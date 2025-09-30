//===---*- Greatdori! -*---------------------------------------------------===//
//
// LoginCampaignSearchView.swift
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

// MARK: LoginCampaignSearchView
struct LoginCampaignSearchView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    //    @State var filterClass: DoriFrontend.LoginCampaignsFilter
    @State var filter = DoriFrontend.Filter()
    @State var sorter = DoriFrontend.Sorter(keyword: .releaseDate(in: .jp), direction: .descending)
    @State var loginCampaigns: [PreviewLoginCampaign]?
    @State var searchedLoginCampaigns: [PreviewLoginCampaign]?
    @State var infoIsAvailable = true
    @State var searchedText = ""
    @State var showDetails = true
    @State var showFilterSheet = false
    @State var presentingLoginCampaignID: Int?
    @Namespace var loginCampaignLists
    var body: some View {
        Group {
            Group {
                if let resultLoginCampaigns = searchedLoginCampaigns ?? loginCampaigns {
                    Group {
                        if !resultLoginCampaigns.isEmpty {
                            ScrollView {
                                HStack {
                                    Spacer(minLength: 0)
                                    ViewThatFits {
                                        LazyVStack(spacing: showDetails ? nil : bannerSpacing) {
                                            let loginCampaigns = resultLoginCampaigns.chunked(into: 2)
                                            ForEach(loginCampaigns, id: \.self) { loginCampaignGroup in
                                                HStack(spacing: showDetails ? nil : bannerSpacing) {
                                                    Spacer(minLength: 0)
                                                    ForEach(loginCampaignGroup) { loginCampaign in
                                                        Button(action: {
                                                            showFilterSheet = false
                                                            presentingLoginCampaignID = loginCampaign.id
                                                        }, label: {
                                                            LoginCampaignInfo(loginCampaign, preferHeavierFonts: true, inLocale: nil, showDetails: showDetails, searchedKeyword: $searchedText)
                                                                .frame(maxWidth: bannerWidth)
                                                        })
                                                        .buttonStyle(.plain)
                                                        .wrapIf(true, in: { content in
                                                            if #available(iOS 18.0, macOS 15.0, *) {
                                                                content
                                                                    .matchedTransitionSource(id: loginCampaign.id, in: loginCampaignLists)
                                                            } else {
                                                                content
                                                            }
                                                        })
                                                        .matchedGeometryEffect(id: loginCampaign.id, in: loginCampaignLists)
                                                        if loginCampaignGroup.count == 1 && loginCampaigns[0].count != 1 {
                                                            Rectangle()
                                                                .frame(maxWidth: 420, maxHeight: 140)
                                                                .opacity(0)
                                                        }
                                                    }
                                                    Spacer(minLength: 0)
                                                }
                                            }
                                        }
                                        .frame(width: bannerWidth * 2 + bannerSpacing)
                                        LazyVStack(spacing: showDetails ? nil : bannerSpacing) {
                                            ForEach(resultLoginCampaigns, id: \.self) { loginCampaign in
                                                Button(action: {
                                                    showFilterSheet = false
                                                    presentingLoginCampaignID = loginCampaign.id
                                                }, label: {
                                                    LoginCampaignInfo(loginCampaign, preferHeavierFonts: true, inLocale: nil, showDetails: showDetails, searchedKeyword: $searchedText)
                                                        .frame(maxWidth: bannerWidth)
                                                })
                                                .buttonStyle(.plain)
                                                .wrapIf(true, in: { content in
                                                    if #available(iOS 18.0, macOS 15.0, *) {
                                                        content
                                                            .matchedTransitionSource(id: loginCampaign.id, in: loginCampaignLists)
                                                    } else {
                                                        content
                                                    }
                                                })
                                                .matchedGeometryEffect(id: loginCampaign.id, in: loginCampaignLists)
                                            }
                                        }
                                        .frame(maxWidth: bannerWidth)
                                    }
                                    .padding(.horizontal)
                                    .animation(.spring(duration: 0.3, bounce: 0.1, blendDuration: 0), value: showDetails)
                                    Spacer(minLength: 0)
                                }
                            }
                            .geometryGroup()
                            .navigationDestination(item: $presentingLoginCampaignID) { id in
                                LoginCampaignDetailView(id: id, allLoginCampaigns: loginCampaigns)
                                #if !os(macOS)
                                    .wrapIf(true, in: { content in
                                        if #available(iOS 18.0, macOS 15.0, *) {
                                            content
                                                .navigationTransition(.zoom(sourceID: id, in: loginCampaignLists))
                                        } else {
                                            content
                                        }
                                    })
                                #endif
                            }
                        } else {
                            ContentUnavailableView("Search.no-results", systemImage: "magnifyingglass", description: Text("Search.no-results.description"))
                        }
                    }
                    .onSubmit {
                        if let loginCampaigns {
                            searchedLoginCampaigns = loginCampaigns.search(for: searchedText)
                        }
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
                        }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView("Login-campaign.search.unavailable", systemImage: "line.horizontal.star.fill.line.horizontal", description: Text("Search.unavailable.description"))
                                .onTapGesture {
                                    Task {
                                        await getLoginCampaigns()
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $searchedText, prompt: "Login-campaign.search.placeholder")
            .navigationTitle("Login-campaign")
            .wrapIf(searchedLoginCampaigns != nil, in: { content in
                if #available(iOS 26.0, *) {
                    content.navigationSubtitle((searchedText.isEmpty && !filter.isFiltered) ? "Login-campaign.count.\(searchedLoginCampaigns!.count)" :  "Search.result.\(searchedLoginCampaigns!.count)")
                } else {
                    content
                }
            })
            .toolbar {
                ToolbarItem {
                    LayoutPicker(selection: $showDetails, options: [("Filter.view.banner-and-details", "text.below.rectangle", true), ("Filter.view.banner-only", "rectangle.grid.1x2", false)])
                }
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                ToolbarItemGroup {
                    FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: PreviewLoginCampaign.applicableSortingTypes, hasEndingDate: true)
                }
            }
            .onDisappear {
                showFilterSheet = false
            }
        }
        .withSystemBackground()
        .inspector(isPresented: $showFilterSheet) {
            FilterView(filter: $filter, includingKeys: Set(PreviewLoginCampaign.applicableFilteringKeys))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
        .withSystemBackground() // This modifier MUST be placed BOTH before
                                // and after `inspector` to make it work as expected
        .task {
            await getLoginCampaigns()
        }
        .onChange(of: filter) {
            if let loginCampaigns {
                searchedLoginCampaigns = loginCampaigns.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: sorter) {
            if loginCampaigns != nil {
                searchedLoginCampaigns = loginCampaigns!.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: searchedText, {
            if let loginCampaigns {
                searchedLoginCampaigns = loginCampaigns.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        })
    }
    
    func getLoginCampaigns() async {
        infoIsAvailable = true
        DoriCache.withCache(id: "LoginCampaignList_\(filter.identity)", trait: .realTime) {
            await DoriFrontend.LoginCampaign.list()
        } .onUpdate {
            if let loginCampaigns = $0 {
                self.loginCampaigns = loginCampaigns.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending))
                searchedLoginCampaigns = loginCampaigns.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            } else {
                infoIsAvailable = false
            }
        }
    }
}
