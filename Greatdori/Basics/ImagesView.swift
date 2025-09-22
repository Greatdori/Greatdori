//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardsView.swift
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

//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 1)


// This file is an essential complications for several items that are all related with images.
// Files not marked with [✓] is not optimized for multiplatform yet (they're all from watchOS).

import DoriKit
import SDWebImageSwiftUI
import SwiftUI


//MARK: CardInfo [✓]
struct CardInfo: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var attributedTitle: AttributedString = AttributedString("")
//    @State var attributedType: AttributedString = AttributedString("")
    
    var layoutType = 1
    // 1 - List
    // 2 - Grid
    // 3 - Gallery
    
    private var preferHeavierFonts: Bool = true
    private var thumbNormalImageURL: URL
    private var thumbTrainedImageURL: URL?
    private var cardType: DoriAPI.Card.CardType
    private var attribute: DoriAPI.Attribute
    private var rarity: Int
    private var band: Band?
    private var bandIconImageURL: URL?
    private var prefix: DoriAPI.LocalizedData<String>
    private var characterID: Int
    private var cardID: Int
    private var previewCard: PreviewCard
    private var searchedText: String
    @State var cardCharacterName: DoriAPI.LocalizedData<String>?
    
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 220)
    init(_ card: DoriAPI.Card.PreviewCard, layoutType: Int = 1, preferHeavierFonts: Bool = false, searchedText: String = "") {
        self.layoutType = layoutType
        self.preferHeavierFonts = preferHeavierFonts
        self.thumbNormalImageURL = card.thumbNormalImageURL
        self.thumbTrainedImageURL = card.thumbAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.band = DoriCache.preCache.categorizedCharacters.first(where: { $0.value.contains(where: { $0.id == card.characterID }) })?.key
        self.bandIconImageURL = band?.iconImageURL
        self.prefix = card.prefix
        self.characterID = card.characterID
        self.cardID = card.id
        self.previewCard = card
        self.searchedText = searchedText
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 220)
    init(_ card: DoriAPI.Card.Card, layoutType: Int = 1, preferHeavierFonts: Bool = false, searchedText: String = "") {
        self.layoutType = layoutType
        self.preferHeavierFonts = preferHeavierFonts
        self.thumbNormalImageURL = card.thumbNormalImageURL
        self.thumbTrainedImageURL = card.thumbAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.band = DoriCache.preCache.categorizedCharacters.first(where: { $0.value.contains(where: { $0.id == card.characterID }) })?.key
        self.bandIconImageURL = band?.iconImageURL
        self.prefix = card.prefix
        self.characterID = card.characterID
        self.cardID = card.id
        self.previewCard = PreviewCard(card)
        self.searchedText = searchedText
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 230)
    
    var body: some View {
        CustomGroupBox {
            CustomStack(axis: layoutType == 1 ? .horizontal : .vertical) {
                if layoutType == 2 {
                    Spacer()
                }
                // MARK: CardPreviewImage
                if layoutType != 3 {
                    HStack(spacing: 5) {
                        CardPreviewImage(previewCard)
                        if thumbTrainedImageURL != nil {
                            CardPreviewImage(previewCard, showTrainedVersion: true)
                        }
                    }
                    .wrapIf(sizeClass == .regular) { content in
                        content.frame(maxWidth: 200)
                    }
                } else {
                    CardCoverImage(previewCard, band: band)
                        .allowsHitTesting(false)
                }
                
                // MARK: Text
                VStack(alignment: layoutType == 1 ? .leading : .center) {
                    Text(attributedTitle)
                        .bold()
//                        .font((!preferHeavierFonts && !isMACOS) ? .body : .title3)
                        .font(isMACOS ? .title3 : .body)
                        .onAppear {
                            attributedTitle = highlightOccurrences(of: searchedText, in: prefix.forPreferredLocale() ?? "nil")
                        }
                        .onChange(of: prefix, {
                            attributedTitle = highlightOccurrences(of: searchedText, in: prefix.forPreferredLocale() ?? "nil")
                        })
                    Group {
                        Text(cardCharacterName?.forPreferredLocale() ?? "nil") + Text(verbatim: " • ").bold() + Text(cardType.localizedString)
                    }
                    .foregroundStyle(.secondary)
                    .font((!preferHeavierFonts && !isMACOS) ? .caption : .body)
//                    .font(isMACOS ? .body : .caption)
                }
                .multilineTextAlignment(layoutType == 1 ? .leading : .center)
                if layoutType != 3 {
                    Spacer()
                }
            }
            .wrapIf(layoutType == 2) { content in
                HStack {
                    Spacer(minLength: 0)
                    content
                    Spacer(minLength: 0)
                }
            }
        }
        .onAppear {
            self.cardCharacterName = DoriCache.preCache.characterDetails[characterID]?.characterName
        }
    }
}


