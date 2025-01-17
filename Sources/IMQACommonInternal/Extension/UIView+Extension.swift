//
//  UIView+Extension.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/9/25.
//
#if canImport(UIKit) && !os(watchOS)
import UIKit

public extension UIViewController {
    static var currentVCLatestClickTraceId: String?
}

public extension UIView {
    func findTitle() -> String? {
        if let label = self as? UILabel, let text = label.text {
            return text
        }
        if let button = self as? UIButton, let title = button.title(for: .normal) {
            return title
        }
        for subview in subviews {
            if let title = subview.findTitle() {
                return title
            }
        }
        return nil
    }
}

#endif
