//
//  Character.swift
//  Greatdori
//
//  Created by Mark Chan on 7/18/25.
//

import SwiftUI
import Foundation
internal import SwiftyJSON

extension DoriAPI {
    public class Character {
        private init() {}
        
        public static func all() async -> [PreviewCharacter]? {
            // Response example:
            // {
            //     "1": {
            //         "characterType": "unique",
            //         "characterName": [
            //             "戸山 香澄",
            //             "Kasumi Toyama",
            //             "戶山 香澄",
            //             "户山 香澄",
            //             "토야마 카스미"
            //         ],
            //         "nickname": [
            //             null,
            //             ...
            //         ],
            //         "bandId": 1,
            //         "colorCode": "#FF5522"
            //     },
            //     ...
            // }
            let request = await requestJSON("https://bestdori.com/api/characters/all.2.json")
            if case let .success(respJSON) = request {
                var characters = [PreviewCharacter]()
                for (key, value) in respJSON {
                    characters.append(
                        .init(
                            id: Int(key) ?? 0,
                            characterType: .init(rawValue: value["characterType"].stringValue) ?? .common,
                            characterName: .init(
                                jp: value["characterName"][0].string,
                                en: value["characterName"][1].string,
                                tw: value["characterName"][2].string,
                                cn: value["characterName"][3].string,
                                kr: value["characterName"][4].string
                            ),
                            nickname: .init(
                                jp: value["nickname"][0].string,
                                en: value["nickname"][1].string,
                                tw: value["nickname"][2].string,
                                cn: value["nickname"][3].string,
                                kr: value["nickname"][4].string
                            ),
                            bandID: value["bandId"].int,
                            color: .init(hex: value["colorCode"].stringValue)
                        )
                    )
                }
                return characters.sorted { $0.id < $1.id }
            }
            return nil
        }
        
        public static func allBirthday() async -> [BirthdayCharacter]? {
            // Response example:
            // {
            //     "1": {
            //         "characterName": [
            //             "戸山 香澄",
            //             "Kasumi Toyama",
            //             "戶山 香澄",
            //             "户山 香澄",
            //             "토야마 카스미"
            //         ],
            //         "nickname": [
            //             null,
            //             ...
            //         ],
            //         "profile": {
            //             "birthday": "963500400000"
            //         }
            //     },
            //     ...
            // }
            let request = await requestJSON("https://bestdori.com/api/characters/main.birthday.json")
            if case let .success(respJSON) = request {
                var result = [BirthdayCharacter]()
                for (key, value) in respJSON {
                    result.append(.init(
                        id: Int(key) ?? 0,
                        characterName: .init(
                            jp: value["characterName"][0].string,
                            en: value["characterName"][1].string,
                            tw: value["characterName"][2].string,
                            cn: value["characterName"][3].string,
                            kr: value["characterName"][4].string
                        ),
                        nickname: .init(
                            jp: value["nickname"][0].string,
                            en: value["nickname"][1].string,
                            tw: value["nickname"][2].string,
                            cn: value["nickname"][3].string,
                            kr: value["nickname"][4].string
                        ),
                        birthday: .init(timeIntervalSince1970: Double(Int64(value["profile"]["birthday"].stringValue.dropLast(3)) ?? 0))
                    ))
                }
                return result.sorted { $0.id < $1.id }
            }
            return nil
        }
        
