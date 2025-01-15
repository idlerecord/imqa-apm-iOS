//
//  IMQASpanType.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/9/25.
//

public enum IMQASpanType: String, Decodable {
    case SESSION = "session"
    case RENDER = "render"
    case XHR = "xhr"
    case EVENT = "event"
    case CRASH = "crash"
    case LOG = "log"
    case APPLIFECYCLE = "app_lifecycle"
    case DEFAULT = "default"
}

