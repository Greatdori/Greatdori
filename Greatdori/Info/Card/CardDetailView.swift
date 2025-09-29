//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardDetailView.swift
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
                            
                            DetailSectionsSpacer()
                            DetailsCostumesSection(costumes: [information.costume])
                            
                            if !information.event.isEmpty || information.cardSource.containsSource(from: .event) {
                                DetailSectionsSpacer()
                                DetailsEventsSection(event: information.event, sources: information.cardSource)
                            }
                            
                            if information.cardSource.containsSource(from: .gacha) {
                                DetailSectionsSpacer()
                                DetailsGachasSection(sources: information.cardSource)
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
                                MultilingualText(information.card.prefix)
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
                                        MultilingualText(information.character.characterName)
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
                                    MultilingualText(information.band.bandName, allowPopover: false)
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
                                        Image(information.card.rarity >= 3 ? .trainedStar : .star)
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
                                    MultilingualText(skill.maximumDescription)
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
                                    MultilingualText(information.card.gachaText)
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
                                MultilingualText(information.card.releasedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
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
