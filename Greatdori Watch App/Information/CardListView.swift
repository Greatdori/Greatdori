//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardListView.swift
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

struct CardListView: View {
    @State var filter = DoriFrontend.Filter.recoverable(id: "CardList")
    @State var cards: [DoriFrontend.Card.CardWithBand]?
    @State var isFilterSettingsPresented = false
    @State var isSearchPresented = false
    @State var searchInput = ""
    @State var searchedCards: [DoriFrontend.Card.CardWithBand]?
    @State var availability = true
    var body: some View {
        List {
            if let cards = searchedCards ?? cards {
                ForEach(cards) { card in
                    NavigationLink(destination: { CardDetailView(id: card.card.id) }) {
                        ThumbCardCardView(card.card)
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
                    UnavailableView("载入卡牌时出错", systemImage: "person.text.rectangle.fill", retryHandler: getCards)
                }
            }
        }
        .navigationTitle("卡牌")
        .sheet(isPresented: $isFilterSettingsPresented) {
            Task {
                cards = nil
                await getCards()
            }
        } content: {
            FilterView(filter: $filter, includingKeys: [
                .band,
                .attribute,
                .rarity,
                .character,
                .server,
                .released,
                .cardType,
                .skill,
                .sort
            ]) {
                if let cards {
                    SearchView(items: cards, text: $searchInput) { result in
                        searchedCards = result
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isFilterSettingsPresented = true
                }, label: {
                    Image(systemName: "line.3.horizontal.decrease")
                })
                .tint(filter.isFiltered || !searchInput.isEmpty ? .accent : nil)
            }
        }
        .task {
            await getCards()
        }
    }
    
    func getCards() async {
        availability = true
        DoriCache.withCache(id: "CardList_\(filter.identity)") {
            await DoriFrontend.Card.list(filter: filter)
        }.onUpdate {
            if let cards = $0 {
                self.cards = cards
            } else {
                availability = false
            }
        }
    }
}
