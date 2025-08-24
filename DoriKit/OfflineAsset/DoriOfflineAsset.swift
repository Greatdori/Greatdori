//===---*- Greatdori! -*---------------------------------------------------===//
//
// DoriOfflineAsset.swift
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

#if canImport(DoriAssetShims)

import Foundation
@_implementationOnly import DoriAssetShims

public final class DoriOfflineAsset: Sendable {
    public static let shared = DoriOfflineAsset()
    
    public init() {
        AssetShims.startup()
    }
    deinit {
        AssetShims.shutdown()
    }
    
    @discardableResult
    public func downloadResource(
        of type: String,
        in locale: DoriAPI.Locale,
        onProgressUpdate: @Sendable @escaping (Double, Int, Int) -> Void
    ) async throws -> Bool {
        let callback: @Sendable @convention(c) (UnsafePointer<_git_indexer_progress>?, UnsafeMutableRawPointer?) -> Int32 = { progress, payload in
            if let progress = unsafe progress, let updatePayload = unsafe payload?.load(as: ((Double, Int, Int) -> Void).self) {
                let percentage = unsafe Double(progress.pointee.indexed_objects) / Double(progress.pointee.total_objects)
                unsafe updatePayload(percentage, Int(progress.pointee.indexed_objects), Int(progress.pointee.total_objects))
            }
            return 0
        }
        return try await withCheckedThrowingContinuation { continuation in
                DispatchQueue(label: "com.memz233.DoriKit.OfflineAsset.download-resource", qos: .userInitiated).async {
                    var mutableProgressUpdate = onProgressUpdate
                    unsafe withUnsafeMutablePointer(to: &mutableProgressUpdate) { ptr in
                        var error: NSError?
                        let success = unsafe AssetShims.downloadResource(
                            inLocale: locale.rawValue,
                            ofType: type,
                            payload: ptr,
                            error: &error,
                            onProgressUpdate: callback
                        )
                        if let error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume(returning: success)
                    }
                }
            }
    }
}

#endif
