//===---*- Greatdori! -*---------------------------------------------------===//
//
// OfflineNetworking.swift
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
internal import Alamofire

internal func offlineAssetResult(for convertible: URLConvertible) -> OfflineAssetNetworkingResult {
    if let url = try? convertible.asURL() {
        offlineAssetResult(for: url)
    } else {
        .useDefault
    }
}

internal func offlineAssetResult(for url: URL) -> OfflineAssetNetworkingResult {
    offlineAssetResult(for: url.absoluteString)
}

internal func offlineAssetResult(for url: String) -> OfflineAssetNetworkingResult {
    #if canImport(DoriAssetShims)
    let behavior = DoriOfflineAsset.localBehavior
    if behavior == .disabled { return .useDefault }
    
    guard url.hasPrefix("https://bestdori.com/") else { return .useDefault }
    let basePath = String(url.dropFirst("https://bestdori.com/".count))
    
    if basePath.hasPrefix("api") {
        if let data = try? DoriOfflineAsset.shared.fileData(forPath: basePath, in: .jp, of: .main) {
            return .delegated(data)
        } else if behavior == .enabled {
            return .delegated(nil)
        }
    }
    #endif
    
    return .useDefault
}

internal enum OfflineAssetNetworkingResult {
    case delegated(Data?)
    case useDefault
}
