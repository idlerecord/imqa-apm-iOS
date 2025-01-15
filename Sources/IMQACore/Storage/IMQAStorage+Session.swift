//
//  IMQAStorage+Session.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/31.
//
import Foundation
import IMQACommonInternal
import IMQAOtelInternal

extension IMQAStorage {
    /// Adds a session to the storage synchronously.
    /// - Parameters:
    ///   - id: Identifier of the session
    ///   - state: `SessionState` of the session
    ///   - processId: `ProcessIdentifier` of the session
    ///   - traceId: String representing the trace identifier of the corresponding session span
    ///   - spanId: String representing the span identifier of the corresponding session span
    ///   - startTime: `Date` of when the session started
    ///   - endTime: `Date` of when the session ended (optional)
    ///   - lastHeartbeatTime: `Date` of the last heartbeat for the session (optional).
    ///   - crashReportId: Identifier of the crash report linked with this session
    /// - Returns: The newly stored `SessionRecord`
    @discardableResult
    public func addSession(
        id: SessionIdentifier,
        state: SessionState,
        processId: ProcessIdentifier,
        traceId: String,
        spanId: String,
        startTime: Date,
        endTime: Date? = nil,
        lastHeartbeatTime: Date? = nil,
        crashReportId: String? = nil
    ) throws -> SessionRecord {
        let session = SessionRecord(
            id: id,
            processId: processId,
            state: state.rawValue,
            traceId: traceId,
            spanId: spanId,
            startTime: startTime,
            endTime: endTime,
            lastHeartbeatTime: lastHeartbeatTime
        )

        upsertSession(session)

        return session
    }

    /// Adds or updates a `SessionRecord` to the storage synchronously.
    /// - Parameter record: `SessionRecord` to insert
    public func upsertSession(_ session: SessionRecord) {
        let storage = IMQAMuti<SessionRecord>()
        storage.save(session)
    }

    /// Fetches the stored `SessionRecord` synchronously with the given identifier, if any.
    /// - Parameters:
    ///   - id: Identifier of the session
    /// - Returns: The stored `SessionRecord`, if any

    public func fetchSession(id: SessionIdentifier) -> SessionRecord? {
        let storage = IMQAMuti<SessionRecord>()
        let sessionRecord = storage.fetch(id.toString)
        return sessionRecord
    }

    /// Synchronously fetches the newest session in the storage, ignoring the current session if it exists.
    /// - Returns: The newest stored `SessionRecord`, if any
    public func fetchLatestSession(
        ignoringCurrentSessionId sessionId: SessionIdentifier? = nil
    ) throws -> SessionRecord? {
        var session: SessionRecord?
        let storage = IMQAMuti<SessionRecord>()
        let filterRecords = storage.get()
        session = filterRecords.first
        return session
    }

    /// Synchronously fetches the oldest session in the storage, if any.
    /// - Returns: The oldest stored `SessionRecord`, if any
    public func fetchOldestSession() throws -> SessionRecord? {
        let storage = IMQAMuti<SessionRecord>()
        let filterRecords = storage.get()
        return filterRecords.last
    }
}
