//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardDetailView.swift
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

struct CardDetailView: View {
    var id: Int
    @State var information: DoriFrontend.Card.ExtendedCard?
    @State var statsView = 0
    @State var statsCustomLevel = 1
    @State var statsCustomMasterRank = 4
    @State var statsCustomViewedStoryCount = 2
    @State var statsCustomTrained = true
    @State var availability = true
    var body: some View {
        List {
            if let information {
                Section {
                    CardCardView(information.card)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    if let text = information.card.gachaText.forPreferredLocale() {
                        HStack {
                            Spacer(minLength: 0)
                            Text(text)
                                .multilineTextAlignment(.center)
                            Spacer(minLength: 0)
                        }
                        Button("播放语音", systemImage: "play.fill") {
                            playAudio(url: information.card.gachaVoiceURL)
                        }
                    }
                }
                Section {
                    VStack(alignment: .leading) {
                        Text("标题")
                            .font(.system(size: 16, weight: .medium))
                        Text(information.card.prefix.forPreferredLocale() ?? "")
                            .font(.system(size: 14))
                            .opacity(0.6)
                    }
                    VStack(alignment: .leading) {
                        Text("种类")
                            .font(.system(size: 16, weight: .medium))
                        Text(information.card.type.localizedString)
                            .font(.system(size: 14))
                            .opacity(0.6)
                    }
                    VStack(alignment: .leading) {
                        Text("角色")
                            .font(.system(size: 16, weight: .medium))
                        HStack {
                            WebImage(url: information.character.iconImageURL)
                                .resizable()
                                .clipShape(Circle())
                                .frame(width: 20, height: 20)
                            Text(information.character.characterName.forPreferredLocale() ?? "")
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("乐团")
                            .font(.system(size: 16, weight: .medium))
                        HStack {
                            WebImage(url: information.band.iconImageURL)
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text(information.band.bandName.forPreferredLocale() ?? "")
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("属性")
                            .font(.system(size: 16, weight: .medium))
                        HStack {
                            WebImage(url: information.card.attribute.iconImageURL)
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text(information.card.attribute.rawValue.uppercased())
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("稀有度")
                            .font(.system(size: 16, weight: .medium))
                        HStack {
                            ForEach(1...information.card.rarity, id: \.self) { _ in
                                Image(information.card.rarity >= 4 ? .trainedStar : .star)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("技能")
                            .font(.system(size: 16, weight: .medium))
                        Text(information.skill.maximumDescription.forPreferredLocale() ?? "")
                            .font(.system(size: 14))
                            .opacity(0.6)
                    }
                    if let text = information.card.gachaText.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("招募语")
                                .font(.system(size: 16, weight: .medium))
                            Text(text)
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    }
                    if let date = information.card.releasedAt.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("发布日期")
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
                        Text(verbatim: "ID")
                            .font(.system(size: 16, weight: .medium))
                        Text(String(id))
                            .font(.system(size: 14))
                            .opacity(0.6)
                    }
                }
                .listRowBackground(Color.clear)
                if let minLevel = information.card.stat.minimumLevel,
                   let maxLevel = information.card.stat.maximumLevel {
                    Section {
                        statsViewSelector
                        if statsView == 2 {
                            Picker("星光等级", selection: $statsCustomMasterRank) {
                                ForEach(0...4, id: \.self) { i in
                                    Text(String(i)).tag(i)
                                }
                            }
                            if !information.card.episodes.isEmpty {
                                Picker("故事", selection: $statsCustomViewedStoryCount) {
                                    Text("未看").tag(0)
                                    Text("已看故事").tag(1)
                                    Text("已看故事和纪念故事").tag(2)
                                }
                            }
                            if information.card.stat[.training] != nil {
                                Toggle("特训", isOn: $statsCustomTrained)
                            }
                            Slider(
                                value: .init(get: { Double(statsCustomLevel) },
                                             set: { statsCustomLevel = Int($0) }),
                                in: Double(minLevel)...Double(maxLevel),
                                step: 1
                            )
                            .listRowInsets(.init(top: -1, leading: 0, bottom: -1, trailing: 0))
                        }
                        Group {
                            let stat = switch statsView {
                            case 0: information.card.stat.forMinimumLevel() ?? .zero
                            case 1: information.card.stat.maximumValue(rarity: information.card.rarity) ?? .zero
                            default: information.card.stat.calculated(
                                level: statsCustomLevel,
                                rarity: information.card.rarity,
                                masterRank: statsCustomMasterRank,
                                viewedStoryCount: statsCustomViewedStoryCount,
                                trained: statsCustomTrained
                            ) ?? .zero
                            }
                            if 0...2 ~= statsView {
                                VStack(alignment: .leading) {
                                    Text(verbatim: "等级")
                                        .font(.system(size: 16, weight: .medium))
                                    Text({
                                        switch statsView {
                                        case 0: "\(minLevel)"
                                        case 1: "\(maxLevel)"
                                        default: "\(statsCustomLevel)"
                                        }
                                    }())
                                    .font(.system(size: 14))
                                    .opacity(0.6)
                                }
                                VStack(alignment: .leading) {
                                    Text(verbatim: "演出")
                                        .font(.system(size: 16, weight: .medium))
                                    Text(String(stat.performance))
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                }
                                VStack(alignment: .leading) {
                                    Text(verbatim: "技巧")
                                        .font(.system(size: 16, weight: .medium))
                                    Text(String(stat.technique))
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                }
                                VStack(alignment: .leading) {
                                    Text(verbatim: "形象")
                                        .font(.system(size: 16, weight: .medium))
                                    Text(String(stat.visual))
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                }
                                VStack(alignment: .leading) {
                                    Text(verbatim: "综合")
                                        .font(.system(size: 16, weight: .medium))
                                    Text(String(stat.total))
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                }
                            } else {
                                VStack(alignment: .leading) {
                                    Text(verbatim: "名字")
                                        .font(.system(size: 16, weight: .medium))
                                    Text(information.card.skillName.forPreferredLocale() ?? "")
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                }
                                VStack(alignment: .leading) {
                                    Text(verbatim: "效果")
                                        .font(.system(size: 16, weight: .medium))
                                    Text(information.skill.simpleDescription.forPreferredLocale() ?? "")
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                }
                                VStack(alignment: .leading) {
                                    Text(verbatim: "完整效果")
                                        .font(.system(size: 16, weight: .medium))
                                    Text(information.skill.description.forPreferredLocale() ?? "")
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                }
                                VStack(alignment: .leading) {
                                    Text(verbatim: "持续时间")
                                        .font(.system(size: 16, weight: .medium))
                                    Text(information.skill.duration.map { String(format: "%.1f", $0) }.joined(separator: ", "))
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    } header: {
                        Text("数据")
                    }
                    Section {
                        NavigationLink(destination: { CostumeLive2DViewer(id: information.costume.id).ignoresSafeArea() }) {
                            ThumbCostumeCardView(information.costume)
                        }
                    } header: {
                        Text("服装")
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
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入卡牌时出错", systemImage: "person.text.rectangle.fill", retryHandler: getInformation)
                }
            }
        }
        .navigationTitle(information?.card.prefix.forPreferredLocale() ?? "正在载入卡牌...")
        .task {
            await getInformation()
        }
    }
    
    func getInformation() async {
        availability = true
        DoriCache.withCache(id: "CardDetail_\(id)") {
            await DoriFrontend.Card.extendedInformation(of: id)
        }.onUpdate {
            if let information = $0 {
                self.information = information
                statsCustomLevel = information.card.stat.maximumLevel ?? 1
            } else {
                availability = false
            }
        }
    }
    
    @ViewBuilder
    private var statsViewSelector: some View {
        ScrollView(.horizontal) {
            HStack {
                Spacer()
                    .frame(width: 10)
                Button("最小") {
                    statsView = 0
                }
                .opacity(statsView == 0 ? 1 : 0.6)
                Spacer()
                    .frame(width: 20)
                Button("最大") {
                    statsView = 1
                }
                .opacity(statsView == 1 ? 1 : 0.6)
                Spacer()
                    .frame(width: 20)
                Button("自定") {
                    statsView = 2
                }
                .opacity(statsView == 2 ? 1 : 0.6)
                Spacer()
                    .frame(width: 20)
                Button("技能") {
                    statsView = 3
                }
                .opacity(statsView == 3 ? 1 : 0.6)
                Spacer()
                    .frame(width: 10)
            }
            .scrollTargetLayout()
            .buttonStyle(.plain)
        }
        .scrollIndicators(.never)
        .scrollTargetBehavior(.viewAligned)
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}
