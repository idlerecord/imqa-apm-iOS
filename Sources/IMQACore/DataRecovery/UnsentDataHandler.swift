//
//  UnsentDataHandler.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import IMQACommonInternal
import IMQAOtelInternal


class UnsentDataHandler {
    static func sendUnsentData(
        storage: IMQAStorage?,
        upload: IMQAUpload?,
        otel: IMQAOpenTelemetry?,
        logController: LogControllable? = nil,
        currentSessionId: SessionIdentifier? = nil,
        crashReporter: CrashReporter? = nil
    ) {

        guard let storage = storage,
              let upload = upload else {
            return
        }

        // send any logs in storage first before we clean up the resources
        logController?.uploadAllPersistedLogs()

        // if we have a crash reporter, we fetch the unsent crash reports first
        // and save their identifiers to the corresponding sessions
        if let crashReporter = crashReporter {
            crashReporter.fetchUnsentCrashReports { reports in
                sendCrashReports(
                    storage: storage,
                    upload: upload,
                    otel: otel,
                    currentSessionId: currentSessionId,
                    crashReporter: crashReporter,
                    crashReports: reports
                )
            }
        } else {
            sendSessions(storage: storage, upload: upload, currentSessionId: currentSessionId)
        }
    }

    static private func sendCrashReports(
        storage: IMQAStorage,
        upload: IMQAUpload,
        otel: IMQAOpenTelemetry?,
        currentSessionId: SessionIdentifier?,
        crashReporter: CrashReporter,
        crashReports: [CrashReport]
    ) {
        // send crash reports
        for report in crashReports {

            // link session with crash report if possible
            var session: SessionRecord?

            if let sessionId = SessionIdentifier(string: report.sessionId) {
                session = storage.fetchSession(id: sessionId)
                if let session = session {
                    // update session's end time with the crash report timestamp
                    session.endTime = report.timestamp ?? session.endTime
                    
                    // update crash report id
                    session.crashReportId = report.id.uuidString
                    
                    storage.update(session: session)
                }
                recordCrashSpan(report: report, sessionId: sessionId.toString)
            }

            
            // send crash log
            sendCrashLog(
                report: report,
                reporter: crashReporter,
                session: session,
                storage: storage,
                upload: upload,
                otel: otel
            )
        }

        // send sessions
        sendSessions(
            storage: storage,
            upload: upload,
            currentSessionId: currentSessionId
        )
    }
    
