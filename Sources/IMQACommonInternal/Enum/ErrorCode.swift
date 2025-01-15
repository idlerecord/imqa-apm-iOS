//
//  ErrorCode.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/9/25.
//

public enum ErrorCode: String {
    /// Span ended in an expected, but less than optimal state
    case failure

    /// Span ended because user reverted intent
    case userAbandon

    /// Span ended in some other way
    case unknown
}
