//
//  Untitled.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/22.
//
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

public struct BatteryModel {

    public static var isCharging:Bool{
#if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        if UIDevice.current.batteryState == .charging {
            return true
        }
#endif
        return false
    }
    
    public static var level: String{
#if canImport(UIKit)
        return "\(UIDevice.current.batteryLevel * 100)%"
#else
        return "0%"
#endif
    }

}


