//
//  UNUserNotificationCenterDelegateProxy.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/7.
//

import UserNotifications

class UNUserNotificationCenterDelegateProxy: NSObject {
    weak var originalDelegate: UNUserNotificationCenterDelegate?
    let captureData: Bool

    init(captureData: Bool) {
        self.captureData = captureData
    }
}

extension UNUserNotificationCenterDelegateProxy: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {

        // generate span event
        if let event = try? PushNotificationEvent(notification: notification, captureData: captureData) {
            IMQA.client?.add(event: event)
        }

        // call original
        if #available(iOS 14.0, tvOS 14.0, *) {
            originalDelegate?.userNotificationCenter?(
                center,
                willPresent: notification,
                withCompletionHandler: completionHandler
            )
                ?? completionHandler(.list)
        } else {
            originalDelegate?.userNotificationCenter?(
                center,
                willPresent: notification,
                withCompletionHandler: completionHandler
            )
                ?? completionHandler(.alert)
        }
    }
#if !os(tvOS)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {

        // generate span event
        if let event = try? PushNotificationEvent(notification: response.notification, captureData: captureData) {
            IMQA.client?.add(event: event)
        }

        // call original
        originalDelegate?.userNotificationCenter?(
            center,
            didReceive: response,
            withCompletionHandler: completionHandler
        )
            ?? completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        openSettingsFor notification: UNNotification?
    ) {
        // call original
        originalDelegate?.userNotificationCenter?(center, openSettingsFor: notification)
    }
#endif
}
