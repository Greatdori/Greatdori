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

struct APITests {
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
            #expect(band.id > 0)
            #expect(band.bandName.availableLocale() != nil)
        }
        
        bands = try #require(await DoriAPI.Band.main())
        #expect(!bands.isEmpty)
        for band in bands {
            #expect(band.id > 0)
            #expect(band.bandName.availableLocale() != nil)
        }
    }
    
    @Test
    func testCard() async throws {
        let cards = try #require(await DoriAPI.Card.all())
        #expect(!cards.isEmpty)
        let respJSON = try #require(await retryableRequestJSON("https://bestdori.com/api/cards/all.5.json"))
        try #require(respJSON.dictionary!.count == cards.count)
        for (index, (key, value)) in respJSON.sorted().enumerated() {
            let card = cards[index]
            #expect(Int(key)! == card.id)
            #expect(findExtraKeys(in: value, comparedTo: card).isEmpty)
        }
    }
}
