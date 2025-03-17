//
//  SessionController.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import IMQAOtelInternal
import IMQACommonInternal


class SessionController: SessionControllable{
    @ThreadSafe
    var currentSession: SessionRecord?
    
    @ThreadSafe
    var currentSessionSpan: Span?
                
    //session시작하는 시간
    var startSessionTime:Date?
    
    let sessionId: SessionIdentifier = IMQAOTel.sessionId
    
    weak var storage: IMQAStorage?
    weak var upload: IMQAUpload?
    let queue: DispatchQueue
    let heartbeat: SessionHeartbeat

    var firstSession = true
    
    // Lock used for session boundaries. Will be shared at both start/end of session
    private let lock = UnfairLock()
    
    internal var notificationCenter = NotificationCenter.default
    
    init(storage: IMQAStorage,
         upload: IMQAUpload?,
         heartbeatInterval: TimeInterval = SessionHeartbeat.defaultInterval) {
        self.storage = storage
        self.upload = upload
        
        let heartbeatQueue = DispatchQueue(label: "com.imqa.session_heartbeat")
        self.heartbeat = SessionHeartbeat(queue: heartbeatQueue, interval: heartbeatInterval)
        self.queue = DispatchQueue(label: "com.imqa.session_controller_upload")
        
        self.heartbeat.callback = { [weak self] in
            let heartbeat = Date()
            self?.currentSession?.lastHeartbeatTime = heartbeat
            SessionSpanUtils.setHeartbeat(span: self?.currentSessionSpan, heartbeat: heartbeat)
            self?.save()
        }
    }
    
    deinit {
        heartbeat.stop()
    }

    
    @discardableResult
    func startSession(state: SessionState) -> SessionRecord? {
        startSessionTime = Date()
        return startSession(state: state, startTime: startSessionTime!)
    }
    
    @discardableResult
    func startSession(state: SessionState, startTime: Date = Date()) -> SessionRecord? {
        // end current session first
        if currentSession != nil {
            endSession(endTime: Date())
        }
        
        // detect cold start
        let isColdStart = firstSession

        // we lock after end session to avoid a deadlock
        return lock.locked {
            // create session span
            let newId = sessionId
            let span = SessionSpanUtils.span(id: newId, startTime: startTime, state: state)
            currentSessionSpan = span
            
            // create session record
            let session = SessionRecord(
                id: newId,
                processId: ProcessIdentifier.current,
                state: state.rawValue,
                traceId: span.context.traceId.hexString,
                spanId: span.context.spanId.hexString,
                startTime: startTime
            )
            currentSession = session
            session.coldStart = isColdStart
            
            save()
            
            heartbeat.start()
            
            notificationCenter.post(name: .imqaSessionDidStart, object: session)
            firstSession = false
            
            return nil
        }
    }
    
    
    @discardableResult
    func endSession() -> Date {
        return lock.locked {
            heartbeat.stop()
            
            let now = Date()
            
            notificationCenter.post(name: .imqaSessionWillEnd, object: currentSession)
            currentSessionSpan?.end(time: now)
            currentSession?.endTime = now
            currentSession?.cleanExit = true
            
            save()
            uploadSession()
            
            currentSession = nil
            currentSessionSpan = nil
            return now
        }
    }
    
    @discardableResult
    func endSession(endTime: Date = Date()) -> Date {
        return lock.locked {
            heartbeat.stop()
            let now = endTime
            
            notificationCenter.post(name: .imqaSessionWillEnd, object: currentSession)
            currentSessionSpan?.end(time: now)
            currentSession?.endTime = now
            currentSession?.cleanExit = true
            
            save()
            uploadSession()
            
            currentSession = nil
            currentSessionSpan = nil
            return now
        }
    }
    
    func update(state: SessionState) {
        SessionSpanUtils.setState(span: currentSessionSpan, state: state)
        currentSession?.state = state.rawValue
        save()
    }
        
    func update(appTerminated: Bool) {
        SessionSpanUtils.setTerminated(span: currentSessionSpan, terminated: appTerminated)
        currentSession?.appTerminated = appTerminated
        save()
    }
    
    func uploadSession() {
        guard let storage = storage,
              let upload = upload,
              let session = currentSession else {
            return
        }
        
        queue.async {
            UnsentDataHandler.sendSession(session, storage: storage, upload: upload)
        }
    }
}

extension SessionController {
    private func save() {
        guard let storage = storage,
              let session = currentSession else {
            return
        }
        storage.upsertSession(session)
    }
    
    private func delete() {
        guard let storage = storage,
              let session = currentSession else {
            return
        }
        storage.delete(session: session)
        currentSession = nil
        currentSessionSpan = nil
    }
}
