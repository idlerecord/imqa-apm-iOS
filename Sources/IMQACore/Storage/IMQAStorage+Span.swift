//
//  IMQAStorage+Span.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/31.
//

import Foundation
import IMQACommonInternal
import IMQAOtelInternal

extension IMQAStorage {

    static let defaultSpanLimitByType = 1500

    /// Adds a span to the storage synchronously.
    /// - Parameters:
    ///   - id: Identifier of the span
    ///   - name: name of the span
    ///   - traceId: Identifier of the trace containing this span
    ///   - type: SpanType of the span
    ///   - data: Data of the span
    ///   - startTime: Date of when the span started
    ///   - endTime: Date of when the span ended (optional)
    /// - Returns: The newly stored `SpanRecord`
    @discardableResult
    public func addSpan(
        id: String,
        name: String,
        traceId: String,
        type: IMQASpanType,
        data: Data,
        startTime: Date,
        endTime: Date? = nil,
        processIdentifier: ProcessIdentifier = .current
    ) throws -> SpanRecord {

        let span = SpanRecord(
            id: id,
            name: name,
            traceId: traceId,
            type: type,
            data: data,
            startTime: startTime,
            endTime: endTime,
            processIdentifier: processIdentifier
        )
        try upsertSpan(span)

        return span
    }

    /// Adds or updates a `SpanRecord` to the storage synchronously.
    /// - Parameter record: `SpanRecord` to upsert
    public func upsertSpan(_ span: SpanRecord) throws {
         let storage = IMQAMuti<SpanRecord>()
        storage.save(span)
    }

    /// Fetches the stored `SpanRecord` synchronously with the given identifiers, if any.
    /// - Parameters:
    ///   - id: Identifier of the span
    ///   - traceId: Identifier of the trace containing this span
    /// - Returns: The stored `SpanRecord`, if any
    public func fetchSpan(id: String, traceId: String) throws -> SpanRecord? {
        var span: SpanRecord?
        let storage = IMQAMuti<SpanRecord>()
        span = storage.fetch(id)
        return span
    }

    /// Synchronously removes all the closed spans older than the given date.
    /// If no date is provided, all closed spans will be removed.
    /// - Parameter date: Date used to determine which spans to remove
    public func cleanUpSpans(date: Date? = nil) throws {
        let storage = IMQAMuti<SpanRecord>()
        let records = storage.get()
        if let date = date {
            let filterRecords = records.filter{$0.endTime != nil && ($0.endTime ?? $0.startTime) < date}
            for reocord in filterRecords {
                storage.remove(reocord.id)
            }
        }else{
            let filterRecords = records.filter{$0.endTime != nil}
            for reocord in filterRecords {
                storage.remove(reocord.id)
            }
        }
    }

    /// Synchronously closes all open spans with the given `endTime`.
    /// - Parameters:
    ///   - endTime: Identifier of the trace containing this span
    public func closeOpenSpans(endTime: Date) {
        let storage = IMQAMuti<SpanRecord>()
        let records = storage.get()
        let filterRecords = records.filter{
            $0.endTime == nil && $0.processIdentifier != ProcessIdentifier.current
        }
        filterRecords.forEach{
            $0.endTime = endTime
            storage.save($0)
        }
    }

    /// Fetch spans for the given session record
    /// Will retrieve all spans that overlap with session record start / end (or last heartbeat)
    /// that occur within the same process. For cold start sessions, will include spans that occur before the session starts.
    /// Parameters:
    /// - sessionRecord: The session record to fetch spans for
    /// - ignoreSessionSpans: Whether to ignore the session's (or any other session's) own span
    public func fetchSpans(
        for sessionRecord: SessionRecord,
        ignoreSessionSpans: Bool = true,
        limit: Int = 1000
    ) -> [SpanRecord] {        
        let storage = IMQAMuti<SpanRecord>()
        let records = storage.get()
        let sessionEndTime = sessionRecord.endTime ?? sessionRecord.lastHeartbeatTime
        let filterRecords = records.filter{
            var condition:Bool = false
            if sessionRecord.coldStart{
                condition = ($0.processIdentifier == sessionRecord.processId) && ($0.startTime <= sessionEndTime)
            }else{
                condition = (($0.startTime <= sessionRecord.startTime) && ($0.endTime ?? Date() >= sessionRecord.startTime)) ||
                (($0.startTime >= sessionRecord.startTime) && (($0.endTime ?? Date() <= sessionRecord.endTime ?? Date()) || ($0.endTime == nil))) ||
                (($0.startTime <= sessionRecord.endTime ?? Date()) && (($0.endTime ?? Date() >= sessionRecord.endTime ?? Date()) || $0.endTime == nil)) ||
                ($0.startTime <= sessionRecord.startTime && (($0.endTime ?? Date() >= sessionRecord.endTime ?? Date()) || $0.endTime == nil))
            }
            if ignoreSessionSpans{
#warning("fix me")
                condition = condition && ($0.type != IMQASpanType.SESSION)
            }
            return condition
        }
        let count = filterRecords.count
        if count > limit{
            return Array(filterRecords[0..<limit])
        }
        return Array(filterRecords[0..<count])
    }
}

// MARK: - Database operations
fileprivate extension IMQAStorage {
    func upsertSpan(span: SpanRecord) {
        // update if its already stored
        
        let storage = IMQAMuti<SpanRecord>()
        if storage.exist(span.id){
            storage.save(span)
            return
        }

        // check limit and delete if necessary
        // default to 1500 if limit is not set
        let limit = options.spanLimits[span.type, default: Self.defaultSpanLimitByType]

        let count = spanCount(type: span.type)
        var records = requestSpans(of: span.type)
        if count >= limit {
            records = Array(records[(count - limit + 1)..<count])
            
        }
        records.append(span)
    }

    func requestSpans(of type: IMQASpanType) -> [SpanRecord] {
        let storage = IMQAMuti<SpanRecord>()
        return storage.get().filter{$0.type.rawValue == type.rawValue}
    }

    func spanCount(type: IMQASpanType) -> Int {
        let storage = IMQAMuti<SpanRecord>()
        let records = storage.get()
        let filters = records.filter{$0.type.rawValue == type.rawValue}
        return filters.count
    }

    func fetchSpans(type: IMQASpanType, limit: Int?) -> [SpanRecord] {
        let storage = IMQAMuti<SpanRecord>()
        let records = storage.get()
        let filters = records.filter{$0.type.rawValue == type.rawValue}
        if let limit = limit {
            return Array(filters[0..<limit])
        }
        return filters
    }
    
    func deleteSpans(spanIds: [String]) {
        let storage = IMQAMuti<SpanRecord>()
        let records = storage.get()
        let filters = records.filter{!spanIds.contains($0.id)}
        storage.save(filters)
    }
}
