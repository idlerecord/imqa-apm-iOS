//
//  URLSessionRequestsDataSource.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/5.
//

import Foundation

/// This protocol can be used to modify requests before the Embrace SDK
/// captures their data into OTel spans.
///
/// Example:
/// This could be useful if you need to obfuscate certain parts of a request path
/// if it contains sensitive data.
@objc public protocol URLSessionRequestsDataSource: NSObjectProtocol {
    @objc func modifiedRequest(for request: URLRequest) -> URLRequest
}
