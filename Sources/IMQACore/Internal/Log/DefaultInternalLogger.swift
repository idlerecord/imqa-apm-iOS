//
//  DefaultInternalLogger.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/10/25.
//

import Foundation
import OpenTelemetryApi
import IMQAOtelInternal


class DefaultInternalLogger: InternalLogger {
#if DEBUG
    var level: LogLevel = .debug
#else
    var level: LogLevel = .error
#endif
    var otel: IMQAOpenTelemetry?
}

extension DefaultInternalLogger{
    @discardableResult
    func log(level: LogLevel, message: String, attributes: [String : String]) -> Bool {
        
        sendOTelLog(level: level, message: message, attributes: attributes)
        
        guard self.level != .none && self.level.rawValue <= level.rawValue else {
            return false
        }

        print(message)
        return true
    }
    
    private func sendOTelLog(level: LogLevel, message: String, attributes: [String: String]) {
#error("attributes의 로그타입을 통해서 type에 값을 설정해주세요 ")
        // send log
        otel?.log(
            message,
            severity: level.severity,
            type: .INTERNAL,
            attributes: attributes,
            stackTraceBehavior: .default
        )
    }
    
    
    @discardableResult
    func log(level: LogLevel, message: String) -> Bool {
        return log(level: level, message: message, attributes: [:])
    }
    
    @discardableResult
    func trace(_ message: String, attributes: [String : String]) -> Bool {
        return log(level: .trace, message: message, attributes: [:])
    }
    
    @discardableResult
    func trace(_ message: String) -> Bool {
        return log(level: .trace, message: message)
    }
    
    @discardableResult
    func debug(_ message: String, attributes: [String : String]) -> Bool {
        return log(level: .debug, message: message, attributes: [:])
    }
    
    @discardableResult
    func debug(_ message: String) -> Bool {
        return log(level: .debug, message: message)
    }
    
    @discardableResult
    func info(_ message: String, attributes: [String : String]) -> Bool {
        return log(level: .info, message: message, attributes: [:])
    }
    
    @discardableResult
    func info(_ message: String) -> Bool {
        return log(level: .info, message: message)
    }
    
    @discardableResult
    func warning(_ message: String, attributes: [String : String]) -> Bool {
        return log(level: .warning, message: message, attributes: [:])
    }
    
    @discardableResult
    func warning(_ message: String) -> Bool {
        return log(level: .warning, message: message)
    }
    
    @discardableResult
    func error(_ message: String, attributes: [String : String]) -> Bool {
        return log(level: .error, message: message, attributes: [:])
    }
    
    @discardableResult
    func error(_ message: String) -> Bool {
        return log(level: .error, message: message)
    }
}

extension DefaultInternalLogger{
    
    func traceLog(message: String, spanContext: SpanContext, logType: IMQALogType, attributes: [String : String]){
        var attributes:[String: String] = [:]
        if let userId = UserModel.id {
            attributes[SpanSemantics.Common.userId] = userId
        }
        if let areaCode = AreaCodeModel.areaCode {
            attributes[SpanSemantics.Common.areaCode] = areaCode
        }
        
        otel?.log(message,
                  severity: .error,
                  type: logType,
                  spanContext: spanContext,
                  timestamp: Date(),
                  attributes: attributes,
                  stackTraceBehavior: .notIncluded)
    }
}
