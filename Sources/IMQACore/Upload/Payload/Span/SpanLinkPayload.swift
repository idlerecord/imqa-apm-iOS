//
//  SpanLinkPayload.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//


import Foundation
//import OpenTelemetryProtocolExporterCommon
import OpenTelemetryApi
import IMQAOtelInternal

struct SpanLinkPayload: Codable {
    let traceId: String
    let spanId: String
    let traceState: TraceState
    let attributes: [SpanAttribute]
    let droppedAttributesCount: Int
    
    init(traceId: String,
         spanId: String,
         traceState: TraceState,
         attributes: [SpanAttribute],
         droppedAttributesCount: Int) {
        self.traceId = traceId
        self.spanId = spanId
        self.traceState = traceState
        self.attributes = attributes
        self.droppedAttributesCount = droppedAttributesCount
    }
    
    init(from link: SpanLink){
        self.traceId = link.context.traceId.hexString
        self.spanId = link.context.spanId.hexString
        self.attributes = PayloadUtils.converSpanAttributes(link.attributes)
        self.traceState = link.context.traceState
        self.droppedAttributesCount = 0
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.traceId, forKey: .traceId)
        try container.encode(self.spanId, forKey: .spanId)
        try container.encode(self.traceState, forKey: .traceState)
        try container.encode(self.attributes, forKey: .attributes)
        try container.encode(self.droppedAttributesCount, forKey: .droppedAttributesCount)
    }
}

extension SpanLinkPayload: Equatable {
    public static func == (lhs: SpanLinkPayload, rhs: SpanLinkPayload) -> Bool {
        return
            lhs.traceId == rhs.traceId &&
            lhs.spanId == rhs.spanId &&
            lhs.traceState == rhs.traceState &&
            lhs.attributes == rhs.attributes &&
            lhs.droppedAttributesCount == rhs.droppedAttributesCount
    }
}
