//
//  CrashSpanRecord.swift
//  IMQAIO
//
//  Created by Hunta Park on 2/26/25.
//

import Foundation
import IMQACommonInternal
import IMQAOtelInternal

public class CrashSpanRecord: Codable, VVIdenti{
    public var id: String
    public var name: String
    public var traceId: String
    public var type: IMQASpanType
    public var data: Data
    public var startTime: Date
    public var endTime: Date?
    public var processIdentifier: ProcessIdentifier
    public var sessionId: String
    
    public var vvid: String {
        sessionId
    }
    
    public convenience init(spanRecord: SpanRecord, sessionId: String){
        self.init(id: spanRecord.id,
                  name: spanRecord.name,
                  traceId: spanRecord.traceId,
                  type: spanRecord.type,
                  data: spanRecord.data,
                  startTime: spanRecord.startTime,
                  endTime: spanRecord.endTime,
                  processIdentifier: spanRecord.processIdentifier,
                  sessionId: sessionId)
    }
    
    public init(id: String,
                name: String,
                traceId: String,
                type: IMQASpanType,
                data: Data,
                startTime: Date,
                endTime: Date? = nil,
                processIdentifier: ProcessIdentifier,
                sessionId: String) {
        self.id = id
        self.name = name
        self.traceId = traceId
        self.type = type
        self.data = data
        self.startTime = startTime
        self.endTime = endTime
        self.processIdentifier = processIdentifier
        self.sessionId = sessionId
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case traceId
        case type
        case data
        case startTime
        case endTime
        case processIdentifier
        case sessionId
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.traceId, forKey: .traceId)
        try container.encode(self.type.rawValue, forKey: .type)
        try container.encode(self.data, forKey: .data)
        try container.encode(self.startTime, forKey: .startTime)
        try container.encodeIfPresent(self.endTime, forKey: .endTime)
        try container.encode(self.processIdentifier, forKey: .processIdentifier)
        try container.encode(self.sessionId, forKey: .sessionId)
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
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
    }
    
}

public extension CrashSpanRecord{
    func toSpanRecord() -> SpanRecord{
        return SpanRecord(id: self.id,
                          name: self.name,
                          traceId: self.traceId,
                          type: self.type,
                          data: self.data,
                          startTime: self.startTime,
                          endTime: self.endTime,
                          processIdentifier: self.processIdentifier)
    }
}
