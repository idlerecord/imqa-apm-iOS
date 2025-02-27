//
//  LogController.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation
import OpenTelemetrySdk
import OpenTelemetryApi
//import OpenTelemetryProtocolExporterCommon
import IMQAOtelInternal
import IMQACommonInternal

protocol LogControllable: LogBatcherDelegate {
    func uploadAllPersistedLogs()
}

class LogController: LogControllable {
    private(set) weak var sessionController: SessionControllable?
    private weak var storage: Storage?
    private weak var upload: IMQALogUploader?
    static let maxLogsPerBatch: Int = 20

    
    init(storage: Storage?,
         upload:IMQALogUploader?,
         sessionController: SessionControllable) {
        self.storage = storage
        self.upload = upload
        self.sessionController = sessionController
    }
    
    func uploadAllPersistedLogs() {
        guard let storage = storage else {
            return
        }
        do {
            let logs: [LogRecord] = try storage.fetchAll(excludingProcessIdentifier: .current)
            if logs.count > 0 {
                send(batches: divideInBatches(logs))
            }
        } catch let exception {
            Error.couldntAccessBatches(reason: exception.localizedDescription).log()
            try? storage.removeAllLogs()
        }
    }
}

extension LogController {
    func batchFinished(withLogs logs: [LogRecord]) {
        do {
            guard let sessionId = sessionController?.currentSession?.id, logs.count > 0 else {
                return
            }
            send(logs: logs)
        } catch let exception {
            Error.couldntCreatePayload(reason: exception.localizedDescription).log()
        }
    }
}

private extension LogController{
    func send(batches: [LogsBatch]) {
        guard batches.count > 0 else {
            return
        }

        for batch in batches {
            do {
                guard batch.logs.count > 0 else {
                    continue
                }

                // Since we always end batches when a session ends
                // all the logs still in storage when the app starts should come
                // from the last session before the app closes.
                //
                // We grab the first valid sessionId from the stored logs
                // and assume all of them come from the same session.
                //
                // If we can't find a sessionId, we use the processId instead
                send(logs: batch.logs)
            } catch let exception {
                Error.couldntCreatePayload(reason: exception.localizedDescription).log()
            }
        }
    }

    func send(logs: [LogRecord]) {
        guard let upload = upload else {
            return
        }
                
        let readableLogs = logs.map{LogPayloadBuilder.buildReadableLogRecord(log: $0, resource: [:])}
        let data = PayloadEnvelope<LogPayload>.requestLogProtobufData(logRecords: readableLogs)
        guard let envelopeData = data else{ return }
        do {
            upload.uploadLog(id: UUID().uuidString, data: envelopeData) { [weak self] result in
                guard let self = self else {
                    return
                }
                if case Result.failure(let error) = result {
                    Error.couldntUpload(reason: error.localizedDescription).log()
                    return
                }

                try? self.storage?.remove(logs: logs)
            }
        } catch let exception {
            Error.couldntCreatePayload(reason: exception.localizedDescription).log()
        }
    }

    func divideInBatches(_ logs: [LogRecord]) -> [LogsBatch] {
        var batches: [LogsBatch] = []
        var batch: LogsBatch = .init(limits: .init(maxBatchAge: .infinity, maxLogsPerBatch: Self.maxLogsPerBatch))
        for log in logs {
            let result = batch.add(logRecord: log)
            switch result {
            case .success(let batchState):
                if batchState == .closed {
                    batches.append(batch)
                    batch = LogsBatch(limits: .init(maxLogsPerBatch: Self.maxLogsPerBatch))
                }
            case .failure:
                // This shouldn't happen.
                // However, we add this logic to ensure everything works fine
                batches.append(batch)
                batch = LogsBatch(limits: .init(), logs: [log])
            }
        }
        if batch.batchState != .closed && !batch.logs.isEmpty {
            batches.append(batch)
        }
        return batches
    }
}

extension LogController {
    enum Error: LocalizedError, CustomNSError {
        case couldntAccessStorageModule
        case couldntAccessUploadModule
        case couldntUpload(reason: String)
        case couldntCreatePayload(reason: String)
        case couldntAccessBatches(reason: String)

        public static var errorDomain: String {
            return "IMQA"
        }

        public var errorCode: Int {
            switch self {
            case .couldntAccessStorageModule:
                -1
            case .couldntAccessUploadModule:
                -2
            case .couldntCreatePayload:
                -3
            case .couldntUpload:
                -4
            case .couldntAccessBatches:
                -5
            }
        }

        public var errorDescription: String? {
            switch self {
            case .couldntAccessStorageModule:
                "Couldn't access to the storage layer"
            case .couldntAccessUploadModule:
                "Couldn't access to the upload module"
            case .couldntUpload(let reason):
                "Couldn't upload logs: \(reason)"
            case .couldntCreatePayload(let reason):
                "Couldn't create payload: \(reason)"
            case .couldntAccessBatches(let reason):
                "There was a problem fetching batches: \(reason)"
            }
        }

        public var localizedDescription: String {
            return self.errorDescription ?? "No Matching Error"
        }

        func log() {
            IMQA.logger.error(localizedDescription)
        }
    }
}
