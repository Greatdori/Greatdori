//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardSearchView.swift
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

// MARK: CardSearchView
struct CardSearchView: View {
    let gridLayoutItemWidth: CGFloat = 200
    let galleryLayoutItemMinimumWidth: CGFloat = 400
    let galleryLayoutItemMaximumWidth: CGFloat = 500
    var body: some View {
        SearchViewBase("Card", forType: CardWithBand.self, initialLayout: 1, layoutOptions: [("Filter.view.list", "list.bullet", 1), ("Filter.view.grid", "square.grid.2x2", 2), ("Filter.view.gallery", "text.below.rectangle", 3)]) { layout, content in
            if layout == 1 {
                LazyVStack {
                    content
                }
                .frame(maxWidth: 600)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: layout == 2 ? gridLayoutItemWidth : galleryLayoutItemMinimumWidth, maximum: layout == 2 ? gridLayoutItemWidth : galleryLayoutItemMaximumWidth))]) {
                    content
                }
            }
        } eachContent: { layout, element in
            CardInfo(element.card, layoutType: layout)
        } destination: { element, list in
            CardDetailView(id: element.id, allCards: list)
        }
        .contentUnavailablePrompt("Card.search.unavailable")
        .contentUnavailableImage(systemName: "line.horizontal.star.fill.line.horizontal")
        .searchPlaceholder("Card.search.placeholder")
        .resultCountDescription { count in
            "Card.count.\(count)"
        }
    }
}
