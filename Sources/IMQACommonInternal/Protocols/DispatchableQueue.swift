//
//  DispatchableQueue.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/9/25.
//

import Foundation

public protocol DispatchableQueue: AnyObject {
    func async(_ block: @escaping () -> Void)
    func sync(execute block: () -> Void)
}

extension DispatchQueue: DispatchableQueue {
    public func async(_ block: @escaping () -> Void) {
        async(group: nil, execute: block)
    }
}
