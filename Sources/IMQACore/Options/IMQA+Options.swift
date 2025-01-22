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
        public var sampleRate: Double = 1.0
        
        public init(
            serviceKey: String,
            endpoints: IMQA.Endpoints? = nil,
            sampleRate: Double = 1.0
        ){
            self.serviceKey = serviceKey
            self.endpoints = endpoints
            self.services = .basic
            self.sampleRate = sampleRate
            self.crashReporter = IMQACrashReporter()
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
