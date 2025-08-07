//
//  CardsView.swift
//  Greatdori
//
//  Created by ThreeManager785 on 2025/7/28.
//


//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 1)

import SwiftUI
import DoriKit
import SDWebImageSwiftUI


// **DON'T KNOW, DON'T TOUCH**

// MARK: EventCardView [✓]
struct EventCardView: View {
    private var eventImageURL: URL
    private var title: DoriAPI.LocalizedData<String>
    private var startAt: DoriAPI.LocalizedData<Date>
    private var endAt: DoriAPI.LocalizedData<Date>
    private var locale: DoriAPI.Locale?
    private var showsCountdown: Bool
    
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 24)
    init(_ event: DoriAPI.Event.PreviewEvent, inLocale locale: DoriAPI.Locale?, showsCountdown: Bool = false) {
        self.eventImageURL = event.bannerImageURL
        self.title = event.eventName
        self.startAt = event.startAt
        self.endAt = event.endAt
        self.locale = locale
        self.showsCountdown = showsCountdown
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 24)
    init(_ event: DoriAPI.Event.Event, inLocale locale: DoriAPI.Locale?, showsCountdown: Bool = false) {
        self.eventImageURL = event.bannerImageURL
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
                    .fill(Color.gray.opacity(0.15))
                    .aspectRatio(3.0, contentMode: .fit)
            }
            .interpolation(.high)
            .cornerRadius(10)
            
            if showsCountdown { // Accually Title & Countdown
                Text(locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? ""))
                    .bold()
                    .font(.title3)
                Group {
                    if let startDate = locale != nil ? startAt.forLocale(locale!) : startAt.forPreferredLocale(),
                       let endDate = locale != nil ? endAt.forLocale(locale!) : startAt.forPreferredLocale() {
                        if startDate > .now {
                            Text("Events.countdown.start-at.\(Text(startDate, style: .relative)).\(locale != nil ? "(\(locale!.rawValue.uppercased()))" : "")")
                        } else if endDate > .now {
                            Text("Events.countdown.end-at.\(Text(endDate, style: .relative)).\(locale != nil ? "(\(locale!.rawValue.uppercased()))" : "")")
                        } else {
                            Text("Events.countdown.ended.\(locale != nil ? "(\(locale!.rawValue.uppercased()))" : "")")
                        }
                    } else {
                        Text("Events.countdown.unstarted.\(locale != nil ? "(\(locale!.rawValue.uppercased()))" : "")")
                    }
                }
            }
        }
    }
}

//MARK: CardCardView
struct CardCardView: View {
    private var normalBackgroundImageURL: URL
    private var trainedBackgroundImageURL: URL?
    private var cardType: DoriAPI.Card.CardType
    private var attribute: DoriAPI.Attribute
    private var rarity: Int
    private var bandIconImageURL: URL
    
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 104)
    init(_ card: DoriAPI.Card.PreviewCard, band: DoriAPI.Band.Band) {
        self.normalBackgroundImageURL = card.coverNormalImageURL
        self.trainedBackgroundImageURL = card.coverAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = band.iconImageURL
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 104)
    init(_ card: DoriAPI.Card.Card, band: DoriAPI.Band.Band) {
        self.normalBackgroundImageURL = card.coverNormalImageURL
        self.trainedBackgroundImageURL = card.coverAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = band.iconImageURL
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 113)
    
    var body: some View {
        ZStack {
            if let trainedBackgroundImageURL {
                if ![.others, .campaign, .birthday].contains(cardType) {
                    HStack(spacing: 0) {
                        WebImage(url: normalBackgroundImageURL) { image in
                            image
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.15))
                        }
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFill()
//                        .frame(width: (screenBounds.width - 5) / 2)
                        .clipped()
                        WebImage(url: trainedBackgroundImageURL) { image in
                            image
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.15))
                        }
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFill()
//                        .frame(width: (screenBounds.width - 5) / 2)
                        .clipped()
                    }
                } else {
                    WebImage(url: trainedBackgroundImageURL) { image in
                        image
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.15))
                    }
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .cornerRadius(2)
                }
            } else {
                WebImage(url: normalBackgroundImageURL) { image in
                    image
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.15))
                }
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .cornerRadius(2)
            }
            if rarity != 1 {
                Image("CardBorder\(rarity)")
                    .resizable()
            } else {
                Image("CardBorder\(rarity)\(attribute.rawValue.prefix(1).uppercased() + attribute.rawValue.dropFirst())")
                    .resizable()
            }
            VStack {
                HStack {
                    WebImage(url: bandIconImageURL)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .frame(width: 25, height: 25)
                    Spacer()
                    WebImage(url: attribute.iconImageURL)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .frame(width: 23, height: 23)
                }
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(1...rarity, id: \.self) { _ in
                            Image(rarity >= 4 ? .trainedStar : .star)
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                    }
                    Spacer()
                }
            }
        }
