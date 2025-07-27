//
//  FrontendCharacter.swift
//  Greatdori
//
//  Created by Mark Chan on 7/23/25.
//

import Foundation

extension DoriFrontend {
    public class Character {
        private init() {}
        
        public static func recentBirthdayCharacters() async -> [BirthdayCharacter]? {
            guard let allBirthday = await DoriAPI.Character.allBirthday() else { return nil }
            return allBirthday.filter {
                abs(
                    $0.birthday.componentsRewritten(
                        year: Date.now.components.year
                    ).timeIntervalSince1970 - Date.now.timeIntervalSince1970
                ) < 60*60*24*7
            }
        }
        
        public static func categorizedCharacters() async -> CategorizedCharacters? {
            let groupResult = await withTasksResult {
                await DoriAPI.Band.main()
            } _: {
                await DoriAPI.Character.all()
            }
            guard let bands = groupResult.0 else { return nil }
            guard let characters = groupResult.1 else { return nil }
            
            var result = [DoriAPI.Band.Band?: [PreviewCharacter]]()
            
            // Add characters for each bands
            for band in bands {
                var characters = characters.filter { $0.bandID == band.id }
                if _slowPath(band.id == 3) {
                    // Hello, Happy World!
                    characters.removeAll { $0.id == 601 } // Misaki...
                }
                result.updateValue(characters, forKey: band)
            }
            
            // Add characters that aren't in any band
            result.updateValue(characters.filter { $0.bandID == nil }, forKey: nil)
            
            return result
        }
        
        public static func extendedInformation(of id: Int) async -> ExtendedCharacter? {
            let groupResult = await withTasksResult {
                await DoriAPI.Character.detail(of: id)
            } _: {
                await DoriAPI.Band.all()
            } _: {
                await DoriAPI.Card.all()
            } _: {
                await DoriAPI.Costume.all()
            } _: {
                await DoriAPI.Event.all()
            } _: {
                await DoriAPI.Gacha.all()
            }
            guard let character = groupResult.0 else { return nil }
            guard let bands = groupResult.1 else { return nil }
            guard let cards = groupResult.2 else { return nil }
            guard let costumes = groupResult.3 else { return nil }
            guard let events = groupResult.4 else { return nil }
            guard let gacha = groupResult.5 else { return nil }
            
            let band = if let id = character.bandID {
                bands.first { $0.id == id }
            } else {
                nil as DoriAPI.Band.Band?
            }
            
            let newCards = cards.filter { $0.characterID == character.id }
            
            return .init(
                id: id,
                character: character,
                band: band,
                cards: newCards,
                costumes: costumes.filter { $0.characterID == character.id },
                events: events.filter { $0.characters.contains { $0.characterID == character.id } },
                gacha: gacha.filter { $0.newCards.contains { cardID in newCards.contains { $0.id == cardID } } }
            )
        }
    }
}

extension DoriFrontend.Character {
    public typealias PreviewCharacter = DoriAPI.Character.PreviewCharacter
    public typealias BirthdayCharacter = DoriAPI.Character.BirthdayCharacter
    public typealias CategorizedCharacters = [DoriAPI.Band.Band?: [PreviewCharacter]]
    public typealias Character = DoriAPI.Character.Character
    
    public struct ExtendedCharacter: Identifiable, DoriCache.Cacheable {
        public var id: Int
        public var character: Character
        public var band: DoriAPI.Band.Band?
        public var cards: [DoriAPI.Card.PreviewCard]
        public var costumes: [DoriAPI.Costume.PreviewCostume]
        public var events: [DoriAPI.Event.PreviewEvent]
        public var gacha: [DoriAPI.Gacha.PreviewGacha]
        
        internal init(
            id: Int,
            character: Character,
            band: DoriAPI.Band.Band?,
            cards: [DoriAPI.Card.PreviewCard],
            costumes: [DoriAPI.Costume.PreviewCostume],
            events: [DoriAPI.Event.PreviewEvent],
            gacha: [DoriAPI.Gacha.PreviewGacha]
        ) {
            self.id = id
            self.character = character
            self.band = band
            self.cards = cards
            self.costumes = costumes
            self.events = events
            self.gacha = gacha
        }
    }
}

extension DoriFrontend.Character.ExtendedCharacter {
    public func randomCard() -> DoriAPI.Card.PreviewCard? {
        self.cards.randomElement()
    }
}
