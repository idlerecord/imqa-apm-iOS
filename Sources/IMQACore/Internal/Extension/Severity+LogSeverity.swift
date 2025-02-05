//
//  Severity+LogSeverity.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//

import OpenTelemetryApi
import IMQAOtelInternal


public extension Severity {
    /// Transforms `OpenTelemetryApi.Severity` to `IMQACommon.LogSeverity`
    /// - Returns: a `IMQACommon.LogSeverity`. The transformation could fail, that's why it's an `Optional`
    func toLogSeverity() -> LogSeverity? {
        LogSeverity(rawValue: self.rawValue)
    }

    static func fromLogSeverity(_ logSeverity: LogSeverity) -> Severity? {
        Severity(rawValue: logSeverity.number)
    }
}
