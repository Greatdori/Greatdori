//
//  Skill.swift
//  Greatdori
//
//  Created by Mark Chan on 7/21/25.
//

import SwiftUI
import Foundation
internal import SwiftyJSON

extension DoriAPI {
    public class Skill {
        private init() {}
        
        public static func all() async -> [Skill]? {
            // Response example:
            // {
            //     "1": {
            //         "simpleDescription": [
            //             "スコア10%ＵＰ",
            //             "Score Boost 10%",
            //             "ＳＣＯＲＥ１０%ＵＰ",
            //             "得分提升10%",
            //             "스코어 10% UP"
            //         ],
            //         "description": [
            //             "{0}秒間  スコアが10%UPする",
            //             ...
            //         ],
            //         "duration": [
            //             5,
            //             5.5,
            //             6,
            //             6.5,
            //             7
            //         ],
            //         "activationEffect": {
            //             "activateEffectTypes": {
            //                 "score": {
            //                     "activateEffectValue": [
            //                         10,
            //                         10,
            //                         10,
            //                         10,
            //                         10
            //                     ],
            //                     "activateEffectValueType": "rate",
            //                     "activateCondition": "good"
            //                 }
            //             }
            //         }
            //     },
            //     ...
            // }
            let request = await requestJSON("https://bestdori.com/api/skills/all.10.json")
            if case let .success(respJSON) = request {
                var result = [Skill]()
                for (key, value) in respJSON {
                    var effects = Skill.ActivationEffect.Effects()
                    for (k, v) in value["activationEffect"]["activateEffectTypes"] {
                        if let type = Skill.ActivationEffect.ActivateEffectType(rawValue: k) {
                            effects.updateValue(
                                .init(
                                    activateEffectValue: .init(
                                        jp: v["activateEffectValue"][0].int,
                                        en: v["activateEffectValue"][1].int,
                                        tw: v["activateEffectValue"][2].int,
                                        cn: v["activateEffectValue"][3].int,
                                        kr: v["activateEffectValue"][4].int
                                    ),
                                    activateEffectValueType: .init(rawValue: v["activateEffectValueType"].stringValue) ?? .rate,
                                    activateCondition: .init(rawValue: v["activateCondition"].stringValue) ?? .good,
                                    activateConditionLife: v["activateConditionLife"].int
                                ),
                                forKey: type
                            )
                        }
                    }
                    result.append(.init(
                        id: Int(key) ?? 0,
                        simpleDescription: .init(
                            jp: value["simpleDescription"][0].string,
                            en: value["simpleDescription"][1].string,
                            tw: value["simpleDescription"][2].string,
                            cn: value["simpleDescription"][3].string,
                            kr: value["simpleDescription"][4].string
                        ),
                        description: .init(
                            jp: value["description"][0].string,
                            en: value["description"][1].string,
                            tw: value["description"][2].string,
                            cn: value["description"][3].string,
                            kr: value["description"][4].string
                        ),
                        duration: value["duration"].map { $0.1.doubleValue },
                        activationEffect: .init(
                            unificationActivateEffectValue: value["activationEffect"]["unificationActivateEffectValue"].int,
                            unificationActivateConditionType: .init(rawValue: value["activationEffect"]["unificationActivateConditionType"].stringValue),
                            unificationActivateConditionBandID: value["activationEffect"]["unificationActivateConditionBandId"].int,
                            activateEffectTypes: effects
                        )
                    ))
                }
                return result.sorted { $0.id < $1.id }
            }
            return nil
        }
    }
}

extension DoriAPI.Skill {
    public struct Skill: Identifiable {
        public var id: Int
        public var simpleDescription: DoriAPI.LocalizedData<String>
        public var description: DoriAPI.LocalizedData<String> // Uses `{Int}` for string interpolation
        public var duration: [Double]
        public var activationEffect: ActivationEffect
        
        public struct ActivationEffect {
            public var unificationActivateEffectValue: Int?
            public var unificationActivateConditionType: ActivateConditionType?
            public var unificationActivateConditionBandID: Int?
            public var activateEffectTypes: Effects
            
            internal init(
                unificationActivateEffectValue: Int?,
                unificationActivateConditionType: ActivateConditionType?,
                unificationActivateConditionBandID: Int?,
                activateEffectTypes: Effects
            ) {
                self.unificationActivateEffectValue = unificationActivateEffectValue
                self.unificationActivateConditionType = unificationActivateConditionType
                self.unificationActivateConditionBandID = unificationActivateConditionBandID
                self.activateEffectTypes = activateEffectTypes
            }
            
            public enum ActivateConditionType: String {
                case pure = "PURE"
                case cool = "COOL"
                case happy = "HAPPY"
                case powerful = "POWERFUL"
            }
            
            public typealias Effects = [ActivateEffectType: ActivateEffect]
            public enum ActivateEffectType: String {
                case score
                case judge
                case scoreOverLife = "score_over_life"
                case scoreUnderLife = "score_under_life"
                case scoreContinuedNoteJudge = "score_continued_note_judge"
                case scoreOnlyPerfect = "score_only_perfect"
                case scoreRateUpWithPerfect = "score_rate_up_with_perfect"
                case scoreUnderGreatHalf = "score_under_great_half"
                case damage
                case neverDie = "never_die"
            }
            public struct ActivateEffect {
                public var activateEffectValue: DoriAPI.LocalizedData<Int>
                public var activateEffectValueType: ValueType
                public var activateCondition: ActivateCondition
                public var activateConditionLife: Int?
                
                internal init(
                    activateEffectValue: DoriAPI.LocalizedData<Int>,
                    activateEffectValueType: ValueType,
                    activateCondition: ActivateCondition,
                    activateConditionLife: Int?
                ) {
                    self.activateEffectValue = activateEffectValue
                    self.activateEffectValueType = activateEffectValueType
                    self.activateCondition = activateCondition
                    self.activateConditionLife = activateConditionLife
                }
                
                public enum ValueType: String {
                    case rate
                    case realValue = "real_value"
                }
                public enum ActivateCondition: String {
                    case none
                    case good
                    case perfect
                }
            }
        }
    }
}
