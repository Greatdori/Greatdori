//===---*- Greatdori! -*---------------------------------------------------===//
//
// DetailSongsSection.swift
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

import DoriKit
import SDWebImageSwiftUI
import SwiftUI


// MARK: DetailsSongsSection
struct DetailsSongsSection: View {
    var songs: [PreviewSong]
    var applyLocaleFilter: Bool = false
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var songsSorted: [PreviewSong] = []
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if !songsSorted.isEmpty {
                        ForEach((showAll ? songsSorted : Array(songsSorted.prefix(3))), id: \.self) { item in
                            NavigationLink(destination: {
                                SongDetailView(id: item.id)
                            }, label: {
                                SongInfo(item, layout: .horizontal)
                            })
                            .buttonStyle(.plain)
                        }
                    } else {
                        DetailUnavailableView(title: "Details.songs.unavailable", symbol: "person.crop.square.on.square.angled")
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.songs")
                        .font(.title2)
                        .bold()
                    if applyLocaleFilter {
                        DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
                    }
                    Spacer()
                    if songsSorted.count > 3 {
                        Button(action: {
                            showAll.toggle()
                        }, label: {
                            Text(showAll ? "Details.show-less" : "Details.show-all.\(songsSorted.count)")
                                .foregroundStyle(.secondary)
                        })
                        .buttonStyle(.plain)
                    }
                    
                }
                .frame(maxWidth: 615)
            })
        }
        .onAppear {
            songsSorted = songs.sorted(withDoriSorter: DoriSorter(keyword: .releaseDate(in: .jp)))
            if applyLocaleFilter {
                songsSorted = songsSorted.filter{$0.publishedAt.availableInLocale(locale)}
            }
        }
        .onChange(of: locale) {
            songsSorted = songs.sorted(withDoriSorter: DoriSorter(keyword: .releaseDate(in: .jp)))
            if applyLocaleFilter {
                songsSorted = songsSorted.filter{$0.publishedAt.availableInLocale(locale)}
            }
        }
    }
}
