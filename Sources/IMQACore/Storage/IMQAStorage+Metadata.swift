//
//  IMQAStorage+Metadata.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/31.
//

import Foundation
//import GRDB


extension IMQAStorage {

    /// Adds a new `MetadataRecord` with the given values.
    /// Fails and returns nil if the metadata limit was reached.
    @discardableResult
    public func addMetadata(
        key: String,
        value: String,
        type: MetadataRecordType,
        lifespan: MetadataRecordLifespan,
        lifespanId: String = ""
    ) throws -> MetadataRecord? {

        let metadata = MetadataRecord(
            key: key,
            value: .string(value),
            type: type,
            lifespan: lifespan,
            lifespanId: lifespanId
        )

        if try addMetadata(metadata) {
            return metadata
        }

        return nil
    }

    /// Adds a new `MetadataRecord`.
    /// Fails and returns nil if the metadata limit was reached.
    public func addMetadata(_ metadata: MetadataRecord) -> Bool {
        let storage = IMQAMuti<MetadataRecord>()
        if metadata.type == .requiredResource {
            storage.save(metadata)
            return true
        }
        let limit = limitForType(metadata.type)
        let count =  storage.get().filter{
            $0.type == metadata.type &&
            $0.lifespan == metadata.lifespan &&
            $0.lifespanId == metadata.lifespanId
        }.count
        

        guard count < limit else {
            // TODO: limit could be applied incorrectly if at max limit and updating an existing record
            return false
        }
        storage.save(metadata)
        return true
    }

    private func limitForType(_ type: MetadataRecordType) -> Int {
        switch type {
        case .resource: return options.resourcesLimit
        case .customProperty: return options.customPropertiesLimit
        case .personaTag: return options.personaTagsLimit
        default: return 0
        }
    }

    /// Updates the `MetadataRecord` for the given key, type and lifespan with a new given value.
    public func updateMetadata(
        key: String,
        value: String,
        type: MetadataRecordType,
        lifespan: MetadataRecordLifespan
    ) {
        let storage = IMQAMuti<MetadataRecord>()
        let filterRecords = storage.get().filter{
            $0.key == key &&
            $0.type == type &&
            $0.lifespan == lifespan
        }
        guard var record = filterRecords.first else{
            return
        }
        record.value = .string(value)
        storage.save(record)
    }

    /// Updates the given `MetadataRecord`.
    public func updateMetadata(_ record: MetadataRecord) throws {
        let storage = IMQAMuti<MetadataRecord>()
        storage.save(record)
    }

    /// Removes all `MetadataRecords` that don't corresponde to the given session and process ids.
    /// Permanent metadata is not removed.
    public func cleanMetadata(
        currentSessionId: String?,
        currentProcessId: String
    ) {
        let storage = IMQAMuti<MetadataRecord>()
        if let currentSessionId = currentSessionId {
            let filterRecords = storage.get().filter{
                ($0.lifespan == MetadataRecordLifespan.session &&
                $0.lifespanId != currentSessionId) ||
                ($0.lifespan == MetadataRecordLifespan.process &&
                 $0.lifespanId != currentProcessId)
            }
            filterRecords.forEach{
                storage.remove($0.vvid)
            }
        }else{
            let filterRecords = storage.get().filter{
                $0.lifespan == MetadataRecordLifespan.process &&
                $0.lifespanId != currentProcessId
            }
            filterRecords.forEach{
                storage.remove($0.vvid)
            }
        }
    }

    /// Removes the `MetadataRecord` for the given values.
    public func removeMetadata(
        key: String,
        type: MetadataRecordType,
        lifespan: MetadataRecordLifespan,
        lifespanId: String
    ) {
        let storage = IMQAMuti<MetadataRecord>()
        let filterReocrds = storage.get().filter{
            $0.key == key &&
            $0.type == type &&
            $0.lifespan == lifespan &&
            $0.lifespanId == lifespanId
        }
        filterReocrds.forEach{
            storage.remove($0.vvid)
        }
    }

    /// Removes all `MetadataRecords` for the given lifespans.
    /// - Note: This method is inteded to be indirectly used by implementers of the SDK
    ///         For this reason records of the `.requiredResource` type are not removed.
    public func removeAllMetadata(type: MetadataRecordType, lifespans: [MetadataRecordLifespan]) throws {
        guard type != .requiredResource && lifespans.count > 0 else {
            return
        }
        let storage = IMQAMuti<MetadataRecord>()
        let filterReocrds = storage.get().filter{
            var condition = ($0.type == type)
            var condition2: Bool = false
            for lifespan in lifespans {
                if lifespan == $0.lifespan {
                    condition2 = true
                    break
                }
            }
            return (condition && condition2)
        }
        filterReocrds.forEach{
            storage.remove($0.vvid)
        }
    }

    /// Removes all `MetadataRecords` for the given keys and timespan.
    /// Note that this method is inteded to be indirectly used by implementers of the SDK
    /// For this reason records of the `.requiredResource` type are not removed.
    public func removeAllMetadata(keys: [String], lifespan: MetadataRecordLifespan) throws {
        guard keys.count > 0 else {
            return
        }
        let storage = IMQAMuti<MetadataRecord>()
        let filterReocrds = storage.get().filter{
            var condition = ($0.type != MetadataRecordType.requiredResource)
            var condition2: Bool = false
            for key in keys {
                if key == $0.key{
                    condition2 = true
                    break
                }
            }
            return (condition && condition2)
        }
        filterReocrds.forEach{
            storage.remove($0.vvid)
        }
    }

