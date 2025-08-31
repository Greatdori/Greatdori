//===---*- Greatdori! -*---------------------------------------------------===//
//
// ContentView.swift
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

struct ContentView: View {
    @State var navigation: NavigationPage? = .home
    
    @AppStorage("startUpSucceeded") var startUpSucceeded = true
    @State var mainAppShouldBeDisplayed = false
    @State var crashViewShouldBeDisplayed = false
    @State var lastStartUpWasSuccessful = true
    @State var showCrashAlert = false
    var body: some View {
        if mainAppShouldBeDisplayed {
            NavigationSplitView {
                NavigationListView(navigation: $navigation)
            } detail: {
                NavigationStack {
                    switch navigation {
                    case .home:
                        HomeView()
                    case .post:
                        CommunityPostsView()
                    case .story:
                        CommunityStoriesView()
                    case .character:
                        CharacterListView()
                    case .card:
                        CardListView()
                    case .costume:
                        CostumeListView()
                    case .event:
                        EventListView()
                    case .gacha:
                        GachaListView()
                    case .song:
                        SongListView()
                    case .songMeta:
                        SongMetaView()
                    case .miracleTicket:
                        MiracleTicketView()
                    case .comic:
                        ComicListView()
                    case .eventTracker:
                        EventTrackerView()
                    case .storyViewer:
                        StoryViewerView()
                    case nil:
                        EmptyView()
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    startUpSucceeded = true
                }
            }
        } else {
            if crashViewShouldBeDisplayed {
                // Crash View pretended to be the same as loading view below.
                ProgressView()
                    .onAppear {
                        NSLog("CRASH VIEW HAD BEEN ENTERED")
#if DEBUG
                        showCrashAlert = true
#else
                        DoriCache.invalidateAll()
                        mainAppShouldBeDisplayed = true
#endif
                    }
                    .alert("Debug.crash-detected.title", isPresented: $showCrashAlert, actions: {
                        Button(action: {
                            DoriCache.invalidateAll()
                            mainAppShouldBeDisplayed = true
                        }, label: {
                            Text("Debug.crash-detected.invalidate-cache-enter")
                        })
                        Button(role: .destructive, action: {
                            mainAppShouldBeDisplayed = true
                        }, label: {
                            Text("Debug.crash-detected.direct-enter")
                        })
                    }, message: {
                        Text("Debug.crash-detected.message")
                    })
            } else {
                ProgressView()
                    .onAppear {
                        lastStartUpWasSuccessful = startUpSucceeded
                        startUpSucceeded = false
                        if lastStartUpWasSuccessful {
                            mainAppShouldBeDisplayed = true
                        } else {
                            crashViewShouldBeDisplayed = true
                        }
                    }
            }
        }
    }
}

enum NavigationPage {
    case home
    case post
    case story
    case character
    case card
    case costume
    case event
    case gacha
    case song
    case songMeta
    case miracleTicket
    case comic
    case eventTracker
    case storyViewer
}