//MARK: CardCoverImage [✓]
struct CardCoverImage: View {
    private var normalBackgroundImageURL: URL
    private var trainedBackgroundImageURL: URL?
    private var cardType: DoriAPI.Card.CardType
    private var attribute: DoriAPI.Attribute
    private var rarity: Int
    private var bandIconImageURL: URL?
    private var showNavigationHints: Bool
    private var cardID: Int
    private var cardTitle: DoriAPI.LocalizedData<String>
    private var characterID: Int
    @State var cardCharacterName: DoriAPI.LocalizedData<String>?
    @State var showCardDetailView: Bool = false
//    @State var cardDestinationID: Int = 0
    
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 104)
    init(_ card: DoriAPI.Card.PreviewCard, band: DoriAPI.Band.Band?, showNavigationHints: Bool = true) {
        self.normalBackgroundImageURL = card.coverNormalImageURL
        self.trainedBackgroundImageURL = card.coverAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = band?.iconImageURL
        self.showNavigationHints = showNavigationHints
        self.cardID = card.id
        self.cardTitle = card.prefix
        self.characterID = card.characterID
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 104)
    init(_ card: DoriAPI.Card.Card, band: DoriAPI.Band.Band?, showNavigationHints: Bool = true) {
        self.normalBackgroundImageURL = card.coverNormalImageURL
        self.trainedBackgroundImageURL = card.coverAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = band?.iconImageURL
        self.showNavigationHints = showNavigationHints
        self.cardID = card.id
        self.cardTitle = card.prefix
        self.characterID = card.characterID
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 113)
    
    private let cardCornerRadius: CGFloat = 10
    private let standardCardWidth: CGFloat = 480
    private let standardCardHeight: CGFloat = 320
    private let expectedCardRatio: CGFloat = 480/320
    private let cardFocusSwitchingAnimation: Animation = .easeOut(duration: 0.15)
    
    @State var normalCardIsOnHover = false
    @State var trainedCardIsOnHover = false
    
    
    @State var isHovering: Bool = false
    var body: some View {
        ZStack {
            // MARK: Border
            Group {
                if rarity != 1 {
                    Image("CardBorder\(rarity)")
                        .resizable()
                } else {
                    Image("CardBorder\(rarity)\(attribute.rawValue.prefix(1).uppercased() + attribute.rawValue.dropFirst())")
                        .resizable()
                }
            }
            .aspectRatio(expectedCardRatio, contentMode: .fit)
            .clipped()
            .allowsHitTesting(false)
            .background {
                // MARK: Card Content
                GeometryReader { proxy in
                    Group {
                        if let trainedBackgroundImageURL {
                            if ![.others, .campaign, .birthday].contains(cardType) {
                                HStack(spacing: 0) {
                                    WebImage(url: normalBackgroundImageURL) { image in
                                        image
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 0)
                                            .fill(getPlaceholderColor())
                                    }
                                    .resizable()
                                    .interpolation(.high)
                                    .antialiased(true)
                                    .scaledToFill()
                                    .frame(width: proxy.size.width * CGFloat(normalCardIsOnHover ? 0.75 : (trainedCardIsOnHover ? 0.25 : 0.5)))
                                    .clipped()
                                    .onTapGesture {
                                        withAnimation(cardFocusSwitchingAnimation) {
                                            if !normalCardIsOnHover {
                                                normalCardIsOnHover = true
                                                trainedCardIsOnHover = false
                                            } else {
                                                normalCardIsOnHover = false
                                            }
                                        }
                                    }
                                    .onHover { isHovering in
                                        withAnimation(cardFocusSwitchingAnimation) {
                                            if isHovering {
                                                normalCardIsOnHover = true
                                                trainedCardIsOnHover = false
                                            } else {
                                                normalCardIsOnHover = false
                                            }
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    
                                    WebImage(url: trainedBackgroundImageURL) { image in
                                        image
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 0)
                                            .fill(getPlaceholderColor())
                                    }
                                    .resizable()
                                    .interpolation(.high)
                                    .antialiased(true)
                                    .scaledToFill()
                                    .frame(width: proxy.size.width * CGFloat(trainedCardIsOnHover ? 0.75 : (normalCardIsOnHover ? 0.25 : 0.5)))
                                    .clipped()
                                    .onTapGesture {
                                        withAnimation(cardFocusSwitchingAnimation) {
                                            if !trainedCardIsOnHover {
                                                normalCardIsOnHover = false
                                                trainedCardIsOnHover = true
                                            } else {
                                                trainedCardIsOnHover = false
                                            }
                                        }
                                    }
                                    .onHover { isHovering in
                                        withAnimation(cardFocusSwitchingAnimation) {
                                            if isHovering {
                                                normalCardIsOnHover = false
                                                trainedCardIsOnHover = true
                                            } else {
                                                trainedCardIsOnHover = false
                                            }
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .allowsHitTesting(true)
                            } else {
                                WebImage(url: trainedBackgroundImageURL) { image in
                                    image
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: cardCornerRadius)
                                        .fill(getPlaceholderColor())
                                }
                                .resizable()
                                .interpolation(.high)
                                .antialiased(true)
                            }
                        } else {
                            WebImage(url: normalBackgroundImageURL) { image in
                                image
                            } placeholder: {
                                RoundedRectangle(cornerRadius: cardCornerRadius)
                                    .fill(getPlaceholderColor())
                            }
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                        }
                    }
                    .cornerRadius(cardCornerRadius)
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    //                    .scaleEffect(0.97)
                }
            }
            
            // The Image may not be in expected ratio. Gosh.
            // Why the heck will the image has a different ratio with the border???
            // --@ThreeManager785
            
            // MARK: Visualized Card Information
            // This includes information like `attributes` and `rarity`.
            GeometryReader { proxy in
                VStack {
                    HStack {
                        if let bandIconImageURL {
                            WebImage(url: bandIconImageURL)
                                .resizable()
                                .interpolation(.high)
                                .antialiased(true)
                            //51:480 = ?:currentWidth
                            //? = currentWidth*51/480
                            
                                .frame(width: 51/standardCardWidth*proxy.size.width, height: 51/standardCardHeight*proxy.size.height, alignment: .topLeading)
                                .offset(x: proxy.size.width*0.005, y: proxy.size.height*0.01)
                            //                    Spacer()
                        }
                        Spacer()
                        WebImage(url: attribute.iconImageURL)
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .frame(width: 51/standardCardWidth*proxy.size.width, height: 51/standardCardHeight*proxy.size.height, alignment: .topLeading)
                            .offset(x: proxy.size.width*(-0.015), y: proxy.size.height*0.015)
                    }
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(1...rarity, id: \.self) { _ in
                                Image(rarity >= 4 ? .trainedStar : .star)
                                    .resizable()
                                    .frame(width: 40/standardCardWidth*proxy.size.width, height: 40/standardCardHeight*proxy.size.height, alignment: .topLeading)
                                    .padding(.top, CGFloat(-rarity))
                            }
                        }
                        Spacer()
                    }
                }
            }
            .aspectRatio(expectedCardRatio, contentMode: .fit)
        }
        .cornerRadius(cardCornerRadius)
        .wrapIf(showNavigationHints, in: { content in
#if os(iOS)
            content
                .contextMenu(menuItems: {
                    VStack {
                        Button(action: {
                            //                            cardNavigationDestinationID = cardID
                            showCardDetailView = true
                        }, label: {
                            if let title = cardTitle.forPreferredLocale(), let character = cardCharacterName?.forPreferredLocale() {
                                Group {
                                    Text(title)
                                    Group {
                                        Text("\(character)") + Text("Typography.bold-dot-seperater").bold() +  Text(cardType.localizedString)
                                    }
                                    .font(.caption)
                                }
                            } else {
                                Group {
                                    Text(verbatim: "Lorem ipsum dolor")
                                    //                                        .foregroundStyle(.secondary)
                                    Text(verbatim: "Lorem ipsum")
                                        .font(.caption)
                                    //                                        .foregroundStyle(.tertiary)
                                }
                                .redacted(reason: .placeholder)
                                
                            }
                        })
                        .disabled(cardTitle.forPreferredLocale() == nil ||  cardCharacterName?.forPreferredLocale() == nil)
                    }
                })
#else
            content
            /*
             // Very weird code cuz SwiftUI has very weird refreshing logic.
             // Don't touch without complete-understaning
             let sumimi = HereTheWorld(arguments: (cardTitle, cardCharacterName)) { cardTitle, cardCharacterName in
             VStack {
             if let title = cardTitle?.forPreferredLocale(), let character = cardCharacterName?.forPreferredLocale() {
             Group {
             Text(title)
             Group {
             Text("\(character)") + Text(verbatim: " • ").bold() +  Text("#\(String(cardID))")
             }
             .font(.caption)
             }
             } else {
             Group {
             Text(verbatim: "Lorem ipsum dolor")
             .foregroundStyle(getPlaceholderColor())
             //                                .fill()
             Text(verbatim: "Lorem ipsum")
             .foregroundStyle(.tertiary)
             }
             .redacted(reason: .placeholder)
             
             }
             }
             .padding()
             }
             content
             .onHover { isHovering in
             self.isHovering = isHovering
             }
             .popover(isPresented: $isHovering, arrowEdge: .bottom) {
             sumimi
             }
             .onChange(of: cardTitle) {
             sumimi.updateArguments((cardTitle, cardCharacterName))
             }
             .onChange(of: cardCharacterName) {
             sumimi.updateArguments((cardTitle, cardCharacterName))
             }
             */
#endif
        })
        .onAppear {
            self.cardCharacterName = DoriCache.preCache.characterDetails[characterID]?.characterName
        }
        .navigationDestination(isPresented: $showCardDetailView, destination: {
            CardDetailView(id: cardID)
        })
    }
    
}


