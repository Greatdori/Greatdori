//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongSearchView.swift
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

// MARK: SongSearchView
struct SongSearchView: View {
    let gridLayoutItemWidth: CGFloat = 225
    var body: some View {
        SearchViewBase("Song", forType: PreviewSong.self, initialLayout: SummaryLayout.horizontal, layoutOptions: verticalAndHorizontalLayouts) { layout, content in
            if layout == .horizontal {
                LazyVStack {
                    content
                }
                .frame(maxWidth: 600)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: gridLayoutItemWidth, maximum: gridLayoutItemWidth))]) {
                    content
                }
            }
        } eachContent: { layout, element in
            SongInfo(element, layout: layout)
        } destination: { element, list in
            SongDetailView(id: element.id, allSongs: list)
        }
        .contentUnavailableImage(systemName: "music.note")
        .resultCountDescription { count in
            "Song.count.\(count)"
        }
    }
}
