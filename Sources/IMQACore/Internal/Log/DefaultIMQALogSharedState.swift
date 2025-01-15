//
//  DefaultIMQALogSharedState.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/13.
//

import Foundation
import OpenTelemetrySdk

class DefaultIMQALogSharedState: IMQALogSharedState {
    let processors: [LogRecordProcessor]
    let resourceProvider: IMQAResourceProvider
    private(set) var config: any IMQALoggerConfig

    init(
        config: any IMQALoggerConfig,
        processors: [LogRecordProcessor],
        resourceProvider: IMQAResourceProvider
    ) {
        self.config = config
        self.processors = processors
        self.resourceProvider = resourceProvider
    }

    func update(_ config: any IMQALoggerConfig) {
        self.config = config
    }
}

extension DefaultIMQALogSharedState {
    static func create(
        storage: IMQAStorage,
        controller: LogControllable,
        exporter: LogRecordExporter? = nil
    ) -> DefaultIMQALogSharedState {
        var exporters: [LogRecordExporter] = [
            StorageIMQALogExporter(
                logBatcher: DefaultLogBatcher(
                    repository: storage,
                    logLimits: .init(),
                    delegate: controller
                )
            )
        ]

        if let exporter = exporter {
            exporters.append(exporter)
        }

        return DefaultIMQALogSharedState(
            config: DefaultIMQALoggerConfig(),
            processors: .default(withExporters: exporters),
            resourceProvider: ResourceStorageExporter(storage: storage)
        )
    }
}
