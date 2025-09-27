//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongView.swift
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
    @State var layout = Axis.horizontal
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
                                                        SongInfo(song, preferHeavierFonts: true, layout: layout, searchedKeyword: $searchedText)
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
                                                        SongInfo(song, preferHeavierFonts: true, layout: layout, searchedKeyword: $searchedText)
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
                    LayoutPicker(selection: $layout, options: [("Filter.view.list", "list.bullet", Axis.horizontal), ("Filter.view.grid", "square.grid.2x2", Axis.vertical)])
                }
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                ToolbarItemGroup {
                    FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: PreviewSong.applicableSortingTypes)
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

// MARK: SongDetailView
struct SongDetailView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var id: Int
    var allSongs: [PreviewSong]? = nil
    @State var songID: Int = 0
    @State var informationLoadPromise: CachePromise<ExtendedSong?>?
    @State var information: ExtendedSong?
    @State var infoIsAvailable = true
    @State var allSongIDs: [Int] = []
    @State var showSubtitle: Bool = false
    var body: some View {
        EmptyContainer {
            if let information {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            SongDetailOverviewView(information: information.song)
                            
                            DetailSectionsSpacer()
                            SongDetailGameplayView(information: information)
                        }
                        .padding()
                        Spacer(minLength: 0)
                    }
                }
                .scrollDisablesMultilingualTextPopover()
            } else {
                if infoIsAvailable {
                    ExtendedConstraints {
                        ProgressView()
                    }
                } else {
                    Button(action: {
                        Task {
                            await getInformation(id: songID)
                        }
                    }, label: {
                        ExtendedConstraints {
                            ContentUnavailableView("Song.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
                        }
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .withSystemBackground()
        .navigationTitle(Text(information?.song.musicTitle.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Song") : "")"))
#if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.description.forPreferredLocale() != nil ? "#\(songID)" : "")
            } else {
                content
            }
        }
#endif
        .onAppear {
            Task {
                if (allSongs ?? []).isEmpty {
                    allSongIDs = await (Event.all() ?? []).sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending)).map {$0.id}
                } else {
                    allSongIDs = allSongs!.map {$0.id}
                }
            }
        }
        .onChange(of: songID, {
            Task {
                await getInformation(id: songID)
            }
        })
        .task {
            songID = id
            await getInformation(id: songID)
        }
        .toolbar {
            ToolbarItemGroup(content: {
                DetailsIDSwitcher(currentID: $songID, allIDs: allSongIDs, destination: { SongSearchView() })
                    .onChange(of: songID) {
                        information = nil
                    }
                    .onAppear {
                        showSubtitle = (sizeClass == .compact)
                    }
            })
        }
    }
    
    func getInformation(id: Int) async {
        infoIsAvailable = true
        informationLoadPromise?.cancel()
        informationLoadPromise = DoriCache.withCache(id: "SongDetail_\(id)", trait: .realTime) {
            await ExtendedSong(id: id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
            } else {
                infoIsAvailable = false
            }
        }
    }
}

// MARK: SongDetailOverviewView
struct SongDetailOverviewView: View {
    let information: Song
    
    let coverSideLength: CGFloat = 320
    var body: some View {
        VStack {
            Group {
                //                // MARK: Title Image
                Group {
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                    WebImage(url: information.jacketImageURL) { image in
                        image
                            .antialiased(true)
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(getPlaceholderColor())
                    }
                    .interpolation(.high)
                    .frame(width: 96, height: 96)
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                }
                // MARK: Info
                CustomGroupBox(cornerRadius: 20) {
                    LazyVStack {
                        // MARK: Title
                        Group {
                            ListItemView(title: {
                                Text("Song.title")
                                    .bold()
                            }, value: {
                                MultilingualText(information.musicTitle)
                            })
                            Divider()
                        }
                        
                        // MARK: Type
                        Group {
                            ListItemView(title: {
                                Text("Song.type")
                                    .bold()
                            }, value: {
                                Text(information.tag.localizedString)
                            })
                            Divider()
                        }
                        
                        // MARK: Lyrics
                        Group {
                            ListItemView(title: {
                                Text("Song.lyrics")
                                    .bold()
                            }, value: {
                                MultilingualText(information.lyricist)
                            })
                            Divider()
                        }
                        
                        // MARK: Composer
                        Group {
                            ListItemView(title: {
                                Text("Song.composer")
                                    .bold()
                            }, value: {
                                MultilingualText(information.composer)
                            })
                            Divider()
                        }
                        
                        // MARK: Arrangement
                        Group {
                            ListItemView(title: {
                                Text("Song.arrangement")
                                    .bold()
                            }, value: {
                                MultilingualText(information.arranger)
                            })
                            Divider()
                        }
                        
                        // MARK: ID
                        Group {
                            ListItemView(title: {
                                Text("ID")
                                    .bold()
                            }, value: {
                                Text("\(String(information.id))")
                            })
                        }
                        //
                        //                    }
                        //                }
                        //            }
                        //        }
                        //        .frame(maxWidth: 600)
                    }
                }
            }
        }
        .frame(maxWidth: 600)
    }
}

struct SongDetailGameplayView: View {
    var information: ExtendedSong
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                CustomGroupBox {
                    VStack {
                        if let band = information.band {
                            //MARK: Band
                            Group {
                                ListItemView(title: {
                                    Text("Character.band")
                                        .bold()
                                }, value: {
                                    MultilingualText(band.bandName)
                                    //                            Text(DoriCache.preCache.mainBands.first{$0.id == bandID}?.bandName.forPreferredLocale(allowsFallback: true) ?? "Unknown")
                                    if DoriCache.preCache.mainBands.contains(where: { $0.id == band.id }) || !DoriCache.preCacheAvailability {
                                        WebImage(url: band.iconImageURL)
                                            .resizable()
                                            .interpolation(.high)
                                            .antialiased(true)
                                            .frame(width: 30, height: 30)
                                    }
                                    
                                })
                                Divider()
                            }
                        }
                        
                        
                        // MARK: Release Date
                        Group {
                            ListItemView(title: {
                                Text("Song.release-date")
                                    .bold()
                            }, value: {
                                MultilingualText(information.song.publishedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            })
                            Divider()
                        }
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Song.gameplay")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .frame(maxWidth: 615)
            })
        }
    }
}
