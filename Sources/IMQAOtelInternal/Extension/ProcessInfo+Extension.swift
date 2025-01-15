//
//  ProcessInfo+Extension.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/14/25.
//

import Foundation
public extension ProcessInfo{
    var isSwiftUIPreview: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
