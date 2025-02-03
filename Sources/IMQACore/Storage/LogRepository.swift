//
//  LogRepository.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/29.
//
import IMQACommonInternal

internal protocol LogRepository {
    func create(_ log: LogRecord, completion: (Result<LogRecord, Error>) -> Void)
    func fetchAll(excludingProcessIdentifier processIdentifier: ProcessIdentifier) throws -> [LogRecord]
    func remove(logs: [LogRecord]) throws
    func removeAllLogs() throws
}
