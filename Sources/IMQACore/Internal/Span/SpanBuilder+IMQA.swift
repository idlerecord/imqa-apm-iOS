//
//  SpanBuilder+IMQA.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/16/25.
//

import OpenTelemetryApi
import Foundation
import IMQACommonInternal

extension SpanBuilder {
    @discardableResult func setAttribute(key: String, value: String) -> Self {
        setAttribute(key: key, value: value)
        return self
    }

//    @discardableResult public func markAsPrivate() -> Self {
//        setAttribute(key: SpanSemantics.keyIsPrivateSpan, value: "true")
//    }
//
//    @discardableResult public func markAsKeySpan() -> Self {
//        setAttribute(key: SpanSemantics.keyIsKeySpan, value: "true")
//    }

    @discardableResult internal func error(errorCode: ErrorCode) -> Self {
        setAttribute(key: "imqa.error_code", value: errorCode.rawValue)
    }

}
