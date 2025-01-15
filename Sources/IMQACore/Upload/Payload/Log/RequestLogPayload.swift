//
//  RequestLogPayload.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/21.
//
import OpenTelemetrySdk
import OpenTelemetryProtocolExporterCommon

struct RequestLogPayload: Codable {
    let resourceLogs: [ResourceLog]
}

struct ResourceLog: Codable {
    let resource: LogResource
    let scopeLogs: [ScopeLog]
}

struct LogResource: Codable {
    let attributes: [LogAttribute]
    var droppedAttributesCount: Int
}

struct ScopeLog: Codable {
    let scope: InstrumentationScopeInfo
    let logRecords: [LogPayload]
}
