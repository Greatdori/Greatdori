//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventSearchView.swift
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


// MARK: EventSearchView
struct EventSearchView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    @State var filter = DoriFrontend.Filter()
    @State var sorter = DoriFrontend.Sorter(keyword: .releaseDate(in: .jp), direction: .descending)
    @State var events: [DoriFrontend.Event.PreviewEvent]?
    @State var searchedEvents: [DoriFrontend.Event.PreviewEvent]?
    @State var infoIsAvailable = true
    @State var searchedText = ""
    @State var showDetails = true
    @State var showFilterSheet = false
    @State var presentingEventID: Int?
    @Namespace var eventLists
    var body: some View {
        Group {
            Group {
                if let resultEvents = searchedEvents ?? events {
                    Group {
                        if !resultEvents.isEmpty {
                            ScrollView {
                                HStack {
                                    Spacer(minLength: 0)
                                    ViewThatFits {
                                        LazyVStack(spacing: showDetails ? nil : bannerSpacing) {
                                            let events = resultEvents.chunked(into: 2)
                                            ForEach(events, id: \.self) { eventGroup in
                                                HStack(spacing: showDetails ? nil : bannerSpacing) {
                                                    Spacer(minLength: 0)
                                                    ForEach(eventGroup) { event in
                                                        Button(action: {
                                                            showFilterSheet = false
                                                            //                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                            presentingEventID = event.id
                                                            //                                                            }
                                                        }, label: {
                                                            EventInfo(event, showDetails: showDetails)
                                                                .highlightKeyword($searchedText)
                                                        })
                                                        .buttonStyle(.plain)
                                                        .wrapIf(true, in: { content in
                                                            if #available(iOS 18.0, macOS 15.0, *) {
                                                                content
                                                                    .matchedTransitionSource(id: event.id, in: eventLists)
                                                            } else {
                                                                content
                                                            }
                                                        })
                                                        .matchedGeometryEffect(id: event.id, in: eventLists)
                                                        if eventGroup.count == 1 && events[0].count != 1 {
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
                                            ForEach(resultEvents, id: \.self) { event in
                                                Button(action: {
                                                    showFilterSheet = false
                                                    //                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    presentingEventID = event.id
                                                    //                                                    }
                                                }, label: {
                                                    EventInfo(event, showDetails: showDetails)
                                                        .highlightKeyword($searchedText)
                                                        .frame(maxWidth: bannerWidth)
                                                })
                                                .buttonStyle(.plain)
                                                .wrapIf(true, in: { content in
                                                    if #available(iOS 18.0, macOS 15.0, *) {
                                                        content
                                                            .matchedTransitionSource(id: event.id, in: eventLists)
                                                    } else {
                                                        content
                                                    }
                                                })
                                                .matchedGeometryEffect(id: event.id, in: eventLists)
                                            }
                                        }
                                        .frame(maxWidth: bannerWidth)
                                    }
                                    .padding(.horizontal)
                                    .animation(.spring(duration: 0.3, bounce: 0.1, blendDuration: 0), value: showDetails)
                                    //                                    .animation(.easeInOut(duration: 0.2), value: showDetails)
                                    Spacer(minLength: 0)
                                }
                            }
                            .geometryGroup()
                            .navigationDestination(item: $presentingEventID) { id in
                                EventDetailView(id: id, allEvents: events)
#if !os(macOS)
                                    .wrapIf(true, in: { content in
                                        if #available(iOS 18.0, macOS 15.0, *) {
                                            content
                                                .navigationTransition(.zoom(sourceID: id, in: eventLists))
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
                        if let events {
                            searchedEvents = events.search(for: searchedText)
                        }
                    }
                } else {
                    if infoIsAvailable {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            Spacer()
                        }
                    } else {
                        ContentUnavailableView("Event.search.unavailable", systemImage: "line.horizontal.star.fill.line.horizontal", description: Text("Search.unavailable.description"))
                            .onTapGesture {
                                Task {
                                    await getEvents()
                                }
                            }
                    }
                }
            }
            .searchable(text: $searchedText, prompt: "Event.search.placeholder")
            .navigationTitle("Event")
            .wrapIf(searchedEvents != nil, in: { content in
                if #available(iOS 26.0, *) {
                    content.navigationSubtitle((searchedText.isEmpty && !filter.isFiltered) ? "Event.count.\(searchedEvents!.count)" :  "Search.result.\(searchedEvents!.count)")
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
                    FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: PreviewEvent.applicableSortingTypes, hasEndingDate: true)
                }
            }
            .onDisappear {
                showFilterSheet = false
            }
        }
        .withSystemBackground()
        .inspector(isPresented: $showFilterSheet) {
            FilterView(filter: $filter, includingKeys: Set(PreviewEvent.applicableFilteringKeys))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
        .withSystemBackground() // This modifier MUST be placed BOTH before
                                // and after `inspector` to make it work as expected
        .task {
            await getEvents()
        }
        .onChange(of: filter) {
            if let events {
                searchedEvents = events.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: sorter) {
            if let oldEvents = events {
                searchedEvents = events!.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: searchedText, {
            if let events {
                searchedEvents = events.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        })
    }
    
    func getEvents() async {
        infoIsAvailable = true
        DoriCache.withCache(id: "EventList_\(filter.identity)", trait: .realTime) {
            await DoriFrontend.Event.list()
        } .onUpdate {
            if let events = $0 {
                self.events = events.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending))
                searchedEvents = events.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            } else {
                infoIsAvailable = false
            }
        }
    }
    
}
