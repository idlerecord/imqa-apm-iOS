//
//  DeviceIdentifier+Persistence.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//


import Foundation
import IMQACommonInternal


extension DeviceIdentifier {
    static let resourceKey = "imqa.device_id"

    static func retrieve(from storage: IMQAStorage?) -> DeviceIdentifier {
#error("fix me")
        // retrieve from storage
//        if let storage = storage {
//            if let resource = storage.fetchRequiredPermanentResource(key: resourceKey) {
//                if let uuid = resource.uuidValue {
//                    return DeviceIdentifier(value: uuid)
//                }
//                IMQA.logger.warning("Failed to convert device.id back into a UUID. Possibly corrupted!")
//            }
//        }

        // fallback to retrieve from Keychain
        let uuid = KeychainAccess.deviceId
        let deviceId = DeviceIdentifier(value: uuid)

//        if let storage = storage {
//            do {
//                try storage.addMetadata(
//                    key: resourceKey,
//                    value: deviceId.hex,
//                    type: .requiredResource,
//                    lifespan: .permanent
//                )
//            } catch let e {
//                IMQA.logger.error("Failed to add device id to database \(e.localizedDescription)")
//            }
//        }
        return deviceId
    }
}


extension DeviceIdentifier: VVIdenti {
    var vvid: String {
        return hex
    }
}
