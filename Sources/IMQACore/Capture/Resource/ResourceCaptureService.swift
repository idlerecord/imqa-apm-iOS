//
//  ResourceCaptureService.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/15/25.
//

import OpenTelemetryApi
import IMQACaptureService
import IMQAOtelInternal
import IMQACommonInternal


protocol ResourceCaptureServiceHandler: AnyObject {
    func addResource(key: String, value: AttributeValue)
}

class ResourceCaptureService: CaptureService {
    weak var handler: ResourceCaptureServiceHandler?

    func addResource(key: String, value: AttributeValue) {
        handler?.addResource(key: key, value: value)
    }
}

extension IMQAStorage: ResourceCaptureServiceHandler {
    func addResource(key: String, value: AttributeValue) {
        do {
            _ = try addMetadata(
                MetadataRecord(
                    key: key,
                    value: value,
                    type: .requiredResource,
                    lifespan: .process,
                    lifespanId: ProcessIdentifier.current.hex
                )
            )
        } catch {
            IMQA.logger.error("Failed to capture resource: \(error.localizedDescription)")
        }
    }
}
