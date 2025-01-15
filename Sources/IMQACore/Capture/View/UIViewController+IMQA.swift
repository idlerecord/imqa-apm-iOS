//
//  UIViewController+IMQA.swift
//  Imqa-sdk-ios
//
//  Created by Hunta Park on 12/13/24.
//
import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController {
    private struct AssociatedKeys {
        static var imqaIdentifier: Int = 0
    }

    var imqa_identifier: String? {
        get {
            if let value = objc_getAssociatedObject(self, &AssociatedKeys.imqaIdentifier) as? NSString {
                return value as String
            }

            return nil
        }

        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.imqaIdentifier,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN)
        }
    }


    var imqa_viewName: String {
        var title: String?

        if let customized = self as? IMQAViewControllerCustomization {
            title = customized.nameForViewControllerInIMQA
        }

        return title ?? className
    }

    var imqa_shouldCaptureView: Bool {
        if let customized = self as? IMQAViewControllerCustomization {
            return customized.shouldCaptureViewInIMQA
        }

        return true
    }

    var className: String {
        return String(describing: type(of: self))
    }
}
#endif
