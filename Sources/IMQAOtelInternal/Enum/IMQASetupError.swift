//
//  File.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/18.
//

import Foundation
public enum IMQASetupError: Error, Equatable{
    case invalidThread(_ description: String)
    case initializationNotAllowed(_ description: String)
    case unableToInitialize(_ description: String)
    case failedStorageCreation(partitionId: String, appGroupId: String?)
    case invalidAppId(_ description: String)
    case invalidAppGroupId(_ description: String)

}

extension IMQASetupError: LocalizedError, CustomNSError{
    public static var errorDomain: String {
        return "IMQA"
    }

    public var errorCode: Int{
        switch self {
            
        case .invalidAppGroupId:
            return -1
        case .invalidAppId:
            return -2
        case .invalidThread:
            return -3
        case .failedStorageCreation:
            return -5
        case .unableToInitialize:
            return -6
        case .initializationNotAllowed:
            return -7
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .invalidThread(let description):
            return description
        case .initializationNotAllowed(let description):
            return description
        case .unableToInitialize(let description):
            return description
        case .failedStorageCreation(let partitionId, let appGroupId):
            return "Failed to create Storage Directory. partitionId: '\(partitionId)' appGroupId: '\(appGroupId ?? "")'"
        case .invalidAppId(let description):
            return description
        case .invalidAppGroupId(let description):
            return description
        }
    }
    
    public var localizedDescription: String {
        return self.errorDescription ?? "No Matching Error"
    }

}
