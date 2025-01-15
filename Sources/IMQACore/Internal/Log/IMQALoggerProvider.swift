//
//  IMQALoggerProvider.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

public protocol IMQALoggerProvider: LoggerProvider {
    func get() -> Logger
    func update(_ config: any IMQALoggerConfig)
}

class DefaultIMQALoggerProvider: IMQALoggerProvider {
    private lazy var logger: IMQALogger = IMQALogger(sharedState: sharedState)

    let sharedState: IMQALogSharedState

    init(sharedState: IMQALogSharedState) {
        self.sharedState = sharedState
    }

    func get() -> Logger {
        logger
    }

    func update(_ config: any IMQALoggerConfig) {
        sharedState.update(config)
    }

    /// The parameter is not going to be used, as we're always going to create an `IMQALogger`
    /// which always has the same `instrumentationScope` (version & name)
    func get(instrumentationScopeName: String) -> Logger {
        get()
    }

    /// This method, defined by the `LoggerProvider` protocol, is intended to
    /// create a `LoggerBuilder` for a named `Logger` instance.
    ///
    /// In our implementation, the `instrumentationScopeName` parameter is not utilized since we
    /// consistently create an `IMQALoggerBuilder`. This builder, in turn, produces an `IMQALogger`
    /// instance with a fixed `instrumentationScope` (version & name).
    ///
    /// Consequently, we advise using `get()` or `get(instrumentationScopeName)` for standard
    /// `IMQALogger` retrieval. Directly instantiate an `IMQALoggerBuilder` only if you need a
    /// `Logger` with a distinct set of attributes.
    ///
    /// - Parameter instrumentationScopeName: An unused parameter in this context.
    /// - Returns: An instance of `IMQALoggerBuilder` which conforms to the `LoggerBuilder` interface.
    func loggerBuilder(instrumentationScopeName: String) -> LoggerBuilder {
        IMQALoggerBuilder(sharedState: sharedState)
    }
}
