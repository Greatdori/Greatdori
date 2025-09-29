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
import SDWebImageSwiftUI
import SwiftUI
#if os(macOS)
import QuickLook
#endif

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

// MARK: DetailsEventsSection
struct DetailsEventsSection: View {
    var events: [PreviewEvent]?
    var event: DoriAPI.LocalizedData<PreviewEvent>?
    var sources: DoriAPI.LocalizedData<Set<DoriFrontend.Card.ExtendedCard.Source>>?
    var applyLocaleFilter: Bool = false
    //    var withSourceSubtitle: Bool
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var eventsFromList: [PreviewEvent] = []
    @State var eventsFromSources: [PreviewEvent] = []
    @State var pointsDict: [PreviewEvent: Int] = [:]
    @State var showAll = false
    @State var sourcePreference: Int
    
    init(events: [PreviewEvent], applyLocaleFilter: Bool = false) {
        self.events = events
        self.event = nil
        self.sources = nil
        self.applyLocaleFilter = applyLocaleFilter
        //        self.withSourceSubtitle = false
        self.sourcePreference = 0
    }
    
    init(event: DoriAPI.LocalizedData<PreviewEvent>, sources: DoriAPI.LocalizedData<Set<DoriFrontend.Card.ExtendedCard.Source>>) {
        self.events = nil
        self.event = event
        self.sources = sources
        self.applyLocaleFilter = true
        //        self.withSourceSubtitle = true
        self.sourcePreference = 1
    }
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if getEventsCount() > 0 {
                        if sourcePreference == 0 {
                            ForEach((showAll ? eventsFromList : Array(eventsFromList.prefix(3))), id: \.self) { item in
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
                            ForEach((showAll ? eventsFromSources : Array(eventsFromSources.prefix(3))), id: \.self) { item in
                                NavigationLink(destination: {
                                    EventDetailView(id: item.id)
                                }, label: {
                                    EventInfo(item, preferHeavierFonts: false, subtitle: (pointsDict[item] == nil ? "Details.source.release-during-event" :"Details.events.source.rewarded-at-points.\(pointsDict[item]!)"), showDetails: true)
                                        .scaledToFill()
                                        .frame(maxWidth: 600)
                                        .scaledToFill()
                                })
                                .buttonStyle(.plain)
                            }
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
                    if getEventsCount() > 3 {
                        Button(action: {
                            showAll.toggle()
                        }, label: {
                            Text(showAll ? "Details.show-less" : "Details.show-all.\(getEventsCount())")
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
        eventsFromList = []
        eventsFromSources = []
        pointsDict = [:]
        
        if sourcePreference == 0 {
            if let events {
                eventsFromList = events.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: applyLocaleFilter ? locale : .jp)))
                if applyLocaleFilter {
                    eventsFromList = eventsFromList.filter{$0.startAt.availableInLocale(locale)}
                }
            }
        } else {
            if let sources {
                for item in Array(sources.forLocale(locale) ?? Set()) {
                    switch item {
                    case .event(let dict):
                        for (key, value) in dict {
                            eventsFromSources.append(key)
                            pointsDict.updateValue(value, forKey: key)
                        }
                        eventsFromSources = eventsFromSources.sorted(withDoriSorter: DoriSorter(keyword: .releaseDate(in: locale)))
                    default: break
                    }
                }
            }
            if let localEvent = event?.forLocale(locale) {
                eventsFromSources.insert(localEvent, at: 0)
            }
        }
    }
    
    func getEventsCount() -> Int {
        if sourcePreference == 0 {
            return eventsFromList.count
        } else {
            return eventsFromSources.count
        }
    }
}

// MARK: DetailsGachasSection
struct DetailsGachasSection: View {
    var gachas: [PreviewGacha]?
    var sources: DoriAPI.LocalizedData<Set<DoriFrontend.Card.ExtendedCard.Source>>?
    var applyLocaleFilter: Bool = false
    //    var withSourceSubtitle: Bool
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var gachasFromList: [PreviewGacha] = []
    @State var gachasFromSources: [PreviewGacha] = []
    @State var probabilityDict: [PreviewGacha: Double] = [:]
    @State var showAll = false
    @State var sourcePreference: Int
    
    init(gachas: [PreviewGacha], applyLocaleFilter: Bool = false) {
        self.gachas = gachas
        self.sources = nil
        self.applyLocaleFilter = applyLocaleFilter
        //        self.withSourceSubtitle = false
        self.sourcePreference = 0
    }
    
    init(sources: DoriAPI.LocalizedData<Set<DoriFrontend.Card.ExtendedCard.Source>>) {
        self.gachas = nil
        self.sources = sources
        self.applyLocaleFilter = true
        //        self.withSourceSubtitle = true
        self.sourcePreference = 1
    }
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if getGachasCount() > 0 {
                        if sourcePreference == 0 {
                            ForEach((showAll ? gachasFromList : Array(gachasFromList.prefix(3))), id: \.self) { item in
                                NavigationLink(destination: {
                                    GachaDetailView(id: item.id)
                                }, label: {
                                    GachaInfo(item, preferHeavierFonts: false, showDetails: true)
                                        .scaledToFill()
                                        .frame(maxWidth: 600)
                                        .scaledToFill()
                                })
                                .buttonStyle(.plain)
                            }
                        } else {
                            ForEach((showAll ? gachasFromSources : Array(gachasFromSources.prefix(3))), id: \.self) { item in
                                NavigationLink(destination: {
                                    GachaDetailView(id: item.id)
                                }, label: {
                                    GachaInfo(item, preferHeavierFonts: false, subtitle: unsafe "Details.gachas.source.chance.\(String(format: "%.2f", (probabilityDict[item] ?? 0)*100) + String("%"))", showDetails: true)
                                        .scaledToFill()
                                        .frame(maxWidth: 600)
                                        .scaledToFill()
                                })
                                .buttonStyle(.plain)
                            }
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
                    if getGachasCount() > 3 {
                        Button(action: {
                            showAll.toggle()
                        }, label: {
                            Text(showAll ? "Details.show-less" : "Details.show-all.\(getGachasCount())")
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
            handleGachas()
        }
        .onChange(of: locale) {
            handleGachas()
        }
    }
    
    func handleGachas() {
        gachasFromList = []
        gachasFromSources = []
        probabilityDict = [:]
        
        if sourcePreference == 0 {
            if let gachas {
                gachasFromList = gachas.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: applyLocaleFilter ? locale : .jp)))
                if applyLocaleFilter {
                    gachasFromList = gachasFromList.filter {$0.publishedAt.availableInLocale(locale)}
                }
            }
        } else {
            if let sources {
                for item in Array(sources.forLocale(locale) ?? Set()) {
                    switch item {
                    case .gacha(let dict):
                        for (key, value) in dict {
                            gachasFromSources.append(key)
                            probabilityDict.updateValue(value, forKey: key)
                        }
                        gachasFromSources = gachasFromSources.sorted(withDoriSorter: DoriSorter(keyword: .releaseDate(in: locale)))
                    default: break
                    }
                }
            }
        }
    }
    
    func getGachasCount() -> Int {
        if sourcePreference == 0 {
            return gachasFromList.count
        } else {
            return gachasFromSources.count
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

// MARK: DetailSectionOptionPicker
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

// MARK: DetailsSongsSection
struct DetailsSongsSection: View {
    var songs: [PreviewSong]
    var applyLocaleFilter: Bool = false
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var songsSorted: [PreviewSong] = []
    @State var showAll = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if !songsSorted.isEmpty {
                        ForEach((showAll ? songsSorted : Array(songsSorted.prefix(3))), id: \.self) { item in
                            NavigationLink(destination: {
                                SongDetailView(id: item.id)
                            }, label: {
                                SongInfo(item, preferHeavierFonts: false, layout: .horizontal)
                            })
                            .buttonStyle(.plain)
                        }
                    } else {
                        DetailUnavailableView(title: "Details.songs.unavailable", symbol: "person.crop.square.on.square.angled")
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.songs")
                        .font(.title2)
                        .bold()
                    if applyLocaleFilter {
                        DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
                    }
                    Spacer()
                    if songsSorted.count > 3 {
                        Button(action: {
                            showAll.toggle()
                        }, label: {
                            Text(showAll ? "Details.show-less" : "Details.show-all.\(songsSorted.count)")
                                .foregroundStyle(.secondary)
                        })
                        .buttonStyle(.plain)
                    }
                    
                }
                .frame(maxWidth: 615)
            })
        }
        .onAppear {
            songsSorted = songs.sorted(withDoriSorter: DoriSorter(keyword: .releaseDate(in: .jp)))
            if applyLocaleFilter {
                songsSorted = songsSorted.filter{$0.publishedAt.availableInLocale(locale)}
            }
        }
        .onChange(of: locale) {
            songsSorted = songs.sorted(withDoriSorter: DoriSorter(keyword: .releaseDate(in: .jp)))
            if applyLocaleFilter {
                songsSorted = songsSorted.filter{$0.publishedAt.availableInLocale(locale)}
            }
        }
    }
}

// MARK: DetailSectionsSpacer
struct DetailSectionsSpacer: View {
    var body: some View {
        Rectangle()
            .opacity(0)
            .frame(height: 30)
    }
}

// MARK: DetailUnavailableView
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

struct InfoArtsTab: Identifiable {
    let id: UUID = UUID()
    var tabName: LocalizedStringResource
    var content: [InfoArtsItem]
}

struct InfoArtsItem: Identifiable {
    let id = UUID()
    var title: LocalizedStringResource
    var url: URL
}

// MARK: DetailArtsSection
struct DetailArtsSection: View {
    var information: [InfoArtsTab]
    @State var tab: UUID? = nil
    #if os(macOS)
    @State private var previewController = PreviewController()
    #endif
    @State var showQuickLook = false
    @State var quickLookOnFocusItem: URL? = nil
    
