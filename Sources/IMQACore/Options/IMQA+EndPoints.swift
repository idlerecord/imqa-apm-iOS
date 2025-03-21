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
        
        @objc public init(collectorURL: String) {
            self.baseURL = collectorURL
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
