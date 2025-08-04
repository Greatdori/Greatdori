//
//  FrontendGacha.swift
//  Greatdori
//
//  Created by Mark Chan on 8/1/25.
//

import Foundation

extension DoriFrontend {
    public class Gacha {
        private init() {}
        
        public static func list(filter: Filter = .init()) async -> [PreviewGacha]? {
            let groupResult = await withTasksResult {
                await DoriAPI.Gacha.all()
            } _: {
                await DoriAPI.Card.all()
            }
            guard let gacha = groupResult.0 else { return nil }
            guard let cards = groupResult.1 else { return nil }
            
            var filteredGacha = gacha
            if filter.isFiltered {
                filteredGacha = gacha.filter {
                    filter.gachaType.contains($0.type)
                }.filter { gacha in
                    if filter.attribute == Set(Filter.Attribute.allCases) {
                        return true
                    }
                    let cards = cards.filter { gacha.newCards.contains($0.id) }
                    return filter.attribute.contains { cards.map { $0.attribute }.contains($0) }
                }.filter { gacha in
                    if filter.character == Set(Filter.Character.allCases) {
                        return true
                    }
                    let cards = cards.filter { gacha.newCards.contains($0.id) }
                    return filter.character.contains { cards.map { $0.characterID }.contains($0.rawValue) }
                }.filter { gacha in
                    for bool in filter.released {
                        for locale in filter.server {
                            if bool {
                                if (gacha.publishedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 4107477600)) < .now {
                                    return true
                                }
                            } else {
                                if (gacha.publishedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 0)) > .now {
                                    return true
                                }
                            }
                        }
                    }
                    return false
                }.filter { gacha in
                    for timelineStatus in filter.timelineStatus {
                        let result = switch timelineStatus {
                        case .ended:
                            (gacha.closedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 4107477600)) < .now
                        case .ongoing:
                            (gacha.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 4107477600)) < .now
                            && (gacha.closedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)) > .now
                        case .upcoming:
                            (gacha.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)) > .now
                        }
                        if result {
                            return true
                        }
                    }
                    return false
                }
            }
            
            switch filter.sort.keyword {
            case .releaseDate(let locale):
                return filteredGacha.sorted { lhs, rhs in
                    filter.sort.compare(
                        lhs.publishedAt.forLocale(locale) ?? lhs.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0),
                        rhs.publishedAt.forLocale(locale) ?? rhs.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)
                    )
                }
            default:
                return filteredGacha.sorted { lhs, rhs in
                    filter.sort.compare(lhs.id, rhs.id)
                }
            }
        }
        
        public static func extendedInformation(of id: Int) async -> ExtendedGacha? {
            let groupResult = await withTasksResult {
                await DoriAPI.Gacha.detail(of: id)
            } _: {
                await DoriAPI.Event.all()
            } _: {
                await DoriAPI.Card.all()
            }
            guard let gacha = groupResult.0 else { return nil }
            guard let events = groupResult.1 else { return nil }
            guard let cards = groupResult.2 else { return nil }
            
            if let pickupCardIDs = gacha.details.forPreferredLocale()?.filter({ $0.value.pickup }).keys {
                let cardDetails = gacha.details.map { dic in
                    if let dic {
                        return dic.compactMap { pair in
                            if let card = cards.first(where: { pair.key == $0.id }) {
                                (key: pair.value.rarityIndex, value: card)
                            } else {
                                nil
                            }
                        }.reduce(into: [Int: [DoriAPI.Card.PreviewCard]]()) { partialResult, pair in
                            if var value = partialResult[pair.key] {
                                value.append(pair.value)
                                partialResult.updateValue(value, forKey: pair.key)
                            } else {
                                partialResult.updateValue([pair.value], forKey: pair.key)
                            }
                        }
                    }
                    return nil
                }
                return .init(
                    id: id,
                    gacha: gacha,
                    events: events.filter { $0.startAt.forPreferredLocale() == gacha.publishedAt.forPreferredLocale() },
                    pickupCards: cards.filter { pickupCardIDs.contains($0.id) },
                    cardDetails: cardDetails.forPreferredLocale() ?? [:]
                )
            }
            return nil
        }
    }
}

extension DoriFrontend.Gacha {
    public typealias PreviewGacha = DoriAPI.Gacha.PreviewGacha
    public typealias Gacha = DoriAPI.Gacha.Gacha
    
    public struct ExtendedGacha: Sendable, Identifiable, DoriCache.Cacheable {
        public var id: Int
        public var gacha: Gacha
        public var events: [DoriAPI.Event.PreviewEvent]
        public var pickupCards: [DoriAPI.Card.PreviewCard]
        public var cardDetails: [Int: [DoriAPI.Card.PreviewCard]] // [Rarity: [Card]]
    }
}