//MARK: CardPreviewImage [✓]
struct CardPreviewImage: View {
    private var inputtedPreviewCard: DoriAPI.Card.PreviewCard?
    private var cardID: Int
    private var thumbNormalImageURL: URL
    private var thumbTrainedImageURL: URL?
    private var cardType: DoriAPI.Card.CardType
    private var attribute: DoriAPI.Attribute
    private var rarity: Int
    private var bandIconImageURL: URL?
    private var showTrainedVersion: Bool = false
    private var sideLength: CGFloat = 72
    private var showNavigationHints: Bool
    private var cardTitle: DoriAPI.LocalizedData<String>
    private var characterID: Int
    @State var cardCharacterName: DoriAPI.LocalizedData<String>?
//    @State var isCardInfoAvailable = false
//    @State var cardNavigationDestinationID: Int?
    @State var showCardDetailView = false
    @State var cardNavigationDestinationID: Int = 0
    @State var isHovering: Bool = false
    
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 323)
    init(_ card: DoriAPI.Card.PreviewCard, showTrainedVersion: Bool = false, sideLength: CGFloat = 72, showNavigationHints: Bool = false/*, cardNavigationDestinationID: Binding<Int?>*/) {
        self.inputtedPreviewCard = card
        self.cardID = card.id
        self.thumbNormalImageURL = card.thumbNormalImageURL
        self.thumbTrainedImageURL = card.thumbAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = URL(string: "https://bestdori.com/res/icon/band_\(DoriCache.preCache.characters.first { $0.id == card.characterID }?.bandID ?? 0).svg")!
        self.showTrainedVersion = showTrainedVersion
        self.sideLength = sideLength
        self.showNavigationHints = showNavigationHints
        self.cardTitle = card.prefix
        self.characterID = card.characterID
//        self._cardNavigationDestinationID = cardNavigationDestinationID
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 323)
    init(_ card: DoriAPI.Card.Card, showTrainedVersion: Bool = false, sideLength: CGFloat = 72, showNavigationHints: Bool = false/*, cardNavigationDestinationID: Binding<Int?>*/) {
        self.cardID = card.id
        self.thumbNormalImageURL = card.thumbNormalImageURL
        self.thumbTrainedImageURL = card.thumbAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = URL(string: "https://bestdori.com/res/icon/band_\(DoriCache.preCache.characters.first { $0.id == card.characterID }?.bandID ?? 0).svg")!
        self.showTrainedVersion = showTrainedVersion
        self.sideLength = sideLength
        self.showNavigationHints = showNavigationHints
        self.cardTitle = card.prefix
        self.characterID = card.characterID
//        self._cardNavigationDestinationID = cardNavigationDestinationID
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 332)
    
    var body: some View {
        ZStack(alignment: .center) {
            // Cover
            WebImage(url: (thumbTrainedImageURL != nil && showTrainedVersion) ? thumbTrainedImageURL : thumbNormalImageURL) { image in
                image
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
//                    .fill(Color.gray.opacity(0.15))
                    .fill(getPlaceholderColor())
                    .aspectRatio(1, contentMode: .fit)
            }
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            //.scaledToFill()
            //.cornerRadius(2)
            .clipped()
            .frame(width: 67/72*sideLength, height: 67/72*sideLength)
            
            // Frame
            if rarity != 1 {
                Image("CardThumbBorder\(rarity)")
                    .resizable()
                    .frame(width: sideLength, height: sideLength)
            } else {
                Image("CardThumbBorder\(rarity)\(attribute.rawValue.prefix(1).uppercased() + attribute.rawValue.dropFirst())")
                    .resizable()
                    .frame(width: sideLength, height: sideLength)
            }
            
            // Icons
            VStack(spacing: 0) {
                HStack {
                    WebImage(url: bandIconImageURL)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .frame(width: 20/72*sideLength, height: 20/72*sideLength, alignment: .topLeading)
                    Spacer()
                    WebImage(url: attribute.iconImageURL)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .frame(width: 18/72*sideLength, height: 18/72*sideLength, alignment: .topTrailing)
                        .offset(x: -1)
                }
                
                Spacer(minLength: 0)
                HStack {
                    VStack(alignment: .leading, spacing: -2) {
                        ForEach(1...rarity, id: \.self) { _ in
                            Image((thumbTrainedImageURL != nil && showTrainedVersion) ? .trainedStar : .star)
                                .resizable()
                                .frame(width: 12/72*sideLength, height: 12/72*sideLength)
                        }
                    }
                    Spacer()
                }
            }
            .frame(width: sideLength, height: sideLength)
        }
        .wrapIf(showNavigationHints, in: { content in
            #if os(iOS)
            content
                .contextMenu(menuItems: {
                    VStack {
                        //                        NavigationLink(destination: {
                        //                            CardDetailView(id: cardID)
                        //                        }, label: {
                        Button(action: {
                            cardNavigationDestinationID = cardID
                            showCardDetailView = true
                        }, label: {
                            if let title = cardTitle.forPreferredLocale(), let character = cardCharacterName?.forPreferredLocale() {
                                Group {
                                    Text(title)
                                    Group {
                                        Text("\(character)") + Text("Typography.bold-dot-seperater").bold() +  Text(cardType.localizedString)
                                    }
                                    .font(.caption)
                                }
                            } else {
                                Group {
                                    Text(verbatim: "Lorem ipsum dolor")
//                                        .foregroundStyle(.secondary)
                                    Text(verbatim: "Lorem ipsum")
                                        .font(.caption)
//                                        .foregroundStyle(.tertiary)
                                }
                                .redacted(reason: .placeholder)
                                
                            }
                        })
                        .disabled(cardTitle.forPreferredLocale() == nil ||  cardCharacterName?.forPreferredLocale() == nil)
                    }
                })
            #else
            // Very weird code cuz SwiftUI has very weird refreshing logic.
            // Don't touch without complete-understaning
            let sumimi = HereTheWorld(arguments: (cardTitle, cardCharacterName)) { cardTitle, cardCharacterName in
                VStack {
                    if let title = cardTitle.forPreferredLocale(), let character = cardCharacterName?.forPreferredLocale() {
                        Group {
                            Text(title)
                            Group {
                                Text("\(character)") + Text(verbatim: " • ").bold() +  Text(cardType.localizedString)
                            }
                            .font(.caption)
                        }
                    } else {
                        Group {
                            Text(verbatim: "Lorem ipsum dolor")
                                .foregroundStyle(getPlaceholderColor())
//                                .fill()
                            Text(verbatim: "Lorem ipsum")
                                .foregroundStyle(.tertiary)
                        }
                        .redacted(reason: .placeholder)
                        
                    }
                }
                .padding()
            }
            content
                .onHover { isHovering in
                    self.isHovering = isHovering
                }
                .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                    sumimi
                }
                .onChange(of: cardTitle) {
                    sumimi.updateArguments((cardTitle, cardCharacterName))
                }
                .onChange(of: cardCharacterName) {
                    sumimi.updateArguments((cardTitle, cardCharacterName))
                }
            #endif
        })
        .frame(width: sideLength, height: sideLength)
        .onAppear {
            self.cardCharacterName = DoriCache.preCache.characterDetails[characterID]?.characterName
        }
        .navigationDestination(isPresented: $showCardDetailView, destination: {
            CardDetailView(id: cardNavigationDestinationID)
        })
    }
}


