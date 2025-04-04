//
//  File.swift
//  IMQA-iOS-P
//
//  Created by Hunta on 2024/10/15.
//

import Foundation
import IMQACommonInternal
import IMQAOtelInternal
import WebKit

@objcMembers
public class IMQA: NSObject {
    
    @objc public static var client: IMQA?
        
    static let logger: DefaultInternalLogger = DefaultInternalLogger()
    
    let storage: IMQAStorage
    
    let upload: IMQAUpload?

    let captureServices: CaptureServices
    
    static let notificationCenter: NotificationCenter = NotificationCenter()
    
    public private(set) var options:IMQA.Options
        
    private static let synchronizationQueue = DispatchQueue(
        label: "com.imqa.synchronization",
        qos: .utility
    )
    
    private let processingQueue = DispatchQueue(
        label: "com.imqa.processing",
        qos: .background,
        attributes: .concurrent
    )
    
    /*******************************************************Parameters*******************************************************************************/
    
    ///SDK가 시작되였는가
    @objc public private(set) var started: Bool
    
    /// Returns the `DeviceIdentifier` used by imqa for the current device.
    public private(set) var deviceId: DeviceIdentifier

    /// log level
    @objc public var logLevel: LogLevel = .error {
        didSet {
            IMQA.logger.level = logLevel
        }
    }
    var currentAppState:SessionState{
        return sessionLifecycle.currentState
    }
    
    let sessionController: SessionController
    let sessionLifecycle: SessionLifecycle
    let logController: LogControllable

    /*******************************************************Parameters*******************************************************************************/

    
    private init(options: IMQA.Options) throws{
        self.started = false
        self.options = options
        self.storage = IMQA.createStorage(options: options)
        self.deviceId = DeviceIdentifier.retrieve(from: storage)
        self.upload = IMQA.createUpload(options: options, deviceId: deviceId.hex)
        self.captureServices = try CaptureServices(options: options,
                                                   storage: storage,
                                                   upload: upload)
        self.sessionController = SessionController(storage: storage,
                                                   upload: upload)
        self.sessionLifecycle = IMQA.createSessionLifecycle(controller: sessionController)
        self.logController = LogController(storage: storage,
                                           upload: upload,
                                           sessionController: sessionController)
        super.init()
        
        IMQAOTel.setUp(option: options,
                       storage: storage,
                       cache: self.upload!.cache,
                       logController: logController) //꼭 실행해야함니다.
        IMQA.logger.otel = self
    }
}

extension IMQA{
    @discardableResult
    @objc public func start() throws -> IMQA{
        guard Thread.isMainThread else {
            throw IMQASetupError.invalidThread("IMQA must be started on the main thread")
        }
        sessionLifecycle.setup()
        
        IMQA.synchronizationQueue.sync {
            guard started == false else{
                IMQA.logger.warning("IMQA was already started!")
                return
            }
            started = true
            
            //lifecycle start
            sessionLifecycle.start()
            //tap view xhr crash 잡는 서비스 start
            captureServices.start()
            
            processingQueue.async {[weak self] in
                // fetch crash reports and link them to sessions
                // then upload them
                UnsentDataHandler.sendUnsentData(
                    storage: self?.storage,
                    upload: self?.upload,
                    otel: self,
                    logController: self?.logController,
                    currentSessionId: self?.sessionController.currentSession?.id,
                    crashReporter: self?.captureServices.crashReporter
                )
                
                // retry any remaining cached upload data
                self?.upload?.retryCachedData()
            }
        }
        return self
    }
    
    @discardableResult
    @objc public static func setup(options: IMQA.Options) throws -> IMQA {
        //network  status
        NetworkInfoManager.sharedInstance

        if !Thread.isMainThread {
            throw IMQASetupError.invalidThread("IMQA must be setup on the main thread")
        }

        if ProcessInfo.processInfo.isSwiftUIPreview {
            throw IMQASetupError.initializationNotAllowed("IMQA cannot be initialized on SwiftUI Previews")
        }
        
        return try IMQA.synchronizationQueue.sync{
            if let client = client {
                IMQA.logger.debug("IMQA was already initialized!")
                return client
            }

            client = try IMQA(options: options)

            if let client = client {
                IMQA.logger.debug("IMQA setUp completed successfully")
                return client
            } else {
                throw IMQASetupError.unableToInitialize("Unable to initialize IMQA.client")
            }
        }
    }
}

public extension IMQA {
    
    /// UserId 저장
    /// - Parameter id: id
    static func setUserId(id: String?) {
        UserModel.setUserId(id)
        IMQAOTel.setUpCommonSpanAttributeValues()
    }
    
    /// UserId 회득
    /// - Returns: id
    static func getUserId() -> String? {
        return UserModel.id
    }
    
    /// customlog직는 방법
    /// - Parameters:
    ///   - level: 레별
    ///   - message: 찍으려는 로그메세지
    static func customLog(level: LogLevel, message: String){
        IMQA.logger.log(level: level, message: message, attributes: [:])
    }
    
    
    /// session공용
    /// - Parameter session:
    static func setSharedSession(session: Bool){
        IMQAOTel.isSharedSession = session
    }
    
    
    /// webview를 띄울때 꼭 호출해야 하는 함수
    /// - Parameter configuration: configuration
    static func setWebviewConfiguration(userContentController: WKUserContentController){
        let sessionScriptString = "window.__imqa_session_id = '\(IMQAOTel.sessionId.toString)';"
        let userScript = WKUserScript(
            source: sessionScriptString,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(userScript)

        
        let serviceNameScriptString = "window.__imqa_service_name = '\(Bundle.appIdentifier)';"
        let serviceNameScript = WKUserScript(
            source: serviceNameScriptString,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(serviceNameScript)
                
        //
        let serviceVersionScriptString = "window.__imqa_service_version = '\(Bundle.appVersion)';"
        let serviceVersionScript = WKUserScript(
            source: serviceVersionScriptString,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(serviceVersionScript)
        
        
        //imqaSharedSession
        var imqaSharedSessionScriptString = ""
        if IMQAOTel.isSharedSession {
            imqaSharedSessionScriptString = "window.__imqa_shared_session = true;"
        }else{
            imqaSharedSessionScriptString = "window.__imqa_shared_session = false;"
        }
        
        let imqaSharedSessionScript = WKUserScript(
            source: imqaSharedSessionScriptString,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(imqaSharedSessionScript)

        
        //service Key
        var serviceKeyScriptString = "window.__imqa_service_key = '\(IMQAOTel.serviceKey)';"
        let serviceKeyScript = WKUserScript(
            source: serviceKeyScriptString,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(serviceKeyScript)

        
        if !SessionBasedSampler.sampler {
            let deactivatedScriptString = "window.__imqa_deactivated = true;"
            let deactivatedScript = WKUserScript(
                source: deactivatedScriptString,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            userContentController.addUserScript(deactivatedScript)
        }
    }
}


extension IMQA{
    static func createSessionLifecycle(controller: SessionControllable) -> SessionLifecycle {
        iOSSessionLifecycle(controller: controller)
    }
    
    @objc public func currentSessionId() -> String? {
        return sessionController.currentSession?.id.toString
    }
}
