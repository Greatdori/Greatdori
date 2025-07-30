//
//  EventView.swift
//  Greatdori
//
//  Created by ThreeManager785 on 2025/7/29.
//

import SwiftUI
import DoriKit
import SDWebImageSwiftUI

let localeLabelDict: [DoriAPI.Locale: String] = [.jp: "JP", .en: "EN", .tw: "TW", .cn: "CN", .kr: "KR"]

struct EventDetailView: View {
    var id: Int
    @State var information: DoriFrontend.Event.ExtendedEvent?
    @State var infoIsAvailable = true // 785: ?
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
                                    Text(information.event.eventType.localizedString)
                                }
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
        .navigationTitle(information?.event.eventName.forPreferredLocale() ?? "#\(id)")
        .task {
            await getInformation()
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
    var body: some View {
        Menu(content: {
            ForEach([DoriAPI.Locale.jp, DoriAPI.Locale.en, DoriAPI.Locale.tw, DoriAPI.Locale.cn, DoriAPI.Locale.kr], id: \.self) { localeValue in
                if let targetValue = source.forLocale(localeValue) {
                    Text("\(targetValue)")
                    //Text("\(targetValue) (\(localeLabelDict[localeValue]!))")
                }
            }
            
        }, label: {
            VStack(alignment: .trailing) {
                Text(source.forPreferredLocale() ?? "Error")
                if let secondaryText = source.forSecondaryLocale(), secondaryText != source.forPreferredLocale() {
                    Text(secondaryText)
                        .foregroundStyle(.secondary)
                }
            }
        })
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .foregroundStyle(.primary)
    }
}
