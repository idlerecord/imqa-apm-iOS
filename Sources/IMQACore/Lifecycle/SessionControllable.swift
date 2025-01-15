//
//  SessionControllable.swift
//  imqa-apm-iOS
//
//  Created by Hunta Park on 1/13/25.
//

import Foundation
import IMQACommonInternal
import IMQAOtelInternal

protocol SessionControllable: AnyObject {

    var currentSession: SessionRecord? { get }

    @discardableResult
    func startSession(state: SessionState) -> SessionRecord?

    @discardableResult
    func endSession() -> Date

    func update(state: SessionState)
    func update(appTerminated: Bool)
}
