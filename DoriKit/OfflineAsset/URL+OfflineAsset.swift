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
    // FIXME: The referenced file by URL should be checked out to somewhere
    // FIXME: before URL returns, implement hash and checkout single file
    // FIXME: in DoriAssetShims first.
    @usableFromInline
    internal func respectOfflineAssetContext() -> URL {
        #if canImport(DoriAssetShims)
        let behavior = DoriOfflineAsset.localBehavior
        if behavior == .disabled { return self }
        
        let path = self.absoluteString
        guard path.hasPrefix("https://bestdori.com/") else { return self }
        let basePath = String(path.dropFirst("https://bestdori.com/".count))
        
        if basePath.hasPrefix("api") {
            if DoriOfflineAsset.shared.fileExists(basePath, in: .jp, of: .main) {
                return DoriOfflineAsset.shared.bundleBaseURL.appending(path: basePath)
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
            if DoriOfflineAsset.shared.fileExists(localPath, in: locale, of: resourceType) {
                return DoriOfflineAsset.shared.bundleBaseURL.appending(path: localPath)
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
