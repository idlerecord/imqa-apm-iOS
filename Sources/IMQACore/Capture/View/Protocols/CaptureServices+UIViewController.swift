//
//  CaptureServices+UIViewController.swift
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


extension CaptureServices {

    var viewCaptureService: ViewCaptureService? {
        services.first(where: { $0 is ViewCaptureService }) as? ViewCaptureService
    }

    var serviceNotFoundError: ViewCaptureServiceError {
        ViewCaptureServiceError.serviceNotFound("No active `ViewCaptureService` found!")
    }

    var firstRenderInstrumentationDisabledError: ViewCaptureServiceError {
        ViewCaptureServiceError
            .firstRenderInstrumentationDisabled("This instrumentation was disabled on the `ViewCaptureService`!")
    }

    var parentSpanNotFoundError: ViewCaptureServiceError {
        ViewCaptureServiceError.parentSpanNotFound("No parent span found!")
    }

    func validateCaptureService() throws -> ViewCaptureService? {
        guard let viewCaptureService = viewCaptureService else {
            throw serviceNotFoundError
        }

        guard viewCaptureService.options.instrumentFirstRender else {
            throw firstRenderInstrumentationDisabledError
        }

        return viewCaptureService
    }
#if canImport(UIKit) && !os(watchOS)
    func onInteractionReady(for vc: UIViewController) throws {
        guard let viewCaptureService = try validateCaptureService() else {
            return
        }

        viewCaptureService.onViewBecameInteractive(vc)
    }
#endif
#if canImport(UIKit) && !os(watchOS)
    func buildChildSpan(
        for vc: UIViewController,
        name: String,
        type: IMQASpanType = .RENDER,
        startTime: Date = Date(),
        attributes: [String: String] = [:]
    ) throws -> SpanBuilder? {
        guard let viewCaptureService = try validateCaptureService() else {
            return nil
        }

        guard let parentSpan = viewCaptureService.parentSpan(for: vc) else {
            throw parentSpanNotFoundError
        }

        guard let builder = viewCaptureService.otel?.buildSpan(
            name: name,
            type: type,
            attributes: attributes
        ) else {
            return nil
        }

        builder.setParent(parentSpan)

        return builder
    }
#endif
    
#if canImport(UIKit) && !os(watchOS)
    func recordCompletedChildSpan(
        for vc: UIViewController,
        name: String,
        type: IMQASpanType = .RENDER,
        startTime: Date,
        endTime: Date,
        attributes: [String: String] = [:]
    ) throws {
        guard let viewCaptureService = try validateCaptureService() else {
            return
        }

        guard let parentSpan = viewCaptureService.parentSpan(for: vc) else {
            throw parentSpanNotFoundError
        }

        guard let builder = viewCaptureService.otel?.buildSpan(
            name: name,
            type: type,
            attributes: attributes
        ) else {
            return
        }

        builder.setStartTime(time: startTime)
        builder.setParent(parentSpan)

        let span = builder.startSpan()
        span.end(time: endTime)
    }
#endif
}


