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
    var body: some View {
        List {
            if let cards {
                ForEach(cards, id: \.card.id) { card in
                    ThumbCardCardView(card.card, band: card.band)
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
        .task {
            await getCards()
        }
    }
    
    func getCards() async {
        cards = await DoriFrontend.Card.list(filter: filter)
    }
}
