//===---*- Greatdori! -*---------------------------------------------------===//
//
// ComicInfo.swift
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


// MARK: ComicInfo
struct ComicInfo: View {
    @Binding var searchedKeyword: String
    @State var attributedTitle: AttributedString = AttributedString("")
    
    private var preferHeavierFonts: Bool = true
    private var thumbImageURL: URL
    private var title: DoriAPI.LocalizedData<String>
    private var subTitle: DoriAPI.LocalizedData<String>
    private var comicID: Int
    private var locale: DoriAPI.Locale?
    private var layout: Axis
    private var showID: Bool
    private var comicType: Comic.ComicType? // FIXME: Driver bug
    
    init(_ comic: Comic, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, layout: Axis = .horizontal, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
        self.preferHeavierFonts = preferHeavierFonts
        self.thumbImageURL = comic.thumbImageURL(in: locale ?? DoriAPI.preferredLocale)!
        self.title = comic.title
        self.subTitle = comic.subTitle
        self.comicID = comic.id
        self.locale = locale
        self.layout = layout
        self.showID = showID
        self._searchedKeyword = searchedKeyword
        self.comicType = comic.type
    }
    
    let lighterVersionBannerScaleFactor: CGFloat = 0.85
    
    var body: some View {
        CustomGroupBox {
            CustomStack(axis: layout) {
                WebImage(url: thumbImageURL) { image in
                    image
                        .resizable()
                        .antialiased(true)
                        .scaledToFit()
                        .frame(width: 150*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), height: 150*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(getPlaceholderColor())
                        .frame(width: 150*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), height: 150*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                }
                .interpolation(.high)
                
                if layout == .vertical {
                    Spacer()
                }
                
                VStack(alignment: layout == .horizontal ? .leading : .center) {
                    Text(attributedTitle)
                        .bold()
                        .font((!preferHeavierFonts && !isMACOS) ? .body : .title3)
                        .onAppear {
                            attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))!
                        }
                        .multilineTextAlignment(layout == .horizontal ? .leading : .center)
                        .typesettingLanguage(.explicit(((locale ?? .jp).nsLocale().language)))
                        .onChange(of: searchedKeyword, {
                            attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))!
                        })
                    Text(subTitle.forPreferredLocale() ?? "nil")
                        .font((!preferHeavierFonts && !isMACOS) ? .caption : .body)
                    if let type = comicType {
                        Text(type.localizedString)
                            .foregroundStyle(.secondary)
                            .font((!preferHeavierFonts && !isMACOS) ? .caption : .body)
                    }
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
            attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? "")))!
            // FIXME: Attributed subtitle
        }
    }
}
