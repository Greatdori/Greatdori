//
//  Song.swift
//  Greatdori
//
//  Created by Mark Chan on 7/22/25.
//

import SwiftUI
import Foundation
internal import SwiftyJSON

extension DoriAPI {
    public class Song {
        private init() {}
        
        public static func all() async -> [PreviewSong]? {
            // Response example:
            // {
            //     "1": {
            //         "tag": "normal",
            //         "bandId": 1,
            //         "jacketImage": [
            //             "yes_bang_dream"
            //         ],
            //         "musicTitle": [
            //             "Yes! BanG_Dream!",
            //             "Yes! BanG_Dream!",
            //             "Yes! BanG_Dream!",
            //             "Yes! BanG_Dream!",
            //             "Yes! BanG_Dream!"
            //         ],
            //         "publishedAt": [
            //             "1462071600000",
            //             ...
            //         ],
            //         "closedAt": [
            //             "4102369200000",
            //             ...
            //         ],
            //         "difficulty": {
            //             "0": {
            //                 "playLevel": 5
            //             },
            //             ...
            //         }
            //     },
            //     ...
            // }
            let request = await requestJSON("https://bestdori.com/api/songs/all.5.json")
            if case let .success(respJSON) = request {
                var result = [PreviewSong]()
                for (key, value) in respJSON {
                    result.append(.init(
                        id: Int(key) ?? 0,
                        tag: .init(rawValue: value["tag"].stringValue) ?? .normal,
                        bandID: value["bandId"].intValue,
                        jacketImage: value["jacketImage"].map { $0.1.stringValue },
                        musicTitle: .init(
                            jp: value["musicTitle"][0].string,
                            en: value["musicTitle"][1].string,
                            tw: value["musicTitle"][2].string,
                            cn: value["musicTitle"][3].string,
                            kr: value["musicTitle"][4].string
                        ),
                        publishedAt: .init(
                            jp: value["publishedAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(value["publishedAt"][0].stringValue.dropLast(3))!)) : nil,
                            en: value["publishedAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(value["publishedAt"][1].stringValue.dropLast(3))!)) : nil,
                            tw: value["publishedAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(value["publishedAt"][2].stringValue.dropLast(3))!)) : nil,
                            cn: value["publishedAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(value["publishedAt"][3].stringValue.dropLast(3))!)) : nil,
                            kr: value["publishedAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(value["publishedAt"][4].stringValue.dropLast(3))!)) : nil
                        ),
                        closedAt: .init(
                            jp: value["closedAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int(value["closedAt"][0].stringValue.dropLast(3))!)) : nil,
                            en: value["closedAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int(value["closedAt"][1].stringValue.dropLast(3))!)) : nil,
                            tw: value["closedAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int(value["closedAt"][2].stringValue.dropLast(3))!)) : nil,
                            cn: value["closedAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int(value["closedAt"][3].stringValue.dropLast(3))!)) : nil,
                            kr: value["closedAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int(value["closedAt"][4].stringValue.dropLast(3))!)) : nil
                        ),
                        difficulty: value["difficulty"].map {
                            (key: DifficultyType(rawValue: Int($0.0) ?? 0) ?? .easy,
                             value: Difficulty(
                                playLevel: $0.1["playLevel"].intValue,
                                publishedAt: $0.1["publishedAt"].null == nil ? .init(
                                    jp: $0.1["publishedAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int($0.1["publishedAt"][0].stringValue.dropLast(3))!)) : nil,
                                    en: $0.1["publishedAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int($0.1["publishedAt"][1].stringValue.dropLast(3))!)) : nil,
                                    tw: $0.1["publishedAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int($0.1["publishedAt"][2].stringValue.dropLast(3))!)) : nil,
                                    cn: $0.1["publishedAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int($0.1["publishedAt"][3].stringValue.dropLast(3))!)) : nil,
                                    kr: $0.1["publishedAt"][4].string != nil ? Date(timeIntervalSince1970: Double(Int($0.1["publishedAt"][4].stringValue.dropLast(3))!)) : nil
                                ) : nil
                             ))
                        }.reduce(into: [DifficultyType: Difficulty]()) {
                            $0.updateValue($1.value, forKey: $1.key)
                        },
                        musicVideos: value["musicVideos"].exists() ? value["musicVideos"].map {
                            (key: $0.0,
                             value: MusicVideoMetadata(
                                startAt: .init(
                                    jp: $0.1["startAt"][0].string != nil ? Date(timeIntervalSince1970: Double(Int($0.1["startAt"][0].stringValue.dropLast(3))!)) : nil,
                                    en: $0.1["startAt"][1].string != nil ? Date(timeIntervalSince1970: Double(Int($0.1["startAt"][1].stringValue.dropLast(3))!)) : nil,
                                    tw: $0.1["startAt"][2].string != nil ? Date(timeIntervalSince1970: Double(Int($0.1["startAt"][2].stringValue.dropLast(3))!)) : nil,
                                    cn: $0.1["startAt"][3].string != nil ? Date(timeIntervalSince1970: Double(Int($0.1["startAt"][3].stringValue.dropLast(3))!)) : nil,
                                    kr: $0.1["startAt"][4].string != nil ? Date(
                                        timeIntervalSince1970: Double(
                                            Int(
                                                $0.1["startAt"][4].stringValue.dropLast(3)
                                            )!
                                        )
                                    ) : nil
                                )
                             ))
                        }.reduce(into: [String: MusicVideoMetadata]()) {
                            $0.updateValue($1.value, forKey: $1.key)
                        } : nil
                    ))
                }
                return result.sorted { $0.id < $1.id }
            }
            return nil
        }
    }
}

extension DoriAPI.Song {
    public struct PreviewSong: Identifiable {
        public var id: Int
        public var tag: SongTag
        public var bandID: Int
        public var jacketImage: [String]
        public var musicTitle: DoriAPI.LocalizedData<String>
        public var publishedAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
        public var closedAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
        public var difficulty: [DifficultyType: Difficulty] // {Index: {Difficulty}...}(JSON) -> ~(Swift)
        public var musicVideos: [String: MusicVideoMetadata]? // ["music_video_{Int}": ~]
        
        internal init(
            id: Int,
            tag: SongTag,
            bandID: Int,
            jacketImage: [String],
            musicTitle: DoriAPI.LocalizedData<String>,
            publishedAt: DoriAPI.LocalizedData<Date>,
            closedAt: DoriAPI.LocalizedData<Date>,
            difficulty: [DifficultyType : Difficulty],
            musicVideos: [String : MusicVideoMetadata]?
        ) {
            self.id = id
            self.tag = tag
            self.bandID = bandID
            self.jacketImage = jacketImage
            self.musicTitle = musicTitle
            self.publishedAt = publishedAt
            self.closedAt = closedAt
            self.difficulty = difficulty
            self.musicVideos = musicVideos
        }
    }
    
    public enum SongTag: String {
        case normal
        case anime
        case tieUp = "tie_up"
    }
    
    public enum DifficultyType: Int {
        case easy = 0
        case normal
        case hard
        case expert
        case special
    }
    public struct Difficulty {
        public var playLevel: Int
        public var publishedAt: DoriAPI.LocalizedData<Date>? // String(JSON) -> Date(Swift)
        
        internal init(playLevel: Int, publishedAt: DoriAPI.LocalizedData<Date>?) {
            self.playLevel = playLevel
            self.publishedAt = publishedAt
        }
    }
    
    public struct MusicVideoMetadata {
        public var startAt: DoriAPI.LocalizedData<Date> // String(JSON) -> Date(Swift)
    }
}
