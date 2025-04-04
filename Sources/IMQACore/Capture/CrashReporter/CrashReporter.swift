//
//  CrashReporter.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/4.
//

import Foundation
import IMQAOtelInternal

@objc public enum LastRunState: Int {
    case unavailable, crash, cleanExit
}

@objc public protocol CrashReporter {
    @objc var currentSessionId: String? { get set }

    @objc func install(context: CrashReporterContext, logger: InternalLogger)

    @objc func getLastRunState() -> LastRunState

    @objc func fetchUnsentCrashReports(completion: @escaping ([CrashReport]) -> Void)
    @objc func deleteCrashReport(id: Int)

    @objc var onNewReport: ((CrashReport) -> Void)? { get set }
}

/// This protocol that extends the functionality of a `CrashReporter` and it allows
/// implementers to add additional information to crash reports and extend them.
///
/// Implementing this protocol is optional and should only be considered in cases where
/// additional customization in error reporting is required.
public protocol ExtendableCrashReporter: CrashReporter {
    func appendCrashInfo(key: String, value: String)
}

@objc public class CrashReport: NSObject {
    public private(set) var id: UUID
    public private(set) var payload: String
    public private(set) var provider: String
    public private(set) var internalId: Int?
    public private(set) var sessionId: String?
    public private(set) var timestamp: Date?
    public private(set) var spanRecord: SpanRecord?

    public init(
        payload: String,
        provider: String,
        internalId: Int? = nil,
        sessionId: String? = nil,
        timestamp: Date? = nil,
        spanRecord: SpanRecord? = nil
    ) {
        self.id = UUID()
        self.payload = payload
        self.provider = provider
        self.internalId = internalId
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.spanRecord = spanRecord
    }
}
