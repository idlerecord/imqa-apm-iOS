//
//  IMQAUpload+MetadataOptions.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//


import Foundation

public extension IMQAUpload {
    /// Used to construct the http request headers
    class MetadataOptions {
        public var apiKey: String
        public var userAgent: String
        public var deviceId: String

        public init(apiKey: String, userAgent: String, deviceId: String) {
            self.apiKey = apiKey
            self.userAgent = userAgent
            self.deviceId = deviceId
        }
    }
}
