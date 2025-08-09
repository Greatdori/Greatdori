//===---*- Greatdori! -*---------------------------------------------------===//
//
// APITests.swift
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

import Testing
import Foundation
import SwiftyJSON
@testable import DoriKit

// While testing details of something (card, event, etc.),
// we only choose one or several representative ones to fetch its detail,
// or every time we run a test it becomes an attack to Bestdori's server.

private struct APITests {
    init() {
        // We set _preferredLocale directly to prevent it being stored.
        DoriAPI._preferredLocale = .init(rawValue: ProcessInfo.processInfo.environment["DORIKIT_TESTING_PREFERRED_LOCALE"]!)!
    }
    
    @Test
    func testDataLocalization() async throws {
        var data = DoriAPI.LocalizedData<Int>(jp: nil, en: nil, tw: nil, cn: nil, kr: nil)
        let allLocales = DoriAPI.Locale.allCases
        for locale in allLocales {
            #expect(data.forLocale(locale) == nil)
            #expect(!data.availableInLocale(locale))
            #expect(data.availableLocale(prefer: locale) == nil)
        }
        #expect(data.forPreferredLocale(allowsFallback: false) == nil)
        #expect(data.forPreferredLocale(allowsFallback: true) == nil)
        #expect(!data.availableInPreferredLocale())
        #expect(data.availableLocale(prefer: nil) == nil)
        data._set(42, forLocale: DoriAPI.preferredLocale)
        #expect(data.forPreferredLocale(allowsFallback: false) != nil)
        #expect(data.forPreferredLocale(allowsFallback: true) != nil)
        #expect(data.availableInPreferredLocale())
        #expect(data.availableLocale(prefer: nil) == DoriAPI.preferredLocale)
        
        data = data.map({ _ in 42 })
        for locale in allLocales {
            #expect(data.forLocale(locale) == 42)
        }
    }
    
    @Test
    func testBand() async throws {
        var bands = try #require(await DoriAPI.Band.all())
        #expect(!bands.isEmpty)
        for band in bands {
            #expect(band.id > 0, .init(band))
            #expect(band.bandName.availableLocale() != nil, .init(band))
        }
        
        let respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/bands/all.1.json"))
        try #require(respJSON.dictionary!.count == bands.count, Comment(respJSON.dictionary!, bands))
        for (index, (key, value)) in respJSON.sorted().enumerated() {
            let band = bands[index]
            #expect(Int(key)! == band.id, .init(band))
            #expect(findExtraKeys(in: value, comparedTo: band).isEmpty, .init(value))
        }
        
        bands = try #require(await DoriAPI.Band.main())
        #expect(!bands.isEmpty)
        for band in bands {
            #expect(band.id > 0, .init(band))
            #expect(band.bandName.availableLocale() != nil, .init(band))
        }
    }
    
