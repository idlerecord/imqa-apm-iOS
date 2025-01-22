//
//  UserModel.swift
//  IMQAMpmAgent
//
//  Created by Theodore Cha on 29/09/2018.
//  Copyright © 2018 Theodore Cha. All rights reserved.
//

import Foundation


public struct UserSemantics {
    public static let userProfileUserDefaultKey: String = Bundle.appIdentifier + ".userdefault"
}

public struct UserModel{
    
    public static var id: String? {
        UserDefaults(suiteName: UserSemantics.userProfileUserDefaultKey)?.string(forKey: "id")
    }
    
    public static var name: String? {
        UserDefaults(suiteName: UserSemantics.userProfileUserDefaultKey)?.string(forKey: "name")
    }
    
    public static var email: String? {
        UserDefaults(suiteName: UserSemantics.userProfileUserDefaultKey)?.string(forKey: "email")
    }
    
    public static func setUserId(_ id: String?) {
        UserDefaults(suiteName: UserSemantics.userProfileUserDefaultKey)?.set(id, forKey: "id")
    }
    
    public static func setUserName(_ name: String?) {
        UserDefaults(suiteName: UserSemantics.userProfileUserDefaultKey)?.set(name, forKey: "name")
    }
    
    public static func setUserEmail(_ email: String?) {
        UserDefaults(suiteName: UserSemantics.userProfileUserDefaultKey)?.set(email, forKey: "email")
    }
    
}

public struct AreaCodeModel{
    static var areaCode: String? {
        UserDefaults(suiteName: UserSemantics.userProfileUserDefaultKey)?.string(forKey: "areaCode")
    }
    
    public static func setAreaCode(_ areaCode: String?) {
        UserDefaults(suiteName: UserSemantics.userProfileUserDefaultKey)?.set(areaCode, forKey: "areaCode")
    }
}
