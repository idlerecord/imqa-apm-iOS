//
//  IMQAStorageMetadataFetcher.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/29.
//
import Foundation
import IMQACommonInternal
import IMQAOtelInternal


public protocol IMQAStorageMetadataFetcher: AnyObject {
    func fetchAllResources() throws -> [MetadataRecord]
    func fetchResourcesForSessionId(_ sessionId: SessionIdentifier) throws -> [MetadataRecord]
    func fetchResourcesForProcessId(_ processId: ProcessIdentifier) throws -> [MetadataRecord]
    func fetchCustomPropertiesForSessionId(_ sessionId: SessionIdentifier) throws -> [MetadataRecord]
    func fetchPersonaTagsForSessionId(_ sessionId: SessionIdentifier) throws -> [MetadataRecord]
    func fetchPersonaTagsForProcessId(_ processId: ProcessIdentifier) throws -> [MetadataRecord]
}
