//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardInfo.swift
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

import Foundation
import DoriKit
import SDWebImageSwiftUI
import SwiftUI

// MARK: CardInfo
struct CardInfo: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var attributedTitle: AttributedString = AttributedString("")
    //    @State var attributedType: AttributedString = AttributedString("")
    
    var layoutType = 1
    // 1 - List
    // 2 - Grid
    // 3 - Gallery
    
    private var preferHeavierFonts: Bool = true
    private var thumbNormalImageURL: URL
    private var thumbTrainedImageURL: URL?
    private var cardType: DoriAPI.Card.CardType
    private var attribute: DoriAPI.Attribute
    private var rarity: Int
    private var band: Band?
    private var bandIconImageURL: URL?
    private var prefix: DoriAPI.LocalizedData<String>
    private var characterID: Int
    private var cardID: Int
    private var previewCard: PreviewCard
    
    private var searchedText: String
    @State var cardCharacterName: DoriAPI.LocalizedData<String>?
    @State var isNormalCardAvailable = true
    
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 220)
    init(_ card: DoriAPI.Card.PreviewCard, layoutType: Int = 1, preferHeavierFonts: Bool = false, searchedText: String = "") {
        self.layoutType = layoutType
        self.preferHeavierFonts = false
        self.thumbNormalImageURL = card.thumbNormalImageURL
        self.thumbTrainedImageURL = card.thumbAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.band = DoriCache.preCache.categorizedCharacters.first(where: { $0.value.contains(where: { $0.id == card.characterID }) })?.key
        self.bandIconImageURL = band?.iconImageURL
        self.prefix = card.prefix
        self.characterID = card.characterID
        self.cardID = card.id
        self.previewCard = card
        self.searchedText = searchedText
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 220)
    init(_ card: DoriAPI.Card.Card, layoutType: Int = 1, preferHeavierFonts: Bool = false, searchedText: String = "") {
        self.layoutType = layoutType
        self.preferHeavierFonts = false
        self.thumbNormalImageURL = card.thumbNormalImageURL
        self.thumbTrainedImageURL = card.thumbAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.band = DoriCache.preCache.categorizedCharacters.first(where: { $0.value.contains(where: { $0.id == card.characterID }) })?.key
        self.bandIconImageURL = band?.iconImageURL
        self.prefix = card.prefix
        self.characterID = card.characterID
        self.cardID = card.id
        self.previewCard = PreviewCard(card)
        self.searchedText = searchedText
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 230)
    
    var body: some View {
        CustomGroupBox {
            CustomStack(axis: layoutType == 1 ? .horizontal : .vertical) {
                if layoutType == 2 {
                    Spacer()
                }
                // MARK: CardPreviewImage
                if layoutType != 3 {
                    HStack(spacing: 5) {
                        if isNormalCardAvailable {
                            CardPreviewImage(previewCard)
                        }
                        if thumbTrainedImageURL != nil {
                            CardPreviewImage(previewCard, showTrainedVersion: true)
                        }
                    }
                    .wrapIf(sizeClass == .regular) { content in
                        content.frame(maxWidth: 200)
                    }
                } else {
                    CardCoverImage(previewCard, band: band)
                        .allowsHitTesting(false)
                }
                
                // MARK: Text
                VStack(alignment: layoutType == 1 ? .leading : .center) {
                    Text(attributedTitle)
                        .bold()
                    //                        .font((!preferHeavierFonts && !isMACOS) ? .body : .title3)
                        .font(isMACOS ? .title3 : .body)
                        .onAppear {
                            attributedTitle = highlightOccurrences(of: searchedText, in: prefix.forPreferredLocale() ?? "nil")!
                        }
                        .onChange(of: prefix, {
                            attributedTitle = highlightOccurrences(of: searchedText, in: prefix.forPreferredLocale() ?? "nil")!
                        })
                    Group {
                        Text(cardCharacterName?.forPreferredLocale() ?? "nil") + Text(verbatim: " • ").bold() + Text(cardType.localizedString)
                    }
                    .foregroundStyle(.secondary)
                    //                    .font((!preferHeavierFonts && !isMACOS) ? .caption : .body)
                    .font(isMACOS ? .body : .caption)
                }
                .multilineTextAlignment(layoutType == 1 ? .leading : .center)
                if layoutType != 3 {
                    Spacer()
                }
            }
            .wrapIf(layoutType == 2) { content in
                HStack {
                    Spacer(minLength: 0)
                    content
                    Spacer(minLength: 0)
                }
            }
        }
        .onAppear {
            if cardCharacterName == nil { // First appear
                Task {
                    isNormalCardAvailable = await DoriURLValidator.reachability(
                        of: layoutType != 3 ? previewCard.thumbNormalImageURL : previewCard.coverNormalImageURL
                    )
                }
            }
            self.cardCharacterName = DoriCache.preCache.characterDetails[characterID]?.characterName
        }
    }
}
