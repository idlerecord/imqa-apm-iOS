//
//  IMQALogger.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation
import OpenTelemetryApi

class IMQALogger: Logger {
    let sharedState: IMQALogSharedState
    private let attributes: [String: AttributeValue]

    init(sharedState: IMQALogSharedState,
         attributes: [String: AttributeValue] = [:]) {
        self.sharedState = sharedState
        self.attributes = attributes
    }

    /// This method is meant to be used as part of the [Event API](https://opentelemetry.io/docs/specs/otel/logs/event-api/).
    /// However, due to the experimental state of this interface and the changes it has been receiving, we decided to not support it.
    ///
    /// - Parameter name: the name of the event. **Won't be used**.
    /// - Returns: a `IMQALogRecordBuilder` instance.
    func eventBuilder(name: String) -> EventBuilder {
        IMQALogRecordBuilder(sharedState: sharedState,
                                attributes: attributes)
    }

    func logRecordBuilder() -> LogRecordBuilder {
        IMQALogRecordBuilder(sharedState: sharedState,
                                attributes: attributes)
    }
}
