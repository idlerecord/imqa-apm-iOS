//
//  StackTraceBehavior.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/9/25.
//


import Foundation

/// Describes the behavior for automatically capturing stack traces.
public enum StackTraceBehavior: Int {
    /// Stack traces are not automatically captured.
    case notIncluded

    /// The default behavior for automatically capturing stack traces.
    case `default`
}

