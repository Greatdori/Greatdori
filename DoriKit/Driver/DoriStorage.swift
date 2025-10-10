//===---*- Greatdori! -*---------------------------------------------------===//
//
// DoriStorage.swift
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

@propertyWrapper
public struct DoriStorage<Value: Sendable & DoriCacheable>: Sendable {
    private let key: String
    private let defaultValue: Value
    
    public init(wrappedValue: Value, _ key: String) {
        self.key = key.replacingOccurrences(of: "/", with: "_")
        self.defaultValue = wrappedValue
        
        if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Documents/DoriStorage/") {
            try? FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Documents/DoriStorage/", withIntermediateDirectories: true)
        }
    }
    
    public var wrappedValue: Value {
        get {
            if let _data = try? Data(contentsOf: storageURL),
               let value = Value(fromCache: _data) {
                value
            } else {
                defaultValue
            }
        }
        nonmutating set {
            try? newValue.dataForCache.write(to: storageURL)
        }
    }
    
    private var storageURL: URL {
        .init(filePath: NSHomeDirectory() + "/Documents/DoriStorage/\(key).plist")
    }
}

#if canImport(SwiftUI)

import SwiftUI

extension DoriStorage: DynamicProperty {
    public var projectedValue: Binding<Value> {
        .init {
            wrappedValue
        } set: { newValue in
            try? newValue.dataForCache.write(to: storageURL)
        }
    }
}

#endif
