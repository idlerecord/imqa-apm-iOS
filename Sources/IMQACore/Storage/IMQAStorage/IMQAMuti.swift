//
//  IMQAMuti.swift
//  Imqa-sdk-ios
//
//  Created by Hunta Park on 11/25/24.
//


import Foundation
import IMQAOtelInternal

class IMQAMuti<T: Codable & VVIdenti> {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSRecursiveLock()

    private let key = "\([T].self)"

    func save(_ ts: [T]) {
        lock.lock()
        defer { lock.unlock() }
        
        if let data = try? encoder.encode(ts) {
            IMQAStorageUnit.shared.mmkv.set(data, forKey: key)
        } else {
            IMQAStorageUnit.shared.mmkv.removeValue(forKey: key)
        }
    }

    func get() -> [T] {
        lock.lock()
        defer { lock.unlock() }

        if let data = IMQAStorageUnit.shared.mmkv.data(forKey: key), let values = try? decoder.decode([T].self, from: data) {
            return values
        }
        return []
    }

    func save(_ t: T) {
        lock.lock()
        defer { lock.unlock() }

        var items = get()
        if let index = items.firstIndex(where: { $0.vvid == t.vvid }) {
            items[index] = t
        } else {
            items.insert(t, at: 0)
        }

        save(items)
    }
    
    func fetch(_ vvid: String) -> T? {
        lock.lock()
        defer { lock.unlock() }

        if let data = IMQAStorageUnit.shared.mmkv.data(forKey: key), let values = try? decoder.decode([T].self, from: data) {
            let filterValues = values.filter{$0.vvid == vvid }
            return filterValues.first
        }
        return nil
    }
    

    func remove() {
        lock.lock()
        defer { lock.unlock() }

        IMQAStorageUnit.shared.mmkv.removeValue(forKey: key)
    }

    func count() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return get().count
    }
    
    func exist() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return count() != 0
    }

    func exist(_ vvid: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let items = get()
        let index = items.firstIndex(where: { $0.vvid == vvid })
        return index != nil
    }

    @discardableResult
    func remove(_ vvid: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        var isReturn: Bool = false
        var items = get()
        if let index = items.firstIndex(where: { $0.vvid == vvid }) {
            items.remove(at: index)
            isReturn = true
        }

        save(items)
        return isReturn
    }
    
    @discardableResult
    func size()->Int{
        return IMQAStorageUnit.shared.mmkv.valueSize(forKey: key, actualSize: true)
    }
}
