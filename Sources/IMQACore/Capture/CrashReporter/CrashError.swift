//
//  CrashError.swift
//  Imqa-sdk-ios
//
//  Created by Hunta Park on 1/2/25.
//
import OpenTelemetryApi
import OpenTelemetrySdk

struct IMQACrashError: SpanException {
    public var type: String
    
    public var message: String?
    
    public var stackTrace: [String]?
    
    public init(message: String, type: String, stackTrace: [String]?) {
        self.message = message
        self.type = type
        self.stackTrace = stackTrace
    }
}
