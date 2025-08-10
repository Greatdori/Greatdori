//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaDetailView.swift
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

struct GachaDetailView: View {
    var id: Int
    @State var information: DoriFrontend.Gacha.ExtendedGacha?
    @State var availability = true
    @State var cardListPresentation: [DoriFrontend.Card.PreviewCard]?
    @State var cardDetailPresentation: Int?
    var body: some View {
        List {
            if let information {
                Section {
                    WebImage(url: information.gacha.bannerImageURL)
                        .resizable()
                        .scaledToFit()
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init())
                }
                Section {
                    VStack(alignment: .leading) {
                        Text("标题")
                            .font(.system(size: 16, weight: .medium))
                        Text(information.gacha.gachaName.forPreferredLocale() ?? "")
                            .font(.system(size: 14))
                            .opacity(0.6)
                    }
                    VStack(alignment: .leading) {
                        Text("种类")
                            .font(.system(size: 16, weight: .medium))
                        Text(information.gacha.type.localizedString)
                            .font(.system(size: 14))
                            .opacity(0.6)
                    }
                    if let publishedDate = information.gacha.publishedAt.forPreferredLocale(),
                       let closedDate = information.gacha.closedAt.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("倒计时")
                                .font(.system(size: 16, weight: .medium))
                            Group {
                                if publishedDate > .now {
                                    Text("\(Text(publishedDate, style: .relative))后开始")
                                } else if closedDate > .now {
                                    Text("\(Text(closedDate, style: .relative))后结束")
                                } else {
                                    Text("已完结")
                                }
                            }
                            .font(.system(size: 14))
                            .opacity(0.6)
                        }
                    }
                    if let date = information.gacha.publishedAt.forPreferredLocale() {
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
                    if let date = information.gacha.closedAt.forPreferredLocale() {
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
                    if !information.pickupCards.isEmpty {
                        VStack(alignment: .leading) {
                            Text("PICK UP 成员卡牌")
                                .font(.system(size: 16, weight: .medium))
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(information.pickupCards) { card in
                                        CardIconView(card)
                                    }
                                }
                            }
                            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                            .scrollIndicators(.never)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("说明")
                            .font(.system(size: 16, weight: .medium))
                        Text(information.gacha.description.forPreferredLocale() ?? "")
                            .font(.system(size: 14))
                            .opacity(0.6)
                    }
                }
                .listRowBackground(Color.clear)
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
                if !information.cardDetails.isEmpty, let rates = information.gacha.rates.forPreferredLocale() {
                    Section {
                        let keys = rates.keys.sorted(by: >)
                        ForEach(keys, id: \.self) { key in
                            if rates[key]!.weightTotal > 0 {
                                HStack {
                                    Text(verbatim: "\(rates[key]!.rate)%")
                                    HStack(spacing: 1) {
                                        ForEach(1...key, id: \.self) { _ in
                                            Image(key > 2 ? .trainedStar : .star)
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                        }
                                    }
                                    Spacer()
                                }
                                .listRowBackground(Color.clear)
                                if let _details = information.gacha.details.forPreferredLocale() {
                                    let details = _details.filter { $0.value.rarityIndex == key }
                                    if details.contains(where: { $0.value.pickup }) {
                                        let pickups = details.filter { $0.value.pickup }
                                        Button(action: {
                                            if pickups.count > 1 {
                                                cardListPresentation = information.cardDetails[key]!.filter { pickups.map { $0.key }.contains($0.id) }
                                            } else {
                                                cardDetailPresentation = pickups.first!.key
                                            }
                                        }, label: {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(verbatim: "\(String(format: "%.2f", Double(pickups.first!.value.weight) / Double(rates[key]!.weightTotal) * rates[key]!.rate))%")
                                                    Spacer()
                                                    Text("\(pickups.count)张")
                                                        .font(.system(size: 13))
                                                        .opacity(0.6)
                                                }
                                                Spacer()
                                                CardIconView(information.cardDetails[key]!.first(where: { $0.id == pickups.first!.key })!)
                                            }
                                        })
                                    }
                                    let nonPickups = details.filter { !$0.value.pickup }
                                    Button(action: {
                                        if nonPickups.count > 1 {
                                            cardListPresentation = information.cardDetails[key]!.filter { nonPickups.map { $0.key }.contains($0.id) }
                                        } else {
                                            cardDetailPresentation = nonPickups.first!.key
                                        }
                                    }, label: {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(verbatim: "\(String(format: "%.2f", Double(nonPickups.first!.value.weight) / Double(rates[key]!.weightTotal) * rates[key]!.rate))%")
                                                Spacer()
                                                Text("\(nonPickups.count)张")
                                                    .font(.system(size: 13))
                                                    .opacity(0.6)
                                            }
                                            Spacer()
                                            CardIconView(information.cardDetails[key]!.first(where: { $0.id == nonPickups.first!.key })!)
                                        }
                                    })
                                }
                            }
                        }
                    } header: {
                        Text("卡牌")
                    }
                }
                if !information.gacha.paymentMethods.isEmpty {
                    Section {
                        ForEach(information.gacha.paymentMethods, id: \.self) { paymentMethod in
                            VStack(alignment: .leading) {
                                Text("\(paymentMethod.count)次抽卡")
                                    .font(.system(size: 16, weight: .medium))
                                HStack {
                                    WebImage(url: paymentMethod.paymentMethod.iconImageURL)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text(verbatim: "\(paymentMethod.paymentMethod.localizedString) x\(paymentMethod.count)")
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                }
                                if paymentMethod.behavior != .normal {
                                    Text(verbatim: "\(paymentMethod.behavior.localizedString)" + (paymentMethod.maxSpinLimit != nil ? ", " + String(localized: "最多\(paymentMethod.maxSpinLimit!)次") : ""))
                                        .font(.system(size: 13))
                                        .opacity(0.6)
                                }
                            }
                        }
                    } header: {
                        Text("消耗星石")
                    }
                    .listRowBackground(Color.clear)
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入招募时出错", systemImage: "line.horizontal.star.fill.line.horizontal", retryHandler: getInformation)
                }
            }
        }
        .navigationTitle(information?.gacha.gachaName.forPreferredLocale() ?? String(localized: "正在载入招募..."))
        .task {
            await getInformation()
        }
        .navigationDestination(item: $cardDetailPresentation) { id in
            CardDetailView(id: id)
        }
        .sheet(item: $cardListPresentation) { cards in
            List {
                ForEach(cards) { card in
                    Button(action: {
                        cardListPresentation = nil
                        cardDetailPresentation = card.id
                    }, label: {
                        ThumbCardCardView(card)
                    })
                }
            }
        }
    }
    
    func getInformation() async {
        availability = true
        DoriCache.withCache(id: "GachaDetail_\(id)") {
            await DoriFrontend.Gacha.extendedInformation(of: id)
        }.onUpdate {
            if let information = $0 {
                self.information = information
            } else {
                availability = false
            }
        }
    }
}

extension Array<DoriFrontend.Card.PreviewCard>: @retroactive @preconcurrency Identifiable {
    public var id: String {
        self.reduce(into: "") { partialResult, card in
            partialResult += String(card.id)
        }
    }
}
