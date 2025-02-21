//
//  LogFileManager.swift
//  IMQAIO
//
//  Created by Hunta Park on 2/20/25.
//

import Foundation

class LogFileManager {
    static let shared = LogFileManager()
    let fileName = "log.txt"
    let fileManager = FileManager.default
    
    var fileURL: URL {
        guard let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("无法获取文档目录")
        }
        let fileURL = dir.appendingPathComponent(fileName)
        return fileURL
    }
    
    private init() {
        
    }
    func recordToFile(text: String){

        let newText = text + "\n" // 每条数据换行
        let data = newText.data(using: .utf8)!
        
        if fileManager.fileExists(atPath: fileURL.path) {
            // 文件已存在，追加内容
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile() // 移动到文件末尾
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            // 文件不存在，创建新文件并写入
            try? data.write(to: fileURL, options: .atomic)
        }

    }
    

    
}

