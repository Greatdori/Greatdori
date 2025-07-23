//
//  Filters.swift
//  Greatdori
//
//  Created by Mark Chan on 7/23/25.
//

import Foundation

extension DoriFrontend {
    public struct Filter {
        public var band: Set<Band> = .init(Band.allCases)
        public var attribute: Set<Attribute> = .init(Attribute.allCases)
        public var rarity: Set<Rarity> = [1, 2, 3, 4, 5]
        public var character: Set<Character> = .init(Character.allCases)
        public var server: Set<Server> = .init(Server.allCases)
        public var released: Set<Bool> = [false, true]
        public var cardType: Set<CardType> = .init(CardType.allCases)
        public var eventType: Set<EventType> = .init(EventType.allCases)
        public var gachaType: Set<GachaType> = .init(GachaType.allCases)
        public var skill: Skill? = nil
        public var timelineStatus: Set<TimelineStatus> = .init(TimelineStatus.allCases)
        public var sort: Sort = .init(direction: .descending, keyword: .releaseDate(in: .jp))
        
        public init(
            band: Set<Band> = .init(Band.allCases),
            attribute: Set<Attribute> = .init(Attribute.allCases),
            rarity: Set<Rarity> = [1, 2, 3, 4, 5],
            character: Set<Character> = .init(Character.allCases),
            server: Set<Server> = .init(Server.allCases),
            released: Set<Bool> = [false, true],
            cardType: Set<CardType> = .init(CardType.allCases),
            eventType: Set<EventType> = .init(EventType.allCases),
            gachaType: Set<GachaType> = .init(GachaType.allCases),
            skill: Skill? = nil,
            timelineStatus: Set<TimelineStatus> = .init(TimelineStatus.allCases),
            sort: Sort = .init(direction: .descending, keyword: .releaseDate(in: .jp))
        ) {
            self.band = band
            self.attribute = attribute
            self.rarity = rarity
            self.character = character
            self.server = server
            self.released = released
            self.cardType = cardType
            self.eventType = eventType
            self.gachaType = gachaType
            self.skill = skill
            self.timelineStatus = timelineStatus
            self.sort = sort
        }
    }
}

extension DoriFrontend.Filter {
    public typealias Attribute = DoriAPI.Attribute
    public typealias Rarity = Int
    public typealias Server = DoriAPI.Locale
    public typealias CardType = DoriAPI.Card.CardType
    public typealias EventType = DoriAPI.Event.EventType
    public typealias GachaType = DoriAPI.Gacha.GachaType
    public typealias Skill = DoriAPI.Skill.Skill
    
    public enum Band: Int, CaseIterable {
        case poppinParty = 1
        case afterglow
        case helloHappyWorld
        case pastelPalettes
        case roselia
        case raiseASuilen = 18
        case morfonica = 21
        case mygo = 45
        case others = -1
    }
    public enum Character: Int, CaseIterable {
        // Poppin'Party
        case kasumi = 1
        case tae
        case rimi
        case saya
        case arisa
        
        // Afterglow
        case ran
        case moca
        case himari
        case tomoe
        case tsugumi
        
        // Hello, Happy World!
        case kokoro
        case kaoru
        case hagumi
        case kanon
        case misaki
        
        // Pastel＊Palettes
        case aya
        case hina
        case chisato
        case maya
        case eve
        
        // Roselia
        case yukina
        case sayo
        case lisa
        case ako
        case rinko
        
        // Morfonica
        case mashiro
        case toko
        case nanami
        case tsukushi
        case rui
        
        // RAISE A SUILEN
        case rei
        case rokka
        case masuki
        case reona
        case chiyu
        
        // MyGO!!!!!
        case tomori
        case anon
        case rana
        case soyo
        case taki
    }
    public enum TimelineStatus: CaseIterable {
        case ended
        case ongoing
        case upcoming
    }
    
    public struct Sort {
        public var direction: Direction
        public var keyword: Keyword
        
        public init(direction: Direction, keyword: Keyword) {
            self.direction = direction
            self.keyword = keyword
        }
        
        public enum Direction {
            case ascending
            case descending
        }
        public enum Keyword {
            case releaseDate(in: DoriAPI.Locale)
            case rarity
            case maximumStat
            case id
        }
        
        internal func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> Bool {
            switch direction {
            case .ascending: lhs < rhs
            case .descending: lhs > rhs
            }
        }
    }
}
