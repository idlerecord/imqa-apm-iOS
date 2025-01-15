//
//  SessionHeartbeat.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation

public class SessionHeartbeat {

    public static let defaultInterval: TimeInterval = 5.0

    let queue: DispatchQueue
    let interval: TimeInterval
    public var callback: (() -> Void)?

    var timer: DispatchSourceTimer?

    public init(queue: DispatchQueue, interval: TimeInterval) {
        self.queue = queue

        if interval > 0 {
            self.interval = interval
        } else {
            self.interval = Self.defaultInterval
        }
    }

    public func start() {
        stop()

        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.setEventHandler { [weak self] in
            self?.callback?()
        }

        timer?.schedule(deadline: .now() + interval, repeating: interval)
        timer?.activate()
    }

    public func stop() {
        timer?.cancel()
        timer = nil
    }
}
