//===---*- Greatdori! -*---------------------------------------------------===//
//
// Filter.swift
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
internal import CryptoKit

// MARK: extension DoriFrontend
extension DoriFrontend {
    /// A type that can be sorted by ``DoriFrontend/Sorter``.
    public protocol Sortable {
        /// A group of ``DoriFrontend/Sorter/Keyword`` that can be used
        /// for sorting this type.
        static var applicableSortingTypes: [DoriFrontend.Sorter.Keyword] { get }
        
        /// A boolean value that indicates whether this type
        /// has an ending date (i.e. can be *removed*, *stopped*, or etc.)
        ///
        /// - SeeAlso:
        ///     Pass this value as the `hasEndingDate` argument
        ///     of ``DoriFrontend/Sorter/Keyword/localizedString(hasEndingDate:)``
        ///     to get more accurate description of a keyword if needed.
        static var hasEndingDate: Bool { get }
        
        static func _compare<ValueType>(usingDoriSorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool?
    }
    
    public struct Sorter: Sendable, Equatable, Hashable, Codable {
        /// The direction of this sorter.
        public var direction: Direction { didSet { store() } }
        /// The keyword for sorting.
        public var keyword: Keyword { didSet { store() } }
        
        /// Creates a sorter with given direction and keyword.
        /// - Parameters:
        ///   - direction: The direction of this sorter.
        ///   - keyword: The keyword for sorting.
        public init(direction: Direction = .descending, keyword: Keyword = .id) {
            self.direction = direction
            self.keyword = keyword
            self.direction = direction
        }
        
        private var recoveryID: String?
        
        /// Create a sorter which can restore to its latest selections across sessions.
        /// - Parameter id: An identifier for restoration.
        /// - Returns: A sorter which stores its selections automaticlly and can be restore by provided ID.
        public static func recoverable(id: String) -> Self {
            let storageURL = URL(filePath: NSHomeDirectory() + "/Documents/DoriKit_Sorter_Status.plist")
            let decoder = PropertyListDecoder()
            var result: Self = if let _data = try? Data(contentsOf: storageURL),
                                  let storage = try? decoder.decode([String: Sorter].self, from: _data) {
                storage[id] ?? .init()
            } else {
                .init()
            }
            result.recoveryID = id
            return result
        }
        
        /// A string identity of the sorter.
        ///
        /// This allows you to identify whether two sorters have the same effect,
        /// which is useful when working with ``DoriCache``.
        public var identity: String {
            let desc = """
            \(direction)\
            \(keyword.rawValue)
            """
            return String(SHA256.hash(data: desc.data(using: .utf8)!).map { $0.description }.joined().prefix(8))
        }
        
        private static let _storageLock = NSLock()
        private func store() {
            guard let recoveryID else { return }
            DispatchQueue(label: "com.memz233.DoriKit.Sorter-Store", qos: .utility).async {
                Self._storageLock.lock()
                let storageURL = URL(filePath: NSHomeDirectory() + "/Documents/DoriKit_Sorter_Status.plist")
                let decoder = PropertyListDecoder()
                let encoder = PropertyListEncoder()
                if let _data = try? Data(contentsOf: storageURL),
                   var storage = try? decoder.decode([String: Sorter].self, from: _data) {
                    storage.updateValue(self, forKey: recoveryID)
                    try? encoder.encode(storage).write(to: storageURL)
                } else {
                    let storage = [recoveryID: self]
                    try? encoder.encode(storage).write(to: storageURL)
                }
                Self._storageLock.unlock()
            }
        }
        
        /// Represents direction of a sorter.
        @frozen
        public enum Direction: String, Equatable, Hashable, Codable {
            case ascending = "ascending"
            case descending = "descending"
            
            /// The reversed direction of current.
            @inlinable
            public var reversed: Self {
                switch self {
                case .ascending: .descending
                case .descending: .ascending
                }
            }
            
            /// Reverse the direction.
            @inlinable
            public mutating func reverse() {
                self = self.reversed
            }
        }
        /// Represents keyword of a sorter.
        public enum Keyword: RawRepresentable, CaseIterable, Sendable, Equatable, Hashable, Codable {
            case releaseDate(in: DoriAPI.Locale)
            case difficultyReleaseDate(in: DoriAPI.Locale)
            case mvReleaseDate(in: DoriAPI.Locale)
            case level(for: DoriAPI.Song.DifficultyType)
            case rarity
            case maximumStat
            case id
            
