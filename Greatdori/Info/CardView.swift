//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardView.swift
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


// MARK: CardSearchView
struct CardSearchView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    @State var filter = DoriFrontend.Filter()
    @State var sorter = DoriFrontend.Sorter(keyword: .releaseDate(in: .jp), direction: .descending)
    @State var cards: [DoriFrontend.Card.CardWithBand]?
    @State var searchedCards: [DoriFrontend.Card.CardWithBand]?
    @State var infoIsAvailable = true
    @State var searchedText = ""
    @State var layoutType = 1
    @State var showFilterSheet = false
    @State var presentingCardID: Int?
    @Namespace var cardLists
    
    let gridLayoutItemWidth: CGFloat = 200*0.9
    let galleryLayoutItemWidth: CGFloat = 200*0.9
    var body: some View {
        Group {
            Group {
                if let resultCards = searchedCards ?? cards {
                    Group {
                        if !resultCards.isEmpty {
                            ScrollView {
                                HStack {
                                    Spacer(minLength: 0)
                                    Group {
                                        if layoutType == 1 {
                                            LazyVStack {
                                                ForEach(resultCards, id: \.self) { card in
                                                    Button(action: {
                                                        showFilterSheet = false
                                                        presentingCardID = card.id
                                                    }, label: {
                                                        CardInfo(card.card, layoutType: layoutType, preferHeavierFonts: true, searchedText: searchedText)
                                                    })
                                                    .buttonStyle(.plain)
                                                    .wrapIf(true, in: { content in
                                                        if #available(iOS 18.0, macOS 15.0, *) {
                                                            content
                                                                .matchedTransitionSource(id: card.id, in: cardLists)
                                                        } else {
                                                            content
                                                        }
                                                    })
                                                }
                                            }
                                            .frame(maxWidth: 600)
                                        } else {
                                            LazyVGrid(columns: [GridItem(.adaptive(minimum: layoutType == 2 ? gridLayoutItemWidth : galleryLayoutItemWidth, maximum: layoutType == 2 ? gridLayoutItemWidth : galleryLayoutItemWidth))]) {
                                                ForEach(resultCards, id: \.self) { card in
                                                    Button(action: {
                                                        showFilterSheet = false
                                                        presentingCardID = card.id
                                                    }, label: {
                                                        CardInfo(card.card, layoutType: layoutType, preferHeavierFonts: true, searchedText: searchedText)
                                                    })
                                                    .buttonStyle(.plain)
                                                    .wrapIf(true, in: { content in
                                                        if #available(iOS 18.0, macOS 15.0, *) {
                                                            content
                                                                .matchedTransitionSource(id: card.id, in: cardLists)
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
//                                */
                            }
                            .geometryGroup()
                            .navigationDestination(item: $presentingCardID) { id in
                                CardDetailView(id: id, allCards: cards)
#if !os(macOS)
                                    .wrapIf(true, in: { content in
                                        if #available(iOS 18.0, macOS 15.0, *) {
                                            content
                                                .navigationTransition(.zoom(sourceID: id, in: cardLists))
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
                        if let cards {
                            searchedCards = cards.search(for: searchedText)
                        }
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
                        }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView("Card.search.unavailable", systemImage: "line.horizontal.star.fill.line.horizontal", description: Text("Search.unavailable.description"))
                                .onTapGesture {
                                    Task {
                                        await getCards()
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $searchedText, prompt: "Card.search.placeholder")
            .navigationTitle("Card")
            .wrapIf(searchedCards != nil, in: { content in
                if #available(iOS 26.0, *) {
                    content.navigationSubtitle((searchedText.isEmpty && !filter.isFiltered) ? "Card.count.\(searchedCards!.count)" :  "Search.result.\(searchedCards!.count)")
                } else {
                    content
                }
            })
            .toolbar {
                ToolbarItem {
                    LayoutPicker(selection: $layoutType, options: [("Filter.view.list", "list.bullet", 1), ("Filter.view.grid", "square.grid.2x2", 2), ("Filter.view.gallery", "text.below.rectangle", 3)])
                }
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                ToolbarItemGroup {
                    FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: PreviewCard.applicableSortingTypes)
                }
            }
            .onDisappear {
                showFilterSheet = false
            }
        }
        .withSystemBackground()
        .inspector(isPresented: $showFilterSheet) {
            FilterView(filter: $filter, includingKeys: Set(CardWithBand.applicableFilteringKeys))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
        .withSystemBackground() // This modifier MUST be placed BOTH before
                                // and after `inspector` to make it work as expected
        .task {
            await getCards()
        }
        .onChange(of: filter) {
            if let cards {
                searchedCards = cards.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: sorter) {
            if let cards {
                searchedCards = cards.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: searchedText, {
            if let cards {
                searchedCards = cards.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        })
    }
    
    func getCards() async {
        infoIsAvailable = true
        withDoriCache(id: "CardList_\(filter.identity)", trait: .realTime) {
            await Card.allWithBand()
        } .onUpdate {
            if let cards = $0 {
                self.cards = cards.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending))
                searchedCards = cards.sorted(withDoriSorter: sorter)
            } else {
                infoIsAvailable = false
            }
        }
    }
}

// MARK: CardDetailView
struct CardDetailView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var id: Int
    var allCards: [CardWithBand]? = nil
    @State var cardID: Int = 0
    @State var informationLoadPromise: CachePromise<Card?>?
    @State var information: Card?
    @State var infoIsAvailable = true
    @State var cardNavigationDestinationID: Int?
    @State var allCardIDs: [Int] = []
    @State var showSubtitle: Bool = false
    var body: some View {
        EmptyContainer {
            if let information {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
//                            CardDetailOverviewView(information: information, cardNavigationDestinationID: $cardNavigationDestinationID)
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
                            await getInformation(id: cardID)
                        }
                    }, label: {
                        ExtendedConstraints {
                            ContentUnavailableView("Card.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
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
        .navigationTitle(Text(information?.prefix.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Card") : "")"))
#if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.prefix.forPreferredLocale() != nil ? "#\(cardID)" : "")
            } else {
                content
            }
        }
#endif
        .onAppear {
            Task {
                if (allCards ?? []).isEmpty {
                    allCardIDs = await (Event.all() ?? []).sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending)).map {$0.id}
                } else {
                    allCardIDs = allCards!.map {$0.id}
                }
            }
        }
        .onChange(of: cardID, {
            Task {
                await getInformation(id: cardID)
            }
        })
        .task {
            cardID = id
            await getInformation(id: cardID)
        }
        .toolbar {
            ToolbarItemGroup(content: {
                DetailsIDSwitcher(currentID: $cardID, allIDs: allCardIDs, destination: { CardSearchView() })
                    .onChange(of: cardID) {
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
        informationLoadPromise = DoriCache.withCache(id: "CardDetail_\(id)", trait: .realTime) {
            await Card(id: id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
            } else {
                infoIsAvailable = false
            }
        }
    }
}

/*
// MARK: CardDetailOverviewView
struct CardDetailOverviewView: View {
    let information: Card
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
                                Text("Card.title")
                                    .bold()
                            }, value: {
                                MultilingualText(source: information.description)
                            })
                            Divider()
                        }
                        
                        // MARK: Character
                        Group {
                            ListItemView(title: {
                                Text("Card.character")
                                    .bold()
                            }, value: {
                                // FIXME: This requires `ExtendedCard` to be
                                // FIXME: implemented in DoriKit.
                            })
                            Divider()
                        }
                        
                        // MARK: Band
                        Group {
                            ListItemView(title: {
                                Text("Card.band")
                                    .bold()
                            }, value: {
                                // FIXME: This requires `ExtendedCard` to be
                                // FIXME: implemented in DoriKit.
                            })
                            Divider()
                        }
                        
                        // MARK: Release Date
                        Group {
                            ListItemView(title: {
                                Text("Card.release-date")
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
                                    Text("Card.how-to-get")
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
*/
