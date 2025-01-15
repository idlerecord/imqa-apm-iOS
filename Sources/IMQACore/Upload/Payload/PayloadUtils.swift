//
//  PayloadUtils.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import OpenTelemetryApi
import IMQACommonInternal
import IMQAOtelInternal

class PayloadUtils {
    static func fetchResources(
        from fetcher: IMQAStorageMetadataFetcher,
        sessionId: SessionIdentifier?
    ) -> [MetadataRecord] {

        guard let sessionId = sessionId else {
            return []
        }

//        do {
//            return try fetcher.fetchResourcesForSessionId(sessionId)
//        } catch let e {
//            IMQA.logger.error("Failed to fetch resource records from storage: \(e.localizedDescription)")
//        }

        return []
    }

    static func fetchCustomProperties(
        from fetcher: IMQAStorageMetadataFetcher,
        sessionId: SessionIdentifier?
    ) -> [MetadataRecord] {

        guard let sessionId = sessionId else {
            return []
        }

//        do {
//            return try fetcher.fetchCustomPropertiesForSessionId(sessionId)
//        } catch let e {
//            IMQA.logger.error("Failed to fetch custom properties from storage: \(e.localizedDescription)")
//        }

        return []
    }

//    static func convertSpanAttributes(_ attributes: [String: AttributeValue]) -> [Attribute] {
//        var result: [Attribute] = []
//
//        for (key, value) in attributes {
//            switch value {
//            case .boolArray, .intArray, .doubleArray, .stringArray:
//                continue
//            default:
//                result.append(Attribute(key: key, value: value.description))
//            }
//        }
//
//        return result
//    }
    
    static func converSpanAttributes(_ attributes: [String: AttributeValue]) -> [SpanAttribute]{
        var result: [SpanAttribute] = []
        for (key, value) in attributes {
            switch value{
            case .boolArray, .intArray, .doubleArray, .stringArray:
                continue
            case .bool:
                result.append(SpanAttribute(key: key, value: SpanAttribute.Value(boolValue: (value.description == "true"))));
            case .int:
                result.append(SpanAttribute(key: key, value: SpanAttribute.Value(intValue: Int(value.description))));
            case .string:
                result.append(SpanAttribute(key: key, value: SpanAttribute.Value(stringValue: value.description)));
            case .double:
                result.append(SpanAttribute(key: key, value: SpanAttribute.Value(doubleValue: Double(value.description))));
            default:
                ()
            }
        }
        return result
    }
    
}

struct Attribute: Codable {
    var key: String
    var value: String
}