            public static let allCases: [Self] = [
                .releaseDate(in: .jp),
                .releaseDate(in: .en),
                .releaseDate(in: .tw),
                .releaseDate(in: .cn),
                .releaseDate(in: .kr),
                .difficultyReleaseDate(in: .jp),
                .difficultyReleaseDate(in: .en),
                .difficultyReleaseDate(in: .tw),
                .difficultyReleaseDate(in: .cn),
                .difficultyReleaseDate(in: .kr),
                .mvReleaseDate(in: .jp),
                .mvReleaseDate(in: .en),
                .mvReleaseDate(in: .tw),
                .mvReleaseDate(in: .cn),
                .mvReleaseDate(in: .kr),
                .level(for: .easy),
                .level(for: .normal),
                .level(for: .hard),
                .level(for: .expert),
                .level(for: .special),
                .rarity,
                .maximumStat,
                .id
            ]
            
            public init?(rawValue: UInt32) {
                let high = UInt16(rawValue >> 16 & 0xFFFF)
                let low = UInt16(rawValue & 0xFFFF)
                switch high {
                case 1 << 0:
                    if let locale = DoriAPI.Locale(rawIntValue: Int(low)) {
                        self = .releaseDate(in: locale)
                    } else {
                        return nil
                    }
                case 1 << 1:
                    if let locale = DoriAPI.Locale(rawIntValue: Int(low)) {
                        self = .difficultyReleaseDate(in: locale)
                    } else {
                        return nil
                    }
                case 1 << 2:
                    if let locale = DoriAPI.Locale(rawIntValue: Int(low)) {
                        self = .mvReleaseDate(in: locale)
                    } else {
                        return nil
                    }
                case 1 << 3:
                    if let difficulty = DoriAPI.Song.DifficultyType(rawValue: Int(low)) {
                        self = .level(for: difficulty)
                    } else {
                        return nil
                    }
                case 1 << 4:
                    self = .rarity
                case 1 << 5:
                    self = .maximumStat
                case 1 << 6:
                    self = .id
                default: return nil
                }
            }
            
            public var rawValue: UInt32 {
                let high: UInt16
                let low: UInt16
                switch self {
                case .releaseDate(let locale):
                    high = 1 << 0
                    low = UInt16(locale.rawIntValue)
                case .difficultyReleaseDate(let locale):
                    high = 1 << 1
                    low = UInt16(locale.rawIntValue)
                case .mvReleaseDate(let locale):
                    high = 1 << 2
                    low = UInt16(locale.rawIntValue)
                case .level(let difficulty):
                    high = 1 << 3
                    low = UInt16(difficulty.rawValue)
                case .rarity:
                    high = 1 << 4
                    low = 0
                case .maximumStat:
                    high = 1 << 5
                    low = 0
                case .id:
                    high = 1 << 6
                    low = 0
                }
                return UInt32(high) << 16 | UInt32(low)
            }
            
