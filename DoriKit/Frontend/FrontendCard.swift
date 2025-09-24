//===---*- Greatdori! -*---------------------------------------------------===//
//
// FrontendCard.swift
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

extension DoriFrontend {
    /// Request and fetch data about card in Bandori.
    public enum Card {
        /// List all cards with related information.
        ///
        /// - Returns: All cards with band information, nil if failed to fetch.
        public static func list() async -> [CardWithBand]? {
            let groupResult = await withTasksResult {
                await DoriAPI.Card.all()
            } _: {
                await DoriAPI.Character.all()
            } _: {
                await DoriAPI.Band.main()
            }
            guard let cards = groupResult.0 else { return nil }
            guard let characters = groupResult.1 else { return nil }
            guard let bands = groupResult.2 else { return nil }
            
            FilterCacheManager.shared.writeBandsList(bands)
            FilterCacheManager.shared.writeCharactersList(characters)
            
            return cards.compactMap { card in
                if let band = bands.first(where: { $0.id == characters.first { $0.id == card.characterID }?.bandID }) {
                    .init(card: card, band: band)
                } else {
                    nil
                }
            }
        }
        
        /// Get a detailed card with related information.
        ///
        /// - Parameter id: The ID of card.
        /// - Returns: The card of requested ID,
        ///     with related characters, bands, skill, costumes,
        ///     events and gacha information.
        public static func extendedInformation(of id: Int) async -> ExtendedCard? {
            let groupResult = await withTasksResult {
                await DoriAPI.Card.detail(of: id)
            } _: {
                await DoriAPI.Character.all()
            } _: {
                await DoriAPI.Band.main()
            } _: {
                await DoriAPI.Skill.all()
            } _: {
                await DoriAPI.Costume.all()
            } _: {
                await DoriAPI.Event.all()
            } _: {
                await DoriAPI.Gacha.all()
            } _: {
                await DoriAPI.LoginCampaign.all()
            }
            guard let card = groupResult.0 else { return nil }
            guard let characters = groupResult.1 else { return nil }
            guard let bands = groupResult.2 else { return nil }
            guard let skills = groupResult.3 else { return nil }
            guard let costumes = groupResult.4 else { return nil }
            guard let events = groupResult.5 else { return nil }
            guard let gacha = groupResult.6 else { return nil }
            guard let campaigns = groupResult.7 else { return nil }
            
            let character = characters.first { $0.id == card.characterID }!
            var resultGacha = [DoriAPI.Gacha.PreviewGacha]()
            if let source = card.source.forPreferredLocale() {
                for src in source {
                    guard case .gacha(let info) = src else { continue }
                    resultGacha = gacha.filter { info.keys.contains($0.id) }
                }
            }
            
            func relatedEvent(for locale: DoriAPI.Locale) -> PreviewEvent? {
                events.first {
                    ($0.startAt.forLocale(locale)?.timeIntervalSince1970 ?? 0)...($0.endAt.forLocale(locale)?.timeIntervalSince1970 ?? 0)
                    ~= card.releasedAt.forLocale(locale)?.timeIntervalSince1970 ?? 0o527
                }
            }
            
            return .init(
                id: id,
                card: card,
                cardSource: card.source.map {
                    let mappedResult = $0?.map { (src: DoriAPI.Card.Card.CardSource) -> DoriFrontend.Card.ExtendedCard.Source in
                        switch src {
                        case .gacha(let dict): .gacha(dict.compactMap { key, value in
                            if let g = gacha.first(where: { $0.id == key }) {
                                (key: g, value: value)
                            } else {
                                nil
                            }
                        }.reduce(into: [:]) { (dict, pair: (key: DoriAPI.Gacha.PreviewGacha, value: Double)) in
                            // Swift says the types are too complex
                            // so we have to annotate the type
                            // of `pair` explicitly.
                            dict.updateValue(pair.value, forKey: pair.key)
                        })
                        case .event(let dict): .event(dict.compactMap { key, value in
                            if let e = events.first(where: { $0.id == key }) {
                                (key: e, value: value)
                            } else {
                                nil
                            }
                        }.reduce(into: [:]) { (dict, pair: (key: DoriAPI.Event.PreviewEvent, value: Int)) in
                            // Swift says the types are too complex
                            // so we have to annotate the type
                            // of `pair` explicitly.
                            dict.updateValue(pair.value, forKey: pair.key)
                        })
                        case .login(let ids): .login(ids.compactMap { id in
                            campaigns.first { $0.id == id }
                        })
                        }
                    }
                    return mappedResult != nil ? Set(mappedResult!) : nil
                },
                character: character,
                band: bands.first { character.bandID == $0.id }!,
                skill: skills.first { $0.id == card.skillID }!,
                costume: costumes.first { $0.id == card.costumeID }!,
                event: .init(
                    jp: relatedEvent(for: .jp),
                    en: relatedEvent(for: .en),
                    tw: relatedEvent(for: .tw),
                    cn: relatedEvent(for: .cn),
                    kr: relatedEvent(for: .kr)
                ),
                gacha: resultGacha
            )
        }
    }
}

extension DoriFrontend.Card {
    public typealias PreviewCard = DoriAPI.Card.PreviewCard
    public typealias Card = DoriAPI.Card.Card
    
    public struct CardWithBand: Sendable, Hashable, DoriCache.Cacheable {
        public var card: PreviewCard
        public var band: DoriAPI.Band.Band
    }
    public struct ExtendedCard: Sendable, Identifiable, Hashable, DoriCache.Cacheable {
        public var id: Int
        public var card: Card
        public var cardSource: DoriAPI.LocalizedData<Set<Source>>
        public var character: DoriAPI.Character.PreviewCharacter
        public var band: DoriAPI.Band.Band
        public var skill: DoriAPI.Skill.Skill
        public var costume: DoriAPI.Costume.PreviewCostume
        public var event: DoriAPI.LocalizedData<DoriAPI.Event.PreviewEvent>
        public var gacha: [DoriAPI.Gacha.PreviewGacha]
        
        /// Represent a part of extended sources of a card.
        public enum Source: Sendable, Hashable, DoriCache.Cacheable {
            /// Information about a card can be got from gacha.
            ///
            /// This case is associated an `[PreviewGacha: Double]` dictionary,
            /// which represents `[gacha: probability]`.
            case gacha([DoriAPI.Gacha.PreviewGacha: Double])
            /// Information about a card can be got from events.
            ///
            /// This case is associated an `[PreviewEvent: Int]` dictionary,
            /// which represents `[event: point]`.
            case event([DoriAPI.Event.PreviewEvent: Int])
            /// Information about a card can be got from login campaigns.
            case login([DoriAPI.LoginCampaign.PreviewCampaign])
        }
    }
}
extension DoriFrontend.Card.CardWithBand: DoriFrontend.Searchable {
    public var id: Int { self.card.id }
    public var _searchLocalizedStrings: [DoriAPI.LocalizedData<String>] {
        self.card._searchLocalizedStrings
    }
    public var _searchIntegers: [Int] {
        self.card._searchIntegers
    }
    public var _searchLocales: [DoriAPI.Locale] {
        self.card._searchLocales
    }
    public var _searchBands: [DoriAPI.Band.Band] {
        [self.band]
    }
    public var _searchAttributes: [DoriAPI.Attribute] {
        self.card._searchAttributes
    }
}

extension DoriFrontend.Card.ExtendedCard {
    @inlinable
    public init?(id: Int) async {
        if let card = await DoriFrontend.Card.extendedInformation(of: id) {
            self = card
        } else {
            return nil
        }
    }
}