//        .frame(width: screenBounds.width - 5, height: (screenBounds.width - 5) * 0.7511244378)
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

//MARK: ThumbCardCardView
struct ThumbCardCardView: View {
    private var thumbNormalImageURL: URL
    private var thumbTrainedImageURL: URL?
    private var cardType: DoriAPI.Card.CardType
    private var attribute: DoriAPI.Attribute
    private var rarity: Int
    private var bandIconImageURL: URL
    private var prefix: DoriAPI.LocalizedData<String>
    
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 220)
    init(_ card: DoriAPI.Card.PreviewCard, band: DoriAPI.Band.Band) {
        self.thumbNormalImageURL = card.thumbNormalImageURL
        self.thumbTrainedImageURL = card.thumbAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = band.iconImageURL
        self.prefix = card.prefix
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 220)
    init(_ card: DoriAPI.Card.Card, band: DoriAPI.Band.Band) {
        self.thumbNormalImageURL = card.thumbNormalImageURL
        self.thumbTrainedImageURL = card.thumbAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = band.iconImageURL
        self.prefix = card.prefix
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 230)
    
    var body: some View {
        HStack {
            if let thumbTrainedImageURL {
                ZStack {
                    WebImage(url: thumbTrainedImageURL) { image in
                        image
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.15))
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFill()
                    .clipped()
                    upperLayer(trained: true)
                }
                .frame(width: 50, height: 50)
            } else {
                ZStack {
                    WebImage(url: thumbNormalImageURL) { image in
                        image
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.15))
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .cornerRadius(2)
                    upperLayer(trained: false)
                }
                .frame(width: 50, height: 50)
            }
            VStack(alignment: .leading) {
                Text(prefix.forPreferredLocale() ?? "")
                    .font(.system(size: 16, weight: .semibold))
                Text(cardType.localizedString)
                    .font(.system(size: 14))
            }
        }
    }
    
    @ViewBuilder
    private func upperLayer(trained: Bool) -> some View {
        if rarity != 1 {
            Image("CardThumbBorder\(rarity)")
                .resizable()
        } else {
            Image("CardThumbBorder\(rarity)\(attribute.rawValue.prefix(1).uppercased() + attribute.rawValue.dropFirst())")
                .resizable()
        }
        VStack {
            HStack {
                WebImage(url: bandIconImageURL)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .frame(width: 15, height: 15)
                Spacer()
                WebImage(url: attribute.iconImageURL)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .frame(width: 12, height: 12)
            }
            Spacer()
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(1...rarity, id: \.self) { _ in
                        Image(trained ? .trainedStar : .star)
                            .resizable()
                            .frame(width: 6, height: 6)
                    }
                }
                Spacer()
            }
        }
    }
}