    /// Returns the `MetadataRecord` for the given values.
    public func fetchMetadata(
        key: String,
        type: MetadataRecordType,
        lifespan: MetadataRecordLifespan,
        lifespanId: String = ""
    ) -> MetadataRecord? {
        let storage = IMQAMuti<MetadataRecord>()
        let filterRecords = storage.get().filter{
            $0.key == key && $0.type == type && $0.lifespan == lifespan
        }
        return filterRecords.first
    }

    /// Returns the permanent required resource for the given key.
    public func fetchRequiredPermanentResource(key: String) -> MetadataRecord? {
        return fetchMetadata(key: key, type: .requiredResource, lifespan: .permanent)
    }

    /// Returns all records with types `.requiredResource` or `.resource`
    public func fetchAllResources() -> [MetadataRecord] {
        let storage = IMQAMuti<MetadataRecord>()
        let filterRecords: [MetadataRecord] = storage.get().filter{
            ($0.type == MetadataRecordType.requiredResource) ||
            ($0.type == MetadataRecordType.resource)
        }
        return filterRecords
    }

    /// Returns all records with types `.requiredResource` or `.resource` that are tied to a given session id
    public func fetchResourcesForSessionId(_ sessionId: SessionIdentifier) -> [MetadataRecord] {
        let sessionRecordStorage = IMQAMuti<SessionRecord>()
        let session = sessionRecordStorage.fetch(sessionId.toString)
        guard let session = session else { return [] }
        let metadataRecordStorage = IMQAMuti<MetadataRecord>()
        return metadataRecordStorage.get().filter{
            ((
                $0.lifespan == MetadataRecordLifespan.session &&
                $0.lifespanId == session.id.toString
            ) || (
                $0.lifespan == MetadataRecordLifespan.process &&
                $0.lifespanId == session.processId.hex
            ) ||
            $0.lifespan == MetadataRecordLifespan.permanent) &&
            ($0.type == MetadataRecordType.requiredResource ||
             $0.type == MetadataRecordType.resource)
        }
    }

    /// Returns all records with types `.requiredResource` or `.resource` that are tied to a given process id
    public func fetchResourcesForProcessId(_ processId: ProcessIdentifier) -> [MetadataRecord] {
        let metadataRecordStorage = IMQAMuti<MetadataRecord>()
        return metadataRecordStorage.get().filter{
            ((
                $0.lifespan == MetadataRecordLifespan.process &&
                $0.lifespanId == processId.hex
            ) ||
            $0.lifespan == MetadataRecordLifespan.permanent) &&
            ($0.type == MetadataRecordType.requiredResource ||
             $0.type == MetadataRecordType.resource)
        }
    }

    /// Returns all records of the `.customProperty` type that are tied to a given session id
    public func fetchCustomPropertiesForSessionId(_ sessionId: SessionIdentifier) -> [MetadataRecord] {
        let sessionRecordStorage = IMQAMuti<SessionRecord>()
        guard let session = sessionRecordStorage.fetch(sessionId.toString) else{
            return []
        }
        
        let metadataRecordStorage = IMQAMuti<MetadataRecord>()
        return metadataRecordStorage.get().filter{
            ((
                $0.lifespan == MetadataRecordLifespan.session &&
                $0.lifespanId == session.id.toString
            ) || (
                $0.lifespan == MetadataRecordLifespan.process &&
                $0.lifespanId == session.processId.hex
            ) ||
            $0.lifespan == MetadataRecordLifespan.permanent) &&
            ($0.type == MetadataRecordType.customProperty)
        }
    }

    /// Returns all records of the `.personaTag` type that are tied to a given session id
    public func fetchPersonaTagsForSessionId(_ sessionId: SessionIdentifier) throws -> [MetadataRecord] {
        
        let storage = IMQAMuti<SessionRecord>()
        guard let session = storage.fetch(sessionId.toString) else{return []}
        
        let metadataRecordstorage = IMQAMuti<MetadataRecord>()
        let filterValues = metadataRecordstorage.get().filter{
            ($0.lifespan == MetadataRecordLifespan.session &&
            $0.lifespanId == sessionId.toString) ||
            ($0.lifespan == MetadataRecordLifespan.process &&
             $0.lifespanId == session.processId.hex) ||
            $0.lifespan == MetadataRecordLifespan.permanent
        }
        return filterValues
    }

    /// Returns all records of the `.personaTag` type that are tied to a given process id
    public func fetchPersonaTagsForProcessId(_ processId: ProcessIdentifier) throws -> [MetadataRecord] {
        let storage = IMQAMuti<MetadataRecord>()
        return storage.get().filter{
            ((
                $0.lifespan == MetadataRecordLifespan.process &&
                $0.lifespanId == processId.hex
            ) ||
            $0.lifespan == MetadataRecordLifespan.permanent) &&
            ($0.type == MetadataRecordType.personaTag)
        }
    }
}
