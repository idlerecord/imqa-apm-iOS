//
//  IMQAUpload.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation
import IMQAOtelInternal

public protocol IMQALogUploader: AnyObject {
    func uploadLog(id: String, data: Data, completion: ((Result<(), Error>) -> Void)?)
}

/// Class in charge of uploading all the data collected by the IMQA SDK.
public class IMQAUpload: IMQALogUploader {

    public private(set) var options: Options
    public private(set) var logger: InternalLogger
    public private(set) var queue: DispatchQueue
    let semaphore: DispatchSemaphore
    
    let cache: IMQAUploadCache
    let urlSession: URLSession
    let operationQueue: OperationQueue
    var reachabilityMonitor: IMQAReachabilityMonitor?

    /// Returns an `IMQAUpload` instance
    /// - Parameters:
    ///   - options: `IMQAUpload.Options` instance
    ///   - logger: `IMQAConsoleLogger` instance
    ///   - queue: `DispatchQueue` to be used for all upload operations
    public init(options: Options, logger: InternalLogger, queue: DispatchQueue) throws {

        self.options = options
        self.logger = logger
        self.queue = queue
        self.semaphore = DispatchSemaphore(value: 2)

        cache = try IMQAUploadCache(options: options.cache, logger: logger)

        urlSession = URLSession(configuration: options.urlSessionConfiguration)
        
        operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue

        // reachability monitor
        if options.redundancy.retryOnInternetConnected {
            let monitorQueue = DispatchQueue(label: "com.imqa.upload.reachability")
            reachabilityMonitor = IMQAReachabilityMonitor(queue: monitorQueue)
            reachabilityMonitor?.onConnectionRegained = { [weak self] in
                self?.retryCachedData()
            }

            reachabilityMonitor?.start()
        }
    }

