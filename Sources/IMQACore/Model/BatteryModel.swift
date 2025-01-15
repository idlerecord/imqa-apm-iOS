//
//  Untitled.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/22.
//
#if canImport(UIKit) && !os(watchOS)
import UIKit

struct BatteryModel {
    static var isCharging:Bool{
        UIDevice.current.isBatteryMonitoringEnabled = true
        if UIDevice.current.batteryState == .charging {
            return true
        }
        return false
    }
    
    static var level: String{
        return "\(UIDevice.current.batteryLevel * 100)%"
    }
}
#endif
