//
//  NetworkPayloadCaptureHandler.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/5.
//

import Foundation
import IMQAOtelInternal
import IMQACommonInternal

public extension Notification.Name {
    static let imqaConfigUpdated = Notification.Name("imqaConfigUpdated")
}

class NetworkPayloadCaptureHandler {

    @ThreadSafe
    var active = false

    @ThreadSafe
    var rules: [URLSessionTaskCaptureRule] = []

    @ThreadSafe
    var rulesTriggeredMap: [String: Bool] = [:]

    @ThreadSafe
    var currentSessionId: SessionIdentifier?

    private var otel: IMQAOpenTelemetry?

    init(otel: IMQAOpenTelemetry?) {
        self.otel = otel

        IMQA.notificationCenter.addObserver(
            self,
            selector: #selector(onConfigUpdated),
            name: .imqaConfigUpdated, object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSessionStart),
            name: Notification.Name.imqaSessionDidStart,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSessionEnd),
            name: Notification.Name.imqaSessionWillEnd,
            object: nil
        )

//        updateRules(IMQA.client?.config?.networkPayloadCaptureRules)

        // check if a session is already started
        if let sessionId = IMQA.client?.currentSessionId() {
            active = true
            currentSessionId = SessionIdentifier(string: sessionId)
        }
    }

    deinit {
        IMQA.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    func updateRules(_ rules: [NetworkPayloadCaptureRule]?) {
        guard let rules = rules else {
            return
        }

        self.rules = rules.map { URLSessionTaskCaptureRule(rule: $0) }
    }

    @objc private func onConfigUpdated(_ notification: Notification) {
//        let config = notification.object as? IMQAConfig
//        updateRules(config?.networkPayloadCaptureRules)
    }

    @objc func onSessionStart(_ notification: Notification) {
        active = true
        rulesTriggeredMap.removeAll()

        currentSessionId = (notification.object as? SessionRecord)?.id
    }

    @objc func onSessionEnd() {
        active = false
        currentSessionId = nil
    }

    public func process(
        request: URLRequest?,
        response: URLResponse?,
        data: Data?,
        error: Error?,
        startTime: Date?,
        endTime: Date?
    ) {

        guard active else {
            return
        }

        for rule in rules {
            // check if rule was already triggered
            guard rulesTriggeredMap[rule.id] == nil else {
                continue
            }

            // check if rule applies for this task
            guard rule.shouldTriggerFor(request: request, response: response, error: error) else {
                continue
            }

            // generate payload
            guard let payload = EncryptedNetworkPayload(
                request: request,
                response: response,
                data: data,
                error: error,
                startTime: startTime,
                endTime: endTime,
                matchedUrl: rule.urlRegex,
                sessionId: currentSessionId
            ) else {
                IMQA.logger.debug("Couldn't generate payload for task \(rule.urlRegex)!")
                return
            }

            // encrypt payload
            guard let result = payload.encrypted(withKey: rule.publicKey) else {
                IMQA.logger.debug("Couldn't encrypt payload for task \(rule.urlRegex)!")
                return
            }

            // generate otel log
            otel?.log(
                "",
                severity: .info,
                type: IMQALogType.XHR,
                attributes: [:
//                    LogSemantics.NetworkCapture.keyUrl: payload.url,
//                    LogSemantics.NetworkCapture.keyEncryptionMechanism: result.mechanism,
//                    LogSemantics.NetworkCapture.keyEncryptedPayload: result.payload,
//                    LogSemantics.NetworkCapture.keyPayloadAlgorithm: result.payloadAlgorithm,
//                    LogSemantics.NetworkCapture.keyEncryptedKey: result.key,
//                    LogSemantics.NetworkCapture.keyKeyAlgorithm: result.keyAlgorithm,
//                    LogSemantics.NetworkCapture.keyAesIv: result.iv
                ],
                stackTraceBehavior: .default
            )

            // flag rule as triggered
            rulesTriggeredMap[rule.id] = true
        }
    }
}
