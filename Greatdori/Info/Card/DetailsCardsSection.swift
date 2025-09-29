//===---*- Greatdori! -*---------------------------------------------------===//
//
// DetailsCardsSection.swift
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


import DoriKit
import SDWebImageSwiftUI
import SwiftUI


// MARK: DetailsCardsSection
struct DetailsCardsSection: View {
    var cards: [PreviewCard]
    var applyLocaleFilter: Bool = false
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var cardsSorted: [PreviewCard] = []
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if !cardsSorted.isEmpty {
                        ForEach((showAll ? cardsSorted : Array(cardsSorted.prefix(3))), id: \.self) { item in
                            NavigationLink(destination: {
                                CardDetailView(id: item.id)
                            }, label: {
                                CardInfo(item)
                            })
                            .buttonStyle(.plain)
                        }
                    } else {
                        DetailUnavailableView(title: "Details.cards.unavailable", symbol: "person.crop.square.on.square.angled")
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.cards")
                        .font(.title2)
                        .bold()
                    if applyLocaleFilter {
                        DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
                    }
                    Spacer()
                    if cardsSorted.count > 3 {
                        Button(action: {
                            showAll.toggle()
                        }, label: {
                            Text(showAll ? "Details.show-less" : "Details.show-all.\(cardsSorted.count)")
                                .foregroundStyle(.secondary)
                        })
                        .buttonStyle(.plain)
                    }
                    
                }
                .frame(maxWidth: 615)
            })
        }
        .onAppear {
            cardsSorted = cards.sorted{compare($0.releasedAt.forLocale(applyLocaleFilter ? locale : .jp)?.corrected(),$1.releasedAt.forLocale(applyLocaleFilter ? locale : .jp)?.corrected())}
            if applyLocaleFilter {
                cardsSorted = cardsSorted.filter{$0.releasedAt.availableInLocale(locale)}
            }
        }
        .onChange(of: locale) {
            cardsSorted = cards.sorted{compare($0.releasedAt.forLocale(applyLocaleFilter ? locale : .jp)?.corrected(),$1.releasedAt.forLocale(applyLocaleFilter ? locale : .jp)?.corrected())}
            if applyLocaleFilter {
                cardsSorted = cardsSorted.filter{$0.releasedAt.availableInLocale(locale)}
            }
        }
    }
}