        public static func detail(of id: Int) async -> Character? {
            // Response example:
            // {
            //     "characterType": "unique",
            //     "characterName": [
            //         "長崎 そよ",
            //         "Soyo Nagasaki",
            //         "長崎 爽世",
            //         "长崎 爽世",
            //         null
            //     ],
            //     "firstName": [
            //         "そよ",
            //         ...
            //     ],
            //     "lastName": [
            //         "長崎",
            //         ...
            //     ],
            //     "nickname": [
            //         null,
            //         ...
            //     ],
            //     "bandId": 45,
            //     "colorCode": "#FFDD88",
            //     "sdAssetBundleName": "00039",
            //     "defaultCostumeId": 1789,
            //     "seasonCostumeListMap": ..., // This attribute is not provided in Swift API
            //     "ruby": [
            //         "ながさき そよ",
            //         ...
            //     ],
            //     "profile": {
            //         "characterVoice": [
            //             "小日向美香",
            //             ...
            //         ],
            //         "favoriteFood": [
            //             "紅茶、ミネストローネ",
            //             ...
            //         ],
            //         "hatedFood": [
            //             "ホルモン",
            //             ...
            //         ],
            //         "hobby": [
            //             "アロマ",
            //             ...
            //         ],
            //         "selfIntroduction": [
            //             "おっとりした雰囲気のMyGO!!!!!のベーシスト。...",
            //             ...
            //         ],
            //         "school": [
            //             "月ノ森女子学園",
            //             ...
            //         ],
            //         "schoolCls": [
            //             "A組",
            //             ...
            //         ],
            //         "schoolYear": [
            //             "高校1年生",
            //             ...
            //         ],
            //         "part": "base",
            //         "birthday": "959356800000",
            //         "constellation": "gemini",
            //         "height": 162
            //     }
            // }
            let request = await requestJSON("https://bestdori.com/api/characters/\(id).json")
            if case let .success(respJSON) = request {
                if let characterType = CharacterType(rawValue: respJSON["characterType"].stringValue) {
                    switch characterType {
                    case .unique:
                        return .init(
                            id: id,
                            characterType: characterType,
                            characterName: .init(
                                jp: respJSON["characterName"][0].string,
                                en: respJSON["characterName"][1].string,
                                tw: respJSON["characterName"][2].string,
                                cn: respJSON["characterName"][3].string,
                                kr: respJSON["characterName"][4].string
                            ),
                            firstName: .init(
                                jp: respJSON["firstName"][0].string,
                                en: respJSON["firstName"][1].string,
                                tw: respJSON["firstName"][2].string,
                                cn: respJSON["firstName"][3].string,
                                kr: respJSON["firstName"][4].string
                            ),
                            lastName: .init(
                                jp: respJSON["lastName"][0].string,
                                en: respJSON["lastName"][1].string,
                                tw: respJSON["lastName"][2].string,
                                cn: respJSON["lastName"][3].string,
                                kr: respJSON["lastName"][4].string
                            ),
                            nickname: .init(
                                jp: respJSON["nickname"][0].string,
                                en: respJSON["nickname"][1].string,
                                tw: respJSON["nickname"][2].string,
                                cn: respJSON["nickname"][3].string,
                                kr: respJSON["nickname"][4].string
                            ),
                            bandID: respJSON["bandId"].intValue,
                            color: .init(hex: respJSON["colorCode"].stringValue),
                            sdAssetBundleName: respJSON["sdAssetBundleName"].stringValue,
                            defaultCostumeID: respJSON["defaultCostumeId"].intValue,
                            ruby: .init(
                                jp: respJSON["ruby"][0].string,
                                en: respJSON["ruby"][1].string,
                                tw: respJSON["ruby"][2].string,
                                cn: respJSON["ruby"][3].string,
                                kr: respJSON["ruby"][4].string
                            ),
                            profile: .init(
                                characterVoice: .init(
                                    jp: respJSON["profile"]["characterVoice"][0].string,
                                    en: respJSON["profile"]["characterVoice"][1].string,
                                    tw: respJSON["profile"]["characterVoice"][2].string,
                                    cn: respJSON["profile"]["characterVoice"][3].string,
                                    kr: respJSON["profile"]["characterVoice"][4].string
                                ),
                                favoriteFood: .init(
                                    jp: respJSON["profile"]["favoriteFood"][0].string,
                                    en: respJSON["profile"]["favoriteFood"][1].string,
                                    tw: respJSON["profile"]["favoriteFood"][2].string,
                                    cn: respJSON["profile"]["favoriteFood"][3].string,
                                    kr: respJSON["profile"]["favoriteFood"][4].string
                                ),
                                hatedFood: .init(
                                    jp: respJSON["profile"]["hatedFood"][0].string,
                                    en: respJSON["profile"]["hatedFood"][1].string,
                                    tw: respJSON["profile"]["hatedFood"][2].string,
                                    cn: respJSON["profile"]["hatedFood"][3].string,
                                    kr: respJSON["profile"]["hatedFood"][4].string
                                ),
                                hobby: .init(
                                    jp: respJSON["profile"]["hobby"][0].string,
                                    en: respJSON["profile"]["hobby"][1].string,
                                    tw: respJSON["profile"]["hobby"][2].string,
                                    cn: respJSON["profile"]["hobby"][3].string,
                                    kr: respJSON["profile"]["hobby"][4].string
                                ),
                                selfIntroduction: .init(
                                    jp: respJSON["profile"]["selfIntroduction"][0].string,
                                    en: respJSON["profile"]["selfIntroduction"][1].string,
                                    tw: respJSON["profile"]["selfIntroduction"][2].string,
                                    cn: respJSON["profile"]["selfIntroduction"][3].string,
                                    kr: respJSON["profile"]["selfIntroduction"][4].string
                                ),
                                school: .init(
                                    jp: respJSON["profile"]["school"][0].string,
                                    en: respJSON["profile"]["school"][1].string,
                                    tw: respJSON["profile"]["school"][2].string,
                                    cn: respJSON["profile"]["school"][3].string,
                                    kr: respJSON["profile"]["school"][4].string
                                ),
                                schoolClass: .init(
                                    jp: respJSON["profile"]["schoolCls"][0].string,
                                    en: respJSON["profile"]["schoolCls"][1].string,
                                    tw: respJSON["profile"]["schoolCls"][2].string,
                                    cn: respJSON["profile"]["schoolCls"][3].string,
                                    kr: respJSON["profile"]["schoolCls"][4].string
                                ),
                                schoolYear: .init(
                                    jp: respJSON["profile"]["schoolYear"][0].string,
                                    en: respJSON["profile"]["schoolYear"][1].string,
                                    tw: respJSON["profile"]["schoolYear"][2].string,
                                    cn: respJSON["profile"]["schoolYear"][3].string,
                                    kr: respJSON["profile"]["schoolYear"][4].string
                                ),
                                part: .init(rawValue: respJSON["profile"]["part"].stringValue) ?? .keyboard,
                                birthday: .init(timeIntervalSince1970: Double(Int64(respJSON["profile"]["birthday"].stringValue.dropLast(3)) ?? 0)),
                                constellation: .init(rawValue: respJSON["profile"]["constellation"].stringValue) ?? .aries,
                                height: respJSON["profile"]["height"].intValue
                            )
                        )
                    case .common, .another:
                        return .init(
                            id: id,
                            characterType: characterType,
                            characterName: .init(
                                jp: respJSON["characterName"][0].string,
                                en: respJSON["characterName"][1].string,
                                tw: respJSON["characterName"][2].string,
                                cn: respJSON["characterName"][3].string,
                                kr: respJSON["characterName"][4].string
                            ),
                            firstName: .init(
                                jp: respJSON["firstName"][0].string,
                                en: respJSON["firstName"][1].string,
                                tw: respJSON["firstName"][2].string,
                                cn: respJSON["firstName"][3].string,
                                kr: respJSON["firstName"][4].string
                            ),
                            lastName: .init(
                                jp: respJSON["lastName"][0].string,
                                en: respJSON["lastName"][1].string,
                                tw: respJSON["lastName"][2].string,
                                cn: respJSON["lastName"][3].string,
                                kr: respJSON["lastName"][4].string
                            ),
                            nickname: .init(
                                jp: respJSON["nickname"][0].string,
                                en: respJSON["nickname"][1].string,
                                tw: respJSON["nickname"][2].string,
                                cn: respJSON["nickname"][3].string,
                                kr: respJSON["nickname"][4].string
                            ),
                            sdAssetBundleName: respJSON["sdAssetBundleName"].stringValue,
                            ruby: .init(
                                jp: respJSON["ruby"][0].string,
                                en: respJSON["ruby"][1].string,
                                tw: respJSON["ruby"][2].string,
                                cn: respJSON["ruby"][3].string,
                                kr: respJSON["ruby"][4].string
                            )
                        )
                    }
                }
            }
            return nil
        }
    }
}

