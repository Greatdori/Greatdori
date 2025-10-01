//===---*- Greatdori! -*---------------------------------------------------===//
//
// DetailsGachasSection.swift
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
                                    GachaInfo(item)
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
                                    GachaInfo(item, subtitle: unsafe "Details.gachas.source.chance.\(String(format: "%.2f", (probabilityDict[item] ?? 0)*100) + String("%"))", showDetails: true)
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
