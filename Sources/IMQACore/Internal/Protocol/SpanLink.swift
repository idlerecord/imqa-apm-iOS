//
//  SpanLink.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import OpenTelemetryApi
import OpenTelemetrySdk

internal protocol SpanLink {
    var context: SpanContext { get }
    var attributes: [String: AttributeValue] { get }
}

extension SpanData.Link: SpanLink { }
