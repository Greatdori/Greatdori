//===---*- Greatdori! -*---------------------------------------------------===//
//
// Costume.swift
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

// MARK: CostumeSearchView
struct CostumeSearchView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    @State var filter = DoriFrontend.Filter()
    @State var sorter = DoriFrontend.Sorter(keyword: .releaseDate(in: .jp), direction: .descending)
    @State var costumes: [DoriFrontend.Costume.PreviewCostume]?
    @State var searchedCostumes: [DoriFrontend.Costume.PreviewCostume]?
    @State var infoIsAvailable = true
    @State var searchedText = ""
    @State var layout = Axis.horizontal
    @State var showFilterSheet = false
    @State var presentingCostumeID: Int?
    @Namespace var costumeLists
    var body: some View {
        Group {
            Group {
                if let resultCostumes = searchedCostumes ?? costumes {
                    Group {
                        if !resultCostumes.isEmpty {
                            ScrollView {
                                HStack {
                                    Spacer(minLength: 0)
                                    Group {
                                        if layout == .horizontal {
                                            LazyVStack {
                                                ForEach(resultCostumes, id: \.self) { costume in
                                                    Button(action: {
                                                        showFilterSheet = false
                                                        presentingCostumeID = costume.id
                                                    }, label: {
                                                        CostumeInfo(costume, preferHeavierFonts: true, inLocale: nil, layout: layout, searchedKeyword: $searchedText)
                                                    })
                                                    .buttonStyle(.plain)
                                                    .wrapIf(true, in: { content in
                                                        if #available(iOS 18.0, macOS 15.0, *) {
                                                            content
                                                                .matchedTransitionSource(id: costume.id, in: costumeLists)
                                                        } else {
                                                            content
                                                        }
                                                    })
                                                    .matchedGeometryEffect(id: costume.id, in: costumeLists)
                                                }
                                            }
                                            .frame(maxWidth: 600)
                                        } else {
                                            LazyVGrid(columns: [.init(.adaptive(minimum: 200), spacing: bannerSpacing)]) {
                                                ForEach(resultCostumes, id: \.self) { costume in
                                                    Button(action: {
                                                        showFilterSheet = false
                                                        presentingCostumeID = costume.id
                                                    }, label: {
                                                        CostumeInfo(costume, preferHeavierFonts: true, inLocale: nil, layout: layout, searchedKeyword: $searchedText)
                                                            .frame(maxWidth: bannerWidth)
                                                    })
                                                    .buttonStyle(.plain)
                                                    .wrapIf(true, in: { content in
                                                        if #available(iOS 18.0, macOS 15.0, *) {
                                                            content
                                                                .matchedTransitionSource(id: costume.id, in: costumeLists)
                                                        } else {
                                                            content
                                                        }
                                                    })
                                                    .matchedGeometryEffect(id: costume.id, in: costumeLists)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .animation(.spring(duration: 0.3, bounce: 0.1, blendDuration: 0), value: layout)
                                    Spacer(minLength: 0)
                                }
                            }
                            .geometryGroup()
                            .navigationDestination(item: $presentingCostumeID) { id in
                                CostumeDetailView(id: id, allCostumes: costumes)
                                #if !os(macOS)
                                    .wrapIf(true, in: { content in
                                        if #available(iOS 18.0, macOS 15.0, *) {
                                            content
                                                .navigationTransition(.zoom(sourceID: id, in: costumeLists))
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
                        if let costumes {
                            searchedCostumes = costumes.search(for: searchedText)
                        }
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
                        }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView("Costume.search.unavailable", systemImage: "line.horizontal.star.fill.line.horizontal", description: Text("Search.unavailable.description"))
                                .onTapGesture {
                                    Task {
                                        await getCostumes()
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $searchedText, prompt: "Costume.search.placeholder")
            .navigationTitle("Costume")
            .wrapIf(searchedCostumes != nil, in: { content in
                if #available(iOS 26.0, *) {
                    content.navigationSubtitle((searchedText.isEmpty && !filter.isFiltered) ? "Costume.count.\(searchedCostumes!.count)" :  "Search.result.\(searchedCostumes!.count)")
                } else {
                    content
                }
            })
            .toolbar {
#if os(iOS)
                ToolbarItem {
                    Menu {
                        Picker("", selection: $layout.animation(.easeInOut(duration: 0.2))) {
                            Label(title: {
                                Text("Filter.view.list")
                            }, icon: {
                                Image(systemName: "list.bullet")
                            })
                            .tag(Axis.horizontal)
                            Label(title: {
                                Text("Filter.view.grid")
                            }, icon: {
                                Image(systemName: "rectangle.grid.2x2")
                            })
                            .tag(Axis.vertical)
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    } label: {
                        if layout == .horizontal {
                            Image(systemName: "list.bullet")
                        } else {
                            Image(systemName: "rectangle.grid.2x2")
                        }
                    }
                }
#else
                ToolbarItem {
                    Picker("", selection: $layout) {
                        Label(title: {
                            Text("Filter.view.list")
                        }, icon: {
                            Image(systemName: "list.bullet")
                        })
                        .tag(Axis.horizontal)
                        Label(title: {
                            Text("Filter.view.grid")
                        }, icon: {
                            Image(systemName: "rectangle.grid.2x2")
                        })
                        .tag(Axis.vertical)
                    }
                    .pickerStyle(.inline)
                }
#endif
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                ToolbarItemGroup {
                    FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: PreviewCostume.applicableSortingTypes)
                }
            }
            .onDisappear {
                showFilterSheet = false
            }
        }
        .withSystemBackground()
        .inspector(isPresented: $showFilterSheet) {
            FilterView(filter: $filter, includingKeys: [.attribute, .character, .characterRequiresMatchAll, .server, .timelineStatus, .gachaType])
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
        .withSystemBackground() // This modifier MUST be placed BOTH before
                                // and after `inspector` to make it work as expected
        .task {
            await getCostumes()
        }
        .onChange(of: filter) {
            if let costumes {
                searchedCostumes = costumes.filter(withDoriFilter: filter).search(for: searchedText)
            }
        }
        .onChange(of: sorter) {
            if let oldCostumes = costumes {
                costumes = oldCostumes.sorted(withDoriSorter: sorter)
                searchedCostumes = costumes!.filter(withDoriFilter: filter).search(for: searchedText)
            }
        }
        .onChange(of: searchedText, {
            if let costumes {
                searchedCostumes = costumes.filter(withDoriFilter: filter).search(for: searchedText)
            }
        })
    }
    
    func getCostumes() async {
        infoIsAvailable = true
        withDoriCache(id: "CostumeList_\(filter.identity)", trait: .realTime) {
            await PreviewCostume.all()
        } .onUpdate {
            if let costumes = $0 {
                self.costumes = costumes.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending))
                searchedCostumes = costumes.sorted(withDoriSorter: sorter)
            } else {
                infoIsAvailable = false
            }
        }
    }
}

// MARK: CostumeDetailView
struct CostumeDetailView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var id: Int
    var allCostumes: [PreviewCostume]? = nil
    @State var costumeID: Int = 0
    @State var informationLoadPromise: CachePromise<Costume?>?
    @State var information: Costume?
    @State var infoIsAvailable = true
    @State var cardNavigationDestinationID: Int?
    @State var allCostumeIDs: [Int] = []
    @State var showSubtitle: Bool = false
    var body: some View {
        EmptyContainer {
            if let information {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            CostumeDetailOverviewView(information: information, cardNavigationDestinationID: $cardNavigationDestinationID)
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
                            await getInformation(id: costumeID)
                        }
                    }, label: {
                        ExtendedConstraints {
                            ContentUnavailableView("Costume.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
                        }
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .withSystemBackground()
        .navigationDestination(item: $cardNavigationDestinationID, destination: { id in
            Text("\(id)")
        })
        .navigationTitle(Text(information?.description.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Costume") : "")"))
#if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.description.forPreferredLocale() != nil ? "#\(costumeID)" : "")
            } else {
                content
            }
        }
#endif
        .onAppear {
            Task {
                if (allCostumes ?? []).isEmpty {
                    allCostumeIDs = await (Event.all() ?? []).sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending)).map {$0.id}
                } else {
                    allCostumeIDs = allCostumes!.map {$0.id}
                }
            }
        }
        .onChange(of: costumeID, {
            Task {
                await getInformation(id: costumeID)
            }
        })
        .task {
            costumeID = id
            await getInformation(id: costumeID)
        }
        .toolbar {
            ToolbarItemGroup(content: {
                DetailsIDSwitcher(currentID: $costumeID, allIDs: allCostumeIDs, destination: { CostumeSearchView() })
                    .onChange(of: costumeID) {
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
        informationLoadPromise = DoriCache.withCache(id: "CostumeDetail_\(id)", trait: .realTime) {
            await Costume(id: id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
            } else {
                infoIsAvailable = false
            }
        }
    }
}

// MARK: CostumeDetailOverviewView
struct CostumeDetailOverviewView: View {
    let information: Costume
    @State var cardsArray: [DoriFrontend.Card.PreviewCard] = []
    @State var cardsArraySeperated: [[DoriFrontend.Card.PreviewCard?]] = []
    @State var cardsPercentage: Int = -100
    @State var rewardsArray: [DoriFrontend.Card.PreviewCard] = []
    @State var cardsTitleWidth: CGFloat = 0 // Fixed
    @State var cardsPercentageWidth: CGFloat = 0 // Fixed
    @State var cardsContentRegularWidth: CGFloat = 0 // Fixed
    @State var cardsFixedWidth: CGFloat = 0 //Fixed
    @State var cardsUseCompactLayout = true
    @Binding var cardNavigationDestinationID: Int?
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    var body: some View {
        VStack {
            Group {
                // MARK: Title Image
                Group {
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                    // FIXME: Replace image with Live2D viewer
                    WebImage(url: information.thumbImageURL) { image in
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
                        // MARK: Description
                        Group {
                            ListItemView(title: {
                                Text("Costume.title")
                                    .bold()
                            }, value: {
                                MultilingualText(source: information.description)
                            })
                            Divider()
                        }
                        
                        // MARK: Character
                        Group {
                            ListItemView(title: {
                                Text("Costume.character")
                                    .bold()
                            }, value: {
                                // FIXME: This requires `ExtendedCostume` to be
                                // FIXME: implemented in DoriKit.
                            })
                            Divider()
                        }
                        
                        // MARK: Band
                        Group {
                            ListItemView(title: {
                                Text("Costume.band")
                                    .bold()
                            }, value: {
                                // FIXME: This requires `ExtendedCostume` to be
                                // FIXME: implemented in DoriKit.
                            })
                            Divider()
                        }
                        
                        // MARK: Release Date
                        Group {
                            ListItemView(title: {
                                Text("Costume.release-date")
                                    .bold()
                            }, value: {
                                MultilingualText(source: information.publishedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            })
                            Divider()
                        }
                        
                        if !information.howToGet.isValueEmpty {
                            // MARK: How to Get
                            Group {
                                ListItemView(title: {
                                    Text("Costume.how-to-get")
                                        .bold()
                                }, value: {
                                    MultilingualText(source: information.howToGet)
                                }, displayMode: .basedOnUISizeClass)
                                Divider()
                            }
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
                        
                    }
                }
            }
        }
        .frame(maxWidth: 600)
    }
}
