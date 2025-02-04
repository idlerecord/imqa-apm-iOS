//
//  IMQAStorage.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/29.
//
import Foundation
import MMKV
import IMQAOtelInternal
import IMQACommonInternal

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

internal typealias Storage = IMQAStorageMetadataFetcher & LogRepository

public class IMQAStorage: Storage{
    
    public private(set) var options: Options
    public private(set) var appId: String
    public private(set) var logger: InternalLogger
    
    /// Returns an `IMQAStorage` instance for the given `IMQAStorage.Options`
    /// - Parameters:
    ///   - options: `IMQAStorage.Options` instance
    ///   - logger : `IMQAConsoleLogger` instance
    public init(options: Options, logger: InternalLogger, appId: String) {
        self.options = options
        self.logger = logger
        self.appId = appId
        IMQAStorageUnit.shared.create(mmkvID: "IMQAStorage",
                                mode: MMKVMode.multiProcess,
                                logger: logger)
#if canImport(UIKit)
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { notifiation in
            MMKV.onAppTerminate()
        }
#endif
    }

    /// Deletes the database and recreates it from scratch
    func reset() {
        IMQAStorageUnit.shared.mmkv.close()
    }
    
}


// MARK: - Sync operations
extension IMQAStorage {
    public func update(session: SessionRecord){
        let storage = IMQAMuti<SessionRecord>()
        storage.save(session)
    }

    @discardableResult
    public func delete(session: SessionRecord)->Bool{
        let storage = IMQAMuti<SessionRecord>()
        return storage.remove(session.id.toString)
    }

    public func fetchAll() -> [SessionRecord]{
        let storage = IMQAMuti<SessionRecord>()
        return storage.get()
    }
    
    public func fetchOne(id: String) -> SessionRecord?{
        let storage = IMQAMuti<SessionRecord>()
        return storage.fetch(id)
    }
}

extension IMQAStorage {
    /// Will attempt to delete the provided file.
    private static func deleteDBFile(at fileURL: URL, logger: InternalLogger) throws {
        do {
            let fileURL = URL(fileURLWithPath: fileURL.path)
            try FileManager.default.removeItem(at: fileURL)
        } catch let error {
            logger.error(
                """
                IMQAStorage failed to remove DB file.
                Error: \(error.localizedDescription)
                Filepath: \(fileURL)
                """
            )
        }
    }
}

extension LogRecord: Identifiable {
    public var id: String {
        identifier.value.uuidString
    }
}

extension IMQAStorage{
    func writeLog(_ log: LogRecord) throws {
        let storage = IMQAMuti<LogRecord>()
        storage.save(log)
    }

    public func fetchAll(excludingProcessIdentifier processIdentifier: ProcessIdentifier) throws -> [LogRecord] {
        let storage = IMQAMuti<LogRecord>()
        return storage.get().filter{$0.processIdentifier.value != processIdentifier.value}
    }

    public func removeAllLogs() {
        let storage = IMQAMuti<LogRecord>()
        storage.remove()
    }

    public func remove(logs: [LogRecord]) {
        let storage = IMQAMuti<LogRecord>()
        logs.forEach { reocord in
            storage.remove(reocord.vvid)
        }
    }

    public func getAll() -> [LogRecord] {
        let storage = IMQAMuti<LogRecord>()
        return storage.get()
    }

    public func create(_ log: LogRecord, completion: (Result<LogRecord, Error>) -> Void) {
        do {
            try writeLog(log)
            completion(.success(log))
        } catch let exception {
            completion(.failure(exception))
        }
    }
}
