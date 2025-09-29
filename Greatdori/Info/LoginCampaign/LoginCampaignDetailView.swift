//===---*- Greatdori! -*---------------------------------------------------===//
//
// LoginCampaignDetailView.swift
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


// MARK: LoginCampaignDetailView
struct LoginCampaignDetailView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var id: Int
    var allLoginCampaigns: [PreviewLoginCampaign]? = nil
    @State var loginCampaignID: Int = 0
    @State var informationLoadPromise: DoriCache.Promise<LoginCampaign?>?
    @State var information: LoginCampaign?
    @State var infoIsAvailable = true
    @State var cardNavigationDestinationID: Int?
    //    @State var latestLoginCampaignID: Int = 0
    @State var allLoginCampaignIDs: [Int] = []
    @State var showSubtitle: Bool = false
    var body: some View {
        EmptyContainer {
            if let information {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
//                            LoginCampaignDetailOverviewView(information: information, cardNavigationDestinationID: $cardNavigationDestinationID)
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
                            await getInformation(id: loginCampaignID)
                        }
                    }, label: {
                        ExtendedConstraints {
                            ContentUnavailableView("LoginCampaign.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
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
        .navigationTitle(Text(information?.caption.forPreferredLocale() ?? "\(isMACOS ? String(localized: "LoginCampaign") : "")"))
        #if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.loginCampaign.loginCampaignName.forPreferredLocale() != nil ? "#\(loginCampaignID)" : "")
            } else {
                content
            }
        }
        #endif
        .onAppear {
            Task {
                if (allLoginCampaigns ?? []).isEmpty {
                    allLoginCampaignIDs = await (Event.all() ?? []).sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending)).map {$0.id}
                } else {
                    allLoginCampaignIDs = allLoginCampaigns!.map {$0.id}
                    //                print(allEventIDs)
                }
            }
        }
        .onChange(of: loginCampaignID, {
            Task {
                await getInformation(id: loginCampaignID)
            }
        })
        .task {
            loginCampaignID = id
            await getInformation(id: loginCampaignID)
        }
        .toolbar {
            ToolbarItemGroup(content: {
                DetailsIDSwitcher(currentID: $loginCampaignID, allIDs: allLoginCampaignIDs, destination: { LoginCampaignSearchView() })
                    .onChange(of: loginCampaignID) {
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
        informationLoadPromise = DoriCache.withCache(id: "LoginCampaignDetail_\(id)", trait: .realTime) {
            await LoginCampaign(id: id)
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
// MARK: LoginCampaignDetailOverviewView
//struct LoginCampaignDetailOverviewView: View {
//    let information: DoriFrontend.LoginCampaign.ExtendedLoginCampaign
//    //    @State var loginCampaignCharacterPercentageDict: [Int: [DoriAPI.LoginCampaign.LoginCampaignCharacter]] = [:]
//    //    @State var loginCampaignCharacterNameDict: [Int: DoriAPI.LocalizedData<String>] = [:]
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
//                    WebImage(url: information.loginCampaign.bannerImageURL) { image in
//                        image
//                            .antialiased(true)
//                            .resizable()
//                        //                            .aspectRatio(3.0, contentMode: .fit)
//                            .scaledToFit()
//                            .frame(maxWidth: bannerWidth,/* maxHeight: bannerWidth/3*/)
//                    } placeholder: {
//                        RoundedRectangle(cornerRadius: 10)
//                        //                            .fill(Color.gray.opacity(0.15))
//                            .fill(getPlaceholderColor())
//                            .aspectRatio(3.0, contentMode: .fit)
//                            .frame(maxWidth: bannerWidth, maxHeight: bannerWidth/3)
//                    }
//                    .interpolation(.high)
//                    .cornerRadius(10)
//                    Rectangle()
//                        .opacity(0)
//                        .frame(height: 2)
//                }
//                
//                
//                // MARK: Info
//                CustomGroupBox(cornerRadius: 20) {
//                    // Make this lazy fixes [250920-a] last appears in 8783d44.
//                    // Seems like a bug of SwiftUI, idk why make this lazy
//                    // fixes that bug. Whatever, it works.
//                    LazyVStack {
//                        // MARK: Title
//                        Group {
//                            ListItemView(title: {
//                                Text("LoginCampaign.title")
//                                    .bold()
//                            }, value: {
//                                MultilingualText(information.loginCampaign.loginCampaignName)
//                            })
//                            Divider()
//                        }
//                        
//                        // MARK: Type
//                        Group {
//                            ListItemView(title: {
//                                Text("LoginCampaign.type")
//                                    .bold()
//                            }, value: {
//                                Text(information.loginCampaign.type.localizedString)
//                            })
//                            Divider()
//                        }
//                        
//                        // MARK: Countdown
//                        Group {
//                            ListItemView(title: {
//                                Text("LoginCampaign.countdown")
//                                    .bold()
//                            }, value: {
//                                MultilingualTextForCountdown(information.loginCampaign)
//                            })
//                            Divider()
//                        }
//                        
//                        // MARK: Release Date
//                        Group {
//                            ListItemView(title: {
//                                Text("LoginCampaign.release-date")
//                                    .bold()
//                            }, value: {
//                                MultilingualText(information.loginCampaign.publishedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
//                            })
//                            Divider()
//                        }
//                        
//                        // MARK: Close Date
//                        Group {
//                            ListItemView(title: {
//                                Text("LoginCampaign.close-date")
//                                    .bold()
//                            }, value: {
//                                MultilingualText(information.loginCampaign.closedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
//                            })
//                            Divider()
//                        }
//                        
//                        //                        //MARK: Spotlight Card
//                        //                        if !cardsArray.isEmpty {
//                        //                            ListItemWithWrappingView(title: {
//                        //                                Text("Event.spotlight-card")
//                        //                                    .bold()
//                        //                            }, element: { value in
//                        //                                NavigationLink(destination: {
//                        //                                    //TODO: [NAVI785]CardD
//                        //                                    Text("\(value)")
//                        //                                }, label: {
//                        //                                    CardPreviewImage(value!, sideLength: cardThumbnailSideLength, showNavigationHints: true, cardNavigationDestinationID: $cardNavigationDestinationID)
//                        //                                })
//                        //                                .buttonStyle(.plain)
//                        //                            }, caption: nil, contentArray: cardsArray, columnNumbers: 3, elementWidth: cardThumbnailSideLength)
//                        //                            Divider()
//                        //                        }
//                        
//                        // MARK: Description
//                        Group {
//                            ListItemView(title: {
//                                Text("LoginCampaign.descripition")
//                                    .bold()
//                            }, value: {
//                                MultilingualText(information.loginCampaign.description)
//                            }, displayMode: .basedOnUISizeClass)
//                            Divider()
//                        }
//                        
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
