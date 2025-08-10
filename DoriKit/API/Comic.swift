//===---*- Greatdori! -*---------------------------------------------------===//
//
// Comic.swift
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
internal import SwiftyJSON

extension DoriAPI {
    public class Comic {
        private init() {}
        
        public static func all() async -> [Comic]? {
            // Response example:
            // {
            //     "2": {
            //         "assetBundleName": "comic_001",
            //         "title": [
            //             "香澄＆有咲①「香澄語３級」",
            //             ...
            //         ],
            //         "subTitle": [
            //             "香澄＆有咲①",
            //             ...
            //         ],
            //         "publicStartAt": [
            //             1,
            //             ...
            //         ],
            //         "characterId": [
            //             1,
            //             5
            //         ]
            //     },
            //     ...
            // }
            let request = await requestJSON("https://bestdori.com/api/comics/all.5.json")
            if case let .success(respJSON) = request {
                let task = Task.detached(priority: .userInitiated) {
                    var result = [Comic]()
                    for (key, value) in respJSON {
                        result.append(.init(
                            id: Int(key) ?? 0,
                            assetBundleName: value["assetBundleName"].stringValue,
                            title: .init(
                                jp: value["title"][0].string,
                                en: value["title"][1].string,
                                tw: value["title"][2].string,
                                cn: value["title"][3].string,
                                kr: value["title"][4].string
                            ),
                            subTitle: .init(
                                jp: value["subTitle"][0].string,
                                en: value["subTitle"][1].string,
                                tw: value["subTitle"][2].string,
                                cn: value["subTitle"][3].string,
                                kr: value["subTitle"][4].string
                            ),
                            publicStartAt: .init(
                                jp: value["publicStartAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(value["publicStartAt"][0].stringValue.dropLast(3))!)) : nil,
                                en: value["publicStartAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(value["publicStartAt"][1].stringValue.dropLast(3))!)) : nil,
                                tw: value["publicStartAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(value["publicStartAt"][2].stringValue.dropLast(3))!)) : nil,
                                cn: value["publicStartAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(value["publicStartAt"][3].stringValue.dropLast(3))!)) : nil,
                                kr: value["publicStartAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(value["publicStartAt"][4].stringValue.dropLast(3))!)) : nil
                            ),
                            characterIDs: value["characterId"].map { $0.1.intValue }
                        ))
                    }
                    return result
                }
                return await task.value
            }
            return nil
        }
    }
}

extension DoriAPI.Comic {
    public struct Comic: Sendable, Identifiable, DoriCache.Cacheable {
        public var id: Int
        public var assetBundleName: String
        public var title: DoriAPI.LocalizedData<String>
        public var subTitle: DoriAPI.LocalizedData<String>
        public var publicStartAt: DoriAPI.LocalizedData<Date>
        public var characterIDs: [Int]
    }
}
