//===---*- Greatdori! -*---------------------------------------------------===//
//
// DoriAPI.swift
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

/// Access Bestdori API directly, fetch Swifty raw data.
///
/// Each methods in ``DoriAPI`` fetches raw data from Bestdori API directly,
/// makes them Swifty and return them.
public final class DoriAPI {
    private init() {}
    
    @usableFromInline
    @safe
    nonisolated(unsafe)
    internal static var _preferredLocale = Locale(rawValue: UserDefaults.standard.string(forKey: "_DoriKit_DoriAPIPreferredLocale") ?? "jp") ?? .jp
    /// The preferred locale.
    @inlinable
    public static var preferredLocale: Locale {
        _read {
            yield _preferredLocale
        }
        set {
            _preferredLocale = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "_DoriKit_DoriAPIPreferredLocale")
        }
    }
    @usableFromInline
    @safe
    nonisolated(unsafe)
    internal static var _secondaryLocale = Locale(rawValue: UserDefaults.standard.string(forKey: "_DoriKit_DoriAPISecondaryLocale") ?? "en") ?? .en
    /// The secondary preferred locale.
    @inlinable
    public static var secondaryLocale: Locale {
        _read {
            yield _secondaryLocale
        }
        set {
            _secondaryLocale = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "_DoriKit_DoriAPISecondaryLocale")
        }
    }
    
    /// Represent a specific country or region which localized in GBP.
    @frozen
    public enum Locale: String, CaseIterable, DoriCache.Cacheable {
        @inlinable
        public static var primaryLocale: Self {
            _read {
                yield preferredLocale
            }
            _modify {
                yield &preferredLocale
            }
        }
        @inlinable
        public static var secondaryLocale: Self {
            _read {
                yield DoriAPI.secondaryLocale
            }
            _modify {
                yield &DoriAPI.secondaryLocale
            }
        }
        
        case jp
        case en
        case tw
        case cn
        case kr
    }
    
    /// Represent data which differently in different locale.
    ///
    /// Data in different locales is optional
    /// because some data isn't available in all locales.
    /// There's no guarantee that there's always at least
    /// one locale's data is available in a bunch of localized data.
    /// That is, a `LocalizedData` may has all properties `nil`.
    ///
    /// Generally, if data is not available in a locale,
    /// you can use the `jp`'s as fallback.
    /// However, not all data availables in `jp`,
    /// such as events related to Bilibili are only available in China.
    @_eagerMove
    public struct LocalizedData<T>: _DestructorSafeContainer {
        public var jp: T?
        public var en: T?
        public var tw: T?
        public var cn: T?
        public var kr: T?
        
        @usableFromInline
        internal init(jp: T?, en: T?, tw: T?, cn: T?, kr: T?) {
            self.jp = jp
            self.en = en
            self.tw = tw
            self.cn = cn
            self.kr = kr
        }
        
        @inlinable
        public init(_jp: T?, en: T?, tw: T?, cn: T?, kr: T?) {
            self.init(jp: _jp, en: en, tw: tw, cn: cn, kr: kr)
        }
        
        /// Get localized data for locale.
        /// - Parameter locale: required locale for data.
        /// - Returns: localized data, nil if not available.
        @inlinable
        public func forLocale(_ locale: Locale) -> T? {
            switch locale {
            case .jp: self.jp
            case .en: self.en
            case .tw: self.tw
            case .cn: self.cn
            case .kr: self.kr
            }
        }
        /// Check if the data available in specific locale.
        /// - Parameter locale: the locale to check.
        /// - Returns: if the data available.
        @inlinable
        public func availableInLocale(_ locale: Locale) -> Bool {
            forLocale(locale) != nil
        }
        /// Get localized data for preferred locale.
        /// - Parameter allowsFallback: Whether to allow fallback to other locales
        /// if data isn't available in preferred locale.
        /// - Returns: localized data for preferred locale, nil if not available.
        public func forPreferredLocale(allowsFallback: Bool = true) -> T? {
            forLocale(preferredLocale) ?? (allowsFallback ? (forLocale(.jp) ?? forLocale(.en) ?? forLocale(.tw) ?? forLocale(.cn) ?? forLocale(.kr) ?? logger.warning("Failed to lookup any candidate of \(T.self) for preferred locale", evaluate: nil)) : nil)
        }
        /// Get localized data for secondary locale.
        /// - Parameter allowsFallback: Whether to allow fallback to other locales
        /// if data isn't available in secondary locale.
        /// - Returns: localized data for secondary locale, nil if not available.
        public func forSecondaryLocale(allowsFallback: Bool = true) -> T? {
            forLocale(secondaryLocale) ?? (allowsFallback ? (forLocale(.jp) ?? forLocale(.en) ?? forLocale(.tw) ?? forLocale(.cn) ?? forLocale(.kr) ?? logger.warning("Failed to lookup any candidate of \(T.self) for secondary locale", evaluate: nil)) : nil)
        }
        /// Check if the data available in preferred locale.
        /// - Returns: if the data available.
        @inlinable
        public func availableInPreferredLocale() -> Bool {
            forPreferredLocale(allowsFallback: false) != nil
        }
        /// Check if the data available in secondary locale.
        /// - Returns: if the data available.
        @inlinable
        public func availableInSecondaryLocale() -> Bool {
            forSecondaryLocale(allowsFallback: false) != nil
        }
        /// Check if the available locale of data.
        ///
        /// This function checks if data available in preferred locale first,
        /// if not provided or not available, it checks from jp to kr respectively.
        ///
        /// - Parameter locale: preferred first locale.
        /// - Returns: first available locale of data, nil if none.
        @inlinable
        public func availableLocale(prefer locale: Locale? = nil) -> Locale? {
            if availableInLocale(locale ?? preferredLocale) {
                return locale ?? preferredLocale
            }
            for locale in Locale.allCases where availableInLocale(locale) {
                return locale
            }
            return nil
        }
        
        @inlinable
        public mutating func _set(_ newValue: T?, forLocale locale: Locale) {
            switch locale {
            case .jp: self.jp = newValue
            case .en: self.en = newValue
            case .tw: self.tw = newValue
            case .cn: self.cn = newValue
            case .kr: self.kr = newValue
            }
        }
    }
    
    /// Represent a constellation
    @frozen
    public enum Constellation: String, DoriCache.Cacheable {
        case aries
        case taurus
        case gemini
        case cancer
        case leo
        case virgo
        case libra
        case scorpio
        case sagittarius
        case capricorn
        case aquarius
        case pisces
    }
    
    /// Attribute of cards
    @frozen
    public enum Attribute: String, Sendable, CaseIterable, Hashable, DoriCache.Cacheable {
        case powerful
        case cool
        case happy
        case pure
    }
}

