//
//  OpenTelemetryManager+Span.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//
import OpenTelemetryApi
internal import ResourceExtension
import Foundation
import OpenTelemetrySdk
import IMQAOtelInternal
import IMQACommonInternal

extension IMQA{
    func createProcessStartSpan() -> Span {
        let builder = buildSpan(name: "imqa-process-launch", type: IMQASpanType.SESSION)
//            .markAsPrivate()

        if let startTime = ProcessMetadata.startTime {
            builder.setStartTime(time: startTime)
        } else {
            // start time will default to "now" but span will be marked with error
            builder.error(errorCode: .unknown)
        }

        return builder.startSpan()
    }
    
    
    /// setUp 시간을 기록합니다.
    /// - Parameter startTime: 시간
    func recordSetupSpan(startTime: Date) {
        buildSpan(name: "imqa-setup", type: IMQASpanType.DEFAULT)
//            .markAsPrivate()
            .setStartTime(time: startTime)
            .startSpan()
            .end()
    }

}

