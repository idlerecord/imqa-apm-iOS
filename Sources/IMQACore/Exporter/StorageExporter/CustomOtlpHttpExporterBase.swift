//
//  CustomOtlpHttpExporterBase.swift
//  IMQAIO
//
//  Created by Hunta Park on 2/3/25.
//

#if canImport(Compression)
import DataCompression
#endif
import Foundation
import SwiftProtobuf
import OpenTelemetryProtocolExporterCommon
import OpenTelemetryProtocolExporterHttp
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class CustomOtlpHttpExporterBase {
    let endpoint: URL
    let envVarHeaders : [(String,String)]?
    let config : OtlpConfiguration

  public init(
    endpoint: URL,
    config: OtlpConfiguration = OtlpConfiguration(),
    useSession: URLSession? = nil,
    envVarHeaders: [(String,String)]? = EnvVarHeaders.attributes
  ) {
      self.envVarHeaders = envVarHeaders
      self.endpoint = endpoint
      self.config = config
  }
  
    public func createRequest(body: Message, endpoint: URL) -> URLRequest {
        var request = URLRequest(url: endpoint)
        
        do {
            let rawData = try body.serializedData()
            request.httpMethod = "POST"
            request.setValue(Headers.getUserAgentHeader(), forHTTPHeaderField: Constants.HTTP.userAgent)
            request.setValue("application/x-protobuf", forHTTPHeaderField: "Content-Type")
            
            var compressedData = rawData
            
#if canImport(Compression)
            switch config.compression {
            case .gzip:
                if let data = rawData.gzip() {
                    compressedData = data
                    request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
                }
                
            case .deflate:
                if let data = rawData.deflate() {
                    compressedData = data
                    request.setValue("deflate", forHTTPHeaderField: "Content-Encoding")
                }
                
            case .none:
                break
            }
#endif
            // Apply final data. Could be compressed or raw
            // but it doesn't matter here
            request.httpBody = compressedData
        } catch {
            print("Error serializing body: \(error)")
        }
        
        return request
    }
  
  public func shutdown(explicitTimeout: TimeInterval? = nil) {
    
  }
}
