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


extension DoriFrontend {
    //MARK: protocol Filterable
    public protocol Filterable {
        func matches<ValueType>(_ value: ValueType) -> Bool?
        // `matches` only handle single value.
        // Please keep in mind that it does handle values like any `Array` or `characterRequiresMatchAll`.
        // Unexpected value type or cache reading failure will lead to `nil` return.
    }
    
    //MARK: actor PreviewCardCache
    final class FilterCache: Sendable {
        static let shared = FilterCache()
        
        nonisolated(unsafe) private var cachedCards: [DoriAPI.Card.PreviewCard]?
        private let lock = NSLock()
        
        func readCardCache() -> [DoriAPI.Card.PreviewCard]? {
            lock.lock()
            defer { lock.unlock() }
            return unsafe cachedCards
        }
        
        func writeCardCache(_ cards: [DoriAPI.Card.PreviewCard]?) {
            lock.lock()
            unsafe cachedCards = cards
            lock.unlock()
        }
    }

}


//MARK: extension PreviewEvent
// Attribute, Character, Server, Timeline Status, Event Type
extension DoriAPI.Event.PreviewEvent {
    public func matches<ValueType>(_ value: ValueType) -> Bool? {
        if let attribute = value as? DoriFrontend.Filter.Attribute { // Attribute
            return self.attributes.contains { $0.attribute == attribute }
        } else if let character = value as? DoriFrontend.Filter.Character { // Character
            return self.characters.contains { $0.characterID == character.rawValue }
        } else if let server = value as? DoriFrontend.Filter.Server { // Server
            return self.startAt.availableInLocale(server)
        } else if let timelineStatus = value as? DoriFrontend.Filter.TimelineStatus { // Timeline Status
            switch timelineStatus {
            case .ended:
                for singleLocale in DoriAPI.Locale.allCases {
                    if (self.endAt.forLocale(singleLocale) ?? dateOfYear2100) < .now {
                        return true
                    }
                }
            case .ongoing:
                for singleLocale in DoriAPI.Locale.allCases {
                    if (self.startAt.forLocale(singleLocale) ?? dateOfYear2100) < .now
                        && (self.endAt.forLocale(singleLocale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        return true
                    }
                }
            case .upcoming:
                for singleLocale in DoriAPI.Locale.allCases {
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
extension DoriAPI.Gacha.PreviewGacha {
    public func matches<ValueType>(_ value: ValueType) -> Bool? {
        if let attribute = value as? DoriFrontend.Filter.Attribute { // Attribute
            let cards = unsafe DoriFrontend.FilterCache.shared.readCardCache()
            if let cards {
                let containingCards = cards.filter {
                    self.newCards.contains($0.id) }
                let cardAttributes = Set(cards.map { $0.attribute })
                return cardAttributes.contains(attribute)
            } else {
                NSLog("[Filter][Gacha] Found `nil` while trying to read card cache.")
                return nil // Unexpected: no cache
            }
        } else if let character = value as? DoriFrontend.Filter.Character { // Character
            let cards = unsafe DoriFrontend.FilterCache.shared.readCardCache()
            if let cards {
                let containingCards = cards.filter { self.newCards.contains($0.id) }
                let cardCharacters = Set(cards.map { $0.characterID })
                return cardCharacters.contains(character.rawValue)
            } else {
                NSLog("[Filter][Gacha] Found `nil` while trying to read card cache.")
                return nil // Unexpected: no cache
            }
        } else if let server = value as? DoriFrontend.Filter.Server { // Server
            return (self.publishedAt.forLocale(server) ?? dateOfYear2100) < .now
        } else if let timelineStatus = value as? DoriFrontend.Filter.TimelineStatus { // Timeline Status
            switch timelineStatus {
            case .ended:
                for singleLocale in DoriAPI.Locale.allCases {
                    if (self.closedAt.forLocale(singleLocale) ?? dateOfYear2100) < .now {
                        if self.id == 1652 {
                            print("#1652 ended \(singleLocale)")
                        }
                        return true
                    }
                }
            case .ongoing:
                for singleLocale in DoriAPI.Locale.allCases {
                    if (self.publishedAt.forLocale(singleLocale) ?? dateOfYear2100) < .now
                        && (self.closedAt.forLocale(singleLocale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        if self.id == 1652 {
                            print("#1652 ongoing \(singleLocale)")
                        }
                        return true
                    }
                }
            case .upcoming:
                for singleLocale in DoriAPI.Locale.allCases {
                    if (self.closedAt.forLocale(singleLocale) ?? .init(timeIntervalSince1970: 0)) > .now {
                        if self.id == 1652 {
                            print("#1652 upcoming \(singleLocale)")
                        }
                        return true
                    }
                }
            }
            if self.id == 1652 {
                print("#1652 none")
            }
            return false
        } else if let gachaType = value as? DoriFrontend.Filter.GachaType { // Gacha Type
            return self.type == gachaType
        } else {
            return nil // Unexpected: unexpected value type
        }
    }
}

public extension Array where Element: DoriFrontend.Filterable {
    public func filterByDori(with filter: DoriFrontend.Filter) -> [Element] {
        var result: [Element] = self
        guard filter.isFiltered else { return result }
        
        result = result.filter { element in // Attribute
            guard filter.attribute != Set(DoriFrontend.Filter.Attribute.allCases) else { return true }
            return filter.attribute.contains { attribute in
                element.matches(attribute) ?? true
            }
        } .filter { element in // Character
            if filter.characterRequiresMatchAll {
                return filter.character.allSatisfy { character in
                    element.matches(character) ?? true
                }
            } else {
                guard filter.character != Set(DoriFrontend.Filter.Character.allCases) else { return true }
                return filter.character.contains { character in
                    element.matches(character) ?? true
                }
            }
        } .filter { element in // Timeline Status
            guard filter.timelineStatus != Set(DoriFrontend.Filter.TimelineStatus.allCases) else { return true }
            return filter.timelineStatus.contains { timelineStatus in
                element.matches(timelineStatus) ?? true
            }
        } .filter { element in // Server
            guard filter.server != Set(DoriFrontend.Filter.Server.allCases) else { return true }
            return filter.server.contains { server in
                element.matches(server) ?? true
            }
        } .filter { element in // Event Types
            guard filter.eventType != Set(DoriFrontend.Filter.EventType.allCases) else { return true }
            return filter.eventType.contains { eventType in
                element.matches(eventType) ?? true
            }
        } .filter { element in // Gacha Types
            guard filter.gachaType != Set(DoriFrontend.Filter.GachaType.allCases) else { return true }
            return filter.gachaType.contains { eventType in
                element.matches(eventType) ?? true
            }
        }
        return result
    }
}
