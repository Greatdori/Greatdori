//===---*- Greatdori! -*---------------------------------------------------===//
//
// MatchedFilters.swift
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
internal import os

extension DoriFrontend {
    public protocol Filterable {
        static var applicableKeys: [DoriFrontend.Filter.Key] { get }
        
        // `matches` only handle single value.
        // Please keep in mind that it does handle values like any `Array` or `characterRequiresMatchAll`.
        // Unexpected value type or cache reading failure will lead to `nil` return.
        func _matches<ValueType>(_ value: ValueType, withCache: _FilterCache?) -> Bool?
    }
    
    public struct _FilterCache {
        fileprivate var cardsList: [DoriAPI.Card.PreviewCard]?
        fileprivate var cardsDict: [Int: DoriAPI.Card.PreviewCard] = [:]
        fileprivate var bandsList: [DoriAPI.Band.Band]?
        fileprivate var charactersList: [DoriAPI.Character.PreviewCharacter]?
    }
}

// MARK: - Supporting Types
private struct TimelineStatusWithServers {
    fileprivate let timelineStatus: DoriFrontend.Filter.TimelineStatus
    fileprivate let servers: Set<DoriFrontend.Filter.Server>
}

private struct AvailabilityWithServers: Equatable {
    fileprivate let releaseStatus: DoriFrontend.Filter.ReleaseStatus
    fileprivate let servers: Set<DoriFrontend.Filter.Server>
}

private func plainBandID(from bandID: Int) -> Int {
    if [1, 2, 3, 4, 5, 18, 21, 45].contains(bandID) {
        return bandID
    } else {
        return -1
    }
}

// MARK: - Filter Cache Manager
internal final class FilterCacheManager: Sendable {
    internal static let shared = FilterCacheManager()
    
    nonisolated(unsafe) private var allCache = DoriFrontend._FilterCache()
    private let lock = NSLock()
    
    internal func writeCardCache(_ cardsList: [DoriAPI.Card.PreviewCard]?) {
        lock.lock()
        defer { lock.unlock() }
        if cardsList != nil {
            unsafe allCache.cardsList = cardsList
            unsafe allCache.cardsDict.removeAll()
            if let cards = cardsList {
                for card in cards {
                    unsafe allCache.cardsDict[card.id] = card
                }
            }
        }
    }
    
    internal func writeBandsList(_ bandsList: [DoriAPI.Band.Band]?) {
        lock.lock()
        defer { lock.unlock() }
        if bandsList != nil {
            unsafe allCache.bandsList = bandsList
        }
    }
    
    internal func writeCharactersList(_ charactersList: [DoriAPI.Character.PreviewCharacter]?) {
        lock.lock()
        defer { lock.unlock() }
        if charactersList != nil {
            unsafe allCache.charactersList = charactersList
        }
    }
    
    internal func read() -> DoriFrontend._FilterCache {
        lock.lock()
        defer { lock.unlock() }
        return unsafe allCache
    }
    
    internal func erase() {
        lock.lock()
        defer { lock.unlock() }
        unsafe allCache = .init()
    }
}

// MARK: extension PreviewEvent
// Attribute, Character, Server, Timeline Status, Event Type
extension DoriAPI.Event.PreviewEvent: DoriFrontend.Filterable {
    @inlinable
    public static var applicableKeys: [DoriFrontend.Filter.Key] {
        [.attribute, .character, .characterRequiresMatchAll, .server, .timelineStatus, .eventType]
    }
    
