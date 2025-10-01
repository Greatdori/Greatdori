//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongSearchView.swift
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
import SDWebImageSwiftUI

// MARK: SongSearchView
struct SongSearchView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    @State var filter = DoriFrontend.Filter()
    @State var sorter = DoriFrontend.Sorter(keyword: .releaseDate(in: .jp), direction: .descending)
    @State var songs: [DoriFrontend.Song.PreviewSong]?
    @State var searchedSongs: [DoriFrontend.Song.PreviewSong]?
    @State var infoIsAvailable = true
    @State var searchedText = ""
    @State var layout = SummaryLayout.horizontal
    @State var showFilterSheet = false
    @State var presentingSongID: Int?
    @Namespace var songLists
    
    let gridLayoutItemWidth: CGFloat = 225
    var body: some View {
        Group {
            Group {
                if let resultSongs = searchedSongs ?? songs {
                    Group {
                        if !resultSongs.isEmpty {
                            ScrollView {
                                HStack {
                                    Spacer(minLength: 0)
                                    Group {
                                        if layout == .horizontal {
                                            LazyVStack {
                                                ForEach(resultSongs, id: \.self) { song in
                                                    Button(action: {
                                                        showFilterSheet = false
                                                        presentingSongID = song.id
                                                    }, label: {
                                                        SongInfo(song, layout: layout)
                                                            .highlightKeyword($searchedText)
                                                    })
                                                    .buttonStyle(.plain)
                                                    .wrapIf(true, in: { content in
                                                        if #available(iOS 18.0, macOS 15.0, *) {
                                                            content
                                                                .matchedTransitionSource(id: song.id, in: songLists)
                                                        } else {
                                                            content
                                                        }
                                                    })
                                                }
                                            }
                                            .frame(maxWidth: 600)
                                        } else {
                                            LazyVGrid(columns: [GridItem(.adaptive(minimum: gridLayoutItemWidth, maximum: gridLayoutItemWidth))]) {
                                                ForEach(resultSongs, id: \.self) { song in
                                                    Button(action: {
                                                        showFilterSheet = false
                                                        presentingSongID = song.id
                                                    }, label: {
                                                        SongInfo(song, layout: layout)
                                                            .highlightKeyword($searchedText)
                                                    })
                                                    .buttonStyle(.plain)
                                                    .wrapIf(true, in: { content in
                                                        if #available(iOS 18.0, macOS 15.0, *) {
                                                            content
                                                                .matchedTransitionSource(id: song.id, in: songLists)
                                                        } else {
                                                            content
                                                        }
                                                    })
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    Spacer(minLength: 0)
                                }
                            }
                            .geometryGroup()
                            .navigationDestination(item: $presentingSongID) { id in
                                SongDetailView(id: id, allSongs: songs)
#if !os(macOS)
                                    .wrapIf(true, in: { content in
                                        if #available(iOS 18.0, macOS 15.0, *) {
                                            content
                                                .navigationTransition(.zoom(sourceID: id, in: songLists))
                                        } else {
                                            content
                                        }
                                    })
#endif
                            }
                        } else {
                            ContentUnavailableView("Search.no-results", systemImage: "magnifyingglass", description: Text("Search.no-results.description"))
                        }
                    }
                    .onSubmit {
                        if let songs {
                            searchedSongs = songs.search(for: searchedText)
                        }
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
                        }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView("Song.search.unavailable", systemImage: "line.horizontal.star.fill.line.horizontal", description: Text("Search.unavailable.description"))
                                .onTapGesture {
                                    Task {
                                        await getSongs()
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $searchedText, prompt: "Song.search.placeholder")
            .navigationTitle("Song")
            .wrapIf(searchedSongs != nil, in: { content in
                if #available(iOS 26.0, *) {
                    content.navigationSubtitle((searchedText.isEmpty && !filter.isFiltered) ? "Song.count.\(searchedSongs!.count)" :  "Search.result.\(searchedSongs!.count)")
                } else {
                    content
                }
            })
            .toolbar {
                ToolbarItem {
                    LayoutPicker(selection: $layout, options: [("Filter.view.list", "list.bullet", SummaryLayout.horizontal), ("Filter.view.grid", "square.grid.2x2", SummaryLayout.vertical())])
                }
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                ToolbarItemGroup {
                    FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: PreviewSong.applicableSortingTypes, hasEndingDate: false)
                }
            }
            .onDisappear {
                showFilterSheet = false
            }
        }
        .withSystemBackground()
        .inspector(isPresented: $showFilterSheet) {
            FilterView(filter: $filter, includingKeys: Set(PreviewSong.applicableFilteringKeys))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
        .withSystemBackground() // This modifier MUST be placed BOTH before
                                // and after `inspector` to make it work as expected
        .task {
            await getSongs()
        }
        .onChange(of: filter) {
            if let songs {
                searchedSongs = songs.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: sorter) {
            if let songs {
                searchedSongs = songs.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: searchedText, {
            if let songs {
                searchedSongs = songs.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        })
    }
    
    func getSongs() async {
        infoIsAvailable = true
        withDoriCache(id: "SongList_\(filter.identity)", trait: .realTime) {
            await PreviewSong.all()
        } .onUpdate {
            if let songs = $0 {
                self.songs = songs.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending))
                searchedSongs = songs.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            } else {
                infoIsAvailable = false
            }
        }
    }
}
