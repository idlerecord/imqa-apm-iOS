//
//  IMQA+EndPoints.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//

import Foundation

extension IMQA{
    @objc(IMQAEndpoits)
    public class Endpoints: NSObject {

        /// The base URL to upload session data
        @objc public let baseURL: String

        /// The base URL to upload session data while a debugger is attached
        @objc public let developmentBaseURL: String

        @objc public init(baseURL: String, developmentBaseURL: String) {
            self.baseURL = baseURL
            self.developmentBaseURL = developmentBaseURL
        }
        
        public enum OpentelemetryBaseUrl{
            case tracer(String)
            case metric(String)
            case logs(String)
            
            func baseUrl() -> String {
                switch self {
                case .tracer(let url):
                    return url + "/v1/traces"
                case .metric(let url):
                    return url + "/v1/metrics"
                case .logs(let url):
                    return url + "/v1/logs"
                }
            }
        }
    }
}
