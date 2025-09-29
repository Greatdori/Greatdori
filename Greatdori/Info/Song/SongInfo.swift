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
    @Binding var searchedKeyword: String
    @State var attributedTitle: AttributedString = AttributedString("")
    
    @State var information: PreviewSong
    
    var preferHeavierFonts: Bool = true
    var subtitle: LocalizedStringKey? = nil
    var songID: Int
    var locale: DoriAPI.Locale
    var layout: Axis
    var showID: Bool
    
    init(_ song: DoriAPI.Song.PreviewSong, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale = DoriAPI.preferredLocale, subtitle: LocalizedStringKey? = nil, layout: Axis = .horizontal, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
        self.information = song
        self.preferHeavierFonts = preferHeavierFonts
        self.subtitle = subtitle
        self.songID = song.id
        self.locale = locale
        self.layout = layout
        self.showID = showID
        self._searchedKeyword = searchedKeyword
        //        self.bandID = song.bandID
    }
    
    init(_ song: DoriAPI.Song.Song, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale = DoriAPI.preferredLocale,  subtitle: LocalizedStringKey? = nil, layout: Axis = .horizontal, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
        self.information = PreviewSong(song)
        self.preferHeavierFonts = preferHeavierFonts
        self.subtitle = subtitle
        self.songID = song.id
        self.locale = locale
        self.layout = layout
        self.showID = showID
        self._searchedKeyword = searchedKeyword
    }
    
    let lighterVersionBannerScaleFactor: CGFloat = 1
    let coverSideLengthForHorizontalLayout: CGFloat = 100
    let coverSideLengthForVerticalLayout: CGFloat = 120
    let cornerRadius: CGFloat = 5
    @State var bandName: LocalizedData<String>?
    
    var body: some View {
        CustomGroupBox {
            CustomStack(axis: layout) {
                WebImage(url: information.jacketImageURL(in: locale)) { image in
                    image
                        .resizable()
                        .antialiased(true)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: (layout == .vertical ? coverSideLengthForVerticalLayout : coverSideLengthForHorizontalLayout)*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), height: (layout == .vertical ? coverSideLengthForVerticalLayout : coverSideLengthForHorizontalLayout)*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                        .cornerRadius(cornerRadius)
                } placeholder: {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(getPlaceholderColor())
                        .frame(width: (layout == .vertical ? coverSideLengthForVerticalLayout : coverSideLengthForHorizontalLayout)*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), height: (layout == .vertical ? coverSideLengthForVerticalLayout : coverSideLengthForHorizontalLayout)*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                }
                .interpolation(.high)
                
                if layout == .vertical {
                    Spacer()
                } else {
                    Spacer()
                        .frame(maxWidth: 15)
                }
                
                VStack(alignment: layout == .horizontal ? .leading : .center) {
                    Text(attributedTitle)
                        .bold()
                        .font((!preferHeavierFonts && !isMACOS) ? .body : .title3)
                        .typesettingLanguage(.explicit(((locale).nsLocale().language)))
                    Text(bandName?.forPreferredLocale() ?? "nil")
                        .foregroundStyle(.secondary)
                        .font((!preferHeavierFonts && !isMACOS) ? .caption : .body)
                    if let subtitle {
                        Text(subtitle)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    if layout == .horizontal {
                        SongDifficultiesIndicator(information.difficulty)
                    }
                }
                .multilineTextAlignment(layout == .horizontal ? .leading : .center)
                
                //                if layout == .horizontal {
                Spacer(minLength: 0)
                //                }
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
            bandName = DoriCache.preCache.bands.first { $0.id == information.bandID }?.bandName
            attributedTitle = highlightOccurrences(of: searchedKeyword, in: (information.musicTitle.forLocale(locale) ?? information.musicTitle.forPreferredLocale(allowsFallback: true)))!
        }
        .onChange(of: searchedKeyword) {
            attributedTitle = highlightOccurrences(of: searchedKeyword, in: (information.musicTitle.forLocale(locale) ?? information.musicTitle.forPreferredLocale(allowsFallback: true)))!
        }
    }
}
