//===---*- Greatdori! -*---------------------------------------------------===//
//
// FiltersExp.swift
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
import Playgrounds
internal import os

//MARK: [IMPORTANT] This file has incorrect internal protection settings. Check ALL before merging.
// The message above should be removed before merging into `main`.

extension DoriFrontend {
    //MARK: protocol Filterable
    public protocol Filterable {
        func matches<ValueType>(_ value: ValueType, withFilterCache: FilterCache?) -> Bool?
        // `matches` only handle single value.
        // Please keep in mind that it does handle values like any `Array` or `characterRequiresMatchAll`.
        // Unexpected value type or cache reading failure will lead to `nil` return.
    }
    
    //MARK: class FilterCacheManager
    final class FilterCacheManager: Sendable {
        static let shared = FilterCacheManager()
        
        nonisolated(unsafe) private var allCache: FilterCache = FilterCache()
        private let lock = NSLock()
        
        func read() -> FilterCache {
            lock.lock()
            defer { lock.unlock() }
            return unsafe allCache
        }
        
        func writeCardCache(_ cardsList: [DoriAPI.Card.PreviewCard]?) {
            lock.lock()
            defer { lock.unlock() }
            unsafe allCache.cardsList = cardsList
            unsafe allCache.cardsDict.removeAll()
            if let cards = cardsList {
                for card in cards {
                    unsafe allCache.cardsDict[card.id] = card
                }
            }
            
        }
        
        func writeBandsList(_ bandsList: [DoriAPI.Band.Band]?) {
            lock.lock()
            defer { lock.unlock() }
            unsafe allCache.bandsList = bandsList
        }
        
        func writeCharactersList(_ charactersList: [DoriAPI.Character.PreviewCharacter]?) {
            lock.lock()
            defer { lock.unlock() }
            unsafe allCache.charactersList = charactersList
        }
    }
    
    public struct FilterCache {
        var cardsList: [DoriAPI.Card.PreviewCard]?
        var cardsDict: [Int: DoriAPI.Card.PreviewCard] = [:]
        var bandsList: [DoriAPI.Band.Band]?
        var charactersList: [DoriAPI.Character.PreviewCharacter]?
    }
    
    public struct TimelineStatusWithServers {
        let timelineStatus: DoriFrontend.Filter.TimelineStatus
        let servers: Set<DoriFrontend.Filter.Server>
    }
    
    public struct AvailabilityWithServers: Equatable {
        let releaseStatus: DoriFrontend.Filter.ReleaseStatus
        let servers: Set<DoriFrontend.Filter.Server>
    }
}


