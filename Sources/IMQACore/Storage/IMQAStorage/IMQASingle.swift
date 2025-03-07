//
//  IMQASingle.swift
//  Imqa-sdk-ios
//
//  Created by Hunta Park on 11/25/24.
//


import Foundation

class IMQASingle<T: Codable> {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSRecursiveLock()

    private let key: String = "\(T.self)"

    func save(_ item: T?) {
        lock.lock()
        defer { lock.unlock() }
        if let data = try? encoder.encode(item) {
            IMQAStorageUnit.shared.mmkv.set(data, forKey: key)
        } else {
            IMQAStorageUnit.shared.mmkv.removeValue(forKey: key)
        }
    }

    func get() -> T? {
        lock.lock()
        defer { lock.unlock() }
        if let data = IMQAStorageUnit.shared.mmkv.data(forKey: key), let value = try? decoder.decode(T.self, from: data) {
            return value
        }
        return nil
    }

    func remove() {
        IMQAStorageUnit.shared.mmkv.removeValue(forKey: key)
    }
    
    @discardableResult
    func size()->Int{
        return IMQAStorageUnit.shared.mmkv.valueSize(forKey: key, actualSize: true)
    }

}
