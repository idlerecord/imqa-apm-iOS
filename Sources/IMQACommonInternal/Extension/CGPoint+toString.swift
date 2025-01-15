//
//  CGPoint+toString.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/7.
//

import Foundation

extension CGPoint {
    public func toString() -> String {
        "\(Int(trunc(x))),\(Int(trunc(y)))"
    }
}
