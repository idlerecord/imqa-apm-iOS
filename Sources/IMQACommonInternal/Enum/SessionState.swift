//
//  SessionState.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//

import Foundation

public enum SessionState: String {
    case foreground = "foreground"
    case background = "background"
}

#if canImport(UIKit) && !os(watchOS)
import UIKit

public extension SessionState {
    init?(appState: UIApplication.State) {
        if appState == .background {
            self = .background
        } else {
            self = .foreground
        }
    }
}
#endif
