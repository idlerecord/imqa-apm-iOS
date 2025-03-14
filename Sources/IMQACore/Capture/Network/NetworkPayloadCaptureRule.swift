//
//  NetworkPayloadCaptureRule.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/5.
//

import Foundation

@objc
public final class NetworkPayloadCaptureRule: NSObject ,Decodable{
    public let id: String
    public let urlRegex: String
    public let statusCodes: [Int]?
    public let methods: [String]?
    public let expiration: Double
    public let publicKey: String

    public var expirationDate: Date {
        return Date(timeIntervalSince1970: expiration)
    }

    init(
        id: String,
        urlRegex: String,
        statusCodes: [Int]?,
        methods: [String]?,
        expiration: Double,
        publicKey: String
    ) {
        self.id = id
        self.urlRegex = urlRegex
        self.statusCodes = statusCodes
        self.methods = methods
        self.expiration = expiration
        self.publicKey = publicKey
    }
}

extension NetworkPayloadCaptureRule {
    enum CodingKeys: String, CodingKey {
        case id
        case urlRegex = "url"
        case statusCodes = "status_code"
        case methods = "method"
        case expiration
        case publicKey = "public_key"
    }
}

extension NetworkPayloadCaptureRule /* Equatable */ {
    public static func == (lhs: NetworkPayloadCaptureRule, rhs: NetworkPayloadCaptureRule) -> Bool {
        lhs.id == rhs.id
    }
}
