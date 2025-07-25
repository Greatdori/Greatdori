//
//  CardListView.swift
//  Greatdori
//
//  Created by Mark Chan on 7/24/25.
//

import SwiftUI
import DoriKit

struct CardListView: View {
    @State var filter = DoriFrontend.Filter()
    @State var cards: [DoriFrontend.Card.CardWithBand]?
    @State var isFilterSettingsPresented = false
    @State var isSearchPresented = false
    @State var searchInput = ""
    var body: some View {
        List {
            if let cards {
                ForEach(cards, id: \.card.id) { card in
                    NavigationLink(destination: { CardDetailView(id: card.card.id) }) {
                        ThumbCardCardView(card.card, band: card.band)
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
            ])
        }
        .sheet(isPresented: $isSearchPresented) {
            if let cards {
                SearchView(items: cards.map { $0.card }, text: $searchInput) { result in
                    
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
                .tint(filter.isFiltered ? .accent : nil)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isSearchPresented = true
                }, label: {
                    Image(systemName: "magnifyingglass")
                })
            }
        }
        .task {
            await getCards()
        }
    }
    
    func getCards() async {
        cards = await DoriFrontend.Card.list(filter: filter)
    }
}
