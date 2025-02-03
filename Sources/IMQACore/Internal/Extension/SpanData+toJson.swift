//
//  SpanData+toJson.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//
import Foundation
import IMQACommonInternal
import OpenTelemetrySdk
import IMQAOtelInternal

extension SpanData {
    
    internal var spanType: IMQASpanType {
        if let raw = attributes[SpanSemantics.spanType] {
            switch raw {
            case let .string(val):
                return IMQASpanType(rawValue: val) ?? IMQASpanType.DEFAULT
            default:
                break
            }
        }
        return IMQASpanType.DEFAULT
    }

    internal var errorCode: ErrorCode? {
        guard let value = attributes["imqa.error_code"] else {
            return nil
        }
        return ErrorCode(rawValue: value.description)
    }

    internal func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
}
