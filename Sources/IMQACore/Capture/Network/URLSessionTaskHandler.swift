//
//  URLSessionTaskHandler.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/5.
//

import Foundation
import OpenTelemetryApi
import IMQAOtelInternal
import IMQAObjCUtilsInternal
import IMQACommonInternal
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

extension Notification.Name {
    static let networkRequestCaptured = Notification.Name("networkRequestCaptured")
}

public protocol URLSessionTaskHandler: AnyObject {
    @discardableResult
    func create(task: URLSessionTask) -> Bool
    func finish(task: URLSessionTask, data: Data?, error: (any Error)?)
}

protocol URLSessionTaskHandlerDataSource: AnyObject {
    var state: CaptureServiceState { get }
    var otel: IMQAOpenTelemetry? { get }

    var injectTracingHeader: Bool { get }
    var requestsDataSource: URLSessionRequestsDataSource? { get }
}

final class DefaultURLSessionTaskHandler: URLSessionTaskHandler {

    private var spans: [URLSessionTask: Span] = [:]
    
    
    private let queue: DispatchableQueue
    private let payloadCaptureHandler: NetworkPayloadCaptureHandler
    weak var dataSource: URLSessionTaskHandlerDataSource?

    init(processingQueue: DispatchQueue = DefaultURLSessionTaskHandler.queue(),
         dataSource: URLSessionTaskHandlerDataSource?) {
        self.queue = processingQueue
        self.dataSource = dataSource
        self.payloadCaptureHandler = NetworkPayloadCaptureHandler(otel: dataSource?.otel)
    }

    @discardableResult
    func create(task: URLSessionTask) -> Bool {
        if isInWhiteList(task: task) {
            return false
        }
        
        var handled = false
        queue.sync {
            // don't capture if this task was already handled
            guard task.imqaCaptured == false else {
                return
            }

            // save start time for payload capture
            task.imqaStartTime = Date()

            // don't capture if the service is not active
            guard self.dataSource?.state == .active else {
                return
            }

            // validate task
            guard
                var request = task.originalRequest,
                let url = request.url,
                let otel = self.dataSource?.otel else {
                return
            }

            // get modified request from data source
            request = self.dataSource?.requestsDataSource?.modifiedRequest(for: request) ?? request

            // flag as captured
            task.imqaCaptured = true

            // Probably this could be moved to a separate class
            var attributes: [String: String] = [:]
            //url.full record
            attributes[SemanticAttributes.urlFull.rawValue] = request.url?.absoluteString ?? "N/A"
            
            //http.request.method record
            let httpMethod = request.httpMethod ?? ""
            if !httpMethod.isEmpty {
                attributes[SemanticAttributes.httpRequestMethod.rawValue] = request.httpMethod
            }
            
            //header record
            if request.allHTTPHeaderFields != nil, JSONSerialization.isValidJSONObject(request.allHTTPHeaderFields) {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: request.allHTTPHeaderFields, options: .prettyPrinted)
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    attributes[SpanSemantics.XHR.httpRequestHeaders] = jsonString

                } catch let error {
                    IMQA.logger.error("Failed to serialize HTTP headers: \(error)")
                }
            }
            
