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
@_spi(GreatLyrics) import DoriKit

struct ContentView: View {
    @State var lyrics = Lyrics(
        id: 0,
        version: 1,
        lyrics: [],
        mainStyle: nil,
        metadata: .init(legends: [])
    )
    @State var mainTabSelection = 0
    var body: some View {
        TabView(selection: $mainTabSelection) {
            Tab("File", systemImage: "document", value: 0) {
                NavigationStack {
                    FileView(lyrics: $lyrics)
                }
            }
            Tab("Style", systemImage: "paintbrush", value: 1) {
                NavigationStack {
                    StyleView(lyrics: $lyrics)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
