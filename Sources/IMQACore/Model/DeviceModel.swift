//
//  DeviceModel.swift
//  IMQAMpmAgent
//
//  Created by Hunta on 2024/10/16.
import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

struct DeviceModel {
    static var systemName: String {
#if canImport(UIKit) && !os(watchOS)
        return UIDevice.current.systemName
#else
        return ""
#endif
        
    }
    
    static var systemVersion: String {
#if canImport(UIKit) && !os(watchOS)
        return UIDevice.current.systemVersion
#else
        return ""
#endif
    }
            
    static var manufacturer: String{
        return "Apple"
    }
    
    static var brand: String{
        return "iPhone"
    }
    
    static var model: String {
#if canImport(UIKit) && !os(watchOS)
        return UIDevice.current.model
#else
        return ""
#endif
    }
    
}

