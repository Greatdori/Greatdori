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
internal import DoriAssetShims

public final class DoriOfflineAsset: Sendable {
    public static let shared = DoriOfflineAsset()
    
    public init() {
        AssetShims.startup()
    }
    deinit {
        AssetShims.shutdown()
    }
    
    public var bundleBaseURL: URL {
        .init(filePath: NSHomeDirectory() + "/Documents/OfflineResource.bundle")
    }
    
    /// Download offline resource with type and locale.
    ///
    /// - Parameters:
    ///   - type: Type of resource, see ``ResourceType`` for more details.
    ///   - locale: Locale of resource.
    ///   - onProgressUpdate: A closure to call when downloading progress updates.
    ///
    ///     This closure takes 3 arguments, which means downloading progress (0.0~1.0),
    ///     received objects count, and total objects count, respectively.
    /// - Returns: Whether downloading is success.
    ///
    /// Some other works have to be performed before the first call of `onProgressUpdate`.
    /// The best practice for progress UI is show some texts like "preparing..."
    /// before `onProgressUpdate` being called. Actually, Git is contacting the server
    /// before downloading. You can provide more detailed text to user based on this information.
    /// Mention `Git` to users is not a good idea, generally.
    @discardableResult
    public func downloadResource(
        of type: ResourceType,
        in locale: DoriAPI.Locale,
        onProgressUpdate: @Sendable @escaping (Double, Int, Int) -> Void
    ) async throws -> Bool {
        let callback: @Sendable @convention(c) (UnsafePointer<_git_indexer_progress>, UnsafeMutableRawPointer?) -> Int32 = { progress, payload in
            if let updatePayload = unsafe payload?.load(as: ((Double, Int, Int) -> Void).self) {
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
                            ofType: type.rawValue,
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
    
    public func fileExists(_ path: String, in locale: DoriAPI.Locale, of type: ResourceType) -> Bool {
        AssetShims.fileExists(path, inLocale: locale.rawValue, ofType: type.rawValue)
    }
    
    public func contentsOfDirectory(atPath path: String, in locale: DoriAPI.Locale, of type: ResourceType) throws -> [String] {
        try AssetShims.contentsOfDirectory(atPath: path, inLocale: locale.rawValue, ofType: type.rawValue)
    }
    
    public func fileData(forPath path: String, in locale: DoriAPI.Locale, of type: ResourceType) throws -> Data {
        try AssetShims.fileData(forPath: path, inLocale: locale.rawValue, ofType: type.rawValue)
    }
    
    public func fileHash(forPath path: String, in locale: DoriAPI.Locale, of type: ResourceType) throws -> String {
        try AssetShims.fileHash(forPath: path, inLocale: locale.rawValue, ofType: type.rawValue)
    }
    
    public func writeFile(atPath path: String, in locale: DoriAPI.Locale, of type: ResourceType, toPath destination: String) throws {
        // We have to load all file data to memory first
        // because blobs in git are compressed and can't be read by streaming.
        // Since most of files in GBP aren't large at all, this won't cost much.
        let data = try fileData(forPath: path, in: locale, of: type)
        try data.write(to: URL(filePath: destination))
    }
    
    public enum ResourceType: String, Sendable {
        case main
        case basic
        case movie
        case sound
        case unsupported
    }
}

#endif
