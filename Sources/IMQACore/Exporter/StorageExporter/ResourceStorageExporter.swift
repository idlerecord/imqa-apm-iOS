//
//  ResourceStorageExporter.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//
import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

class ConcreteIMQAResource: IMQAResource {
    var key: String
    var value: ResourceValue

    init(key: String, value: ResourceValue) {
        self.key = key
        self.value = value
    }
}

class ResourceStorageExporter: IMQAResourceProvider {
    private(set) weak var storage: IMQAStorage?

    public init(storage: IMQAStorage) {
        self.storage = storage
    }

    func getResource() -> Resource {
        return IMQAOTel.resources ?? Resource()
    }
}

