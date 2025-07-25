//
//  Card.swift
//  Greatdori
//
//  Created by Mark Chan on 7/21/25.
//

import SwiftUI
import Foundation
internal import SwiftyJSON

extension DoriAPI {
    public class Card {
        private init() {}
        
        public static func all() async -> [PreviewCard]? {
            // Response example:
            // {
            //     "1": {
            //         "characterId": 1,
            //         "rarity": 1,
            //         "attribute": "pure",
            //         "levelLimit": 20,
            //         "resourceSetName": "res001001",
            //         "prefix": [
            //             "猪突猛進っ！",
            //             "Reckless!",
            //             "莽撞冒進！",
            //             "奋不顾身向前冲！",
            //             "저돌맹진!"
            //         ],
            //         "releasedAt": [
            //             "1489626000000",
            //             ...
            //         ],
            //         "skillId": 1,
            //         "type": "initial",
            //         "stat": {
            //             "1": {
            //                 "performance": 666,
            //                 "technique": 861,
            //                 "visual": 1239
            //             },
            //             "20": {
            //                 "performance": 1685,
            //                 "technique": 2178,
            //                 "visual": 3136
            //             },
            //             "episodes": [
            //                 {
            //                     "performance": 100,
            //                     "technique": 100,
            //                     "visual": 100
            //                 },
            //                 {
            //                     "performance": 200,
            //                     "technique": 200,
            //                     "visual": 200
            //                 }
            //             ]
            //         }
            //     },
            //     ...
            // }
            let request = await requestJSON("https://bestdori.com/api/cards/all.5.json")
            if case let .success(respJSON) = request {
                var result = [PreviewCard]()
                for (key, value) in respJSON {
                    var stats = CardStat()
                    for (k, v) in value["stat"] {
                        if let level = Int(k) {
                            stats.updateValue(
                                [.init(
                                    performance: v["performance"].intValue,
                                    technique: v["technique"].intValue,
                                    visual: v["visual"].intValue
                                )],
                                forKey: .level(level)
                            )
                        } else if k == "episodes" {
                            stats.updateValue(
                                v["episodes"].map {
                                    Stat(performance: $0.1["performance"].intValue,
                                         technique: $0.1["technique"].intValue,
                                         visual: $0.1["visual"].intValue)
                                },
                                forKey: .episodes
                            )
                        }
                    }
                    result.append(.init(
                        id: Int(key) ?? 0,
                        characterID: value["characterId"].intValue,
                        rarity: value["rarity"].intValue,
                        attribute: .init(rawValue: value["attribute"].stringValue) ?? .pure,
                        levelLimit: value["levelLimit"].intValue,
                        resourceSetName: value["resourceSetName"].stringValue,
                        prefix: .init(
                            jp: value["prefix"][0].string,
                            en: value["prefix"][1].string,
                            tw: value["prefix"][2].string,
                            cn: value["prefix"][3].string,
                            kr: value["prefix"][4].string
                        ),
                        releasedAt: .init(
                            jp: value["releasedAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(value["releasedAt"][0].stringValue.dropLast(3))!)) : nil,
                            en: value["releasedAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(value["releasedAt"][1].stringValue.dropLast(3))!)) : nil,
                            tw: value["releasedAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(value["releasedAt"][2].stringValue.dropLast(3))!)) : nil,
                            cn: value["releasedAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(value["releasedAt"][3].stringValue.dropLast(3))!)) : nil,
                            kr: value["releasedAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(value["releasedAt"][4].stringValue.dropLast(3))!)) : nil
                        ),
                        skillID: value["skillId"].intValue,
                        type: .init(rawValue: value["type"].stringValue) ?? .others,
                        stat: stats
                    ))
                }
                return result.sorted { $0.id < $1.id }
            }
            return nil
        }
        
        public static func detail(of id: Int) async -> Card? {
            // Response example:
            // {
            //     "characterId": 36,
            //     "rarity": 5,
            //     "attribute": "cool",
            //     "levelLimit": 50,
            //     "resourceSetName": "res036008",
            //     "sdResourceName": "sd036008",
            //     "episodes": {
            //         "entries": [
            //             {
            //                 "episodeId": 3169,
            //                 "episodeType": "standard",
            //                 "situationId": 1937,
            //                 "scenarioId": "episode1937",
            //                 "appendPerformance": 250,
            //                 "appendTechnique": 250,
            //                 "appendVisual": 250,
            //                 "releaseLevel": 1,
            //                 "costs": {
            //                     "entries": [
            //                         {
            //                             "resourceId": 2,
            //                             "resourceType": "item",
            //                             "quantity": 500,
            //                             "lbBonus": 1
            //                         },
            //                         ...
            //                     ]
            //                 },
            //                 "rewards": {
            //                     "entries": [
            //                         {
            //                             "resourceType": "star",
            //                             "quantity": 25,
            //                             "lbBonus": 1
            //                         }
            //                     ]
            //                 },
            //                 "title": [
            //                     "強くなりたい",
            //                     "I Want To Become Stronger",
            //                     "想變強",
            //                     "想要变强",
            //                     null
            //                 ],
            //                 "characterId": 36
            //             },
            //             ...
            //         ]
            //     },
            //     "costumeId": 1890,
            //     "gachaText": [
            //         "！　負けた……",
            //         ...
            //     ],
            //     "prefix": [
            //         "運命の一枚",
            //         ...
            //     ],
            //     "releasedAt": [
            //         "1708408800000",
            //         ...
            //     ],
            //     "skillName": [
            //         "透き通った色",
            //         ...
            //     ],
            //     "skillId": 67,
            //     "source": [
            //         {
            //             "gacha": {
            //                 "1281": {
            //                     "probability": 0.005009016229212583
            //                 },
            //                 ...
            //             }
            //         },
            //         ...
            //     ],
            //     "type": "permanent",
            //     "stat": {
            //         "1": {
            //             "performance": 3514,
            //             "technique": 3789,
            //             "visual": 3493
            //         },
            //         ...,
            //         "episodes": [
            //             {
            //                 "performance": 250,
            //                 "technique": 250,
            //                 "visual": 250
            //             },
            //             {
            //                 "performance": 600,
            //                 "technique": 600,
            //                 "visual": 600
            //             }
            //         ],
            //         "training": {
            //             "levelLimit": 10,
            //             "performance": 400,
            //             "technique": 400,
            //             "visual": 400
            //         }
            //     }
            // }
            let request = await requestJSON("https://bestdori.com/api/cards/\(id).json")
            if case let .success(respJSON) = request {
                var episodes = [CardEpisode]()
                for episode in respJSON["episodes"]["entries"] {
                    episodes.append(.init(
                        id: episode.1["episodeId"].intValue,
                        episodeType: .init(rawValue: episode.1["episodeType"].stringValue) ?? .standard,
                        situationID: episode.1["situationId"].intValue,
                        scenarioID: episode.1["scenarioId"].stringValue,
                        appendPerformance: episode.1["appendPerformance"].intValue,
                        appendTechnique: episode.1["appendTechnique"].intValue,
                        appendVisual: episode.1["appendVisual"].intValue,
                        releaseLevel: episode.1["releaseLevel"].intValue,
                        costs: episode.1["costs"]["entries"].map {
                            CardEpisode.Resource(
                                resourceID: $0.1["resourceId"].int,
                                resourceType: .init(rawValue: $0.1["resourceType"].stringValue) ?? .item,
                                quantity: $0.1["quantity"].intValue,
                                lbBonus: $0.1["lbBonus"].intValue
                            )
                        },
                        rewards: episode.1["costs"]["rewards"].map {
                            CardEpisode.Resource(
                                resourceID: $0.1["resourceId"].int,
                                resourceType: .init(rawValue: $0.1["resourceType"].stringValue) ?? .item,
                                quantity: $0.1["quantity"].intValue,
                                lbBonus: $0.1["lbBonus"].intValue
                            )
                        },
                        title: .init(
                            jp: episode.1["title"][0].string,
                            en: episode.1["title"][1].string,
                            tw: episode.1["title"][2].string,
                            cn: episode.1["title"][3].string,
                            kr: episode.1["title"][4].string
                        ),
                        characterID: episode.1["characterId"].intValue
                    ))
                }
                var stats = CardStat()
                for (key, value) in respJSON["stat"] {
                    if let level = Int(key) {
                        stats.updateValue(
                            [.init(
                                performance: value["performance"].intValue,
                                technique: value["technique"].intValue,
                                visual: value["visual"].intValue
                            )],
                            forKey: .level(level)
                        )
                    } else if key == "episodes" {
                        stats.updateValue(
                            value["episodes"].map {
                                Stat(performance: $0.1["performance"].intValue,
                                     technique: $0.1["technique"].intValue,
                                     visual: $0.1["visual"].intValue)
                            },
                            forKey: .episodes
                        )
                    } else if key == "training" {
                        stats.updateValue(
                            [.init(
                                performance: value["performance"].intValue,
                                technique: value["technique"].intValue,
                                visual: value["visual"].intValue
                            )],
                            forKey: .training
                        )
                    }
                }
                
                func cardSource(atLocalizedIndex index: Int) -> Set<Card.CardSource>? {
                    let array = respJSON["source"][index].compactMap {
                        switch $0.0 {
                        case "gacha":
                            Card.CardSource.gacha(
                                $0.1.map {
                                    (key: Int($0.0) ?? 0, value: $0.1["probability"].doubleValue)
                                }.reduce(into: [Int: Double]()) {
                                    $0.updateValue(
                                        $1.value,
                                        forKey: $1.key
                                    )
                                }
                            )
                        case "event":
                            Card.CardSource.event(
                                $0.1.map {
                                    (key: Int($0.0) ?? 0, value: $0.1["point"].intValue)
                                }.reduce(into: [Int: Int]()) {
                                    $0.updateValue(
                                        $1.value,
                                        forKey: $1.key
                                    )
                                }
                            )
                        case "login":
                            Card.CardSource.login(ids: $0.1.map { Int($0.0) ?? 0 })
                        default:
                            nil
                        }
                    }
                    guard !array.isEmpty else { return nil }
                    return .init(array)
                }
                return .init(
                    id: id,
                    characterID: respJSON["characterId"].intValue,
                    rarity: respJSON["rarity"].intValue,
                    attribute: .init(rawValue: respJSON["attribute"].stringValue) ?? .pure,
                    levelLimit: respJSON["levelLimit"].intValue,
                    resourceSetName: respJSON["resourceSetName"].stringValue,
                    sdResourceName: respJSON["sdResourceName"].stringValue,
                    episodes: episodes,
                    costumeID: respJSON["costumeId"].intValue,
                    gachaText: .init(
                        jp: respJSON["gachaText"][0].string,
                        en: respJSON["gachaText"][1].string,
                        tw: respJSON["gachaText"][2].string,
                        cn: respJSON["gachaText"][3].string,
                        kr: respJSON["gachaText"][4].string
                    ),
                    prefix: .init(
                        jp: respJSON["prefix"][0].string,
                        en: respJSON["prefix"][1].string,
                        tw: respJSON["prefix"][2].string,
                        cn: respJSON["prefix"][3].string,
                        kr: respJSON["prefix"][4].string
                    ),
                    releasedAt: .init(
                        jp: respJSON["releasedAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["releasedAt"][0].stringValue.dropLast(3))!)) : nil,
                        en: respJSON["releasedAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["releasedAt"][1].stringValue.dropLast(3))!)) : nil,
                        tw: respJSON["releasedAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["releasedAt"][2].stringValue.dropLast(3))!)) : nil,
                        cn: respJSON["releasedAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["releasedAt"][3].stringValue.dropLast(3))!)) : nil,
                        kr: respJSON["releasedAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["releasedAt"][4].stringValue.dropLast(3))!)) : nil
                    ),
                    skillName: .init(
                        jp: respJSON["skillName"][0].string,
                        en: respJSON["skillName"][1].string,
                        tw: respJSON["skillName"][2].string,
                        cn: respJSON["skillName"][3].string,
                        kr: respJSON["skillName"][4].string
                    ),
                    skillID: respJSON["skillId"].intValue,
                    source: .init(
                        jp: cardSource(atLocalizedIndex: 0),
                        en: cardSource(atLocalizedIndex: 1),
                        tw: cardSource(atLocalizedIndex: 2),
                        cn: cardSource(atLocalizedIndex: 3),
                        kr: cardSource(atLocalizedIndex: 4)
                    ),
                    type: .init(rawValue: respJSON["type"].stringValue) ?? .others,
                    stat: stats
                )
            }
            return nil
        }
    }
}

extension DoriAPI.Card {
    public struct PreviewCard: Identifiable {
        public var id: Int
        public var characterID: Int
        public var rarity: Int
        public var attribute: DoriAPI.Attribute
        public var levelLimit: Int
        public var resourceSetName: String
        public var prefix: DoriAPI.LocalizedData<String>
        public var releasedAt: DoriAPI.LocalizedData<Date>
        public var skillID: Int
        public var type: CardType
        public var stat: CardStat
    }
    
    public struct Card: Identifiable {
        public var id: Int
        public var characterID: Int
        public var rarity: Int
        public var attribute: DoriAPI.Attribute
        public var levelLimit: Int
        public var resourceSetName: String
        public var sdResourceName: String
        public var episodes: [CardEpisode]
        public var costumeID: Int
        public var gachaText: DoriAPI.LocalizedData<String>
        public var prefix: DoriAPI.LocalizedData<String>
        public var releasedAt: DoriAPI.LocalizedData<Date>
        public var skillName: DoriAPI.LocalizedData<String>
        public var skillID: Int
        public var source: DoriAPI.LocalizedData<Set<CardSource>>
        public var type: CardType
        public var stat: CardStat
        
        public enum CardSource: Hashable {
            case gacha([Int: Double]) // [gachaID: probability]
            case event([Int: Int]) // [eventID: point]
            case login(ids: [Int])
        }
    }
    
    public enum CardType: String, CaseIterable {
        case initial
        case permanent
        case event
        case limited
        case campaign
        case kirafes
        case dreamfes
        case special
        case birthday
        case others
    }
    
    public struct CardEpisode: Identifiable {
        public var id: Int
        public var episodeType: EpisodeType
        public var situationID: Int
        public var scenarioID: String
        public var appendPerformance: Int
        public var appendTechnique: Int
        public var appendVisual: Int
        public var releaseLevel: Int
        public var costs: [Resource]
        public var rewards: [Resource]
        public var title: DoriAPI.LocalizedData<String>
        public var characterID: Int
        
        public enum EpisodeType: String {
            case standard
            case memorial
        }
        public struct Resource {
            public var resourceID: Int?
            public var resourceType: ResourceType
            public var quantity: Int
            public var lbBonus: Int
            
            internal init(resourceID: Int?, resourceType: ResourceType, quantity: Int, lbBonus: Int) {
                self.resourceID = resourceID
                self.resourceType = resourceType
                self.quantity = quantity
                self.lbBonus = lbBonus
            }
            
            public enum ResourceType: String {
                case item
                case star
            }
        }
    }
    
    public typealias CardStat = [StatKey: [Stat]]
    public struct Stat {
        public var performance: Int
        public var technique: Int
        public var visual: Int
        
        @usableFromInline
        init(performance: Int, technique: Int, visual: Int) {
            self.performance = performance
            self.technique = technique
            self.visual = visual
        }
        
        @inlinable
        public var total: Int {
            performance + technique + visual
        }
    }
    public enum StatKey: Hashable {
        case level(Int)
        case episodes
        case training
    }
}

extension DoriAPI.Card.Card {
    @inlinable
    public init?(id: Int) async {
        if let card = await DoriAPI.Card.detail(of: id) {
            self = card
        }
        return nil
    }
    
    @inlinable
    public init?(preview: DoriAPI.Card.PreviewCard) async {
        await self.init(id: preview.id)
    }
}

extension DoriAPI.Card.Stat: AdditiveArithmetic {
    public static let zero: Self = .init(performance: 0, technique: 0, visual: 0)
    
    @_transparent
    public static func +(lhs: Self, rhs: Self) -> Self {
        .init(
            performance: lhs.performance + rhs.performance,
            technique: lhs.technique + rhs.technique,
            visual: lhs.visual + rhs.visual
        )
    }
    @_transparent
    public static func +=(a: inout Self, b: Self) {
        a = a + b
    }
    @_transparent
    public static func -(lhs: Self, rhs: Self) -> Self {
        .init(
            performance: lhs.performance - rhs.performance,
            technique: lhs.technique - rhs.technique,
            visual: lhs.visual - rhs.visual
        )
    }
    @_transparent
    public static func -=(a: inout Self, b: Self) {
        a = a - b
    }
    @_transparent
    public static func *(lhs: Self, rhs: Int) -> Self {
        .init(
            performance: lhs.performance * rhs,
            technique: lhs.technique * rhs,
            visual: lhs.visual * rhs
        )
    }
    @_transparent
    public static func *=(a: inout Self, b: Int) {
        a = a * b
    }
}
extension DoriAPI.Card.CardStat {
    @inlinable
    public var minimumLevel: Int? {
        self.keys
            .compactMap { if case let .level(level) = $0 { level } else { nil } }
            .sorted { $0 < $1 }
            .first
    }
    @inlinable
    public var maximumLevel: Int? {
        self.keys
            .compactMap { if case let .level(level) = $0 { level } else { nil } }
            .sorted { $0 > $1 }
            .first
    }
    
    @inlinable
    public func forMinimumLevel() -> DoriAPI.Card.Stat? {
        guard let level = minimumLevel else { return nil }
        return self[.level(level)]![0]
    }
    @inlinable
    public func forMaximumLevel() -> DoriAPI.Card.Stat? {
        guard let level = maximumLevel else { return nil }
        return self[.level(level)]![0]
    }
    
    @inlinable
    public func calculated(
        level: Int,
        rarity: Int,
        masterRank: Int,
        viewedStoryCount: Int,
        trained: Bool
    ) -> DoriAPI.Card.Stat? {
        guard let minimumLevel, let maximumLevel else { return nil }
        guard minimumLevel...maximumLevel ~= level else { return nil }
        guard 1...5 ~= rarity else { return nil }
        guard 0...4 ~= masterRank else { return nil }
        guard 0...2 ~= viewedStoryCount else { return nil }
        
        guard var result = self[.level(level)]?[0] else { return nil }
        let episodeCount = self[.episodes]?.count ?? 0
        result += DoriAPI.Card.Stat(performance: 50, technique: 50, visual: 50) * rarity
        if viewedStoryCount >= 1, episodeCount >= 1 {
            result += self[.episodes]![0]
        }
        if viewedStoryCount >= 2, episodeCount >= 2 {
            result += self[.episodes]![1]
        }
        if let training = self[.training]?[0], trained {
            result += training
        }
        
        return result
    }
    
    @inlinable
    public func maximumValue(rarity: Int) -> DoriAPI.Card.Stat? {
        guard let maximumLevel else { return nil }
        return calculated(
            level: maximumLevel,
            rarity: rarity,
            masterRank: 4,
            viewedStoryCount: 2,
            trained: true
        )
    }
}
