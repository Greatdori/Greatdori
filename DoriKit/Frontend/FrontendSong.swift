//
//  FrontendSong.swift
//  Greatdori
//
//  Created by Mark Chan on 8/6/25.
//

import Foundation

extension DoriFrontend {
    public class Song {
        private init() {}
        
        public static func list(filter: Filter = .init()) async -> [PreviewSong]? {
            guard let songs = await DoriAPI.Song.all() else { return nil }
            
            var filteredSongs = songs
            if filter.isFiltered {
                filteredSongs = songs.filter {
                    filter.songType.contains($0.tag)
                }.filter {
                    filter.band.map { $0.rawValue }.contains($0.bandID)
                }.filter { song in
                    for bool in filter.released {
                        for locale in filter.server {
                            if bool {
                                if (song.publishedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 4107477600)) < .now {
                                    return true
                                }
                            } else {
                                if (song.publishedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 0)) > .now {
                                    return true
                                }
                            }
                        }
                    }
                    return false
                }.filter { song in
                    for bool in filter.released {
                        for locale in filter.server {
                            if bool {
                                if (song.publishedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 4107477600)) < .now {
                                    return true
                                }
                            } else {
                                if (song.publishedAt.forLocale(locale) ?? .init(timeIntervalSince1970: 0)) > .now {
                                    return true
                                }
                            }
                        }
                    }
                    return false
                }
            }
            
            switch filter.sort.keyword {
            case .releaseDate(let locale):
                return filteredSongs.sorted { lhs, rhs in
                    filter.sort.compare(
                        lhs.publishedAt.forLocale(locale) ?? lhs.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0),
                        rhs.publishedAt.forLocale(locale) ?? rhs.publishedAt.forPreferredLocale() ?? .init(timeIntervalSince1970: 0)
                    )
                }
            default:
                return filteredSongs.sorted { lhs, rhs in
                    filter.sort.compare(lhs.id, rhs.id)
                }
            }
        }
    }
}

extension DoriFrontend.Song {
    public typealias PreviewSong = DoriAPI.Song.PreviewSong
}
