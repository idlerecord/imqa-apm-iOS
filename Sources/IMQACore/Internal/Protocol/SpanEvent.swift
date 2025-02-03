//
//  SpanEvent.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/9/25.
//
import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk


internal protocol SpanEvent {
    var name: String { get }
    var timestamp: Date { get }
    var attributes: [String: AttributeValue] { get }
}

extension SpanData.Event: SpanEvent { }

