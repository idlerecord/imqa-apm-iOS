//
//  DeviceModel.swift
//  IMQAMpmAgent
//
//  Created by Hunta on 2024/10/16.
import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit


struct DeviceModel {
    static var systemName: String {
        return UIDevice.current.systemName
    }
    
    static var systemVersion: String {
        return UIDevice.current.systemVersion
    }
            
    static var manufacturer: String{
        return "Apple"
    }
    
    static var brand: String{
        return "iPhone"
    }
    
    static var model: String {
        return UIDevice.current.model
    }
    
}
#endif
