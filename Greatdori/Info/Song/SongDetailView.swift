//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDetailView.swift
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
    @State var arts: [InfoArtsTab] = []
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
                            
                            if !arts.isEmpty {
                                DetailSectionsSpacer()
                                DetailArtsSection(information: arts)
                            }
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
                    .navigationSubtitle(information?.song.musicTitle.forPreferredLocale() != nil ? "#\(songID)" : "")
            } else {
                content
            }
        }
#endif
        .task {
            if (allSongs ?? []).isEmpty {
                allSongIDs = await (Event.all() ?? []).sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending)).map {$0.id}
            } else {
                allSongIDs = allSongs!.map {$0.id}
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
                
                arts = []
                var artsCover: [InfoArtsItem] = []
                for locale in DoriLocale.allCases {
                    if let url = information.song.jacketImageURL(in: locale, allowsFallback: false) {
                        artsCover.append(InfoArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url))
                    }
                }
                arts.append(InfoArtsTab(tabName: "Song.art.cover", content: artsCover))
            } else {
                infoIsAvailable = false
            }
        }
    }
}

// MARK: SongDetailOverviewView
struct SongDetailOverviewView: View {
    let information: Song
    
    let coverSideLength: CGFloat = 270
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
                    .frame(width: coverSideLength, height: coverSideLength)
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
