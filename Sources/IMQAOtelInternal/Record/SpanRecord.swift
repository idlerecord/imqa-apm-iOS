//
//  SpanRecord.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//

import Foundation
import IMQACommonInternal

/// Represents a span in the storage
public class SpanRecord: Codable, VVIdenti {
    public var id: String
    public var name: String
    public var traceId: String
    public var type: IMQASpanType
    public var data: Data
    public var startTime: Date
    public var endTime: Date?
    public var processIdentifier: ProcessIdentifier
    
    public var vvid: String {
        id
    }
    
    public init(
        id: String,
        name: String,
        traceId: String,
        type: IMQASpanType,
        data: Data,
        startTime: Date,
        endTime: Date? = nil,
        processIdentifier: ProcessIdentifier = .current
    ) {
        self.id = id
        self.traceId = traceId
        self.type = type
        self.data = data
        self.startTime = startTime
        self.endTime = endTime
        self.name = name
        self.processIdentifier = processIdentifier
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.traceId, forKey: .traceId)
        try container.encode(self.type.rawValue, forKey: .type)
        try container.encode(self.data, forKey: .data)
        try container.encode(self.startTime, forKey: .startTime)
        try container.encodeIfPresent(self.endTime, forKey: .endTime)
        try container.encode(self.processIdentifier, forKey: .processIdentifier)
    }
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case traceId
        case type
        case data
        case startTime
        case endTime
        case processIdentifier
    }
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.traceId = try container.decode(String.self, forKey: .traceId)
        self.type = try container.decode(IMQASpanType.self, forKey: .type)
        self.data = try container.decode(Data.self, forKey: .data)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        self.processIdentifier = try container.decode(ProcessIdentifier.self, forKey: .processIdentifier)
    }
}
