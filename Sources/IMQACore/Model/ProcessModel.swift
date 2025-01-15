//
//  File.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/23.
//

import Foundation
import CoreFoundation

struct ProcessModel {
    //processID
    static var pid: String{
        return "\(ProcessInfo.processInfo.processIdentifier)"
    }
    
    //실행 명령
    static var command: String{
        return ProcessInfo.processInfo.processName
    }
                
    func toGBStr(memory: UInt64) -> String{
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryInGB = Double(physicalMemory) / (1024 * 1024 * 1024)
        return String(format: "%.2f GB", memoryInGB)
    }
    
    func toHumanTime(systemUptime: TimeInterval) ->String{
        let seconds = Int(systemUptime)
        let hours = seconds/3600
        let minutes = (seconds%3600)/60
        let secondsLeft = (seconds%3600)%60
        return "\(hours):\(minutes):\(secondsLeft)"
    }
    
    func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secondsLeft = (seconds % 3600) % 60
        return (hours, minutes, secondsLeft)
    }
}
