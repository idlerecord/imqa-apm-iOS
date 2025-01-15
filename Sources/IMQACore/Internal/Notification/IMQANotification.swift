//
//  Notification.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//


import Foundation

public extension Notification.Name {
    static let imqaSessionDidStart = Notification.Name("imqa.session.did_start")
    static let imqaSessionWillEnd = Notification.Name("imqa.session.will_end")
}

