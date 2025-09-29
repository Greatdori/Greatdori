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
    @Environment(\.horizontalSizeClass) var sizeClass
    var id: Int
    var allCostumes: [PreviewCostume]? = nil
    @State var costumeID: Int = 0
    @State var informationLoadPromise: CachePromise<ExtendedCostume?>?
    @State var information: ExtendedCostume?
    @State var infoIsAvailable = true
    @State var allCostumeIDs: [Int] = []
    @State var showSubtitle: Bool = false
    var body: some View {
        EmptyContainer {
            if let information {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            CostumeDetailOverviewView(information: information)
                            
                            if !information.cards.isEmpty {
                                Rectangle()
                                    .opacity(0)
                                    .frame(height: 30)
                                DetailsCardsSection(cards: information.cards)
                            }
                        }
                        .padding()
                        Spacer(minLength: 0)
                    }
                }
                .scrollDisablesMultilingualTextPopover()
            } else {
                if infoIsAvailable {
                    ExtendedConstraints {
                        ProgressView()
                    }
                } else {
                    Button(action: {
                        Task {
                            await getInformation(id: costumeID)
                        }
                    }, label: {
                        ExtendedConstraints {
                            ContentUnavailableView("Costume.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
                        }
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .withSystemBackground()
        .navigationTitle(Text(information?.costume.description.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Costume") : "")"))
        #if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.costume.description.forPreferredLocale() != nil ? "#\(costumeID)" : "")
            } else {
                content
            }
        }
        #endif
        .onAppear {
            Task {
                if (allCostumes ?? []).isEmpty {
                    allCostumeIDs = await (Event.all() ?? []).sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending)).map {$0.id}
                } else {
                    allCostumeIDs = allCostumes!.map {$0.id}
                }
            }
        }
        .onChange(of: costumeID, {
            Task {
                await getInformation(id: costumeID)
            }
        })
        .task {
            costumeID = id
            await getInformation(id: costumeID)
        }
        .toolbar {
            ToolbarItemGroup(content: {
                DetailsIDSwitcher(currentID: $costumeID, allIDs: allCostumeIDs, destination: { CostumeSearchView() })
                    .onChange(of: costumeID) {
                        information = nil
                    }
                    .onAppear {
                        showSubtitle = (sizeClass == .compact)
                    }
            })
        }
    }
    
    func getInformation(id: Int) async {
        infoIsAvailable = true
        informationLoadPromise?.cancel()
        informationLoadPromise = DoriCache.withCache(id: "CostumeDetail_\(id)", trait: .realTime) {
            await ExtendedCostume(id: id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
            } else {
                infoIsAvailable = false
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
