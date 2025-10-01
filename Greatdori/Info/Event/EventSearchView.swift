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
    let gridLayoutItemWidth: CGFloat = 225
    
    @Namespace var eventNamespace
    var body: some View {
        SearchViewBase("Event", forType: PreviewEvent.self, initialLayout: true, layoutOptions: bannerLayouts) { showDetails, content in
            ViewThatFits {
                LazyVGrid(columns: [GridItem(.fixed(bannerWidth), spacing: bannerSpacing), GridItem(.fixed(bannerWidth))], spacing: 25) {
                    content
                }
                .frame(width: bannerWidth * 2 + bannerSpacing)
                LazyVStack(spacing: showDetails ? nil : bannerSpacing) {
                    content
                }
                .frame(maxWidth: bannerWidth)
            }
            .padding(.horizontal)
            .animation(.spring(duration: 0.3, bounce: 0.1, blendDuration: 0), value: showDetails)
        } eachContent: { showDetails, element in
            EventInfo(element, showDetails: showDetails)
        } destination: { element, list in
            EventDetailView(id: element.id, allEvents: list)
        }
        .contentUnavailableImage(systemName: "star.hexagon")
        .resultCountDescription { count in
            "Event.count.\(count)"
        }
    }
}