// MARK: CostumeInfo [✓]
struct CostumeInfo: View {
    @Binding var searchedKeyword: String
    @State var attributedTitle: AttributedString = AttributedString("")
    @State var attributedChar: AttributedString = AttributedString("")
    
    private var preferHeavierFonts: Bool = true
    private var thumbImageURL: URL
    private var title: DoriAPI.LocalizedData<String>
    private var costumeID: Int
    private var locale: DoriAPI.Locale?
    private var layout: Axis
    private var showID: Bool
    private var characterID: Int
    
    init(_ costume: DoriAPI.Costume.PreviewCostume, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, layout: Axis = .horizontal, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
        self.preferHeavierFonts = preferHeavierFonts
        self.thumbImageURL = costume.thumbImageURL(in: locale ?? DoriAPI.preferredLocale)!
        self.title = costume.description
        self.costumeID = costume.id
        self.locale = locale
        self.layout = layout
        self.showID = showID
        self._searchedKeyword = searchedKeyword
        self.characterID = costume.characterID
    }
    
    init(_ costume: DoriAPI.Costume.Costume, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, layout: Axis = .horizontal, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
        self.preferHeavierFonts = preferHeavierFonts
        self.thumbImageURL = costume.thumbImageURL(in: locale ?? DoriAPI.preferredLocale)!
        self.title = costume.description
        self.costumeID = costume.id
        self.locale = locale
        self.layout = layout
        self.showID = showID
        self._searchedKeyword = searchedKeyword
        self.characterID = costume.characterID
    }
    
