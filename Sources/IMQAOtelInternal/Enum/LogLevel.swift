//
//  InternalLogger.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/24.
//

import Foundation

/// Levels ordered by severity
@objc public enum LogLevel: Int {
    case none
    case trace
    case debug
    case info
    case warning
    case error

    #if DEBUG
    public static let `default`: LogLevel = .debug
    #else
    public static let `default`: LogLevel = .error
    #endif

    public var severity: LogSeverity {
        switch self {
        case .trace: return LogSeverity.trace
        case .debug: return LogSeverity.debug
        case .info: return LogSeverity.info
        case .warning: return LogSeverity.warn
        default: return LogSeverity.error
        }
    }
}