//MARK: extension PreviewEvent
// Attribute, Character, Server, Timeline Status, Event Type
// Filter Cache Not Required
extension DoriAPI.Event.PreviewEvent {
    public func matches<ValueType>(_ value: ValueType, withFilterCache: DoriFrontend.FilterCache? = nil) -> Bool? {
        if let attribute = value as? DoriFrontend.Filter.Attribute { // Attribute
            return self.attributes.contains { $0.attribute == attribute }
        } else if let character = value as? DoriFrontend.Filter.Character { // Character
            return self.characters.contains { $0.characterID == character.rawValue }
        } else if let server = value as? DoriFrontend.Filter.Server { // Server
            return self.startAt.availableInLocale(server)
        } else if let timelineStatusWithServers = value as? DoriFrontend.TimelineStatusWithServers { // Timeline Status with Servers
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

//MARK: extension PreviewGacha
// Attribute, Character, Server, Timeline Status, Gacha Type
// Filter Cache Required
extension DoriAPI.Gacha.PreviewGacha {
    public func matches<ValueType>(_ value: ValueType, withFilterCache cache: DoriFrontend.FilterCache?) -> Bool? {
        if let attribute = value as? DoriFrontend.Filter.Attribute { // Attribute
            guard let cards = cache?.cardsDict else {
                os_log("[Filter][Gacha] Found `nil` while trying to read card cache.")
                return nil
            }
            let containingAttributes = self.newCards.compactMap { cards[$0]?.attribute }
            return containingAttributes.contains(attribute)
        } else if let character = value as? DoriFrontend.Filter.Character { // Character
            guard let cards = cache?.cardsDict else {
                os_log("[Filter][Gacha] Found `nil` while trying to read card cache.")
                return nil
            }
            let containingCharacterIDs = self.newCards.compactMap { cards[$0]?.characterID }
            return containingCharacterIDs.contains(character.rawValue)
        } else if let server = value as? DoriFrontend.Filter.Server { // Server
            return (self.publishedAt.forLocale(server) ?? dateOfYear2100) < .now
        } else if let timelineStatusWithServers = value as? DoriFrontend.TimelineStatusWithServers { // Timeline Status with Servers
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

//MARK: extension CardWithBand
// Band, Attribute, Rarity, Character, Server, Availability, Card Type
// Filter Cache Required
extension DoriFrontend.Card.CardWithBand {
    public func matches<ValueType>(_ value: ValueType, withFilterCache cache: DoriFrontend.FilterCache?) -> Bool? { // Band
        if let band = value as? DoriFrontend.Filter.Band {
            guard let characters = cache?.charactersList else {
                os_log("[Filter][Gacha] Found `nil` while trying to read card cache.")
                return nil
            }
            return self.band.id == band.rawValue
        } else if let attribute = value as? DoriFrontend.Filter.Attribute { // Attribute
            return self.card.attribute.rawValue.contains(attribute.rawValue)
        } else if let rarity = value as? DoriFrontend.Filter.Rarity { // Rarity
            return self.card.rarity == rarity
        } else if let character = value as? DoriFrontend.Filter.Character { // Character
            return self.card.characterID == character.rawValue
        } else if let server = value as? DoriFrontend.Filter.Server { // Server
            return self.card.prefix.availableInLocale(server)
        } else if let availabilityWithServers = value as? DoriFrontend.AvailabilityWithServers { // Availability
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
        } else if let skill = value as? DoriFrontend.Filter.Skill {
            return self.card.skillID == skill.id
        } else {
            return nil // Unexpected: unexpected value type
        }
    }
}

public extension Array where Element: DoriFrontend.Filterable {
    public func filterByDori(with filter: DoriFrontend.Filter) -> [Element] {
        var result: [Element] = self
        guard filter.isFiltered else { return result }
        let cacheCopy: DoriFrontend.FilterCache = DoriFrontend.FilterCacheManager.shared.read()
        
        result = result.filter { element in // Band
            guard filter.band != Set(DoriFrontend.Filter.Band.allCases) else { return true }
            return filter.band.contains { band in
                element.matches(band, withFilterCache: cacheCopy) ?? true
            }
        } .filter { element in // Attribute
            guard filter.attribute != Set(DoriFrontend.Filter.Attribute.allCases) else { return true }
            return filter.attribute.contains { attribute in
                element.matches(attribute, withFilterCache: cacheCopy) ?? true
            }
        } .filter { element in // Rarity
            guard filter.rarity != Set([1, 2, 3, 4, 5]) else { return true }
            return filter.rarity.contains { rarity in
                element.matches(rarity, withFilterCache: cacheCopy) ?? true
            }
        } .filter { element in // Character
            if filter.characterRequiresMatchAll {
                return filter.character.allSatisfy { character in
                    element.matches(character, withFilterCache: cacheCopy) ?? true
                }
            } else {
                guard filter.character != Set(DoriFrontend.Filter.Character.allCases) else { return true }
                return filter.character.contains { character in
                    element.matches(character, withFilterCache: cacheCopy) ?? true
                }
            }
        }
        result = result.filter { element in // Timeline Status with Servers
            guard filter.timelineStatus != Set(DoriFrontend.Filter.TimelineStatus.allCases) else { return true }
            return filter.timelineStatus.contains { timelineStatus in
                element.matches(DoriFrontend.TimelineStatusWithServers(timelineStatus: timelineStatus, servers: filter.server), withFilterCache: cacheCopy) ?? true
            }
        } .filter { element in // Availability with Servers
            guard filter.released != Set([true, false]) else { return true }
            return filter.released.contains { releaseStatus in
                element.matches(DoriFrontend.AvailabilityWithServers(releaseStatus: releaseStatus, servers: filter.server), withFilterCache: cacheCopy) ?? true
            }
        } .filter { element in // Server
            guard filter.server != Set(DoriFrontend.Filter.Server.allCases) else { return true }
            return filter.server.contains { server in
                element.matches(server, withFilterCache: cacheCopy) ?? true
            }
        } .filter { element in // Event Types
            guard filter.eventType != Set(DoriFrontend.Filter.EventType.allCases) else { return true }
            return filter.eventType.contains { eventType in
                element.matches(eventType, withFilterCache: cacheCopy) ?? true
            }
        } .filter { element in // Gacha Types
            guard filter.gachaType != Set(DoriFrontend.Filter.GachaType.allCases) else { return true }
            return filter.gachaType.contains { gachaType in
                element.matches(gachaType, withFilterCache: cacheCopy) ?? true
            }
        }
        return result
    }
}