    public func _matches<ValueType>(_ value: ValueType, withCache: DoriFrontend._FilterCache? = nil) -> Bool? {
        if let attribute = value as? DoriFrontend.Filter.Attribute { // Attribute
            return self.attributes.contains { $0.attribute == attribute }
        } else if let character = value as? DoriFrontend.Filter.Character { // Character
            return self.characters.contains { $0.characterID == character.rawValue }
        } else if let server = value as? DoriFrontend.Filter.Server { // Server
            return self.startAt.availableInLocale(server)
        } else if let timelineStatusWithServers = value as? TimelineStatusWithServers { // Timeline Status with Servers
            switch timelineStatusWithServers.timelineStatus {
            case .ended:
                for singleLocale in timelineStatusWithServers.servers {
                    if (self.endAt.forLocale(singleLocale) ?? dateOfYear2100) < .now {
                        return true
                    }
                }
            case .ongoing:
                for singleLocale in timelineStatusWithServers.servers {
                    if (self.startAt.forLocale(singleLocale) ?? dateOfYear2100) < .now
                        && (self.endAt.forLocale(singleLocale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        return true
                    }
                }
            case .upcoming:
                for singleLocale in timelineStatusWithServers.servers {
                    if (self.startAt.forLocale(singleLocale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        return true
                    }
                }
            }
            return false
        } else if let eventType = value as? DoriFrontend.Filter.EventType { // Event Type
            return self.eventType == eventType
        } else {
            return nil // Unexpected: unexpected value type
        }
    }
}

// MARK: extension PreviewGacha
// Attribute, Character, Server, Timeline Status, Gacha Type
// Filter Cache Required
extension DoriAPI.Gacha.PreviewGacha: DoriFrontend.Filterable {
    @inlinable
    public static var applicableKeys: [DoriFrontend.Filter.Key] {
        [.attribute, .character, .characterRequiresMatchAll, .server, .timelineStatus, .gachaType]
    }
    
    public func _matches<ValueType>(_ value: ValueType, withCache cache: DoriFrontend._FilterCache?) -> Bool? {
        if let attribute = value as? DoriFrontend.Filter.Attribute { // Attribute
            guard let cards = cache?.cardsDict else {
                unsafe os_log("[Filter][Gacha] Found `nil` while trying to read card cache.")
                return nil
            }
            let containingAttributes = self.newCards.compactMap { cards[$0]?.attribute }
            return containingAttributes.contains(attribute)
        } else if let character = value as? DoriFrontend.Filter.Character { // Character
            guard let cards = cache?.cardsDict else {
                unsafe os_log("[Filter][Gacha] Found `nil` while trying to read card cache.")
                return nil
            }
            let containingCharacterIDs = self.newCards.compactMap { cards[$0]?.characterID }
            return containingCharacterIDs.contains(character.rawValue)
        } else if let server = value as? DoriFrontend.Filter.Server { // Server
            return (self.publishedAt.forLocale(server) ?? dateOfYear2100) < .now
        } else if let timelineStatusWithServers = value as? TimelineStatusWithServers { // Timeline Status with Servers
            switch timelineStatusWithServers.timelineStatus {
            case .ended:
                for singleLocale in timelineStatusWithServers.servers {
                    if (self.closedAt.forLocale(singleLocale) ?? dateOfYear2100) < .now {
                        return true
                    }
                }
            case .ongoing:
                for singleLocale in timelineStatusWithServers.servers {
                    if (self.publishedAt.forLocale(singleLocale) ?? dateOfYear2100) < .now
                        && (self.closedAt.forLocale(singleLocale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        return true
                    }
                }
            case .upcoming:
                for singleLocale in timelineStatusWithServers.servers {
                    if (self.publishedAt.forLocale(singleLocale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        return true
                    }
                }
            }
            return false
        } else if let gachaType = value as? DoriFrontend.Filter.GachaType { // Gacha Type
            return self.type == gachaType
        } else {
            return nil // Unexpected: unexpected value type
        }
    }
}

// MARK: extension CardWithBand
// Band, Attribute, Rarity, Character, Server, Availability, Card Type, Skill
extension DoriFrontend.Card.CardWithBand: DoriFrontend.Filterable {
    @inlinable
    public static var applicableKeys: [DoriFrontend.Filter.Key] {
        [.band, .attribute, .rarity, .character, .server, .released, .cardType, .skill]
    }
    
    public func _matches<ValueType>(_ value: ValueType, withCache cache: DoriFrontend._FilterCache?) -> Bool? { // Band
        if let band = value as? DoriFrontend.Filter.FullBand { // Band - Full
            return plainBandID(from: self.band.id) == band.rawValue
        } else if let attribute = value as? DoriFrontend.Filter.Attribute { // Attribute
            return self.card.attribute.rawValue.contains(attribute.rawValue)
        } else if let rarity = value as? DoriFrontend.Filter.Rarity { // Rarity
            return self.card.rarity == rarity
        } else if let character = value as? DoriFrontend.Filter.Character { // Character
            return self.card.characterID == character.rawValue
        } else if let server = value as? DoriFrontend.Filter.Server { // Server
            return self.card.prefix.availableInLocale(server)
        } else if let availabilityWithServers = value as? AvailabilityWithServers { // Availability
            for locale in availabilityWithServers.servers {
                if availabilityWithServers.releaseStatus.boolValue {
                    if (self.card.releasedAt.forLocale(locale) ?? dateOfYear2100) < .now {
                        return true
                    }
                } else {
                    if (self.card.releasedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        return true
                    }
                }
            }
            return false
        } else if let cardType = value as? DoriFrontend.Filter.CardType { // Card Type
            return self.card.type == cardType
        } else if let skill = value as? DoriFrontend.Filter.Skill { // Skill
            return self.card.skillID == skill.id
        } else {
            return nil // Unexpected: unexpected value type
        }
    }
}

// MARK: extension PreviewSong
// Band, Server, Timeline Status, Song Type, Level
extension DoriAPI.Song.PreviewSong: DoriFrontend.Filterable {
    @inlinable
    public static var applicableKeys: [DoriFrontend.Filter.Key] {
        [.band, .server, .timelineStatus, .songType, .level]
    }
    
    public func _matches<ValueType>(_ value: ValueType, withCache cache: DoriFrontend._FilterCache?) -> Bool? {
        if let band = value as? DoriFrontend.Filter.FullBand { // Band - Full
            return plainBandID(from: self.bandID) == band.rawValue
        } else if let server = value as? DoriFrontend.Filter.Server { // Server
            return (self.publishedAt.forLocale(server) ?? dateOfYear2100) < .now
        } else if let timelineStatusWithServers = value as? TimelineStatusWithServers { // Timeline Status
            switch timelineStatusWithServers.timelineStatus {
            case .ended:
                for singleLocale in timelineStatusWithServers.servers {
                    if (self.closedAt.forLocale(singleLocale) ?? dateOfYear2100) < .now {
                        return true
                    }
                }
            case .ongoing:
                for singleLocale in timelineStatusWithServers.servers {
                    if (self.publishedAt.forLocale(singleLocale) ?? dateOfYear2100) < .now
                        && (self.closedAt.forLocale(singleLocale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        return true
                    }
                }
            case .upcoming:
                for singleLocale in timelineStatusWithServers.servers {
                    if (self.publishedAt.forLocale(singleLocale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        return true
                    }
                }
            }
            return false
        } else if let songType = value as? DoriFrontend.Filter.SongType { // Song Type
            return self.tag == songType
        } else if let level = value as? DoriFrontend.Filter.Level { // Level
            return self.difficulty.contains(where: { $0.value.playLevel == level })
        } else {
            return nil // Unexpected: unexpected value type
        }
    }
}

// MARK: extension PreivewCampaign
// Server, Timeline Status, Login Campaign Type
extension DoriAPI.LoginCampaign.PreviewCampaign: DoriFrontend.Filterable {
    @inlinable
    public static var applicableKeys: [DoriFrontend.Filter.Key] {
        [.server, .timelineStatus, .loginCampaignType]
    }
    
    public func _matches<ValueType>(_ value: ValueType, withCache: DoriFrontend._FilterCache?) -> Bool? {
        if let server = value as? DoriFrontend.Filter.Server { // Server
            return self.publishedAt.availableInLocale(server)
        } else if let timelineStatusWithServers = value as? TimelineStatusWithServers { // Timeline Status with Servers
            switch timelineStatusWithServers.timelineStatus {
            case .ended:
                for singleLocale in timelineStatusWithServers.servers {
                    if (self.closedAt.forLocale(singleLocale) ?? dateOfYear2100) < .now {
                        return true
                    }
                }
            case .ongoing:
                for singleLocale in timelineStatusWithServers.servers {
                    if (self.publishedAt.forLocale(singleLocale) ?? dateOfYear2100) < .now
                        && (self.closedAt.forLocale(singleLocale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        return true
                    }
                }
            case .upcoming:
                for singleLocale in timelineStatusWithServers.servers {
                    if (self.publishedAt.forLocale(singleLocale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        return true
                    }
                }
            }
            return false
        } else if let campaignType = value as? DoriFrontend.Filter.LoginCampaignType { // Login Campaign Type
            return self.loginBonusType.rawValue == campaignType.rawValue
        } else {
            return nil 
        }
    }
}

// MARK: extension Comic
// Character, Server, Comic Type
extension DoriAPI.Comic.Comic: DoriFrontend.Filterable {
    @inlinable
    public static var applicableKeys: [DoriFrontend.Filter.Key] {
        [.character, .characterRequiresMatchAll, .server, .comicType]
    }
    
    public func _matches<ValueType>(_ value: ValueType, withCache: DoriFrontend._FilterCache?) -> Bool? {
        if let character = value as? DoriFrontend.Filter.Character { // Character
            return self.characterIDs.contains(character.rawValue)
        } else if let server = value as? DoriFrontend.Filter.Server { // Server
            return self.publicStartAt.availableInLocale(server)
        } else if let comicType = value as? DoriFrontend.Filter.ComicType { // Comic Type
            return self.type == comicType
        } else {
            return nil // Unexpected: unexpected value type
        }
    }
}

// MARK: extension PreviewCostume
// Band, Character, Server, Availability
// Filter Cache Required
extension DoriFrontend.Costume.PreviewCostume: DoriFrontend.Filterable {
    @inlinable
    public static var applicableKeys: [DoriFrontend.Filter.Key] {
        [.band, .character, .server, .released]
    }
    
    public func _matches<ValueType>(_ value: ValueType, withCache cache: DoriFrontend._FilterCache?) -> Bool? {
        if let band = value as? DoriFrontend.Filter.FullBand { // Band - Full
            guard let characters = cache?.charactersList else {
                unsafe os_log("[Filter][Costume] Found `nil` while trying to read characters cache.")
                return nil
            }
            return band.rawValue == characters.first(where: { $0.id == self.characterID })?.bandID
        } else if let character = value as? DoriFrontend.Filter.Character { // Character
            return self.characterID == character.rawValue
        } else if let server = value as? DoriFrontend.Filter.Server { // Server
            return self.description.availableInLocale(server)
        } else if let availabilityWithServers = value as? AvailabilityWithServers { // Availability
            for locale in availabilityWithServers.servers {
                if availabilityWithServers.releaseStatus.boolValue {
                    if (self.publishedAt.forLocale(locale) ?? dateOfYear2100) < .now {
                        return true
                    }
                } else {
                    if (self.publishedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        return true
                    }
                }
            }
            return false
        } else {
            return nil 
        }
    }
}

// MARK: extension Array
extension Array where Element: DoriFrontend.Filterable {
    public func filter(withDoriFilter filter: DoriFrontend.Filter) -> [Element] {
        var result: [Element] = self
        guard filter.isFiltered else { return result }
        let cacheCopy: DoriFrontend._FilterCache = FilterCacheManager.shared.read()
        
        // Breaking them up for type-check. Annoying. --@ThreeManager785
        result = result.filter { element in // Band
            guard (filter.band != Set(DoriFrontend.Filter.Band.allCases) || filter.bandMatchesOthers == .excludeOthers) else { return true }
            var allBands: Set<DoriFrontend.Filter.FullBand> = Set(filter.band.map({$0.asFullBand()}))
            if filter.bandMatchesOthers == .includeOthers {
                allBands.insert(.others)
            }
            return allBands.contains { band in
                element._matches(band, withCache: cacheCopy) ?? true
            }
        }.filter { element in // Attribute
            guard filter.attribute != Set(DoriFrontend.Filter.Attribute.allCases) else { return true }
            return filter.attribute.contains { attribute in
                element._matches(attribute, withCache: cacheCopy) ?? true
            }
        }.filter { element in // Rarity
            guard filter.rarity != Set([1, 2, 3, 4, 5]) else { return true }
            return filter.rarity.contains { rarity in
                element._matches(rarity, withCache: cacheCopy) ?? true
            }
        }.filter { element in // Character
            if filter.characterRequiresMatchAll {
                return filter.character.allSatisfy { character in
                    element._matches(character, withCache: cacheCopy) ?? true
                }
            } else {
                guard filter.character != Set(DoriFrontend.Filter.Character.allCases) else { return true }
                return filter.character.contains { character in
                    element._matches(character, withCache: cacheCopy) ?? true
                }
            }
        }
        result = result.filter { element in // Timeline Status with Servers
            guard filter.timelineStatus != Set(DoriFrontend.Filter.TimelineStatus.allCases) else { return true }
            return filter.timelineStatus.contains { timelineStatus in
                element._matches(TimelineStatusWithServers(timelineStatus: timelineStatus, servers: filter.server), withCache: cacheCopy) ?? true
            }
        }.filter { element in // Availability with Servers
            guard filter.released != Set([true, false]) else { return true }
            return filter.released.contains { releaseStatus in
                element._matches(AvailabilityWithServers(releaseStatus: releaseStatus, servers: filter.server), withCache: cacheCopy) ?? true
            }
        }
        result = result.filter { element in // Server
            guard filter.server != Set(DoriFrontend.Filter.Server.allCases) else { return true }
            return filter.server.contains { server in
                element._matches(server, withCache: cacheCopy) ?? true
            }
        }.filter { element in // Event Types
            guard filter.eventType != Set(DoriFrontend.Filter.EventType.allCases) else { return true }
            return filter.eventType.contains { eventType in
                element._matches(eventType, withCache: cacheCopy) ?? true
            }
        }.filter { element in // Gacha Types
            guard filter.gachaType != Set(DoriFrontend.Filter.GachaType.allCases) else { return true }
            return filter.gachaType.contains { gachaType in
                element._matches(gachaType, withCache: cacheCopy) ?? true
            }
        }.filter { element in // Card Types
            guard filter.cardType != Set(DoriFrontend.Filter.CardType.allCases) else { return true }
            return filter.cardType.contains { cardType in
                element._matches(cardType, withCache: cacheCopy) ?? true
            }
        }.filter { element in // Song Types
            guard filter.songType != Set(DoriFrontend.Filter.SongType.allCases) else { return true }
            return filter.songType.contains { songType in
                element._matches(songType, withCache: cacheCopy) ?? true
            }
        }.filter { element in // Login Campaign Types
            guard filter.loginCampaignType != Set(DoriFrontend.Filter.LoginCampaignType.allCases) else { return true }
            return filter.loginCampaignType.contains { loginCampaignType in
                element._matches(loginCampaignType, withCache: cacheCopy) ?? true
            }
        }.filter { element in // Comic Types
            guard filter.comicType != Set(DoriFrontend.Filter.ComicType.allCases) else { return true }
            return filter.comicType.contains { comicType in
                element._matches(comicType, withCache: cacheCopy) ?? true
            }
        }
        result = result.filter { element in // Skill
            guard filter.skill != nil else { return true }
            return element._matches(filter.skill, withCache: cacheCopy) ?? true
        }.filter { element in // Level
            guard filter.level != nil else { return true }
            return element._matches(filter.level, withCache: cacheCopy) ?? true
        }
        return result
    }
}
