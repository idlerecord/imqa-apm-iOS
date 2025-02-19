//
//  CaptureService+Helpers.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/7.
//

import Foundation

@objc public extension CaptureService {
    /// Returns a `URLSessionCaptureService` with the given `URLSessionCaptureService.Options`.
    /// - Parameter options: `URLSessionCaptureService.Options` used to configure the service.
    static func urlSession(
        options: URLSessionCaptureService.Options = URLSessionCaptureService.Options()
    ) -> URLSessionCaptureService {
        return URLSessionCaptureService(options: options)
    }

#if canImport(UIKit) && !os(watchOS)
    /// Returns a `TapCaptureService` with the given `TapCaptureService.Options`.
    /// - Parameter options: `TapCaptureService.Options` used to configure the service.
    static func tap(
        options: TapCaptureService.Options = TapCaptureService.Options()
    ) -> TapCaptureService {
        return TapCaptureService(options: options)
    }

    /// Returns a `ViewCaptureService`.
    static func view() -> ViewCaptureService {
        return ViewCaptureService()
    }
#endif

#if canImport(WebKit)
    /// Returns a `WebViewCaptureService` with the given `WebViewCaptureService.Options`.
    /// - Parameter options: `WebViewCaptureService.Options` used to configure the service.
    static func webView(
        options: WebViewCaptureService.Options = WebViewCaptureService.Options()
    ) -> WebViewCaptureService {
        return WebViewCaptureService(options: options)
    }
#endif

//    static func anr() -> ANRCaptureService {
//        return ANRCaptureService()
//    }
   
    /// Adds a `LowMemoryWarningCaptureService`.
    static func lowMemoryWarning() -> LowMemoryWarningCaptureService {
        return LowMemoryWarningCaptureService()
    }

    /// Adds a `LowPowerModeCaptureService`.
    static func lowPowerMode() -> LowPowerModeCaptureService {
        return LowPowerModeCaptureService()
    }

    /// Adds a `PushNotificationCaptureService` with the given `PushNotificationCaptureService.Options`.
    /// - Parameter options: `PushNotificationCaptureService.Options` used to configure the service.
    static func pushNotification(
        options: PushNotificationCaptureService.Options = PushNotificationCaptureService.Options()
    ) -> PushNotificationCaptureService {
        return PushNotificationCaptureService(options: options)
    }
    
    
}
