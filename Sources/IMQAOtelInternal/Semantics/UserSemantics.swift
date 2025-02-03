//
//  UserSemantics.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//
import Foundation

public struct UserSemantics {
    public static var userProfileUserDefaultKey: String {
        if let value = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
            return value + ".userdefault"
        }
        return "" + ".userdefault"
    }
}
