//
//  File.swift
//  IMQAIO
//
//  Created by Hunta Park on 2/3/25.
//

import Foundation
import OpenTelemetrySdk
import OpenTelemetryApi

class CustomOtlpHttpLogExporter: CustomOtlpHttpExporterBase, LogRecordExporter{
    var pendingLogRecords: [ReadableLogRecord] = []
    private let exporterLock = NSLock()
    private(set) weak var uploadCache:IMQAUploadCache?
    
    public convenience init(
        endpoint: URL = URL(string: "http://localhost:4318/v1/logs")!,
        config: CustomOtlpConfiguration = CustomOtlpConfiguration(),
        useSession: URLSession? = nil,
        envVarHeaders: [(String, String)]? = CustomEnvVarHeaders.attributes,
        uploadCache:IMQAUploadCache
    ) {
        self.init(
            endpoint: endpoint,
            config: config,
            useSession: useSession,
            envVarHeaders: envVarHeaders
        )
        self.uploadCache = uploadCache
    }
    
    public func export(logRecords: [OpenTelemetrySdk.ReadableLogRecord], explicitTimeout: TimeInterval? = nil) -> OpenTelemetrySdk.ExportResult {
        var resultValue: SpanExporterResultCode = .success
        var sendingLogRecords: [ReadableLogRecord] = []
        exporterLock.lock()
        pendingLogRecords = []
        pendingLogRecords.append(contentsOf: logRecords)
        sendingLogRecords = pendingLogRecords
        pendingLogRecords = []
        exporterLock.unlock()

        let body = Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest.with { request in
            request.resourceLogs = CustomLogRecordAdapter.toProtoResourceRecordLog(logRecordList: sendingLogRecords)
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
                                         type: .logs,
                                         data: request.httpBody!)
        request.timeoutInterval = min(explicitTimeout ?? TimeInterval.greatestFiniteMagnitude, config.timeout)
        URLSession.shared.dataTask(with: request) {[weak self] data, response, error  in
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
                                                    type: .logs)
            }
            
        }.resume()

        return .success
    }

    public func forceFlush(explicitTimeout: TimeInterval? = nil) -> ExportResult {
        flush(explicitTimeout: explicitTimeout)
    }

    public func flush(explicitTimeout: TimeInterval? = nil) -> ExportResult {
        var exporterResult: ExportResult = .success
        var pendingLogRecords: [ReadableLogRecord] = []
        exporterLock.lock()
            pendingLogRecords = self.pendingLogRecords
        exporterLock.unlock()


        if !pendingLogRecords.isEmpty {
            let body = Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest.with { request in
                request.resourceLogs = CustomLogRecordAdapter.toProtoResourceRecordLog(logRecordList: pendingLogRecords)
            }
            let semaphore = DispatchSemaphore(value: 0)
            var request = createRequest(body: body, endpoint: endpoint)
            request.timeoutInterval = min(explicitTimeout ?? TimeInterval.greatestFiniteMagnitude, config.timeout)
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
                                             type: .logs,
                                             data: request.httpBody!)

            URLSession.shared.dataTask(with: request) {[weak self] data, response, error in
                if let error = error {
                    exporterResult = ExportResult.failure
                } else if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    exporterResult = ExportResult.success
                } else {
                    exporterResult = ExportResult.failure
                }
                
                if exporterResult == .success {
                    //record data
                    self?.uploadCache?.deleteUploadData(id: recordId,
                                                        type: .logs)
                }
            }.resume()
            
            semaphore.wait()
        }

        return exporterResult
    }
}
