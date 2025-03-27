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
    
    static var currentSDKVersion: String = IMQAMeta.sdkVersion
    static var savedSDKVersionKey: String = "savedSDKVersion"
    static var savedAppVersionKey: String = "savedAppVersion"
    
    public var mmkv: MMKV!
    
    var suitName:String = Bundle.appIdentifier + ".userdefault"

    static let rootDir = IMQAStorageUnit.path.appending("/IMQA")
    static let currentSubDir = IMQAStorageUnit.rootDir.appending("/APP_\(Bundle.appVersion)/sdk_\(IMQAStorageUnit.currentSDKVersion)")
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
        
        
        //app  버전있을때
        if let savedAppVersion = UserDefaults(suiteName: suitName)?.string(forKey: IMQAStorageUnit.savedAppVersionKey) {
            //app 버전 다를때
            if savedAppVersion != Bundle.appVersion {
                let exceptFolder: String = IMQAStorageUnit.rootDir.appending("/APP_\(Bundle.appVersion)")
                let rootDir = IMQAStorageUnit.rootDir
                deleteAllExcept(exceptFolder: exceptFolder, in: IMQAStorageUnit.rootDir)
                
                UserDefaults(suiteName: suitName)?.set(Bundle.appVersion, forKey: IMQAStorageUnit.savedAppVersionKey)
                UserDefaults(suiteName: suitName)?.set(IMQAStorageUnit.currentSDKVersion, forKey: IMQAStorageUnit.savedSDKVersionKey)
                UserDefaults(suiteName: suitName)?.synchronize()
        //app 버전 같을때
            }else{
                if let savedSDKVersion = UserDefaults(suiteName: suitName)?.string(forKey: IMQAStorageUnit.savedSDKVersionKey) {
                    if savedSDKVersion != IMQAStorageUnit.currentSDKVersion{
                        let exceptFoler: String = IMQAStorageUnit.rootDir.appending("/APP_\(Bundle.appVersion)/sdk_\(IMQAStorageUnit.currentSDKVersion)")
                        let rootDir = IMQAStorageUnit.rootDir.appending("/APP_\(Bundle.appVersion)")
                        deleteAllExcept(exceptFolder: exceptFoler, in: rootDir)
                        
                        UserDefaults(suiteName: suitName)?.set(IMQAStorageUnit.currentSDKVersion, forKey: IMQAStorageUnit.savedSDKVersionKey)
                        UserDefaults(suiteName: suitName)?.synchronize()
                    }
                }
            }
        }else{
            UserDefaults(suiteName: suitName)?.set(Bundle.appVersion, forKey: IMQAStorageUnit.savedAppVersionKey)
            UserDefaults(suiteName: suitName)?.set(IMQAStorageUnit.currentSDKVersion, forKey: IMQAStorageUnit.savedSDKVersionKey)
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
    
    func removeFolder(path:String) {
        let manager = FileManager.default
        if manager.fileExists(atPath: path) {
            do {
                try manager.removeItem(atPath: path)
            } catch let error {
                IMQA.logger.debug("removeFolder error: \(error)")
            }
        }
    }
    
    func deleteAllExcept(exceptFolder: String, in directoryPath: String) {
        let fileManager = FileManager.default

        do {
            // 获取当前目录下的所有文件和文件夹
            let contents = try fileManager.contentsOfDirectory(atPath: directoryPath)

            for item in contents {
                let itemPath = (directoryPath as NSString).appendingPathComponent(item)

                // 检查是否是要保留的文件夹
                if item == exceptFolder {
//                    print("Skipping: \(itemPath)")
                    continue
                }

                // 删除文件或文件夹
                try fileManager.removeItem(atPath: itemPath)
//                print("Deleted: \(itemPath)")
            }
        } catch {
//            print("Error deleting items: \(error.localizedDescription)")
        }
    }
    

    public static func custom(mmkvID: String? = "default", cryptKey: Data?, mode: MMKVMode = .multiProcess) -> MMKV {
        initializeMMKV()
        if let mmkvID = mmkvID, let mmkv = MMKV(mmapID: mmkvID, cryptKey: cryptKey, mode: mode) {
            return mmkv
        } else {
            return MMKV.default()!
        }
    }

    private static func initializeMMKV() {
        guard !didInitialize else {
            return
        }

        do {
            try? FileManager.default.createDirectory(atPath: currentSubDir, withIntermediateDirectories: true)
        } catch let error {
            
        }
        
        MMKV.initialize(rootDir: currentSubDir, logLevel: .none)
    }
}

