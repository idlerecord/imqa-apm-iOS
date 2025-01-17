//
//  IMQALoggerConfig.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/16/25.
//

import Foundation

public protocol IMQALoggerConfig: Equatable {
    var batchLifetimeInSeconds: Int { get }
    var maximumTimeBetweenLogsInSeconds: Int { get }
    var maximumMessageLength: Int { get }
    var maximumAttributes: Int { get }
    var logAmountLimit: Int { get }
}

extension IMQALoggerConfig {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.batchLifetimeInSeconds == rhs.batchLifetimeInSeconds &&
        lhs.maximumTimeBetweenLogsInSeconds == rhs.maximumTimeBetweenLogsInSeconds &&
        lhs.maximumMessageLength == rhs.maximumMessageLength &&
        lhs.maximumAttributes == rhs.maximumAttributes &&
        lhs.logAmountLimit == rhs.logAmountLimit
    }
}
