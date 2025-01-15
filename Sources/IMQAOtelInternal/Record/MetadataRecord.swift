//
//  MetadataRecord.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/29.
//
//import GRDB
import OpenTelemetryApi
import Foundation

public enum MetadataRecordType: String, Codable {
    /// Resource that is attached to session and logs data
    case resource

    /// IMQA-generated resource that is deemed required and cannot be removed by the user of the SDK
    case requiredResource

    /// Custom property attached to session and logs data and that can be manipulated by the user of the SDK
    case customProperty

    /// Persona tag attached to session and logs data and that can be manipulated by the user of the SDK
    case personaTag
}

public enum MetadataRecordLifespan: String, Codable {
    /// Value tied to a specific session
    case session

    /// Value tied to multiple sessions within a single process
    case process

    /// Value tied to all sessions until explicitly removed
    case permanent
}

public struct MetadataRecord: Codable, VVIdenti {
    public var vvid: String{
        return lifespanId
    }
    
    public let key: String
    public var value: AttributeValue
    public let type: MetadataRecordType
    public let lifespan: MetadataRecordLifespan
    public let lifespanId: String
    public let collectedAt: Date

    /// Main initializer for the MetadataRecord
    public init(
        key: String,
        value: AttributeValue,
        type: MetadataRecordType,
        lifespan: MetadataRecordLifespan,
        lifespanId: String,
        collectedAt: Date = Date()
    ) {
        self.key = key
        self.value = value
        self.type = type
        self.lifespan = lifespan
        self.lifespanId = lifespanId
        self.collectedAt = collectedAt
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.key, forKey: .key)
        try container.encode(self.value, forKey: .value)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.lifespan, forKey: .lifespan)
        try container.encode(self.lifespanId, forKey: .lifespanId)
        try container.encode(self.collectedAt, forKey: .collectedAt)
    }
    
    enum CodingKeys: CodingKey {
        case key
        case value
        case type
        case lifespan
        case lifespanId
        case collectedAt
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decode(String.self, forKey: .key)
        self.value = try container.decode(AttributeValue.self, forKey: .value)
        self.type = try container.decode(MetadataRecordType.self, forKey: .type)
        self.lifespan = try container.decode(MetadataRecordLifespan.self, forKey: .lifespan)
        self.lifespanId = try container.decode(String.self, forKey: .lifespanId)
        self.collectedAt = try container.decode(Date.self, forKey: .collectedAt)
    }
}

extension MetadataRecord {
    public static let lifespanIdForPermanent = ""
}


extension MetadataRecord {

    public var boolValue: Bool? {
        switch value {
        case .bool(let bool): return bool
        case .int(let integer): return integer > 0
        case .double(let double): return double > 0
        case .string(let string): return Bool(string)
        default: return nil
        }
    }

    public var integerValue: Int? {
        switch value {
        case .bool(let bool): return bool ? 1 : 0
        case .int(let integer): return integer
        case .double(let double): return Int(double)
        case .string(let string): return Int(string)
        default: return nil
        }
    }

    public var doubleValue: Double? {
        switch value {
        case .bool(let bool): return bool ? 1 : 0
        case .int(let integer): return Double(integer)
        case .double(let double): return double
        case .string(let string): return Double(string)
        default: return nil
        }
    }

    public var stringValue: String? {
        switch value {
        case .bool(let bool): return String(bool)
        case .int(let integer): return String(integer)
        case .double(let double): return String(double)
        case .string(let string): return string
        default: return nil
        }
    }

    public var uuidValue: UUID? {
        switch value {
        case .string(let string): return UUID(withoutHyphen: string)
        default: return nil
        }
    }
}
