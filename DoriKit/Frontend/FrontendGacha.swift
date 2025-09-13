//===---*- Greatdori! -*---------------------------------------------------===//
//
// FrontendGacha.swift
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
    /// Request and fetch data about gacha in Bandori.
    public enum Gacha {
        /// List all gacha.
        ///
        /// - Returns: All gacha, nil if failed to fetch.
        public static func list() async -> [PreviewGacha]? {
            let groupResult = await withTasksResult {
                await DoriAPI.Gacha.all()
            } _: {
                await DoriAPI.Card.all()
            }
            guard let gacha = groupResult.0 else { return nil }
            guard let cards = groupResult.1 else { return nil }
            
            FilterCacheManager.shared.writeCardCache(cards)
            
            return gacha
        }
        
        /// Get detailed gacha with related information.
        ///
        /// - Parameter id: The ID of gacha.
        /// - Returns: The gacha of requested ID,
        ///     with related events and cards information.
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
    
    public struct ExtendedGacha: Sendable, Identifiable, Hashable, DoriCache.Cacheable {
        public var id: Int
        public var gacha: Gacha
        public var events: [DoriAPI.Event.PreviewEvent]
        public var pickupCards: [DoriAPI.Card.PreviewCard]
        public var cardDetails: [Int: [DoriAPI.Card.PreviewCard]] // [Rarity: [Card]]
    }
}
