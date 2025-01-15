//
//  IMQAReachabilityMonitor.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation
import Network

class IMQAReachabilityMonitor {
    private let queue: DispatchQueue
    private let monitor: NWPathMonitor
    private var wasConnected: Bool = true

    var onConnectionRegained: (() -> Void)?

    init(queue: DispatchQueue) {
        self.queue = queue
        self.monitor = NWPathMonitor()

        self.monitor.pathUpdateHandler = { [weak self] path in
            self?.update(connected: path.status == .satisfied)
        }
    }

    func start() {
        monitor.start(queue: self.queue)
    }

    private func update(connected: Bool) {
        if !wasConnected && connected {
            onConnectionRegained?()
        }

        wasConnected = connected
    }
}
