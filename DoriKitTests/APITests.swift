//
//  APITests.swift
//  DoriKitTests
//
//  Created by Mark Chan on 7/27/25.
//

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
            #expect(band.id > 0, "\(band)")
            #expect(band.bandName.availableLocale() != nil, "\(band)")
        }
        
        let respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/bands/all.1.json"))
        try #require(respJSON.dictionary!.count == bands.count, "\(respJSON.dictionary!)|||||\(bands)")
        for (index, (key, value)) in respJSON.sorted().enumerated() {
            let band = bands[index]
            #expect(Int(key)! == band.id, "\(band)")
            #expect(findExtraKeys(in: value, comparedTo: band).isEmpty, "\(value)")
        }
        
        bands = try #require(await DoriAPI.Band.main())
        #expect(!bands.isEmpty)
        for band in bands {
            #expect(band.id > 0, "\(band)")
            #expect(band.bandName.availableLocale() != nil, "\(band)")
        }
    }
    
    @Test
    func testCard() async throws {
        // -- Testing preview cards --
        let cards = try #require(await DoriAPI.Card.all())
        #expect(!cards.isEmpty)
        
        let cardIDs = cards.map { $0.id }
        #expect(cardIDs.count == Set(cardIDs).count, "\(cards)") // ID should be unique
        for card in cards {
            #expect(card.id > 0, "\(card)")
            #expect(1...5 ~= card.rarity, "\(card)")
            #expect(card.levelLimit >= 10, "\(card)")
            #expect(!card.resourceSetName.isEmpty, "\(card)")
            #expect(card.prefix.availableLocale() != nil, "\(card)")
            #expect(card.releasedAt.availableLocale() != nil, "\(card)")
            #expect(card.skillID > 0, "\(card)")
            #expect(!card.stat.isEmpty, "\(card)")
            
            // Card stats processing
            for value in card.stat.values {
                try #require(!value.isEmpty)
                let stat = value[0]
                #expect(stat.total == stat.performance + stat.technique + stat.visual, "\(stat)")
                #expect(stat + stat == stat * 2, "\(stat)")
                #expect(stat - .zero == stat, "\(stat)")
            }
            #expect((try #require(card.stat.minimumLevel)) < (try #require(card.stat.maximumLevel)), "\(card)")
            #expect((try #require(card.stat.forMinimumLevel()?.total)) <= (try #require(card.stat.forMaximumLevel()?.total)), "\(card)")
            #expect((try #require(card.stat.maximumValue(rarity: card.rarity)?.total)) > (try #require(card.stat.forMaximumLevel()?.total)), "\(card)")
        }
        
        var respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/cards/all.5.json"))
        try #require(respJSON.dictionary!.count == cards.count, "\(respJSON.dictionary!)|||||\(cards)")
        for (index, (key, value)) in respJSON.sorted().enumerated() {
            let card = cards[index]
            #expect(Int(key)! == card.id, "\(card)")
            #expect(findExtraKeys(in: value, comparedTo: card).isEmpty, "\(value)")
        }
        
        // -- Testing card details --
        let testingCardID = 2125 // Why 2125? I like it 😋
        let card = try #require(await DoriAPI.Card.detail(of: testingCardID))
        respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/cards/\(testingCardID).json"))
        #expect(findExtraKeys(in: respJSON, comparedTo: card).isEmpty, "\(respJSON)")
        #expect(card.id == testingCardID, "\(card)")
        #expect(1...5 ~= card.rarity, "\(card)")
        #expect(card.levelLimit >= 10, "\(card)")
        #expect(!card.resourceSetName.isEmpty, "\(card)")
        #expect(!card.sdResourceName.isEmpty, "\(card)")
        #expect(card.costumeID > 0, "\(card)")
        #expect(card.gachaText.availableLocale() != nil, "\(card)")
        #expect(card.prefix.availableLocale() != nil, "\(card)")
        #expect(card.releasedAt.availableLocale() != nil, "\(card)")
        #expect(card.skillName.availableLocale() != nil, "\(card)")
        #expect(card.skillID > 0, "\(card)")
        #expect(!card.stat.isEmpty, "\(card)")
        
        // Card stats processing
        for value in card.stat.values {
            #expect(!value.isEmpty)
        }
        #expect((try #require(card.stat.minimumLevel)) < (try #require(card.stat.maximumLevel)), "\(card)")
        #expect((try #require(card.stat.forMinimumLevel()?.total)) <= (try #require(card.stat.forMaximumLevel()?.total)), "\(card)")
        #expect((try #require(card.stat.maximumValue(rarity: card.rarity)?.total)) > (try #require(card.stat.forMaximumLevel()?.total)), "\(card)")
    }
    
    @Test
    func testCharacter() async throws {
        // -- Testing preview characters --
        let characters = try #require(await DoriAPI.Character.all())
        #expect(!characters.isEmpty)
        
        let characterIDs = characters.map { $0.id }
        #expect(characterIDs.count == Set(characterIDs).count, "\(characters)")
        for character in characters {
            #expect(character.id > 0, "\(character)")
            #expect(character.characterName.availableLocale() != nil, "\(character)")
        }
        
        var respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/characters/all.2.json"))
        try #require(respJSON.dictionary!.count == characters.count, "\(respJSON)|||||\(characters)")
        for (index, (key, value)) in respJSON.sorted().enumerated() {
            let character = characters[index]
            #expect(Int(key)! == character.id, "\(character)")
            #expect(findExtraKeys(in: value, comparedTo: character, exceptions: ["colorCode"]).isEmpty, "\(value)")
        }
        
        // -- Testing birthday characters --
        let bdayCharacters = try #require(await DoriAPI.Character.allBirthday())
        #expect(!bdayCharacters.isEmpty)
        
        let bdayCharaIDs = bdayCharacters.map { $0.id }
        #expect(bdayCharaIDs.count == Set(bdayCharaIDs).count, "\(bdayCharacters)")
        for character in bdayCharacters {
            #expect(character.id > 0, "\(character)")
            #expect(character.characterName.availableLocale() != nil, "\(character)")
            #expect(character.birthday < .now, "\(character)")
        }
        
        respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/characters/main.birthday.json"))
        try #require(respJSON.dictionary!.count == bdayCharacters.count, "\(respJSON)|||||\(bdayCharacters)")
        for (index, (key, value)) in respJSON.sorted().enumerated() {
            let character = bdayCharacters[index]
            #expect(Int(key)! == character.id, "\(character)")
            #expect(findExtraKeys(in: value, comparedTo: character, exceptions: ["profile"]).isEmpty, "\(value)")
        }
        
        // -- Testing character details --
        let testingCharacterID = 39
        let character = try #require(await DoriAPI.Character.detail(of: 39))
        respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/characters/\(testingCharacterID).json"))
        #expect(findExtraKeys(in: respJSON, comparedTo: character, exceptions: ["seasonCostumeListMap", "colorCode"]).isEmpty, "\(respJSON)")
        #expect(character.id == testingCharacterID, "\(character)")
        #expect(character.characterName.availableLocale() != nil, "\(character)")
        #expect(!character.sdAssetBundleName.isEmpty, "\(character)")
    }
    
    @Test
    func testCostume() async throws {
        // -- Testing preview costumes --
        let costumes = try #require(await DoriAPI.Costume.all())
        #expect(!costumes.isEmpty)
        
        let costumeIDs = costumes.map { $0.id }
        #expect(costumeIDs.count == Set(costumeIDs).count, "\(costumes)")
        for costume in costumes {
            #expect(costume.id > 0, "\(costume)")
            #expect(costume.characterID > 0, "\(costume)")
            #expect(!costume.assetBundleName.isEmpty, "\(costume)")
            #expect(costume.description.availableLocale() != nil, "\(costume)")
            #expect(costume.publishedAt.availableLocale() != nil, "\(costume)")
        }
        
        var respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/costumes/all.5.json"))
        try #require(respJSON.dictionary!.count == costumes.count, "\(respJSON)|||||\(costumes)")
        for (index, (key, value)) in respJSON.sorted().enumerated() {
            let costume = costumes[index]
            #expect(Int(key)! == costume.id, "\(costume)")
            #expect(findExtraKeys(in: value, comparedTo: costume).isEmpty, "\(value)")
        }
        
        // -- Testing costume details --
        let testingCostumeID = 2120
        let costume = try #require(await DoriAPI.Costume.detail(of: testingCostumeID))
        respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/costumes/\(testingCostumeID).json"))
        #expect(findExtraKeys(in: respJSON, comparedTo: costume).isEmpty, "\(respJSON)")
        #expect(costume.id == testingCostumeID, "\(costume)")
        #expect(costume.characterID > 0, "\(costume)")
        #expect(!costume.assetBundleName.isEmpty, "\(costume)")
        #expect(costume.description.availableLocale() != nil, "\(costume)")
        #expect(costume.publishedAt.availableLocale() != nil, "\(costume)")
        #expect(!costume.cards.isEmpty, "\(costume)")
    }
}
