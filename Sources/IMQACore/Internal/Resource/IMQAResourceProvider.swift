//
//  IMQAResourceProvider.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation
import OpenTelemetrySdk

/// This provider allows to dependents to decide which resource they should expose or not
/// as an `OpenTelemetryApi.Resource`. Mapping to the actual `Resource` object
/// is being done internally in `IMQAOTel`.
public protocol IMQAResourceProvider {
    func getResource() -> Resource
}
