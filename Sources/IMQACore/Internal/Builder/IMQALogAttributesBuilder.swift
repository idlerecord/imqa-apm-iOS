
//
//  IMQALogAttributesBuilder.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/29.
//
import IMQAOtelInternal
import IMQACommonInternal
import Foundation


class IMQALogAttributesBuilder {
    private weak var storage: IMQAStorageMetadataFetcher?
    private weak var sessionControllable: SessionControllable?
    private var session: SessionRecord?
    private var crashReport: CrashReport?
    private var attributes: [String: String]

    private var currentSession: SessionRecord? {
        session ?? sessionControllable?.currentSession
    }

    init(storage: IMQAStorageMetadataFetcher,
         sessionControllable: SessionControllable,
         initialAttributes: [String: String]) {
        self.storage = storage
        self.sessionControllable = sessionControllable
        self.attributes = initialAttributes
    }

    init(session: SessionRecord?,
         crashReport: CrashReport? = nil,
         initialAttributes: [String: String]) {
        self.session = session
        self.crashReport = crashReport
        self.attributes = initialAttributes
    }

    @discardableResult
    func addStackTrace(_ stackTrace: [String]) -> Self {
//        guard !stackTrace.isEmpty else {
//            return self
//        }
//        let processedStackTrace = EMBStackTraceProccessor.processStackTrace(stackTrace)
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: processedStackTrace, options: [])
//            let stackTraceInBase64 = jsonData.base64EncodedString()
//            attributes[LogSemantics.keyStackTrace] = stackTraceInBase64
//        } catch let exception {
//            IMQA.logger.error("Couldn't convert stack trace to json string: \(exception.localizedDescription)")
//        }
        return self
    }

    /// Makes sure that `emb.type` attribute is not already set in attributes
    /// If not set, will set the `emb.type` to the value
    @discardableResult
    func addLogType(_ logType: IMQALogType) -> Self {
//        guard attributes[LogSemantics.keyIMQAType] == nil else {
//            return self
//        }
//        attributes[CommonSpanSemantics.imqaSpanType] = logType.rawValue
        return self
    }

    @discardableResult
    func addApplicationProperties() -> Self {
//        guard let sessionId = currentSession?.id,
//              let storage = storage else {
//            return self
//        }
//        if let customProperties = try? storage.fetchCustomPropertiesForSessionId(sessionId) {
//            customProperties.forEach { record in
//                guard UserResourceKey(rawValue: record.key) == nil else {
//                    // prevent UserResource keys from appearing in properties
//                    // will be sent in MetadataPayload instead
//                    return
//                }
//
//                if let value = record.stringValue {
//                    let key = String(format: LogSemantics.keyPropertiesPrefix, record.key)
//                    attributes[key] = value
//                }
//            }
//        }
        return self
    }

    @discardableResult
    func addApplicationState() -> Self {
//        guard let state = currentSession?.state else {
//            return self
//        }
//        attributes[LogSemantics.keyState] = state
        return self
    }

    @discardableResult
    func addSessionIdentifier() -> Self {
//        guard let sessionId = currentSession?.id else {
//            return self
//        }
//        attributes[LogSemantics.keySessionId] = sessionId.toString
        return self
    }

    @discardableResult
    func addCrashReportProperties() -> Self {
        guard let crashReport = crashReport else {
            return self
        }

#warning("fix me")
//        attributes[LogSemantics.Crash.keyId] = crashReport.id.withoutHyphen
//        attributes[LogSemantics.Crash.keyProvider] = crashReport.provider
//        attributes[LogSemantics.Crash.keyPayload] = crashReport.payload

        return self
    }
    @discardableResult
    func addTag(tag: String) -> Self {
        attributes["Tag"] = tag
        return self
    }
    
//    @discardableResult
//    func getCrashSpanContext() -> SpanContext{
//        
//    }
    

    func build() -> [String: String] {
        attributes
    }
}
