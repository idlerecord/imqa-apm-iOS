//
//  PowerModeProvider.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/7.
//

import Foundation

public protocol PowerModeProvider {
    var isLowPowerModeEnabled: Bool { get }
}

@objc(IMQADefaultPowerModeProvider)
public class DefaultPowerModeProvider: NSObject, PowerModeProvider {
    @objc public var isLowPowerModeEnabled: Bool { ProcessInfo.processInfo.isLowPowerModeEnabled }
}
