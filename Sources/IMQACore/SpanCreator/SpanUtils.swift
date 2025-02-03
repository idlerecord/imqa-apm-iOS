//
//  SpanUtils.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//
import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import IMQACommonInternal
import IMQAOtelInternal


internal struct SpanAttributesUtils {
    @ThreadSafe
    public static var spanCommonAttributes:[String: AttributeValue] = [:]
    
    public static func updateCommonAttributes(key: String, value: AttributeValue){
        //推荐 在这里判断开关
        spanCommonAttributes.updateValue(value, forKey: key)
    }
}

struct SessionSpanUtils {
    static func span(id: SessionIdentifier, startTime: Date, state: SessionState) -> Span {
        IMQAOTel().buildSpan(name: SpanSemantics.Session.name, type: .SESSION)
            .setStartTime(time: startTime)
            .setSpanKind(spanKind: .client)
            .setAttribute(key: SpanSemantics.Common.sessionId, value: id.toString)
            .setAttribute(key: SpanSemantics.Applifecycle.appLifecycle, value: state.rawValue)
            .setCommonSpanAttributes(attributes:SpanAttributesUtils.spanCommonAttributes)
            .startSpan()
    }
    
    static func setName(span: Span?, name: String){
        span?.name = name
    }
    
    static func setState(span: Span?, state: SessionState) {
        span?.setAttribute(key: SpanSemantics.Session.keyState, value: state.rawValue)
    }
    
    static func setHeartbeat(span: Span?, heartbeat: Date) {
        span?.setAttribute(key: SpanSemantics.Session.keyHeartbeat, value: heartbeat.nanosecondsSince1970Truncated)
    }
    
    static func setTerminated(span: Span?, terminated: Bool) {
        span?.setAttribute(key: SpanSemantics.Session.keyTerminated, value: terminated)
    }
    
    static func setCleanExit(span: Span?, cleanExit: Bool) {
        span?.setAttribute(key: SpanSemantics.Session.keyCleanExit, value: cleanExit)
    }
    
    static func setSpanType(span: Span?, type: IMQASpanType){
        span?.setAttribute(key: SpanSemantics.spanType, value: type.rawValue)
    }
    
    static func payload(
        from session: SessionRecord,
        spanData: SpanData? = nil,
        properties: [MetadataRecord] = [],
        sessionNumber: Int
    ) -> SpanPayload {
        return SpanPayload(from: session, spanData: spanData, properties: properties, sessionNumber: sessionNumber)
    }

}

public struct SpanUtils{
    static func span(name: String,
                     parentSpan: Span? = nil,
                     startTime: Date,
                     type: IMQASpanType,
                     attributes:[String: AttributeValue] = [:])-> Span{
        if let parentSpan = parentSpan {
            return IMQAOTel().buildSpan(name: name, type: type)
                .setStartTime(time: startTime)
                .setSpanKind(spanKind: .client)
                .setParent(parentSpan)
                .setCommonSpanAttributes(attributes:SpanAttributesUtils.spanCommonAttributes)
                .setAttributes(attributes: attributes)
                .startSpan()
        }else{
            return IMQAOTel().buildSpan(name: name, type: type)
                .setStartTime(time: startTime)
                .setSpanKind(spanKind: .client)
                .setCommonSpanAttributes(attributes: SpanAttributesUtils.spanCommonAttributes)
                .setAttributes(attributes: attributes)
                .startSpan()
        }
    }
}


fileprivate extension SpanPayload {
    init(
        from session: SessionRecord,
        spanData: SpanData? = nil,
        properties: [MetadataRecord],
        sessionNumber: Int
    ) {
        self.traceId = session.traceId
        self.spanId = session.spanId
        self.parentSpanId = nil
        self.name = SpanSemantics.Session.name
        self.status = session.crashReportId != nil ? Status.sessionCrashedError() : Status.ok
        self.startTimeUnixNano = String(session.startTime.nanosecondsSince1970Truncated)
        self.endTimeUnixNano = String(session.endTime?.nanosecondsSince1970Truncated ??
                                      session.lastHeartbeatTime.nanosecondsSince1970Truncated)
        
        var attributeArray: [SpanAttribute] = [
            SpanAttribute(key: SpanSemantics.spanType, value: SpanAttribute.Value(stringValue: IMQASpanType.SESSION.rawValue)),
            SpanAttribute(key: SpanSemantics.Session.keyId, value: SpanAttribute.Value(stringValue: session.id.toString)),
            SpanAttribute(key: SpanSemantics.Session.keyState, value: SpanAttribute.Value(stringValue: session.state)),
            SpanAttribute(key: SpanSemantics.Session.keyColdStart, value: SpanAttribute.Value(stringValue: String(session.coldStart))),
            SpanAttribute(key: SpanSemantics.Session.keyTerminated, value: SpanAttribute.Value(stringValue: String(session.appTerminated))),
            SpanAttribute(key: SpanSemantics.Session.keyCleanExit, value: SpanAttribute.Value(stringValue: String(session.cleanExit))),
            SpanAttribute(key: SpanSemantics.Session.keyHeartbeat, value: SpanAttribute.Value(stringValue: String(session.lastHeartbeatTime.nanosecondsSince1970Truncated))),
            SpanAttribute(key: SpanSemantics.Session.keySessionNumber, value: SpanAttribute.Value(stringValue: String(sessionNumber)))
        ]
        
        if let crashId = session.crashReportId {
            attributeArray.append(SpanAttribute(key: SpanSemantics.Session.keyCrashId, value: SpanAttribute.Value(stringValue: crashId)))
        }
        
        attributeArray.append(
            contentsOf: properties.compactMap { record in
                guard !record.key.starts(with: "imqa.user") else {
                    return nil
                }
                return SpanAttribute(key: String(format: "imqa.properties.%@", record.key),
                                     value: SpanAttribute.Value(stringValue: record.value.description))
            }
        )
        
        self.attributes = attributeArray
        
        if let spanData = spanData {
            self.events = spanData.events.map { SpanEventPayload(from: $0) }
            self.links = spanData.links.map { SpanLinkPayload(from: $0) }
        } else {
            self.events = []
            self.links = []
        }
        
        self.droppedAttributesCount = 0
        self.kind = 1
        self.droppedEventsCount = 0
        self.droppedLinksCount = 0
    }
}


internal extension OpenTelemetryApi.Status {
    static func sessionCrashedError() -> Status {
        return Status.error(description: "Session crashed!")
    }
}

