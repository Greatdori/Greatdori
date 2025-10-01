//===---*- Greatdori! -*---------------------------------------------------===//
//
// CostumeDetailView.swift
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

import SwiftUI
import DoriKit
import SDWebImageSwiftUI

// MARK: CostumeDetailView
struct CostumeDetailView: View {
    var id: Int
    var allCostumes: [PreviewCostume]? = nil
    var body: some View {
        DetailViewBase("Costume", previewList: allCostumes, initialID: id) { information in
            CostumeDetailOverviewView(information: information)
            if !information.cards.isEmpty {
                DetailsCardsSection(cards: information.cards)
            }
        }
    }
}

// MARK: CostumeDetailOverviewView
struct CostumeDetailOverviewView: View {
    let information: ExtendedCostume
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    var body: some View {
        VStack {
            Group {
                // MARK: Title Image
                Group {
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                    // FIXME: Replace image with Live2D viewer
                    WebImage(url: information.costume.thumbImageURL) { image in
                        image
                            .antialiased(true)
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(getPlaceholderColor())
                    }
                    .interpolation(.high)
                    .frame(width: 96, height: 96)
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                }
                
                
                // MARK: Info
                CustomGroupBox(cornerRadius: 20) {
                    LazyVStack {
                        // MARK: Description
                        Group {
                            ListItemView(title: {
                                Text("Costume.title")
                                    .bold()
                            }, value: {
                                MultilingualText(information.costume.description)
                            })
                            Divider()
                        }
                        
                        // MARK: Character
                        Group {
                            ListItemView(title: {
                                Text("Costume.character")
                                    .bold()
                            }, value: {
                                NavigationLink(destination: {
                                    CharacterDetailView(id: information.character.id)
                                }, label: {
                                    Text(information.character.characterName.forPreferredLocale() ?? "Unknown")
                                    WebImage(url: information.character.iconImageURL)
                                        .resizable()
                                        .interpolation(.high)
                                        .antialiased(true)
                                        .frame(width: 30, height: 30)
                                })
                                .buttonStyle(.plain)
                            })
                            Divider()
                        }
                        
                        // MARK: Band
                        Group {
                            ListItemView(title: {
                                Text("Costume.band")
                                    .bold()
                            }, value: {
                                Text(information.band.bandName.forPreferredLocale() ?? "Unknown")
                                WebImage(url: information.band.iconImageURL)
                                    .resizable()
                                    .interpolation(.high)
                                    .antialiased(true)
                                    .frame(width: 30, height: 30)
                            })
                            Divider()
                        }
                        
                        // MARK: Release Date
                        Group {
                            ListItemView(title: {
                                Text("Costume.release-date")
                                    .bold()
                            }, value: {
                                MultilingualText(information.costume.publishedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            })
                            Divider()
                        }
                        
                        if !information.costume.howToGet.isValueEmpty {
                            // MARK: How to Get
                            Group {
                                ListItemView(title: {
                                    Text("Costume.how-to-get")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.costume.howToGet)
                                }, displayMode: .basedOnUISizeClass)
                                Divider()
                            }
                        }
                        
                        // MARK: ID
                        Group {
                            ListItemView(title: {
                                Text("ID")
                                    .bold()
                            }, value: {
                                Text("\(String(information.costume.id))")
                            })
                        }
                        
                    }
                }
            }
        }
        .frame(maxWidth: 600)
    }
}
