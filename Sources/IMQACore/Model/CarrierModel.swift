//
//  File.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/22.
//

import Foundation
import CoreTelephony

struct CarrierModel{
    static var carrierName: String = ""

    static func getCarrierInfo() {
        if #available(iOS 12.0, *) {
            let networkInfo = CTTelephonyNetworkInfo()
            if let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value {
                self.carrierName = carrier.carrierName ?? ""
            }
        } else {
            if let carrier = CTTelephonyNetworkInfo().subscriberCellularProvider{
                self.carrierName = carrier.carrierName ?? ""
            }
        }
    }
}
