//
//  Severity+LogSeverity.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//

import OpenTelemetryApi
import IMQAOtelInternal


extension Severity {
    /// Transforms `OpenTelemetryApi.Severity` to `IMQACommon.LogSeverity`
    /// - Returns: a `IMQACommon.LogSeverity`. The transformation could fail, that's why it's an `Optional`
    internal func toLogSeverity() -> LogSeverity? {
        LogSeverity(rawValue: self.rawValue)
    }

    static internal func fromLogSeverity(_ logSeverity: LogSeverity) -> Severity? {
        Severity(rawValue: logSeverity.number)
    }
}
