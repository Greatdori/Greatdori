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

extension DoriFrontend {
    public protocol Sortable {
        static var applicableTypes: [DoriFrontend.Sorter.Keyword] { get }
        static func _compare<ValueType>(usingDoriSorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool?
    }
    
    public struct Sorter: Sendable, Equatable, Hashable, Codable {
        public var direction: Direction
        public var keyword: Keyword
        
        public init(direction: Direction, keyword: Keyword) {
            self.direction = direction
            self.keyword = keyword
        }
        
        @frozen
        public enum Direction: Equatable, Hashable, Codable {
            case ascending
            case descending
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
                case .mvReleaseDate(in: let locale):
                    String(localized: "FILTER_SORT_KEYWORD_MV_RELEASE_DATE_IN_\(locale.rawValue.uppercased())", bundle: #bundle)
                case .level(let difficultyLevel):
                    String(localized: "FILTER_SORT_KEYWORD_LEVEL_FOR_\(difficultyLevel.rawStringValue.uppercased())", bundle: #bundle)
                case .rarity: String(localized: "FILTER_SORT_KEYWORD_RARITY", bundle: #bundle)
                case .maximumStat: String(localized: "FILTER_SORT_KEYWORD_MAXIMUM_STAT", bundle: #bundle)
                case .id: String(localized: "FILTER_SORT_KEYWORD_ID", bundle: #bundle)
                }
            }
        }
        
        internal func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> Bool {
            switch direction {
            case .ascending: lhs < rhs
            case .descending: lhs > rhs
            }
        }
    }
}

// MARK: extension PreviewEvent
extension DoriAPI.Event.PreviewEvent: DoriFrontend.Sortable {
    @inlinable
    public static var applicableTypes: [DoriFrontend.Sorter.Keyword] {
        [.releaseDate(in: .jp), .releaseDate(in: .en), .releaseDate(in: .tw), .releaseDate(in: .cn), .releaseDate(in: .kr), .id]
    }
    
    public static func _compare<ValueType>(usingDoriSorter sorter: DoriFrontend.Sorter, lhs: ValueType, rhs: ValueType) -> Bool? {
        guard let castedLHS = lhs as? DoriAPI.Event.PreviewEvent, let castedRHS = rhs as? DoriAPI.Event.PreviewEvent else { return nil }
        switch sorter.keyword {
        case .releaseDate(let locale):
            return sorter.compare(
                castedLHS.startAt.forLocale(locale) ?? castedLHS.startAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0),
                castedRHS.startAt.forLocale(locale) ?? castedRHS.startAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)
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
            Element._compare(usingDoriSorter: sorter, lhs: $0, rhs: $1) ?? true
        }
        return result
    }
}
