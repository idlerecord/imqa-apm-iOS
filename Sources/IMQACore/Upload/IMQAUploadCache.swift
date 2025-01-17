//
//  IMQAUploadCache.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation
import IMQAOtelInternal

class IMQAUploadCache {
    private(set) var options: IMQAUpload.CacheOptions
    
    let logger: InternalLogger
    
    private let queue = DispatchQueue(label: "com.imqa.uploadCache")
    
    init(options: IMQAUpload.CacheOptions, logger: InternalLogger) throws {
        self.options = options
        self.logger = logger
    }

    /// Fetches the cached upload data for the given identifier.
    /// - Parameters:
    ///   - id: Identifier of the data
    ///   - type: Type of the data
    /// - Returns: The cached `UploadDataRecord`, if any
    public func fetchUploadData(id: String, type: IMQAUploadType) -> UploadDataRecord? {
        return queue.sync {
            let storage = IMQAMuti<UploadDataRecord>()
            let uploadDataRecordContainer = storage.get().filter{
                $0.id == id && $0.type == type.rawValue
            }
            return uploadDataRecordContainer.first
        }
    }

    /// Fetches all the cached upload data.
    /// - Returns: An array containing all the cached `UploadDataRecords`
    public func fetchAllUploadData() -> [UploadDataRecord] {
        return queue.sync {
            let storage = IMQAMuti<UploadDataRecord>()
            let uploadDataRecordContainer = storage.get()
            return uploadDataRecordContainer
        }
    }

    /// Removes stale data based on size or date, if they're limited in options.
    @discardableResult public func clearStaleDataIfNeeded() -> UInt {
        return queue.sync {
            let limitDays = options.cacheDaysLimit
            let limitSize = options.cacheSizeLimit
            do{
                let recordsBasedOnDate = limitDays > 0 ? try fetchRecordsToDeleteBasedOnDate(maxDays: limitDays) : []
                let recordsBasedOnSize = limitSize > 0 ? try fetchRecordsToDeleteBasedOnSize(maxSize: limitSize) : []
                let recordsToDelete = Array(Set(recordsBasedOnDate + recordsBasedOnSize))

                let deleteCount = recordsToDelete.count

                if deleteCount > 0 {
        //            let span = IMQAOTel().buildSpan(
        //                name: "imqa-upload-cache-vacuum",
        //                type: .performance,
        //                attributes: ["removed": "\(deleteCount)"])
        //                .markAsPrivate()
        //            span.setStartTime(time: Date())
        //            let startedSpan = span.startSpan()
                    deleteRecords(recordIDs: recordsToDelete)
        //            startedSpan.end()

                    return UInt(deleteCount)
                }
                return 0
            }catch{
                logger.debug("Failed to clearStaleDataIfNeeded:\(error)")
            }
        }
    }

    /// Saves the given upload data to the cache.
    /// - Parameters:
    ///   - id: Identifier of the data
    ///   - type: Type of the data
    ///   - data: Data to cache
    /// - Returns: The newly cached `UploadDataRecord`
    @discardableResult func saveUploadData(id: String,
                                           type: IMQAUploadType,
                                           data: Data) -> UploadDataRecord {
        let record = UploadDataRecord(id: id,
                                      type: type.rawValue,
                                      data: data,
                                      attemptCount: 0,
                                      date: Date())
        do{
            try saveUploadData(record)
        } catch{
            logger.debug("Failed to save upload data:\(error)")
        }
        return record
    
    }

    /// Saves the given `UploadDataRecord` to the cache.
    /// - Parameter record: `UploadDataRecord` instance to save
    func saveUploadData(_ record: UploadDataRecord) {
        return queue.sync {
            let storage =  IMQAMuti<UploadDataRecord>()
            if storage.exist(record.vvid) {
                storage.save(record)
                return
            }
            let limit = self.options.cacheLimit
            if limit > 0 {
                let count = storage.get().count
                if count >= limit {
                    let redundant = count - Int(limit)
                    let removeRecords = storage.get().suffix(redundant)
                    removeRecords.forEach{
                        storage.remove($0.vvid)
                    }
                }
            }
            storage.save(record)
        }
    }

    /// Deletes the cached data for the given identifier.
    /// - Parameters:
    ///   - id: Identifier of the data
    ///   - type: Type of the data
    /// - Returns: Boolean indicating if the data was successfully deleted
    @discardableResult func deleteUploadData(id: String, type: IMQAUploadType) -> Bool {
        do{
            guard let uploadData = fetchUploadData(id: id, type: type) else {
                return false
            }

            return try deleteUploadData(uploadData)
        }catch{
            logger.debug("deleteUploadData error \(error)")
        }
    }

    /// Deletes the cached `UploadDataRecord`.
    /// - Parameter uploadData: `UploadDataRecord` to delete
    /// - Returns: Boolean indicating if the data was successfully deleted
    func deleteUploadData(_ uploadData: UploadDataRecord) -> Bool {
        return queue.sync {
            let storage = IMQAMuti<UploadDataRecord>()
            storage.remove(uploadData.vvid)
            return true
        }
    }

    /// Updates the attempt count of the upload data for the given identifier.
    /// - Parameters:
    ///   - id: Identifier of the data
    ///   - type: Type of the data
    ///   - attemptCount: New attempt count
    /// - Returns: Returns the updated `UploadDataRecord`, if any
    func updateAttemptCount(
        id: String,
        type: IMQAUploadType,
        attemptCount: Int
    ) {
        return queue.sync {
            let storage = IMQAMuti<UploadDataRecord>()
            let filterRecords = storage.get().filter{
                $0.id == id && $0.type == type.rawValue
            }
            filterRecords.forEach{
                $0.attemptCount = attemptCount
            }
            storage.save(filterRecords)
        }
    }

    /// Sorts Upload Cache by descending order and goes through it adding the space taken by each record.
    /// Once the __maxSize__ has been reached, all the following record IDs will be returned indicating those need to be deleted.
    /// - Parameter maxSize: The maximum allowed size in bytes for the Database.
    /// - Returns: An array of IDs of the oldest records which are making the DB go above the target maximum size.
    func fetchRecordsToDeleteBasedOnSize(maxSize: UInt) -> [String] {
        return queue.sync {
            let storage = IMQAMuti<UploadDataRecord>()
            storage.size()
            var result: [String] = []
    #warning("fix me please")
            return result

        }
    }

    /// Fetches all records that should be deleted based on them being older than __maxDays__ days
    /// - Parameter db: The database where to pull the data from, assumes the records to be UploadDataRecord.
    /// - Parameter maxDays: The maximum allowed days old a record is allowed to be cached.
    /// - Returns: An array of IDs from records that should be deleted.
    func fetchRecordsToDeleteBasedOnDate(maxDays: UInt) -> [String] {
        return queue.sync {
            let storage = IMQAMuti<UploadDataRecord>()
            let filterRecords = storage.get().filter{
                let maxDaysAgo = Date().addingTimeInterval(-Double((maxDays)) * 24 * 60 * 60)
                return ($0.date.timeIntervalSince1970 < maxDaysAgo.timeIntervalSince1970)
            }
            return filterRecords.map{$0.id}
        }
    }

    /// Deletes requested records from the database based on their IDs
    /// Assumes the records to be of type __UploadDataRecord__
    /// - Parameter recordIDs: The IDs array to delete
    func deleteRecords(recordIDs: [String]) {
        return queue.sync {
            let storage = IMQAMuti<UploadDataRecord>()
            recordIDs.forEach{
                storage.remove($0)
            }
        }
    }
}
