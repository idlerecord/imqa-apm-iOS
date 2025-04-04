//
//  IMQAUploadError.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation

/// Enum containing possible error codes
public enum IMQAUploadErrorCode: Int {
    case invalidMetadata = 1000
    case invalidData = 1001
    case operationCancelled = 1002
    case valueConvertError = 1003
}

public enum IMQAUploadError: Error, Equatable {
    case incorrectStatusCodeError(_ code: Int)
    case internalError(_ code: IMQAUploadErrorCode)
}

// Allows bridging to NSError
extension IMQAUploadError: LocalizedError, CustomNSError {

    public static var errorDomain: String {
        return "IMQA"
    }

    public var errorCode: Int {
        switch self {
        case .incorrectStatusCodeError(let code):
            return code
        case .internalError(let code):
            return code.rawValue
        }
    }

    public var errorDescription: String? {
        switch self {
        case .incorrectStatusCodeError(let code):
            return "Invalid status code received: \(code)"
        case .internalError(let code):
            return "Internal Error: \(code)"
        }
    }

    public var localizedDescription: String {
        return self.errorDescription ?? "No Matching Error"
    }
}
