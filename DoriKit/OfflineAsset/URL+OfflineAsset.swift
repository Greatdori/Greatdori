//===---*- Greatdori! -*---------------------------------------------------===//
//
// URL+OfflineAsset.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import Foundation
internal import os

private let placeholderURL = URL(string: "placeholder://nil")!

#if canImport(DoriAssetShims)

extension URL {
    public func withOfflineAsset(_ behavior: OfflineAssetBehavior = .enableIfAvailable) -> URL {
        DoriKit.withOfflineAsset(behavior) {
            self.respectOfflineAssetContext()
        }
    }
}

#endif

extension URL {
    @usableFromInline
    internal func respectOfflineAssetContext() -> URL {
        #if canImport(DoriAssetShims)
        func checkedOutFileURL(base path: String, in locale: DoriAPI.Locale, of type: DoriOfflineAsset.ResourceType) -> URL? {
            if let hash = try? DoriOfflineAsset.shared.fileHash(forPath: path, in: locale, of: type) {
                var sourceExtension = path.split(separator: ".").last ?? ""
                if sourceExtension.contains("/") {
                    // Invalid
                    sourceExtension = ""
                } else if !sourceExtension.isEmpty {
                    sourceExtension = "." + sourceExtension
                }
                let fileURL = URL(filePath: NSHomeDirectory() + "/tmp/TemporaryOfflineAssetCheckouts/\(hash)\(sourceExtension)")
                if FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) {
                    // Since a hash of blob is unique, we can elide writing
                    // if previous checked out file exists.
                    return fileURL
                }
                let fileParentDirectoryURL = fileURL.deletingLastPathComponent()
                do {
                    if _slowPath(!FileManager.default.fileExists(atPath: fileParentDirectoryURL.path(percentEncoded: false))) {
                        try FileManager.default.createDirectory(at: fileParentDirectoryURL, withIntermediateDirectories: true)
                    }
                    try DoriOfflineAsset.shared.writeFile(atPath: path, in: locale, of: type, toPath: fileURL.path(percentEncoded: false))
                    return fileURL
                } catch {
                    logger.fault("Failed to write temporary file for local asset; please submit a bug report (https://github.com/WindowsMEMZ/Greatdori/issues/new) [\(error.localizedDescription)]")
                }
            }
            return nil
        }
        
        let behavior = DoriOfflineAsset.localBehavior
        if behavior == .disabled { return self }
        
        let path = self.absoluteString
        guard path.hasPrefix("https://bestdori.com/") else { return self }
        let basePath = String(path.dropFirst("https://bestdori.com/".count))
        
        if basePath.hasPrefix("api") {
            if let url = checkedOutFileURL(base: basePath, in: .jp, of: .main) {
                return url
            } else if behavior == .enabled {
                logger.fault("Offline asset context requires using local asset URL, but requested asset is not exist in local, returning a placeholder URL")
                return placeholderURL
            }
        }
        if basePath.hasPrefix("assets") {
            // assets/[locale]/[recognizer]/...
            // we use [recognizer] to determine the resource type.
            let separatedPath = basePath.split(separator: "/")
            guard separatedPath.count > 3 else { return self } // To prevent out of index
            guard let locale = DoriAPI.Locale(rawValue: String(separatedPath[1])) else { return self }
            let resourceType = resourceType(from: String(separatedPath[2]), next: separatedPath.dropFirst(3).map { String($0) })
            let localPath = separatedPath.dropFirst().joined(separator: "/") // removes 'assets/'
            if let url = checkedOutFileURL(base: localPath, in: locale, of: resourceType) {
                return url
            } else if behavior == .enabled {
                logger.fault("Offline asset context requires using local asset URL, but requested asset is not exist in local, returning a placeholder URL")
                return placeholderURL
            }
        }
        #endif
        
        return self
    }
}

#if canImport(DoriAssetShims)

private func resourceType(from recognizer: String, next: [String]) -> DoriOfflineAsset.ResourceType {
    switch recognizer {
    case "movie": .movie
    case "sound": .sound
    case "characters":
        if let nextRecognizer = next.first,
           nextRecognizer == "ingameresourceset" {
            .unsupported
        } else {
            .basic
        }
    case "live2d", "star3d", "musicscore", "pickupsituation": .unsupported
    default: .basic
    }
}

#endif