extension DoriAPI.Character {
    public struct PreviewCharacter: Identifiable {
        public var id: Int
        public var characterType: CharacterType
        public var characterName: DoriAPI.LocalizedData<String>
        public var nickname: DoriAPI.LocalizedData<String>
        public var bandID: Int?
        public var color: Color? // String(JSON) -> Color(Swift)
        
        internal init(
            id: Int,
            characterType: CharacterType,
            characterName: DoriAPI.LocalizedData<String>,
            nickname: DoriAPI.LocalizedData<String>,
            bandID: Int?,
            color: Color?
        ) {
            self.id = id
            self.characterType = characterType
            self.characterName = characterName
            self.nickname = nickname
            self.bandID = bandID
            self.color = color
        }
    }
    
    public struct BirthdayCharacter: Identifiable {
        public var id: Int
        public var characterName: DoriAPI.LocalizedData<String>
        public var nickname: DoriAPI.LocalizedData<String>
        public var birthday: Date // String(JSON) -> Date(Swift)
    }
    
    public struct Character: Identifiable {
        public var id: Int
        public var characterType: CharacterType
        public var characterName: DoriAPI.LocalizedData<String>
        public var firstName: DoriAPI.LocalizedData<String>
        public var lastName: DoriAPI.LocalizedData<String>
        public var nickname: DoriAPI.LocalizedData<String>
        public var bandID: Int?
        public var color: Color? // String(JSON) -> Color(Swift)
        public var sdAssetBundleName: String
        public var defaultCostumeID: Int?
        public var ruby: DoriAPI.LocalizedData<String>
        public var profile: Profile?
        
