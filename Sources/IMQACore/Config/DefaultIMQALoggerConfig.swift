//
//  DefaultIMQALoggerConfig.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/16/25.
//

struct DefaultIMQALoggerConfig: IMQALoggerConfig {
    let batchLifetimeInSeconds: Int = 60
    let maximumTimeBetweenLogsInSeconds: Int = 20
    let maximumAttributes: Int = 10
    let maximumMessageLength: Int = 128
    let logAmountLimit: Int = 10
}
