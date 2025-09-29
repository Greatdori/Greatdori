//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailView.swift
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


// MARK: EventDetailView
struct EventDetailView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var id: Int
    var allEvents: [PreviewEvent]? = nil
    @State var eventID: Int = 0
    @State var informationLoadPromise: DoriCache.Promise<DoriFrontend.Event.ExtendedEvent?>?
    @State var information: DoriFrontend.Event.ExtendedEvent?
    @State var infoIsAvailable = true
    @State var cardNavigationDestinationID: Int?
    //    @State var latestEventID: Int = 0
    @State var showSubtitle: Bool = false
    @State var allEventIDs: [Int] = []
    
    @State var arts: [InfoArtsTab] = []
    var body: some View {
        EmptyContainer {
            if let information {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            EventDetailOverviewView(information: information, cardNavigationDestinationID: $cardNavigationDestinationID)
                            
                            DetailSectionsSpacer()
                            DetailsGachasSection(gachas: information.gacha, applyLocaleFilter: false)
                            //                            DetailsCardsSection(cards: information.cards, applyLocaleFilter: true)
                            
                            //                            DetailsEventsSection(events: information.event, applyLocaleFilter: true)
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
                            await getInformation(id: eventID)
                        }
                    }, label: {
                        ExtendedConstraints {
                            ContentUnavailableView("Event.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
                        }
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(item: $cardNavigationDestinationID, destination: { id in
            Text("\(id)")
        })
        .navigationTitle(Text(information?.event.eventName.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Event") : "")"))
#if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.event.eventName.forPreferredLocale() != nil ? "#\(eventID)" : "")
            } else {
                content
            }
        }
#endif
        .onChange(of: eventID, {
            Task {
                await getInformation(id: eventID)
            }
        })
        .task {
            eventID = id
            await getInformation(id: eventID)
            if (allEvents ?? []).isEmpty {
                allEventIDs = await (Event.all() ?? []).sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending)).map {$0.id}
            } else {
                allEventIDs = allEvents!.map {$0.id}
                //                print(allEventIDs)
            }
        }
        .toolbar {
            ToolbarItemGroup(content: {
                DetailsIDSwitcher(currentID: $eventID, allIDs: allEventIDs, destination: { EventSearchView() })
                    .onChange(of: eventID) {
                        information = nil
                    }
                    .onAppear {
                        showSubtitle = (sizeClass == .compact)
                    }
            })
        }
        .withSystemBackground()
    }
    
    func getInformation(id: Int) async {
        infoIsAvailable = true
        informationLoadPromise?.cancel()
        informationLoadPromise = DoriCache.withCache(id: "EventDetail_\(id)", trait: .realTime) {
            await DoriFrontend.Event.extendedInformation(of: id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
                
                arts = []
                var artsBanners: [InfoArtsItem] = []
                for locale in DoriLocale.allCases {
                    if let url = information.event.bannerImageURL(in: locale, allowsFallback: false) {
                        Task {
                            if await DoriURLValidator.reachability(of: url) {
                                artsBanners.append(InfoArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url))
                            }
                        }
                    }
                    
                }
//                arts.append(InfoArtsTab(tabName: "Song.art.cover", content: artsCover))
                
                
                
            } else {
                infoIsAvailable = false
            }
        }
    }
}


