//
//  CaptureServices.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/4.
//

import Foundation
import IMQACommonInternal
import IMQAOtelInternal


final class CaptureServices {

    @ThreadSafe
    var services: [CaptureService]

    var context: CrashReporterContext
    weak var crashReporter: CrashReporter?

    init(options: IMQA.Options,
         storage: IMQAStorage?,
         upload: IMQAUpload?) throws {
        
        // add required capture services
        // and remove duplicates
        services = CaptureServiceFactory.addRequiredServices(to: options.services.unique)

        // create context for crash reporter
        let partitionIdentifier = IMQAFileSystem.defaultPartitionId
        context = CrashReporterContext(
            appId: Bundle.appIdentifier,
            sdkVersion: IMQAMeta.sdkVersion,
            filePathProvider: IMQAFilePathProvider(
                partitionId: partitionIdentifier,
                appGroupId: nil
            ),
            notificationCenter: IMQA.notificationCenter
        )
        crashReporter = options.crashReporter

        // upload action for crash reports
        if let crashReporter = options.crashReporter {
            crashReporter.onNewReport = { [weak crashReporter, weak storage, weak upload] report in
                UnsentDataHandler.sendCrashLog(
                    report: report,
                    reporter: crashReporter,
                    session: nil,
                    storage: storage,
                    upload: upload,
                    otel: IMQA.client
                )
            }
        }
        
        // pass storage reference to capture services
        // that generate resources
        for service in services {
            if let resourceService = service as? ResourceCaptureService {
                resourceService.handler = storage
            }
        }

        // subscribe to session start notification
        // to update the crash reporter with the new session id
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSessionStart),
            name: Notification.Name.imqaSessionDidStart,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        crashReporter?.install(context: context, logger: IMQA.logger)

        for service in services {
            service.install(otel: IMQA.client, logger: IMQA.logger)
            service.start()
        }
    }

    func stop() {
        for service in services {
            service.stop()
        }
    }

    @objc func onSessionStart(notification: Notification) {
        if let session = notification.object as? SessionRecord {
            crashReporter?.currentSessionId = session.id.toString
        }
    }
}

private extension Array where Element == CaptureService {
    var unique: [CaptureService] {
        var unique = [String: CaptureService]()

        for service in self {
            let typeName = String(describing: type(of: service))
            guard unique[typeName] == nil else {
                continue
            }

            unique[typeName] = service
        }

        return Array(unique.values)
    }
}
