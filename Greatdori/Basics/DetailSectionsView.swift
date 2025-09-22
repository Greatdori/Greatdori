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

// MARK: DetailsCardSection
struct DetailsCardsSection: View {
    var cards: [PreviewCard]
    @State var cardsSorted: [PreviewCard] = []
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                ForEach((showAll ? cardsSorted : Array(cardsSorted.prefix(3))), id: \.self) { item in
                    NavigationLink(destination: {
                        CardDetailView(id: item.id)
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
                    if cardsSorted.count > 3 {
                        Button(action: {
                            showAll.toggle()
                        }, label: {
                            Text(showAll ? "Details.show-less" : "Details.show-all.\(cardsSorted.count)")
                                .foregroundStyle(.secondary)
                            //                        .font(.caption)
                        })
                        .buttonStyle(.plain)
                    }
                    //                .alignmentGuide(.bottom, computeValue: 0)
                    
                }
                .frame(maxWidth: 615)
//                .shadow(radius: 10)
                //            .border(.red)
            })
        }
        .onAppear {
            cardsSorted = cards.sorted{compare($0.releasedAt.jp?.corrected(),$1.releasedAt.jp?.corrected())}
        }
    }
}

// MARK: DetailsEventsSection
struct DetailsEventsSection: View {
    var events: [PreviewEvent]
    @State var eventsSorted: [PreviewEvent] = []
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                ForEach((showAll ? eventsSorted : Array(eventsSorted.prefix(3))), id: \.self) { item in
                    NavigationLink(destination: {
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
                    if eventsSorted.count > 3 {
                        Button(action: {
                            showAll.toggle()
                        }, label: {
                            Text(showAll ? "Details.show-less" : "Details.show-all.\(eventsSorted.count)")
                                .foregroundStyle(.secondary)
                            //                        .font(.caption)
                        })
                        .buttonStyle(.plain)
                    }
                    //                .alignmentGuide(.bottom, computeValue: 0)
                    
                }
                .frame(maxWidth: 615)
                //            .border(.red)
            })
        }
        .onAppear {
            eventsSorted = events.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: .jp)))
        }
    }
}

// MARK: DetailsGachasSection
struct DetailsGachasSection: View {
    var gachas: [PreviewGacha]
    @State var gachasSorted: [PreviewGacha] = []
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                ForEach((showAll ? gachasSorted : Array(gachasSorted.prefix(3))), id: \.self) { item in
                    NavigationLink(destination: {
                        GachaDetailView(id: item.id)
                    }, label: {
                        GachaInfo(item, preferHeavierFonts: false, showDetails: true)
                    })
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.gachas")
                        .font(.title2)
                        .bold()
                    Spacer()
                    if gachasSorted.count > 3 {
                        Button(action: {
                            showAll.toggle()
                        }, label: {
                            Text(showAll ? "Details.show-less" : "Details.show-all.\(gachasSorted.count)")
                                .foregroundStyle(.secondary)
                            //                        .font(.caption)
                        })
                        .buttonStyle(.plain)
                    }
                    //                .alignmentGuide(.bottom, computeValue: 0)
                    
                }
                .frame(maxWidth: 615)
                //            .border(.red)
            })
        }
        .onAppear {
            gachasSorted = gachas.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: .jp)))
        }
    }
}

// MARK: DetailsCostumesSection
struct DetailsCostumesSection: View {
    var costumes: [PreviewCostume]
    @State var costumesSorted: [PreviewCostume] = []
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                ForEach((showAll ? costumesSorted : Array(costumesSorted.prefix(3))), id: \.self) { item in
                    NavigationLink(destination: {
                        CostumeDetailView(id: item.id)
                    }, label: {
                        //                    CustomGroupBox {
                        CostumeInfo(item, preferHeavierFonts: false/*, showDetails: true*/)
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
                    Text("Details.costumes")
                        .font(.title2)
                        .bold()
                    Spacer()
                    if costumesSorted.count > 3 {
                        Button(action: {
                            showAll.toggle()
                        }, label: {
                            Text(showAll ? "Details.show-less" : "Details.show-all.\(costumesSorted.count)")
                                .foregroundStyle(.secondary)
                            //                        .font(.caption)
                        })
                        .buttonStyle(.plain)
                    }
                    //                .alignmentGuide(.bottom, computeValue: 0)
                    
                }
                .frame(maxWidth: 615)
                //            .border(.red)
            })
        }
        .onAppear {
            costumesSorted = costumes.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: .jp)))
        }
    }
}
