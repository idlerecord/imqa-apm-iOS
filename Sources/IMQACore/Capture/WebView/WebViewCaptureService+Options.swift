//
//  WebViewCaptureService+Options.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/7.
//

#if canImport(WebKit)
import Foundation

extension WebViewCaptureService {
    /// Class used to setup a WebViewCaptureService.
    @objc(IMQAWebViewCaptureServiceOptions)
    public final class Options: NSObject {
        /// Defines wether or not the Embrace SDK should remove the query params when capturing URLs from a web view.
        @objc public let stripQueryParams: Bool

        @objc public init(stripQueryParams: Bool) {
            self.stripQueryParams = stripQueryParams
        }

        @objc public convenience override init() {
            self.init(stripQueryParams: false)
        }
    }
}
#endif
