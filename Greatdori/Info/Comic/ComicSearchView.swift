//===---*- Greatdori! -*---------------------------------------------------===//
//
// ComicSearchView.swift
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

// MARK: ComicSearchView
struct ComicSearchView: View {
    @State var theComic: Comic? = nil
    
    let gridLayoutItemWidth: CGFloat = 260*0.9
    var body: some View {
        Group {
            if let theComic {
                ComicInfo(theComic)
            } else {
                Text(verbatim: "WIP")
            }
        }
            .onAppear {
                Task {
//                    DoriCache.withCache(id: "111111", invocation: {
                        theComic = await Comic(id: 1)
//                    }) .onUpdate({ sth in
//                        theComic = sth
//                    })
                }
            }
    }
}

/*
// MARK: ComicSearchView
struct ComicSearchView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    @State var filter = DoriFrontend.Filter()
    @State var sorter = DoriFrontend.Sorter(keyword: .id, direction: .descending)
    @State var comics: [DoriFrontend.Comic.Comic]?
    @State var searchedComics: [DoriFrontend.Comic.Comic]?
    @State var infoIsAvailable = true
    @State var searchedText = ""
    @State var layout = SummaryLayout.horizontal
    @State var showFilterSheet = false
    @State var presentingComicID: Int?
    @Namespace var comicLists
    
    let gridLayoutItemWidth: CGFloat = 260*0.9
    var body: some View {
        Group {
            Group {
                if let resultComics = searchedComics ?? comics {
                    Group {
                        if !resultComics.isEmpty {
                            ScrollView {
                                HStack {
                                    Spacer(minLength: 0)
                                    Group {
                                        if layout == .horizontal {
                                            LazyVStack {
                                                ForEach(resultComics, id: \.self) { comic in
                                                    Button(action: {
                                                        showFilterSheet = false
                                                        presentingComicID = comic.id
                                                    }, label: {
                                                        ComicInfo(comic, layout: layout)
                                                            .highlightKeyword($searchedText)
                                                    })
                                                    .buttonStyle(.plain)
                                                    .wrapIf(true, in: { content in
                                                        if #available(iOS 18.0, macOS 15.0, *) {
                                                            content
                                                                .matchedTransitionSource(id: comic.id, in: comicLists)
                                                        } else {
                                                            content
                                                        }
                                                    })
                                                }
                                            }
                                            .frame(maxWidth: 600)
                                        } else {
                                            LazyVGrid(columns: [GridItem(.adaptive(minimum: gridLayoutItemWidth, maximum: gridLayoutItemWidth))]) {
                                                ForEach(resultComics, id: \.self) { comic in
                                                    Button(action: {
                                                        showFilterSheet = false
                                                        presentingComicID = comic.id
                                                    }, label: {
                                                        ComicInfo(comic, layout: layout)
                                                            .highlightKeyword($searchedText)
                                                    })
                                                    .buttonStyle(.plain)
                                                    .wrapIf(true, in: { content in
                                                        if #available(iOS 18.0, macOS 15.0, *) {
                                                            content
                                                                .matchedTransitionSource(id: comic.id, in: comicLists)
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
                            .navigationDestination(item: $presentingComicID) { id in
                                ComicDetailView(id: id, allComics: comics)
#if !os(macOS)
                                    .wrapIf(true, in: { content in
                                        if #available(iOS 18.0, macOS 15.0, *) {
                                            content
                                                .navigationTransition(.zoom(sourceID: id, in: comicLists))
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
                        if let comics {
                            searchedComics = comics.search(for: searchedText)
                        }
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
                        }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView("Comic.search.unavailable", systemImage: "line.horizontal.star.fill.line.horizontal", description: Text("Search.unavailable.description"))
                                .onTapGesture {
                                    Task {
                                        await getComics()
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $searchedText, prompt: "Comic.search.placeholder")
            .navigationTitle("Comic")
            .wrapIf(searchedComics != nil, in: { content in
                if #available(iOS 26.0, *) {
                    content.navigationSubtitle((searchedText.isEmpty && !filter.isFiltered) ? "Comic.count.\(searchedComics!.count)" :  "Search.result.\(searchedComics!.count)")
                } else {
                    content
                }
            })
            .toolbar {
                ToolbarItem {
                    LayoutPicker(selection: $layout, options: [("Filter.view.list", "list.bullet", SummaryLayout.horizontal), ("Filter.view.grid", "square.grid.2x2", SummaryLayout.vertical)])
                }
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                ToolbarItemGroup {
                    FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: Comic.applicableSortingTypes, hasEndingDate: Comic.hasEndingDate)
                }
            }
            .onDisappear {
                showFilterSheet = false
            }
        }
        .withSystemBackground()
        .inspector(isPresented: $showFilterSheet) {
            FilterView(filter: $filter, includingKeys: Set(Comic.applicableFilteringKeys))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
        .withSystemBackground() // This modifier MUST be placed BOTH before
                                // and after `inspector` to make it work as expected
        .task {
            await getComics()
        }
        .onChange(of: filter) {
            if let comics {
                searchedComics = comics.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: sorter) {
            if let comics {
                searchedComics = comics.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: searchedText, {
            if let comics {
                searchedComics = comics.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        })
    }
    
    func getComics() async {
        infoIsAvailable = true
        withDoriCache(id: "ComicList_\(filter.identity)", trait: .realTime) {
            await Comic.all()
        } .onUpdate {
            if let comics = $0 {
                self.comics = comics.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending))
                searchedComics = comics.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            } else {
                infoIsAvailable = false
            }
        }
    }
}

*/
