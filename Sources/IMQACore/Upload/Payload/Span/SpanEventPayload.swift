//
//  SpanEventPayload.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation
import OpenTelemetryProtocolExporterCommon
import IMQAOtelInternal

struct SpanEventPayload: Encodable {
    let name: String
    let timeUnixNano: String
    let droppedAttributesCount:Int
    let attributes: [SpanAttribute]

    enum CodingKeys: CodingKey {
        case name
        case timeUnixNano
        case droppedAttributesCount
        case attributes
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.timeUnixNano, forKey: .timeUnixNano)
        try container.encode(self.droppedAttributesCount, forKey: .droppedAttributesCount)
        try container.encode(self.attributes, forKey: .attributes)
    }
    
    init(name: String,
         timeUnixNano: String,
         droppedAttributesCount: Int,
         attributes: [SpanAttribute]) {
        self.name = name
        self.timeUnixNano = timeUnixNano
        self.droppedAttributesCount = droppedAttributesCount
        self.attributes = attributes
    }
    
    init(from event: SpanEvent) {
        self.name = event.name
        self.timeUnixNano =  String(event.timestamp.nanosecondsSince1970Truncated)
        self.attributes = PayloadUtils.converSpanAttributes(event.attributes)
        self.droppedAttributesCount = 0
    }
}

extension SpanEventPayload: Equatable {
    public static func == (lhs: SpanEventPayload, rhs: SpanEventPayload) -> Bool {
        return
            lhs.name == rhs.name &&
            lhs.timeUnixNano == rhs.timeUnixNano &&
            lhs.droppedAttributesCount == rhs.droppedAttributesCount
    }
}
