//
//  CharacterDetailView.swift
//  Greatdori
//
//  Created by Mark Chan on 7/23/25.
//

import SwiftUI
import DoriKit
import SDWebImageSwiftUI

struct CharacterDetailView: View {
    var id: Int
    @State var information: DoriFrontend.Character.ExtendedCharacter?
    @State var randomCard: DoriAPI.Card.PreviewCard?
    @State var isCardsExpanded = false
    @State var isCostumesExpanded = false
    @State var isEventsExpanded = false
    @State var isGachaExpanded = false
    var body: some View {
        List {
            if let information {
                if let randomCard, let band = information.band {
                    Section {
                        NavigationLink(destination: {  }) {
                            CardCardView(randomCard, band: band)
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
                            Text("\(birthday.components(in: .init(identifier: "Asia/Tokyo")!).month!)月\(birthday.components(in: .init(identifier: "Asia/Tokyo")!).day!)日")
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
                if !information.cards.isEmpty, let band = information.band {
                    Section {
                        ForEach(information.cards.reversed()) { card in
                            if isCardsExpanded || card.id == information.cards.last?.id {
                                ThumbCardCardView(card, band: band)
                            }
                        }
                        if information.cards.count > 1 {
                            Button(isCardsExpanded ? "收起" : "显示所有", systemImage: isCardsExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical") {
                                isCardsExpanded.toggle()
                            }
                        }
                    } header: {
                        Text("卡牌")
                    }
                }
                if !information.costumes.isEmpty {
                    Section {
                        ForEach(information.costumes.reversed()) { costume in
                            if isCostumesExpanded || costume.id == information.costumes.last?.id {
                                ThumbCostumeCardView(costume)
                            }
                        }
                        if information.costumes.count > 1 {
                            Button(isCostumesExpanded ? "收起" : "显示所有", systemImage: isCostumesExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical") {
                                isCostumesExpanded.toggle()
                            }
                        }
                    } header: {
                        Text("服装")
                    }
                }
                if !information.events.isEmpty {
                    Section {
                        ForEach(information.events.reversed()) { event in
                            if isEventsExpanded || event.id == information.events.last?.id {
                                EventCardView(event, inLocale: nil)
                            }
                        }
                        if information.events.count > 1 {
                            Button(isEventsExpanded ? "收起" : "显示所有", systemImage: isEventsExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical") {
                                isEventsExpanded.toggle()
                            }
                        }
                    } header: {
                        Text("活动")
                    }
                }
                if !information.gacha.isEmpty {
                    Section {
                        ForEach(information.gacha.reversed()) { gacha in
                            if isGachaExpanded || gacha.id == information.gacha.last?.id {
                                GachaCardView(gacha)
                            }
                        }
                        if information.gacha.count > 1 {
                            Button(isGachaExpanded ? "收起" : "显示所有", systemImage: isGachaExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical") {
                                isGachaExpanded.toggle()
                            }
                        }
                    } header: {
                        Text("招募")
                    }
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .animation(.default, value: isCardsExpanded)
        .animation(.default, value: isCostumesExpanded)
        .animation(.default, value: isEventsExpanded)
        .animation(.default, value: isGachaExpanded)
        .navigationTitle(information?.character.characterName.forPreferredLocale() ?? String(localized: "正在载入角色..."))
        .task {
            information = await DoriFrontend.Character.extendedInformation(of: id)
            if let information {
                randomCard = information.randomCard()
            }
        }
    }
}
