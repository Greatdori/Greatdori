//===---*- Greatdori! -*---------------------------------------------------===//
//
// CostumeInfo.swift
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


// MARK: CostumeInfo
struct CostumeInfo: View {
    @Binding var searchedKeyword: String
    @State var attributedTitle: AttributedString = AttributedString("")
    @State var attributedChar: AttributedString = AttributedString("")
    
    private var preferHeavierFonts: Bool = true
    private var thumbImageURL: URL
    private var title: DoriAPI.LocalizedData<String>
    private var costumeID: Int
    private var locale: DoriAPI.Locale?
    private var layout: Axis
    private var showID: Bool
    private var characterID: Int
    
    init(_ costume: DoriAPI.Costume.PreviewCostume, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, layout: Axis = .horizontal, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
        self.preferHeavierFonts = false
        self.thumbImageURL = costume.thumbImageURL(in: locale ?? DoriAPI.preferredLocale)!
        self.title = costume.description
        self.costumeID = costume.id
        self.locale = locale
        self.layout = layout
        self.showID = showID
        self._searchedKeyword = searchedKeyword
        self.characterID = costume.characterID
    }
    
    init(_ costume: DoriAPI.Costume.Costume, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, layout: Axis = .horizontal, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
        self.preferHeavierFonts = false
        self.thumbImageURL = costume.thumbImageURL(in: locale ?? DoriAPI.preferredLocale)!
        self.title = costume.description
        self.costumeID = costume.id
        self.locale = locale
        self.layout = layout
        self.showID = showID
        self._searchedKeyword = searchedKeyword
        self.characterID = costume.characterID
    }
    
    let lighterVersionBannerScaleFactor: CGFloat = 0.85
    @State var characterName: LocalizedData<String>?
    
    var body: some View {
        CustomGroupBox {
            CustomStack(axis: layout) {
                WebImage(url: thumbImageURL) { image in
                    image
                        .resizable()
                        .antialiased(true)
                    //                        .scaledToFit()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 96*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), height: 96*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(getPlaceholderColor())
                        .frame(width: 96*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), height: 96*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                }
                .interpolation(.high)
                
                if layout == .vertical {
                    Spacer()
                }
                
                VStack(alignment: layout == .horizontal ? .leading : .center) {
                    Text(attributedTitle)
                        .bold()
                    //                        .font((!preferHeavierFonts && !isMACOS) ? .body : .title3)
                        .font(.body)
                        .onAppear {
                            attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))!
                        }
                        .multilineTextAlignment(layout == .horizontal ? .leading : .center)
                        .typesettingLanguage(.explicit(((locale ?? .jp).nsLocale().language)))
                        .onChange(of: searchedKeyword, {
                            attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))!
                        })
                    Text(characterName?.forPreferredLocale() ?? "nil")
                        .foregroundStyle(.secondary)
                    //                        .font((!preferHeavierFonts && !isMACOS) ? .caption : .body)
                        .font(.caption)
                }
                
                if layout == .horizontal {
                    Spacer()
                }
            }
            .wrapIf(layout == .vertical) { content in
                HStack {
                    Spacer()
                    content
                    Spacer()
                }
            }
        }
        .onAppear {
            characterName = DoriCache.preCache.characters.first(where: {$0.id == characterID})?.characterName
            
            attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))!
            attributedChar = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (characterName?.forLocale(locale!) ?? characterName?.jp ?? "") : (characterName?.forPreferredLocale() ?? "")))!
        }
        //        .border(.red)
    }
}