    @Test
    func testCard() async throws {
        // -- Testing preview cards --
        let cards = try #require(await DoriAPI.Card.all())
        #expect(!cards.isEmpty)
        
        let cardIDs = cards.map { $0.id }
        #expect(cardIDs.count == Set(cardIDs).count, .init(cards)) // ID should be unique
        for card in cards {
            #expect(card.id > 0, .init(card))
            #expect(1...5 ~= card.rarity, .init(card))
            #expect(card.levelLimit >= 10, .init(card))
            #expect(!card.resourceSetName.isEmpty, .init(card))
            #expect(card.prefix.availableLocale() != nil, .init(card))
            #expect(card.releasedAt.availableLocale() != nil, .init(card))
            #expect(card.skillID > 0, .init(card))
            #expect(!card.stat.isEmpty, .init(card))
            
            // Card stats processing
            for value in card.stat.values {
                try #require(!value.isEmpty)
                let stat = value[0]
                #expect(stat.total == stat.performance + stat.technique + stat.visual, .init(stat))
                #expect(stat + stat == stat * 2, .init(stat))
                #expect(stat - .zero == stat, .init(stat))
            }
            #expect((try #require(card.stat.minimumLevel)) < (try #require(card.stat.maximumLevel)), .init(card))
            #expect((try #require(card.stat.forMinimumLevel()?.total)) <= (try #require(card.stat.forMaximumLevel()?.total)), .init(card))
            #expect((try #require(card.stat.maximumValue(rarity: card.rarity)?.total)) > (try #require(card.stat.forMaximumLevel()?.total)), .init(card))
        }
        
        var respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/cards/all.5.json"))
        try #require(respJSON.dictionary!.count == cards.count, Comment(respJSON.dictionary!, cards))
        for (index, (key, value)) in respJSON.sorted().enumerated() {
            let card = cards[index]
            #expect(Int(key)! == card.id, .init(card))
            #expect(findExtraKeys(in: value, comparedTo: card).isEmpty, .init(value))
        }
        
        // -- Testing card details --
        let testingCardID = 2125 // Why 2125? I like it 😋
        let card = try #require(await DoriAPI.Card.detail(of: testingCardID))
        respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/cards/\(testingCardID).json"))
        #expect(findExtraKeys(in: respJSON, comparedTo: card).isEmpty, .init(respJSON))
        #expect(card.id == testingCardID, .init(card))
        #expect(1...5 ~= card.rarity, .init(card))
        #expect(card.levelLimit >= 10, .init(card))
        #expect(!card.resourceSetName.isEmpty, .init(card))
        #expect(!card.sdResourceName.isEmpty, .init(card))
        #expect(card.costumeID > 0, .init(card))
        #expect(card.gachaText.availableLocale() != nil, .init(card))
        #expect(card.prefix.availableLocale() != nil, .init(card))
        #expect(card.releasedAt.availableLocale() != nil, .init(card))
        #expect(card.skillName.availableLocale() != nil, .init(card))
        #expect(card.skillID > 0, .init(card))
        #expect(!card.stat.isEmpty, .init(card))
        
        // Card stats processing
        for value in card.stat.values {
            #expect(!value.isEmpty)
        }
        #expect((try #require(card.stat.minimumLevel)) < (try #require(card.stat.maximumLevel)), .init(card))
        #expect((try #require(card.stat.forMinimumLevel()?.total)) <= (try #require(card.stat.forMaximumLevel()?.total)), .init(card))
        #expect((try #require(card.stat.maximumValue(rarity: card.rarity)?.total)) > (try #require(card.stat.forMaximumLevel()?.total)), .init(card))
    }
    
    @Test
    func testCharacter() async throws {
        // -- Testing preview characters --
        let characters = try #require(await DoriAPI.Character.all())
        #expect(!characters.isEmpty)
        
        let characterIDs = characters.map { $0.id }
        #expect(characterIDs.count == Set(characterIDs).count, .init(characters))
        for character in characters {
            #expect(character.id > 0, .init(character))
            #expect(character.characterName.availableLocale() != nil, .init(character))
        }
        
        var respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/characters/all.2.json"))
        try #require(respJSON.dictionary!.count == characters.count, Comment(respJSON, characters))
        for (index, (key, value)) in respJSON.sorted().enumerated() {
            let character = characters[index]
            #expect(Int(key)! == character.id, .init(character))
            #expect(findExtraKeys(in: value, comparedTo: character, exceptions: ["colorCode"]).isEmpty, .init(value))
        }
        
        // -- Testing birthday characters --
        let bdayCharacters = try #require(await DoriAPI.Character.allBirthday())
        #expect(!bdayCharacters.isEmpty)
        
        let bdayCharaIDs = bdayCharacters.map { $0.id }
        #expect(bdayCharaIDs.count == Set(bdayCharaIDs).count, .init(bdayCharacters))
        for character in bdayCharacters {
            #expect(character.id > 0, "\(character)")
            #expect(character.characterName.availableLocale() != nil, .init(character))
            #expect(character.birthday < .now, .init(character))
        }
        
        respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/characters/main.birthday.json"))
        try #require(respJSON.dictionary!.count == bdayCharacters.count, Comment(respJSON, bdayCharacters))
        for (index, (key, value)) in respJSON.sorted().enumerated() {
            let character = bdayCharacters[index]
            #expect(Int(key)! == character.id, .init(character))
            #expect(findExtraKeys(in: value, comparedTo: character, exceptions: ["profile"]).isEmpty, .init(value))
        }
        
        // -- Testing character details --
        let testingCharacterID = 39
        let character = try #require(await DoriAPI.Character.detail(of: 39))
        respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/characters/\(testingCharacterID).json"))
        #expect(findExtraKeys(in: respJSON, comparedTo: character, exceptions: ["seasonCostumeListMap", "colorCode"]).isEmpty, .init(respJSON))
        #expect(character.id == testingCharacterID, .init(character))
        #expect(character.characterName.availableLocale() != nil, .init(character))
        #expect(!character.sdAssetBundleName.isEmpty, .init(character))
    }
    
