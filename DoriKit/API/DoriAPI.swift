//
//  DoriAPI.swift
//  DoriKit
//
//  Created by Mark Chan on 7/18/25.
//

import Foundation

/// Access Bestdori API directly, fetch Swifty raw data.
///
/// Each methods in ``DoriAPI`` fetches raw data from Bestdori API directly,
/// makes them Swifty and return them.
public class DoriAPI {
    private init() {}
    
    @usableFromInline
    internal static var _preferredLocale = Locale(rawValue: UserDefaults.standard.string(forKey: "_DoriKit_DoriAPIPreferredLocale") ?? "jp") ?? .jp
    /// The preferred locale.
    @inlinable
    public static var preferredLocale: Locale {
        get {
            _preferredLocale
        }
        set {
            _preferredLocale = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "_DoriKit_DoriAPIPreferredLocale")
        }
    }
    
    /// Represent a specific country or region which localized in BanG Dream.
    @frozen
    public enum Locale: String, CaseIterable {
        case jp
        case en
        case tw
        case cn
        case kr
    }
    
    /// Represent data which differently in different locale.
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
        /// - Returns: localized data for preferred locale, nil if not available.
        public func forPreferredLocale(allowsFallback: Bool = true) -> T? {
            forLocale(preferredLocale) ?? (allowsFallback ? (forLocale(.jp) ?? forLocale(.en) ?? forLocale(.tw) ?? forLocale(.cn) ?? forLocale(.kr) ?? logger.warning("Failed to lookup any candidate of \(T.self) for preferred locale", evaluate: nil)) : nil)
        }
        /// Check if the data available in preferred locale.
        /// - Returns: if the data available.
        @inlinable
        public func availableInPreferredLocale() -> Bool {
            forPreferredLocale(allowsFallback: false) != nil
        }
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
    
    public enum Constellation: String {
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
    public enum Attribute: String, CaseIterable {
        case pure
        case cool
        case happy
        case powerful
    }
}

extension DoriAPI.LocalizedData: Equatable where T: Equatable {}
extension DoriAPI.LocalizedData: Hashable where T: Hashable {}

extension DoriAPI.LocalizedData {
    @inlinable
    public func map<R, E>(_ transform: (T?) throws(E) -> R?) throws(E) -> DoriAPI.LocalizedData<R> {
        var result = DoriAPI.LocalizedData<R>(jp: nil, en: nil, tw: nil, cn: nil, kr: nil)
        for locale in DoriAPI.Locale.allCases {
            result._set(try transform(self.forLocale(locale)), forLocale: locale)
        }
        return result
    }
}
