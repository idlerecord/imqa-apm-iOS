//
//  Span+IMQA.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/25.
//

import Foundation
import OpenTelemetryApi
import IMQACommonInternal
import IMQAOtelInternal

extension Span {


    public func end(errorCode: ErrorCode? = nil, time: Date = Date()) {
        end(error: nil, errorCode: errorCode, time: time)
    }

    public func end(error: Error?, errorCode: ErrorCode? = nil, time: Date = Date()) {
        var errorCode = errorCode

/*
 attributes[SemanticAttributes.exceptionType.rawValue] = AttributeValue(type[Int(typeIndex)])
 attributes[SemanticAttributes.exceptionMessage.rawValue] = AttributeValue(message[Int(messageIndex)])
 attributes[SemanticAttributes.exceptionStacktrace.rawValue] = AttributeValue(spanException.stackTrace)
 */
        
        // get attributes from error
        if let error = error as? NSError {
            setAttribute(key: SemanticAttributes.exceptionMessage.rawValue, value: error.localizedDescription)
            errorCode = errorCode ?? .failure
        }

        // set error code
        if let errorCode = errorCode {
            status = .error(description: errorCode.rawValue)
        } else {
            // no error or error code means the span ended successfully
            status = .ok
        }

        end(time: time)
    }
}

extension Span {
    public func add(events: [SpanEvent]) {
        events.forEach { event in
            addEvent(name: event.name, attributes: event.attributes, timestamp: event.timestamp)
        }
    }
}
