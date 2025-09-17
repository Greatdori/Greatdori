//===---*- Greatdori! -*---------------------------------------------------===//
//
// CharacterView.swift
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

import DoriKit
import SDWebImageSwiftUI
import SwiftUI

fileprivate let bandLogoScaleFactor: CGFloat = 1.2
fileprivate let charVisualImageCornerRadius: CGFloat = 10

struct CharacterSearchView: View {
    @Namespace var detailNavigation
    @State var charactersDict: DoriFrontend.Character.CategorizedCharacters?
    @State var bandArray: [DoriAPI.Band.Band?] = []
    @State var infoIsAvailable = true
    @State var infoIsReady = false
    var body: some View {
        Group {
            if infoIsReady {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            ForEach(bandArray, id: \.self) { band in
                                if let band {
                                    WebImage(url: band.logoImageURL)
                                        .resizable()
                                        .frame(width: 160*bandLogoScaleFactor, height: 82*bandLogoScaleFactor)
                                    HStack {
                                        ForEach(charactersDict![band]!.swappedAt(0, 3).swappedAt(2, 3), id: \.self) { char in
                                            NavigationLink(destination: {
                                                CharacterDetailView(id: char.id, allCharacters: $charactersDict)
                                                #if !os(macOS)
                                                    .wrapIf(true, in: { content in
                                                        if #available(iOS 18.0, *) {
                                                            content
                                                                .navigationTransition(.zoom(sourceID: char.id, in: detailNavigation))
                                                        } else {
                                                            content
                                                        }
                                                    })
                                                #endif
                                            }, label: {
                                                CharacterImageView(character: char)
                                            })
                                            .buttonStyle(.plain)
                                            .wrapIf(true, in: { content in
                                                if #available(iOS 18.0, macOS 15.0, *) {
                                                    content
                                                        .matchedTransitionSource(id: char.id, in: detailNavigation)
                                                } else {
                                                    content
                                                }
                                            })
                                        }
                                    }
                                    Rectangle()
                                        .frame(width: 0, height: 20)
                                }
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal)
                }
            } else {
                if infoIsAvailable {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        Spacer()
                    }
                } else {
                    ContentUnavailableView("Character.search.unavailable", systemImage: "person.2.fill", description: Text("Search.unavailable.description"))
                        .onTapGesture {
                            Task {
                                await getCharacters()
                            }
                        }
                }
            }
        }
//        .withSystemBackground()
        .navigationTitle("Character")
        .task {
            await getCharacters()
        }
        .withSystemBackground()
    }
    
    func getCharacters() async {
        infoIsAvailable = true
        infoIsReady = false
        DoriCache.withCache(id: "CharacterList") {
            await DoriFrontend.Character.categorizedCharacters()
        }.onUpdate {
            if let characters = $0 {
                self.charactersDict = characters
                bandArray = []
                if let charactersDict {
                    for (key, _) in charactersDict {
                        bandArray.append(key)
                    }
                    bandArray.sort { ($0?.id ?? 9999) < ($1?.id ?? 9999) }
                }
                infoIsReady = true
            } else {
                infoIsAvailable = false
            }
        }
    }
    
    struct CharacterImageView: View {
        var character: DoriFrontend.Character.PreviewCharacter
        @Environment(\.horizontalSizeClass) var sizeClass
        @State var isHovering = false
        var body: some View {
            Group {
                if sizeClass == .regular {
                    ZStack {
                        RoundedRectangle(cornerRadius: charVisualImageCornerRadius)
                            .foregroundStyle(character.color ?? .gray)
                        WebImage(url: character.keyVisualImageURL)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(isHovering ? 1.05 : 1)
                    }
                    .frame(width: 122, height: 480)
                } else {
                    RoundedRectangle(cornerRadius: charVisualImageCornerRadius)
                        .foregroundStyle(character.color ?? .gray)
                        .aspectRatio(122 / 480, contentMode: .fill)
                        .overlay {
                            WebImage(url: character.keyVisualImageURL)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .scaleEffect(isHovering ? 1.05 : 1)
                        }
                }
            }
            .mask {
                RoundedRectangle(cornerRadius: charVisualImageCornerRadius)
                    .aspectRatio(122/480, contentMode: .fill)
            }
            .animation(.spring(duration: 0.3, bounce: 0.1, blendDuration: 0), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
            .contentShape(RoundedRectangle(cornerRadius: charVisualImageCornerRadius))
        }
    }
}


struct CharacterDetailView: View {
    private let randomCardScalingFactor: CGFloat = 1
    
