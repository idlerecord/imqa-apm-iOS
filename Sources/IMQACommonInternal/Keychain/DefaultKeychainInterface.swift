//
//  DefaultKeychainInterface.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//


import Foundation

public protocol KeychainInterface {
    func valueFor(service: CFString, account: CFString) -> (value: String?, status: OSStatus)
    func setValue(service: CFString, account: CFString, value: String) -> OSStatus
    func deleteValue(service: CFString, account: CFString) -> OSStatus
}

public class DefaultKeychainInterface: KeychainInterface {
    public func valueFor(service: CFString, account: CFString) -> (value: String?, status: OSStatus) {
        let keychainQuery: NSMutableDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?

        // Search for the keychain items
        let status: OSStatus = SecItemCopyMatching(keychainQuery, &dataTypeRef)
        var contentsOfKeychain: String?

        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                contentsOfKeychain = String(data: retrievedData, encoding: String.Encoding.utf8)
            }
        }

        return (contentsOfKeychain, status)
    }

    public func setValue(service: CFString, account: CFString, value: String) -> OSStatus {
        guard let dataFromString = value.data(using: String.Encoding.utf8, allowLossyConversion: false) else {
            return errSecParam
        }

        let querry: NSMutableDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: dataFromString
        ]

        // Add the new keychain item
        return SecItemAdd( querry, nil)
    }

    public func deleteValue(service: CFString, account: CFString) -> OSStatus {
        let keychainQuery: NSMutableDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        return SecItemDelete(keychainQuery)
    }

}
