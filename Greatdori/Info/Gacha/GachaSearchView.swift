//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaSearchView.swift
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


// MARK: GachaSearchView
struct GachaSearchView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    //    @State var filterClass: DoriFrontend.GachasFilter
    @State var filter = DoriFrontend.Filter()
    @State var sorter = DoriFrontend.Sorter(keyword: .releaseDate(in: .jp), direction: .descending)
    @State var gachas: [DoriFrontend.Gacha.PreviewGacha]?
    @State var searchedGachas: [DoriFrontend.Gacha.PreviewGacha]?
    @State var infoIsAvailable = true
    @State var searchedText = ""
    @State var showDetails = true
    @State var showFilterSheet = false
    @State var presentingGachaID: Int?
    @Namespace var gachaLists
    var body: some View {
        Group {
            Group {
                if let resultGachas = searchedGachas ?? gachas {
                    Group {
                        if !resultGachas.isEmpty {
                            ScrollView {
                                HStack {
                                    Spacer(minLength: 0)
                                    ViewThatFits {
                                        LazyVStack(spacing: showDetails ? nil : bannerSpacing) {
                                            let gachas = resultGachas.chunked(into: 2)
                                            ForEach(gachas, id: \.self) { gachaGroup in
                                                HStack(spacing: showDetails ? nil : bannerSpacing) {
                                                    Spacer(minLength: 0)
                                                    ForEach(gachaGroup) { gacha in
                                                        Button(action: {
                                                            showFilterSheet = false
                                                            //                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                            presentingGachaID = gacha.id
                                                            //                                                            }
                                                        }, label: {
                                                            GachaInfo(gacha, preferHeavierFonts: true, inLocale: nil, showDetails: showDetails, searchedKeyword: $searchedText)
                                                                .frame(maxWidth: bannerWidth)
                                                        })
                                                        .buttonStyle(.plain)
                                                        .wrapIf(true, in: { content in
                                                            if #available(iOS 18.0, macOS 15.0, *) {
                                                                content
                                                                    .matchedTransitionSource(id: gacha.id, in: gachaLists)
                                                            } else {
                                                                content
                                                            }
                                                        })
                                                        .matchedGeometryEffect(id: gacha.id, in: gachaLists)
                                                        if gachaGroup.count == 1 && gachas[0].count != 1 {
                                                            Rectangle()
                                                                .frame(maxWidth: 420, maxHeight: 140)
                                                                .opacity(0)
                                                        }
                                                    }
                                                    Spacer(minLength: 0)
                                                }
                                            }
                                        }
                                        .frame(width: bannerWidth * 2 + bannerSpacing)
                                        LazyVStack(spacing: showDetails ? nil : bannerSpacing) {
                                            ForEach(resultGachas, id: \.self) { gacha in
                                                Button(action: {
                                                    showFilterSheet = false
                                                    //                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    presentingGachaID = gacha.id
                                                    //                                                    }
                                                }, label: {
                                                    GachaInfo(gacha, preferHeavierFonts: true, inLocale: nil, showDetails: showDetails, searchedKeyword: $searchedText)
                                                        .frame(maxWidth: bannerWidth)
                                                })
                                                .buttonStyle(.plain)
                                                .wrapIf(true, in: { content in
                                                    if #available(iOS 18.0, macOS 15.0, *) {
                                                        content
                                                            .matchedTransitionSource(id: gacha.id, in: gachaLists)
                                                    } else {
                                                        content
                                                    }
                                                })
                                                .matchedGeometryEffect(id: gacha.id, in: gachaLists)
                                            }
                                        }
                                        .frame(maxWidth: bannerWidth)
                                    }
                                    .padding(.horizontal)
                                    .animation(.spring(duration: 0.3, bounce: 0.1, blendDuration: 0), value: showDetails)
                                    //                                    .animation(.easeInOut(duration: 0.2), value: showDetails)
                                    Spacer(minLength: 0)
                                }
                            }
                            .geometryGroup()
                            .navigationDestination(item: $presentingGachaID) { id in
                                GachaDetailView(id: id, allGachas: gachas)
#if !os(macOS)
                                    .wrapIf(true, in: { content in
                                        if #available(iOS 18.0, macOS 15.0, *) {
                                            content
                                                .navigationTransition(.zoom(sourceID: id, in: gachaLists))
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
                        if let gachas {
                            searchedGachas = gachas.search(for: searchedText)
                        }
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
                        }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView("Gacha.search.unavailable", systemImage: "line.horizontal.star.fill.line.horizontal", description: Text("Search.unavailable.description"))
                                .onTapGesture {
                                    Task {
                                        await getGachas()
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $searchedText, prompt: "Gacha.search.placeholder")
            .navigationTitle("Gacha")
            .wrapIf(searchedGachas != nil, in: { content in
                if #available(iOS 26.0, *) {
                    content.navigationSubtitle((searchedText.isEmpty && !filter.isFiltered) ? "Gacha.count.\(searchedGachas!.count)" :  "Search.result.\(searchedGachas!.count)")
                } else {
                    content
                }
            })
            .toolbar {
                ToolbarItem {
                    LayoutPicker(selection: $showDetails, options: [("Filter.view.banner-and-details", "text.below.rectangle", true), ("Filter.view.banner-only", "rectangle.grid.1x2", false)])
                }
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                ToolbarItemGroup {
                    FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: PreviewGacha.applicableSortingTypes, hasEndingDate: true)
                }
            }
            .onDisappear {
                showFilterSheet = false
            }
        }
        .withSystemBackground()
        .inspector(isPresented: $showFilterSheet) {
            FilterView(filter: $filter, includingKeys: Set(PreviewGacha.applicableFilteringKeys))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
        .withSystemBackground() // This modifier MUST be placed BOTH before
                                // and after `inspector` to make it work as expected
        .task {
            await getGachas()
        }
        .onChange(of: filter) {
            if let gachas {
                searchedGachas = gachas.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: sorter) {
            if let oldGachas = gachas {
                searchedGachas = gachas!.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: searchedText, {
            if let gachas {
                searchedGachas = gachas.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        })
    }
    
    func getGachas() async {
        infoIsAvailable = true
        DoriCache.withCache(id: "GachaList_\(filter.identity)", trait: .realTime) {
            await DoriFrontend.Gacha.list()
        } .onUpdate {
            if let gachas = $0 {
                self.gachas = gachas.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending))
                searchedGachas = gachas.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            } else {
                infoIsAvailable = false
            }
        }
    }
    
}
