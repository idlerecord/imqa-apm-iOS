//
//  CrashReporterContext.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/4.
//

import Foundation

/// Object passed to the active crash reporter during setup
@objc public final class CrashReporterContext: NSObject {

    public let appId: String?
    public let sdkVersion: String
    public let filePathProvider: FilePathProvider
    public let notificationCenter: NotificationCenter

    public init(
        appId: String?,
        sdkVersion: String,
        filePathProvider: FilePathProvider,
        notificationCenter: NotificationCenter
    ) {
        self.appId = appId
        self.sdkVersion = sdkVersion
        self.filePathProvider = filePathProvider
        self.notificationCenter = notificationCenter
    }
}
