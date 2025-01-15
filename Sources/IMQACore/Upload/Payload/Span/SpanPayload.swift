//
//  SpanPayload.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import IMQAOtelInternal

struct SpanPayload: Encodable {
    let traceId: String
    let spanId: String
    let parentSpanId: String?
    let name: String
    let kind: Int
    let startTimeUnixNano: String
    let endTimeUnixNano: String?
    let attributes:[SpanAttribute]
    let droppedAttributesCount:Int
    let events: [SpanEventPayload]
    let droppedEventsCount: Int
    let status: Status
    let links: [SpanLinkPayload]
    let droppedLinksCount: Int
    
    init(traceId: String,
         spanId: String,
         parentSpanId: String?,
         name: String,
         kind: Int,
         startTimeUnixNano: String,
         endTimeUnixNano: String,
         attributes: [SpanAttribute],
         droppedAttributesCount: Int,
         events: [SpanEventPayload],
         droppedEventsCount: Int,
         status: Status,
         links: [SpanLinkPayload],
         droppedLinksCount: Int) {
        
        self.traceId = traceId
        self.spanId = spanId
        self.parentSpanId = parentSpanId
        self.name = name
        self.kind = kind
        self.startTimeUnixNano = startTimeUnixNano
        self.endTimeUnixNano = endTimeUnixNano
        self.attributes = attributes
        self.droppedAttributesCount = droppedAttributesCount
        self.events = events
        self.droppedEventsCount = droppedEventsCount
        self.status = status
        self.links = links
        self.droppedLinksCount = droppedLinksCount
    }
    
    enum CodingKeys: CodingKey {
        case traceId
        case spanId
        case parentSpanId
        case name
        case kind
        case startTimeUnixNano
        case endTimeUnixNano
        case attributes
        case droppedAttributesCount
        case events
        case droppedEventsCount
        case status
        case links
        case droppedLinksCount
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.traceId, forKey: .traceId)
        try container.encode(self.spanId, forKey: .spanId)
        try container.encodeIfPresent(self.parentSpanId, forKey: .parentSpanId)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.kind, forKey: .kind)
        try container.encode(self.startTimeUnixNano, forKey: .startTimeUnixNano)
        try container.encodeIfPresent(self.endTimeUnixNano, forKey: .endTimeUnixNano)
        try container.encode(self.attributes, forKey: .attributes)
        try container.encode(self.droppedAttributesCount, forKey: .droppedAttributesCount)
        try container.encode(self.events, forKey: .events)
        try container.encode(self.droppedEventsCount, forKey: .droppedEventsCount)
        try container.encode(self.status, forKey: .status)
        try container.encode(self.links, forKey: .links)
        try container.encode(self.droppedLinksCount, forKey: .droppedLinksCount)
    }
    
    init(from span: SpanData, endTime: Date? = nil, failed: Bool = false) {
        self.traceId = span.traceId.hexString
        self.spanId = span.spanId.hexString
        self.parentSpanId = span.parentSpanId?.hexString
        self.name = span.name
        self.kind = 1
        self.startTimeUnixNano = String(span.startTime.nanosecondsSince1970Truncated)
        if let endTime = endTime {
            self.endTimeUnixNano = String(endTime.nanosecondsSince1970Truncated)
        } else if span.hasEnded {
            self.endTimeUnixNano = String(span.endTime.nanosecondsSince1970Truncated)
        } else {
            self.endTimeUnixNano = nil
        }
        self.droppedAttributesCount = 0
        self.droppedEventsCount = 0
        self.droppedLinksCount = 0

        self.events = span.events.map { SpanEventPayload(from: $0) }
        self.links = span.links.map { SpanLinkPayload(from: $0) }

        if span.status == .ok || !failed {
            self.status = span.status
        } else {
            self.status = Status.sessionCrashedError()
        }

        var attributeArray = PayloadUtils.converSpanAttributes(span.attributes)
        if failed {
#warning("fix me please")
//            attributeArray.append(SpanAttribute(key: SpanSemantics.keyErrorCode, value: SpanAttribute.Value(stringValue: "failure")))
        }

        self.attributes = attributeArray
    }

}

extension SpanPayload: Equatable {
    public static func == (lhs: SpanPayload, rhs: SpanPayload) -> Bool {
        return
            lhs.traceId == rhs.traceId &&
            lhs.spanId == rhs.spanId &&
            lhs.parentSpanId == rhs.parentSpanId &&
            lhs.name == rhs.name &&
            lhs.status == rhs.status &&
            lhs.endTimeUnixNano == rhs.endTimeUnixNano &&
            lhs.startTimeUnixNano == rhs.startTimeUnixNano &&
            lhs.events == rhs.events &&
            lhs.links == rhs.links &&
            lhs.droppedLinksCount == rhs.droppedLinksCount
    }
}



public struct SpanAttribute: Codable {
    var key: String?
    var value: Value?
    
    public struct Value: Codable {
        var stringValue: String?
        var boolValue: Bool?
        var intValue: Int?
        var doubleValue: Double?
        
        init(stringValue: String? = nil,
             boolValue: Bool? = nil,
             intValue: Int? = nil,
             doubleValue:Double? = nil) {
            self.stringValue = stringValue
            self.boolValue = boolValue
            self.intValue = intValue
            self.doubleValue = doubleValue
        }
    }
    
    init(key: String? = nil, value: Value? = nil) {
        self.key = key
        self.value = value
    }
    
}

extension SpanAttribute: Equatable {
    public static func == (lhs: SpanAttribute, rhs: SpanAttribute) -> Bool {
        return
            lhs.key == rhs.key &&
            lhs.value == rhs.value
    }
}

extension SpanAttribute.Value: Equatable{
    public static func == (lhs: SpanAttribute.Value, rhs: SpanAttribute.Value) -> Bool {
    return
        lhs.intValue == rhs.intValue ||
        lhs.boolValue == rhs.boolValue ||
        lhs.stringValue == rhs.stringValue ||
        lhs.doubleValue == rhs.doubleValue
    }

}
