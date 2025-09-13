//===---*- Greatdori! -*---------------------------------------------------===//
//
// ComicListView.swift
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

struct ComicListView: View {
    @State var filter = DoriFrontend.Filter.recoverable(id: "ComicList")
    @State var sorter = DoriFrontend.Sorter.recoverable(id: "ComicList")
    @State var comics: [DoriFrontend.Comic.Comic]?
    @State var isFilterSettingsPresented = false
    @State var isSearchPresented = false
    @State var searchInput = ""
    @State var searchedComics: [DoriFrontend.Comic.Comic]?
    @State var availability = true
    var body: some View {
        List {
            if let comics = searchedComics ?? comics {
                ForEach(comics) { comic in
                    NavigationLink(destination: { ComicDetailView(comic: comic) }) {
                        ComicCardView(comic)
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
                    UnavailableView("载入漫画时出错", systemImage: "photo.on.rectangle.angled.fill", retryHandler: getComics)
                }
            }
        }
        .navigationTitle("漫画")
        .sheet(isPresented: $isFilterSettingsPresented) {
            Task {
                comics = nil
                await getComics()
            }
        } content: {
            FilterView(filter: $filter, sorter: $sorter, includingKeys: [
                .comicType,
                .character,
                .characterRequiresMatchAll,
                .server
            ], includingKeywords: [
                .id
            ]) {
                if let comics {
                    SearchView(items: comics, text: $searchInput) { result in
                        searchedComics = result
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
            await getComics()
        }
    }
    
    func getComics() async {
        availability = true
        DoriCache.withCache(id: "ComicList_\(filter.identity)_\(sorter.identity)") {
            await DoriFrontend.Comic.list()?
                .filter(withDoriFilter: filter)
                .sorted(withDoriSorter: sorter)
        }.onUpdate {
            if let comics = $0 {
                self.comics = comics
            } else {
                availability = false
            }
        }
    }
}
