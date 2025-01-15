//
//  IMQASwizzableError.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/28.
//

import Foundation

public enum IMQASwizzableError: Error, Equatable {
    case methodNotFound(selectorName: String, className: String)
}

// Allows bridging to NSError
extension IMQASwizzableError: LocalizedError, CustomNSError {

    public static var errorDomain: String {
        return "IMQA"
    }

    public var errorCode: Int {
        switch self {
        case .methodNotFound:
            return -1
        }
    }

    public var errorDescription: String? {
        switch self {
        case .methodNotFound(let selector, let className):
            return "No method for selector \(selector) in class \(className)"
        }
    }

    public var localizedDescription: String {
        return self.errorDescription ?? "No Matching Error"
    }
}
