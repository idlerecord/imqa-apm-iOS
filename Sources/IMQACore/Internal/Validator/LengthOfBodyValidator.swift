//
//  LengthOfBodyValidator.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//


import Foundation
import OpenTelemetrySdk

/// Validates the length of ``ReadableLogRecord.body``.
/// This compares the length of the String in characters, not bytes.
/// The range defaults  to (1...4000) characters
class LengthOfBodyValidator: LogDataValidator {

    let allowedCharacterCount: ClosedRange<Int>

    init(allowedCharacterCount: ClosedRange<Int> = 0...4000) {
        self.allowedCharacterCount = allowedCharacterCount
    }

    func validate(data: inout ReadableLogRecord) -> Bool {
        guard let body = data.body else {
            return false
        }
        return allowedCharacterCount.contains(body.description.count)
    }
}
