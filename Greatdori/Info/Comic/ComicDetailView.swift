//===---*- Greatdori! -*---------------------------------------------------===//
//
// ComicDetailView.swift
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


// MARK: ComicDetailView
struct ComicDetailView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var id: Int
    var allComics: [Comic]? = nil
    @State var comicID: Int = 0
    @State var informationLoadPromise: CachePromise<Comic?>?
    @State var information: Comic?
    @State var infoIsAvailable = true
    @State var cardNavigationDestinationID: Int?
    @State var allComicIDs: [Int] = []
    @State var showSubtitle: Bool = false
    var body: some View {
        EmptyContainer {
            if let information {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            // FIXME: Implement `ComicDetailOverviewView` first
                            //                            ComicDetailOverviewView(information: information, cardNavigationDestinationID: $cardNavigationDestinationID)
                            
                            //                            if !information.cards.isEmpty {
                            //                                Rectangle()
                            //                                    .opacity(0)
                            //                                    .frame(height: 30)
                            //                                DetailsCardsSection(cards: information.cards)
                            //                            }
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
                            await getInformation(id: comicID)
                        }
                    }, label: {
                        ExtendedConstraints {
                            ContentUnavailableView("Comic.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
                        }
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .withSystemBackground()
        .navigationDestination(item: $cardNavigationDestinationID, destination: { id in
            Text("\(id)")
        })
        .navigationTitle(Text(information?.title.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Comic") : "")"))
#if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.subTitle.forPreferredLocale() != nil ? "#\(comicID)" : "")
            } else {
                content
            }
        }
#endif
        .onAppear {
            Task {
                if (allComics ?? []).isEmpty {
                    allComicIDs = await (Event.all() ?? []).sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending)).map {$0.id}
                } else {
                    allComicIDs = allComics!.map {$0.id}
                }
            }
        }
        .onChange(of: comicID, {
            Task {
                await getInformation(id: comicID)
            }
        })
        .task {
            comicID = id
            await getInformation(id: comicID)
        }
        .toolbar {
            ToolbarItemGroup(content: {
                DetailsIDSwitcher(currentID: $comicID, allIDs: allComicIDs, destination: { ComicSearchView() })
                    .onChange(of: comicID) {
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
        informationLoadPromise = DoriCache.withCache(id: "ComicDetail_\(id)", trait: .realTime) {
            await Comic(id: id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
            } else {
                infoIsAvailable = false
            }
        }
    }
}

// FIXME
// MARK: ComicDetailOverviewView
//struct ComicDetailOverviewView: View {
//    let information: Comic
//    @State var cardsArray: [DoriFrontend.Card.PreviewCard] = []
//    @State var cardsArraySeperated: [[DoriFrontend.Card.PreviewCard?]] = []
//    @State var cardsPercentage: Int = -100
//    @State var rewardsArray: [DoriFrontend.Card.PreviewCard] = []
//    @State var cardsTitleWidth: CGFloat = 0 // Fixed
//    @State var cardsPercentageWidth: CGFloat = 0 // Fixed
//    @State var cardsContentRegularWidth: CGFloat = 0 // Fixed
//    @State var cardsFixedWidth: CGFloat = 0 //Fixed
//    @State var cardsUseCompactLayout = true
//    @Binding var cardNavigationDestinationID: Int?
//    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
//    var body: some View {
//        VStack {
//            Group {
//                // MARK: Title Image
//                Group {
//                    Rectangle()
//                        .opacity(0)
//                        .frame(height: 2)
//                    // FIXME: Replace image with Live2D viewer
//                    WebImage(url: information.thumbImageURL) { image in
//                        image
//                            .antialiased(true)
//                            .resizable()
//                            .scaledToFit()
//                    } placeholder: {
//                        RoundedRectangle(cornerRadius: 10)
//                            .fill(getPlaceholderColor())
//                    }
//                    .interpolation(.high)
//                    .frame(width: 96, height: 96)
//                    Rectangle()
//                        .opacity(0)
//                        .frame(height: 2)
//                }
//
//
//                // MARK: Info
//                CustomGroupBox(cornerRadius: 20) {
//                    LazyVStack {
//                        // MARK: Description
//                        Group {
//                            ListItemView(title: {
//                                Text("Comic.title")
//                                    .bold()
//                            }, value: {
//                                MultilingualText(information.description)
//                            })
//                            Divider()
//                        }
//
//                        // MARK: Character
//                        Group {
//                            ListItemView(title: {
//                                Text("Comic.character")
//                                    .bold()
//                            }, value: {
//                                // FIXME: This requires `ExtendedComic` to be
//                                // FIXME: implemented in DoriKit.
//                            })
//                            Divider()
//                        }
//
//                        // MARK: Band
//                        Group {
//                            ListItemView(title: {
//                                Text("Comic.band")
//                                    .bold()
//                            }, value: {
//                                // FIXME: This requires `ExtendedComic` to be
//                                // FIXME: implemented in DoriKit.
//                            })
//                            Divider()
//                        }
//
//                        // MARK: Release Date
//                        Group {
//                            ListItemView(title: {
//                                Text("Comic.release-date")
//                                    .bold()
//                            }, value: {
//                                MultilingualText(information.publishedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
//                            })
//                            Divider()
//                        }
//
//                        if !information.howToGet.isValueEmpty {
//                            // MARK: How to Get
//                            Group {
//                                ListItemView(title: {
//                                    Text("Comic.how-to-get")
//                                        .bold()
//                                }, value: {
//                                    MultilingualText(information.howToGet)
//                                }, displayMode: .basedOnUISizeClass)
//                                Divider()
//                            }
//                        }
//
//                        // MARK: ID
//                        Group {
//                            ListItemView(title: {
//                                Text("ID")
//                                    .bold()
//                            }, value: {
//                                Text("\(String(information.id))")
//                            })
//                        }
//
//                    }
//                }
//            }
//        }
//        .frame(maxWidth: 600)
//    }
//}
