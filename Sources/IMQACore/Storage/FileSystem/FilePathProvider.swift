//
//  FilePathProvider.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/4.
//


import Foundation

public protocol FilePathProvider {
    func fileURL(for scope: String, name: String) -> URL?

    func directoryURL(for scope: String) -> URL?
}
