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
    let galleryLayoutItemMinimumWidth: CGFloat = 400
    let galleryLayoutItemMaximumWidth: CGFloat = 500
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
                                            LazyVGrid(columns: [GridItem(.adaptive(minimum: layoutType == 2 ? gridLayoutItemWidth : galleryLayoutItemMinimumWidth, maximum: layoutType == 2 ? gridLayoutItemWidth : galleryLayoutItemMaximumWidth))]) {
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
                searchedCards = cards.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
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
    @State var informationLoadPromise: CachePromise<ExtendedCard?>?
    @State var information: ExtendedCard?
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
                            CardDetailOverviewView(information: information, cardNavigationDestinationID: $cardNavigationDestinationID)
                            
                            DetailSectionsSpacer()
                            CardDetailStatsView(card: information.card)
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
        .navigationTitle(Text(information?.card.prefix.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Card") : "")"))
#if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.card.prefix.forPreferredLocale() != nil ? "#\(cardID)" : "")
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
            await ExtendedCard(id: id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
            } else {
                infoIsAvailable = false
            }
        }
    }
}


// MARK: CardDetailOverviewView
struct CardDetailOverviewView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let information: ExtendedCard
    @Binding var cardNavigationDestinationID: Int?
    @State private var allSkills: [Skill] = []
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    
    let cardCoverScalingFactor: CGFloat = 1
    var body: some View {
        VStack {
            Group {
                // MARK: Title Image
                Group {
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                    CardCoverImage(information.card, band: information.band)
                        .wrapIf(sizeClass == .regular) { content in
                            content
                                .frame(maxWidth: 480*cardCoverScalingFactor, maxHeight: 320*cardCoverScalingFactor)
                        } else: { content in
                            content
//                                .padding(.horizontal, -15)
                        }
//                    .interpolation(.high)
//                    .frame(width: 96, height: 96)
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
                                Text("Card.title")
                                    .bold()
                            }, value: {
                                MultilingualText(source: information.card.prefix)
                            })
                            Divider()
                        }
                        
                        // MARK: Type
                        Group {
                            ListItemView(title: {
                                Text("Card.type")
                                    .bold()
                            }, value: {
                                Text(information.card.type.localizedString)
                            })
                            Divider()
                        }
                        
                        // MARK: Type
                        Group {
                            ListItemView(title: {
                                Text("Card.character")
                                    .bold()
                            }, value: {
                                NavigationLink(destination: {
                                    CharacterDetailView(id: information.character.id)
                                }, label: {
                                    HStack {
                                        MultilingualText(source: information.character.characterName)
                                        WebImage(url: information.character.iconImageURL)
                                            .resizable()
                                            .clipShape(Circle())
                                            .frame(width: imageButtonSize, height: imageButtonSize)
                                    }
                                })
                                .buttonStyle(.plain)
                            })
                            Divider()
                        }
                        
                        // MARK: Band
                        Group {
                            ListItemView(title: {
                                Text("Card.band")
                                    .bold()
                            }, value: {
                                HStack {
                                    MultilingualText(source: information.band.bandName, allowPopover: false)
                                    WebImage(url: information.band.iconImageURL)
                                        .resizable()
                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                }
                            })
                            Divider()
                        }
                        
                        // MARK: Attribute
                        Group {
                            ListItemView(title: {
                                Text("Card.attribute")
                                    .bold()
                            }, value: {
                                HStack {
                                    Text(information.card.attribute.selectorText.uppercased())
                                    WebImage(url: information.card.attribute.iconImageURL)
                                        .resizable()
                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                }
                            })
                            Divider()
                        }
                        
                        // MARK: Rarity
                        Group {
                            ListItemView(title: {
                                Text("Card.rarity")
                                    .bold()
                            }, value: {
                                HStack(spacing: 0) {
                                    ForEach(1...information.card.rarity, id: \.self) { _ in
                                        Image(information.card.rarity >= 4 ? .trainedStar : .star)
                                            .resizable()
                                            .frame(width: imageButtonSize, height: imageButtonSize)
                                            .padding(.top, -1)
                                    }
                                }
                            })
                            Divider()
                        }
                        
                        // MARK: Skill
                        if let skill = allSkills.first(where: { $0.id == information.card.skillID }) {
                            Group {
                                ListItemView(title: {
                                    Text("Card.skill")
                                        .bold()
                                }, value: {
//                                    Text(skill.maximumDescription)
                                    MultilingualText(source: skill.maximumDescription)
                                }, displayMode: .basedOnUISizeClass)
                                Divider()
                            }
                        }
                        
                        
                        // MARK: Gacha Quote
                        if !information.card.gachaText.isValueEmpty {
                            Group {
                                ListItemView(title: {
                                    Text("Card.gacha-quote")
                                        .bold()
                                }, value: {
                                    MultilingualText(source: information.card.gachaText)
                                }, displayMode: .basedOnUISizeClass)
                                Divider()
                            }
                        }
                        
                        // MARK: Release Date
                        Group {
                            ListItemView(title: {
                                Text("Card.release-date")
                                    .bold()
                            }, value: {
                                MultilingualText(source: information.card.releasedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
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
                    }
                }
            }
        }
        .frame(maxWidth: 600)
        .task {
            // Load skills asynchronously once when the view appears
            if allSkills.isEmpty {
                if let fetched = await Skill.all() {
                    allSkills = fetched
                }
            }
        }
    }
}


