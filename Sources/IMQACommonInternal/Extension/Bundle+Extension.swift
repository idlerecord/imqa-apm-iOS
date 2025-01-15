//
//  Bundle+Extension.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/23.
//

import Foundation

public extension Bundle{
    class var appIdentifier: String{
        if let value = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
            return value
        }
        return ""
    }
    
    class var appVersion: String {
        if let value = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return value
        }
        return ""
    }
    
    class var appBuildVersion: String {
        if let value = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return value
        }
        return ""
    }
    
    class var appName: String{
        if let value = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            return value
        }
        return ""
    }
    
    var isUIKit: Bool {
        return bundleURL.lastPathComponent == "UIKitCore.framework" // on iOS 12+
            || bundleURL.lastPathComponent == "UIKit.framework"     // on iOS 11
    }
}
