//
//  IMQASpanProcessor+Setup.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/14.
//

import Foundation
import OpenTelemetrySdk

extension Collection where Element == SpanProcessor {
    static func processors(for storage: IMQAStorage, export: OpenTelemetryExport?) -> [SpanProcessor] {
        var processors: [SpanProcessor] = [
            SingleSpanProcessor(
                spanExporter: StorageSpanExporter(
                    options: .init(storage: storage),
                    logger: IMQA.logger
                )
            )
        ]

        if let external = export?.spanExporter {
            processors.append(BatchSpanProcessor(spanExporter: external) { [weak storage] items in
                let resource = getResource(storage: storage)
                for idx in items.indices {
                    items[idx].settingResource(resource)
                }
            })
        }

        return processors
    }

    static func getResource(storage: IMQAStorage?) -> Resource {
        guard let storage = storage else {
            return Resource()
        }
        let provider = ResourceStorageExporter(storage: storage)
        return provider.getResource()
    }
}
