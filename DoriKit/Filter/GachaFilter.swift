//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaFilter.swift
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

public struct GachaFilter {
    public var attribute: Set<DoriAPI.Attribute> = .init(DoriAPI.Attribute.allCases)
    public var character: Set<DoriFilterCharacter> = .init(DoriFilterCharacter.allCases)
    public var characterRequiresMatchAll: Bool = false
    public var server: Set<DoriAPI.Locale> = .init(DoriAPI.Locale.allCases)
    public var released: Set<Bool> = [false, true]
    public var type: Set<DoriAPI.Gacha.GachaType> = .init(DoriAPI.Gacha.GachaType.allCases)
    public var timelineStatus: Set<DoriFilterTimelineStatus> = .init(DoriFilterTimelineStatus.allCases)
    
    public init() {}
    public init(
        attribute: Set<DoriAPI.Attribute>,
        character: Set<DoriFilterCharacter>,
        characterRequiresMatchAll: Bool,
        server: Set<DoriAPI.Locale>,
        released: Set<Bool>,
        type: Set<DoriAPI.Gacha.GachaType>,
        timelineStatus: Set<DoriFilterTimelineStatus>
    ) {
        self.attribute = attribute
        self.character = character
        self.characterRequiresMatchAll = characterRequiresMatchAll
        self.server = server
        self.released = released
        self.type = type
        self.timelineStatus = timelineStatus
    }
}

extension GachaFilter: DoriFilter {
    public typealias Element = DoriAPI.Gacha.PreviewGacha
    public func filter(_ elements: [Element]) -> [Element] {
        guard self.isFiltered else { return elements }
        guard let cards = FilterCacheManager.shared.read().cardsList else { return elements }
        
        return elements.filter {
            self.type.contains($0.type)
        }.filter { gacha in
            if self.attribute == Set(DoriAPI.Attribute.allCases) {
                return true
            }
            let cards = cards.filter { gacha.newCards.contains($0.id) }
            return self.attribute.contains { cards.map { $0.attribute }.contains($0) }
        }.filter { gacha in
            if self.character == Set(DoriFilterCharacter.allCases) {
                return true
            }
            let cards = cards.filter { gacha.newCards.contains($0.id) }
            if self.characterRequiresMatchAll {
                return self.character.allSatisfy { cards.map { $0.characterID }.contains($0.rawValue) }
            } else {
                return self.character.contains { cards.map { $0.characterID }.contains($0.rawValue) }
            }
        }.filter { gacha in
            for status in self.released {
                for locale in self.server {
                    if status {
                        if (gacha.publishedAt.forLocale(locale) ?? dateOfYear2100) < .now {
                            return true
                        }
                    } else {
                        if (gacha.publishedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 0)) > .now {
                            return true
                        }
                    }
                }
            }
            return false
        }.filter { gacha in
            for timelineStatus in self.timelineStatus {
                let result = switch timelineStatus {
                case .ended:
                    (gacha.closedAt.forPreferredLocale() ?? dateOfYear2100) < .now
                case .ongoing:
                    (gacha.publishedAt.forPreferredLocale() ?? dateOfYear2100) < .now
                    && (gacha.closedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)) > .now
                case .upcoming:
                    (gacha.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)) > .now
                }
                if result {
                    return true
                }
            }
            return false
        }
    }
    
    public enum Key: Int, DoriFilterKey {
        case attribute
        case character
        case characterRequiresMatchAll
        case server
        case type
        case timelineStatus
        
        public var localizedString: String {
            switch self {
            case .attribute: String(localized: "FILTER_KEY_ATTRIBUTE", bundle: #bundle)
            case .character: String(localized: "FILTER_KEY_CHARACTER", bundle: #bundle)
            case .characterRequiresMatchAll: String(localized: "FILTER_KEY_CHARACTER_REQUIRES_MATCH_ALL", bundle: #bundle)
            case .server: String(localized: "FILTER_KEY_SERVER", bundle: #bundle)
            case .type: String(localized: "FILTER_KEY_GACHA_TYPE", bundle: #bundle)
            case .timelineStatus: String(localized: "FILTER_KEY_TIMELINE_STATUS", bundle: #bundle)
            }
        }
    }
}