// MARK: EventDetailOverviewView
struct EventDetailOverviewView: View {
    let information: DoriFrontend.Event.ExtendedEvent
    @State var eventCharacterPercentageDict: [Int: [DoriAPI.Event.EventCharacter]] = [:]
    @State var eventCharacterNameDict: [Int: DoriAPI.LocalizedData<String>] = [:]
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
        Group {
            VStack {
                Group {
                    //MARK: Title Image
                    Group {
                        Rectangle()
                            .opacity(0)
                            .frame(height: 2)
                        WebImage(url: information.event.bannerImageURL) { image in
                            image
                                .antialiased(true)
                                .resizable()
                                .aspectRatio(3.0, contentMode: .fit)
                                .frame(maxWidth: bannerWidth, maxHeight: bannerWidth/3)
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
                    
                    //MARK: Info
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            //MARK: Title
                            Group {
                                ListItemView(title: {
                                    Text("Event.title")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.event.eventName)
                                })
                                Divider()
                            }
                            
                            //MARK: Type
                            Group {
                                ListItemView(title: {
                                    Text("Event.type")
                                        .bold()
                                }, value: {
                                    Text(information.event.eventType.localizedString)
                                })
                                Divider()
                            }
                            
                            //MARK: Countdown
                            Group {
                                ListItemView(title: {
                                    Text("Event.countdown")
                                        .bold()
                                }, value: {
                                    MultilingualTextForCountdown(information.event)
                                })
                                Divider()
                            }
                            
                            //MARK: Start Date
                            Group {
                                ListItemView(title: {
                                    Text("Event.start-date")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.event.startAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                                })
                                Divider()
                            }
                            
                            //MARK: End Date
                            Group {
                                ListItemView(title: {
                                    Text("Event.end-date")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.event.endAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                                })
                                Divider()
                            }
                            
                            //MARK: Attribute
                            Group {
                                ListItemView(title: {
                                    Text("Event.attribute")
                                        .bold()
                                }, value: {
                                    ForEach(information.event.attributes, id: \.attribute.rawValue) { attribute in
                                        VStack(alignment: .trailing) {
                                            HStack {
                                                WebImage(url: attribute.attribute.iconImageURL)
                                                    .antialiased(true)
                                                    .resizable()
                                                    .frame(width: imageButtonSize, height: imageButtonSize)
                                                Text(verbatim: "+\(attribute.percent)%")
                                            }
                                        }
                                    }
                                })
                                Divider()
                            }
                            
                            //MARK: Character
                            Group {
                                if let firstKey = eventCharacterPercentageDict.keys.first, let valueArray = eventCharacterPercentageDict[firstKey], eventCharacterPercentageDict.keys.count == 1 {
                                    ListItemWithWrappingView(title: {
                                        Text("Event.character")
                                            .bold()
                                            .fixedSize(horizontal: true, vertical: true)
                                    }, element: { value in
#if os(macOS)
                                        if let value = value {
                                            NavigationLink(destination: {
                                                CharacterDetailView(id: value.characterID)
                                            }, label: {
                                                WebImage(url: value.iconImageURL)
                                                    .antialiased(true)
                                                    .resizable()
                                                    .frame(width: imageButtonSize, height: imageButtonSize)
                                            })
                                            .buttonStyle(.plain)
                                        } else {
                                            Rectangle()
                                                .opacity(0)
                                                .frame(width: 0, height: 0)
                                        }
#else
                                        if let value = value {
                                            Menu(content: {
                                                NavigationLink(destination: {
                                                    CharacterDetailView(id: value.characterID)
                                                }, label: {
                                                    HStack {
                                                        WebImage(url: value.iconImageURL)
                                                            .antialiased(true)
                                                            .resizable()
                                                            .frame(width: imageButtonSize, height: imageButtonSize)
                                                        //                                                Text(char.name)
                                                        if let name = eventCharacterNameDict[value.characterID]?.forPreferredLocale() {
                                                            Text(name)
                                                        } else {
                                                            Text(verbatim: "Lorum Ipsum")
                                                                .foregroundStyle(Color(UIColor.placeholderText))
                                                                .redacted(reason: .placeholder)
                                                        }
                                                        //                                                        Spacer()
                                                    }
                                                })
                                            }, label: {
                                                WebImage(url: value.iconImageURL)
                                                    .antialiased(true)
                                                    .resizable()
                                                    .frame(width: imageButtonSize, height: imageButtonSize)
                                            })
                                        } else {
                                            Rectangle()
                                                .opacity(0)
                                                .frame(width: 0, height: 0)
                                        }
#endif
                                    }, caption: {
                                        Text("+\(firstKey)%")
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: true)
                                    }, contentArray: valueArray, columnNumbers: 5, elementWidth: imageButtonSize)
                                } else {
                                    // Fallback to legacy render mode
                                    ListItemView(title: {
                                        Text("Event.character")
                                            .bold()
                                            .fixedSize(horizontal: true, vertical: true)
                                        //                                Text("*")
                                    }, value: {
                                        VStack(alignment: .trailing) {
                                            let keys = eventCharacterPercentageDict.keys.sorted()
                                            ForEach(keys, id: \.self) { percentage in
                                                HStack {
                                                    //                                                    Spacer()
                                                    ForEach(eventCharacterPercentageDict[percentage]!, id: \.self) { char in
#if os(macOS)
                                                        NavigationLink(destination: {
                                                            CharacterDetailView(id: char.characterID)
                                                        }, label: {
                                                            WebImage(url: char.iconImageURL)
                                                                .antialiased(true)
                                                                .resizable()
                                                                .frame(width: imageButtonSize, height: imageButtonSize)
                                                        })
                                                        .buttonStyle(.plain)
#else
                                                        Menu(content: {
                                                            NavigationLink(destination: {
                                                                CharacterDetailView(id: char.characterID)
                                                            }, label: {
                                                                HStack {
                                                                    WebImage(url: char.iconImageURL)
                                                                        .antialiased(true)
                                                                        .resizable()
                                                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                                                    //                                                Text(char.name)
                                                                    Text(eventCharacterNameDict[char.characterID]?.forPreferredLocale() ?? "Unknown")
                                                                    //                                                                    Spacer()
                                                                }
                                                            })
                                                        }, label: {
                                                            WebImage(url: char.iconImageURL)
                                                                .antialiased(true)
                                                                .resizable()
                                                                .frame(width: imageButtonSize, height: imageButtonSize)
                                                        })
#endif
                                                    }
                                                    Text("+\(percentage)%")
                                                        .fixedSize(horizontal: true, vertical: true)
                                                }
                                            }
                                        }
                                    })
                                }
                                Divider()
                            }
                            
                            //MARK: Parameter
                            if let paramters = information.event.eventCharacterParameterBonus, paramters.total > 0 {
                                ListItemView(title: {
                                    Text("Event.parameter")
                                        .bold()
                                }, value: {
                                    VStack(alignment: .trailing) {
                                        if paramters.performance > 0 {
                                            HStack {
                                                Text("Event.parameter.performance")
                                                Text("+\(paramters.performance)%")
                                            }
                                        }
                                        if paramters.technique > 0 {
                                            HStack {
                                                Text("Event.parameter.technique")
                                                Text("+\(paramters.technique)%")
                                            }
                                        }
                                        if paramters.visual > 0 {
                                            HStack {
                                                Text("Event.parameter.visual")
                                                Text("+\(paramters.visual)%")
                                            }
                                        }
                                    }
                                })
                                Divider()
                            }
                            
                            //MARK: Card
                            if !cardsArray.isEmpty {
                                ListItemWithWrappingView(title: {
                                    Text("Event.card")
                                        .bold()
                                }, element: { value in
                                    NavigationLink(destination: {
                                        CardDetailView(id: value!.id)
                                    }, label: {
                                        CardPreviewImage(value!, sideLength: cardThumbnailSideLength, showNavigationHints: true)
                                    })
                                    .buttonStyle(.plain)
                                }, caption: {
                                    Text("+\(cardsPercentage)%")
                                        .lineLimit(1, reservesSpace: true)
                                        .fixedSize(horizontal: true, vertical: true)
                                }, contentArray: cardsArray, columnNumbers: 3, elementWidth: cardThumbnailSideLength)
                                Divider()
                            }
                            
                            //MARK: Rewards
                            if !rewardsArray.isEmpty {
                                ListItemView(title: {
                                    Text("Event.rewards")
                                        .bold()
                                }, value: {
                                    ForEach(rewardsArray) { card in
                                        NavigationLink(destination: {
                                            CardDetailView(id: card.id)
                                        }, label: {
                                            CardPreviewImage(card, sideLength: cardThumbnailSideLength, showNavigationHints: true/*, cardNavigationDestinationID: $cardNavigationDestinationID*/)
                                        })
                                        .contentShape(Rectangle())
                                        .buttonStyle(.plain)
                                        
                                    }
                                })
                                Divider()
                            }
                            
                            
                            //MARK: ID
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
        }
        .frame(maxWidth: 600)
        .onAppear {
            eventCharacterPercentageDict = [:]
            rewardsArray = []
            cardsArray = []
            let eventCharacters = information.event.characters
            for char in eventCharacters {
                eventCharacterPercentageDict.updateValue(((eventCharacterPercentageDict[char.percent] ?? []) + [char]), forKey: char.percent)
                Task {
                    if let allCharacters = await DoriAPI.Character.all() {
                        if let character = allCharacters.first(where: { $0.id == char.characterID }) {
                            eventCharacterNameDict.updateValue(character.characterName, forKey: char.characterID)
                        }
                    }
                    
                }
            }
            for card in information.cards {
                if information.event.rewardCards.contains(card.id) {
                    rewardsArray.append(card)
                } else {
                    cardsArray.append(card)
                    if cardsPercentage == -100 {
                        cardsPercentage = information.event.members.first(where: { $0.situationID == card.id })?.percent ?? -200
                    }
                }
            }
            cardsArraySeperated = cardsArray.chunked(into: 3)
            for i in 0..<cardsArraySeperated.count {
                while cardsArraySeperated[i].count < 3 {
                    cardsArraySeperated[i].insert(nil, at: 0)
                }
            }
        }
    }
}
