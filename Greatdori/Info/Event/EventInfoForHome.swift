//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventInfoForHome.swift
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


// MARK: EventInfoForHome
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
