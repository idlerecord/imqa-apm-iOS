//
//  LogPayload.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation
import OpenTelemetrySdk
//import OpenTelemetryProtocolExporterCommon

struct LogPayload: Codable {
    var timeUnixNano: String
    var observedTimeUnixNano: String
    var severityNumber: Int
    var body: LogAttribute.Value
    var attributes: [LogAttribute]
    var droppedAttributesCount: Int
//    var traceId: String?
//    var spanId: String?
}

public struct LogAttribute: Codable {
    var key: String?
    var value: Value?
    
    public struct Value: Codable {
        var stringValue: String?
        var boolValue: Bool?
        
        init(stringValue: String? = nil, boolValue: Bool? = nil) {
            self.stringValue = stringValue
            self.boolValue = boolValue
        }
    }
    init(key: String? = nil, value: Value? = nil) {
        self.key = key
        self.value = value
    }
}

