//
//  LogsBatch.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//
import Foundation

struct LogBatchLimits {
    let maxBatchAge: TimeInterval
    let maxLogsPerBatch: Int

    init(maxBatchAge: TimeInterval = 60, maxLogsPerBatch: Int = 20) {
        self.maxBatchAge = maxBatchAge
        self.maxLogsPerBatch = maxLogsPerBatch
    }
}
