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
        
        public static func recentBirthdayCharacters(aroundDate date: Date = .now) async -> [BirthdayCharacter]? {
            guard let allBirthday = await DoriAPI.Character.allBirthday() else { return nil }
            
            // JST TODAY
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
            var components = calendar.dateComponents([.month, .day], from: date)
            components.year = 2000
            components.hour = 0
            components.minute = 0
            components.second = 0
            let today = calendar.date(from: components)!

            // Get IDs by Interval
            var birthdayInterval: [TimeInterval] = []
            
            var pastMaxInterval: TimeInterval = -315360000000
            var lastBirthdayID: Int = -1
            
            var veryFirstBirthdayInYearInterval: TimeInterval = 315360000000
            var veryFirstBirthdayInYearID: Int = -1
            
            var futureMinInterval: TimeInterval = 315360000000
            var nextBirthdayID: Int = -1
            
            var veryLastBirthdayInYearInterval: TimeInterval = -315360000000
            var veryLastBirthdayInYearID: Int = -1
            
            var todaysBirthdayID: [Int] = []
            
            for i in 0..<allBirthday.count {
                birthdayInterval.append(allBirthday[i].birthday.timeIntervalSince(today))
                if birthdayInterval[i] > 0 {
                    // FUTURE
                    if birthdayInterval[i] < futureMinInterval {
                        futureMinInterval = birthdayInterval[i]
                        nextBirthdayID = i
                    }
                    if birthdayInterval[i] > veryLastBirthdayInYearInterval {
                        veryLastBirthdayInYearInterval = birthdayInterval[i]
                        veryLastBirthdayInYearID = i
                    }
                } else if birthdayInterval[i] < 0 {
                    // PAST
                    if birthdayInterval[i] > pastMaxInterval {
                        pastMaxInterval = birthdayInterval[i]
                        lastBirthdayID = i
                    }
                    if birthdayInterval[i] < veryFirstBirthdayInYearInterval {
                        veryFirstBirthdayInYearInterval = birthdayInterval[i]
                        veryFirstBirthdayInYearID = i
                    }
                } else {
                    // TODAY
                    todaysBirthdayID.append(i)
                }
            }
            
            // Infer Character by ID
            var finalist: [BirthdayCharacter] = []
            if todaysBirthdayID.count > 0 {
                // Today's Someone's Birthday
                for i in 0..<todaysBirthdayID.count {
                    finalist.append(allBirthday[todaysBirthdayID[i]])
                }
            } else {
                // Today's not someone's birthday
                if nextBirthdayID != -1 {
                    finalist.append(allBirthday[nextBirthdayID])
                } else {
                    finalist.append(allBirthday[veryFirstBirthdayInYearID])
                }
                if lastBirthdayID != -1 {
                    finalist.append(allBirthday[lastBirthdayID])
                } else {
                    finalist.append(allBirthday[veryLastBirthdayInYearID])
                }
            }
            
            // Sayo & Hina Confirmation
            if (finalist.contains(where: { $0.id == 17}) && !finalist.contains(where: { $0.id == 22})) {
                // ✓HINA, ×SAYO
                finalist.insert(allBirthday[21], at: 1)
            }
            // (There's no situation which there's Sayo but no Hina,
            // since Sayo has an ID after Hina which will make Hina being registered first.)
            
            return finalist
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
