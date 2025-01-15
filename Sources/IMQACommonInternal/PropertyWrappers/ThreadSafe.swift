//
//  ThreadSafe.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/24.
//

import Foundation

/// A thread-safe wrapper for properties.
///
/// This property wrapper uses an `UnfairLock` (aka. wrapper around `os_unfair_lock`) to ensure that access
/// to the wrapped property is thread-safe.
/// You can use it to protect properties that might be accessed from multiple threads simultaneously.
///
///     class IMQAClass {
///         @ThreadSafe var threadSafeProperty: Int = 0
///     }
///
/// Keep in mind that the underlying lock is "unfair", meaning that there's no guarantee about the order in which threads acquire the lock.
/// One thread might acquire the lock multiple times in a row while other threads are waiting.
///
/// - Important: Do not use this wrapper for recursive access patterns; it will deadlock.
@propertyWrapper
public final class ThreadSafe<Value> {
    private var value: Value
    private let lock = UnfairLock()

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    public var wrappedValue: Value {
        get {
            lock.locked { value }
        }
        set {
            lock.locked { value = newValue }
        }
    }

    public func modify(_ operation: (inout Value) -> Void) {
        lock.locked {
            operation(&value)
        }
    }
}

final public class UnfairLock {
    private var _lock: UnsafeMutablePointer<os_unfair_lock>

    public init() {
        _lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        _lock.initialize(to: os_unfair_lock())
    }

    deinit {
        _lock.deallocate()
    }

    public func locked<ReturnValue>(_ f: () throws -> ReturnValue) rethrows -> ReturnValue {
        os_unfair_lock_lock(_lock)
        defer { os_unfair_lock_unlock(_lock) }
        return try f()
    }
}
