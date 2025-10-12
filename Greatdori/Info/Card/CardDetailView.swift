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


// MARK: CardDetailView
struct CardDetailView: View {
    var id: Int
    var allCards: [CardWithBand]? = nil
    var body: some View {
        DetailViewBase("Card", forType: ExtendedCard.self, previewList: allCards, initialID: id) { information in
            CardDetailOverviewView(information: information)
            CardDetailStatsView(card: information.card)
            DetailsCostumesSection(costumes: [information.costume])
            if !information.event.isEmpty || information.cardSource.containsSource(from: .event) {
                DetailsEventsSection(event: information.event, sources: information.cardSource)
            }
            if information.cardSource.containsSource(from: .gacha) {
                DetailsGachasSection(sources: information.cardSource)
            }
        } switcherDestination: {
            CardSearchView()
        }
    }
}


// MARK: CardDetailOverviewView
struct CardDetailOverviewView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let information: ExtendedCard
    @State private var allSkills: [Skill] = []
    let cardCoverScalingFactor: CGFloat = 1
    var body: some View {
        DetailInfoBase {
            DetailInfoItem("Card.title", text: information.card.prefix)
            DetailInfoItem("Card.type", text: information.card.type.localizedString)
            DetailInfoItem("Card.character") {
                NavigationLink(destination: {
                    CharacterDetailView(id: information.character.id)
                }, label: {
                    HStack {
                        MultilingualText(information.character.characterName)
                        WebImage(url: information.character.iconImageURL)
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: imageButtonSize, height: imageButtonSize)
                    }
                })
            }
            DetailInfoItem("Card.band") {
                HStack {
                    MultilingualText(information.band.bandName, allowPopover: false)
                    WebImage(url: information.band.iconImageURL)
                        .resizable()
                        .frame(width: imageButtonSize, height: imageButtonSize)
                }
            }
            DetailInfoItem("Card.attribute") {
                HStack {
                    Text(information.card.attribute.selectorText.uppercased())
                    WebImage(url: information.card.attribute.iconImageURL)
                        .resizable()
                        .frame(width: imageButtonSize, height: imageButtonSize)
                }
            }
            DetailInfoItem("Card.rarity") {
                HStack(spacing: 0) {
                    ForEach(1...information.card.rarity, id: \.self) { _ in
                        Image(information.card.rarity >= 3 ? .trainedStar : .star)
                            .resizable()
                            .frame(width: imageButtonSize, height: imageButtonSize)
                            .padding(.top, -1)
                    }
                }
            }
            if let skill = allSkills.first(where: { $0.id == information.card.skillID }) {
                DetailInfoItem("Card.skill", text: skill.maximumDescription)
            }
            if !information.card.gachaText.isValueEmpty {
                DetailInfoItem("Card.gacha-quote", text: information.card.gachaText)
            }
            DetailInfoItem("Card.release-date", date: information.card.releasedAt)
                .showsLocaleKey()
            DetailInfoItem("ID", text: "\(String(information.id))")
        } head: {
            CardCoverImage(information.card, band: information.band)
                .wrapIf(sizeClass == .regular) { content in
                    content
                        .frame(maxWidth: 480*cardCoverScalingFactor, maxHeight: 320*cardCoverScalingFactor)
                } else: { content in
                    content
                }
        }
        .task {
            // Load skills asynchronously once when the view appears
            if allSkills.isEmpty {
                if let fetched = await Skill.all() {
                    allSkills = fetched
                }
            }
        }
    }
}
