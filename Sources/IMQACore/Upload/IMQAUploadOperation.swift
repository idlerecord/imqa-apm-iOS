//
//  IMQAUploadOperation.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//


import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import OpenTelemetryProtocolExporterCommon
import IMQAOtelInternal


typealias IMQAUploadOperationCompletion = (_ cancelled: Bool, _ attemptCount: Int, _ error: Error?) -> Void

class IMQAUploadOperation: AsyncOperation {

    private let urlSession: URLSession
    private let metadataOptions: IMQAUpload.MetadataOptions
    private let endpoint: URL
    private let identifier: String
    private let data: Data
    private let retryCount: Int
    private var attemptCount: Int
    private let logger: InternalLogger?
    private let completion: IMQAUploadOperationCompletion?
    private let isProtobuf: Bool 
    
    private var task: URLSessionDataTask?

    init(
        urlSession: URLSession,
        metadataOptions: IMQAUpload.MetadataOptions,
        endpoint: URL,
        identifier: String,
        data: Data,
        retryCount: Int,
        attemptCount: Int,
        logger: InternalLogger? = nil,
        isProtobuf: Bool = true,
        completion: IMQAUploadOperationCompletion? = nil
    ) {
        self.urlSession = urlSession
        self.metadataOptions = metadataOptions
        self.endpoint = endpoint
        self.identifier = identifier
        self.data = data
        self.retryCount = retryCount
        self.attemptCount = attemptCount
        self.logger = logger
        self.isProtobuf = isProtobuf
        self.completion = completion
    }

    override func cancel() {
        super.cancel()

        task?.cancel()
        task = nil

        completion?(true, attemptCount, nil)
    }

    override func execute() {
        let request = createRequest()

        sendRequest(request, retryCount: retryCount)
    }

    private func sendRequest(_ r: URLRequest, retryCount: Int) {
        var request = r

        // increment attempt count
        attemptCount += 1

        // update request's attempt count header
        request = updateRequest(request, attemptCount: attemptCount)

        task = urlSession.dataTask(with: request, completionHandler: { [weak self] _, response, error in

            // retry?
            if error != nil && retryCount > 0 {
                self?.sendRequest(request, retryCount: retryCount - 1)
                return
            }

            // check success
            if let response = response as? HTTPURLResponse {
                self?.logger?.debug("Upload operation complete. Status: \(response.statusCode) URL: \(String(describing: response.url))")
                if response.statusCode >= 200 && response.statusCode < 300 {
                    self?.completion?(false, self?.attemptCount ?? 0, nil)
                } else {
                    let returnError = IMQAUploadError.incorrectStatusCodeError(response.statusCode)
                    self?.completion?(false, self?.attemptCount ?? 0, returnError)
                }

            // no retries left, send completion
            } else {
                self?.completion?(false, self?.attemptCount ?? 0, error)
            }

            self?.finish()
        })

        task?.resume()
    }

    private func createRequest() -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = data


        if isProtobuf {
            request.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
            request.setValue(Headers.getUserAgentHeader(), forHTTPHeaderField: Constants.HTTP.userAgent)
        }else{
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
            request.setValue(metadataOptions.userAgent, forHTTPHeaderField: "User-Agent")
        }
        

//        request.setValue(metadataOptions.apiKey, forHTTPHeaderField: "x-imqa-AID")
//        request.setValue(metadataOptions.deviceId, forHTTPHeaderField: "x-imqa-DID")

        return request
    }

    private func updateRequest(_ r: URLRequest, attemptCount: Int) -> URLRequest {
        guard attemptCount > 1 else {
            return r
        }

        var request = r
        request.setValue(String(attemptCount - 1), forHTTPHeaderField: "x-imqa-retry-count")

        return request
    }
}
