//
//  IMQALogSharedState.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation
import IMQAOtelInternal
import OpenTelemetryApi
import OpenTelemetrySdk


internal protocol IMQALogSharedState {
    var processors: [LogRecordProcessor] { get }
    var config: any IMQALoggerConfig { get }
    var resourceProvider: IMQAResourceProvider { get }

    func update(_ config: any IMQALoggerConfig)
}
