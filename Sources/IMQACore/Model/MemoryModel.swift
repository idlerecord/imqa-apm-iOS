//
//  MemoryModel.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/23.
//
import MachO
import Foundation
import IMQACollectDeviceInfo

struct MemoryModel {
    
    static var memoryAllocated: String{
        return "\(FSRAMUsage.getAppRAMUsage())"
    }
    
    static var systemRAMUsage: String{
        return "\(FSRAMUsage.getSystemRAMUsage())"
    }
    
    static var memoryFree: String {
        return "\(FSRAMUsage.getSystemRAMAvailable())"
    }
    
    static var memoryTotal: String{
        return "\(FSRAMUsage.getSystemRAMTotal())"
    }
}
