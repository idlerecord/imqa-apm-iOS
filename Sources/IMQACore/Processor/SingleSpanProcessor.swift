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

        processorQueue.async {
            _ = exporter.export(spans: [data])
        }
    }

    public func onEnd(span: OpenTelemetrySdk.ReadableSpan) {
        let exporter = self.spanExporter

        var data = span.toSpanData()
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
