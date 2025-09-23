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

// MARK: DetailsEventsSection
struct DetailsEventsSection: View {
    var events: [PreviewEvent]
    var sources: DoriAPI.LocalizedData<Set<DoriAPI.Card.Card.CardSource>>?
    var applyLocaleFilter: Bool = false
//    var withSourceSubtitle: Bool
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var eventsSorted: [PreviewEvent] = []
    @State var finalEvents: [Int] = []
    @State var finalSource: [Int: Int] = [:]
    @State var eventDict: [Int: PreviewEvent] = [:]
    @State var showAll = false
    
    init(events: [PreviewEvent], applyLocaleFilter: Bool = false) {
        self.events = events
        self.sources = nil
        self.applyLocaleFilter = applyLocaleFilter
//        self.withSourceSubtitle = false
    }
    
    init(events: [PreviewEvent], sources: DoriAPI.LocalizedData<Set<DoriAPI.Card.Card.CardSource>>) {
        self.events = events
        self.sources = sources
        self.applyLocaleFilter = true
//        self.withSourceSubtitle = true
    }
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if !eventsSorted.isEmpty {
                        ForEach((showAll ? finalEvents : Array(finalEvents.prefix(3))), id: \.self) { item in
                            let eventItem = eventDict[item]
                            NavigationLink(destination: {
                                EventDetailView(id: item)
                            }, label: {
                                if let event = eventDict[item] {
                                    EventInfo(event, preferHeavierFonts: false, subtitle: sources == nil ? nil : "Details.source.release-during-event", showDetails: true)
                                        .scaledToFill()
                                        .frame(maxWidth: 600)
                                        .scaledToFill()
                                } else {
                                    EventInfo(id: item, preferHeavierFonts: false, subtitle: sources == nil ? nil : "Details.events.source.rewarded-at-points.\(finalSource[item] ?? 0)", showDetails: true)
                                        .scaledToFill()
                                        .frame(maxWidth: 600)
                                        .scaledToFill()
                                }
                            })
                            .buttonStyle(.plain)
                        }
                    } else {
                        DetailUnavailableView(title: "Details.events.unavailable", symbol: "star.hexagon")
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.events")
                        .font(.title2)
                        .bold()
                    if applyLocaleFilter {
                        DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
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
            })
        }
        .onAppear {
            handleEvents()
        }
        .onChange(of: locale) {
            handleEvents()
        }
    }
    
    func handleEvents() {
        eventsSorted = events.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: applyLocaleFilter ? locale : .jp)))
        if applyLocaleFilter {
            eventsSorted = eventsSorted.filter{$0.startAt.availableInLocale(locale)}
        }
        
        if let sources {
            print("AAA \(sources)")
            for item in Array(sources.forLocale(locale) ?? Set()) {
                switch item {
                case .event(let dict):
                    for (key, value) in dict {
                        finalEvents.append(key)
                        finalSource.updateValue(value, forKey: key)
                    }
                    finalEvents.sort {compareWithinNormalRange($0, $1, largetAcceptableNumber: 1000, ascending: true)}
                default: break
                }
            }
        }
        finalEvents = eventsSorted.map{$0.id} + finalEvents
        for item in eventsSorted {
            eventDict.updateValue(item, forKey: item.id)
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
                        DetailUnavailableView(title: "Details.gachas.unavailable", symbol: "line.horizontal.star.fill.line.horizontal")
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.gachas")
                        .font(.title2)
                        .bold()
                    if applyLocaleFilter {
                        DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
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
                        DetailUnavailableView(title: "Details.costumes.unavailable", symbol: "swatchpalette")
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.costumes")
                        .font(.title2)
                        .bold()
                    if applyLocaleFilter {
                        DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
//                        DetailsLocalePicker(locale: $locale)
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

struct DetailSectionOptionPicker<T: Hashable>: View {
    @Binding var selection: T
    var options: [T]
    var labels: [T: String]? = nil
    var body: some View {
        Menu(content: {
            Picker(selection: $selection, content: {
                ForEach(options, id: \.self) { item in
                    Text(labels?[item] ?? ((T.self == DoriLocale.self) ? "\(item)".uppercased() : "\(item)"))
                        .tag(item)
                }
            }, label: {
                Text("")
            })
            .pickerStyle(.inline)
            .labelsHidden()
            .multilineTextAlignment(.leading)
        }, label: {
            Text(getAttributedString(labels?[selection] ?? ((T.self == DoriLocale.self) ? "\(selection)".uppercased() : "\(selection)"), fontSize: .title2, fontWeight: .semibold, foregroundColor: .accent))
        })
        .menuIndicator(.hidden)
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
    }
}

struct DetailSectionsSpacer: View {
    var body: some View {
        Rectangle()
            .opacity(0)
            .frame(height: 30)
    }
}

struct DetailUnavailableView: View {
    var title: LocalizedStringKey
    var symbol: String
    var body: some View {
        CustomGroupBox {
            HStack {
                Spacer()
                VStack {
                    Image(systemName: symbol)
                        .font(.largeTitle)
                        .padding(.top, 2)
                        .padding(.bottom, 1)
                    Text(title)
                        .font(.title2)
                        .padding(.bottom, 2)
                }
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
}

