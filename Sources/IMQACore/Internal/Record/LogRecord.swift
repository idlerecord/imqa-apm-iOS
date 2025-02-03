//
//  LogRecord.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation
import OpenTelemetrySdk
import OpenTelemetryApi
import IMQACommonInternal
import IMQAOtelInternal

internal struct LogRecord: Codable, VVIdenti {
    public var identifier: LogIdentifier
    public var processIdentifier: ProcessIdentifier
    public var severity: LogSeverity
    public var body: String
    public var timestamp: Date
    public var attributes: [String: PersistableValue]
    public var spanContext: SpanContext?

    public var vvid: String{
        return identifier.toString
    }
    
    
    public init(identifier: LogIdentifier,
                processIdentifier: ProcessIdentifier,
                severity: LogSeverity,
                body: String,
                attributes: [String: PersistableValue],
                timestamp: Date = Date(),
                spanContext:SpanContext?) {
        self.identifier = identifier
        self.processIdentifier = processIdentifier
        self.severity = severity
        self.body = body
        self.timestamp = timestamp
        self.attributes = attributes
        self.spanContext = spanContext
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.processIdentifier, forKey: .processIdentifier)
        try container.encode(self.severity, forKey: .severity)
        try container.encode(self.body, forKey: .body)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encode(self.attributes, forKey: .attributes)
    }
    
    enum CodingKeys: CodingKey {
        case identifier
        case processIdentifier
        case severity
        case body
        case timestamp
        case attributes
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try container.decode(LogIdentifier.self, forKey: .identifier)
        self.processIdentifier = try container.decode(ProcessIdentifier.self, forKey: .processIdentifier)
        self.severity = try container.decode(LogSeverity.self, forKey: .severity)
        self.body = try container.decode(String.self, forKey: .body)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.attributes = try container.decode([String : PersistableValue].self, forKey: .attributes)
    }
}
