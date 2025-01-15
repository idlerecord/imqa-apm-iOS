//
//  PushNotificationCaptureService+Options.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/7.
//

import Foundation

extension PushNotificationCaptureService {
    /// Class used to setup a WebViewCaptureService.
    @objc(IMQAPushNotificationCaptureServiceOptions)
    public final class Options: NSObject {
        /// Defines wether or not the IMQA SDK should capture the data from the push notifications
        @objc public let captureData: Bool

        @objc public init(captureData: Bool) {
            self.captureData = captureData
        }

        @objc public convenience override init() {
            self.init(captureData: false)
        }
    }
}
