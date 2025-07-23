//
//  Band.swift
//  Greatdori
//
//  Created by Mark Chan on 7/21/25.
//

import SwiftUI
import Foundation
internal import SwiftyJSON

extension DoriAPI {
    public class Band {
        private init() {}
        
        public static func main() async -> [Band]? {
            // Response example:
            // {
            //     "1": {
            //         "bandName": [
            //             "Poppin'Party",
            //             "Poppin'Party",
            //             "Poppin'Party",
            //             "Poppin'Party",
            //             "Poppin'Party"
            //         ]
            //     },
            //     ...
            // }
            let request = await requestJSON("https://bestdori.com/api/bands/main.1.json")
            if case let .success(respJSON) = request {
                var result = [Band]()
                for (key, value) in respJSON {
                    result.append(.init(
                        id: Int(key) ?? 0,
                        bandName: .init(
                            jp: value["bandName"][0].string,
                            en: value["bandName"][1].string,
                            tw: value["bandName"][2].string,
                            cn: value["bandName"][3].string,
                            kr: value["bandName"][4].string
                        )
                    ))
                }
                return result.sorted { $0.id < $1.id }
            }
            return nil
        }
        
        public static func all() async -> [Band]? {
            // Response example:
            // {
            //     "1": {
            //         "bandName": [
            //             "Poppin'Party",
            //             "Poppin'Party",
            //             "Poppin'Party",
            //             "Poppin'Party",
            //             "Poppin'Party"
            //         ]
            //     },
            //     ...
            // }
            let request = await requestJSON("https://bestdori.com/api/bands/all.1.json")
            if case let .success(respJSON) = request {
                var result = [Band]()
                for (key, value) in respJSON {
                    result.append(.init(
                        id: Int(key) ?? 0,
                        bandName: .init(
                            jp: value["bandName"][0].string,
                            en: value["bandName"][1].string,
                            tw: value["bandName"][2].string,
                            cn: value["bandName"][3].string,
                            kr: value["bandName"][4].string
                        )
                    ))
                }
                return result.sorted { $0.id < $1.id }
            }
            return nil
        }
    }
}

extension DoriAPI.Band {
    public struct Band: Identifiable, Hashable {
        public var id: Int
        public var bandName: DoriAPI.LocalizedData<String>
    }
}
