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

// MARK: extension DoriFrontend
extension DoriFrontend {
    public protocol Sortable {
        static var applicableSortingTypes: [DoriFrontend.Sorter.Keyword] { get }
        static var hasEndingDate: Bool { get }
        static func _compare<ValueType>(usingDoriSorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool?
    }
    
    public struct Sorter: Sendable, Equatable, Hashable, Codable {
        public var direction: Direction
        public var keyword: Keyword
        
        public init(direction: Direction = .descending, keyword: Keyword = .id) {
            self.direction = direction
            self.keyword = keyword
        }
        
        @frozen
        public enum Direction: String, Equatable, Hashable, Codable {
            case ascending = "ascending"
            case descending = "descending"
            
            public var reversed: Self {
                switch self {
                case .ascending: .descending
                case .descending: .ascending
                }
            }
            
            public mutating func reverse() {
                self = self.reversed
            }
        }
        public enum Keyword: CaseIterable, Sendable, Equatable, Hashable, Codable {
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
        
        public func getLocalizedSortingDirectionName(keyword: Keyword? = nil, direction: Direction? = nil) -> String {
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
            case .id: String(localized: "FILTER_SORT_KEYWORD_ID", bundle: #bundle)
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