    let lighterVersionBannerScaleFactor: CGFloat = 0.85
    @State var characterName: LocalizedData<String>?
    
    var body: some View {
        CustomGroupBox {
            CustomStack(axis: layout) {
                WebImage(url: thumbImageURL) { image in
                    image
                        .resizable()
                        .antialiased(true)
//                        .scaledToFit()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 96*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), height: 96*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(getPlaceholderColor())
                        .frame(width: 96*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), height: 96*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                }
                .interpolation(.high)
                
                if layout == .vertical {
                    Spacer()
                }
                
                VStack(alignment: layout == .horizontal ? .leading : .center) {
                    Text(attributedTitle)
                        .bold()
                        .font((!preferHeavierFonts && !isMACOS) ? .body : .title3)
                        .onAppear {
                            attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))
                        }
                        .multilineTextAlignment(layout == .horizontal ? .leading : .center)
                        .typesettingLanguage(.explicit(((locale ?? .jp).nsLocale().language)))
                        .onChange(of: searchedKeyword, {
                            attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))
                        })
                        Text(characterName?.forPreferredLocale() ?? "nil")
                    .foregroundStyle(.secondary)
                    .font((!preferHeavierFonts && !isMACOS) ? .caption : .body)
                }
                
                if layout == .horizontal {
                    Spacer()
                }
            }
            .wrapIf(layout == .vertical) { content in
                HStack {
                    Spacer()
                    content
                    Spacer()
                }
            }
        }
        .onAppear {
            characterName = DoriCache.preCache.characters.first(where: {$0.id == characterID})?.characterName
            
            attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))
            attributedChar = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (characterName?.forLocale(locale!) ?? characterName?.jp ?? "") : (characterName?.forPreferredLocale() ?? "")))
        }