    var id: Int
    @Binding var allCharacters: DoriFrontend.Character.CategorizedCharacters?
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var currentID: Int = 0
    @State var informationLoadPromise: DoriCache.Promise<DoriFrontend.Character.ExtendedCharacter?>?
    @State var information: DoriFrontend.Character.ExtendedCharacter?
    @State var infoIsAvailable = true
    @State var cardNavigationDestinationID: Int?
    @State var lastAvaialbleID: Int = 0
    @State var randomCard: DoriAPI.Card.PreviewCard?
    @State var showSubtitle: Bool = false
    var body: some View {
        EmptyContainer {
            if let information {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
//                            Text()
                            if let randomCard, information.band != nil {
                                CardCardView(randomCard, band: information.band!)
                                    .frame(maxWidth: 480*randomCardScalingFactor, maxHeight: 320*randomCardScalingFactor)
                            }
                            Button(action: {
                                randomCard = information.randomCard()!
                            }, label: {
                                Text(verbatim: "#\(randomCard?.id)")
                            })
//                            CharacterDetailOverviewView(information: information, cardNavigationDestinationID: $cardNavigationDestinationID)
                        }
                        .padding()
                        Spacer(minLength: 0)
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
                    Button(action: {
                        Task {
                            await getInformation(id: currentID)
                        }
                    }, label: {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ContentUnavailableView("Character.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
                                Spacer()
                            }
                            Spacer()
                        }
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(item: $cardNavigationDestinationID, destination: { id in
            Text("\(id)")
        })
        .navigationTitle(Text(information?.character.characterName.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Character") : "")"))
        #if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.character.characterName.forPreferredLocale() != nil ? "#\(currentID)" : "")
            } else {
                content
            }
        }
        #endif
        .onAppear {
            Task {
                DoriCache.withCache(id: "Character_Last_JP_ID", trait: .realTime) {
                    await DoriFrontend.Event.localizedLatestEvent()?.jp?.id
//                    await DoriFrontend.Character.CategorizedCharacters()
                } .onUpdate {
                    lastAvaialbleID = $0 ?? 0
                }
            }
        }
        .onChange(of: currentID, {
            Task {
                await getInformation(id: currentID)
            }
        })
        .task {
            currentID = id
            await getInformation(id: currentID)
        }
        .toolbar {
            ToolbarItemGroup(content: {
                if sizeClass == .regular, let allCharacters {
                    let flatMainCharacters = allCharacters.compactMap { key, value in
                        // only *main* characters
                        key != nil ? value : nil
                    }.flatMap { $0 }
                    if let currentIndex = flatMainCharacters.firstIndex(where: { $0.id == currentID }) {
                        HStack(spacing: 0) {
                            Button(action: {
                                information = nil
                                currentID = flatMainCharacters[currentIndex - 1].id
                            }, label: {
                                Label("Character.previous", systemImage: "arrow.backward")
                            })
                            .disabled(currentIndex - 1 < 0)
                            NavigationLink(destination: {
                                EventSearchView()
                            }, label: {
                                Text("#\(String(currentID))")
                                    .fontDesign(.monospaced)
                                    .bold()
                            })
                            Button(action: {
                                information = nil
                                currentID = flatMainCharacters[currentIndex + 1].id
                            }, label: {
                                Label("Character.next", systemImage: "arrow.forward")
                            })
                            .disabled(currentIndex + 1 >= flatMainCharacters.count)
                        }
                        .disabled(lastAvaialbleID == 0 || currentID == 0)
                        .onAppear {
                            showSubtitle = false
                        }
                    }
                } else {
                    NavigationLink(destination: {
                        CharacterSearchView()
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
        
        informationLoadPromise = DoriCache.withCache(id: "CharacterDetail_\(id)") {
            await DoriFrontend.Character.extendedInformation(of: id)
        }.onUpdate {
            if let information = $0 {
                self.information = information
                randomCard = information.randomCard()
            } else {
                infoIsAvailable = false
            }
        }
    }
}


//MARK: CharacterDetailOverviewView
struct CharacterDetailOverviewView: View {
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
                                        //TODO: [NAVI785]CharD
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
                                            //TODO: [NAVI785]CharD
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
                                                Spacer()
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
                                                        .antialiased(true)
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
                                                                .antialiased(true)
                                                                .resizable()
                                                                .frame(width: imageButtonSize, height: imageButtonSize)
                                                            //                                                Text(char.name)
                                                            Text(eventCharacterNameDict[char.characterID]?.forPreferredLocale() ?? "Unknown")
                                                            Spacer()
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
                            Text("\(String(information.id))")
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
