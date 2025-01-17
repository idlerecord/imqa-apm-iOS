//
//  IMQAViewControllerCustomization.swift
//  Imqa-sdk-ios
//
//  Created by Hunta Park on 12/13/24.
//
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif
/// Implement this protocol on your ViewControllers to customize certain aspects of how  IMQA logs you ViewControllers.
public protocol IMQAViewControllerCustomization {

    /// Optional.
    ///  IMQA uses the `title` property of your ViewController by default.
    /// Implement this property in your ViewController if you'd like  IMQA to log the ViewController under a different name without modifying the `title` property.
    var nameForViewControllerInIMQA: String? { get }

    /// Optional.
    /// By default,  IMQA will capture a Span to represent every view controller that appears
    /// Implement this var and set it to return `false` if you'd like  IMQA to skip logging this view.
    var shouldCaptureViewInIMQA: Bool { get }
}
#if canImport(UIKit) && !os(watchOS)
/// Default implementation for ` IMQAViewControllerCustomization` methods that are intended to be optional.
public extension IMQAViewControllerCustomization where Self: UIViewController {
    var nameForViewControllerInIMQA: String? { nil } /// Will default to class name
    var shouldCaptureViewInIMQA: Bool { true }
}
#endif

