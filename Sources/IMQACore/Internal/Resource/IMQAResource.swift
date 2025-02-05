//
//  IMQAResource.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//
import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

/// Typealias created to abstract away the `AttributeValue` from `OpenTelemetryApi`,
/// reducing the dependency exposure to dependents.
public typealias ResourceValue = AttributeValue

// This representation of the `Resource` concept was necessary because
// some entities (like `LogReadableRecord`) needs it.
public protocol IMQAResource {
    var key: String { get }
    var value: ResourceValue { get }
}
