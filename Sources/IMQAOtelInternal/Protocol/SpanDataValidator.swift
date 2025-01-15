//
//  SpanDataValidator.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation
import OpenTelemetrySdk

protocol SpanDataValidator {
    func validate(data: inout SpanData) -> Bool
}
