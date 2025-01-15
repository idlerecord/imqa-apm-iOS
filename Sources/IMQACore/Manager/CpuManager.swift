//
//  CpuManager.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//
import IMQACollectDeviceInfo

class CpuManager: NSObject {
    /// app이 cpu를 사용하는 퍼센트수
    /// - Returns: 퍼센트수 0~100까지
    static func getAppCPUUsage() -> Float {
        return FSCPUUsage.getAppCPUUsage()
    }
    
    
    /// system이 cpu를 사용하는 퍼센트수
    /// - Returns: 퍼센트수 0~100까지
    static func getSystemCPUUsage() -> Float {
        return FSCPUUsage.getSystemCPUUsage()
    }
    
    /// CPU 핵수량
    /// - Returns: 핵수량
    static func getCPUCoreNumber() -> Int {
        return FSCPUUsage.getCPUCoreNumber()
    }

    /// CPU 주파수
    /// - Returns: 주파수
    static func getCPUFrequency() -> UInt {
        return FSCPUUsage.getCPUFrequency()
    }

    /// Processor Architechture
    /// - Returns: Architechture
    static func getCPUArchitectureString() -> String {
        return FSCPUUsage.getCPUArchitectureString()
    }

    
    /// APP 이 cpu 사용상황
    /// - Returns: 사용상황
    static func getAppCPUUsageStruct() -> fs_app_cpu_usage{
        return FSCPUUsage.getAppCPUUsageStruct()
    }

    static func getSystemCPUUsageStruct() -> fs_system_cpu_usage {
        return FSCPUUsage.getSystemCPUUsageStruct()
    }
}
