

//
//  Ex.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//


import OpenTelemetrySdk
import Foundation

public class OpenTelemetryExporter: NSObject{
    public let spanExporter: SpanExporter?
    public let logExporter: LogRecordExporter?
    
    public init(spanExporter: SpanExporter? = nil, logExporter: LogRecordExporter? = nil) {
        self.spanExporter = spanExporter
        self.logExporter = logExporter
    }
    
}
