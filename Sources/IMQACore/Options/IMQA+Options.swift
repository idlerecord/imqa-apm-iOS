//
//  IMQA+Options.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//
import Foundation
import IMQACaptureService

extension IMQA {
    /// Class used to setup the IMQA SDK.
    public final class Options: NSObject {
        public let serviceKey: String
        public let endpoints: IMQA.Endpoints?
        public let services: [CaptureService]
        public let crashReporter: CrashReporter?
        
        public init(
            serviceKey: String,
            endpoints: IMQA.Endpoints? = nil
//            config: IMQAConfigurable = DefaultConfig()
        ){
            self.serviceKey = serviceKey
//            self.appGroupId = nil
//            self.platform = .default
            self.endpoints = endpoints
            self.services = .basic
            self.crashReporter = IMQACrashReporter()
//            self.logLevel = .default
//            self.export = nil
//            self.runtimeConfiguration = config
        }

    }
}

public extension Array where Element == CaptureService {
    static var all: [CaptureService] {
        return CaptureServiceBuilder()
            .addAll()
            .build()
    }
    
    static var basic: [CaptureService] {
        return CaptureServiceBuilder()
            .addBasicServices()
            .build()
    }
}
