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
    /// Request and fetch data about band in Bandori.
    public class Band {
        private init() {}
        
        /// Get all main bands in Bandori.
        ///
        /// *Main bands* means bands that have their own chapters in the game,
        /// such as *Poppin'Party*, *Roselia*, *MyGO!!!!!*, etc.
        ///
        /// The results have guaranteed sorting by ID.
        ///
        /// - Returns: Requested bands, nil if failed to fetch data.
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
                let task = Task.detached(priority: .userInitiated) {
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
                return await task.value
            }
            return nil
        }
        
        /// Get all bands in Bandori.
        ///
        /// *All bands* contains much more bands in addition to *main bands*,
        /// all temporary bands with different names are assigned a unique ID
        /// and become single items in the list.
        ///
        /// Generally, each songs in the *Other* category is associated with a band which is not *main*.
        ///
        /// The results have guaranteed sorting by ID.
        ///
        /// - Returns: Requested bands, nil if failed to fetch data.
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
                let task = Task.detached(priority: .userInitiated) {
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
                return await task.value
            }
            return nil
        }
    }
}

extension DoriAPI.Band {
    /// Represent a band.
    public struct Band: Identifiable, Hashable, DoriCache.Cacheable {
        /// A unique ID of band.
        public var id: Int
        /// Localized name of band.
        public var bandName: DoriAPI.LocalizedData<String>
    }
}
