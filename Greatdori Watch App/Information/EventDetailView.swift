//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailView.swift
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

struct EventDetailView: View {
    var id: Int
    @State var information: DoriFrontend.Event.ExtendedEvent?
    @State var availability = true
    var body: some View {
        List {
            if let information {
                Section {
                    WebImage(url: information.event.bannerImageURL)
                        .resizable()
                        .scaledToFit()
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init())
                }
                Section {
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
                            // if the card is contained in `members`, it is a card that has bonus in this event.
                            // if not, it should be shown in rewards section (the next one).
                            if let percent = information.event.members.first(where: { $0.situationID == card.id })?.percent {
                                HStack {
                                    NavigationLink(destination: { CardDetailView(id: card.id) }) {
                                        CardIconView(card)
                                    }
                                    .buttonStyle(.borderless)
                                    Text("+\(percent)%")
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("奖励")
                            .font(.system(size: 16, weight: .medium))
                        HStack {
                            ForEach(information.cards) { card in
                                if information.event.rewardCards.contains(card.id) {
                                    NavigationLink(destination: { CardDetailView(id: card.id) }) {
                                        CardIconView(card)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    }
                }
                .listRowBackground(Color.clear)
                if !information.gacha.isEmpty {
                    Section {
                        FoldableList(information.gacha.reversed()) { gacha in
                            NavigationLink(destination: { GachaDetailView(id: gacha.id) }) {
                                GachaCardView(gacha)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                    } header: {
                        Text("招募")
                    }
                }
                if !information.songs.isEmpty {
                    Section {
                        FoldableList(information.songs.reversed()) { song in
                            SongCardView(song)
                        }
                    } header: {
                        Text("歌曲")
                    }
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入活动时出错", systemImage: "star.hexagon.fill", retryHandler: getInformation)
                }
            }
        }
        .navigationTitle(information?.event.eventName.forPreferredLocale() ?? "正在载入活动...")
        .task {
            await getInformation()
        }
    }
    
    func getInformation() async {
        availability = true
        DoriCache.withCache(id: "EventDetail_\(id)") {
            await DoriFrontend.Event.extendedInformation(of: id)
        }.onUpdate {
            if let information = $0 {
                self.information = information
            } else {
                availability = false
            }
        }
    }
}
