//
//  TapCaptureServiceDelegate.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/7.
//
import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

/// Delegate used to control which taps are allowed to be captured by a `TapCaptureService`.
@objc(IMQATapCaptureServiceDelegate)
public protocol TapCaptureServiceDelegate: NSObjectProtocol {
#if canImport(UIKit) && !os(watchOS)
     func shouldCaptureTap(onView: UIView) -> Bool
     func shouldCaptureTapCoordinates(onView: UIView) -> Bool
#endif
}

