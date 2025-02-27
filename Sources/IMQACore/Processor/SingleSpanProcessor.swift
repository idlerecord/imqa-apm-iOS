//
//  SingleSpanProcessor.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/14.
//

import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

/// A really simple implementation of the SpanProcessor that converts the ExportableSpan to SpanData
/// and passes it to the configured exporter in both `onStart` and `onEnd`
struct SingleSpanProcessor: SpanProcessor {

    let spanExporter: SpanExporter
    private let processorQueue = DispatchQueue(label: "io.imqa.spanprocessor", qos: .utility)

    /// Returns a new SingleSpanProcessor that converts spans to SpanData and forwards them to
    /// the given spanExporter.
    /// - Parameter spanExporter: the SpanExporter to where the Spans are pushed.
    public init(spanExporter: SpanExporter) {
        self.spanExporter = spanExporter
    }

    public let isStartRequired: Bool = true

    public let isEndRequired: Bool = true

    public func onStart(parentContext: SpanContext?, span: OpenTelemetrySdk.ReadableSpan) {
        let exporter = self.spanExporter

        let data = span.toSpanData()
        //record before crash span
        if let record = buildRecord(from: data){
            let crashStorage = IMQAMuti<CrashSpanRecord>()
            let crashRecord: CrashSpanRecord = CrashSpanRecord(id: record.id,
                                                               name: record.name,
                                                               traceId: record.traceId,
                                                               type: record.type,
                                                               data: record.data,
                                                               startTime: record.startTime,
                                                               endTime: record.endTime,
                                                               processIdentifier: record.processIdentifier,
                                                               sessionId: IMQAOTel.sessionId.toString)
            crashStorage.save(crashRecord)
        }

        processorQueue.async {
            _ = exporter.export(spans: [data])
        }
    }

    public func onEnd(span: OpenTelemetrySdk.ReadableSpan) {
        let exporter = self.spanExporter

        var data = span.toSpanData()
//        if let record = buildRecord(from: data){
//            let crashStorage = IMQAMuti<CrashSpanRecord>()
//            let crashRecord: CrashSpanRecord = CrashSpanRecord(id: record.id,
//                                                               name: record.name,
//                                                               traceId: record.traceId,
//                                                               type: record.type,
//                                                               data: record.data,
//                                                               startTime: record.startTime,
//                                                               endTime: record.endTime,
//                                                               processIdentifier: record.processIdentifier,
//                                                               sessionId: IMQAOTel.sessionId.toString)
//            crashStorage.save(crashRecord)
//        }
//
//        
        if data.hasEnded && data.status == .unset {
            if let errorCode = data.errorCode {
                data.settingStatus(.error(description: errorCode.rawValue))
            } else {
                data.settingStatus(.ok)
            }
        }

        processorQueue.async {
            _ = exporter.export(spans: [data])
        }
    }

    public func forceFlush(timeout: TimeInterval?) {
        _ = processorQueue.sync { spanExporter.flush() }
    }

    public func shutdown(explicitTimeout: TimeInterval?) {
        processorQueue.sync {
            spanExporter.shutdown()
        }
    }
}
extension SingleSpanProcessor {
    private func buildRecord(from spanData: SpanData) -> SpanRecord? {
        guard let data = try? spanData.toJSON() else {
            return nil
        }

        return SpanRecord(
            id: spanData.spanId.hexString,
            name: spanData.name,
            traceId: spanData.traceId.hexString,
            type: spanData.spanType,
            data: data,
            startTime: spanData.startTime,
            endTime: spanData.endTime )
    }
}

