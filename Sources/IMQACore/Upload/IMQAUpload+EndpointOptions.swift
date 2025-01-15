//
//  IMQAUpload+EndpointOptions.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation

public extension IMQAUpload {
    class EndpointOptions {
        /// URL for the spans upload endpoint
        public let spansURL: URL

        /// URL for the logs upload endpoint
        public let logsURL: URL

        public init(spansURL: URL, logsURL: URL) {
            self.spansURL = spansURL
            self.logsURL = logsURL
        }
    }
}
