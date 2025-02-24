//
//  CustomOtlpHttpTraceExporter.swift
//  IMQAIO
//
//  Created by Hunta Park on 2/3/25.
//

import Foundation
//import OpenTelemetryProtocolExporterCommon
import OpenTelemetrySdk
import OpenTelemetryApi
import SwiftProtobuf
//import OpenTelemetryProtocolExporterCommon

public class CustomOtlpHttpTraceExporter: CustomOtlpHttpExporterBase, SpanExporter {
    var pendingSpans: [SpanData] = []
    
    private let exporterLock = NSLock()
        
    private(set) weak var uploadCache:IMQAUploadCache?
    
    public convenience init(endpoint: URL,
                config: CustomOtlpConfiguration = CustomOtlpConfiguration(),
                useSession: URLSession? = nil,
                envVarHeaders: [(String, String)]? = CustomEnvVarHeaders.attributes,
                            uploadCache:IMQAUploadCache) {
        self.init(
            endpoint: endpoint,
            config: config,
            useSession: useSession,
            envVarHeaders: envVarHeaders
        )
        self.uploadCache = uploadCache
    }
    
    public func export(spans: [SpanData], explicitTimeout: TimeInterval? = nil) -> SpanExporterResultCode {
        var resultValue: SpanExporterResultCode = .success
        var sendingSpans: [SpanData] = []
        exporterLock.lock()
        pendingSpans = []
        pendingSpans.append(contentsOf: spans)
        sendingSpans = pendingSpans
        pendingSpans = []
        exporterLock.unlock()

        let body = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest.with {
            $0.resourceSpans = CustomSpanAdapter.toProtoResourceSpans(spanDataList: sendingSpans)
        }
        var request = createRequest(body: body, endpoint: endpoint)
        if let headers = envVarHeaders {
            headers.forEach { key, value in
                request.addValue(value, forHTTPHeaderField: key)
            }

        } else if let headers = config.headers {
            headers.forEach { key, value in
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        let recordId = UUID().uuidString
        self.uploadCache?.saveUploadData(id: recordId,
                                         type: .spans,
                                         data: request.httpBody!)
        
        URLSession.shared.dataTask(with: request) {[weak self] data, response, error in
            if let error = error {
                resultValue = .failure
            } else if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                resultValue = .success
            } else {
                resultValue = .failure
            }
            
            if resultValue == .success {
                //record data
                self?.uploadCache?.deleteUploadData(id: recordId,
                                                    type: .spans)
            }

        }.resume()

        
        return .success
    }

    public func flush(explicitTimeout: TimeInterval? = nil) -> SpanExporterResultCode {
        var resultValue: SpanExporterResultCode = .success
        var pendingSpans: [SpanData] = []
        exporterLock.lock()
            pendingSpans = self.pendingSpans
        exporterLock.unlock()
        if !pendingSpans.isEmpty {
            let body = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest.with {
                $0.resourceSpans = CustomSpanAdapter.toProtoResourceSpans(spanDataList: pendingSpans)
            }
            let semaphore = DispatchSemaphore(value: 0)
            let request = createRequest(body: body, endpoint: endpoint)

            URLSession.shared.dataTask(with: request) {[weak self] data, response, error in
                if let error = error {
                    resultValue = .failure
                } else if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    resultValue = .success
                } else {
                    resultValue = .failure
                }
                if resultValue == .failure {
                    //record data
                }
                semaphore.signal() // 释放信号量，继续执行后续代码
            }.resume()

            semaphore.wait()
        }
        return resultValue
    }
}

public struct CustomEnvVarHeaders {
    private static let labelListSplitter = Character(",")
    private static let labelKeyValueSplitter = Character("=")

    ///  This resource information is loaded from the
    ///  environment variable.
    public static let attributes: [(String, String)]? = CustomEnvVarHeaders.attributes()

    public static func attributes(for rawEnvAttributes: String? = ProcessInfo.processInfo.environment["OTEL_EXPORTER_OTLP_HEADERS"]) -> [(String, String)]? {
        parseAttributes(rawEnvAttributes: rawEnvAttributes)
    }

    private init() {}

    private static func isKey(token: String) -> Bool {
        let alpha = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let digit = CharacterSet(charactersIn: "0123456789")
        let special = CharacterSet(charactersIn: "!#$%&'*+-.^_`|~")
        let tchar = special.union(alpha).union(digit)
        return tchar.isSuperset(of: CharacterSet(charactersIn: token))
    }

    private static func isValue(baggage: String) -> Bool {
        let asciiSet = CharacterSet(charactersIn: UnicodeScalar(0) ..< UnicodeScalar(0x80))
        let special = CharacterSet(charactersIn: "^\"|\"$")
        let baggageOctet = asciiSet.subtracting(.controlCharacters).subtracting(.whitespaces).union(special)
        return baggageOctet.isSuperset(of: CharacterSet(charactersIn: baggage))
    }

    /// Creates a label map from the environment variable string.
    /// - Parameter rawEnvLabels: the comma-separated list of labels
    /// NOTE: Parsing does not fully match W3C Correlation-Context
    private static func parseAttributes(rawEnvAttributes: String?) -> [(String, String)]? {
        guard let rawEnvLabels = rawEnvAttributes else { return nil }

        var labels = [(String, String)]()

        rawEnvLabels.split(separator: labelListSplitter).forEach {
            let split = $0.split(separator: labelKeyValueSplitter)
            if split.count != 2 {
                return
            }

            let key = split[0].trimmingCharacters(in: .whitespaces)
            guard isKey(token: key) else { return }

            let value = split[1].trimmingCharacters(in: .whitespaces)
            guard isValue(baggage: value) else { return }

            labels.append((key, value))
        }
        return labels.count > 0 ? labels : nil
    }
}

extension CustomOtlpHttpTraceExporter {
    private func buildRecord(from spanData: SpanData) -> SpanRecord? {
        guard let data = try? spanData.toJSON() else {
            return nil
        }

        // spanData endTime is non-optional and will be set during `toSpanData()`
        let endTime = spanData.hasEnded ? spanData.endTime : nil

        return SpanRecord(
            id: spanData.spanId.hexString,
            name: spanData.name,
            traceId: spanData.traceId.hexString,
            type: spanData.spanType,
            data: data,
            startTime: spanData.startTime,
            endTime: endTime )
    }
}
