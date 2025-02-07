//
//  IMQACrashReporter.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/4.
//

import Foundation
//import KSCrashRecording
import KSCrash
import OpenTelemetryApi
import IMQACommonInternal
import IMQAOtelInternal

public final class IMQACrashReporter: NSObject, CrashReporter {

    static let providerIdentifier = "kscrash"

    enum UserInfoKey {
        static let sessionId = "imqa-sid"
        static let sdkVersion = "imqa-sdk"
        static let crashSpan = "imqa-crashSpan"
    }

    @ThreadSafe
    var ksCrash: KSCrash?

    var logger: InternalLogger?
    private var queue: DispatchQueue = DispatchQueue(label: "com.imqa.crashreporter")

    public private(set) var basePath: String?

    /// Sets the current session identifier that will be included in a crash report.
    public var currentSessionId: String? {
        didSet {
            updateKSCrashInfo()
        }
    }

    /// Adds the SDK version to the crash reports.
    private(set) var sdkVersion: String? {
        didSet {
            updateKSCrashInfo()
        }
    }

    private(set) var extraInfo: [String: String] = [:] {
        didSet {
            updateKSCrashInfo()
        }
    }

    /// Unused in this KSCrash implementation
    public var onNewReport: ((CrashReport) -> Void)?

    private func updateKSCrashInfo() {
        guard let ksCrash = ksCrash else {
            return
        }

        var crashInfo: [String: Any] = ksCrash.userInfo ?? [:]

        self.extraInfo.forEach {
            crashInfo[$0.key] = $0.value
        }

        crashInfo[UserInfoKey.sdkVersion] = self.sdkVersion ?? NSNull()
        crashInfo[UserInfoKey.sessionId] = self.currentSessionId ?? NSNull()

        ksCrash.userInfo = crashInfo
    }

    /// Used to determine if the last session ended cleanly or in a crash.
    public func getLastRunState() -> LastRunState {
        guard let ksCrash = ksCrash else {
            return .unavailable
        }

        return ksCrash.crashedLastLaunch ? .crash : .cleanExit
    }

    public func install(context: CrashReporterContext, logger: InternalLogger) {
        guard ksCrash == nil else {
            logger.debug("IMQACrashReporter already installed!")
            return
        }

        self.logger = logger
        sdkVersion = context.sdkVersion
        basePath = context.filePathProvider.directoryURL(for: "imqa_crash_reporter")?.path

        let bundleName = context.appId ?? "default"
        
        ksCrash = KSCrash.shared
        let configuration = KSCrashConfiguration()
        configuration.monitors = [
            .all
        ]
        configuration.installPath = basePath
        configuration.reportStoreConfiguration.appName = bundleName
        configuration.crashNotifyCallback = { [weak self] writerPointer in
            let storage = IMQAMuti<SpanRecord>()
            let latestRecord = storage.get().first
            if let spanData = try? JSONEncoder().encode(latestRecord),
               let spanJSONString = String(data: spanData, encoding: .utf8) {
                // 使用低级 API 写入崩溃报告
                writerPointer.withMemoryRebound(to: ReportWriter.self, capacity: 1) { writer in
                    writer.pointee.addJSONElement(writer, UserInfoKey.crashSpan, spanJSONString, true)
                }
            }
        }
        updateKSCrashInfo()
        
        do {
            try ksCrash?.install(with: configuration)
        } catch  {
            logger.debug("crash install \(error.localizedDescription)")
        }
    }

    /// Fetches all saved `CrashReports`.
    /// - Parameter completion: Completion handler to be called with the fetched `CrashReports`
    public func fetchUnsentCrashReports(completion: @escaping ([CrashReport]) -> Void) {
        guard ksCrash != nil else {
            completion([])
            return
        }

        queue.async { [weak self] in
            guard let reports = self?.ksCrash?.reportStore?.reportIDs else {
                completion([])
                return
            }

            // get all report ids
            var crashReports: [CrashReport] = []
            for reportId in reports {
                let id = reportId

                // fetch report
                guard let report = self?.ksCrash?.reportStore?.report(for: id.int64Value)?.value as? [String: Any] else {
                    continue
                }
                // serialize json
                var payload: String?
                do {
                    let data = try JSONSerialization.data(withJSONObject: report)
                    if let json = String(data: data, encoding: String.Encoding.utf8) {
                        payload = json
                    } else {
                        self?.logger?.warning("Error serializing raw crash report \(reportId)!")
                    }
                } catch {
                    self?.logger?.warning("Error serializing raw crash report \(reportId)!")
                }

                guard let payload = payload else {
                    continue
                }

                // get custom data from report
                var sessionId: SessionIdentifier?
                var timestamp: Date?
                var crashSpan: SpanRecord?
                if let userDict = report["user"] as? [AnyHashable: Any] {
                    if let value = userDict[UserInfoKey.sessionId] as? String {
                        sessionId = SessionIdentifier(string: value)
                    }
                    if let info = userDict[UserInfoKey.crashSpan] as? [AnyHashable: Any]{
                        if let data = try? JSONSerialization.data(withJSONObject: info, options: []),
                            let span = try? JSONDecoder().decode(SpanRecord.self, from: data) {
                            crashSpan =  span
                        }
                    }
                }

                if let reportDict = report["report"] as? [AnyHashable: Any],
                   let rawTimestamp = reportDict["timestamp"] as? String {
                    timestamp = IMQACrashReporter.dateFormatter.date(from: rawTimestamp)
                }
                
                

                // add report
                let crashReport = CrashReport(
                    payload: payload,
                    provider: IMQACrashReporter.providerIdentifier,
                    internalId: id.intValue,
                    sessionId: sessionId?.toString,
                    timestamp: timestamp,
                    spanRecord: crashSpan
                )

                crashReports.append(crashReport)
            }

            completion(crashReports)
        }
    }

    /// Permanently deletes a crash report for the given identifier.
    /// - Parameter id: Identifier of the report to delete
    public func deleteCrashReport(id: Int) {
        ksCrash?.reportStore?.deleteReport(with: Int64(id))
    }

    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.formatterBehavior = .default
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul") // 设置韩国时区
        return formatter
    }
}

extension IMQACrashReporter: ExtendableCrashReporter {
    public func appendCrashInfo(key: String, value: String) {
        extraInfo[key] = value
    }
}

