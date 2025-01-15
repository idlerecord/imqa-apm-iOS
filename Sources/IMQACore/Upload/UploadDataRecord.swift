//
//  UploadDataRecord.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation
import IMQAOtelInternal

/// Represents a cached upload data in the storage
public class UploadDataRecord: Codable, VVIdenti {
    var id: String
    var type: Int
    var data: Data
    var attemptCount: Int
    var date: Date
    
    public var vvid: String{
        return id
    }
    
    init (id: String, type: Int, data: Data, attemptCount: Int, date: Date) {
        self.id = id
        self.type = type
        self.data = data
        self.attemptCount = attemptCount
        self.date = date
    }
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(Int.self, forKey: .type)
        self.data = try container.decode(Data.self, forKey: .data)
        self.attemptCount = try container.decode(Int.self, forKey: .attemptCount)
        self.date = try container.decode(Date.self, forKey: .date)
    }
    
    enum CodingKeys: CodingKey {
        case id
        case type
        case data
        case attemptCount
        case date
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.data, forKey: .data)
        try container.encode(self.attemptCount, forKey: .attemptCount)
        try container.encode(self.date, forKey: .date)
    }
}
