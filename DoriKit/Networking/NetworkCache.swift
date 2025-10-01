//===---*- Greatdori! -*---------------------------------------------------===//
//
// NetworkCache.swift
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

internal actor NetworkCache: Sendable {
    internal static let shared = NetworkCache()
    
    private init() {}
    
    private var _storage: [URL: CacheItem] = [:]
    
    internal func getCache(for url: URL) -> CacheItem? {
        _storage[url]
    }
    internal func updateCache(_ cache: CacheItem, for url: URL) {
        _storage.updateValue(cache, forKey: url)
    }
    internal func removeCache(for url: URL) {
        _storage.removeValue(forKey: url)
    }
    
    internal struct CacheItem: Sendable {
        internal var data: Data
        internal var dateUpdated: Date = .now
    }
}
