//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongInfo.swift
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
import SDWebImageSwiftUI
import SwiftUI


// MARK: SongInfo
struct SongInfo: View {
    @State var information: PreviewSong
    var subtitle: LocalizedStringKey? = nil
    var layout: SummaryLayout
    
    init(_ song: DoriAPI.Song.PreviewSong, subtitle: LocalizedStringKey? = nil, layout: SummaryLayout = .horizontal) {
        self.information = song
        self.subtitle = subtitle
        self.layout = layout
    }
    
    init(_ song: DoriAPI.Song.Song, subtitle: LocalizedStringKey? = nil, layout: SummaryLayout = .horizontal) {
        self.information = PreviewSong(song)
        self.subtitle = subtitle
        self.layout = layout
    }
    
    var body: some View {
        SummaryViewBase(layout, source: information) {
            WebImage(url: information.jacketImageURL) { image in
                image
                    .resizable()
                    .antialiased(true)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .cornerRadius(5)
            } placeholder: {
                RoundedRectangle(cornerRadius: 5)
                    .fill(getPlaceholderColor())
                    .frame(width: 120, height: 120)
            }
            .interpolation(.high)
        } detail: {
            Text(DoriCache.preCache.bands.first { $0.id == information.bandID }?.bandName.forPreferredLocale() ?? "nil")
                .font(isMACOS ? .body : .caption)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
            }
            SongDifficultiesIndicator(information.difficulty)
                .preferHiddenInCompactLayout()
        }
    }
}
