//
//  File.swift
//  IMQA-iOS-P
//
//  Created by Hunta on 2024/10/15.
//

import Foundation
import IMQACommonInternal
import IMQACaptureService
import IMQAOtelInternal

public class IMQA: NSObject {
    
    public static var client: IMQA?
        
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
                       logController: logController) //꼭 실행해야함니다.
        IMQA.logger.otel = self
    }
}

extension IMQA{
    @discardableResult
    public func start() throws -> IMQA{
        guard Thread.isMainThread else {
            throw IMQASetupError.invalidThread("IMQA must be started on the main thread")
        }
        sessionLifecycle.setup()
        
        IMQA.synchronizationQueue.sync {
            guard started == false else{
                IMQA.logger.warning("IMQA was already started!")
                return
            }
//            guard config == nil || config?.isSDKEnabled == true else {
//                IMQA.logger.warning("IMQA was already started!")
//                return
//            }

            let processStartSpan = createProcessStartSpan()
            defer{processStartSpan.end()}

//            recordSpan(name: "Session", parent: processStartSpan, type: .SESSION) { _ in
                started = true
                
                sessionLifecycle.start()
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
//            }
        }
        return self
    }
    
    @discardableResult
    public static func setup(options: IMQA.Options) throws -> IMQA {
        //network  status
        NetworkInfoManager.sharedInstance

        if !Thread.isMainThread {
            throw IMQASetupError.invalidThread("IMQA must be setup on the main thread")
        }

        if ProcessInfo.processInfo.isSwiftUIPreview {
            throw IMQASetupError.initializationNotAllowed("IMQA cannot be initialized on SwiftUI Previews")
        }
        
        let startTime = Date()
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

extension IMQA{
    static func createSessionLifecycle(controller: SessionControllable) -> SessionLifecycle {
        iOSSessionLifecycle(controller: controller)
    }
    
    @objc public func currentSessionId() -> String? {
//        guard config == nil || config?.isSDKEnabled == true else {
//            return nil
//        }

        return sessionController.currentSession?.id.toString
    }

}
