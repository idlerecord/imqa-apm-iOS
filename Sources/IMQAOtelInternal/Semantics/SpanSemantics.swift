//
//  SpanSemantics.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/9/25.
//

public struct SpanSemantics{
    /// span의 유형
    public static let spanType: String = "span.type"
    
    public struct Event {
        public static let eventType = "event_type"
        public static let targetElement = "target_element"
        public static let targetElementText = "target_element_text"
        public static let tapCoords = "tap.coords"
    }
    
    public enum EventValue: String{
         case eventClick = "click"
         case eventScroll = "scroll"
    }

    public struct XHR {
        static let httpRequestHeaders = "http.request.headers"
        static let httpRequestBody = "http.request.body"
        static let errorType = "error.type"
    }

    public struct Session {
        public static let name = "session"
        public static let keyId = "session.id"
        public static let keyState = "imqa.state"
        public static let keyColdStart = "imqa.cold_start"
        public static let keyTerminated = "imqa.terminated"
        public static let keyCleanExit = "imqa.clean_exit"
        public static let keySessionNumber = "imqa.session_number"
        public static let keyHeartbeat = "imqa.heartbeat_time_unix_nano"
        public static let keyCrashId = "imqa.crash_id"
    }

    public struct Common {
        /// span에 공동으로 들러가는 session id
        public static let sessionId = "session.id"
        ///파블릭 아이피
        public static let sourceAddress = "source.address"
        /// 화면의 class이름
        public static let screenName = "screen.name"
        /// 화면의 타입
        public static let screenType = "screen.type"
        /// 사용자의 id
        public static let userId = "user.id"
        /// 통신사의 이름
        public static let networkCarrierName = "network.carrier.name"
        /// 네트워크 연결유형,통신 방식
        public static let networkConnectionSubtype = "network.connection.subtype"
        /// 남은 베터리 퍼센트수
        public static let deviceBatteryLevel = "device.battery.level"
        /// 충전중 여부
        public static let deviceBatteryIsCharging = "device.battery.charging"
        /// cpu사용율
        public static let deviceCpuUsage = "app.cpu.usage"
        /// 전체 메모리 용량
        public static let deviceMemoryTotal = "device.memory.total"
        /// 남은 메모리 용량
        public static let deviceMemoryFree = "device.memory.free"
        /// app이 사용하는 메모리양
        public static let appMemoryAllocated = "app.memory.allocated"
        /// 영역 code
        public static let areaCode = "area.code"
        /// 사용 가능한 네트워크 여부
        public static let networkAvailable = "network.available"
        /// 인터넷 사용할수 있을시 Cellular(모바일 data)를 연결 여부
        public static let networkCellular = "network.cellular"
        /// 인터넷 사용할수 있을시 wifi를 연결 여부
        public static let networkWifi = "network.wifi"
        
    }
    
    public struct CommonValue{
        public static var noScreenValue:String = "NoScreen"
        public static var viewValue:String = "view"
    }

    public struct SessionValue{
        public static var name:String = "Session"
    }

    public struct Applifecycle{
        /// app 의 lifecycle 상태 foreground background
        public static let appLifecycle = "device.app.lifecycle"
    }
    
}
