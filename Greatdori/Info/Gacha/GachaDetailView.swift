//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaDetailView.swift
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


// MARK: GachaDetailView
struct GachaDetailView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var id: Int
    var allGachas: [PreviewGacha]? = nil
    @State var gachaID: Int = 0
    @State var informationLoadPromise: DoriCache.Promise<DoriFrontend.Gacha.ExtendedGacha?>?
    @State var information: DoriFrontend.Gacha.ExtendedGacha?
    @State var infoIsAvailable = true
    @State var cardNavigationDestinationID: Int?
    //    @State var latestGachaID: Int = 0
    @State var allGachaIDs: [Int] = []
    @State var showSubtitle: Bool = false
    var body: some View {
        EmptyContainer {
            if let information {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            GachaDetailOverviewView(information: information, cardNavigationDestinationID: $cardNavigationDestinationID)
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
                            await getInformation(id: gachaID)
                        }
                    }, label: {
                        ExtendedConstraints {
                            ContentUnavailableView("Gacha.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
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
        .navigationTitle(Text(information?.gacha.gachaName.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Gacha") : "")"))
#if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.gacha.gachaName.forPreferredLocale() != nil ? "#\(gachaID)" : "")
            } else {
                content
            }
        }
#endif
        .onAppear {
            Task {
                if (allGachas ?? []).isEmpty {
                    allGachaIDs = await (Event.all() ?? []).sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending)).map {$0.id}
                } else {
                    allGachaIDs = allGachas!.map {$0.id}
                    //                print(allEventIDs)
                }
            }
        }
        .onChange(of: gachaID, {
            Task {
                await getInformation(id: gachaID)
            }
        })
        .task {
            gachaID = id
            await getInformation(id: gachaID)
        }
        .toolbar {
            ToolbarItemGroup(content: {
                DetailsIDSwitcher(currentID: $gachaID, allIDs: allGachaIDs, destination: { GachaSearchView() })
                    .onChange(of: gachaID) {
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
        informationLoadPromise = DoriCache.withCache(id: "GachaDetail_\(id)", trait: .realTime) {
            await DoriFrontend.Gacha.extendedInformation(of: id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
                //                latestGachaID = information.
            } else {
                infoIsAvailable = false
            }
        }
    }
}


// MARK: GachaDetailOverviewView
struct GachaDetailOverviewView: View {
    let information: DoriFrontend.Gacha.ExtendedGacha
    //    @State var gachaCharacterPercentageDict: [Int: [DoriAPI.Gacha.GachaCharacter]] = [:]
    //    @State var gachaCharacterNameDict: [Int: DoriAPI.LocalizedData<String>] = [:]
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
                    WebImage(url: information.gacha.bannerImageURL) { image in
                        image
                            .antialiased(true)
                            .resizable()
                        //                            .aspectRatio(3.0, contentMode: .fit)
                            .scaledToFit()
                            .frame(maxWidth: bannerWidth,/* maxHeight: bannerWidth/3*/)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                        //                            .fill(Color.gray.opacity(0.15))
                            .fill(getPlaceholderColor())
                            .aspectRatio(3.0, contentMode: .fit)
                            .frame(maxWidth: bannerWidth, maxHeight: bannerWidth/3)
                    }
                    .interpolation(.high)
                    .cornerRadius(10)
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                }
                
                
                // MARK: Info
                CustomGroupBox(cornerRadius: 20) {
                    // Make this lazy fixes [250920-a] last appears in 8783d44.
                    // Seems like a bug of SwiftUI, idk why make this lazy
                    // fixes that bug. Whatever, it works.
                    LazyVStack {
                        // MARK: Title
                        Group {
                            ListItemView(title: {
                                Text("Gacha.title")
                                    .bold()
                            }, value: {
                                MultilingualText(information.gacha.gachaName)
                            })
                            Divider()
                        }
                        
                        // MARK: Type
                        Group {
                            ListItemView(title: {
                                Text("Gacha.type")
                                    .bold()
                            }, value: {
                                Text(information.gacha.type.localizedString)
                            })
                            Divider()
                        }
                        
                        // MARK: Countdown
                        Group {
                            ListItemView(title: {
                                Text("Gacha.countdown")
                                    .bold()
                            }, value: {
                                MultilingualTextForCountdown(information.gacha)
                            })
                            Divider()
                        }
                        
                        // MARK: Release Date
                        Group {
                            ListItemView(title: {
                                Text("Gacha.release-date")
                                    .bold()
                            }, value: {
                                MultilingualText(information.gacha.publishedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            })
                            Divider()
                        }
                        
                        // MARK: Close Date
                        Group {
                            ListItemView(title: {
                                Text("Gacha.close-date")
                                    .bold()
                            }, value: {
                                MultilingualText(information.gacha.closedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            })
                            Divider()
                        }
                        
                        //                        //MARK: Spotlight Card
                        //                        if !cardsArray.isEmpty {
                        //                            ListItemWithWrappingView(title: {
                        //                                Text("Event.spotlight-card")
                        //                                    .bold()
                        //                            }, element: { value in
                        //                                NavigationLink(destination: {
                        //                                    //TODO: [NAVI785]CardD
                        //                                    Text("\(value)")
                        //                                }, label: {
                        //                                    CardPreviewImage(value!, sideLength: cardThumbnailSideLength, showNavigationHints: true, cardNavigationDestinationID: $cardNavigationDestinationID)
                        //                                })
                        //                                .buttonStyle(.plain)
                        //                            }, caption: nil, contentArray: cardsArray, columnNumbers: 3, elementWidth: cardThumbnailSideLength)
                        //                            Divider()
                        //                        }
                        
                        // MARK: Description
                        Group {
                            ListItemView(title: {
                                Text("Gacha.descripition")
                                    .bold()
                            }, value: {
                                MultilingualText(information.gacha.description)
                            }, displayMode: .basedOnUISizeClass)
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
        .onAppear {
            /*
             gachaCharacterPercentageDict = [:]
             rewardsArray = []
             cardsArray = []
             let gachaCharacters = information.gacha.characters
             for char in gachaCharacters {
             gachaCharacterPercentageDict.updateValue(((gachaCharacterPercentageDict[char.percent] ?? []) + [char]), forKey: char.percent)
             Task {
             if let allCharacters = await DoriAPI.Character.all() {
             if let character = allCharacters.first(where: { $0.id == char.characterID }) {
             gachaCharacterNameDict.updateValue(character.characterName, forKey: char.characterID)
             }
             }
             
             }
             }
             for card in information.cards {
             if information.gacha.rewardCards.contains(card.id) {
             rewardsArray.append(card)
             } else {
             cardsArray.append(card)
             if cardsPercentage == -100 {
             cardsPercentage = information.gacha.members.first(where: { $0.situationID == card.id })?.percent ?? -200
             }
             }
             }
             cardsArraySeperated = cardsArray.chunked(into: 3)
             for i in 0..<cardsArraySeperated.count {
             while cardsArraySeperated[i].count < 3 {
             cardsArraySeperated[i].insert(nil, at: 0)
             }
             }
             */
        }
        
    }
}