//        .border(.red)
    }
}


//MARK: EventInfo [✓]
struct EventInfo: View {
    @Binding var searchedKeyword: String
    @State var attributedTitle: AttributedString = AttributedString("")
    @State var attributedType: AttributedString = AttributedString("")
    
    private var preferHeavierFonts: Bool = true
    private var eventImageURL: URL
    private var title: DoriAPI.LocalizedData<String>
    private var eventID: Int
    private var eventType: DoriAPI.Event.EventType
    private var locale: DoriAPI.Locale?
    private var showDetails: Bool
    private var showID: Bool
    //    @State var imageHeight: CGFloat = 100
    
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 24)
    init(_ event: DoriAPI.Event.PreviewEvent, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, showDetails: Bool = false, showID: Bool = true, searchedKeyword: Binding<String> = .constant("")) {
        self.preferHeavierFonts = preferHeavierFonts
        self.eventImageURL = event.bannerImageURL(in: locale ?? DoriAPI.preferredLocale)!
        self.title = event.eventName
        self.eventID = event.id
        self.eventType = event.eventType
        self.locale = locale
        self.showDetails = showDetails
        self.showID = showID
        self._searchedKeyword = searchedKeyword
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 24)
    init(_ event: DoriAPI.Event.Event, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, showDetails: Bool = false, showID: Bool = true,  searchedKeyword: Binding<String> = .constant("")) {
        self.preferHeavierFonts = preferHeavierFonts
        self.eventImageURL = event.bannerImageURL(in: locale ?? DoriAPI.preferredLocale)!
        self.title = event.eventName
        self.eventID = event.id
        self.eventType = event.eventType
        self.locale = locale
        self.showDetails = showDetails
        self.showID = showID
        self._searchedKeyword = searchedKeyword
    }
    
    let lighterVersionBannerScaleFactor: CGFloat = 0.85
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 33)
    
    var body: some View {
        CustomGroupBox(showGroupBox: showDetails) {
            HStack {
                if !preferHeavierFonts {
                    Spacer(minLength: 0)
                }
                VStack {
                    WebImage(url: eventImageURL) { image in
                        image
                            .resizable()
                            .antialiased(true)
                        //                        .scaledToFit()
                            .aspectRatio(3.0, contentMode: .fit)
                            .frame(maxWidth: 420*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), maxHeight: 140*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                        //                        .fill(Color.gray.opacity(0.15))
                            .fill(getPlaceholderColor())
                            .aspectRatio(3.0, contentMode: .fit)
                            .frame(maxWidth: 420*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), maxHeight: 140*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                    }
                    .interpolation(.high)
                    .cornerRadius(10)
                    
                    if showDetails {
                        VStack { // Accually Title & Countdown
                                 //                        Text(locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? ""))
                            Text(attributedTitle)
                                .multilineTextAlignment(.center)
                                .bold()
                                .font((!preferHeavierFonts && !isMACOS) ? .body : .title3)
                                .onAppear {
                                    //                                attributedString = highlightKeyword(in: , keyword: searchedKeyword)
                                    attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))
                                }
                                .typesettingLanguage(.explicit(((locale ?? .jp).nsLocale().language)))
                                .onChange(of: searchedKeyword, {
                                    attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))
                                })
                            Group {
                                //                            if !searchedKeyword.isEmpty {
                                //                                Text("#\(eventID)").fontDesign(.monospaced).foregroundStyle((searchedKeyword == "#\(eventID)") ? Color.accentColor : .primary) + Text("Typography.dot-seperater").bold() + Text(attributedType)
                                if preferHeavierFonts {
                                    HStack {
                                        Text(attributedType)
                                        if showID {
                                            Text("#\(String(eventID))").fontDesign(.monospaced).foregroundStyle((searchedKeyword == "#\(eventID)") ? Color.accentColor : .secondary)
                                        }
                                    }
                                } else {
                                    Group {
                                        Text(attributedType) + Text(verbatim: " • ").bold() + Text("#\(String(eventID))").fontDesign(.monospaced)
                                    }
                                    .foregroundStyle(.secondary)
                                    //                                    .font(.caption)
                                }
                                //                            } else {
                                //                                Text(eventType.localizedString)
                                //                            }
                            }
                            .onAppear {
                                attributedType = highlightOccurrences(of: searchedKeyword, in: eventType.localizedString)
                            }
                            .onChange(of: eventType.localizedString, {
                                attributedType = highlightOccurrences(of: searchedKeyword, in: eventType.localizedString)
                            })
                        }
                        .frame(height: showDetails ? nil : 0)
                        .opacity(showDetails ? 1 : 0)
                    }
                }
                if !preferHeavierFonts {
                    Spacer(minLength: 0)
                }
            }
        }
    }
}


