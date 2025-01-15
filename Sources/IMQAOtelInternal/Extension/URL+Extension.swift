//
//  URL+Extension.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/1.
//

import Foundation

public extension URL {
    static func endpoint(basePath: String, apiPath: String) -> URL? {
        var components = URLComponents(string: basePath)
        components?.path.append(apiPath)
        return components?.url
    }

    static func spansEndpoint(basePath: String) -> URL? {
        return endpoint(basePath: basePath, apiPath: "/v1/traces")
    }

    static func logsEndpoint(basePath: String) -> URL? {
        return endpoint(basePath: basePath, apiPath: "/v1/logs")
    }
}
