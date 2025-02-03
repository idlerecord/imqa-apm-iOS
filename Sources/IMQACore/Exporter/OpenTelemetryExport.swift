

//
//  Ex.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//


import OpenTelemetrySdk
import Foundation

public class OpenTelemetryExport: NSObject{
    internal let spanExporter: SpanExporter?
    internal let logExporter: LogRecordExporter?
    
    internal init(spanExporter: SpanExporter? = nil, logExporter: LogRecordExporter? = nil) {
        self.spanExporter = spanExporter
        self.logExporter = logExporter
    }
    
}