// MARK: CardDetailStatsView
struct CardDetailStatsView: View {
    var card: Card
    @State var tab: Int = 0
    @State var level: Float = 1
    @State var masterRank: Float = 4
    @State var episodes: Float = 2
    @State var trained: Bool = false
    @State var stat: DoriAPI.Card.Stat = .zero
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                CustomGroupBox {
                    VStack {
                        if tab != 3 {
                            Group {
                                ListItemView(title: {
                                    Text("Card.stats.level")
                                        .bold()
                                }, value: {
                                    Text(tab == 0 ? "\(card.stat.minimumLevel ?? 1)" : tab == 1 ? "\(card.stat.maximumLevel ?? 60)" : ("\(Int(level))"))
//                                        .fontDesign(.monospaced)
                                    if tab == 2 {
                                        Stepper("", value: $level, in: Float(card.stat.minimumLevel ?? 1)...Float(card.stat.maximumLevel ?? 60), step: 1)
                                            .labelsHidden()
                                    }
                                })
                                if tab == 2 {
                                    Slider(value: $level, in: Float(card.stat.minimumLevel ?? 1)...Float(card.stat.maximumLevel ?? 60), step: 1, label: {
                                        Text("")
                                    })
                                    .labelsHidden()
                                }
                                Divider()
                            }
                            
                            if tab == 2 {
                                Group {
                                    ListItemView(title: {
                                        Text("Card.stats.master-rank")
                                            .bold()
                                    }, value: {
                                        Text("\(Int(masterRank))")
                                        Stepper("", value: $masterRank, in: 0...4, step: 1)
                                            .labelsHidden()
                                    })
                                    Divider()
                                }
                                
                                if !card.episodes.isEmpty {
                                    Group {
                                        ListItemView(title: {
                                            Text("Card.stats.episode")
                                                .bold()
                                        }, value: {
                                            Text("\(Int(episodes))")
                                            Stepper("", value: $episodes, in: 0...Float(card.episodes.count), step: 1)
                                                .labelsHidden()
                                        })
                                        Divider()
                                    }
                                }
                                
                                Group {
                                    ListItemView(title: {
                                        Text("Card.stats.trained")
                                    }, value: {
                                        Toggle(isOn: $trained, label: {
                                            
                                        })
                                    })
                                }
                            }
                            
                            Group {
                                ListItemView(title: {
                                    Text("Card.stats.performance")
                                        .bold()
                                }, value: {
                                    Text("\(stat.performance)")
//                                        .fontDesign(.monospaced)
                                        .contentTransition(.numericText())
                                        .animation(.default, value: stat)
                                })
                                Divider()
                            }
                            
                            Group {
                                ListItemView(title: {
                                    Text("Card.stats.technique")
                                        .bold()
                                }, value: {
                                    Text("\(stat.technique)")
//                                        .fontDesign(.monospaced)
                                        .contentTransition(.numericText())
                                        .animation(.default, value: stat)
                                })
                                Divider()
                            }
                            
                            Group {
                                ListItemView(title: {
                                    Text("Card.stats.visual")
                                        .bold()
                                }, value: {
                                    Text("\(stat.visual)")
//                                        .fontDesign(.monospaced)
                                        .contentTransition(.numericText())
                                        .animation(.default, value: stat)
                                })
                                Divider()
                            }
                            
                            Group {
                                ListItemView(title: {
                                    Text("Card.stats.total")
                                        .bold()
                                }, value: {
                                    Text("\(stat.total)")
//                                        .fontDesign(.monospaced)
                                        .contentTransition(.numericText())
                                        .animation(.default, value: stat)
                                })
                            }
                        }
                    }
                }
                .frame(maxWidth: 600)
                .onAppear {
                    level = Float(card.stat.maximumLevel ?? 60)
                    episodes = Float(card.episodes.count)
                    updateStatsData()
                }
                .onChange(of: tab) {
                    updateStatsData()
                }
                .onChange(of: level) {
                    updateStatsData()
                }
                .onChange(of: episodes) {
                    updateStatsData()
                }
                .onChange(of: masterRank) {
                    updateStatsData()
                }
                .onChange(of: trained) {
                    updateStatsData()
                }
            }, header: {
                HStack {
                    Text("Card.stats")
                        .font(.title2)
                        .bold()
                    DetailSectionOptionPicker(selection: $tab, options: [0, 1, 2, 3], labels: [0: "Card.stats.min", 1: "Card.stats.max", 2: "Card.stats.custom", 3: "Card.stats.skill"])
                    Spacer()
                }
                .frame(maxWidth: 615)
            })
        }
    }
    
    func updateStatsData() {
        stat = switch tab {
        case 0: card.stat.forMinimumLevel() ?? .zero
        case 1: card.stat.maximumValue(rarity: card.rarity) ?? .zero
        default: card.stat.calculated(
            level: Int(level),
            rarity: card.rarity,
            masterRank: Int(masterRank),
            viewedStoryCount: Int(episodes),
            trained: trained
        ) ?? .zero
        }
    }
}
