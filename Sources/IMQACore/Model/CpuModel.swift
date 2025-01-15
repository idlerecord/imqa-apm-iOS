//
//  CpuModel.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/23.
//
import IMQACollectDeviceInfo

struct CpuModel {
    /// app이 cpu를 사용하는 퍼센트수
    static var AppCPUUsage: String{
        let retData = String(format: "%0.2f", CpuManager.getAppCPUUsage()) + "%"
        return retData
    }
}


