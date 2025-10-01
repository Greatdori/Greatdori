//===---*- Greatdori! -*---------------------------------------------------===//
//
// DetailCostumesSection.swift
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
                                CostumeInfo(item)
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
