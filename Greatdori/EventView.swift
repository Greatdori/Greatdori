//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventView.swift
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

//MARK: EventDetailView
struct EventDetailView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var id: Int
    @State var eventID: Int = 0
    @State var informationLoadPromise: DoriCache.Promise<DoriFrontend.Event.ExtendedEvent?>?
    @State var information: DoriFrontend.Event.ExtendedEvent?
    @State var infoIsAvailable = true
    @State var cardNavigationDestinationID: Int?
    @State var latestEventID: Int = 0
    @State var showSubtitle: Bool = false
    var body: some View {
        Group {
            if let information {
                ScrollView {
                    HStack {
                        Spacer()
                        VStack {
                            EventDetailOverviewView(information: information, cardNavigationDestinationID: $cardNavigationDestinationID)
                        }
                        .padding()
                        Spacer()
                    }
                }
            } else {
                if infoIsAvailable {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    ContentUnavailableView("Event.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Event.unavailable.description"))
                }
            }
        }
        .navigationDestination(item: $cardNavigationDestinationID, destination: { id in
            Text("\(id)")
        })
        .navigationTitle(Text(information?.event.eventName.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Event") : "")"))
#if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, *) {
                if showSubtitle {
                    content
                        .navigationSubtitle(information?.event.eventName.forPreferredLocale() != nil ? "#\(eventID)" : "")
                }
            } else {
                content
            }
        }
#endif
        .onAppear {
            Task {
                latestEventID = await DoriFrontend.Event.localizedLatestEvent()?.jp?.id ?? 0
            }
        }
        .onChange(of: eventID, {
            Task {
                await getInformation(id: eventID)
            }
        })
        .task {
            eventID = id
            await getInformation(id: eventID)
        }
        .onTapGesture {
            if !infoIsAvailable {
                Task {
                    await getInformation(id: eventID)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(content: {
                if sizeClass == .regular {
                    HStack(spacing: 0) {
                        Button(action: {
                            if eventID > 1 {
                                information = nil
                                eventID -= 1
                            }
                        }, label: {
                            Label("Event.previous", systemImage: "arrow.backward")
                        })
                        .disabled(eventID <= 1)
                        NavigationLink(destination: {
                            EventSearchView()
                        }, label: {
                            Text("#\(eventID)")
                                .fontDesign(.monospaced)
                                .bold()
                        })
                        Button(action: {
                            if eventID < latestEventID {
                                information = nil
                                eventID += 1
                            }
                        }, label: {
                            Label("Event.next", systemImage: "arrow.forward")
                        })
                        .disabled(latestEventID <= eventID)
                    }
                    .disabled(latestEventID == 0 || eventID == 0)
                    .onAppear {
                        showSubtitle = false
                    }
                } else {
                    NavigationLink(destination: {
                        EventSearchView()
                    }, label: {
                        Image(systemName: "list.bullet")
                    })
                    .onAppear {
                        showSubtitle = true
                    }
                }
            })
        }
    }
    
    func getInformation(id: Int) async {
        infoIsAvailable = true
        informationLoadPromise?.cancel()
        informationLoadPromise = DoriCache.withCache(id: "EventDetail_\(id)", trait: .realTime) {
            await DoriFrontend.Event.extendedInformation(of: id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
            } else {
                infoIsAvailable = false
            }
        }
    }
}


