//
//  LogPayloadBuilder.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/4.
//

import Foundation
import OpenTelemetrySdk
import OpenTelemetryApi
import IMQACommonInternal
import IMQAOtelInternal

struct LogPayloadBuilder {
    
    static func buildReadableLogRecord(log: LogRecord,
                                       resource: [String : AttributeValue]) -> ReadableLogRecord{
        let severity = Severity(rawValue: log.severity.number)
        let resource = IMQAOTel.resources ?? Resource(attributes: resource)
        let date = log.timestamp
        let body = AttributeValue(log.body)
        let spanContext = log.spanContext
        var finalAttributes: [String: AttributeValue] = [:]
        for entry in log.attributes {
            finalAttributes[entry.key] = AttributeValue(entry.value.description)
        }

        let scopeInfo = InstrumentationScopeInfo(name: "imqa.sdk.iOS", version: IMQAMeta.sdkVersion)
        
        return ReadableLogRecord(resource: resource,
                          instrumentationScopeInfo: scopeInfo,
                          timestamp: date,
                          observedTimestamp: date,
                                 spanContext: spanContext,
                          severity: severity,
                          body: body,
                          attributes: finalAttributes)
    }
    
}
