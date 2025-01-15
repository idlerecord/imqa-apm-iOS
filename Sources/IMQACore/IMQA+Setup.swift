//
//  IMQA+Setup.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/29.
//

import Foundation
import OpenTelemetryApi
import IMQAOtelInternal
import IMQACommonInternal
import IMQACollectDeviceInfo

extension IMQA {
    static func createStorage(options: IMQA.Options) -> IMQAStorage {

        let partitionId = IMQAFileSystem.defaultPartitionId
        let storageUrl = IMQAFileSystem.storageDirectoryURL(
            partitionId: partitionId,
            appGroupId: nil
        )
        let storageOptions = IMQAStorage.Options(baseUrl: storageUrl!, fileName: "")
        let storage = IMQAStorage(options: storageOptions, logger: IMQA.logger, appId: partitionId)
        return storage
    }

    static func createUpload(options: IMQA.Options, deviceId: String) -> IMQAUpload? {

        // endpoints
        guard let endpoints = options.endpoints else {
            return nil
        }
        
        let baseUrl = IMQADevice.isDebuggerAttached ? endpoints.developmentBaseURL : endpoints.baseURL
        guard let spansURL = URL.spansEndpoint(basePath: baseUrl),
              let logsURL = URL.logsEndpoint(basePath: baseUrl) else {
            IMQA.logger.error("Failed to initialize endpoints!")
            return nil
        }

        let uploadEndpoints = IMQAUpload.EndpointOptions(spansURL: spansURL, logsURL: logsURL)

        let partitionId = IMQAFileSystem.defaultPartitionId

        // cache
        guard let cacheUrl = IMQAFileSystem.uploadsDirectoryPath(
            partitionIdentifier: partitionId,
            appGroupId: nil
        ),
              let cache = IMQAUpload.CacheOptions(cacheBaseUrl: cacheUrl)
        else {
            IMQA.logger.error("Failed to initialize upload cache!")
            return nil
        }

        // metadata
        let metadata = IMQAUpload.MetadataOptions(
            apiKey: "appId",
            userAgent: IMQAMeta.userAgent,
            deviceId: deviceId.filter { c in c.isHexDigit }
        )

        do {
            let options = IMQAUpload.Options(endpoints: uploadEndpoints, cache: cache, metadata: metadata)
            let queue = DispatchQueue(label: "com.imqa.upload", attributes: .concurrent)

            return try IMQAUpload(options: options, logger: IMQA.logger, queue: queue)
        } catch {
            IMQA.logger.error("Error initializing IMQA Upload: " + error.localizedDescription)
        }

        return nil
    }
}