//MARK: EventInfoForHome [✓]
struct EventInfoForHome: View {
    private var eventImageURL: URL
    private var title: DoriAPI.LocalizedData<String>
    private var startAt: DoriAPI.LocalizedData<Date>
    private var endAt: DoriAPI.LocalizedData<Date>
    private var locale: DoriAPI.Locale?
    private var showsCountdown: Bool
    
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 24)
    init(_ event: DoriAPI.Event.PreviewEvent, inLocale locale: DoriAPI.Locale?, showsCountdown: Bool = false) {
        self.eventImageURL = event.bannerImageURL(in: locale ?? DoriAPI.preferredLocale)!
        self.title = event.eventName
        self.startAt = event.startAt
        self.endAt = event.endAt
        self.locale = locale
        self.showsCountdown = showsCountdown
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 24)
    init(_ event: DoriAPI.Event.Event, inLocale locale: DoriAPI.Locale?, showsCountdown: Bool = false) {
        self.eventImageURL = event.bannerImageURL(in: locale ?? DoriAPI.preferredLocale)!
        self.title = event.eventName
        self.startAt = event.startAt
        self.endAt = event.endAt
        self.locale = locale
        self.showsCountdown = showsCountdown
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 33)
    
    var body: some View {
        VStack {
            WebImage(url: eventImageURL) { image in
                image
                    .resizable()
                    .antialiased(true)
                    .scaledToFit()
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(getPlaceholderColor())
                    .aspectRatio(3.0, contentMode: .fit)
            }
            .interpolation(.high)
            .cornerRadius(10)
            
            if showsCountdown { // Accually Title & Countdown
                Text(locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? ""))
                    .typesettingLanguage(.explicit(((locale ?? .jp).nsLocale().language)))
                    .bold()
                    .font(.title3)
                    .multilineTextAlignment(.center)
                Group {
                    if let startDate = locale != nil ? startAt.forLocale(locale!) : startAt.forPreferredLocale(),
                       let endDate = locale != nil ? endAt.forLocale(locale!) : startAt.forPreferredLocale() {
                        if startDate > .now {
                            Text("Events.countdown.start-at.\(Text(startDate, style: .relative)).\(locale != nil ? "(\(locale!.rawValue.uppercased()))" : "")")
                                .multilineTextAlignment(.center)
                        } else if endDate > .now {
                            Text("Events.countdown.end-at.\(Text(endDate, style: .relative)).\(locale != nil ? "(\(locale!.rawValue.uppercased()))" : "")")
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Events.countdown.ended.\(locale != nil ? "(\(locale!.rawValue.uppercased()))" : "")")
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        Text("Events.countdown.unstarted.\(locale != nil ? "(\(locale!.rawValue.uppercased()))" : "")")
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}


//MARK: GachaInfo [✓]
struct GachaInfo: View {
    @Binding var searchedKeyword: String
    @State var attributedTitle: AttributedString = AttributedString("")
    @State var attributedType: AttributedString = AttributedString("")
    
    private var preferHeavierFonts: Bool = true
    private var gachaImageURL: URL
    private var title: DoriAPI.LocalizedData<String>
    private var gachaID: Int
    private var gachaType: DoriAPI.Gacha.GachaType
    private var locale: DoriAPI.Locale?
    private var showDetails: Bool
    private var showID: Bool
    //    @State var imageHeight: CGFloat = 100
    
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 24)
    init(_ gacha: DoriAPI.Gacha.PreviewGacha, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, showDetails: Bool = false, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
        self.preferHeavierFonts = preferHeavierFonts
        self.gachaImageURL = gacha.bannerImageURL(in: locale ?? DoriAPI.preferredLocale)!
        self.title = gacha.gachaName
        self.gachaID = gacha.id
        self.gachaType = gacha.type
        self.locale = locale
        self.showDetails = showDetails
        self.showID = showID
        self._searchedKeyword = searchedKeyword
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 24)
    init(_ gacha: DoriAPI.Gacha.Gacha, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, showDetails: Bool = false, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
        self.preferHeavierFonts = preferHeavierFonts
        self.gachaImageURL = gacha.bannerImageURL(in: locale ?? DoriAPI.preferredLocale)!
        self.title = gacha.gachaName
        self.gachaID = gacha.id
        self.gachaType = gacha.type
        self.locale = locale
        self.showDetails = showDetails
        self.showID = showID
        self._searchedKeyword = searchedKeyword
    }
    
    let lighterVersionBannerScaleFactor: CGFloat = 0.85
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 33)
    
    var body: some View {
        CustomGroupBox(showGroupBox: showDetails) {
            HStack {
                if !preferHeavierFonts {
                    Spacer(minLength: 0)
                }
                VStack {
                    if preferHeavierFonts {
                        Spacer(minLength: 0)
                    }
                    WebImage(url: gachaImageURL) { image in
                        image
                            .resizable()
                            .antialiased(true)
                            .scaledToFit()
                            .aspectRatio(3.0, contentMode: .fit)
                            .frame(maxWidth: 420*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), maxHeight: 140*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(getPlaceholderColor())
                            .aspectRatio(3.0, contentMode: .fit)
                            .frame(maxWidth: 420*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), maxHeight: 140*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                    }
                    .interpolation(.high)
                    .cornerRadius(10)
                    
                    if showDetails {
                        VStack { // Accually Title & Countdown
                                 //                        Text(locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? ""))
                            Text(attributedTitle)
                                .multilineTextAlignment(.center)
                                .bold()
                                .font((!preferHeavierFonts && !isMACOS) ? .body : .title3)
                                .onAppear {
                                    //                                attributedString = highlightKeyword(in: , keyword: searchedKeyword)
                                    attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))
                                }
                                .typesettingLanguage(.explicit(((locale ?? .jp).nsLocale().language)))
                                .onChange(of: searchedKeyword, {
                                    attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))
                                })
                            Group {
                                //                            if !searchedKeyword.isEmpty {
                                //                                Text("#\(gachaID)").fontDesign(.monospaced).foregroundStyle((searchedKeyword == "#\(gachaID)") ? Color.accentColor : .primary) + Text("Typography.dot-seperater").bold() + Text(attributedType)
                                if preferHeavierFonts {
                                    HStack {
                                        Text(attributedType)
                                        if showID {
                                            Text("#\(String(gachaID))").fontDesign(.monospaced).foregroundStyle((searchedKeyword == "#\(gachaID)") ? Color.accentColor : .secondary)
                                        }
                                    }
                                    .foregroundStyle(.secondary)
                                } else {
                                    Group {
                                        Text(attributedType)/* + Text(verbatim: " • ").bold() + Text("#\(String(gachaID))").fontDesign(.monospaced)*/
                                    }
                                    .foregroundStyle(.secondary)
                                    //                                    .font(.caption)
                                }
                                //                            } else {
                                //                                Text(gachaType.localizedString)
                                //                            }
                            }
                            .onAppear {
                                attributedType = highlightOccurrences(of: searchedKeyword, in: gachaType.localizedString)
                            }
                            .onChange(of: gachaType.localizedString, {
                                attributedType = highlightOccurrences(of: searchedKeyword, in: gachaType.localizedString)
                            })
                        }
                        .frame(height: showDetails ? nil : 0)
                        .opacity(showDetails ? 1 : 0)
                    }
                    if preferHeavierFonts {
                        Spacer(minLength: 0)
                    }
                }
                if !preferHeavierFonts {
                    Spacer(minLength: 0)
                }
            }
        }
    }
}


