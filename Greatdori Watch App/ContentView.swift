//
//  ContentView.swift
//  Greatdori Watch App
//
//  Created by Mark Chan on 7/18/25.
//

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
    case character
    case card
    case costume
    case event
    case gacha
    case eventTracker
    case storyViewer
}
