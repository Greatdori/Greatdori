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
#if os(iOS)
import UIKit
#endif

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
                    VStack {
                        HStack {
                            Spacer(minLength: 0)
                            VStack {
                                //                            Text()
                                if var randomCard, information.band != nil {
                                    CardCardView(randomCard, band: information.band!)
                                        .wrapIf(sizeClass == .regular, in: { content in
                                            content
                                                .frame(maxWidth: 480*randomCardScalingFactor, maxHeight: 320*randomCardScalingFactor)
                                        }, else: { content in
                                            content
                                            //[250917-c]
                                            //.scaledToFill()
                                        })
                                }
                                Button(action: {
                                    randomCard = information.randomCard()!
                                }, label: {
                                    Label("Character.random-card", systemImage: "arrow.clockwise")
                                })
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                                
                                //                            CharacterDetailOverviewView(information: information, cardNavigationDestinationID: $cardNavigationDestinationID)
                            }
                            .padding()
                            Spacer(minLength: 0)
                        }
                        CharacterDetailOverviewView(information: information)
                        Spacer()
                    }
                    .padding()
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
    let information: DoriFrontend.Character.ExtendedCharacter
    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.timeZone = .init(identifier: "Asia/Tokyo")!
        df.setLocalizedDateFormatFromTemplate("MMM d")
        return df
    }
    var body: some View {
        VStack {
            Group {
                //MARK: Info
                Group {
                    //MARK: Name
                    Group {
                        ListItemView(title: {
                            Text("Character.name")
                                .bold()
                        }, value: {
                            MultilingualText(source: information.character.characterName)
                        })
                        Divider()
                    }
                    
                    if !(information.character.nickname.jp ?? "").isEmpty {
                        //MARK: Nickname
                        Group {
                            ListItemView(title: {
                                Text("Character.nickname")
                                    .bold()
                            }, value: {
                                MultilingualText(source: information.character.nickname)
                            })
                            Divider()
                        }
                    }
                    
                    if let profile = information.character.profile {
                        //MARK: Character Voice
                        Group {
                            ListItemView(title: {
                                Text("Character.character-voice")
                                    .bold()
                            }, value: {
                                MultilingualText(source: profile.characterVoice)
                            })
                            Divider()
                        }
                    }
                    
                    if let color = information.character.color {
                        //MARK: Color
                        Group {
                            ListItemView(title: {
                                Text("Character.color")
                                    .bold()
                            }, value: {
                                Text(color.toHex() ?? "")
                                    .fontDesign(.monospaced)
                                RoundedRectangle(cornerRadius: 7)
                                //                                    .aspectRatio(1, contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(color)
                            })
                            Divider()
                        }
                    }
                    
                    if let bandID = information.character.bandID {
                        //MARK: Band
                        Group {
                            ListItemView(title: {
                                Text("Character.band")
                                    .bold()
                            }, value: {
                                Text(DoriCache.preCache.mainBands.first{$0.id == bandID}?.bandName.forPreferredLocale(allowsFallback: true) ?? "Unknown")
                                WebImage(url: DoriCache.preCache.mainBands.first{$0.id == bandID}?.iconImageURL)
                                    .resizable()
                                    .interpolation(.high)
                                    .antialiased(true)
//                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                
                            })
                            Divider()
                        }
                    }
                    
                    if let profile = information.character.profile {
                        //MARK: Role
                        Group {
                            ListItemView(title: {
                                Text("Character.role")
                                    .bold()
                            }, value: {
                                Text(profile.part.localizedString)
                            })
                            Divider()
                        }
                        
                        //MARK: Role
                        Group {
                            ListItemView(title: {
                                Text("Character.birthday")
                                    .bold()
                            }, value: {
                                Text(dateFormatter.string(from: profile.birthday))
                            })
                            Divider()
                        }
                        
                        //MARK: Constellation
                        Group {
                            ListItemView(title: {
                                Text("Character.constellation")
                                    .bold()
                            }, value: {
                                Text(profile.constellation.localizedString)
                            })
                            Divider()
                        }
                        
                        //MARK: Height
                        Group {
                            ListItemView(title: {
                                Text("Character.height")
                                    .bold()
                            }, value: {
                                Text(verbatim: "\(profile.height) cm")
                            })
                            Divider()
                        }
                        
                        //MARK: School
                        Group {
                            ListItemView(title: {
                                Text("Character.school")
                                    .bold()
                            }, value: {
                                MultilingualText(source: profile.school)
                            })
                            Divider()
                        }
                        
                        //MARK: Favorite Food
                        Group {
                            ListItemView(title: {
                                Text("Character.year-class")
                                    .bold()
                            }, value: {
                                MultilingualText(source: {
                                    var localizedContent = DoriAPI.LocalizedData<String>.init(_jp: nil, en: nil, tw: nil, cn: nil, kr: nil)
                                    for locale in DoriAPI.Locale.allCases {
                                        localizedContent._set("\(profile.schoolYear.forLocale(locale) ?? "nil") - \(profile.schoolClass.forLocale(locale) ?? "nil")", forLocale: locale)
                                    }
                                    return localizedContent
                                }())
                            })
                            Divider()
                        }
                        
                        //MARK: Favorite Food
                        Group {
                            ListItemView(title: {
                                Text("Character.favorite-food")
                                    .bold()
                            }, value: {
                                MultilingualText(source: profile.favoriteFood)
                            })
                            Divider()
                        }
                        
                        //MARK: Disliked Food
                        Group {
                            ListItemView(title: {
                                Text("Character.disliked-food")
                                    .bold()
                            }, value: {
                                MultilingualText(source: profile.hatedFood)
                            })
                            Divider()
                        }
                        
                        //MARK: Hobby
                        Group {
                            ListItemView(title: {
                                Text("Character.hobby")
                                    .bold()
                            }, value: {
                                MultilingualText(source: profile.hobby)
                            })
                            Divider()
                        }
                        
                        //MARK: Introduction
                        Group {
                            ListItemView(title: {
                                Text("Character.introduction")
                                    .bold()
                            }, value: {
                                MultilingualText(source: profile.selfIntroduction, showSecondaryText: false)
                            }, displayMode: .compactOnly)
                            Divider()
                        }
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
        .frame(maxWidth: 600)
        .onAppear {}
    }
}


extension Color {
    /// 转换为十六进制字符串 (#RRGGBB)
    func toHex() -> String? {
#if os(macOS)
        let nativeColor = NSColor(self).usingColorSpace(.deviceRGB)
        guard let color = nativeColor else { return nil }
#else
        let color = UIColor(self)
#endif
        
//        guard let color = nativeColor else { return nil }
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
#if os(macOS)
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
#else
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
#endif
        
        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(red * 255)),
            lroundf(Float(green * 255)),
            lroundf(Float(blue * 255))
        )
    }
}
