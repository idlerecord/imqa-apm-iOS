//
//  StorageSpanExporter.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/11.
//

import Foundation
import OpenTelemetrySdk
import IMQAOtelInternal

class StorageSpanExporter: SpanExporter {

    private(set) weak var storage: IMQAStorage?
    private weak var logger: InternalLogger?

    let validation: SpanDataValidation

    init(options: Options, logger: InternalLogger) {
        self.storage = options.storage
        self.validation = SpanDataValidation(validators: options.validators)
        self.logger = logger
    }

    @discardableResult public func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        guard let storage = storage else {
            return .failure
        }

        var result = SpanExporterResultCode.success
        for var spanData in spans {

            let isValid = validation.execute(spanData: &spanData)
            if isValid, let record = buildRecord(from: spanData) {
                do {
                    try storage.upsertSpan(record)
                } catch let exception {
                    self.logger?.error(exception.localizedDescription)
                    result = .failure
                }
            } else {
                result = .failure
            }
        }

        return result
    }

    public func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
        // TODO: do we need to make sure storage writes are finished?
        return .success
    }

    public func shutdown(explicitTimeout: TimeInterval?) {
        _ = flush()
    }

}

extension StorageSpanExporter {
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
