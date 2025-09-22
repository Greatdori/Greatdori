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

// MARK: DetailsEventsSection
struct DetailsEventsSection: View {
    var events: [PreviewEvent]
    var applyLocaleFilter: Bool = false
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var eventsSorted: [PreviewEvent] = []
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if !eventsSorted.isEmpty {
                        ForEach((showAll ? eventsSorted : Array(eventsSorted.prefix(3))), id: \.self) { item in
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
            eventsSorted = events.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: applyLocaleFilter ? locale : .jp)))
            if applyLocaleFilter {
                eventsSorted = eventsSorted.filter{$0.startAt.availableInLocale(locale)}
            }
        }
        .onChange(of: locale) {
            eventsSorted = events.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: applyLocaleFilter ? locale : .jp)))
            if applyLocaleFilter {
                eventsSorted = eventsSorted.filter{$0.startAt.availableInLocale(locale)}
            }
        }
    }
}

// MARK: DetailsGachasSection
struct DetailsGachasSection: View {
    var gachas: [PreviewGacha]
    var applyLocaleFilter: Bool = false
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var gachasSorted: [PreviewGacha] = []
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if !gachasSorted.isEmpty {
                        ForEach((showAll ? gachasSorted : Array(gachasSorted.prefix(3))), id: \.self) { item in
                            NavigationLink(destination: {
                                GachaDetailView(id: item.id)
                            }, label: {
                                GachaInfo(item, preferHeavierFonts: false, showDetails: true)
                            })
                            .buttonStyle(.plain)
                        }
                    } else {
                        CustomGroupBox {
                            ContentUnavailableView("Details.gachas.unavailable", systemImage: "line.horizontal.star.fill.line.horizontal")
                        }
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.gachas")
                        .font(.title2)
                        .bold()
                    if applyLocaleFilter {
                        DetailsLocalePicker(locale: $locale)
                    }
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
            gachasSorted = gachas.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: applyLocaleFilter ? locale : .jp)))
            if applyLocaleFilter {
                gachasSorted = gachasSorted.filter{$0.publishedAt.availableInLocale(locale)}
            }
        }
        .onChange(of: locale) {
            gachasSorted = gachas.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: applyLocaleFilter ? locale : .jp)))
            if applyLocaleFilter {
                gachasSorted = gachasSorted.filter{$0.publishedAt.availableInLocale(locale)}
            }
        }
    }
}

// MARK: DetailsCostumesSection
struct DetailsCostumesSection: View {
    var costumes: [PreviewCostume]
    var applyLocaleFilter = false
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var costumesSorted: [PreviewCostume] = []
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if !costumesSorted.isEmpty {
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
                    } else {
                        CustomGroupBox {
                            ContentUnavailableView("Details.costumes.unavailable", systemImage: "swatchpalette")
                        }
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.costumes")
                        .font(.title2)
                        .bold()
                    if applyLocaleFilter {
                        DetailsLocalePicker(locale: $locale)
                    }
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
            costumesSorted = costumes.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: applyLocaleFilter ? locale : .jp)))
            if applyLocaleFilter {
                costumesSorted = costumesSorted.filter{$0.publishedAt.availableInLocale(locale)}
            }
        }
        .onChange(of: locale) {
            costumesSorted = costumes.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: applyLocaleFilter ? locale : .jp)))
            if applyLocaleFilter {
                costumesSorted = costumesSorted.filter{$0.publishedAt.availableInLocale(locale)}
            }
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