    let itemMinimumWidth: CGFloat = 280
    let itemMaximumWidth: CGFloat = 320
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if let tab, let tabContent = information.first(where: {$0.id == tab}) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: itemMinimumWidth, maximum: itemMaximumWidth))]) {
                            ForEach(tabContent.content, id: \.id) { item in
                                Button(action: {
#if os(iOS)
                                    quickLookOnFocusItem = item.url
                                    showQuickLook = true
#else
                                    previewController.fileURLs = tabContent.content.map((\.url))
                                    previewController.showPanel()
#endif
                                }, label: {
                                    CustomGroupBox {
                                        VStack {
                                            WebImage(url: item.url) { image in
                                                image
                                                    .resizable()
                                                    .antialiased(true)
                                                    .scaledToFit()
                                            } placeholder: {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(getPlaceholderColor())
                                            }
                                            .interpolation(.high)
                                            Text(item.title)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                })
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        DetailUnavailableView(title: "Details.arts.unavailable", symbol: "photo.on.rectangle.angled")
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.arts")
                        .font(.title2)
                        .bold()
//                    if information.count > 1 {
                        DetailSectionOptionPicker(selection: $tab, options: information.map(\.id), labels: information.reduce(into: [UUID?: String]()) { $0.updateValue(String(localized: $1.tabName), forKey: $1.id) })
//                    }
                    Spacer()
                }
                .frame(maxWidth: 615)
            })
        }
        .onAppear {
            if !information.isEmpty {
                tab = information.first!.id
            }
        }
        .sheet(isPresented: $showQuickLook, content: {
            #if os(iOS)
            QuickLookPreview(url: quickLookOnFocusItem!)
            #endif
        })
    }
}
