//
//  MemoryModel.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/23.
//
import MachO
import Foundation

struct MemoryModel {
    
    static var memoryAllocated: String{
        return "\(MemoryManager.getAppRAMUsage())"
    }
    
    static var systemRAMUsage: String{
        return "\(MemoryManager.getSystemRAMUsage())"
    }
    
    static var memoryFree: String {
        return "\(MemoryManager.getSystemRAMAvailable())"
    }
    
    static var memoryTotal: String{
        return "\(MemoryManager.getSystemRAMTotal())"
    }
    
}
