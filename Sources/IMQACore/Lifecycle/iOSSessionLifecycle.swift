//
//  iOSSessionLifecycle.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//



import Foundation
import IMQACommonInternal
import IMQAOtelInternal
import OpenTelemetryApi
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

public struct AppStatusSemantics{
    static let lifeCycle: String = "device.app.lifecycle"
}

// ignoring linting rule to have a lowercase letter first on the class name
// since we want to use 'iOS'...

// swiftlint:disable type_name
public final class iOSSessionLifecycle: SessionLifecycle {
// swiftlint:enable type_name

    weak var controller: SessionControllable?
    var currentState: SessionState = .background

    init(controller: SessionControllable) {
        self.controller = controller
        listenForUIApplication()
    }

    func setup() {
        // only fetch the app state once during setup
        // MUST BE DONE ON THE MAIN THREAD!!!
        guard Thread.isMainThread else {
            return
        }
#if canImport(UIKit) && !os(watchOS)
        let appState = UIApplication.shared.applicationState
        currentState = appState == .background ? .background : .foreground
#endif
    }

    func start() {
        startSession()
    }

    func startSession() {
        controller?.startSession(state: currentState)
    }

    func endSession() {
        // there's always an active session!
        // starting a new session will end the current one (if any)
        controller?.startSession(state: currentState)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension iOSSessionLifecycle {

    private func listenForUIApplication() {
#if canImport(UIKit) && !os(watchOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
#endif
    }

    /// Application state is now in foreground
    @objc func appDidBecomeActive() {
        
        currentState = .foreground
        guard let controller = controller else {
            return
        }
        let currentVC = IMQAScreen.name ?? SpanSemantics.CommonValue.noScreenValue
        let name = "\(currentVC)[\(SessionState.foreground.rawValue)]"
        let span = SpanUtils.span(name: name,
                                  startTime: Date(),
                                  type: IMQASpanType.APPLIFECYCLE,
                                  attributes: [AppStatusSemantics.lifeCycle: AttributeValue(SessionState.foreground.rawValue)])
        span.end()
        
        IMQA.logger.traceLog(message: name,
                             spanContext: span.context,
                             logType: IMQALogType.APPLIFECYCLE,
                             attributes: [:])
        
    }

    /// Application state is now in the background
    @objc func appDidEnterBackground() {
        
        currentState = .background
        guard let controller = controller else {
            return
        }
        let currentVC = IMQAScreen.name ?? SpanSemantics.CommonValue.noScreenValue
        let name = "\(currentVC)[\(SessionState.background.rawValue)]"
        let span = SpanUtils.span(name: name,
                                  startTime: Date(),
                                  type: IMQASpanType.APPLIFECYCLE,
                                  attributes: [AppStatusSemantics.lifeCycle: AttributeValue(SessionState.background.rawValue)])
        span.end()
        IMQA.logger.traceLog(message: name,
                             spanContext: span.context,
                             logType: .APPLIFECYCLE,
                             attributes: [:])
    }

    /// User has terminated the app. This will not end the current session as the app
    /// will continue to run until the system kills it.
    /// This session will not be marked as a "clean exit".
    @objc func appWillTerminate() {
        controller?.update(appTerminated: true)
    }
}
