//
//  LogPayloadBuilder.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/4.
//

import Foundation
import OpenTelemetrySdk
import OpenTelemetryApi

struct LogPayloadBuilder {
    static func build(log: LogRecord) -> LogPayload {
        var finalAttributes: [LogAttribute] = log.attributes.map { entry in
            LogAttribute(key: entry.key, value: LogAttribute.Value(stringValue: entry.value.description))
        }
        finalAttributes.append(.init(key: LogSemantics.keyId, value: LogAttribute.Value(stringValue: log.identifier.toString)))

                               
        return .init(timeUnixNano: String(Int(log.timestamp.nanosecondsSince1970)),
                     observedTimeUnixNano: String(Int(log.timestamp.nanosecondsSince1970)),
                     severityNumber: log.severity.number,
                     body: LogAttribute.Value(stringValue: log.body),
                     attributes: finalAttributes,
                     droppedAttributesCount: 0)
    }
    
    static func buildReadableLogRecord(log: LogRecord,
                                       resource: [String : AttributeValue]) -> ReadableLogRecord{
        let severity = Severity(rawValue: log.severity.number)
        let resource = Resource(attributes: resource)
        let date = log.timestamp
        let body = AttributeValue(log.body)
        let spanContext = log.spanContext
        var finalAttributes: [String: AttributeValue] = [:]
        log.attributes.map { entry in
            finalAttributes[entry.key] = AttributeValue(entry.value.description)
        }

        let scopeInfo = InstrumentationScopeInfo(name: "imqa.sdk.iOS", version: IMQAMeta.sdkVersion)
        
        return ReadableLogRecord(resource: resource,
                          instrumentationScopeInfo: scopeInfo,
                          timestamp: date,
                          observedTimestamp: date,
                                 spanContext: spanContext,
                          severity: severity,
                          body: body,
                          attributes: finalAttributes)
    }
    

    static func build(
        timestamp: Date,
        severity: LogSeverity,
        body: String,
        attributes: [String: String],
        storage: IMQAStorage?,
        sessionId: SessionIdentifier?
    ) -> PayloadEnvelope<[LogPayload]> {

        // build resources and metadata payloads
        var resources: [MetadataRecord] = []
        var metadata: [MetadataRecord] = []

        if let storage = storage {
            do {
                if let sessionId = sessionId {
                    resources = try storage.fetchResourcesForSessionId(sessionId)

                    let properties = try storage.fetchCustomPropertiesForSessionId(sessionId)
                    let tags = try storage.fetchPersonaTagsForSessionId(sessionId)
                    metadata.append(contentsOf: properties)
                    metadata.append(contentsOf: tags)
                } else {
                    resources = try storage.fetchResourcesForProcessId(ProcessIdentifier.current)
                    metadata = try storage.fetchPersonaTagsForProcessId(ProcessIdentifier.current)
                }
            } catch {
                IMQA.logger.error("Error fetching resources for crash log.")
            }
        }

        let finalAttributes: [LogAttribute] = attributes.map { entry in
            LogAttribute(key: entry.key, value: LogAttribute.Value(stringValue: entry.value))
        }

        let logPayload = LogPayload(timeUnixNano: String(timestamp.nanosecondsSince1970Truncated),
                                    observedTimeUnixNano: String(timestamp.nanosecondsSince1970Truncated),
                                    severityNumber: severity.rawValue,
                                    body: LogAttribute.Value(stringValue: body),
                                    attributes: finalAttributes,
                                    droppedAttributesCount: 0)
        
        return .init(
            data: [logPayload],
            resource: ResourcePayload(from: resources),
            metadata: MetadataPayload(from: metadata)
        )
    }
}
