//
//  EventView.swift
//  Greatdori
//
//  Created by ThreeManager785 on 2025/7/29.
//

import SwiftUI
import DoriKit
import SDWebImageSwiftUI



struct EventDetailView: View {
    var id: Int
    @State var information: DoriFrontend.Event.ExtendedEvent?
    @State var infoIsAvailable = true
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    var body: some View {
        NavigationStack {
            if let information {
                ScrollView {
                    HStack {
                        Spacer()
                        VStack {
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
                                HStack {
                                    Text("Event.title")
                                        .bold()
                                    Spacer()
                                    MultilingualText(source: information.event.eventName)
                                }
                                Divider()
                                HStack {
                                    Text("Event.type")
                                        .bold()
                                    Spacer()
                                    Text(information.event.eventType.localizedString)
                                }
                                Divider()
                                HStack {
                                    Text("Event.countdown")
                                        .bold()
                                    Spacer()
//                                    Text(information.event)
                                    //TODO: MultilingualTextForCountdown
                                }
                                Divider()
                                HStack {
                                    Text("Event.start-date")
                                        .bold()
                                    Spacer()
                                    MultilingualText(source: information.event.startAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                                }
                                Divider()
                                HStack {
                                    Text("Event.end-date")
                                        .bold()
                                    Spacer()
                                    MultilingualText(source: information.event.endAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                                }
//                                Divider()
//                                HStack {
//                                    Text("Event.end-date")
//                                        .bold()
//                                    Spacer()
//                                    WebImage(url: information.event.attributes)
//                                        .resizable()
//                                        .frame(width: 20, height: 20)
//                                    Text("+\(attribute.percent)%")
//                                }
                                
                            }
                        }
                        .frame(maxWidth: 600)
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
        .navigationTitle(Text(information?.event.eventName.forPreferredLocale() ?? "#\(id)"))
//        .navigationTitle(.lineLimit(nil))
//        .toolbarTitleDisplayMode(.inline)
        .task {
            await getInformation()
        }
        .onTapGesture {
            if !infoIsAvailable {
                Task {
                      await getInformation()
                }
            }
        }
    }
    
    func getInformation() async {
        infoIsAvailable = true
        DoriCache.withCache(id: "EventDetail_\(id)") {
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



/*
 VStack(alignment: .leading) {
 Text("标题")
 .font(.system(size: 16, weight: .medium))
 Text(information.event.eventName.forPreferredLocale() ?? "")
 .font(.system(size: 14))
 .opacity(0.6)
 }
 VStack(alignment: .leading) {
 Text("种类")
 .font(.system(size: 16, weight: .medium))
 Text(information.event.eventType.localizedString)
 .font(.system(size: 14))
 .opacity(0.6)
 }
 
 if let startDate = information.event.startAt.forPreferredLocale(),
 let endDate = information.event.endAt.forPreferredLocale() {
 VStack(alignment: .leading) {
 Text("倒计时")
 .font(.system(size: 16, weight: .medium))
 Group {
 if startDate > .now {
 Text("\(Text(startDate, style: .relative))后开始")
 } else if endDate > .now {
 Text("\(Text(endDate, style: .relative))后结束")
 } else {
 Text("已完结")
 }
 }
 .font(.system(size: 14))
 .opacity(0.6)
 }
 }
 if let date = information.event.startAt.forPreferredLocale() {
 VStack(alignment: .leading) {
 Text("开始日期")
 .font(.system(size: 16, weight: .medium))
 Text({
 let df = DateFormatter()
 df.dateStyle = .medium
 df.timeStyle = .short
 return df.string(from: date)
 }())
 .font(.system(size: 14))
 .opacity(0.6)
 }
 }
 if let date = information.event.endAt.forPreferredLocale() {
 VStack(alignment: .leading) {
 Text("结束日期")
 .font(.system(size: 16, weight: .medium))
 Text({
 let df = DateFormatter()
 df.dateStyle = .medium
 df.timeStyle = .short
 return df.string(from: date)
 }())
 .font(.system(size: 14))
 .opacity(0.6)
 }
 }
 VStack(alignment: .leading) {
 Text("属性")
 .font(.system(size: 16, weight: .medium))
 ForEach(information.event.attributes, id: \.attribute.rawValue) { attribute in
 HStack {
 WebImage(url: attribute.attribute.iconImageURL)
 .resizable()
 .frame(width: 20, height: 20)
 Text("+\(attribute.percent)%")
 .font(.system(size: 14))
 .opacity(0.6)
 }
 }
 }
 VStack(alignment: .leading) {
 Text("角色")
 .font(.system(size: 16, weight: .medium))
 ForEach(information.characters) { character in
 HStack {
 WebImage(url: character.iconImageURL)
 .resizable()
 .frame(width: 20, height: 20)
 if let percent = information.event.characters.first(where: { $0.characterID == character.id })?.percent {
 Text("+\(percent)%")
 .font(.system(size: 14))
 .opacity(0.6)
 }
 }
 }
 }
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
    }
    var body: some View {
        Group {
#if !os(macOS)
            Menu(content: {
                ForEach(allLocaleTexts, id: \.self) { localeValue in
                    Text(localeValue)
                }
            }, label: {
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
                    } else {
                        Text("")
                    }
                    if let secondarySourceInSecondaryLang = source.forSecondaryLocale(allowsFallback: false) {
                        if secondarySourceInSecondaryLang != primaryDisplayString {
                            Text("\(secondarySourceInSecondaryLang)\(showLocaleKey ? " (\(localeToStringDict[DoriAPI.secondaryLocale] ?? "?"))" : "")")
                                .foregroundStyle(.secondary)
                        }
                    } else if let secondarySourceInJP = source.jp {
                        if secondarySourceInJP != primaryDisplayString {
                            Text("\(secondarySourceInJP)\(showLocaleKey ? " (JP)" : "")")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            })
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .foregroundStyle(.primary)
#else
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
                } else {
                    Text("")
                }
                if let secondarySourceInSecondaryLang = source.forSecondaryLocale(allowsFallback: false) {
                    if secondarySourceInSecondaryLang != primaryDisplayString {
                        Text("\(secondarySourceInSecondaryLang)\(showLocaleKey ? " (\(localeToStringDict[DoriAPI.secondaryLocale] ?? "?"))" : "")")
                            .foregroundStyle(.secondary)
                    }
                } else if let secondarySourceInJP = source.jp {
                    if secondarySourceInJP != primaryDisplayString {
                        Text("\(secondarySourceInJP)\(showLocaleKey ? " (JP)" : "")")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onHover { isHovering in
                self.isHovering = isHovering
            }
            .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                VStack(alignment: .trailing) {
                    ForEach(allLocaleTexts, id: \.self) { localeValue in
                        Text(localeValue)
                    }
                }
                .padding()
            }
#endif
        }
        .onAppear {
//            ForEach([DoriAPI.Locale.jp, DoriAPI.Locale.en, DoriAPI.Locale.tw, DoriAPI.Locale.cn, DoriAPI.Locale.kr], id: \.self) { localeValue in
//                if let targetValue = source.forLocale(localeValue) {
//                    Text("\(targetValue)")
//                    //Text("\(targetValue) (\(localeLabelDict[localeValue]!))")
//                }
//            }
            for lang in [DoriAPI.Locale.jp, DoriAPI.Locale.en, DoriAPI.Locale.tw, DoriAPI.Locale.cn, DoriAPI.Locale.kr] {
                if let pendingString = source.forLocale(lang) {
                    if !allLocaleTexts.contains(pendingString) {
                        allLocaleTexts.append("\(pendingString)\(showLocaleKey ? " (\(localeToStringDict[lang] ?? "?"))" : "")")
                    }
                }
            }
        }
    }
}


// COUNTDOWN ONLY
struct MultilingualTextForCountdown: View {
    let source: DoriAPI.LocalizedData<String>
    var showLocaleKey: Bool = false
    @State var isHovering = false
    @State var primaryDisplayString = ""
    
    init(source: DoriAPI.LocalizedData<String>, showLocaleKey: Bool = false/*, isHovering: Bool = false, allLocaleTexts: [String], primaryDisplayString: String = ""*/) {
        self.source = source
        self.showLocaleKey = showLocaleKey
        //        self.isHovering = isHovering
        //        self.allLocaleTexts = allLocaleTexts
        //        self.primaryDisplayString = primaryDisplayString
    }
    var body: some View {
        Group {
#if !os(macOS)
            Menu(content: {
                ForEach(DoriAPI.Locale.allCases, id: \.self) { localeValue in
//                    Text(localeValue)
                    //CountdownText
                }
            }, label: {
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
                    } else {
                        Text("")
                    }
                    if let secondarySourceInSecondaryLang = source.forSecondaryLocale(allowsFallback: false) {
                        if secondarySourceInSecondaryLang != primaryDisplayString {
                            Text("\(secondarySourceInSecondaryLang)\(showLocaleKey ? " (\(localeToStringDict[DoriAPI.secondaryLocale] ?? "?"))" : "")")
                                .foregroundStyle(.secondary)
                        }
                    } else if let secondarySourceInJP = source.jp {
                        if secondarySourceInJP != primaryDisplayString {
                            Text("\(secondarySourceInJP)\(showLocaleKey ? " (JP)" : "")")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            })
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .foregroundStyle(.primary)
#else //TODO: REPLACEMENT!
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
                } else {
                    Text("")
                }
                if let secondarySourceInSecondaryLang = source.forSecondaryLocale(allowsFallback: false) {
                    if secondarySourceInSecondaryLang != primaryDisplayString {
                        Text("\(secondarySourceInSecondaryLang)\(showLocaleKey ? " (\(localeToStringDict[DoriAPI.secondaryLocale] ?? "?"))" : "")")
                            .foregroundStyle(.secondary)
                    }
                } else if let secondarySourceInJP = source.jp {
                    if secondarySourceInJP != primaryDisplayString {
                        Text("\(secondarySourceInJP)\(showLocaleKey ? " (JP)" : "")")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onHover { isHovering in
                self.isHovering = isHovering
            }
            .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                VStack(alignment: .trailing) {
                    ForEach(allLocaleTexts, id: \.self) { localeValue in
                        Text(localeValue)
                    }
                }
                .padding()
            }
#endif
        }
//        .onAppear {
//            //            ForEach([DoriAPI.Locale.jp, DoriAPI.Locale.en, DoriAPI.Locale.tw, DoriAPI.Locale.cn, DoriAPI.Locale.kr], id: \.self) { localeValue in
//            //                if let targetValue = source.forLocale(localeValue) {
//            //                    Text("\(targetValue)")
//            //                    //Text("\(targetValue) (\(localeLabelDict[localeValue]!))")
//            //                }
//            //            }
//            for lang in [DoriAPI.Locale.jp, DoriAPI.Locale.en, DoriAPI.Locale.tw, DoriAPI.Locale.cn, DoriAPI.Locale.kr] {
//                if let pendingString = source.forLocale(lang) {
//                    if !allLocaleTexts.contains(pendingString) {
//                        allLocaleTexts.append("\(pendingString)\(showLocaleKey ? " (\(localeToStringDict[lang] ?? "?"))" : "")")
//                    }
//                }
//            }
//        }
    }
}

// This View does not check for Locale availablity.
struct CountdownText: View {
    let event: DoriFrontend.Event.Event
    let locale: DoriAPI.Locale
    var body: some View {
        Group {
            if let startDate = event.startAt.forLocale(locale),
               let endDate = event.endAt.forLocale(locale),
               let aggregateEndDate = event.aggregateEndAt.forLocale(locale),
               let distributionStartDate = event.distributionStartAt.forLocale(locale) {
                    if startDate > .now {
                        Text("Event.countdown.start-at.\(Text(startDate, style: .relative))")
                    } else if endDate > .now {
                        Text("Event.countdown.end-at.\(Text(endDate, style: .relative))")
                    } else if aggregateEndDate > .now {
                        Text("Event.countdown.result-in.\(Text(endDate, style: .relative))")
                    } else if distributionStartDate > .now {
                        Text("Event.countdown.rewards-in.\(Text(endDate, style: .relative))")
                    } else {
                        Text("Event.countdown.completed")
                    }
            }
        }
    }
}


/*
 if let startDate = information.event.startAt.forPreferredLocale(),
 let endDate = information.event.endAt.forPreferredLocale(),
 let aggregateEndDate = information.event.aggregateEndAt.forPreferredLocale(),
 let distributionStartDate = information.event.distributionStartAt.forPreferredLocale() {
 VStack(alignment: .leading) {
 Text("倒计时")
 .font(.system(size: 16, weight: .medium))
 Group {
 if startDate > .now {
 Text("\(Text(startDate, style: .relative))后开始")
 } else if endDate > .now {
 Text("\(Text(endDate, style: .relative))后结束")
 } else if aggregateEndDate > .now {
 Text("结果公布于\(Text(endDate, style: .relative))后")
 } else if distributionStartDate > .now {
 Text("奖励颁发于\(Text(endDate, style: .relative))后")
 } else {
 Text("已完结")
 }
 }
 .font(.system(size: 14))
 .opacity(0.6)
 }
 }
 */