        internal init(
            id: Int,
            characterType: CharacterType,
            characterName: DoriAPI.LocalizedData<String>,
            firstName: DoriAPI.LocalizedData<String>,
            lastName: DoriAPI.LocalizedData<String>,
            nickname: DoriAPI.LocalizedData<String>,
            bandID: Int?,
            color: Color?,
            sdAssetBundleName: String,
            defaultCostumeID: Int?,
            ruby: DoriAPI.LocalizedData<String>,
            profile: Profile?
        ) {
            self.id = id
            self.characterType = characterType
            self.characterName = characterName
            self.firstName = firstName
            self.lastName = lastName
            self.nickname = nickname
            self.bandID = bandID
            self.color = color
            self.sdAssetBundleName = sdAssetBundleName
            self.defaultCostumeID = defaultCostumeID
            self.ruby = ruby
            self.profile = profile
        }
        internal init(
            id: Int,
            characterType: CharacterType,
            characterName: DoriAPI.LocalizedData<String>,
            firstName: DoriAPI.LocalizedData<String>,
            lastName: DoriAPI.LocalizedData<String>,
            nickname: DoriAPI.LocalizedData<String>,
            sdAssetBundleName: String,
            ruby: DoriAPI.LocalizedData<String>
        ) {
            self.id = id
            self.characterType = characterType
            self.characterName = characterName
            self.firstName = firstName
            self.lastName = lastName
            self.nickname = nickname
            self.sdAssetBundleName = sdAssetBundleName
            self.ruby = ruby
        }
        
        public struct Profile {
            public var characterVoice: DoriAPI.LocalizedData<String>
            public var favoriteFood: DoriAPI.LocalizedData<String>
            public var hatedFood: DoriAPI.LocalizedData<String>
            public var hobby: DoriAPI.LocalizedData<String>
            public var selfIntroduction: DoriAPI.LocalizedData<String>
            public var school: DoriAPI.LocalizedData<String>
            public var schoolClass: DoriAPI.LocalizedData<String> // named "schoolCls" in JSON, we use "schoolClass" to make it clear
            public var schoolYear: DoriAPI.LocalizedData<String>
            public var part: Part
            public var birthday: Date // String(JSON) -> Date(Swift)
            public var constellation: DoriAPI.Constellation
            public var height: Int
            
            public enum Part: String {
                case vocal
                case keyboard
                case guitar
                case guitarVocal = "guitar_vocal"
                case bass = "base" // There's a typo in Bestdori's API response, we correct it in Swift API.
                case bassVocal = "base_vocal" // Also typo
                case drum
                case violin
                case dj
            }
        }
    }
    
    public enum CharacterType: String {
        case unique
        case common
        case another
    }
}

extension DoriAPI.Character.Character {
    @inlinable
    public init?(id: Int) async {
        if let character = await DoriAPI.Character.detail(of: id) {
            self = character
        }
        return nil
    }
    
    @inlinable
    public init?(preview: DoriAPI.Character.PreviewCharacter) async {
        await self.init(id: preview.id)
    }
    @inlinable
    public init?(preview: DoriAPI.Character.BirthdayCharacter) async {
        await self.init(id: preview.id)
    }
}
