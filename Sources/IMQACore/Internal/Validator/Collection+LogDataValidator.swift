//
//  Collection+LogDataValidator.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation

extension Collection where Element == LogDataValidator {
    static var `default`: [Element] {
        return [
            LengthOfBodyValidator()
        ]
    }
}
