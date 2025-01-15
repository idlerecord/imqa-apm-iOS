//
//  KeychainAccess.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation
import Security

public class KeychainAccess {

    static let kIMQAKeychainService = "io.imqa.keys"
    static let kIMQADeviceId = "io.imqa.deviceid_v3"
    
    private init() { }

    static var keychain: KeychainInterface = DefaultKeychainInterface()

    public static var deviceId: UUID {
        // fetch existing id
        let pair = keychain.valueFor(
            service: kIMQAKeychainService as CFString,
            account: kIMQADeviceId as CFString
        )

        if let _deviceId = pair.value {
            if let uuid = UUID(uuidString: _deviceId) {
                return uuid
            }
//            IMQA.logger.debug("Failed to construct device id from keychain")
        }

        // generate new id
        let newId = UUID()
        let status = keychain.setValue(
            service: kIMQAKeychainService as CFString,
            account: kIMQADeviceId as CFString,
            value: newId.uuidString
        )

        if status != errSecSuccess {
            if let err = SecCopyErrorMessageString(status, nil) {
//                IMQA.logger.debug("Write failed: \(err)")
            }
        }

        return newId
    }
}
