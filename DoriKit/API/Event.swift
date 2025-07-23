//
//  Event.swift
//  Greatdori
//
//  Created by Mark Chan on 7/21/25.
//

import SwiftUI
import Foundation
internal import SwiftyJSON

extension DoriAPI {
    public class Event {
        private init() {}
        
        public static func all() async -> [PreviewEvent]? {
            // Response example:
            // {
            //     "1": {
            //         "eventType": "story",
            //         "eventName": [
            //             "SAKURA＊BLOOMING PARTY!",
            //             "SAKURA＊BLOOMING PARTY!",
            //             "SAKURA＊BLOOMING PARTY!",
            //             "SAKURA＊BLOOMING PARTY!",
            //             "CHERRY＊BLOOMING PARTY!"
            //         ],
            //         "assetBundleName": "sakura",
            //         "bannerAssetBundleName": "banner-016",
            //         "startAt": [
            //             "1490335200000",
            //             ...
            //         ],
            //         "endAt": [
            //             "1490875200000",
            //             ...
            //         ],
            //         "attributes": [
            //             {
            //                 "attribute": "pure",
            //                 "percent": 20
            //             }
            //         ],
            //         "characters": [
            //             {
            //                 "characterId": 5,
            //                 "percent": 70
            //             },
            //             ...
            //         ],
            //         "members": [],
            //         "limitBreaks": [],
            //         "rewardCards": [
            //             105,
            //             101
            //         ]
            //     },
            //     ...
            // }
            let request = await requestJSON("https://bestdori.com/api/events/all.5.json")
            if case let .success(respJSON) = request {
                var result = [PreviewEvent]()
                for (key, value) in respJSON {
                    result.append(.init(
                        id: Int(key) ?? 0,
                        eventType: .init(rawValue: value["eventType"].stringValue) ?? .story,
                        eventName: .init(
                            jp: value["eventName"][0].string,
                            en: value["eventName"][1].string,
                            tw: value["eventName"][2].string,
                            cn: value["eventName"][3].string,
                            kr: value["eventName"][4].string
                        ),
                        assetBundleName: value["assetBundleName"].stringValue,
                        bannerAssetBundleName: value["bannerAssetBundleName"].stringValue,
                        startAt: .init(
                            jp: value["startAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(value["startAt"][0].stringValue.dropLast(3))!)) : nil,
                            en: value["startAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(value["startAt"][1].stringValue.dropLast(3))!)) : nil,
                            tw: value["startAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(value["startAt"][2].stringValue.dropLast(3))!)) : nil,
                            cn: value["startAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(value["startAt"][3].stringValue.dropLast(3))!)) : nil,
                            kr: value["startAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(value["startAt"][4].stringValue.dropLast(3))!)) : nil
                        ),
                        endAt: .init(
                            jp: value["endAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(value["endAt"][0].stringValue.dropLast(3))!)) : nil,
                            en: value["endAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(value["endAt"][1].stringValue.dropLast(3))!)) : nil,
                            tw: value["endAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(value["endAt"][2].stringValue.dropLast(3))!)) : nil,
                            cn: value["endAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(value["endAt"][3].stringValue.dropLast(3))!)) : nil,
                            kr: value["endAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(value["endAt"][4].stringValue.dropLast(3))!)) : nil
                        ),
                        attributes: value["attributes"].map {
                            EventAttribute(
                                eventID: $0.1["eventId"].int,
                                attribute: .init(rawValue: $0.1["attribute"].stringValue) ?? .pure,
                                percent: $0.1["percent"].intValue
                            )
                        },
                        characters: value["characters"].map {
                            EventCharacter(
                                eventID: $0.1["eventId"].int,
                                characterID: $0.1["characterId"].intValue,
                                percent: $0.1["percent"].intValue,
                                seq: $0.1["seq"].int
                            )
                        },
                        eventAttributeAndCharacterBonus: value["eventAttributeAndCharacterBonus"]["eventId"].int != nil ? .init(
                            eventID: value["eventAttributeAndCharacterBonus"]["eventId"].intValue,
                            pointPercent: value["eventAttributeAndCharacterBonus"]["pointPercent"].intValue,
                            parameterPercent: value["eventAttributeAndCharacterBonus"]["parameterPercent"].intValue
                        ) : nil,
                        members: value["members"].map {
                            EventMember(
                                eventID: $0.1["eventId"].int,
                                situationID: $0.1["situationId"].intValue,
                                percent: $0.1["percent"].intValue,
                                seq: $0.1["seq"].int
                            )
                        },
                        limitBreaks: value["limitBreaks"].map {
                            EventLimitBreak(
                                rarity: $0.1["rarity"].intValue,
                                rank: $0.1["rank"].intValue,
                                percent: $0.1["percent"].doubleValue
                            )
                        },
                        rewardCards: value["rewardCards"].map { $0.1.intValue }
                    ))
                }
                return result.sorted { $0.id < $1.id }
            }
            return nil
        }
        
        public static func detail(of id: Int) async -> Event? {
            // Response example:
            // {
            //     "eventType": "mission_live",
            //     "eventName": [
            //         "雨上がり、瞳に映る空は",
            //         "After the Rain, What Sky Reflected in Her Eyes",
            //         null,
            //         null,
            //         null
            //     ],
            //     "assetBundleName": "ammeagari_sora",
            //     "bannerAssetBundleName": "banner_event297",
            //     "startAt": [
            //         "1749535200000",
            //         ...
            //     ],
            //     "endAt": [
            //         "1750247999000",
            //         ...
            //     ],
            //     "enableFlag": [ // This attribute is not provided in Swift API. How does it works?
            //         null,
            //         ...
            //     ],
            //     "publicStartAt": [
            //         "1749535200000",
            //         ...
            //     ],
            //     "publicEndAt": [
            //         "1750399199000",
            //         ...
            //     ],
            //     "distributionStartAt": [
            //         "1750298400000",
            //         ...
            //     ],
            //     "distributionEndAt": [
            //         "1751554800000",
            //         ...
            //     ],
            //     "bgmAssetBundleName": "sound/scenario/bgm/63_longing",
            //     "bgmFileName": "63_longing",
            //     "aggregateEndAt": [
            //         "1750249799000",
            //         ...
            //     ],
            //     "exchangeEndAt": [
            //         "1751025599000",
            //         ...
            //     ],
            //     "pointRewards": [
            //         [
            //             {
            //                 "point": "1000",
            //                 "rewardType": "star",
            //                 "rewardQuantity": 50
            //             },
            //             ...
            //         ],
            //         ...
            //     ],
            //     "rankingRewards": [
            //         [
            //             {
            //                 "fromRank": 1,
            //                 "toRank": 1,
            //                 "rewardType": "degree",
            //                 "rewardId": 8025,
            //                 "rewardQuantity": 1
            //             },
            //             ...
            //         ],
            //         ...
            //     ],
            //     "attributes": [
            //         {
            //             "attribute": "powerful",
            //             "percent": 10
            //         }
            //     ],
            //     "characters": [
            //         {
            //             "characterId": 36,
            //             "percent": 20
            //         },
            //         ...
            //     ],
            //     "eventAttributeAndCharacterBonus": {
            //         "pointPercent": 20,
            //         "parameterPercent": 0
            //     },
            //     "members": [
            //         {
            //             "eventId": 297,
            //             "situationId": 2231,
            //             "percent": 20,
            //             "seq": 1
            //         },
            //         ...
            //     ],
            //     "limitBreaks": [
            //         {
            //             "rarity": 1,
            //             "rank": 0,
            //             "percent": 0
            //         },
            //         ...
            //     ],
            //     "stories": [
            //         {
            //             "scenarioId": "event297-01",
            //             "coverImage": "297_0",
            //             "backgroundImage": "0",
            //             "releasePt": "0",
            //             "rewards": [
            //                 {
            //                     "rewardType": "item",
            //                     "rewardId": 13,
            //                     "rewardQuantity": 1
            //                 },
            //                 ...
            //             ],
            //             "caption": [
            //                 "オープニング",
            //                 ...
            //             ],
            //             "title": [
            //                 "幕が開いて",
            //                 ...
            //             ],
            //             "synopsis": [
            //                 "Ave Mujicaのライブを観に行った\n愛音とそよ。そこにいたのは――",
            //                 ...
            //             ],
            //             "releaseConditions": [
            //                 "オープニングシナリオ",
            //                 ...
            //             ]
            //         },
            //         ...
            //     ],
            //     "rewardCards": [
            //         2235,
            //         2234
            //     ]
            // }
            let request = await requestJSON("https://bestdori.com/api/events/\(id).json")
            if case let .success(respJSON) = request {
                // We break up expressions because of:
                // The compiler is unable to type-check this expression in reasonable time;
                // try breaking up the expression into distinct sub-expressions 😇
                let pointRewards = DoriAPI.LocalizedData(
                    jp: respJSON["pointRewards"][0].map {
                        Event.PointReward(
                            point: Int($0.1["point"].stringValue) ?? 0,
                            rewardType: .init(rawValue: $0.1["rewardType"].stringValue) ?? .item,
                            rewardID: $0.1["rewardId"].int,
                            rewardQuantity: $0.1["rewardQuantity"].intValue
                        )
                    },
                    en: respJSON["pointRewards"][1].map {
                        Event.PointReward(
                            point: Int($0.1["point"].stringValue) ?? 0,
                            rewardType: .init(rawValue: $0.1["rewardType"].stringValue) ?? .item,
                            rewardID: $0.1["rewardId"].int,
                            rewardQuantity: $0.1["rewardQuantity"].intValue
                        )
                    },
                    tw: respJSON["pointRewards"][2].map {
                        Event.PointReward(
                            point: Int($0.1["point"].stringValue) ?? 0,
                            rewardType: .init(rawValue: $0.1["rewardType"].stringValue) ?? .item,
                            rewardID: $0.1["rewardId"].int,
                            rewardQuantity: $0.1["rewardQuantity"].intValue
                        )
                    },
                    cn: respJSON["pointRewards"][3].map {
                        Event.PointReward(
                            point: Int($0.1["point"].stringValue) ?? 0,
                            rewardType: .init(rawValue: $0.1["rewardType"].stringValue) ?? .item,
                            rewardID: $0.1["rewardId"].int,
                            rewardQuantity: $0.1["rewardQuantity"].intValue
                        )
                    },
                    kr: respJSON["pointRewards"][4].map {
                        Event.PointReward(
                            point: Int($0.1["point"].stringValue) ?? 0,
                            rewardType: .init(rawValue: $0.1["rewardType"].stringValue) ?? .item,
                            rewardID: $0.1["rewardId"].int,
                            rewardQuantity: $0.1["rewardQuantity"].intValue
                        )
                    }
                )
                let rankingRewards = DoriAPI.LocalizedData(
                    jp: respJSON["rankingRewards"][0].map {
                        Event.RankingReward(
                            rankRange: $0.1["fromRank"].intValue...$0.1["toRank"].intValue,
                            rewardType: .init(rawValue: $0.1["rewardType"].stringValue) ?? .item,
                            rewardID: $0.1["rewardId"].int,
                            rewardQuantity: $0.1["rewardQuantity"].intValue
                        )
                    },
                    en: respJSON["rankingRewards"][1].map {
                        Event.RankingReward(
                            rankRange: $0.1["fromRank"].intValue...$0.1["toRank"].intValue,
                            rewardType: .init(rawValue: $0.1["rewardType"].stringValue) ?? .item,
                            rewardID: $0.1["rewardId"].int,
                            rewardQuantity: $0.1["rewardQuantity"].intValue
                        )
                    },
                    tw: respJSON["rankingRewards"][2].map {
                        Event.RankingReward(
                            rankRange: $0.1["fromRank"].intValue...$0.1["toRank"].intValue,
                            rewardType: .init(rawValue: $0.1["rewardType"].stringValue) ?? .item,
                            rewardID: $0.1["rewardId"].int,
                            rewardQuantity: $0.1["rewardQuantity"].intValue
                        )
                    },
                    cn: respJSON["rankingRewards"][3].map {
                        Event.RankingReward(
                            rankRange: $0.1["fromRank"].intValue...$0.1["toRank"].intValue,
                            rewardType: .init(rawValue: $0.1["rewardType"].stringValue) ?? .item,
                            rewardID: $0.1["rewardId"].int,
                            rewardQuantity: $0.1["rewardQuantity"].intValue
                        )
                    },
                    kr: respJSON["rankingRewards"][4].map {
                        Event.RankingReward(
                            rankRange: $0.1["fromRank"].intValue...$0.1["toRank"].intValue,
                            rewardType: .init(rawValue: $0.1["rewardType"].stringValue) ?? .item,
                            rewardID: $0.1["rewardId"].int,
                            rewardQuantity: $0.1["rewardQuantity"].intValue
                        )
                    },
                )
                return .init(
                    id: id,
                    eventType: .init(rawValue: respJSON["eventType"].stringValue) ?? .story,
                    eventName: .init(
                        jp: respJSON["eventName"][0].string,
                        en: respJSON["eventName"][1].string,
                        tw: respJSON["eventName"][2].string,
                        cn: respJSON["eventName"][3].string,
                        kr: respJSON["eventName"][4].string
                    ),
                    assetBundleName: respJSON["assetBundleName"].stringValue,
                    bannerAssetBundleName: respJSON["bannerAssetBundleName"].stringValue,
                    startAt: .init(
                        jp: respJSON["startAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["startAt"][0].stringValue.dropLast(3))!)) : nil,
                        en: respJSON["startAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["startAt"][1].stringValue.dropLast(3))!)) : nil,
                        tw: respJSON["startAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["startAt"][2].stringValue.dropLast(3))!)) : nil,
                        cn: respJSON["startAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["startAt"][3].stringValue.dropLast(3))!)) : nil,
                        kr: respJSON["startAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["startAt"][4].stringValue.dropLast(3))!)) : nil
                    ),
                    endAt: .init(
                        jp: respJSON["endAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["endAt"][0].stringValue.dropLast(3))!)) : nil,
                        en: respJSON["endAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["endAt"][1].stringValue.dropLast(3))!)) : nil,
                        tw: respJSON["endAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["endAt"][2].stringValue.dropLast(3))!)) : nil,
                        cn: respJSON["endAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["endAt"][3].stringValue.dropLast(3))!)) : nil,
                        kr: respJSON["endAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["endAt"][4].stringValue.dropLast(3))!)) : nil
                    ),
                    publicStartAt: .init(
                        jp: respJSON["publicStartAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["publicStartAt"][0].stringValue.dropLast(3))!)) : nil,
                        en: respJSON["publicStartAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["publicStartAt"][1].stringValue.dropLast(3))!)) : nil,
                        tw: respJSON["publicStartAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["publicStartAt"][2].stringValue.dropLast(3))!)) : nil,
                        cn: respJSON["publicStartAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["publicStartAt"][3].stringValue.dropLast(3))!)) : nil,
                        kr: respJSON["publicStartAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["publicStartAt"][4].stringValue.dropLast(3))!)) : nil
                    ),
                    publicEndAt: .init(
                        jp: respJSON["publicEndAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["publicEndAt"][0].stringValue.dropLast(3))!)) : nil,
                        en: respJSON["publicEndAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["publicEndAt"][1].stringValue.dropLast(3))!)) : nil,
                        tw: respJSON["publicEndAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["publicEndAt"][2].stringValue.dropLast(3))!)) : nil,
                        cn: respJSON["publicEndAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["publicEndAt"][3].stringValue.dropLast(3))!)) : nil,
                        kr: respJSON["publicEndAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["publicEndAt"][4].stringValue.dropLast(3))!)) : nil
                    ),
                    distributionStartAt: .init(
                        jp: respJSON["distributionStartAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["distributionStartAt"][0].stringValue.dropLast(3))!)) : nil,
                        en: respJSON["distributionStartAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["distributionStartAt"][1].stringValue.dropLast(3))!)) : nil,
                        tw: respJSON["distributionStartAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["distributionStartAt"][2].stringValue.dropLast(3))!)) : nil,
                        cn: respJSON["distributionStartAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["distributionStartAt"][3].stringValue.dropLast(3))!)) : nil,
                        kr: respJSON["distributionStartAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["distributionStartAt"][4].stringValue.dropLast(3))!)) : nil
                    ),
                    distributionEndAt: .init(
                        jp: respJSON["distributionEndAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["distributionEndAt"][0].stringValue.dropLast(3))!)) : nil,
                        en: respJSON["distributionEndAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["distributionEndAt"][1].stringValue.dropLast(3))!)) : nil,
                        tw: respJSON["distributionEndAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["distributionEndAt"][2].stringValue.dropLast(3))!)) : nil,
                        cn: respJSON["distributionEndAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["distributionEndAt"][3].stringValue.dropLast(3))!)) : nil,
                        kr: respJSON["distributionEndAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["distributionEndAt"][4].stringValue.dropLast(3))!)) : nil
                    ),
                    bgmAssetBundleName: respJSON["bgmAssetBundleName"].stringValue,
                    bgmFileName: respJSON["bgmFileName"].stringValue,
                    aggregateEndAt: .init(
                        jp: respJSON["aggregateEndAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["aggregateEndAt"][0].stringValue.dropLast(3))!)) : nil,
                        en: respJSON["aggregateEndAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["aggregateEndAt"][1].stringValue.dropLast(3))!)) : nil,
                        tw: respJSON["aggregateEndAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["aggregateEndAt"][2].stringValue.dropLast(3))!)) : nil,
                        cn: respJSON["aggregateEndAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["aggregateEndAt"][3].stringValue.dropLast(3))!)) : nil,
                        kr: respJSON["aggregateEndAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["aggregateEndAt"][4].stringValue.dropLast(3))!)) : nil
                    ),
                    exchangeEndAt: .init(
                        jp: respJSON["exchangeEndAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["exchangeEndAt"][0].stringValue.dropLast(3))!)) : nil,
                        en: respJSON["exchangeEndAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["exchangeEndAt"][1].stringValue.dropLast(3))!)) : nil,
                        tw: respJSON["exchangeEndAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["exchangeEndAt"][2].stringValue.dropLast(3))!)) : nil,
                        cn: respJSON["exchangeEndAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["exchangeEndAt"][3].stringValue.dropLast(3))!)) : nil,
                        kr: respJSON["exchangeEndAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(respJSON["exchangeEndAt"][4].stringValue.dropLast(3))!)) : nil
                    ),
                    pointRewards: pointRewards,
                    rankingRewards: rankingRewards,
                    attributes: respJSON["attributes"].map {
                        EventAttribute(
                            eventID: $0.1["eventId"].int,
                            attribute: .init(rawValue: $0.1["attribute"].stringValue) ?? .pure,
                            percent: $0.1["percent"].intValue
                        )
                    },
                    characters: respJSON["characters"].map {
                        EventCharacter(
                            eventID: $0.1["eventId"].int,
                            characterID: $0.1["characterId"].intValue,
                            percent: $0.1["percent"].intValue,
                            seq: $0.1["seq"].int
                        )
                    },
                    eventAttributeAndCharacterBonus: respJSON["eventAttributeAndCharacterBonus"]["eventId"].int != nil ? .init(
                        eventID: respJSON["eventAttributeAndCharacterBonus"]["eventId"].intValue,
                        pointPercent: respJSON["eventAttributeAndCharacterBonus"]["pointPercent"].intValue,
                        parameterPercent: respJSON["eventAttributeAndCharacterBonus"]["parameterPercent"].intValue
                    ) : nil,
                    members: respJSON["members"].map {
                        EventMember(
                            eventID: $0.1["eventId"].int,
                            situationID: $0.1["situationId"].intValue,
                            percent: $0.1["percent"].intValue,
                            seq: $0.1["seq"].int
                        )
                    },
                    limitBreaks: respJSON["limitBreaks"].map {
                        EventLimitBreak(
                            rarity: $0.1["rarity"].intValue,
                            rank: $0.1["rank"].intValue,
                            percent: $0.1["percent"].doubleValue
                        )
                    },
                    stories: respJSON["stories"].map {
                        Event.Story(
                            scenarioID: $0.1["scenarioId"].stringValue,
                            coverImage: $0.1["coverImage"].stringValue,
                            backgroundImage: $0.1["backgroundImage"].stringValue,
                            releasePt: Int($0.1["releasePt"].stringValue) ?? 0,
                            rewards: $0.1["rewards"].map {
                                Event.Story.Reward(
                                    rewardType: .init(rawValue: $0.1["rewardType"].stringValue) ?? .item,
                                    rewardID: $0.1["rewardId"].int,
                                    rewardQuantity: $0.1["rewardQuantity"].intValue
                                )
                            },
                            caption: .init(
                                jp: $0.1["caption"][0].string,
                                en: $0.1["caption"][1].string,
                                tw: $0.1["caption"][2].string,
                                cn: $0.1["caption"][3].string,
                                kr: $0.1["caption"][4].string
                            ),
                            title: .init(
                                jp: $0.1["title"][0].string,
                                en: $0.1["title"][1].string,
                                tw: $0.1["title"][2].string,
                                cn: $0.1["title"][3].string,
                                kr: $0.1["title"][4].string
                            ),
                            synopsis: .init(
                                jp: $0.1["synopsis"][0].string,
                                en: $0.1["synopsis"][1].string,
                                tw: $0.1["synopsis"][2].string,
                                cn: $0.1["synopsis"][3].string,
                                kr: $0.1["synopsis"][4].string
                            ),
                            releaseConditions: .init(
                                jp: $0.1["releaseConditions"][0].string,
                                en: $0.1["releaseConditions"][1].string,
                                tw: $0.1["releaseConditions"][2].string,
                                cn: $0.1["releaseConditions"][3].string,
                                kr: $0.1["releaseConditions"][4].string
                            )
                        )
                    },
                    rewardCards: respJSON["rewardCards"].map { $0.1.intValue }
                )
            }
            return nil
        }
    }
}

extension DoriAPI.Event {
    public struct PreviewEvent: Identifiable {
        public var id: Int
        public var eventType: EventType
        public var eventName: DoriAPI.LocalizedData<String>
        public var assetBundleName: String
        public var bannerAssetBundleName: String
        public var startAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
        public var endAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
        public var attributes: [EventAttribute]
        public var characters: [EventCharacter]
        public var eventAttributeAndCharacterBonus: EventAttributeAndCharacterBonus?
        public var members: [EventMember]
        public var limitBreaks: [EventLimitBreak]
        public var rewardCards: [Int]
    }
    
    public struct Event: Identifiable {
        public var id: Int
        public var eventType: EventType
        public var eventName: DoriAPI.LocalizedData<String>
        public var assetBundleName: String
        public var bannerAssetBundleName: String
        public var startAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
        public var endAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
        public var publicStartAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
        public var publicEndAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
        public var distributionStartAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
        public var distributionEndAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
        public var bgmAssetBundleName: String
        public var bgmFileName: String
        public var aggregateEndAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
        public var exchangeEndAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
        public var pointRewards: DoriAPI.LocalizedData<[PointReward]>
        public var rankingRewards: DoriAPI.LocalizedData<[RankingReward]>
        public var attributes: [EventAttribute]
        public var characters: [EventCharacter]
        public var eventAttributeAndCharacterBonus: EventAttributeAndCharacterBonus?
        public var members: [EventMember]
        public var limitBreaks: [EventLimitBreak]
        public var stories: [Story]
        public var rewardCards: [Int]
        
        internal init(
            id: Int,
            eventType: EventType,
            eventName: DoriAPI.LocalizedData<String>,
            assetBundleName: String,
            bannerAssetBundleName: String,
            startAt: DoriAPI.LocalizedData<Date>,
            endAt: DoriAPI.LocalizedData<Date>,
            publicStartAt: DoriAPI.LocalizedData<Date>,
            publicEndAt: DoriAPI.LocalizedData<Date>,
            distributionStartAt: DoriAPI.LocalizedData<Date>,
            distributionEndAt: DoriAPI.LocalizedData<Date>,
            bgmAssetBundleName: String,
            bgmFileName: String,
            aggregateEndAt: DoriAPI.LocalizedData<Date>,
            exchangeEndAt: DoriAPI.LocalizedData<Date>,
            pointRewards: DoriAPI.LocalizedData<[PointReward]>,
            rankingRewards: DoriAPI.LocalizedData<[RankingReward]>,
            attributes: [EventAttribute],
            characters: [EventCharacter],
            eventAttributeAndCharacterBonus: EventAttributeAndCharacterBonus?,
            members: [EventMember],
            limitBreaks: [EventLimitBreak],
            stories: [Story],
            rewardCards: [Int]
        ) {
            self.id = id
            self.eventType = eventType
            self.eventName = eventName
            self.assetBundleName = assetBundleName
            self.bannerAssetBundleName = bannerAssetBundleName
            self.startAt = startAt
            self.endAt = endAt
            self.publicStartAt = publicStartAt
            self.publicEndAt = publicEndAt
            self.distributionStartAt = distributionStartAt
            self.distributionEndAt = distributionEndAt
            self.bgmAssetBundleName = bgmAssetBundleName
            self.bgmFileName = bgmFileName
            self.aggregateEndAt = aggregateEndAt
            self.exchangeEndAt = exchangeEndAt
            self.pointRewards = pointRewards
            self.rankingRewards = rankingRewards
            self.attributes = attributes
            self.characters = characters
            self.eventAttributeAndCharacterBonus = eventAttributeAndCharacterBonus
            self.members = members
            self.limitBreaks = limitBreaks
            self.stories = stories
            self.rewardCards = rewardCards
        }
        
        public struct PointReward {
            public var point: Int
            public var rewardType: RewardType
            public var rewardID: Int?
            public var rewardQuantity: Int
            
            internal init(point: Int, rewardType: RewardType, rewardID: Int?, rewardQuantity: Int) {
                self.point = point
                self.rewardType = rewardType
                self.rewardID = rewardID
                self.rewardQuantity = rewardQuantity
            }
        }
        public struct RankingReward {
            public var rankRange: ClosedRange<Int> // keys{fromRank, toRank}(JSON) -> ClosedRange(Swift)
            public var rewardType: RewardType
            public var rewardID: Int?
            public var rewardQuantity: Int
            
            internal init(rankRange: ClosedRange<Int>, rewardType: RewardType, rewardID: Int?, rewardQuantity: Int) {
                self.rankRange = rankRange
                self.rewardType = rewardType
                self.rewardID = rewardID
                self.rewardQuantity = rewardQuantity
            }
        }
        public enum RewardType: String {
            case item
            case star
            case coin
            case practiceTicket = "practice_ticket"
            case stamp
            case voiceStamp = "voice_stamp"
            case situation
            case costume3DMakingItem = "costume_3d_making_item"
            case degree
        }
        
        public struct Story {
            public var scenarioID: String
            public var coverImage: String
            public var backgroundImage: String
            public var releasePt: Int
            public var rewards: [Reward]
            public var caption: DoriAPI.LocalizedData<String>
            public var title: DoriAPI.LocalizedData<String>
            public var synopsis: DoriAPI.LocalizedData<String>
            public var releaseConditions: DoriAPI.LocalizedData<String>
            
            public struct Reward {
                public var rewardType: RewardType
                public var rewardID: Int?
                public var rewardQuantity: Int
                
                internal init(rewardType: RewardType, rewardID: Int?, rewardQuantity: Int) {
                    self.rewardType = rewardType
                    self.rewardID = rewardID
                    self.rewardQuantity = rewardQuantity
                }
            }
        }
    }
    
    public enum EventType: String, CaseIterable {
        case story
        case challenge
        case versus
        case liveTry = "live_try"
        case missionLive = "mission_live"
        case festival
        case medley
    }
    
    public struct EventAttribute {
        public var eventID: Int?
        public var attribute: DoriAPI.Attribute
        public var percent: Int
        
        internal init(eventID: Int?, attribute: DoriAPI.Attribute, percent: Int) {
            self.eventID = eventID
            self.attribute = attribute
            self.percent = percent
        }
    }
    public struct EventCharacter {
        public var eventID: Int?
        public var characterID: Int
        public var percent: Int
        public var seq: Int?
        
        internal init(eventID: Int?, characterID: Int, percent: Int, seq: Int?) {
            self.eventID = eventID
            self.characterID = characterID
            self.percent = percent
            self.seq = seq
        }
    }
    public struct EventMember {
        public var eventID: Int?
        public var situationID: Int
        public var percent: Int
        public var seq: Int?
        
        internal init(eventID: Int?, situationID: Int, percent: Int, seq: Int?) {
            self.eventID = eventID
            self.situationID = situationID
            self.percent = percent
            self.seq = seq
        }
    }
    public struct EventLimitBreak {
        public var rarity: Int
        public var rank: Int
        public var percent: Double
    }
    public struct EventAttributeAndCharacterBonus {
        public var eventID: Int
        public var pointPercent: Int
        public var parameterPercent: Int
    }
}

extension DoriAPI.Event.Event {
    @inlinable
    public init?(id: Int) async {
        if let event = await DoriAPI.Event.detail(of: id) {
            self = event
        }
        return nil
    }
    
    @inlinable
    public init?(preview: DoriAPI.Event.PreviewEvent) async {
        await self.init(id: preview.id)
    }
}
