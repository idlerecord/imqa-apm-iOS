//
//  SpanDataValidation.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation
import OpenTelemetrySdk
import IMQAOtelInternal

class SpanDataValidation {

    let validators: [SpanDataValidator]

    init(validators: [SpanDataValidator]) {
        self.validators = validators
    }

    /// Validators have the opportunity to modify the SpanData if any validation is deemed recoverable
    /// - Parameter spanData The data to validate. An inout parameter as this item can be mutated by any validator
    /// - Returns false if any validator fails
    func execute(spanData: inout SpanData) -> Bool {
        var result = true

        for validator in validators {
            result = result && validator.validate(data: &spanData)
            guard result else { break }
        }

        return result
    }
}
