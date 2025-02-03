//
//  InstrumentableViewController.swift
//  Imqa-sdk-ios
//
//  Created by Hunta Park on 12/13/24.
//

import Foundation
import OpenTelemetryApi
import IMQAOtelInternal
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

#if canImport(UIKit) && !os(watchOS)
public protocol InstrumentableViewController: UIViewController {

}
#else
public protocol InstrumentableViewController{
    
}
#endif

internal extension InstrumentableViewController {

    /// Method used to build a span to be included as a child span to the parent span being handled by the `ViewCaptureService`.
    /// - Parameters:
    ///    - name: The name of the span.
    ///    - type: The type of the span. Will be set as the `emb.type` attribute.
    ///    - startTime: The start time of the span.
    ///    - attributes: A dictionary of attributes to set on the span.
    /// - Returns: An OpenTelemetry `SpanBuilder`.
    /// - Throws: `ViewCaptureService.noServiceFound` if no `ViewCaptureService` is active.
    /// - Throws: `ViewCaptureService.firstRenderInstrumentationDisabled` if this functionallity was not enabled when setting up the `ViewCaptureService`.
    /// - Throws: `ViewCaptureService.parentSpanNotFound` if no parent span was found for this `UIViewController`.
    ///           This could mean the `UIViewController` was already rendered / deemed interactive, or the `UIViewController` has already disappeared.
#if canImport(UIKit) && !os(watchOS)
    func buildChildSpan(
        name: String,
        type: IMQASpanType = .RENDER,
        startTime: Date = Date(),
        attributes: [String: String] = [:]
    ) throws -> SpanBuilder? {
        return try IMQA.client?.captureServices.buildChildSpan(
            for: self,
            name: name,
            type: type,
            startTime: startTime,
            attributes: attributes
        )
    }
#endif
    /// Method used to record a completed span to be included as a child span to the parent span being handled by the `ViewCaptureService`.
    /// - Parameters:
    ///    - name: The name of the span.
    ///    - type: The type of the span. Will be set as the `emb.type` attribute.
    ///    - startTime: The start time of the span.
    ///    - endTime: The end time of the span.
    ///    - attributes: A dictionary of attributes to set on the span.
    /// - Throws: `ViewCaptureService.noServiceFound` if no `ViewCaptureService` is active.
    /// - Throws: `ViewCaptureService.firstRenderInstrumentationDisabled` if this functionallity was not enabled when setting up the `ViewCaptureService`.
    /// - Throws: `ViewCaptureService.parentSpanNotFound` if no parent span was found for this `UIViewController`.
    ///           This could mean the `UIViewController` was already rendered / deemed interactive, or the `UIViewController` has already disappeared.
    ///
#if canImport(UIKit) && !os(watchOS)
    func recordCompletedChildSpan(
        name: String,
        type: IMQASpanType = .RENDER,
        startTime: Date,
        endTime: Date,
        attributes: [String: String] = [:]
    ) throws {
        try IMQA.client?.captureServices.recordCompletedChildSpan(
            for: self,
            name: name,
            type: type,
            startTime: startTime,
            endTime: endTime,
            attributes: attributes
        )
    }
#endif
}


