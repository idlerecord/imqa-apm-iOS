//
//  IMQAStore.swift
//  Imqa-sdk-ios
//
//  Created by Hunta Park on 11/25/24.
//

import Foundation
import MMKV
import IMQAOtelInternal

public struct VersionSemantics {
    static let defaultKey: String = Bundle.appIdentifier
}

class IMQAStorageUnit {
    public static var shared = IMQAStorageUnit()

    var mmkvID: String = ""
    
    static var currentVersion: String = IMQAMeta.sdkVersion
    static var savedVersionKey: String = "savedVersion"
    
    public var mmkv: MMKV!
    
    var suitName:String = Bundle.appIdentifier + ".userdefault"

    static let rootDir = IMQAStorageUnit.path.appending("/IMQA")
    static let currentSubDir = IMQAStorageUnit.rootDir.appending("/\(IMQAStorageUnit.currentVersion)")
    private static let didInitialize = false
    
    static let path: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        return paths[0]
    }()

    private init() {}
    
    func create(mmkvID: String = "default",
                cryptKey: Data? = nil,
                mode: MMKVMode = .multiProcess,
                logger: InternalLogger) {
        
        mmkv = IMQAStorageUnit.custom(mmkvID: mmkvID, cryptKey: cryptKey, mode: mode)
        guard let savedVersion = UserDefaults(suiteName: suitName)?.string(forKey: IMQAStorageUnit.savedVersionKey) else{
            UserDefaults(suiteName: suitName)?.set(IMQAStorageUnit.currentVersion, forKey: IMQAStorageUnit.savedVersionKey)
            UserDefaults(suiteName: suitName)?.synchronize()
            return
        }
        if savedVersion != IMQAStorageUnit.currentVersion{
            clear(path: IMQAStorageUnit.rootDir.appending("/\(savedVersion)"))
            UserDefaults(suiteName: suitName)?.set(IMQAStorageUnit.currentVersion, forKey: IMQAStorageUnit.savedVersionKey)
            UserDefaults(suiteName: suitName)?.synchronize()
        }
    }

    func clear(path:String) {
        let manager = FileManager.default
        let path = path
        if manager.fileExists(atPath: path) {
            try! manager.removeItem(atPath: path.appending(mmkvID))
        }

        if manager.fileExists(atPath: path) {
            try! manager.removeItem(atPath: path.appending("\(mmkvID).crc"))
        }
    }
    

    public static func custom(mmkvID: String? = "default", cryptKey: Data?, mode: MMKVMode = .singleProcess) -> MMKV {
        initializeMMKV()
        if let mmkvID = mmkvID, let mmkv = MMKV(mmapID: mmkvID, cryptKey: cryptKey, mode: mode) {
//        if let mmkvID = mmkvID {
//            let mmkv = MMKV.init(mmapID: mmkvID, cryptKey: cryptKey, rootPath: currentSubDir, mode: .multiProcess, expectedCapacity: 0)
            return mmkv
        } else {
            return MMKV.default()!
        }
    }

    private static func initializeMMKV() {
        guard !didInitialize else {
            return
        }

        try? FileManager.default.createDirectory(atPath: currentSubDir, withIntermediateDirectories: true)
        MMKV.initialize(rootDir: currentSubDir, logLevel: .none)
    }
}

