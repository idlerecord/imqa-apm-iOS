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
    private(set) weak var storage: IMQAStorage?
    
    override init(
        endpoint: URL = URL(string: "http://localhost:4318/v1/logs")!,
        config: CustomOtlpConfiguration = CustomOtlpConfiguration(),
        useSession: URLSession? = nil,
        envVarHeaders: [(String, String)]? = CustomEnvVarHeaders.attributes
    ) {
        super.init(
            endpoint: endpoint,
            config: config,
            useSession: useSession,
            envVarHeaders: envVarHeaders
        )
    }
    
    convenience public init(
        endpoint: URL = URL(string: "http://localhost:4318/v1/logs")!,
        config: CustomOtlpConfiguration = CustomOtlpConfiguration(),
        useSession: URLSession? = nil,
        envVarHeaders: [(String, String)]? = CustomEnvVarHeaders.attributes,
        storage: IMQAStorage
    ) {
        self.init(endpoint: endpoint, config: config, useSession: useSession, envVarHeaders: envVarHeaders)
        self.storage = storage
    }

    
    public func export(logRecords: [OpenTelemetrySdk.ReadableLogRecord], explicitTimeout: TimeInterval? = nil) -> OpenTelemetrySdk.ExportResult {
        var sendingLogRecords: [ReadableLogRecord] = []
        exporterLock.lock()
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
//        exporterMetrics?.addSeen(value: sendingLogRecords.count)
        request.timeoutInterval = min(explicitTimeout ?? TimeInterval.greatestFiniteMagnitude, config.timeout)
        URLSession.shared.dataTask(with: request) {[weak self] data, response, error  in
            if let error = error {
//                self?.exporterMetrics?.addFailed(value: sendingLogRecords.count)
                self?.exporterLock.lock()
                self?.pendingLogRecords.append(contentsOf: sendingLogRecords)
                self?.exporterLock.unlock()
                
            } else if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
//                self?.exporterMetrics?.addSuccess(value: sendingLogRecords.count)
            } else {
//                self?.exporterMetrics?.addFailed(value: sendingLogRecords.count)
                self?.exporterLock.lock()
                self?.pendingLogRecords.append(contentsOf: sendingLogRecords)
                self?.exporterLock.unlock()
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
            
            URLSession.shared.dataTask(with: request) {[weak self] data, response, error in
                if let error = error {
//                    self?.exporterMetrics?.addFailed(value: pendingLogRecords.count)
                    exporterResult = ExportResult.failure
                } else if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
//                    self?.exporterMetrics?.addSuccess(value: pendingLogRecords.count)
                    exporterResult = ExportResult.success
                } else {
//                    self?.exporterMetrics?.addFailed(value: pendingLogRecords.count)
                    exporterResult = ExportResult.failure
                }
            }.resume()
            
            semaphore.wait()
        }

        return exporterResult
    }
}
