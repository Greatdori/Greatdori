//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongListView.swift
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

import SwiftUI
import DoriKit

struct SongListView: View {
    @State var filter = DoriFrontend.Filter.recoverable(id: "SongList")
    @State var songs: [DoriFrontend.Song.PreviewSong]?
    @State var isFilterSettingsPresented = false
    @State var isSearchPresented = false
    @State var searchInput = ""
    @State var searchedSongs: [DoriFrontend.Song.PreviewSong]?
    @State var availability = true
    var body: some View {
        List {
            if let songs = searchedSongs ?? songs {
                ForEach(songs) { song in
                    NavigationLink(destination: { SongDetailView(id: song.id) }) {
                        SongCardView(song)
                    }
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入歌曲时出错", systemImage: "_song", retryHandler: getSongs)
                }
            }
        }
        .navigationTitle("歌曲")
        .sheet(isPresented: $isFilterSettingsPresented) {
            Task {
                songs = nil
                await getSongs()
            }
        } content: {
            FilterView(filter: $filter, includingKeys: [
                .songType,
                .band,
                .server,
                .released
            ]) {
                if let songs {
                    SearchView(items: songs, text: $searchInput) { result in
                        searchedSongs = result
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isFilterSettingsPresented = true
                }, label: {
                    Image(systemName: "line.3.horizontal.decrease")
                })
                .tint(filter.isFiltered || !searchInput.isEmpty ? .accent : nil)
            }
        }
        .task {
            await getSongs()
        }
    }
    
    func getSongs() async {
        availability = true
        DoriCache.withCache(id: "SongList_\(filter.identity)") {
            await DoriFrontend.Song.list()
        }.onUpdate {
            if let songs = $0 {
                self.songs = songs
            } else {
                availability = false
            }
        }
    }
}
