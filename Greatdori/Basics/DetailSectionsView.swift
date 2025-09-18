//===---*- Greatdori! -*---------------------------------------------------===//
//
// ListSectionsView.swift
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
import SwiftUI

//struct ListGachaView: View {
//    @State var locale: DoriAPI.Locale = DoriAPI.preferredLocale
//    var body: some View {
//        VStack {
//            HStack {
//                Text("Details.gacha")
//                HStack {
//                    Picker(selection: $locale, content: {
//                        ForEach(DoriAPI.Locale.allCases, id: \.self) { locale in
//                            Text(locale.rawValue.uppercased())
//                                .tag(locale)
//                        }
//                    }, label: {
//                        Text("")
//                    })
//                    .labelsHidden()
//                }
//            }
//        }
//    }
//}

// MARK: DetailsCardSection
struct DetailsCardsSection: View {
    var cards: [PreviewCard]
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                ForEach((showAll ? cards : Array(cards.prefix(3))), id: \.self) { item in
                    NavigationLink(destination: {
                        //                    [NAVI785]
                    }, label: {
                        CardInfo(item)
                    })
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.cards")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button(action: {
                        showAll.toggle()
                    }, label: {
                        Text(showAll ? "Details.show-less" : "Details.show-all.\(cards.count)")
                            .foregroundStyle(.secondary)
                        //                        .font(.caption)
                    })
                    .buttonStyle(.plain)
                    //                .alignmentGuide(.bottom, computeValue: 0)
                    
                }
                .frame(maxWidth: 615)
                .shadow(radius: 10)
                //            .border(.red)
            })
        }
    }
}

// MARK: DetailsEventsSection
struct DetailsEventsSection: View {
    var events: [PreviewEvent]
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                ForEach((showAll ? events : Array(events.prefix(3))), id: \.self) { item in
                    NavigationLink(destination: {
                        //                    [NAVI785]
                        EventDetailView(id: item.id)
                    }, label: {
                        //                    CustomGroupBox {
                        EventInfo(item, preferHeavierFonts: false, showDetails: true)
                            .scaledToFill()
                            .frame(maxWidth: 600)
                            .scaledToFill()
                        //                    }
                    })
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.events")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button(action: {
                        showAll.toggle()
                    }, label: {
                        Text(showAll ? "Details.show-less" : "Details.show-all.\(events.count)")
                            .foregroundStyle(.secondary)
                        //                        .font(.caption)
                    })
                    .buttonStyle(.plain)
                    //                .alignmentGuide(.bottom, computeValue: 0)
                    
                }
                .frame(maxWidth: 615)
                //            .border(.red)
            })
        }
    }
}
