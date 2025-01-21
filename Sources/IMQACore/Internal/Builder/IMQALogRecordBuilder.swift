//
//  IMQALogRecordBuilder.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/14.
//

import OpenTelemetryApi
import OpenTelemetrySdk
import Foundation
import IMQAOtelInternal

class IMQALogRecordBuilder: EventBuilder {

    let sharedState: IMQALogSharedState
    let instrumentationScope: InstrumentationScopeInfo

    private(set) var timestamp: Date?
    private(set) var observedTimestamp: Date?
    private(set) var severity: Severity?
    private(set) var spanContext: SpanContext?
    private(set) var body: AttributeValue?
    private(set) var attributes: [String: AttributeValue]

    init(sharedState: IMQALogSharedState, attributes: [String: AttributeValue]) {
        self.sharedState = sharedState
        self.attributes = attributes
        self.instrumentationScope = InstrumentationScopeInfo(name: "imqa.sdk.iOS", version: IMQAMeta.sdkVersion)
    }

    func setTimestamp(_ timestamp: Date) -> Self {
        self.timestamp = timestamp
        return self
    }

    func setObservedTimestamp(_ observed: Date) -> Self {
        self.observedTimestamp = observed
        return self
    }

    func setSpanContext(_ context: SpanContext) -> Self {
        self.spanContext = context
        return self
    }

    func setSeverity(_ severity: Severity) -> Self {
        self.severity = severity
        return self
    }

    func setBody(_ body: AttributeValue) -> Self {
        self.body = body
        return self
    }

    func setAttributes(_ attributes: [String: AttributeValue]) -> Self {
        attributes.forEach {
            self.attributes[$0.key] = $0.value
        }
        return self
    }

    func setData(_ attributes: [String: OpenTelemetryApi.AttributeValue]) -> Self {
        return setAttributes(attributes)
    }

    func emit() {
        let resource = sharedState.resourceProvider.getResource()

        if spanContext == nil {
            spanContext = OpenTelemetry.instance.contextProvider.activeSpan?.context
        }

        var attributes = attributes
        if let userId = UserModel.id {
            attributes[SpanSemantics.Common.userId] = .string(userId)
        }
        if let areaCode = AreaCodeModel.areaCode {
            attributes[SpanSemantics.Common.areaCode] = .string(areaCode)
        }

        sharedState.processors.forEach {
            let now = Date()
            let log = ReadableLogRecord(resource: resource,
                              instrumentationScopeInfo: instrumentationScope,
                              timestamp: timestamp ?? now,
                              observedTimestamp: observedTimestamp ?? now,
                              spanContext: spanContext,
                              severity: severity,
                              body: body,
                              attributes: attributes)
            $0.onEmit(logRecord: log)
        }
    }
}
