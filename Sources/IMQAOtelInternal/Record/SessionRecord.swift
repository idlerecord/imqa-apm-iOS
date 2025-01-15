//
//  SessionRecord.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//
import Foundation
import IMQACommonInternal

#if canImport(UIKit) && !os(watchOS)
import UIKit

public class SessionRecord: Codable, VVIdenti {
    
    public var id: SessionIdentifier
    public var processId: ProcessIdentifier
    public var state: String
    public var traceId: String
    public var spanId: String
    public var startTime: Date
    public var endTime: Date?
    public var lastHeartbeatTime: Date
    public var crashReportId: String?
    
    /// Used to mark if the session is the first to occur during this process
    public var coldStart: Bool

    /// Used to mark the session ended in an expected manner
    public var cleanExit: Bool

    /// Used to mark the session that is active when the application was explicitly terminated by the user and/or system
    public var appTerminated: Bool

    public var vvid: String{
        return id.toString
    }
    
    public init(id: SessionIdentifier,
         processId: ProcessIdentifier,
         state: String,
         traceId: String,
         spanId: String,
         startTime: Date,
         endTime: Date? = nil,
         lastHeartbeatTime: Date? = nil,
         crashReportId: String? = nil,
         coldStart: Bool = false,
         cleanExit: Bool = false,
         appTerminated: Bool = false) {
        
        self.id = id
        self.processId = processId
        self.state = state
        self.traceId = traceId
        self.spanId = spanId
        self.startTime = startTime
        self.endTime = endTime
        self.lastHeartbeatTime = lastHeartbeatTime ?? startTime
        self.crashReportId = crashReportId
        self.coldStart = coldStart
        self.cleanExit = cleanExit
        self.appTerminated = appTerminated
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.processId, forKey: .processId)
        try container.encode(self.state, forKey: .state)
        try container.encode(self.traceId, forKey: .traceId)
        try container.encode(self.spanId, forKey: .spanId)
        try container.encode(self.startTime, forKey: .startTime)
        try container.encodeIfPresent(self.endTime, forKey: .endTime)
        try container.encode(self.lastHeartbeatTime, forKey: .lastHeartbeatTime)
        try container.encodeIfPresent(self.crashReportId, forKey: .crashReportId)
        try container.encode(self.coldStart, forKey: .coldStart)
        try container.encode(self.cleanExit, forKey: .cleanExit)
        try container.encode(self.appTerminated, forKey: .appTerminated)
    }
    
    enum CodingKeys: CodingKey {
        case id
        case processId
        case state
        case traceId
        case spanId
        case startTime
        case endTime
        case lastHeartbeatTime
        case crashReportId
        case coldStart
        case cleanExit
        case appTerminated
    }
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(SessionIdentifier.self, forKey: .id)
        self.processId = try container.decode(ProcessIdentifier.self, forKey: .processId)
        self.state = try container.decode(String.self, forKey: .state)
        self.traceId = try container.decode(String.self, forKey: .traceId)
        self.spanId = try container.decode(String.self, forKey: .spanId)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        self.lastHeartbeatTime = try container.decode(Date.self, forKey: .lastHeartbeatTime)
        self.crashReportId = try container.decodeIfPresent(String.self, forKey: .crashReportId)
        self.coldStart = try container.decode(Bool.self, forKey: .coldStart)
        self.cleanExit = try container.decode(Bool.self, forKey: .cleanExit)
        self.appTerminated = try container.decode(Bool.self, forKey: .appTerminated)
    }
}
#endif
