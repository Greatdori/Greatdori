//
//  DoriCache.swift
//  Greatdori
//
//  Created by Mark Chan on 7/27/25.
//

import SwiftUI
import Foundation

public class DoriCache {
    private init() {}
    
    public protocol Cacheable: Codable {
        init?(fromCache cache: Data)
        var dataForCache: Data { get }
    }
    
    public final class Promise<Result> {
        nonisolated(unsafe) private var _onUpdate: ((Result) -> Void)?
        nonisolated(unsafe) private var initialValue: Result?
        nonisolated(unsafe) private var isValueFirstUpdated: Bool = false
        
        internal init(_ initialValue: Result? = nil) {
            self.initialValue = initialValue
        }
        
        @MainActor
        internal func updateValue(_ value: Result) {
            _onUpdate?(value)
            isValueFirstUpdated = true
        }
        
        public func onUpdate(_ action: @escaping (Result) -> Void) {
            self._onUpdate = action
            if !isValueFirstUpdated, let initialValue {
                action(initialValue)
            }
        }
    }
    
    public static func withCache<Result: Sendable & Cacheable>(
        id: String,
        invocation: sending @escaping () async -> Result?
    ) -> Promise<Result?> {
        let cacheURL = URL(filePath: NSHomeDirectory() + "/Library/Caches/DoriKit_\(Result.self)_\(id).cache")
        
        let promise: Promise<Result?> = .init()
        
        Task.detached(priority: .userInitiated) {
            var cachedResult: Result?
            if let cachedData = try? Data(contentsOf: cacheURL) {
                cachedResult = Result(fromCache: cachedData)
            } else {
                #if DORIKIT_ENABLE_PRECACHE
                if let preCache = preCachedData(byID: id) {
                    if let typed = preCache as? Result {
                        cachedResult = typed
                    }
                }
                #endif
            }
            
            if let cachedResult {
                await promise.updateValue(cachedResult)
            }
            
            let result = await invocation()
            
            // If result is nil but there's data in cache,
            // we don't update value of promise.
            if result == nil && cachedResult != nil {
                return
            }
            
            await promise.updateValue(result)
            
            // Don't save cache if result is nil
            if result == nil {
                return
            }
            
            let cache = result.dataForCache
            try? cache.write(to: cacheURL)
        }
        
        return promise
    }
}

extension DoriCache.Promise: Sendable where Result: Sendable {}

extension DoriCache.Cacheable {
    public init?(fromCache cache: Data) {
        let decoder = PropertyListDecoder()
        if let data = try? decoder.decode(Self.self, from: cache) {
            self = data
        } else {
            return nil
        }
    }
    public var dataForCache: Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return try! encoder.encode(self)
    }
}

extension Color: @retroactive Encodable {
    enum CodingKeys: CodingKey {
        case red
        case green
        case blue
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let resolved = self.resolve(in: .init())
        try container.encode(resolved.red, forKey: .red)
        try container.encode(resolved.green, forKey: .green)
        try container.encode(resolved.blue, forKey: .blue)
    }
}
extension Color: @retroactive Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        self.init(red: red, green: green, blue: blue)
    }
}
extension Color: DoriCache.Cacheable {}

extension String: DoriCache.Cacheable {}
extension Int: DoriCache.Cacheable {}
extension Int8: DoriCache.Cacheable {}
extension Int16: DoriCache.Cacheable {}
extension Int32: DoriCache.Cacheable {}
extension Int64: DoriCache.Cacheable {}
extension UInt: DoriCache.Cacheable {}
extension UInt8: DoriCache.Cacheable {}
extension UInt16: DoriCache.Cacheable {}
extension UInt32: DoriCache.Cacheable {}
extension UInt64: DoriCache.Cacheable {}
extension Bool: DoriCache.Cacheable {}
extension Double: DoriCache.Cacheable {}
extension Float: DoriCache.Cacheable {}
extension Date: DoriCache.Cacheable {}
extension Array: DoriCache.Cacheable where Element: DoriCache.Cacheable {}
extension Dictionary: DoriCache.Cacheable where Key: DoriCache.Cacheable, Value: DoriCache.Cacheable {}
extension Set: DoriCache.Cacheable where Element: DoriCache.Cacheable {}
extension Optional: DoriCache.Cacheable where Wrapped: DoriCache.Cacheable {}
