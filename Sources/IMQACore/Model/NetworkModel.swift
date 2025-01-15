//
//  NetworkModel.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/23.
//

struct NetworkModel {
    static var isReachable: Bool {
        return NetworkInfoManager.sharedInstance.isReachable
    }
    
    static var isWifi: Bool {
        return NetworkInfoManager.sharedInstance.isWifi
    }
    
    static var isCellular: Bool {
        return NetworkInfoManager.sharedInstance.isCellular
    }
    
    static var localIpAddress: String {
        return NetworkInfoManager.sharedInstance.localIpAddress
    }
    
}