    static func convertStringToDictionary(jsonString: String) -> [String: Any]? {
        guard let data = jsonString.data(using: .utf8) else {
            print("string to data conversion failed")
            return nil
        }
        
        do {
            if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return dictionary
            }
        } catch {
            print("JSON분석 실패: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    static func convertDictionaryToString(dictionary: [String: Any]) -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            print("JSON serialization failed: \(error.localizedDescription)")
        }
        
        return nil
    }

    
    static public func recordCrashSpan(report:CrashReport, sessionId: String){
        var exceptionMessage: String = ""
        var exceptionType: String = ""
        var stackTrace: [String] = []
        let reportDict = convertStringToDictionary(jsonString: report.payload)
        if let crashInfo = reportDict?["crash"] as? [String: Any] {
            if let crashError = crashInfo["error"] as? [String : Any]{
                if let matchDict = crashError["match"] as? [String: Any]{
                    if let exceptionName = matchDict["exception_name"] as? String   {
                        exceptionMessage = "Crash occurred with exception:\(exceptionName)"
                    }
                }
                if let type = crashError["type"] as? String {
                    exceptionType = type
                }
            }
            if let threads = crashInfo["threads"] as? [Any] {
                let crashedItem = threads.filter{
                    guard let item = ($0 as? [String: Any]) else{
                        return false
                    }
                    if let crashed = item["crashed"] as? Bool{
                        return crashed
                    }
                    return false
                }.first
                if let crashedDict = crashedItem as? [String: Any] {
                    if let backtrace = crashedDict["backtrace"] as? [String : Any] {
                        if let contents = backtrace["contents"] as? [Any]{
                            for item in contents {
                                if let item = (item as? [String: Any]) {
                                    if let str = convertDictionaryToString(dictionary: item){
                                        stackTrace.append(str)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        let spanException = IMQACrashError(message: exceptionMessage, type: exceptionType, stackTrace: stackTrace)
        var attributes:[String: AttributeValue] = [:]
        
//#if DEBUG
//        var type = ["TypeA", "TypeB", "TypeC", "TypeD"]
//        var message = ["messageA", "messageB", "messageC", "messageD", "messageE"]
//        let typeIndex = arc4random() % 4
//        let messageIndex = arc4random() % 5
//        
//        attributes[SemanticAttributes.exceptionType.rawValue] = AttributeValue(type[Int(typeIndex)])
//        attributes[SemanticAttributes.exceptionMessage.rawValue] = AttributeValue(message[Int(messageIndex)])
//        attributes[SemanticAttributes.exceptionStacktrace.rawValue] = AttributeValue(spanException.stackTrace)
//
//#else
//        attributes[SemanticAttributes.exceptionType.rawValue] = AttributeValue(spanException.type)
//        attributes[SemanticAttributes.exceptionMessage.rawValue] = AttributeValue(spanException.message)
//        attributes[SemanticAttributes.exceptionStacktrace.rawValue] = AttributeValue(spanException.stackTrace)
//#endif

        attributes[SemanticAttributes.exceptionType.rawValue] = AttributeValue(spanException.type)
        if let message = spanException.message{
            attributes[SemanticAttributes.exceptionMessage.rawValue] = AttributeValue(message)
        }
        if let stackTrace = spanException.stackTrace{
            attributes[SemanticAttributes.exceptionStacktrace.rawValue] = AttributeValue(stackTrace)
        }
        attributes[SpanSemantics.Common.sessionId] = AttributeValue(sessionId)

        let span = SpanUtils.span(name: exceptionType,
                                  startTime: Date(),
                                  type: .CRASH,
                                  attributes: attributes)
        span.recordException(spanException, attributes: [:], timestamp: Date())
        
        span.status = .error(description: exceptionMessage)
        span.end()
        
        var stringAttributes: [String: String] = [:]
        for (key, value) in attributes {
            if case let .string(stringValue) = value {
                stringAttributes[key] = stringValue
            }
        }
        IMQA.logger.traceLog(message: exceptionType,
                             spanContext: span.context,
                             logType: .CRASH,
                             attributes: stringAttributes,
                             severity: .error)

//        if let data = report.spanRecord?.data{
//            let spanData = try? JSONDecoder().decode(SpanData.self, from: data)
//            if let spanData = spanData {
//                let spanContext = SpanContext.create(traceId: spanData.traceId,
//                                                     spanId: spanData.spanId,
//                                                     traceFlags: spanData.traceFlags,
//                                                     traceState: spanData.traceState)
//                
//                IMQA.logger.traceLog(message: exceptionType,
//                                     spanContext: spanContext,
//                                     logType: .CRASH,
//                                     attributes: [:])
//            }
//        }
    }

    static public func sendCrashLog(
        report: CrashReport,
        reporter: CrashReporter?,
        session: SessionRecord?,
        storage: IMQAStorage?,
        upload: IMQAUpload?,
        otel: IMQAOpenTelemetry?
    ) {
        let timestamp = (report.timestamp ?? session?.lastHeartbeatTime) ?? Date()

        // send otel log
        let attributes = createLogCrashAttributes(
            otel: otel,
            report: report,
            session: session,
            timestamp: timestamp
        )

        guard let upload = upload else {
            return
        }

        // upload crash log
        do {
            let payload = LogPayloadBuilder.build(
                timestamp: timestamp,
                severity: LogSeverity.fatal,
                body: "",
                attributes: attributes,
                storage: storage,
                sessionId: session?.id
            )
            
            let payloadData = try JSONEncoder().encode(payload).gzipped()
            
            upload.uploadCrash(id: report.id.uuidString, data: payloadData) { result in
                switch result {
                case .success:
                    // remove crash report
                    // we can remove this immediately because the upload module will cache it until the upload succeeds
                    if let internalId = report.internalId {
                        guard let reporter = reporter else {
                            return
                        }
                        reporter.deleteCrashReport(id: internalId)
                    }

                case .failure(let error):
                    IMQA.logger.warning("Error trying to upload crash report \(report.id):\n\(error.localizedDescription)")
                }
            }

        } catch {
            IMQA.logger.warning("Error encoding crash report \(report.id) for session \(String(describing: report.sessionId)):\n" + error.localizedDescription)
        }
    }

    static private func createLogCrashAttributes(
        otel: IMQAOpenTelemetry?,
        report: CrashReport,
        session: SessionRecord?,
        timestamp: Date
    ) -> [String: String] {

        let attributesBuilder = IMQALogAttributesBuilder(
            session: session,
            crashReport: report,
            initialAttributes: [:]
        )
        
        let attributes = attributesBuilder
            .addLogType(IMQALogType.CRASH)
            .addApplicationProperties()
            .addApplicationState()
            .addCrashReportProperties()
            .addTag(tag: "SDKInitializer")
            .build()

        return attributes
    }

    static private func sendSessions(
        storage: IMQAStorage,
        upload: IMQAUpload,
        currentSessionId: SessionIdentifier?
    ) {

        // clean up old spans + close open spans
        cleanOldSpans(storage: storage)
        closeOpenSpans(storage: storage, currentSessionId: currentSessionId)

        // fetch all sessions in the storage
        var sessions: [SessionRecord]
        do {
            sessions = try storage.fetchAll()
        } catch {
            IMQA.logger.warning("Error fetching unsent sessions:\n\(error.localizedDescription)")
            return
        }

        for session in sessions {
            // ignore current session
            if let currentSessionId = currentSessionId,
               currentSessionId == session.id {
                continue
            }

            sendSession(session, storage: storage, upload: upload, performCleanUp: false)
        }

        // remove old metadata
        cleanMetadata(storage: storage, currentSessionId: currentSessionId?.toString)
    }

    static public func sendSession(
        _ session: SessionRecord,
        storage: IMQAStorage,
        upload: IMQAUpload,
        performCleanUp: Bool = true
    ) {
        // create payload
        let payload = SessionPayloadBuilder.buildSpanRequestData(for: session, storage: storage)
        guard let payloadData = payload else {
            return
        }
        // upload session spans
#warning("fix me please payloadData havn't been emptied")
        if payloadData.isEmpty {
            let storage = IMQAMuti<SessionRecord>()
            storage.remove(session.vvid)
            return
        }
        upload.uploadSpans(id: session.id.toString, data: payloadData) { result in
            switch result {
            case .success:
                do {
                    // remove session from storage
                    // we can remove this immediately because the upload module will cache it until the upload succeeds
                    try storage.delete(session: session)

                    if performCleanUp {
                        cleanOldSpans(storage: storage)
                        cleanMetadata(storage: storage)
                    }

                } catch {
                    IMQA.logger.debug("Error trying to remove session \(session.id):\n\(error.localizedDescription)")
                }

            case .failure(let error):
                IMQA.logger.warning("Error trying to upload session \(session.id):\n\(error.localizedDescription)")
            }
        }
    }

    static private func cleanOldSpans(storage: IMQAStorage) {
        do {
            // first we delete any span record that is closed and its older
            // than the oldest session we have on storage
            // since spans are only sent when included in a session
            // all of these would never be sent anymore, so they can be safely removed
            // if no session is found, all closed spans can be safely removed as well
            let oldestSession = try storage.fetchOldestSession()
            try storage.cleanUpSpans(date: oldestSession?.startTime)

        } catch {
            IMQA.logger.warning("Error cleaning old spans:\n\(error.localizedDescription)")
        }
    }

    static private func closeOpenSpans(storage: IMQAStorage, currentSessionId: SessionIdentifier?) {
        do {
            // then we need to close any remaining open spans
            // we use the latest session on storage to determine the `endTime`
            // since we need to have a valid `endTime` for these spans, we default
            // to `Date()` if we don't have a session
            let latestSession = try storage.fetchLatestSession(ignoringCurrentSessionId: currentSessionId)
            let endTime = (latestSession?.endTime ?? latestSession?.lastHeartbeatTime) ?? Date()
            try storage.closeOpenSpans(endTime: endTime)
        } catch {
            IMQA.logger.warning("Error closing open spans:\n\(error.localizedDescription)")
        }
    }

    static private func cleanMetadata(storage: IMQAStorage, currentSessionId: String? = nil) {
        do {
            let sessionId = currentSessionId ?? IMQA.client?.currentSessionId()
            try storage.cleanMetadata(currentSessionId: sessionId, currentProcessId: ProcessIdentifier.current.hex)
        } catch {
            IMQA.logger.warning("Error cleaning up metadata:\n\(error.localizedDescription)")
        }
    }
}

