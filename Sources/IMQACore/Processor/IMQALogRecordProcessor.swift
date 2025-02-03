//
//  IMQALogRecordProcessor.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/13.
//

import OpenTelemetrySdk

extension Array where Element == any LogRecordProcessor {
    static func `default`(
        withExporters exporters: [LogRecordExporter]
    ) -> [LogRecordProcessor] {
        [SingleLogRecordProcessor(exporters: exporters)]
    }
}
