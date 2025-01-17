//
//  Collection+SpanDataValidator.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/11.
//

import Foundation
import OpenTelemetrySdk
import OpenTelemetryApi
import IMQAOtelInternal
import IMQACommonInternal

extension Collection where Element == SpanDataValidator {
    static var `default`: [Element] {
        return [
            WhitespaceSpanNameValidator(),
            LengthOfNameValidator()
        ]
    }
}

class WhitespaceSpanNameValidator: SpanDataValidator {
    func validate(data: inout SpanData) -> Bool {
        let trimSet: CharacterSet = .whitespacesAndNewlines.union(.controlCharacters)
        return !data.name.trimmingCharacters(in: trimSet).isEmpty
    }
}

class LengthOfNameValidator: SpanDataValidator {

    let allowedCharacterCount: ClosedRange<Int>

    init(allowedCharacterCount: ClosedRange<Int> = 1...100) {
        self.allowedCharacterCount = allowedCharacterCount
    }

    func validate(data: inout SpanData) -> Bool {
        guard shouldValidate(data: data) else {
            return true
        }
        return allowedCharacterCount.contains(data.name.count)
    }

    private func shouldValidate(data: SpanData) -> Bool {
        return data.spanType != IMQASpanType.XHR
        
    }
}