            //body record
            if request.httpBody != nil, JSONSerialization.isValidJSONObject(request.httpBody) {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: request.httpBody, options: .prettyPrinted)
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    attributes[SpanSemantics.XHR.httpRequestBody] = jsonString
                } catch let error {
                    IMQA.logger.error("Failed to serialize HTTP body: \(error)")
                }
            }
            
            /*
             Note: According to the OpenTelemetry specification, the attribute name should be ' {method} {http.route}.
             The `{http.route}` corresponds to the template of the path so it's necessary to understand the templating system being employed.
             For instance, a template for a request such as http://embrace.io/users/12345?hello=world
             would be reported as /users/:userId (or /users/:userId? in other templating system).

             Until a decision is made regarding the method to convey this information and the heuristics to extract it,
             the `.path` method will be utilized temporarily. This approach may introduce higher cardinality on the backend,
             which is less than optimal.
             It will be important to address this in the near future to enhance performance for the backend.

             Additional information can be found at:
             - HTTP Name attribute: https://opentelemetry.io/docs/specs/semconv/http/http-spans/#name
             - HTTP Attributes: https://opentelemetry.io/docs/specs/semconv/attributes-registry/http/
             */
            let absoluteString = request.url?.absoluteString ?? ""
            let name = httpMethod.isEmpty ? absoluteString : "\(httpMethod) \(absoluteString)"
            let networkSpan = otel.buildSpan(
                name: name,
                type: IMQASpanType.XHR,
                attributes: attributes
            )
            if TapCaptureService.tapSpan != nil {
                networkSpan.setParent(TapCaptureService.tapSpan!)
            }
            let span = networkSpan.startSpan()
            self.spans[task] = span

            
            // tracing header
            if let tracingHader = self.addTracingHeader(task: task, span: span) {
                span.setAttribute(key: "imqa.w3c_traceparent", value: .string(tracingHader))
            }

            handled = true
        }

        return handled
    }

    func finish(task: URLSessionTask, data: Data?, error: (any Error)?) {
        queue.async {
            // save end time for payload capture
            task.imqaEndTime = Date()

            // process payload capture
            self.payloadCaptureHandler.process(
                request: task.currentRequest ?? task.originalRequest,
                response: task.response,
                data: data,
                error: error,
                startTime: task.imqaStartTime,
                endTime: task.imqaEndTime
            )

            // stop if the service is disabled
            guard self.dataSource?.state == .active else {
                return
            }

            // stop if there was no span for this task
            guard let span = self.spans.removeValue(forKey: task) else {
                return
            }
            
            
            // generate attributes from response
            if let response = task.response as? HTTPURLResponse {
                span.setAttribute(
                    key: SemanticAttributes.httpResponseStatusCode.rawValue,
                    value: response.statusCode
                )
                
                if !((200..<300).contains(response.statusCode)){
                    let errorMessage = NetworkStatusCode.errorMessage(code: response.statusCode)
                    span.setAttribute(key: SemanticAttributes.exceptionType.rawValue,
                                      value: .string("\(response.statusCode)"))

                    span.setAttribute(key: SemanticAttributes.exceptionMessage.rawValue,
                                      value: .string(errorMessage))
                    
                    span.status = .error(description: errorMessage)
                }else{
                    span.status = .ok
                }
            }
            
            if let error = error ?? task.error {
                // Should this be something else?
                let nsError = error as NSError
                span.setAttribute(
                    key: SpanSemantics.XHR.errorType,
                    value: nsError.domain
                )
                
                span.setAttribute(key: SemanticAttributes.exceptionType.rawValue,
                                  value: .string(nsError.domain))

                span.setAttribute(key: SemanticAttributes.exceptionMessage.rawValue,
                                  value: .string(error.localizedDescription))
                
                
                span.status = .error(description: error.localizedDescription)
            }
            
            span.end()

            // internal notification with the captured request
            IMQA.notificationCenter.post(name: .networkRequestCaptured, object: task)
        }
    }

    func addTracingHeader(task: URLSessionTask, span: Span) -> String? {

        guard dataSource?.injectTracingHeader == true,
              task.originalRequest != nil else {
            return nil
        }

        // ignore if header is already present
        let previousValue = task.originalRequest?.value(forHTTPHeaderField: W3C.traceparentHeaderName)
        guard previousValue == nil else {
            return previousValue
        }

        let value = W3C.traceparent(from: span.context)
        if task.injectHeader(withKey: W3C.traceparentHeaderName, value: value) {
            return value
        }
        
        return nil
    }
}

private extension DefaultURLSessionTaskHandler {
    static func queue() -> DispatchQueue {
        .init(label: "com.imqa.URLSessionTaskHandler", qos: .utility)
    }
}

extension DefaultURLSessionTaskHandler{
    func isInWhiteList(task: URLSessionTask) -> Bool{
        if let originUrl = task.originalRequest?.url?.absoluteString,
           let currentUrl = task.currentRequest?.url?.absoluteString {
            if originUrl.hasSuffix("/v1/traces") || currentUrl.hasSuffix("/v1/traces") {
                return true
            }
            if originUrl.hasSuffix("/v1/metrics") || currentUrl.hasSuffix("/v1/metrics") {
                return true
            }
            if originUrl.hasSuffix("/v1/logs") || currentUrl.hasSuffix("/v1/logs") {
                return true
            }            
        }
        return false
    }
}

struct NetworkStatusCode{
    static func errorMessage(code: Int) -> String{
        switch code {
        case 301:
            return "Resource permanently redirected"
        case 302:
            return "Resource temporarily redirected"
        case 304:
            return "Not modified (resource unchanged)"
        case 400:
            return "Bad request (invalid format)"
        case 401:
            return "Unauthorized (invalid token)"
        case 403:
            return "Forbidden (access denied)"
        case 404:
            return "Not found (resource not found)"
        case 405:
            return "Method not allowed (request method not supported)"
        case 500:
            return "Internal server error (server problem)"
        case 502:
            return "Bad gateway (proxy problem)"
        case 503:
            return "Service unavailable (server overloaded)"
        default:
            return "\(code)"
        }
    }
    
}
