//
//  URLRequest+Extension.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/5.
//

import Foundation

extension URLRequest {
    private enum Header {
        static let id = "x-imqa-id"
        static let startTime = "x-imqa-st"
    }

    func addIMQAHeaders() -> URLRequest {
        var mutableRequest = self
        mutableRequest.setValue(UUID().uuidString,
                                forHTTPHeaderField: Header.id)
        mutableRequest.setValue(Date().serializedInterval.description,
                                forHTTPHeaderField: Header.startTime)
        return mutableRequest
    }
}
