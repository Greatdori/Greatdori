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
    }
}

extension DoriFrontend.Event {
    public typealias PreviewEvent = DoriAPI.Event.PreviewEvent
}