    /// Attempts to upload all the available cached data.
    public func retryCachedData() {
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                let cachedObjects = try self.cache.fetchAllUploadData()

                for uploadData in cachedObjects {
                    guard let type = IMQAUploadType(rawValue: uploadData.type) else {
                        continue
                    }
                    self.semaphore.wait()
                    self.reUploadData(
                        id: uploadData.id,
                        data: uploadData.data,
                        type: type,
                        attemptCount: uploadData.attemptCount,
                        completion: { 
                            self.semaphore.signal()
                        })
                }
            } catch {
                self.logger.debug("Error retrying cached upload data: \(error.localizedDescription)")
            }
        }
    }

    /// Uploads the given session span data
    /// - Parameters:
    ///   - id: Identifier of the session
    ///   - data: Data of the session's payload
    ///   - completion: Completion block called when the data is successfully cached, or when an `Error` occurs
    public func uploadSpans(id: String, data: Data, completion: ((Result<(), Error>) -> Void)?) {
        queue.async { [weak self] in
            self?.uploadData(id: id, data: data, type: .spans, completion: completion)
        }
    }

    /// Uploads the given log data
    /// - Parameters:
    ///   - id: Identifier of the log batch (has no utility aside of caching)
    ///   - data: Data of the log's payload
    ///   - completion: Completion block called when the data is successfully cached, or when an `Error` occurs
    public func uploadLog(id: String, data: Data, completion: ((Result<(), Error>) -> Void)?) {
        queue.async { [weak self] in
            self?.uploadData(id: id, data: data, type: .logs, completion: completion)
        }
    }
    

    // MARK: - Internal
    private func uploadData(
        id: String,
        data: Data,
        type: IMQAUploadType,
        attemptCount: Int = 0,
        completion: ((Result<(), Error>) -> Void)?) {

        // validate identifier
        guard id.isEmpty == false else {
            completion?(.failure(IMQAUploadError.internalError(.invalidMetadata)))
            return
        }

        // validate data
        guard data.isEmpty == false else {
            completion?(.failure(IMQAUploadError.internalError(.invalidData)))
            return
        }

        // cache operation
        let cacheOperation = BlockOperation { [weak self] in
            do {
                try self?.cache.saveUploadData(id: id, type: type, data: data)
                completion?(.success(()))
            } catch {
                self?.logger.debug("Error caching upload data: \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
            var isProtobuf:Bool = true
            switch type {
            case .spans:
                ()
            case .logs:
                ()
            case .crash:
                ()
            }
        // upload operation
        let uploadOperation = IMQAUploadOperation(
            urlSession: urlSession,
            metadataOptions: options.metadata,
            endpoint: endpoint(for: type),
            identifier: id,
            data: data,
            retryCount: options.redundancy.automaticRetryCount,
            attemptCount: attemptCount,
            logger: logger,
            isProtobuf: isProtobuf) { [weak self] (cancelled, count, error) in
                self?.queue.async { [weak self] in
                    self?.handleOperationFinished(
                        id: id,
                        type: type,
                        cancelled: cancelled,
                        attemptCount: count,
                        error: error
                    )
                    self?.cleanCacheFromStaleData()
                }
            }

        // queue operations
        uploadOperation.addDependency(cacheOperation)
        operationQueue.addOperation(cacheOperation)
        operationQueue.addOperation(uploadOperation)
    }

    func reUploadData(id: String,
                      data: Data,
                      type: IMQAUploadType,
                      attemptCount: Int,
                      completion: @escaping (() -> Void)) {
        let uploadOperation = IMQAUploadOperation(
            urlSession: urlSession,
            metadataOptions: options.metadata,
            endpoint: endpoint(for: type),
            identifier: id,
            data: data,
            retryCount: options.redundancy.automaticRetryCount,
            attemptCount: attemptCount,
            logger: logger,
            isProtobuf: true) { [weak self] (cancelled, count, error) in
                self?.queue.async { [weak self] in
                    self?.handleOperationFinished(
                        id: id,
                        type: type,
                        cancelled: cancelled,
                        attemptCount: count,
                        error: error
                    )
                    completion()
                    self?.cleanCacheFromStaleData()
                }
            }
        
        operationQueue.addOperation(uploadOperation)
    }

    
    private func handleOperationFinished(
        id: String,
        type: IMQAUploadType,
        cancelled: Bool,
        attemptCount: Int,
        error: Error?) {

        // error?
        if cancelled == true || error != nil {
            // update attempt count in cache
            operationQueue.addOperation { [weak self] in
                do {
                    try self?.cache.updateAttemptCount(id: id, type: type, attemptCount: attemptCount)
                } catch {
                    self?.logger.debug("Error updating cache: \(error.localizedDescription)")
                }
            }
            return
        }

        // success -> clear cache
        operationQueue.addOperation { [weak self] in
            do {
                try self?.cache.deleteUploadData(id: id, type: type)
            } catch {
                self?.logger.debug("Error deleting cache: \(error.localizedDescription)")
            }
        }
    }

    private func cleanCacheFromStaleData() {
        operationQueue.addOperation { [weak self] in
            do {
                try self?.cache.clearStaleDataIfNeeded()
            } catch {
                self?.logger.debug("Error clearing stale date from cache: \(error.localizedDescription)")
            }
        }
    }

    private func endpoint(for type: IMQAUploadType) -> URL {
        switch type {
        case .spans: return options.endpoints.spansURL
        case .logs: return options.endpoints.logsURL
        case .crash: return options.endpoints.logsURL
        }
    }
}


//Crash data를 보낸다
extension IMQAUpload {
    public func uploadCrashLog(id: String, data: Data, completion: ((Result<(), Error>) -> Void)?) {
        queue.async { [weak self] in
            self?.uploadCrashLogAction(data: data, completion: completion)
        }
    }
    
    public func uploadCrashSpan(id: String, data: Data, completion: ((Result<(), Error>) -> Void)?){
        queue.async { [weak self] in
            self?.uploadCrashSpansAction(data: data, completion: completion)
        }
    }
    
    private func uploadCrashLogAction(data: Data, completion: ((Result<(), Error>) -> Void)?){
        var request = URLRequest(url: options.endpoints.logsURL)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("IMQA-iOS-SDK", forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")

        let urlSession: URLSession = URLSession(configuration: options.urlSessionConfiguration)

        let task = urlSession.dataTask(with: request) { data, response, error in
            if let response = response as? HTTPURLResponse {
                if response.statusCode >= 200 && response.statusCode < 300 {
                    completion?(.success(()))
                } else {
                    let returnError = IMQAUploadError.incorrectStatusCodeError(response.statusCode)
                    completion?(.failure(returnError))
                }
            } else {
                let returnError = IMQAUploadError.internalError(.valueConvertError)
                completion?(.failure(returnError))
            }
        }
        task.resume()
    }
    
    private func uploadCrashSpansAction(data: Data, completion: ((Result<(), Error>) -> Void)?){
        var request = URLRequest(url: options.endpoints.spansURL)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("IMQA-iOS-SDK", forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
        request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")

        let urlSession: URLSession = URLSession(configuration: options.urlSessionConfiguration)

        let task = urlSession.dataTask(with: request) { data, response, error in
            if let response = response as? HTTPURLResponse {
                if response.statusCode >= 200 && response.statusCode < 300 {
                    completion?(.success(()))
                } else {
                    let returnError = IMQAUploadError.incorrectStatusCodeError(response.statusCode)
                    completion?(.failure(returnError))
                }
            } else {
                let returnError = IMQAUploadError.internalError(.valueConvertError)
                completion?(.failure(returnError))
            }
        }
        task.resume()
    }
}
