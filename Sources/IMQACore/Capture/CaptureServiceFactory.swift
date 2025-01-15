//
//  CaptureServiceFactory.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/4.
//
import IMQACaptureService

public enum CaptureServiceFactory { }

extension CaptureServiceFactory {

    static var requiredServices: [CaptureService] {
        return [
            
        ]
    }

    static func addRequiredServices(to services: [CaptureService]) -> [CaptureService] {
        return services + requiredServices
    }
}
