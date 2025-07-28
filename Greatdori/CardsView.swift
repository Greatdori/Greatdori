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


// MARK: **DON'T KNOW, DON'T TOUCH**

// 785: SAFE
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
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.15))
            }
            .resizable()
            .scaledToFit()
            .cornerRadius(10)
            
            if showsCountdown { // MARK: Accually Title & Countdown
                Text(locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? ""))
                    .bold()
                    .font(.title3)
                Group {
                    if let startDate = locale != nil ? startAt.forLocale(locale!) : startAt.forPreferredLocale(),
                       let endDate = locale != nil ? endAt.forLocale(locale!) : startAt.forPreferredLocale() {
                        if startDate > .now {
                            Text("Events.countdown.start-at.\(Text(startDate, style: .relative)) \(locale != nil ? " (\(locale!.rawValue.uppercased()))" : "")")
                        } else if endDate > .now {
                            Text("Events.countdown.end-at.\(Text(endDate, style: .relative)) \(locale != nil ? " (\(locale!.rawValue.uppercased()))" : "")")
                        } else {
                            Text("Events.countdown.ended.\(locale != nil ? " (\(locale!.rawValue.uppercased()))" : "")")
                        }
                    } else {
                        Text("Events.countdown.unstarted.\(locale != nil ? " (\(locale!.rawValue.uppercased()))" : "")")
                    }
                }
            }
        }
    }
}

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
struct CardIconView: View {
    private var thumbNormalImageURL: URL
    private var thumbTrainedImageURL: URL?
    private var cardType: DoriAPI.Card.CardType
    private var attribute: DoriAPI.Attribute
    private var rarity: Int
    private var bandIconImageURL: URL
    
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 323)
    init(_ card: DoriAPI.Card.PreviewCard, band: DoriAPI.Band.Band) {
        self.thumbNormalImageURL = card.thumbNormalImageURL
        self.thumbTrainedImageURL = card.thumbAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = band.iconImageURL
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 323)
    init(_ card: DoriAPI.Card.Card, band: DoriAPI.Band.Band) {
        self.thumbNormalImageURL = card.thumbNormalImageURL
        self.thumbTrainedImageURL = card.thumbAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = band.iconImageURL
    }
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 332)
    
    var body: some View {
        if let thumbTrainedImageURL {
            ZStack {
                WebImage(url: thumbTrainedImageURL) { image in
                    image
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.15))
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
                }
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .cornerRadius(2)
                upperLayer(trained: false)
            }
            .frame(width: 50, height: 50)
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
