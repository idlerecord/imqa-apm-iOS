//
//  SessionLifecycle.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import ResourceExtension
import IMQACommonInternal

protocol SessionLifecycle {
    /// The underlying SessionController.
    /// It is recommended to use a weak reference when storing this property to prevent retain cycles
    var controller: SessionControllable? { get }

    /// Method called during ``IMQA.init``
    func setup()

    /// Method called during ``IMQA.start`` for initialization purposes
    func start()

    /// An explicit method to create a new session
    func startSession()

    /// Allow for an explicit
    func endSession()
    
    var currentState: SessionState { get set }
}
