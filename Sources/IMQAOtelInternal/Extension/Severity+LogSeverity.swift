//
//  Severity+LogSeverity.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//

import OpenTelemetryApi

extension Severity {
    /// Transforms `OpenTelemetryApi.Severity` to `IMQACommon.LogSeverity`
    /// - Returns: a `IMQACommon.LogSeverity`. The transformation could fail, that's why it's an `Optional`
    public func toLogSeverity() -> LogSeverity? {
        LogSeverity(rawValue: self.rawValue)
    }

    static public func fromLogSeverity(_ logSeverity: LogSeverity) -> Severity? {
        Severity(rawValue: logSeverity.number)
    }
}
