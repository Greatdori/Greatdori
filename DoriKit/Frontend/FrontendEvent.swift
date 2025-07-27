//
//  FrontendEvent.swift
//  Greatdori
//
//  Created by Mark Chan on 7/23/25.
//

import Foundation

extension DoriFrontend {
    public class Event {
        private init() {}
        
        public static func localizedLatestEvent() async -> DoriAPI.LocalizedData<PreviewEvent>? {
            guard let allEvents = await DoriAPI.Event.all() else { return nil }
            var result = DoriAPI.LocalizedData<PreviewEvent>(jp: nil, en: nil, tw: nil, cn: nil, kr: nil)
            let reversedEvents = allEvents.filter { $0.id <= 5000 }.reversed()
            for locale in DoriAPI.Locale.allCases {
                result._set(reversedEvents.first(where: { $0.startAt.availableInLocale(locale) }), forLocale: locale)
                if let event = result.forLocale(locale), let endDate = event.endAt.forLocale(locale), endDate < .now {
                    // latest event has ended, but next event is null
                    if let nextEvent = allEvents.first(where: { $0.id == event.id + 1 }) {
                        result._set(nextEvent, forLocale: locale)
                    }
                }
            }
            return result
        }
        
        public static func list(filter: Filter = .init()) async -> [PreviewEvent]? {
            guard let events = await DoriAPI.Event.all() else { return nil }
            
            let filteredEvents = events.filter { event in
                filter.attribute.contains { attribute in
                    event.attributes.contains { $0.attribute == attribute }
                }
            }.filter { event in
                filter.character.contains { character in
                    event.characters.contains { $0.characterID == character.rawValue }
                }
            }.filter { event in
                filter.server.contains { locale in
                    event.startAt.availableInLocale(locale)
                }
            }.filter { event in
                for timelineStatus in filter.timelineStatus {
                    let result = switch timelineStatus {
                    case .ended:
                        (event.endAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 4107477600)) < .now
                    case .ongoing:
                        (event.startAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 4107477600)) < .now
                        && (event.endAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)) > .now
                    case .upcoming:
                        (event.startAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)) > .now
                    }
                    if result {
                        return true
                    }
                }
                return false
            }.filter { event in
                filter.eventType.contains(event.eventType)
            }
            let sortedEvents = switch filter.sort.keyword {
            case .releaseDate(let locale):
                filteredEvents.sorted { lhs, rhs in
                    filter.sort.compare(
                        lhs.startAt.forLocale(locale) ?? lhs.startAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0),
                        rhs.startAt.forLocale(locale) ?? rhs.startAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)
                    )
                }
            default:
                filteredEvents.sorted { lhs, rhs in
                    filter.sort.compare(lhs.id, rhs.id)
                }
            }
            return sortedEvents
        }
        
        public static func extendedInformation(of id: Int) async -> ExtendedEvent? {
            let groupResult = await withTasksResult {
                await DoriAPI.Event.detail(of: id)
            } _: {
                await DoriAPI.Band.all()
            } _: {
                await DoriAPI.Character.all()
            } _: {
                await DoriAPI.Card.all()
            } _: {
                await DoriAPI.Gacha.all()
            } _: {
                await DoriAPI.Song.all()
            } _: {
                await DoriAPI.Degree.all()
            }
            guard let event = groupResult.0 else { return nil }
            guard let bands = groupResult.1 else { return nil }
            guard let characters = groupResult.2 else { return nil }
            guard let cards = groupResult.3 else { return nil }
            guard let gacha = groupResult.4 else { return nil }
            guard let songs = groupResult.5 else { return nil }
            guard let degrees = groupResult.6 else { return nil }
            
            let resultCharacters = characters.filter { character in event.characters.contains { $0.characterID == character.id } }
            
            return .init(
                id: id,
                event: event,
                bands: bands.filter { band in resultCharacters.contains { $0.bandID == band.id } },
                characters: resultCharacters,
                cards: cards.filter { card in event.rewardCards.contains(card.id) || event.members.contains { $0.situationID == card.id } },
                gacha: gacha.filter { event.startAt.forPreferredLocale() == $0.publishedAt.forPreferredLocale() },
                songs: songs.filter { event.startAt.forPreferredLocale() == $0.publishedAt.forPreferredLocale() },
                degrees: degrees.filter { $0.baseImageName.forPreferredLocale() == "degree_event\(event.id)_point" }
            )
        }
    }
}

extension DoriFrontend.Event {
    public typealias PreviewEvent = DoriAPI.Event.PreviewEvent
    public typealias Event = DoriAPI.Event.Event
    
    public struct ExtendedEvent: Identifiable, DoriCache.Cacheable {
        public var id: Int
        public var event: Event
        public var bands: [DoriAPI.Band.Band]
        public var characters: [DoriAPI.Character.PreviewCharacter]
        public var cards: [DoriAPI.Card.PreviewCard]
        public var gacha: [DoriAPI.Gacha.PreviewGacha]
        public var songs: [DoriAPI.Song.PreviewSong]
        public var degrees: [DoriAPI.Degree.Degree]
    }
}
