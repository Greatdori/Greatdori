//
//  Degree.swift
//  Greatdori
//
//  Created by Mark Chan on 7/22/25.
//

import SwiftUI
import Foundation
internal import SwiftyJSON

extension DoriAPI {
    public class Degree {
        private init() {}
        
        public static func all() async -> [Degree]? {
            // Response example:
            // {
            //     "1": {
            //         "degreeType": [
            //             "event_point",
            //             "event_point",
            //             "event_point",
            //             "event_point",
            //             "event_point"
            //         ],
            //         "iconImageName": [
            //             "none",
            //             ...
            //         ],
            //         "baseImageName": [
            //             "degree001",
            //             ...
            //         ],
            //         "rank": [
            //             "none",
            //             ...
            //         ],
            //         "degreeName": [
            //             "SAKURA＊BLOOMING PARTY! TOP100",
            //             ...
            //         ]
            //     },
            //     ...
            // }
            let request = await requestJSON("https://bestdori.com/api/degrees/all.3.json")
            if case let .success(respJSON) = request {
                var result = [Degree]()
                for (key, value) in respJSON {
                    result.append(.init(
                        id: Int(key) ?? 0,
                        degreeType: .init(
                            jp: .init(rawValue: value["degreeType"][0].stringValue),
                            en: .init(rawValue: value["degreeType"][1].stringValue),
                            tw: .init(rawValue: value["degreeType"][2].stringValue),
                            cn: .init(rawValue: value["degreeType"][3].stringValue),
                            kr: .init(rawValue: value["degreeType"][4].stringValue)
                        ),
                        iconImageName: .init(
                            jp: value["iconImageName"][0].string,
                            en: value["iconImageName"][1].string,
                            tw: value["iconImageName"][2].string,
                            cn: value["iconImageName"][3].string,
                            kr: value["iconImageName"][4].string
                        ),
                        baseImageName: .init(
                            jp: value["baseImageName"][0].string,
                            en: value["baseImageName"][1].string,
                            tw: value["baseImageName"][2].string,
                            cn: value["baseImageName"][3].string,
                            kr: value["baseImageName"][4].string
                        ),
                        rank: .init(
                            jp: value["rank"][0].string,
                            en: value["rank"][1].string,
                            tw: value["rank"][2].string,
                            cn: value["rank"][3].string,
                            kr: value["rank"][4].string
                        ),
                        degreeName: .init(
                            jp: value["degreeName"][0].string,
                            en: value["degreeName"][1].string,
                            tw: value["degreeName"][2].string,
                            cn: value["degreeName"][3].string,
                            kr: value["degreeName"][4].string
                        )
                    ))
                }
                return result.sorted { $0.id < $1.id }
            }
            return nil
        }
    }
}

extension DoriAPI.Degree {
    public struct Degree: Identifiable {
        public var id: Int
        public var degreeType: DoriAPI.LocalizedData<DegreeType>
        public var iconImageName: DoriAPI.LocalizedData<String>
        public var baseImageName: DoriAPI.LocalizedData<String>
        public var rank: DoriAPI.LocalizedData<String>
        public var degreeName: DoriAPI.LocalizedData<String>
        
        public enum DegreeType: String {
            case normal
            case scoreRanking = "score_ranking"
            case eventPoint = "event_point"
            case tryClear = "try_clear"
        }
    }
}
