//
//  FrontendCard.swift
//  Greatdori
//
//  Created by Mark Chan on 7/23/25.
//

import Foundation

extension DoriFrontend {
    public class Card {
        private init() {}
        
        public static func list(filter: Filter = .init()) async -> [CardWithBand]? {
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
            
            let filteredCards = cards.filter { card in
                filter.band.contains { band in
                    band.rawValue == characters.first(where: { $0.id == card.characterID })?.bandID
                }
            }.filter { card in
                filter.attribute.contains(card.attribute)
            }.filter { card in
                filter.rarity.contains(card.rarity)
            }.filter { card in
                filter.character.contains { character in
                    character.rawValue == card.characterID
                }
            }.filter { card in
                filter.server.contains { locale in
                    card.prefix.availableInLocale(locale)
                }
            }.filter { card in
                for bool in filter.released {
                    for locale in filter.server {
                        if bool {
                            if (card.releasedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 4107477600)) < .now {
                                return true
                            }
                        } else {
                            if (card.releasedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 0)) > .now {
                                return true
                            }
                        }
                    }
                }
                return false
            }.filter { card in
                filter.cardType.contains(card.type)
            }.filter { card in
                if let skill = filter.skill {
                    skill.id == card.skillID
                } else {
                    true
                }
            }
            let sortedCards = switch filter.sort.keyword {
            case .releaseDate(let locale):
                filteredCards.sorted { lhs, rhs in
                    filter.sort.compare(
                        lhs.releasedAt.forLocale(locale) ?? lhs.releasedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0),
                        rhs.releasedAt.forLocale(locale) ?? rhs.releasedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)
                    )
                }
            case .rarity:
                filteredCards.sorted { lhs, rhs in
                    filter.sort.compare(lhs.rarity, rhs.rarity)
                }
            case .maximumStat:
                filteredCards.sorted { lhs, rhs in
                    return filter.sort.compare(lhs.stat.forMaximumLevel()?.total ?? 0, rhs.stat.forMaximumLevel()?.total ?? 0)
                }
            case .id:
                filteredCards.sorted { lhs, rhs in
                    filter.sort.compare(lhs.id, rhs.id)
                }
            }
            return sortedCards.compactMap { card in
                if let band = bands.first(where: { $0.id == characters.first { $0.id == card.characterID }?.bandID }) {
                    (card: card, band: band)
                } else {
                    nil
                }
            }
        }
    }
}

extension DoriFrontend.Card {
    public typealias PreviewCard = DoriAPI.Card.PreviewCard
    public typealias CardWithBand = (card: PreviewCard, band: DoriAPI.Band.Band)
}
