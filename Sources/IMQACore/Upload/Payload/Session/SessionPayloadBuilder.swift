//
//  SessionPayloadBuilder.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation
import IMQAOtelInternal
import IMQACommonInternal

class SessionPayloadBuilder {

    static var resourceName = "imqa.session.upload_index"

    class func build(for sessionRecord: SessionRecord, storage: IMQAStorage) -> Data? {
        var resource: MetadataRecord?

        do {
            // fetch resource
            resource = try storage.fetchRequiredPermanentResource(key: resourceName)
        } catch {
            IMQA.logger.debug("Error fetching \(resourceName) resource!")
        }

        // increment counter or create resource if needed
        var counter: Int = -1

        do {
            if var resource = resource {
                counter = (resource.integerValue ?? 0) + 1
                resource.value = .string(String(counter))
                try storage.updateMetadata(resource)
            } else {
                resource = try storage.addMetadata(
                    key: resourceName,
                    value: "1",
                    type: MetadataRecordType.requiredResource,
                    lifespan: MetadataRecordLifespan.permanent
                )
                counter = 1
            }
        } catch {
            IMQA.logger.debug("Error updating \(resourceName) resource!")
        }

        // build spans
        let (spans, spanSnapshots) = SpansPayloadBuilder.build(
            for: sessionRecord,
            storage: storage,
            sessionNumber: counter
        )

        // build resources payload
        var resources: [MetadataRecord] = []
//        do {
//            resources = try storage.fetchResourcesForSessionId(sessionRecord.id)
//        } catch {
//            IMQA.logger.error("Error fetching resources for session \(sessionRecord.id.toString)")
//        }
//        let resourcePayload =  ResourcePayload(from: resources)

        // build metadata payload
        var metadata: [MetadataRecord] = []
//        do {
//            let properties = try storage.fetchCustomPropertiesForSessionId(sessionRecord.id)
//            let tags = try storage.fetchPersonaTagsForSessionId(sessionRecord.id)
//            metadata.append(contentsOf: properties)
//            metadata.append(contentsOf: tags)
//        } catch {
//            IMQA.logger.error("Error fetching custom properties for session \(sessionRecord.id.toString)")
//        }
//        let metadataPayload =  MetadataPayload(from: metadata)

        // build payload
        return PayloadEnvelope<SpanPayload>.requestSpanProtobufData(spans: spans)
    }
}
extension SessionPayloadBuilder{
    class func buildSpanRequestData(for sessionRecord: SessionRecord, storage: IMQAStorage) -> Data?{
        let spans = SpansPayloadBuilder.buildSpanDataList(
            for: sessionRecord,
            storage: storage,
            sessionNumber: 1
        )
        
        // build payload
        return PayloadEnvelope<SpanPayload>.requestSpanProtobufData(spans: spans)
    }
}