extension DoriAPI.Locale {
    internal init?(rawIntValue value: Int) {
        switch value {
        case 0: self = .jp
        case 1: self = .en
        case 2: self = .tw
        case 3: self = .cn
        case 4: self = .kr
        default: return nil
        }
    }
    
    internal var rawIntValue: Int {
        switch self {
        case .jp: return 0
        case .en: return 1
        case .tw: return 2
        case .cn: return 3
        case .kr: return 4
        }
    }
    
    public func nsLocale() -> Locale {
        switch self {
        case .jp: return Locale(identifier: "ja")
        case .en: return Locale(identifier: "en")
        case .tw: return Locale(identifier: "zh-Hant")
        case .cn: return Locale(identifier: "zh-Hans")
        case .kr: return Locale(identifier: "ko")
        }
    }
}

extension DoriAPI.LocalizedData: Sendable where T: Sendable {}
extension DoriAPI.LocalizedData: Equatable where T: Equatable {}
extension DoriAPI.LocalizedData: Hashable where T: Hashable {}
extension DoriAPI.LocalizedData: DoriCache.Cacheable, Codable where T: DoriCache.Cacheable {}

extension DoriAPI.LocalizedData {
    /// Returns localized data containing the results of mapping the given closure
    /// over each locales.
    ///
    /// - Parameter transform: A mapping closure. `transform` accepts an
    ///   element of this localized data as its parameter and returns a transformed
    ///   value of the same or of a different type.
    /// - Returns: Localized data containing the transformed elements of this
    ///   sequence.
    @inlinable
    public func map<R, E>(_ transform: (T?) throws(E) -> R?) throws(E) -> DoriAPI.LocalizedData<R> {
        var result = DoriAPI.LocalizedData<R>(jp: nil, en: nil, tw: nil, cn: nil, kr: nil)
        for locale in DoriAPI.Locale.allCases {
            result._set(try transform(self.forLocale(locale)), forLocale: locale)
        }
        return result
    }
    
    /// Returns an array containing the non-`nil` results of calling the given
    /// transformation with each element of this localized data.
    ///
    /// Use this method to receive an array of non-optional values when your
    /// transformation produces an optional value.
    ///
    /// - Parameter transform: A closure that accepts an element of this
    ///   localized data as its argument and returns an optional value.
    /// - Returns: An array of the non-`nil` results of calling `transform`
    ///   with each element of the sequence.
    ///
    /// - Complexity: O(*n*), where *n* is the length of this sequence.
    @inlinable
    public func compactMap<ElementOfResult>(
        _ transform: (T?) throws -> ElementOfResult?
    ) rethrows -> [ElementOfResult] {
        return try _compactMap(transform)
    }
    
    // The implementation of compactMap accepting a closure with an optional result.
    // Factored out into a separate function in order to be used in multiple
    // overloads.
    @inlinable
    @inline(__always)
    public func _compactMap<ElementOfResult>(
        _ transform: (T?) throws -> ElementOfResult?
    ) rethrows -> [ElementOfResult] {
        var result: [ElementOfResult] = []
        for locale in DoriAPI.Locale.allCases {
            if let newElement = try transform(self.forLocale(locale)) {
                result.append(newElement)
            }
        }
        return result
    }
}
extension DoriAPI.LocalizedData {
    @inlinable
    public var isEmpty: Bool {
        self.jp == nil && self.en == nil && self.tw == nil && self.cn == nil && self.kr == nil
    }
}
extension DoriAPI.LocalizedData where T: Collection {
    @inlinable
    public var isValueEmpty: Bool {
        self.jp?.isEmpty != false
        && self.en?.isEmpty != false
        && self.tw?.isEmpty != false
        && self.cn?.isEmpty != false
        && self.kr?.isEmpty != false
    }
}
