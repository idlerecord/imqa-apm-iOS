//
//  IMQAStorageError.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/31.
//

import Foundation
//import GRDB

public enum IMQAStorageError: Error, Equatable {
    case cannotUpsertSpan(spanName: String, message: String)
    // TODO: Add missing errors in here
}

extension IMQAStorageError: LocalizedError, CustomNSError {
    public static var errorDomain: String {
        return "IMQA"
    }

    public var errorCode: Int {
        switch self {
        case .cannotUpsertSpan:
            return -1
        }
    }

    public var errorDescription: String? {
        switch self {
        case .cannotUpsertSpan(let spanName, let message):
            return "Failed upsertSpan `\(spanName)`: \(message)"
        }
    }

    public var localizedDescription: String {
        return self.errorDescription ?? "No Matching Error"
    }
}