//MARK: SongCardView
struct SongCardView: View {
    private var jacketImageURL: URL
    private var title: DoriAPI.LocalizedData<String>
    private var difficulty: [DoriAPI.Song.DifficultyType: DoriAPI.Song.PreviewSong.Difficulty]
    
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 495)
    init(_ song: DoriAPI.Song.PreviewSong) {
        self.jacketImageURL = song.jacketImageURL
        self.title = song.musicTitle
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 501)
        self.difficulty = song.difficulty
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 503)
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 495)
    init(_ song: DoriAPI.Song.Song) {
        self.jacketImageURL = song.jacketImageURL
        self.title = song.musicTitle
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 499)
        self.difficulty = song.difficulty.mapValues { DoriAPI.Song.PreviewSong.Difficulty($0) }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 503)
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 505)
    
    var body: some View {
        HStack {
            WebImage(url: jacketImageURL)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipped()
            VStack(alignment: .leading) {
                Text(title.forPreferredLocale() ?? "")
                HStack {
                    let keys = difficulty.keys.sorted { $0.rawValue < $1.rawValue }
                    ForEach(keys, id: \.rawValue) { key in
                        Text(String(difficulty[key]!.playLevel))
                            .foregroundStyle(.black)
                            .frame(width: 20, height: 20)
                            .background {
                                Circle()
                                    .fill(key.color)
                            }
                    }
                }
            }
        }
    }
}
