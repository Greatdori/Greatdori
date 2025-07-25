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
            let groupResult = await withTasksResult {
                await DoriAPI.Event.all()
            } _: {
                await DoriAPI.Character.all()
            }
            guard let events = groupResult.0 else { return nil }
            guard let characters = groupResult.1 else { return nil }
            
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
                    return switch timelineStatus {
                    case .ended:
                        (event.endAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 4107477600)) < .now
                    case .ongoing:
                        (event.startAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 4107477600)) < .now
                        && (event.endAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)) > .now
                    case .upcoming:
                        (event.startAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)) > .now
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
    }
}

extension DoriFrontend.Event {
    public typealias PreviewEvent = DoriAPI.Event.PreviewEvent
}
