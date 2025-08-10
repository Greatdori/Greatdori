//===---*- Greatdori! -*---------------------------------------------------===//
//
// CharacterDetailView.swift
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

struct CharacterDetailView: View {
    var id: Int
    @State var information: DoriFrontend.Character.ExtendedCharacter?
    @State var randomCard: DoriAPI.Card.PreviewCard?
    @State var availability = true
    var body: some View {
        List {
            if let information {
                if let randomCard {
                    Section {
                        NavigationLink(destination: { CardDetailView(id: randomCard.id) }) {
                            CardCardView(randomCard)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        Button("随机卡牌", systemImage: "arrow.clockwise") {
                            self.randomCard = information.randomCard()
                        }
                    }
                }
                Section {
                    if let name = information.character.characterName.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("名字")
                                .font(.system(size: 16, weight: .medium))
                            Text(name)
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    if let cv = information.character.profile?.characterVoice.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("配音")
                                .font(.system(size: 16, weight: .medium))
                            Text(cv)
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    if let color = information.character.color {
                        VStack(alignment: .leading) {
                            Text("颜色")
                                .font(.system(size: 16, weight: .medium))
                            HStack {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(color)
                                    .frame(width: 20, height: 20)
                                Text(String(color.description.dropLast(2)))
                                    .font(.system(size: 14))
                                    .opacity(0.6)
                            }
                        }
                    }
                    if let band = information.band {
                        VStack(alignment: .leading) {
                            Text("乐团")
                                .font(.system(size: 16, weight: .medium))
                            HStack {
                                WebImage(url: band.iconImageURL)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text(band.bandName.forPreferredLocale() ?? "")
                                    .font(.system(size: 14))
                                    .opacity(0.6)
                            }
                        }
                    }
                    if let part = information.character.profile?.part {
                        VStack(alignment: .leading) {
                            Text("位置")
                                .font(.system(size: 16, weight: .medium))
                            Text(part.localizedString)
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    if let birthday = information.character.profile?.birthday {
                        VStack(alignment: .leading) {
                            Text("生日")
                                .font(.system(size: 16, weight: .medium))
                            Text(birthdayDateFormatter.string(from: birthday))
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    if let constellation = information.character.profile?.constellation {
                        VStack(alignment: .leading) {
                            Text("星座")
                                .font(.system(size: 16, weight: .medium))
                            Text(constellation.localizedString)
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    if let height = information.character.profile?.height {
                        VStack(alignment: .leading) {
                            Text("身高")
                                .font(.system(size: 16, weight: .medium))
                            Text(verbatim: "\(height) cm")
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    if let school = information.character.profile?.school.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("学校")
                                .font(.system(size: 16, weight: .medium))
                            Text(school)
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    if let year = information.character.profile?.schoolYear.forPreferredLocale(),
                       let `class` = information.character.profile?.schoolClass.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("年 - 班")
                                .font(.system(size: 16, weight: .medium))
                            Text(verbatim: "\(year) - \(`class`)")
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    if let favoriteFood = information.character.profile?.favoriteFood.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("喜欢的食物")
                                .font(.system(size: 16, weight: .medium))
                            Text(favoriteFood)
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    if let hatedFood = information.character.profile?.hatedFood.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("讨厌的食物")
                                .font(.system(size: 16, weight: .medium))
                            Text(hatedFood)
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    if let hobby = information.character.profile?.hobby.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("爱好")
                                .font(.system(size: 16, weight: .medium))
                            Text(hobby)
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    if let intro = information.character.profile?.selfIntroduction.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("介绍")
                                .font(.system(size: 16, weight: .medium))
                            Text(intro)
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text(verbatim: "ID")
                            .font(.system(size: 16, weight: .medium))
                        Text(String(id))
                            .font(.system(size: 14))
                            .opacity(0.6)
                    }
                }
                .listRowBackground(Color.clear)
                if !information.cards.isEmpty {
                    Section {
                        FoldableList(information.cards.reversed()) { card in
                            NavigationLink(destination: { CardDetailView(id: card.id) }) {
                                ThumbCardCardView(card)
                            }
                        }
                    } header: {
                        Text("卡牌")
                    }
                }
                if !information.costumes.isEmpty {
                    Section {
                        FoldableList(information.costumes.reversed()) { costume in
                            NavigationLink(destination: { CostumeLive2DViewer(id: costume.id).ignoresSafeArea() }) {
                                ThumbCostumeCardView(costume)
                            }
                        }
                    } header: {
                        Text("服装")
                    }
                }
                if !information.events.isEmpty {
                    Section {
                        FoldableList(information.events.reversed()) { event in
                            NavigationLink(destination: { EventDetailView(id: event.id) }) {
                                EventCardView(event, inLocale: nil)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                    } header: {
                        Text("活动")
                    }
                }
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
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入角色时出错", systemImage: "person.fill", retryHandler: getInformation)
                }
            }
        }
        .navigationTitle(information?.character.characterName.forPreferredLocale() ?? String(localized: "正在载入角色..."))
        .task {
            await getInformation()
        }
    }
    
    var birthdayDateFormatter: DateFormatter {
        let result = DateFormatter()
        result.locale = Locale.current
        result.setLocalizedDateFormatFromTemplate("MMMd")
        result.timeZone = .init(identifier: "Asia/Tokyo")
        return result
    }
    
    func getInformation() async {
        availability = true
        DoriCache.withCache(id: "CharacterDetail_\(id)") {
            await DoriFrontend.Character.extendedInformation(of: id)
        }.onUpdate {
            if let information = $0 {
                self.information = information
                randomCard = information.randomCard()
            } else {
                availability = false
            }
        }
    }
}
