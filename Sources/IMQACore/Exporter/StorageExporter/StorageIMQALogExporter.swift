//
//  StorageIMQALogExporter.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import IMQACommonInternal
import IMQAOtelInternal

class StorageIMQALogExporter: LogRecordExporter {

    @ThreadSafe
    private(set) var state: State
    private let logBatcher: LogBatcher
    private let validation: LogDataValidation

    enum State {
        case active
        case inactive
    }

    init(logBatcher: LogBatcher, state: State = .active, validators: [LogDataValidator] = .default) {
        self.state = state
        self.logBatcher = logBatcher
        self.validation = LogDataValidation(validators: validators)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSessionEnd),
            name: .imqaSessionWillEnd,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func onSessionEnd(noticication: Notification) {
        // forcefully start a new batch of logs when a session ends
        logBatcher.renewBatch(withLogs: [])
    }

    func export(logRecords: [ReadableLogRecord], explicitTimeout: TimeInterval?) -> ExportResult {
        guard state == .active else {
            return .failure
        }

        for var log in logRecords where validation.execute(log: &log) {

            // do not export crash logs
//            guard !log.isImqaType(LogType.crash) else {
//                continue
//            }

            self.logBatcher.addLogRecord(logRecord: buildLogRecord(from: log))
        }

        return .success
    }

    func shutdown(explicitTimeout: TimeInterval?) {
        state = .inactive
    }

    /// Everything is always persisted on disk, so calling this method has no effect at all.
    /// - Returns: `ExportResult.success`
    func forceFlush(explicitTimeout: TimeInterval?) -> ExportResult {
        .success
    }
}

private extension StorageIMQALogExporter {
    func buildLogRecord(from originalLog: ReadableLogRecord) -> LogRecord {
        let imqaAttributes = originalLog.attributes.reduce(into: [String: PersistableValue]()) {
            $0[$1.key] = PersistableValue(attributeValue: $1.value)
        }
        return .init(identifier: LogIdentifier(),
                     processIdentifier: ProcessIdentifier.current,
                     severity: originalLog.severity?.toLogSeverity() ?? .info,
                     body: originalLog.body?.description ?? "",
                     attributes: imqaAttributes,
                     timestamp: originalLog.timestamp,
                     spanContext: originalLog.spanContext)
    }
}

private extension PersistableValue {
    init?(attributeValue: AttributeValue) {
        switch attributeValue {
        case let .string(value):
            self.init(value)
        case let .bool(value):
            self.init(value)
        case let .int(value):
            self.init(value)
        case let .double(value):
            self.init(value)
        case let .stringArray(value):
            self.init(value)
        case let .boolArray(value):
            self.init(value)
        case let .intArray(value):
            self.init(value)
        case let .doubleArray(value):
            self.init(value)
        default:
            return nil
        }
    }
}
