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
//                                .frame(maxWidth: .infinity)
                            //                            .ignoresSafeArea(nil)
                        }
                        .padding()
                        Spacer()
                    }
//                    HStack {
//                        Text("Event.gacha")
//                            .font(.title3)
//                    .bold
//                    }
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
        .navigationTitle(Text(information?.event.eventName.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Event") : "")"))
        #if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, *) {
                if showSubtitle {
                    //                if information?.event.eventName.forPreferredLocale() != nil {
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
                            //FIXME: [NAVI785] eventList
                        }, label: {
                            Image(systemName: "list.bullet")
                        })
                        .onAppear {
                            showSubtitle = true
                        }
//                        .buttonStyle(.bordered)
//                        .buttonBorderShape(.circle)
                
//                    .buttonBorderShape(.circle)
                }
            })
        }
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
                                            //
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
                                    /*
                                    Grid(alignment: .trailing) {
                                        let separated = if cardsUseCompactLayout {
                                            cardsArraySeperated
                                        } else {
                                            [cardsArraySeperated.flatMap { $0 }.compactMap { $0 }]
                                        }
                                        ForEach(separated, id: \.self) { rowContent in
                                            GridRow {
                                                ForEach(rowContent, id: \.id) { item in
                                                    if item != nil {
                                                        NavigationLink(destination: {
                                                            //TODO: [NAVI785]CardD
                                                        }, label: {
                                                            CardIconView(item!, sideLength: cardThumbnailSideLength, showNavigationHints: true, cardNavigationDestinationID: $cardNavigationDestinationID)
                                                        })
                                                        .buttonStyle(.plain)
                                                    } else {
                                                        Rectangle()
                                                            .opacity(0)
                                                            .frame(width: 0, height: 0)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .gridCellAnchor(.trailing)
                                    */
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


//MARK: MultilingualText
struct MultilingualText: View {
    let source: DoriAPI.LocalizedData<String>
    //    let locale: Locale
    var showLocaleKey: Bool = false
    @State var isHovering = false
    @State var allLocaleTexts: [String] = []
    @State var primaryDisplayString = ""
    
    init(source: DoriAPI.LocalizedData<String>, showLocaleKey: Bool = false) {
        self.source = source
        self.showLocaleKey = showLocaleKey
        
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
                            .multilineTextAlignment(.trailing)
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
            .multilineTextAlignment(.trailing)
        }
    }
}


//MARK: MultilingualTextForCountdown
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


//MARK: ListItemView
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
            if compactModeOnly || (totalAvailableWidth - titleAvailableWidth - valueAvailableWidth) > 5 { // HStack (SHORT)
                HStack {
                    title
                        .fixedSize(horizontal: true, vertical: true)
                        .onFrameChange(perform: { geometry in
                            titleAvailableWidth = geometry.size.width
                        })
                    Spacer()
                    value
                        .onFrameChange(perform: { geometry in
                            valueAvailableWidth = geometry.size.width
                        })
                }
            } else { // VStack (LONG)
                VStack(alignment: .leading) {
                    title
                        .fixedSize(horizontal: true, vertical: true)
                        .onFrameChange(perform: { geometry in
                            titleAvailableWidth = geometry.size.width
                        })
                    HStack {
                        Spacer()
                        value
                            .onFrameChange(perform: { geometry in
                                valueAvailableWidth = geometry.size.width
                            })
                    }
                }
            }
        }
        .onFrameChange(perform: { geometry in
            totalAvailableWidth = geometry.size.width
        })
    }
}
//struct ThisView<Content2: View>: View {
//    let element: (T?) -> Content2
//    init(@ViewBuilder element: () -> Content2) {
//        self.element = element()
//    }
//    var body: some View {
//        element(someSortOfVariableThatIsGivenFromThisView)
//    }
//}





//MARK: ListItemWithWrappingView
struct ListItemWithWrappingView<Content1: View, Content2: View, Content3: View, T>: View {
    let title: Content1
    let element: (T?) -> Content2
    let caption: Content3
    let columnNumbers: Int
    let elementWidth: CGFloat
    var contentArray: [T?]
    @State var contentArrayChunked: [[T?]] = []
    @State var titleWidth: CGFloat = 0 // Fixed
    @State var captionWidth: CGFloat = 0 // Fixed
//    @State var cardsContentRegularWidth: CGFloat = 0 // Fixed
    @State var fixedWidth: CGFloat = 0 //Fixed
    @State var useCompactLayout = true
    
