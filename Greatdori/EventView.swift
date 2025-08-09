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
    var id: Int
    @State var eventID: Int = 0
    @State var informationLoadPromise: DoriCache.Promise<DoriFrontend.Event.ExtendedEvent?>?
    @State var information: DoriFrontend.Event.ExtendedEvent?
    @State var infoIsAvailable = true
    @State var cardNavigationDestinationID: Int?
    @State var pageWidth: CGFloat = 400
    @State var latestEventID: Int = 0
    @State var showSubtitle: Bool = false
    var body: some View {
        NavigationStack {
            if let information {
                ScrollView {
                    HStack {
                        Spacer()
                        VStack {
                            EventDetailOverviewView(information: information, cardNavigationDestinationID: $cardNavigationDestinationID)
//                                .frame(maxWidth: .infinity)
                            //                            .ignoresSafeArea(nil)
                        }
                        .padding()
                        Spacer()
                    }
                    HStack {
                        Text("Event.gacha")
                            .font(.title3)
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
            //                                EmptyView()
            //                NavigationStack {
            Text("\(id)")
        })
        .navigationTitle(Text(information?.event.eventName.forPreferredLocale() ?? "#\(eventID)"))
//        .wrapIf(showSubtitle) { content in
//            if #available(iOS 26, *) {
////                if showSubtitle {
//                    //                if information?.event.eventName.forPreferredLocale() != nil {
//                    content
//                        .navigationSubtitle(information?.event.eventName.forPreferredLocale() != nil ? "#\(eventID)" : "")
//                    //                }
////                } else {
////                    content
////                }
//            } else {
//                content
//            }
//        }
        //        .navigationTitle(.lineLimit(nil))
        //        .toolbarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                latestEventID = await DoriFrontend.Event.localizedLatestEvent()?.jp?.id ?? 0
            }
        }
        .onChange(of: eventID, {
            Task {
                print("on change of eventID: \(eventID)")
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
                ViewThatFits(in: .horizontal) {
                    HStack {
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
                            //MARK: [NAVI785] eventList
                        }, label: {
                            Text("#\(eventID)")
                                .fontDesign(.monospaced)
                        })
                        .padding(-2)
                        Button(action: {
                            if latestEventID < eventID {
                                information = nil
                                eventID += 1
                            }
                        }, label: {
                            Label("Event.next", systemImage: "arrow.forward")
                        })
                        .disabled(latestEventID == 0 || latestEventID <= eventID)
                    }
                    .onAppear {
                        showSubtitle = false
                    }
                    NavigationLink(destination: {
                        //MARK: [NAVI785] eventList
                    }, label: {
                        Image(systemName: "list.bullet")
                    })
                    .onAppear {
                        showSubtitle = true
                    }
                }
            })
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        pageWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) {
//                        pageWidth = geometry.size.width
                    }
            }
        )
    }
    
    func getInformation(id: Int) async {
        infoIsAvailable = true
        informationLoadPromise?.cancel()
        informationLoadPromise = DoriCache.withCache(id: "EventDetail_\(id)") {
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
    @State var cardsColumnWidth: CGFloat = 0
    @State var cardsTitleWidth: CGFloat = 0
    @State var cardsContentWidth: CGFloat = 0
    @Binding var cardNavigationDestinationID: Int?
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    var body: some View {
        NavigationStack {
            Group {
                //MARK: Title Image
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
                
                Group {
                    //MARK: Title
                    ListItemView(title: {
                        Text("Event.title")
                            .bold()
                    }, value: {
                        MultilingualText(source: information.event.eventName)
                    })
                    Divider()
                    //MARK: Type
                    ListItemView(title: {
                        Text("Event.type")
                            .bold()
                    }, value: {
                        Text(information.event.eventType.localizedString)
                    })
                    Divider()
                    //MARK: Countdown
                    ListItemView(title: {
                        Text("Event.countdown")
                            .bold()
                    }, value: {
                        MultilingualTextForCountdown(source: information.event)
                    })
                    Divider()
                    //MARK: Start Date
                    ListItemView(title: {
                        Text("Event.start-date")
                            .bold()
                    }, value: {
                        MultilingualText(source: information.event.startAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                    })
                    Divider()
                    //MARK: End Date
                    ListItemView(title: {
                        Text("Event.end-date")
                            .bold()
                    }, value: {
                        MultilingualText(source: information.event.endAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                    })
                    Divider()
                    //MARK: Attribute
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
                    //MARK: Character
                    ListItemView(title: {
                        Text("Event.character")
                            .bold()
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
                                    //
                                }
                            }
                        }
                    })
                    Divider()
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
//                    if !cardsArray.isEmpty {
//                        ListItemView(title: {
//                            Text("Event.card")
//                                .bold()
//                                .background {
//                                    GeometryReader { geometry in
//                                        Color.clear
//                                            .onAppear {
//                                                cardsTitleWidth = geometry.size.width
//                                            }
//                                            .onChange(of: geometry.size.width) {
//                                                cardsTitleWidth = geometry.size.width
//                                            }
//                                    }
//                                }
//                        }, value: {
//                            HStack {
//                                if (cardsColumnWidth - cardsTitleWidth - cardsContentWidth) > 20 {
//                                    HStack {
//                                        ForEach(cardsArray) { card in
//                                            NavigationLink(destination: {
//                                                //TODO: [NAVI785]CardD
//                                            }, label: {
//                                                CardIconView(card, sideLength: cardThumbnailSideLength, showNavigationHints: true, cardNavigationDestinationID: $cardNavigationDestinationID)
//                                            })
//                                            .contentShape(Rectangle())
//                                            .buttonStyle(.plain)
//                                        }
//                                    }
//                                    //                                    .frame(width: CGFloat(cardsArray.count*72+10))
//                                } else {
//                                    Grid(alignment: .trailing) {
//                                        ForEach(0..<cardsArraySeperated.count, id: \.self) { rowIndex in
//                                            GridRow {
//                                                    ForEach(cardsArraySeperated[rowIndex], id: \.id) { item in
//                                                        if item != nil {
//                                                            NavigationLink(destination: {
//                                                                //TODO: [NAVI785]CardD
//                                                            }, label: {
//                                                                CardIconView(item!, sideLength: cardThumbnailSideLength, showNavigationHints: true, cardNavigationDestinationID: $cardNavigationDestinationID)
//                                                                //                                                        Text("1")
//                                                            })
//                                                            .buttonStyle(.plain)
//                                                        } else {
////                                                            CardIconView
////                                                            EmptyView()
//                                                            Rectangle()
//                                                                .opacity(0)
//                                                        }
//                                                    }
//                                            }
////                                            .frame(width: 72*3+10)
//                                            
//                                        }
//                                        //                                        Text("1")
//                                    }
//                                    .gridCellAnchor(.trailing)
//                                }
//                                Text("+\(cardsPercentage)%")
//                                    .lineLimit(1, reservesSpace: true)
//                            }
//                            .background {
//                                GeometryReader { geometry in
//                                    Color.clear
//                                        .onAppear {
//                                            cardsContentWidth = geometry.size.width
//                                        }
//                                        .onChange(of: geometry.size.width) {
//                                            cardsContentWidth = geometry.size.width
//                                        }
//                                }
//                            }
//                        }/*, compactModeOnly: true*/)
//                        .background(
//                            AnyView(
//                                GeometryReader { geometry in
//                                    Color.clear
//                                        .onAppear {
//                                            cardsColumnWidth = geometry.size.width
//                                        }
//                                        .onChange(of: geometry.size.width) {
//                                            cardsColumnWidth = geometry.size.width
//                                        }
//                                }
//                            )
//                        )
//                        Divider()
//                    }
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
                    ListItemView(title: {
                        Text("Event.id")
                            .bold()
                    }, value: {
                        Text("\(information.id)")
                    })
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
//            print(cardsArraySeperated)
        }
    }
    
}




/*
 VStack(alignment: .leading) {
 Text("卡牌")
 .font(.system(size: 16, weight: .medium))
 ForEach(information.cards) { card in
 if let character = information.characters.first(where: { $0.id == card.characterID }),
 let band = information.bands.first(where: { $0.id == band.id }),
 // if the card is contained in `members`, it is a card that has bonus in this event.
 // if not, it should be shown in rewards section (the next one).
 let percent = information.event.members.first(where: { $0.situationID == card.id })?.percent {
 HStack {
 //                                    NavigationLink(destination: { CardDetailView(id: card.id) }) {
 //                                        CardIconView(card, band: band)
 //                                    }
 //                                    .buttonStyle(.borderless)
 Text("+\(percent)%")
 .font(.system(size: 14))
 .opacity(0.6)
 }
 }
 }
 }
 
 
 Section {
 
 VStack(alignment: .leading) {
 Text("奖励")
 .font(.system(size: 16, weight: .medium))
 HStack {
 ForEach(information.cards) { card in
 if let character = information.characters.first(where: { $0.id == card.characterID }),
 let band = information.bands.first(where: { $0.id == character.bandID }) {
 if information.event.rewardCards.contains(card.id) {
 //                                        NavigationLink(destination: { CardDetailView(id: card.id) }) {
 //                                            CardIconView(card, band: band)
 //                                        }
 //                                        .buttonStyle(.borderless)
 }
 }
 }
 }
 }
 }
 .listRowBackground(Color.clear)
 
 
 
 
 if !information.gacha.isEmpty {
 Section {
 //                        FoldableList(information.gacha.reversed()) { gacha in
 //                            GachaCardView(gacha)
 //                        }
 } header: {
 Text("招募")
 }
 }
 if !information.songs.isEmpty {
 Section {
 //                        FoldableList(information.songs.reversed()) { song in
 //                            SongCardView(song)
 //                        }
 } header: {
 Text("歌曲")
 }
 }
 */


struct MultilingualText: View {
    let source: DoriAPI.LocalizedData<String>
    //    let locale: Locale
    var showLocaleKey: Bool = false
    @State var isHovering = false
    @State var allLocaleTexts: [String] = []
    @State var primaryDisplayString = ""
    
    init(source: DoriAPI.LocalizedData<String>, showLocaleKey: Bool = false/*, isHovering: Bool = false, allLocaleTexts: [String], primaryDisplayString: String = ""*/) {
        self.source = source
        self.showLocaleKey = showLocaleKey
        //        self.isHovering = isHovering
        //        self.allLocaleTexts = allLocaleTexts
        //        self.primaryDisplayString = primaryDisplayString
        
        var __allLocaleTexts: [String] = []
        for lang in DoriAPI.Locale.allCases {
            if let pendingString = source.forLocale(lang) {
                if !__allLocaleTexts.contains(pendingString) {
                    __allLocaleTexts.append("\(pendingString)\(showLocaleKey ? " (\(localeToStringDict[lang] ?? "?"))" : "")")
                }
            }
        }
        self._allLocaleTexts = .init(initialValue: __allLocaleTexts)
    }
    var body: some View {
        Group {
#if !os(macOS)
            Menu(content: {
                ForEach(allLocaleTexts, id: \.self) { localeValue in
                    Button(action: {}, label: {
                        Text(localeValue)
                    })
                }
            }, label: {
                MultilingualTextInternalLabel(source: source, showLocaleKey: showLocaleKey)
            })
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .foregroundStyle(.primary)
#else
            MultilingualTextInternalLabel(source: source, showLocaleKey: showLocaleKey)
                .onHover { isHovering in
                    self.isHovering = isHovering
                }
                .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                    VStack(alignment: .trailing) {
                        ForEach(allLocaleTexts, id: \.self) { text in
                            Text(text)
                        }
                    }
                    .padding()
                }
#endif
        }
    }
    struct MultilingualTextInternalLabel: View {
        let source: DoriAPI.LocalizedData<String>
        //    let locale: Locale
        let showLocaleKey: Bool
        @State var primaryDisplayString: String = ""
        var body: some View {
            VStack(alignment: .trailing) {
                if let sourceInPrimaryLocale = source.forPreferredLocale(allowsFallback: false) {
                    Text("\(sourceInPrimaryLocale)\(showLocaleKey ? " (\(localeToStringDict[DoriAPI.preferredLocale] ?? "?"))" : "")")
                        .onAppear {
                            primaryDisplayString = sourceInPrimaryLocale
                        }
                } else if let sourceInSecondaryLocale = source.forSecondaryLocale(allowsFallback: false) {
                    Text("\(sourceInSecondaryLocale)\(showLocaleKey ? " (\(localeToStringDict[DoriAPI.secondaryLocale] ?? "?"))" : "")")
                        .onAppear {
                            primaryDisplayString = sourceInSecondaryLocale
                        }
                } else if let sourceInJP = source.jp {
                    Text("\(sourceInJP)\(showLocaleKey ? " (JP)" : "")")
                        .onAppear {
                            primaryDisplayString = sourceInJP
                        }
                }
                if let secondarySourceInSecondaryLang = source.forSecondaryLocale(allowsFallback: false), secondarySourceInSecondaryLang != primaryDisplayString {
                    Text("\(secondarySourceInSecondaryLang)\(showLocaleKey ? " (\(localeToStringDict[DoriAPI.secondaryLocale] ?? "?"))" : "")")
                        .foregroundStyle(.secondary)
                } else if let secondarySourceInJP = source.jp, secondarySourceInJP != primaryDisplayString {
                    Text("\(secondarySourceInJP)\(showLocaleKey ? " (JP)" : "")")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct MultilingualTextForCountdown: View {
    let source: DoriAPI.Event.Event
    @State var isHovering = false
    //    @State var allLocaleTexts: [String] = []
    //    @State var primaryDisplayString = ""
    @State var allAvailableLocales: [DoriAPI.Locale] = []
    @State var primaryDisplayLocale: DoriAPI.Locale?
    
    //    init(source: DoriAPI.Event.Event/*, isHovering: Bool = false, allLocaleTexts: [String], primaryDisplayString: String = ""*/) {
    //        self.source = source
    //    }
    var body: some View {
        Group {
#if !os(macOS)
            Menu(content: {
                VStack(alignment: .trailing) {
                    ForEach(allAvailableLocales, id: \.self) { localeValue in
                        Button(action: {}, label: {
                            MultilingualTextForCountdownInternalNumbersView(event: source, locale: localeValue)
                        })
                    }
                }
            }, label: {
                MultilingualTextForCountdownInternalLabel(source: source, allAvailableLocales: allAvailableLocales)
            })
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .foregroundStyle(.primary)
#else
            MultilingualTextForCountdownInternalLabel(source: source, allAvailableLocales: allAvailableLocales)
                .onHover { isHovering in
                    self.isHovering = isHovering
                }
                .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                    VStack(alignment: .trailing) {
                        ForEach(allAvailableLocales, id: \.self) { localeValue in
                            MultilingualTextForCountdownInternalNumbersView(event: source, locale: localeValue)
                        }
                    }
                    .padding()
                }
#endif
        }
        .onAppear {
            allAvailableLocales = []
            for lang in DoriAPI.Locale.allCases {
                if source.startAt.availableInLocale(lang) {
                    allAvailableLocales.append(lang)
                }
            }
        }
    }
    struct MultilingualTextForCountdownInternalLabel: View {
        let source: DoriAPI.Event.Event
        let allAvailableLocales: [DoriAPI.Locale]
        @State var primaryDisplayingLocale: DoriAPI.Locale? = nil
        var body: some View {
            VStack(alignment: .trailing) {
                if allAvailableLocales.contains(DoriAPI.preferredLocale) {
                    MultilingualTextForCountdownInternalNumbersView(event: source, locale: DoriAPI.preferredLocale)
                        .onAppear {
                            primaryDisplayingLocale = DoriAPI.preferredLocale
                        }
                } else if allAvailableLocales.contains(DoriAPI.secondaryLocale) {
                    MultilingualTextForCountdownInternalNumbersView(event: source, locale: DoriAPI.secondaryLocale)
                        .onAppear {
                            primaryDisplayingLocale = DoriAPI.secondaryLocale
                        }
                } else if allAvailableLocales.contains(.jp) {
                    MultilingualTextForCountdownInternalNumbersView(event: source, locale: .jp)
                        .onAppear {
                            primaryDisplayingLocale = .jp
                        }
                }
                
                if allAvailableLocales.contains(DoriAPI.secondaryLocale), DoriAPI.secondaryLocale != primaryDisplayingLocale {
                    MultilingualTextForCountdownInternalNumbersView(event: source, locale: DoriAPI.secondaryLocale)
                        .foregroundStyle(.secondary)
                } else if allAvailableLocales.contains(.jp), .jp != primaryDisplayingLocale {
                    MultilingualTextForCountdownInternalNumbersView(event: source, locale: .jp)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    struct MultilingualTextForCountdownInternalNumbersView: View {
        let event: DoriFrontend.Event.Event
        let locale: DoriAPI.Locale
        var body: some View {
            Group {
                if let startDate = event.startAt.forLocale(locale),
                   let endDate = event.endAt.forLocale(locale),
                   let aggregateEndDate = event.aggregateEndAt.forLocale(locale),
                   let distributionStartDate = event.distributionStartAt.forLocale(locale) {
                    if startDate > .now {
                        Text("Event.countdown.start-at.\(Text(startDate, style: .relative)).\(localeToStringDict[locale] ?? "??")")
                    } else if endDate > .now {
                        Text("Event.countdown.end-at.\(Text(endDate, style: .relative)).\(localeToStringDict[locale] ?? "??")")
                    } else if aggregateEndDate > .now {
                        Text("Event.countdown.results-in.\(Text(endDate, style: .relative)).\(localeToStringDict[locale] ?? "??")")
                    } else if distributionStartDate > .now {
                        Text("Event.countdown.rewards-in.\(Text(endDate, style: .relative)).\(localeToStringDict[locale] ?? "??")")
                    } else {
                        Text("Event.countdown.completed.\(localeToStringDict[locale] ?? "??")")
                    }
                }
            }
        }
    }
}

/*
 struct ListItemView<Content1: View, Content2: View>: View {
 let title: Content1
 let value: Content2
 //    let shouldTitleBeOnTop: Bool
 @State var pageWidth: CGFloat = 600
 
 init(@ViewBuilder title: () -> Content1, @ViewBuilder value: () -> Content2/*, shouldTitleBeOnTop: Bool = false*/) {
 self.title = title()
 self.value = value()
 //        self.shouldTitleBeOnTop = shouldTitleBeOnTop
 }
 
 var body: some View {
 Group {
 
 HStack {
 //                if shouldTitleBeOnTop {
 //                    VStack {
 //                        title
 //                        Spacer()
 //                    }
 //                } else {
 title
 //                }
 Spacer()
 value
 }
 }
 .background(
 GeometryReader { geometry in
 Color.clear
 .onAppear {
 pageWidth = geometry.size.width
 }
 .onChange(of: geometry.size.width) {
 pageWidth = geometry.size.width
 }
 }
 )
 }
 }
 */

struct ListItemView<Content1: View, Content2: View>: View {
    let title: Content1
    let value: Content2
    var compactModeOnly: Bool = true
    @State private var totalAvailableWidth: CGFloat = 0
    @State private var titleAvailableWidth: CGFloat = 0
    @State private var valueAvailableWidth: CGFloat = 0
    
    init(@ViewBuilder title: () -> Content1, @ViewBuilder value: () -> Content2, compactModeOnly: Bool = true) {
        self.title = title()
        self.value = value()
        self.compactModeOnly = compactModeOnly
    }
    
    var body: some View {
        Group {
            if (totalAvailableWidth - titleAvailableWidth - valueAvailableWidth) > 5 || compactModeOnly { // HStack (SHORT)
                HStack {
                    title
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        titleAvailableWidth = geometry.size.width
                                    }
                                    .onChange(of: geometry.size.width) {
                                        titleAvailableWidth = geometry.size.width
                                    }
                            }
                        )
                    Spacer()
                    value
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        valueAvailableWidth = geometry.size.width
                                    }
                                    .onChange(of: geometry.size.width) {
                                        valueAvailableWidth = geometry.size.width
                                    }
                            }
                        )
                    
                }
            } else { // VStack (LONG)
                VStack(alignment: .leading) {
                    title
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        titleAvailableWidth = geometry.size.width
                                    }
                                    .onChange(of: geometry.size.width) {
                                        titleAvailableWidth = geometry.size.width
                                    }
                            }
                        )
                    HStack {
                        Spacer()
                        value
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            valueAvailableWidth = geometry.size.width
                                        }
                                        .onChange(of: geometry.size.width) {
                                            valueAvailableWidth = geometry.size.width
                                        }
                                }
                            )
                    }
                }
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        totalAvailableWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) {
                        totalAvailableWidth = geometry.size.width
                    }
            }
        )
    }
}
