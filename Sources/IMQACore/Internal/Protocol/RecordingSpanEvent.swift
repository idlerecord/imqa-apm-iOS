//
//  RecordingSpanEvent.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/9/25.
//

import Foundation
import OpenTelemetryApi
internal struct RecordingSpanEvent: SpanEvent, Codable, Equatable {
    public let name: String
    public let timestamp: Date
    public let attributes: [String: AttributeValue]

    public init(name: String, timestamp: Date, attributes: [String: AttributeValue] = [:]) {
        self.name = name
        self.timestamp = timestamp
        self.attributes = attributes
    }
}

internal func == (lhs: RecordingSpanEvent, rhs: RecordingSpanEvent) -> Bool {
    return lhs.name == rhs.name &&
        lhs.timestamp == rhs.timestamp &&
        lhs.attributes == rhs.attributes
}

internal func == (lhs: [RecordingSpanEvent], rhs: [RecordingSpanEvent]) -> Bool {
    return lhs.elementsEqual(rhs) { $0 == $1 }
}
