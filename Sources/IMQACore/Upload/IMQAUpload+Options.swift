//
//  IMQAUpload+Options.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation

public extension IMQAUpload {
    /// Class used to configure a IMQAUpload instance
    class Options {

        public let endpoints: EndpointOptions

        public let cache: CacheOptions

        public let metadata: MetadataOptions

        public let redundancy: RedundancyOptions

        public let urlSessionConfiguration: URLSessionConfiguration

        public init(
            endpoints: EndpointOptions,
            cache: CacheOptions,
            metadata: MetadataOptions,
            redundancy: RedundancyOptions = RedundancyOptions(),
            urlSessionConfiguration: URLSessionConfiguration? = nil
        ) {
            self.endpoints = endpoints
            self.cache = cache
            self.metadata = metadata
            self.redundancy = redundancy
            self.urlSessionConfiguration = urlSessionConfiguration ?? Options.defaultUrlSessionConfiguration()
        }

        private class func defaultUrlSessionConfiguration() -> URLSessionConfiguration {
            let config = URLSessionConfiguration.default
            config.urlCache = URLCache(
                memoryCapacity: (4*1024*1024), // 4 MB Memory Cache
                diskCapacity: (20*1024*1024), // 20 MB Disk Cache
                diskPath: "imqa"
            )
            config.httpShouldUsePipelining = true
            config.waitsForConnectivity = true
            return config
        }
    }
}
