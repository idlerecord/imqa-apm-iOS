//
//  InteractableViewController.swift
//  Imqa-sdk-ios
//
//  Created by Hunta Park on 12/13/24.
//
import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit

public protocol InteractableViewController: UIViewController {

}

public extension InteractableViewController {
    /// Call this method in your `UIViewController` when it is ready to be interacted by the user.
    /// - Throws: `ViewCaptureService.noServiceFound` if no `ViewCaptureService` is active.
    /// - Throws: `ViewCaptureService.firstRenderInstrumentationDisabled` if this functionallity was not enabled when setting up the `ViewCaptureService`.
    func setInteractionReady() throws {
        try IMQA.client?.captureServices.onInteractionReady(for: self)
    }
}

#endif