            /// Localized description text for keyword.
            @inline(never)
            public var localizedString: String {
                switch self {
                case .releaseDate(let locale):
                    String(localized: "FILTER_SORT_KEYWORD_RELEASE_DATE_IN_\(locale.rawValue.uppercased())", bundle: #bundle)
                case .difficultyReleaseDate(let locale):
                    String(localized: "FILTER_SORT_KEYWORD_DIFFICULTY_RELEASE_DATE_IN_\(locale.rawValue.uppercased())", bundle: #bundle)
                case .mvReleaseDate(in: let locale):
                    String(localized: "FILTER_SORT_KEYWORD_MV_RELEASE_DATE_IN_\(locale.rawValue.uppercased())", bundle: #bundle)
                case .level(let difficultyLevel):
                    String(localized: "FILTER_SORT_KEYWORD_LEVEL_FOR_\(difficultyLevel.rawStringValue.uppercased())", bundle: #bundle)
                case .rarity: String(localized: "FILTER_SORT_KEYWORD_RARITY", bundle: #bundle)
                case .maximumStat: String(localized: "FILTER_SORT_KEYWORD_MAXIMUM_STAT", bundle: #bundle)
                case .id: String(localized: "FILTER_SORT_KEYWORD_ID", bundle: #bundle)
                }
            }
            
            /// Localized description text for keyword.
            /// - Parameter hasEndingDate: A boolean value that indicates
            ///     whether the type has an ending date
            ///     (i.e. can be *removed*, *stopped*, or etc.)
            /// - Returns: A localized description text for keyword.
            public func localizedString(hasEndingDate: Bool = false) -> String {
                switch self {
                case .releaseDate(let locale):
                    hasEndingDate ? String(localized: "FILTER_SORT_KEYWORD_START_DATE_IN_\(locale.rawValue.uppercased())", bundle: #bundle) : String(localized: "FILTER_SORT_KEYWORD_RELEASE_DATE_IN_\(locale.rawValue.uppercased())", bundle: #bundle)
                case .difficultyReleaseDate(let locale):
                    String(localized: "FILTER_SORT_KEYWORD_DIFFICULTY_RELEASE_DATE_IN_\(locale.rawValue.uppercased())", bundle: #bundle)
                case .mvReleaseDate(let locale):
                    String(localized: "FILTER_SORT_KEYWORD_MV_RELEASE_DATE_IN_\(locale.rawValue.uppercased())", bundle: #bundle)
                case .level(let difficultyLevel):
                    String(localized: "FILTER_SORT_KEYWORD_LEVEL_FOR_\(difficultyLevel.rawStringValue.uppercased())", bundle: #bundle)
                case .rarity: String(localized: "FILTER_SORT_KEYWORD_RARITY", bundle: #bundle)
                case .maximumStat: String(localized: "FILTER_SORT_KEYWORD_MAXIMUM_STAT", bundle: #bundle)
                case .id: String(localized: "FILTER_SORT_KEYWORD_ID", bundle: #bundle)
                }
            }
        }
        
        /// Returns a localized name of given direction with keyword.
        /// - Parameters:
        ///   - keyword: The keyword for direction, nil to use the current one.
        ///   - direction: The direction, nil to use the current one.
        /// - Returns: A localized name of given direction with keyword.
        public func localizedDirectionName(keyword: Keyword? = nil, direction: Direction? = nil) -> String {
            let isAscending: Bool = (direction ?? self.direction) == .ascending
            switch keyword ?? self.keyword {
            case .releaseDate:
                return isAscending ? String(localized: "FILTER_SORT_ORDER_OLDEST_TO_NEWEST", bundle: #bundle) : String(localized: "FILTER_SORT_ORDER_NEWEST_TO_OLDEST", bundle: #bundle)
            case .difficultyReleaseDate:
                return isAscending ? String(localized: "FILTER_SORT_ORDER_OLDEST_TO_NEWEST", bundle: #bundle) : String(localized: "FILTER_SORT_ORDER_NEWEST_TO_OLDEST", bundle: #bundle)
            case .mvReleaseDate:
                return isAscending ? String(localized: "FILTER_SORT_ORDER_OLDEST_TO_NEWEST", bundle: #bundle) : String(localized: "FILTER_SORT_ORDER_NEWEST_TO_OLDEST", bundle: #bundle)
            case .level:
                return isAscending ? String(localized: "FILTER_SORT_ORDER_ASCENDING", bundle: #bundle) : String(localized: "FILTER_SORT_ORDER_DESCENDING", bundle: #bundle)
            case .rarity:
                return isAscending ? String(localized: "FILTER_SORT_ORDER_ASCENDING", bundle: #bundle) : String(localized: "FILTER_SORT_ORDER_DESCENDING", bundle: #bundle)
            case .maximumStat:
                return isAscending ? String(localized: "FILTER_SORT_ORDER_ASCENDING", bundle: #bundle) : String(localized: "FILTER_SORT_ORDER_DESCENDING", bundle: #bundle)
            case .id:
                return isAscending ? String(localized: "FILTER_SORT_ORDER_ASCENDING", bundle: #bundle) : String(localized: "FILTER_SORT_ORDER_DESCENDING", bundle: #bundle)
            }
        }
        
        // `nil` values will always be at the last.
        internal func compare<T: Comparable>(_ lhs: T?, _ rhs: T?) -> Bool {
            guard lhs != nil else { return false }
            guard rhs != nil else { return true }
            
            switch direction {
            case .ascending:
                return lhs! < rhs!
            case .descending:
                return lhs! > rhs!
            }
        }
    }
}

extension Set<DoriFrontend.Sorter.Keyword> {
    @inlinable
    public func sorted() -> [DoriFrontend.Sorter.Keyword] {
        self.sorted { $0.rawValue < $1.rawValue }
    }
}

// MARK: extension PreviewEvent
extension DoriAPI.Event.PreviewEvent: DoriFrontend.Sortable {
    @inlinable
    public static var applicableSortingTypes: [DoriFrontend.Sorter.Keyword] {
        [.releaseDate(in: .jp), .releaseDate(in: .en), .releaseDate(in: .tw), .releaseDate(in: .cn), .releaseDate(in: .kr), .id]
    }
    
    @inlinable
    public static var hasEndingDate: Bool { true }
    
    public static func _compare<ValueType>(usingDoriSorter sorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool? {
        guard let castedLHS = lhs as? DoriAPI.Event.PreviewEvent, let castedRHS = rhs as? DoriAPI.Event.PreviewEvent else { return nil }
        switch sorter.keyword {
        case .releaseDate(let locale):
            return sorter.compare(
                castedLHS.startAt.forLocale(locale),
                castedRHS.startAt.forLocale(locale)
            )
        case .id:
            return sorter.compare(castedLHS.id, castedRHS.id)
        default:
            return nil
        }
    }
}

// MARK: extension PreviewGacha
extension DoriAPI.Gacha.PreviewGacha: DoriFrontend.Sortable {
    @inlinable
    public static var applicableSortingTypes: [DoriFrontend.Sorter.Keyword] {
        [.releaseDate(in: .jp), .releaseDate(in: .en), .releaseDate(in: .tw), .releaseDate(in: .cn), .releaseDate(in: .kr), .id]
    }
    
    @inlinable
    public static var hasEndingDate: Bool { true }
    
    public static func _compare<ValueType>(usingDoriSorter sorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool? {
        guard let castedLHS = lhs as? DoriAPI.Gacha.PreviewGacha, let castedRHS = rhs as? DoriAPI.Gacha.PreviewGacha else { return nil }
        switch sorter.keyword {
        case .releaseDate(let locale):
            return sorter.compare(
                castedLHS.publishedAt.forLocale(locale),
                castedRHS.publishedAt.forLocale(locale)
            )
        case .id:
            return sorter.compare(castedLHS.id, castedRHS.id)
        default:
            return nil
        }
    }
}

// MARK: extension CardWithBand
extension DoriFrontend.Card.CardWithBand: DoriFrontend.Sortable {
    @inlinable
    public static var applicableSortingTypes: [DoriFrontend.Sorter.Keyword] {
        [.releaseDate(in: .jp), .releaseDate(in: .en), .releaseDate(in: .tw), .releaseDate(in: .cn), .releaseDate(in: .kr), .rarity, .maximumStat, .id]
    }
    
    @inlinable
    public static var hasEndingDate: Bool { false }
    
    public static func _compare<ValueType>(usingDoriSorter sorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool? {
        guard let castedLHS = lhs as? DoriFrontend.Card.CardWithBand, let castedRHS = rhs as? DoriFrontend.Card.CardWithBand else { return nil }
        switch sorter.keyword {
        case .releaseDate(let locale):
            return sorter.compare(
                castedLHS.card.releasedAt.forLocale(locale),
                castedRHS.card.releasedAt.forLocale(locale)
            )
        case .rarity:
            return sorter.compare(castedLHS.card.rarity, castedRHS.card.rarity)
        case .maximumStat:
            return sorter.compare(castedLHS.card.stat.maximumLevel, castedRHS.card.stat.maximumLevel)
        case .id:
            return sorter.compare(castedLHS.id, castedRHS.id)
        default:
            return nil
        }
    }
}

// MARK: extension PreviewCard
extension DoriFrontend.Card.PreviewCard: DoriFrontend.Sortable {
    @inlinable
    public static var applicableSortingTypes: [DoriFrontend.Sorter.Keyword] {
        [.releaseDate(in: .jp), .releaseDate(in: .en), .releaseDate(in: .tw), .releaseDate(in: .cn), .releaseDate(in: .kr), .rarity, .maximumStat, .id]
    }
    
    @inlinable
    public static var hasEndingDate: Bool { false }
    
    public static func _compare<ValueType>(usingDoriSorter sorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool? {
        guard let castedLHS = lhs as? DoriFrontend.Card.PreviewCard, let castedRHS = rhs as? DoriFrontend.Card.PreviewCard else { return nil }
        switch sorter.keyword {
        case .releaseDate(let locale):
            return sorter.compare(
                castedLHS.releasedAt.forLocale(locale),
                castedRHS.releasedAt.forLocale(locale)
            )
        case .rarity:
            return sorter.compare(castedLHS.rarity, castedRHS.rarity)
        case .maximumStat:
            return sorter.compare(castedLHS.stat.maximumLevel, castedRHS.stat.maximumLevel)
        case .id:
            return sorter.compare(castedLHS.id, castedRHS.id)
        default:
            return nil
        }
    }
}

// MARK: extension PreviewSong
extension DoriAPI.Song.PreviewSong: DoriFrontend.Sortable {
    @inlinable
    public static var applicableSortingTypes: [DoriFrontend.Sorter.Keyword] {
        [.releaseDate(in: .jp), .releaseDate(in: .en), .releaseDate(in: .tw), .releaseDate(in: .cn), .releaseDate(in: .kr), .difficultyReleaseDate(in: .jp), .difficultyReleaseDate(in: .en), .difficultyReleaseDate(in: .tw), .difficultyReleaseDate(in: .cn), .difficultyReleaseDate(in: .kr), .mvReleaseDate(in: .jp), .mvReleaseDate(in: .en), .mvReleaseDate(in: .tw), .mvReleaseDate(in: .cn), .mvReleaseDate(in: .kr), .level(for: .easy), .level(for: .normal), .level(for: .hard), .level(for: .expert), .level(for: .special), .id]
    }
    
    @inlinable
    public static var hasEndingDate: Bool { false }
    
    public static func _compare<ValueType>(usingDoriSorter sorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool? {
        guard let castedLHS = lhs as? DoriAPI.Song.PreviewSong, let castedRHS = rhs as? DoriAPI.Song.PreviewSong else { return nil }
        switch sorter.keyword {
        case .releaseDate(let locale):
            return sorter.compare(
                castedLHS.publishedAt.forLocale(locale),
                castedRHS.publishedAt.forLocale(locale)
            )
        case .difficultyReleaseDate(let locale):
            return sorter.compare(
                castedLHS.difficulty[.special]?.publishedAt?.forLocale(locale),
                castedRHS.difficulty[.special]?.publishedAt?.forLocale(locale)
            )
        case .mvReleaseDate(let locale):
            var finalReleaseDateForLHS: Date?
            var finalReleaseDateForRHS: Date?
            if let allMVDictForLHS = castedLHS.musicVideos {
                let mvListForLHS: [DoriAPI.Song.MusicVideoMetadata?] = Array(allMVDictForLHS.values)
                let mvDatesForLHS = mvListForLHS.compactMap{ $0?.startAt.forLocale(locale) }.sorted(by: <)
                finalReleaseDateForLHS = mvDatesForLHS.first
            } else {
                finalReleaseDateForLHS = nil
            }
            if let allMVDictForRHS = castedRHS.musicVideos {
                let mvListForRHS: [DoriAPI.Song.MusicVideoMetadata?] = Array(allMVDictForRHS.values)
                let mvDatesForRHS = mvListForRHS.compactMap{ $0?.startAt.forLocale(locale) }.sorted(by: <)
                finalReleaseDateForRHS = mvDatesForRHS.first
            } else {
                finalReleaseDateForRHS = nil
            }
            return sorter.compare(finalReleaseDateForLHS, finalReleaseDateForRHS)
        case .level(let difficulty):
            return sorter.compare(castedLHS.difficulty[difficulty]?.playLevel, castedRHS.difficulty[difficulty]?.playLevel)
        case .id:
            return sorter.compare(castedLHS.id, castedRHS.id)
        default:
            return nil
        }
    }
}

// MARK: extension PreviewCampaign
extension DoriAPI.LoginCampaign.PreviewCampaign: DoriFrontend.Sortable {
    @inlinable
    public static var applicableSortingTypes: [DoriFrontend.Sorter.Keyword] {
        [.releaseDate(in: .jp), .releaseDate(in: .en), .releaseDate(in: .tw), .releaseDate(in: .cn), .releaseDate(in: .kr), .id]
    }
    
    @inlinable
    public static var hasEndingDate: Bool { true }
    
    public static func _compare<ValueType>(usingDoriSorter sorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool? {
        guard let castedLHS = lhs as? DoriAPI.LoginCampaign.PreviewCampaign, let castedRHS = rhs as? DoriAPI.LoginCampaign.PreviewCampaign else { return nil }
        switch sorter.keyword {
        case .releaseDate(let locale):
            return sorter.compare(
                castedLHS.publishedAt.forLocale(locale),
                castedRHS.publishedAt.forLocale(locale)
            )
        case .id:
            return sorter.compare(castedLHS.id, castedRHS.id)
        default:
            return nil
        }
    }
}

// MARK: extension Comic
extension DoriAPI.Comic.Comic: DoriFrontend.Sortable {
    @inlinable
    public static var applicableSortingTypes: [DoriFrontend.Sorter.Keyword] {
        [.id]
    }
    
    @inlinable
    public static var hasEndingDate: Bool { false }
    
    public static func _compare<ValueType>(usingDoriSorter sorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool? {
        guard let castedLHS = lhs as? DoriAPI.Comic.Comic, let castedRHS = rhs as? DoriAPI.Comic.Comic else { return nil }
        switch sorter.keyword {
//        case .releaseDate(let locale):
//            return sorter.compare(
//                castedLHS.publicStartAt.forLocale(locale),
//                castedRHS.publicStartAt.forLocale(locale)
//            )
        case .id:
            return sorter.compare(castedLHS.id, castedRHS.id)
        default:
            return nil
        }
    }
}


// MARK: extension PreviewCostume
extension DoriFrontend.Costume.PreviewCostume: DoriFrontend.Sortable {
    @inlinable
    public static var applicableSortingTypes: [DoriFrontend.Sorter.Keyword] {
        [.releaseDate(in: .jp), .releaseDate(in: .en), .releaseDate(in: .tw), .releaseDate(in: .cn), .releaseDate(in: .kr), .id]
    }
    
    @inlinable
    public static var hasEndingDate: Bool { false }
    
    public static func _compare<ValueType>(usingDoriSorter sorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool? {
        guard let castedLHS = lhs as? DoriFrontend.Costume.PreviewCostume, let castedRHS = rhs as? DoriFrontend.Costume.PreviewCostume else { return nil }
        switch sorter.keyword {
        case .releaseDate(let locale):
            return sorter.compare(
                castedLHS.publishedAt.forLocale(locale),
                castedRHS.publishedAt.forLocale(locale)
            )
        case .id:
            return sorter.compare(castedLHS.id, castedRHS.id)
        default:
            return nil
        }
    }
}

// MARK: extension PreviewCharacter
extension DoriFrontend.Character.PreviewCharacter: DoriFrontend.Sortable {
    @inlinable
    public static var applicableSortingTypes: [DoriFrontend.Sorter.Keyword] {
        [.id]
    }
    
    @inlinable
    public static var hasEndingDate: Bool { false }
    
    public static func _compare<ValueType>(usingDoriSorter sorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool? {
        guard let castedLHS = lhs as? DoriFrontend.Character.PreviewCharacter, let castedRHS = rhs as? DoriFrontend.Character.PreviewCharacter else { return nil }
        switch sorter.keyword {
        case .id:
            return sorter.compare(castedLHS.id, castedRHS.id)
        default:
            return nil
        }
    }
}

// MARK: extension Array
extension Array where Element: DoriFrontend.Sortable {
    public func sorted(withDoriSorter sorter: DoriFrontend.Sorter) -> [Element] {
        var result: [Element] = self
        result = result.sorted {
            Element._compare(usingDoriSorter: sorter, lhs: $0, rhs: $1) ?? false
        }
        return result
    }
}