//MARK: EventDetailOverviewView
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
        NavigationStack {
            Group {
                //MARK: Title Image
                Group {
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                    WebImage(url: information.event.bannerImageURL)
                        .resizable()
                        .aspectRatio(3.0, contentMode: .fit)
                        .frame(maxWidth: 420, maxHeight: 140)
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                }
                
                //MARK: Info
                Group {
                    //MARK: Title
                    Group {
                        ListItemView(title: {
                            Text("Event.title")
                                .bold()
                        }, value: {
                            MultilingualText(source: information.event.eventName)
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
                            MultilingualTextForCountdown(source: information.event)
                        })
                        Divider()
                    }
                    
                    //MARK: Start Date
                    Group {
                        ListItemView(title: {
                            Text("Event.start-date")
                                .bold()
                        }, value: {
                            MultilingualText(source: information.event.startAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                        })
                        Divider()
                    }
                    
                    //MARK: End Date
                    Group {
                        ListItemView(title: {
                            Text("Event.end-date")
                                .bold()
                        }, value: {
                            MultilingualText(source: information.event.endAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
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
                                        //TODO: [NAVI785]CharD
                                    }, label: {
                                        WebImage(url: value.iconImageURL)
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
                                            //TODO: [NAVI785]CharD
                                        }, label: {
                                            HStack {
                                                WebImage(url: value.iconImageURL)
                                                    .resizable()
                                                    .frame(width: imageButtonSize, height: imageButtonSize)
                                                //                                                Text(char.name)
                                                if let name = eventCharacterNameDict[value.characterID]?.forPreferredLocale() {
                                                    Text(name)
                                                } else {
                                                    Text(verbatim: "Lorum Ipsum")
                                                        .redacted(reason: .placeholder)
                                                }
                                                Spacer()
                                            }
                                        })
                                    }, label: {
                                        WebImage(url: value.iconImageURL)
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
                                            Spacer()
                                            ForEach(eventCharacterPercentageDict[percentage]!, id: \.self) { char in
#if os(macOS)
                                                NavigationLink(destination: {
                                                    //TODO: [NAVI785]CharD
                                                }, label: {
                                                    WebImage(url: char.iconImageURL)
                                                        .resizable()
                                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                                })
                                                .buttonStyle(.plain)
#else
                                                Menu(content: {
                                                    NavigationLink(destination: {
                                                        //TODO: [NAVI785]CharD
                                                    }, label: {
                                                        HStack {
                                                            WebImage(url: char.iconImageURL)
                                                                .resizable()
                                                                .frame(width: imageButtonSize, height: imageButtonSize)
                                                            //                                                Text(char.name)
                                                            Text(eventCharacterNameDict[char.characterID]?.forPreferredLocale() ?? "Unknown")
                                                            Spacer()
                                                        }
                                                    })
                                                }, label: {
                                                    WebImage(url: char.iconImageURL)
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
                                //TODO: [NAVI785]CardD
                                Text("\(value)")
                            }, label: {
                                CardIconView(value!, sideLength: cardThumbnailSideLength, showNavigationHints: true, cardNavigationDestinationID: $cardNavigationDestinationID)
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
                                    
                                }, label: {
                                    CardIconView(card, sideLength: cardThumbnailSideLength, showNavigationHints: true, cardNavigationDestinationID: $cardNavigationDestinationID)
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
                            Text("Event.id")
                                .bold()
                        }, value: {
                            Text("\(information.id)")
                        })
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





//MARK: EventSearchView
struct EventSearchView: View {
    let bannerWidth: CGFloat = isMACOS ? 370 : 420
    let bannerSpacing: CGFloat = isMACOS ? 10 : 15
    @State var filter = DoriFrontend.Filter()
    @State var events: [DoriFrontend.Event.PreviewEvent]?
    @State var searchedEvents: [DoriFrontend.Event.PreviewEvent]?
    @State var searchedEventsChunked: [[DoriFrontend.Event.PreviewEvent]]?
    @State var infoIsAvailable = true
    @State var searchedText = ""
    @State var showDetails = false
    var body: some View {
        Group {
            if let resultEvents = searchedEvents ?? events {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        ViewThatFits {
                            LazyVStack(spacing: showDetails ? nil : bannerSpacing) {
                                let events = resultEvents.chunked(into: 2)
                                ForEach(events, id: \.self) { eventGroup in
                                    HStack(spacing: showDetails ? nil : bannerSpacing) {
                                        ForEach(eventGroup) { event in
                                            NavigationLink(destination: {
                                                EventDetailView(id: event.id)
                                            }, label: {
                                                EventCardView(event, inLocale: nil, showDetails: showDetails, searchedKeyword: $searchedText)
                                            })
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .border(Color.red)
                            .frame(maxWidth: bannerWidth * 2 + bannerSpacing)
                            //                        .border(.red)
                            LazyVStack(spacing: showDetails ? nil : bannerSpacing) {
                                ForEach(resultEvents, id: \.self) { event in
                                    NavigationLink(destination: {
                                        EventDetailView(id: event.id)
                                    }, label: {
                                        EventCardView(event, inLocale: nil, showDetails: showDetails, searchedKeyword: $searchedText)
                                        //                                        .padding(.all, showDetails ? 0 : nil)
                                            .frame(maxWidth: bannerWidth)
                                    })
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(maxWidth: bannerWidth)
//                            .border(.yellow)
                        }
                        .padding(.horizontal)
                        //                    .animation(.spring(duration: 0.3, bounce: 0.35, blendDuration: 0), value: showDetails)
                        .animation(.easeOut(duration: 0.2), value: showDetails)
                        Spacer(minLength: 0)
                    }
                }
                .searchable(text: $searchedText, prompt: "Event.search.placeholder")
                .onChange(of: searchedText, {
                    if let events {
                        searchedEvents = events.search(for: searchedText)
                    }
                })
//                .onChange(of: searchedEvents, {
//                    searchedEventsChunked = searchedEvents.chunked(into: 2)
//                })
            } else {
                if infoIsAvailable {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    ContentUnavailableView("Event.search.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Event.unavailable.description"))
                }
            }
        }
        .background(groupedContentBackgroundColor())
        .navigationTitle("Event")
        .task {
            await getEvents()
            searchedEvents = events
//            if let events {
                searchedEventsChunked = events?.chunked(into: 2)
//            }
        }
        .toolbar {
            ToolbarItem {
                Toggle(isOn: $showDetails, label: {
                    Image(systemName: "info.circle")
                })
            }
        }
        .onChange(of: searchedEvents, {
            if let searchedEvents {
                searchedEventsChunked = searchedEvents.chunked(into: 2)
            }
        })
    }
    
    func getEvents() async {
        infoIsAvailable = true
        DoriCache.withCache(id: "EventList_\(filter.identity)") {
            await DoriFrontend.Event.list(filter: filter)
        }.onUpdate {
            if let events = $0 {
                self.events = events
//                self.events = firstXElements(events, x: 10)
            } else {
                infoIsAvailable = false
            }
        }
    }
    
}




/*
 .sheet(isPresented: $isFilterSettingsPresented) {
 Task {
 events = nil
 await getEvents()
 }
 } content: {
 FilterView(filter: $filter, includingKeys: [
 .attribute,
 .character,
 .server,
 .timelineStatus,
 .eventType,
 .sort
 ]) {
 if let events {
 SearchView(items: events, text: $searchInput) { result in
 searchedEvents = result
 }
 }
 }
 }
 */

