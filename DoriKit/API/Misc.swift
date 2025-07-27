//
//  Misc.swift
//  Greatdori
//
//  Created by Mark Chan on 7/26/25.
//

import Foundation
internal import SwiftyJSON

extension DoriAPI {
    public class Misc {
        private init() {}
        
        public static func itemTexts() async -> [String: ItemText]? {
            // Response example:
            // {
            //     "item_1": {
            //         "name": [
            //             "ハッピーのかけら(小)",
            //             "Happy Shard (S)",
            //             "ＨＡＰＰＹ的碎片(小)",
            //             "Happy属性碎片(小)",
            //             "해피 조각 (소)"
            //         ],
            //         "resourceId": 1
            //     },
            //     ...
            // }
            let request = await requestJSON("https://bestdori.com/api/misc/itemtexts.2.json")
            if case let .success(respJSON) = request {
                var result = [String: ItemText]()
                for (key, value) in respJSON {
                    result.updateValue(
                        .init(
                            name: .init(
                                jp: value["name"][0].string,
                                en: value["name"][1].string,
                                tw: value["name"][2].string,
                                cn: value["name"][3].string,
                                kr: value["name"][4].string
                            ),
                            type: .init(rawValue: value["type"].stringValue) ?? .normal,
                            resourceID: value["resourceId"].intValue
                        ),
                        forKey: key
                    )
                }
                return result
            }
            return nil
        }
    }
}

// We declare extension of `DoriAPI` instead of `DoriAPI.Misc`
// to make them can be found easier.
extension DoriAPI {
    public struct Item: Identifiable, DoriCache.Cacheable {
        public var itemID: Int?
        public var type: ItemType
        public var quantity: Int
        
        internal init(itemID: Int?, type: ItemType, quantity: Int) {
            self.itemID = itemID
            self.type = type
            self.quantity = quantity
        }
        
        @inlinable
        public var id: String {
            if let itemID {
                type.rawValue + String(itemID)
            } else {
                type.rawValue
            }
        }
        
        public enum ItemType: String, DoriCache.Cacheable {
            case item
            case star
            case coin
            case gachaTicket = "gacha_ticket"
            case practiceTicket = "practice_ticket"
            case miracleTicket = "miracle_ticket"
            case liveBoostRecoveryItem = "live_boost_recovery_item"
            case stamp
            case voiceStamp = "voice_stamp"
            case situation
            case costume3DMakingItem = "costume_3d_making_item"
            case degree
        }
    }
}

// These declerations are less used so we define it in
// extension of `DoriAPI.Misc`
extension DoriAPI.Misc {
    public struct ItemText: DoriCache.Cacheable {
        public var name: DoriAPI.LocalizedData<String>
        public var type: ItemType?
        public var resourceID: Int
        
        internal init(name: DoriAPI.LocalizedData<String>, type: ItemType?, resourceID: Int) {
            self.name = name
            self.type = type
            self.resourceID = resourceID
        }
        
        public enum ItemType: String, DoriCache.Cacheable {
            case normal
            case practice
            case special
            case skillPractice = "skill_practice"
            case normalTicket = "normal_ticket"
            case gamonTicket1 = "gamon_ticket_1"
            case gamonTicket2 = "gamon_ticket_2"
            case gamonTicket3 = "gamon_ticket_3"
            case overThe3StarTicket = "over_the_3_star_ticket"
            case spend1Fixed4StarTicket = "spend_1_fixed_4_star_ticket"
            case spend2Fixed4StarTicket = "spend_2_fixed_4_star_ticket"
            case spend3Fixed4StarTicket = "spend_3_fixed_4_star_ticket"
            case fixed4StarTicket = "fixed_4_star_ticket"
            case fesFixed4StarTicket = "fes_fixed_4_star_ticket"
            case overThe4StarTicket = "over_the_4_star_ticket"
            case fixed5StarTicket = "fixed_5_star_ticket"
        }
    }
}