    @Test
    func testCostume() async throws {
        // -- Testing preview costumes --
        let costumes = try #require(await DoriAPI.Costume.all())
        #expect(!costumes.isEmpty)
        
        let costumeIDs = costumes.map { $0.id }
        #expect(costumeIDs.count == Set(costumeIDs).count, .init(costumes))
        for costume in costumes {
            #expect(costume.id > 0, .init(costume))
            #expect(costume.characterID > 0, .init(costume))
            #expect(!costume.assetBundleName.isEmpty, .init(costume))
            #expect(costume.description.availableLocale() != nil, .init(costume))
            #expect(costume.publishedAt.availableLocale() != nil, .init(costume))
        }
        
        var respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/costumes/all.5.json"))
        try #require(respJSON.dictionary!.count == costumes.count, Comment(respJSON, costumes))
        for (index, (key, value)) in respJSON.sorted().enumerated() {
            let costume = costumes[index]
            #expect(Int(key)! == costume.id, .init(costume))
            #expect(findExtraKeys(in: value, comparedTo: costume).isEmpty, .init(value))
        }
        
        // -- Testing costume details --
        let testingCostumeID = 2120
        let costume = try #require(await DoriAPI.Costume.detail(of: testingCostumeID))
        respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/costumes/\(testingCostumeID).json"))
        #expect(findExtraKeys(in: respJSON, comparedTo: costume).isEmpty, .init(respJSON))
        #expect(costume.id == testingCostumeID, .init(costume))
        #expect(costume.characterID > 0, .init(costume))
        #expect(!costume.assetBundleName.isEmpty, .init(costume))
        #expect(costume.description.availableLocale() != nil, .init(costume))
        #expect(costume.publishedAt.availableLocale() != nil, .init(costume))
        #expect(!costume.cards.isEmpty, .init(costume))
    }
    
    @Test
    func testEvent() async throws {
        // -- Testing preview events --
        let events = try #require(await DoriAPI.Event.all())
        #expect(!events.isEmpty)
        
        let eventIDs = events.map { $0.id }
        #expect(eventIDs.count == Set(eventIDs).count, .init(events))
        for event in events {
            #expect(event.id > 0, .init(event))
            #expect(event.eventName.forPreferredLocale() != nil, .init(event))
            #expect(!event.assetBundleName.isEmpty, .init(event))
            #expect(!event.bannerAssetBundleName.isEmpty, .init(event))
            #expect(!event.attributes.isEmpty, .init(event))
            #expect(!event.characters.isEmpty, .init(event))
        }
        
        var respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/events/all.5.json"))
        try #require(respJSON.dictionary!.count == events.count, Comment(respJSON, events))
        for (index, (key, value)) in respJSON.sorted().enumerated() {
            let event = events[index]
            #expect(Int(key)! == event.id, .init(event))
            #expect(findExtraKeys(in: value, comparedTo: event).isEmpty, .init(value))
        }
        
        // -- Testing event details --
        let testingEventID = 235
        let event = try #require(await DoriAPI.Event.detail(of: testingEventID))
        respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/events/\(testingEventID).json"))
        #expect(findExtraKeys(in: respJSON, comparedTo: event, exceptions: ["enableFlag"]).isEmpty, .init(respJSON))
        #expect(event.id > 0, .init(event))
        #expect(event.eventName.forPreferredLocale() != nil, .init(event))
        #expect(!event.assetBundleName.isEmpty, .init(event))
        #expect(!event.bannerAssetBundleName.isEmpty, .init(event))
        #expect(!event.attributes.isEmpty, .init(event))
        #expect(!event.characters.isEmpty, .init(event))
    }
}
