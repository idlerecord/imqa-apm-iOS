//
//  File.swift
//  IMQAIO
//
//  Created by Hunta Park on 2/3/25.
//

import Foundation
import Foundation
import OpenTelemetryProtocolExporterCommon
import OpenTelemetrySdk
import OpenTelemetryApi
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class CustomOtlpHttpLogExporter: CustomOtlpHttpExporterBase, LogRecordExporter{
    var pendingLogRecords: [ReadableLogRecord] = []
    private let exporterLock = NSLock()
    private var exporterMetrics: ExporterMetrics?
    private(set) weak var storage: IMQAStorage?
    
    override init(
        endpoint: URL = URL(string: "http://localhost:4318/v1/logs")!,
        config: OtlpConfiguration = OtlpConfiguration(),
        useSession: URLSession? = nil,
        envVarHeaders: [(String, String)]? = EnvVarHeaders.attributes
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
        config: OtlpConfiguration = OtlpConfiguration(),
        useSession: URLSession? = nil,
        envVarHeaders: [(String, String)]? = EnvVarHeaders.attributes,
        storage: IMQAStorage
    ) {
        self.init(endpoint: endpoint, config: config, useSession: useSession, envVarHeaders: envVarHeaders)
        self.storage = storage
    }

    /// A `convenience` constructor to provide support for exporter metric using`StableMeterProvider` type
    /// - Parameters:
    ///    - endpoint: Exporter endpoint injected as dependency
    ///    - config: Exporter configuration including type of exporter
    ///    - meterProvider: Injected `StableMeterProvider` for metric
    ///    - useSession: Overridden `URLSession` if any
    ///    - envVarHeaders: Extra header key-values
    convenience public init(
        endpoint: URL = URL(string: "http://localhost:4318/v1/logs")!,
        config: OtlpConfiguration = OtlpConfiguration(),
        meterProvider: StableMeterProvider,
        useSession: URLSession? = nil,
        envVarHeaders: [(String, String)]? = EnvVarHeaders.attributes
    ) {
        self.init(endpoint: endpoint, config: config, useSession: useSession, envVarHeaders: envVarHeaders)
        exporterMetrics = ExporterMetrics(
            type: "otlp",
            meterProvider: meterProvider,
            exporterName: "log",
            transportName: config.exportAsJson ?
                ExporterMetrics.TransporterType.httpJson :
                ExporterMetrics.TransporterType.grpc
        )
    }
    
    public func export(logRecords: [OpenTelemetrySdk.ReadableLogRecord], explicitTimeout: TimeInterval? = nil) -> OpenTelemetrySdk.ExportResult {
        var sendingLogRecords: [ReadableLogRecord] = []
        exporterLock.lock()
        pendingLogRecords.append(contentsOf: logRecords)
        sendingLogRecords = pendingLogRecords
        pendingLogRecords = []
        exporterLock.unlock()

        let body = Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest.with { request in
            request.resourceLogs = LogRecordAdapter.toProtoResourceRecordLog(logRecordList: sendingLogRecords)
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
        exporterMetrics?.addSeen(value: sendingLogRecords.count)
        request.timeoutInterval = min(explicitTimeout ?? TimeInterval.greatestFiniteMagnitude, config.timeout)
        URLSession.shared.dataTask(with: request) {[weak self] data, response, error  in
            if let error = error {
                self?.exporterMetrics?.addFailed(value: sendingLogRecords.count)
                self?.exporterLock.lock()
                self?.pendingLogRecords.append(contentsOf: sendingLogRecords)
                self?.exporterLock.unlock()
                print(error)
                
            } else if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                self?.exporterMetrics?.addSuccess(value: sendingLogRecords.count)
            } else {
                self?.exporterMetrics?.addFailed(value: sendingLogRecords.count)
                self?.exporterLock.lock()
                self?.pendingLogRecords.append(contentsOf: sendingLogRecords)
                self?.exporterLock.unlock()
            }
        }.resume()

//        httpClient.send(request: request) { [weak self] result in
//            switch result {
//            case .success:
//                self?.exporterMetrics?.addSuccess(value: sendingLogRecords.count)
//                break
//            case let .failure(error):
//                self?.exporterMetrics?.addFailed(value: sendingLogRecords.count)
//                self?.exporterLock.withLockVoid {
//                    self?.pendingLogRecords.append(contentsOf: sendingLogRecords)
//                }
//                print(error)
//            }
//        }

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
                request.resourceLogs = LogRecordAdapter.toProtoResourceRecordLog(logRecordList: pendingLogRecords)
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
                    self?.exporterMetrics?.addFailed(value: pendingLogRecords.count)
                    exporterResult = ExportResult.failure
                } else if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    self?.exporterMetrics?.addSuccess(value: pendingLogRecords.count)
                    exporterResult = ExportResult.success
                } else {
                    self?.exporterMetrics?.addFailed(value: pendingLogRecords.count)
                    exporterResult = ExportResult.failure
                }
            }.resume()

            
//            httpClient.send(request: request) { [weak self] result in
//                switch result {
//                case .success:
//                    self?.exporterMetrics?.addSuccess(value: pendingLogRecords.count)
//                    exporterResult = ExportResult.success
//                case let .failure(error):
//                    self?.exporterMetrics?.addFailed(value: pendingLogRecords.count)
//                    print(error)
//                    exporterResult = ExportResult.failure
//                }
//                semaphore.signal()
//            }
            semaphore.wait()
        }

        return exporterResult
    }
}
