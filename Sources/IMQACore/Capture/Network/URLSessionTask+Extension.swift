//
//  URLSessionTask+Extension.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/5.
//

import Foundation

extension URLSessionTask {
    private struct AssociatedKeys {
        static var imqaCaptured: UInt8 = 0
        static var imqaData: UInt8 = 1
        static var imqaStartTime: UInt8 = 2
        static var imqaEndTime: UInt8 = 3
    }

    var imqaCaptured: Bool {
        get {
            if let value = objc_getAssociatedObject(self, &AssociatedKeys.imqaCaptured) as? NSNumber {
                return value.boolValue
            }

            return false
        }

        set {
            let value: NSNumber = NSNumber(booleanLiteral: newValue)
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.imqaCaptured,
                                     value,
                                     .OBJC_ASSOCIATION_RETAIN)
        }
    }

    var imqaData: Data? {
        get {
            return objc_getAssociatedObject(self,
                                            &AssociatedKeys.imqaData) as? Data
        }
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.imqaData,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN)
        }
    }

    var imqaStartTime: Date? {
        get {
            return objc_getAssociatedObject(self,
                                            &AssociatedKeys.imqaStartTime) as? Date
        }
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.imqaStartTime,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN)
        }
    }

    var imqaEndTime: Date? {
        get {
            return objc_getAssociatedObject(self,
                                            &AssociatedKeys.imqaEndTime) as? Date
        }
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.imqaEndTime,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN)
        }
    }
}
