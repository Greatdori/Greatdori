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

import SwiftUI

struct ContentView: View {
    @State var navigation: NavigationPage? = .home
    var body: some View {
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