//MARK: CardIconView [✓]
struct CardIconView: View {
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
    @State var cardTitle: DoriAPI.LocalizedData<String>?
    @State var cardCharacterName: DoriAPI.LocalizedData<String>?
    @State var isCardInfoAvailable = false
//    @State var cardNavigationDestinationID: Int?
    @Binding var cardNavigationDestinationID: Int?
    @State var isHovering: Bool = false
    
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 323)
    init(_ card: DoriAPI.Card.PreviewCard, showTrainedVersion: Bool = false, sideLength: CGFloat = 72, showNavigationHints: Bool = false, cardNavigationDestinationID: Binding<Int?>) {
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
        self._cardNavigationDestinationID = cardNavigationDestinationID
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 323)
    init(_ card: DoriAPI.Card.Card, showTrainedVersion: Bool = false, sideLength: CGFloat = 72, showNavigationHints: Bool = false, cardNavigationDestinationID: Binding<Int?>) {
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
        self._cardNavigationDestinationID = cardNavigationDestinationID
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 332)
    
    var body: some View {
        ZStack(alignment: .center) {
            // Cover
            WebImage(url: (thumbTrainedImageURL != nil && showTrainedVersion) ? thumbTrainedImageURL : thumbNormalImageURL) { image in
                image
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.15))
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
            
            //Icons
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
            //TODO: Optimize for macOS
                .contextMenu(menuItems: {
                    VStack {
                        Button(action: {
                            cardNavigationDestinationID = cardID
                        }, label: {
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
//                                        .foregroundStyle(.secondary)
                                    Text(verbatim: "Lorem ipsum")
                                        .font(.caption)
//                                        .foregroundStyle(.tertiary)
                                }
                                .redacted(reason: .placeholder)
                                
                            }
                        })
                        .disabled(cardTitle?.forPreferredLocale() == nil ||  cardCharacterName?.forPreferredLocale() == nil)
                    }
                })
            #else
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
                                .foregroundStyle(.secondary)
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
        .task {
            let fullCard = await DoriAPI.Card.Card(id: cardID)
            DispatchQueue.main.async {
                cardTitle = fullCard?.prefix
            }
            
            if let cardCharacterID = fullCard?.characterID {
                DoriCache.withCache(id: "CharacterDetail_\(cardCharacterID)") {
                    await DoriFrontend.Character.extendedInformation(of: cardCharacterID)
                }.onUpdate {
                    if let information = $0 {
                        DispatchQueue.main.async {
                            self.cardCharacterName = information.character.characterName
                            isCardInfoAvailable = true
                        }
                    }
                }
            }
        }
    }
    
    #if os(macOS)
    /// Hi, what happened?
    /// We NEED this to workaround a bug (maybe of SwiftUI?)
    struct HereTheWorld<each T, V: View>: NSViewRepresentable {
        private var controller: NSViewController
        private var viewBuilder: (repeat each T) -> V
        init(arguments: (repeat each T), @ViewBuilder view: @escaping (repeat each T) -> V) {
            self.controller = NSHostingController(rootView: view(repeat each arguments))
            self.viewBuilder = view
        }
        func makeNSView(context: Context) -> some NSView {
            self.controller.view
        }
        func updateNSView(_ nsView: NSViewType, context: Context) {}
        func updateArguments(_ arguments: (repeat each T)) {
            let newView = viewBuilder(repeat each arguments)
            controller.view = NSHostingView(rootView: newView)
        }
    }
    #endif
}

struct ThumbCostumeCardView: View {
    private var thumbImageURL: URL
    private var description: DoriAPI.LocalizedData<String>
    
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 414)
    init(_ costume: DoriAPI.Costume.PreviewCostume) {
        self.thumbImageURL = costume.thumbImageURL
        self.description = costume.description
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 414)
    init(_ costume: DoriAPI.Costume.Costume) {
        self.thumbImageURL = costume.thumbImageURL
        self.description = costume.description
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 419)
    
    var body: some View {
        HStack {
            WebImage(url: thumbImageURL) { image in
                image
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.15))
            }
            .resizable()
            .scaledToFit()
            .frame(width: 50)
            Text(description.forPreferredLocale() ?? "")
        }
    }
}

struct GachaCardView: View {
    private var bannerImageURL: URL
    private var title: DoriAPI.LocalizedData<String>
    
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 444)
    init(_ gacha: DoriAPI.Gacha.PreviewGacha) {
        self.bannerImageURL = gacha.bannerImageURL
        self.title = gacha.gachaName
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 444)
    init(_ gacha: DoriAPI.Gacha.Gacha) {
        self.bannerImageURL = gacha.bannerImageURL
        self.title = gacha.gachaName
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 449)
    
    var body: some View {
        ZStack {
            WebImage(url: bannerImageURL) { image in
                image
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.15))
            }
            .resizable()
            .scaledToFill()
//            .frame(width: screenBounds.width - 5, height: 100)
            .clipped()
            .cornerRadius(10)
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Text(title.forPreferredLocale() ?? "")
                        .padding(.horizontal, 2)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Material.ultraThin)
                                .blur(radius: 5)
                        }
                }
                .font(.system(size: 12))
                .lineLimit(1)
                .padding(.horizontal, 4)
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

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