    init(@ViewBuilder title: () -> Content1, @ViewBuilder element: @escaping (T?) -> Content2, @ViewBuilder caption: () -> Content3, contentArray: [T] , columnNumbers: Int, elementWidth: CGFloat) {
        self.title = title()
        self.element = element
        self.caption = caption()
        self.contentArray = contentArray
        self.elementWidth = elementWidth
        self.columnNumbers = columnNumbers
    }
    var body: some View {
        ListItemView(title: {
            title
                .onFrameChange(perform: { geometry in
                    titleWidth = geometry.size.width
                    fixedWidth = (CGFloat(contentArray.count)*elementWidth) + titleWidth + captionWidth
                })
        }, value: {
            HStack {
                if !useCompactLayout {
                    HStack {
                        ForEach(0..<contentArray.count, id: \.self) { elementIndex in
                            element(contentArray[elementIndex])
                            //contentArray[elementIndex]
                        }
                    }
                } else {
                    /*
                     Grid(alignment: .trailing) {
                     let separated = if cardsUseCompactLayout {
                     cardsArraySeperated
                     } else {
                     [cardsArraySeperated.flatMap { $0 }.compactMap { $0 }]
                     }
                     ForEach(separated, id: \.self) { rowContent in
                     GridRow {
                     ForEach(rowContent, id: \.id) { item in
                     if item != nil {
                     NavigationLink(destination: {
                     //TODO: [NAVI785]CardD
                     Text("\(item)")
                     }, label: {
                     CardIconView(item!, sideLength: cardThumbnailSideLength, showNavigationHints: true, cardNavigationDestinationID: $cardNavigationDestinationID)
                     })
                     .buttonStyle(.plain)
                     } else {
                     Rectangle()
                     .opacity(0)
                     .frame(width: 0, height: 0)
                     }
                     }
                     }
                     }
                     }
                     .gridCellAnchor(.trailing)
                     */
                    Grid(alignment: .trailing) {
                        ForEach(0..<contentArrayChunked.count, id: \.self) { rowIndex in
                            
                            GridRow {
                                ForEach(0..<contentArrayChunked[rowIndex].count, id: \.self) { columnIndex in
                                    if contentArrayChunked[rowIndex][columnIndex] != nil {
                                        NavigationLink(destination: {
                                            //TODO: [NAVI785]CardD
                                        }, label: {
                                            //                                            CardIconView(item!, sideLength: cardThumbnailSideLength, showNavigationHints: true, cardNavigationDestinationID: $cardNavigationDestinationID)
                                            //                                            element
                                            //                                            Text("")
                                            element(contentArrayChunked[rowIndex][columnIndex]!)
//                                            Text("")
                                        })
                                        .buttonStyle(.plain)
                                    } else {
                                        Rectangle()
                                            .opacity(0)
                                            .frame(width: 0, height: 0)
                                    }
                                }
                            }
                        }
                    }
                    .gridCellAnchor(.trailing)
                }
                caption
                    .onFrameChange(perform: { geometry in
                        captionWidth = geometry.size.width
                        fixedWidth = (CGFloat(contentArray.count)*elementWidth) + titleWidth + captionWidth
                    })
            }
        })
        .onAppear {
            fixedWidth = (CGFloat(contentArray.count)*elementWidth) + titleWidth + captionWidth
            
            contentArrayChunked = contentArray.chunked(into: columnNumbers)
            for i in 0..<contentArrayChunked.count {
                while contentArrayChunked[i].count < columnNumbers {
                    contentArrayChunked[i].insert(nil, at: 0)
                }
            }
        }
        .onFrameChange(perform: { geometry in
            if (geometry.size.width - fixedWidth) < 50 && !useCompactLayout {
                useCompactLayout = true
            } else if (geometry.size.width - fixedWidth) > 50 && useCompactLayout {
                useCompactLayout = false
            }
        })
    }
}


//MARK: EventSearchView
struct EventSearchView: View {
    @State var filter = DoriFrontend.Filter()
    @State var events: [DoriFrontend.Event.PreviewEvent]?
    @State var searchedEvents: [DoriFrontend.Event.PreviewEvent]?
    @State var infoIsAvailable = true
    @State var searchedText = ""
    @State var showDetails = false
    var body: some View {
        NavigationStack {
            if let resultEvents = searchedEvents ?? events {
                ScrollView {
                    ViewThatFits {
                        LazyVGrid(columns: [GridItem(.fixed(420), spacing: 10), GridItem(.fixed(420), spacing: 0)], content: {
                            ForEach(0..<resultEvents.count, id: \.self) { eventIndex in
                                NavigationLink(destination: {
                                    EventDetailView(id: resultEvents[eventIndex].id)
                                }, label: {
                                    EventCardView(resultEvents[eventIndex], inLocale: nil, showDetails: showDetails)
                                })
                                .buttonStyle(.plain)
                            }
                        })
                        LazyVStack {
                            ForEach(0..<resultEvents.count, id: \.self) { eventIndex in
                                NavigationLink(destination: {
                                    EventDetailView(id: resultEvents[eventIndex].id)
                                }, label: {
                                    EventCardView(resultEvents[eventIndex], inLocale: nil)
                                })
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .animation(.spring(duration: 0.3, bounce: 0.35, blendDuration: 0), value: showDetails)
                }
                .ignoresSafeArea()
                .padding()
                .searchable(text: $searchedText, prompt: "Event.search.placeholder")
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
        .navigationTitle("Event")
        .task {
            await getEvents()
        }
        .toolbar {
            ToolbarItem {
                Toggle(isOn: $showDetails, label: {
                    Image(systemName: "info.circle")
                })
            }
        }
    }
    
    func getEvents() async {
        infoIsAvailable = true
        DoriCache.withCache(id: "EventList_\(filter.identity)") {
            await DoriFrontend.Event.list(filter: filter)
        }.onUpdate {
            if let events = $0 {
                self.events = events
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

