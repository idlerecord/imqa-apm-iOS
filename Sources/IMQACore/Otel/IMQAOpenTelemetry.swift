//
//  IMQAOpenTelemetry.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/25.
//
import Foundation
import OpenTelemetryApi
import IMQACommonInternal
import IMQAOtelInternal

protocol IMQAOpenTelemetry: AnyObject {
    func buildSpan(name: String,
                   type: IMQASpanType,
                   attributes: [String: String]) -> SpanBuilder

    func recordCompletedSpan(
        name: String,
        type: IMQASpanType,
        parent: Span?,
        startTime: Date,
        endTime: Date,
        attributes: [String: String],
        events: [RecordingSpanEvent],
        errorCode: ErrorCode?
    )

    func add(events: [SpanEvent])

    func add(event: SpanEvent)

    func log(
        _ message: String,
        severity: LogSeverity,
        type: IMQALogType,
        attributes: [String: String],
        stackTraceBehavior: StackTraceBehavior
    )

    func log(
        _ message: String,
        severity: LogSeverity,
        type: IMQALogType,
        timestamp: Date,
        attributes: [String: String],
        stackTraceBehavior: StackTraceBehavior
    )
    
    func log(
        _ message: String,
        severity: LogSeverity,
        type: IMQALogType,
        spanContext: SpanContext,
        timestamp: Date,
        attributes: [String: String],
        stackTraceBehavior: StackTraceBehavior
    )
    
    func propagators(spanContext: SpanContext)
    
    func baggage(key: String,
                 value: String,
                 metadata:String?) -> Baggage?
}

