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
    var applyLocaleFilter: Bool = false
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var cardsSorted: [PreviewCard] = []
    @State var displayingCards: [PreviewCard] = []
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if !displayingCards.isEmpty {
                        ForEach((showAll ? displayingCards : Array(displayingCards.prefix(3))), id: \.self) { item in
                            NavigationLink(destination: {
                                CardDetailView(id: item.id)
                            }, label: {
                                CardInfo(item)
                            })
                            .buttonStyle(.plain)
                        }
                    } else {
                        CustomGroupBox {
                            ContentUnavailableView("Details.cards.unavailable", systemImage: "person.crop.square.on.square.angled")
                        }
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.cards")
                        .font(.title2)
                        .bold()
                    if applyLocaleFilter {
                        DetailsLocalePicker(locale: $locale)
                    }
                    
                    Spacer()
                    if displayingCards.count > 3 {
                        Button(action: {
                            showAll.toggle()
                        }, label: {
                            Text(showAll ? "Details.show-less" : "Details.show-all.\(displayingCards.count)")
                                .foregroundStyle(.secondary)
                        })
                        .buttonStyle(.plain)
                    }
                    
                }
                .frame(maxWidth: 615)
            })
        }
        .onAppear {
            cardsSorted = cards.sorted{compare($0.releasedAt.jp?.corrected(),$1.releasedAt.jp?.corrected())}
            if applyLocaleFilter {
                displayingCards = cardsSorted.filter{$0.releasedAt.availableInLocale(locale)}
            } else {
                displayingCards = cardsSorted
            }
        }
        .onChange(of: locale) {
            if applyLocaleFilter {
                displayingCards = cardsSorted.filter{$0.releasedAt.availableInLocale(locale)}
            }
        }
    }
}

// MARK: DetailsEventsSection
struct DetailsEventsSection: View {
    var events: [PreviewEvent]
    var applyLocaleFilter: Bool = false
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var eventsSorted: [PreviewEvent] = []
    @State var displayingEvents: [PreviewEvent] = []
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if !displayingEvents.isEmpty {
                        ForEach((showAll ? displayingEvents : Array(displayingEvents.prefix(3))), id: \.self) { item in
                            NavigationLink(destination: {
                                EventDetailView(id: item.id)
                            }, label: {
                                EventInfo(item, preferHeavierFonts: false, showDetails: true)
                                    .scaledToFill()
                                    .frame(maxWidth: 600)
                                    .scaledToFill()
                            })
                            .buttonStyle(.plain)
                        }
                    } else {
                        CustomGroupBox {
                            ContentUnavailableView("Details.events.unavailable", systemImage: "star.hexagon")
                        }
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.events")
                        .font(.title2)
                        .bold()
                    if applyLocaleFilter {
                        DetailsLocalePicker(locale: $locale)
                    }
                    Spacer()
                    if displayingEvents.count > 3 {
                        Button(action: {
                            showAll.toggle()
                        }, label: {
                            Text(showAll ? "Details.show-less" : "Details.show-all.\(displayingEvents.count)")
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
            if applyLocaleFilter {
                displayingEvents = eventsSorted.filter{$0.startAt.availableInLocale(locale)}
            } else {
                displayingEvents = eventsSorted
            }
        }
        .onChange(of: locale) {
            if applyLocaleFilter {
                displayingEvents = eventsSorted.filter{$0.startAt.availableInLocale(locale)}
            }
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

struct DetailsLocalePicker: View {
    @Binding var locale: DoriLocale
    var body: some View {
        Menu(content: {
            Picker(selection: $locale, content: {
                ForEach(DoriLocale.allCases, id: \.self) { item in
                    Text(item.selectorText)
                        .tag(item)
                }
            }, label: {
                Text("")
            })
            .pickerStyle(.inline)
            .labelsHidden()
            .multilineTextAlignment(.leading)
        }, label: {
            Text(getAttributedString(locale.selectorText, fontSize: .title2, fontWeight: .semibold, foregroundColor: .accent))
        })
        .menuIndicator(.hidden)
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
    }
}
