//
//  CustomOtlpHttpTraceExporter.swift
//  IMQAIO
//
//  Created by Hunta Park on 2/3/25.
//

import Foundation
import OpenTelemetryProtocolExporterCommon
import OpenTelemetrySdk
import OpenTelemetryApi
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class CustomOtlpHttpTraceExporter: CustomOtlpHttpExporterBase, SpanExporter {
    var pendingSpans: [SpanData] = []
    
    private let exporterLock = NSLock()
    private var exporterMetrics: ExporterMetrics?
    private(set) weak var storage: IMQAStorage?

    override
    public init(
        endpoint: URL = URL(string: "http://localhost:4318/v1/traces")!,
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

    /// A `convenience` constructor to provide support for exporter metric using`StableMeterProvider` type
    /// - Parameters:
    ///    - endpoint: Exporter endpoint injected as dependency
    ///    - config: Exporter configuration including type of exporter
    ///    - meterProvider: Injected `StableMeterProvider` for metric
    ///    - useSession: Overridden `URLSession` if any
    ///    - envVarHeaders: Extra header key-values
    convenience public init(
        endpoint: URL = URL(string: "http://localhost:4318/v1/traces")!,
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
        endpoint: URL,
        config: OtlpConfiguration,
        meterProvider: StableMeterProvider,
        useSession: URLSession? = nil,
        envVarHeaders: [(String, String)]? = EnvVarHeaders.attributes
    ) {
        self.init(endpoint: endpoint, config: config, useSession: useSession, envVarHeaders: envVarHeaders)
        exporterMetrics = ExporterMetrics(
            type: "otlp",
            meterProvider: meterProvider,
            exporterName: "span",
            transportName: config.exportAsJson ?
                ExporterMetrics.TransporterType.httpJson :
                ExporterMetrics.TransporterType.grpc
        )
    }
    
    public func export(spans: [SpanData], explicitTimeout: TimeInterval? = nil) -> SpanExporterResultCode {
        var sendingSpans: [SpanData] = []
        exporterLock.lock()
        pendingSpans.append(contentsOf: spans)
        sendingSpans = pendingSpans
        pendingSpans = []
        exporterLock.unlock()

        let body = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest.with {
            $0.resourceSpans = SpanAdapter.toProtoResourceSpans(spanDataList: sendingSpans)
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
        exporterMetrics?.addSeen(value: sendingSpans.count)
//        httpClient.send(request: request) { [weak self] result in
//            switch result {
//            case .success:
//                self?.exporterMetrics?.addSuccess(value: sendingSpans.count)
//                break
//            case let .failure(error):
//                self?.exporterMetrics?.addFailed(value: sendingSpans.count)
//                self?.exporterLock.withLockVoid {
//                    self?.pendingSpans.append(contentsOf: sendingSpans)
//                }
//                print(error)
//            }
//        }
        URLSession.shared.dataTask(with: request) {[weak self] data, response, error in
            if let error = error {
                self?.exporterMetrics?.addFailed(value: sendingSpans.count)
                print(error)
            } else if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                let spanIds = sendingSpans.map {
                    return $0.spanId.hexString
                }
                self?.storage?.deleteSpans(spanIds: spanIds)
                self?.exporterMetrics?.addSuccess(value: sendingSpans.count)
                
            } else {
                self?.exporterMetrics?.addFailed(value: sendingSpans.count)
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
                $0.resourceSpans = SpanAdapter.toProtoResourceSpans(spanDataList: pendingSpans)
            }
            let semaphore = DispatchSemaphore(value: 0)
            let request = createRequest(body: body, endpoint: endpoint)

//            httpClient.send(request: request) { [weak self] result in
//                switch result {
//                case .success:
//                    self?.exporterMetrics?.addSuccess(value: pendingSpans.count)
//                    break
//                case let .failure(error):
//                    self?.exporterMetrics?.addFailed(value: pendingSpans.count)
//                    print(error)
//                    resultValue = .failure
//                }
//                semaphore.signal()
//            }
//            semaphore.wait()
            
            URLSession.shared.dataTask(with: request) {[weak self] data, response, error in
                if let error = error {
                    self?.exporterMetrics?.addFailed(value: pendingSpans.count)
                    print(error)
                    resultValue = .failure
                } else if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    self?.exporterMetrics?.addSuccess(value: pendingSpans.count)
                } else {
                    self?.exporterMetrics?.addFailed(value: pendingSpans.count)
                }
                semaphore.signal() // 释放信号量，继续执行后续代码
            }.resume()

            
            semaphore.wait()
        }
        return resultValue
    }
}
