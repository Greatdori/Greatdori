//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaInfo.swift
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


// MARK: GachaInfo
struct GachaInfo: View {
    @Binding var searchedKeyword: String
    @State var attributedTitle: AttributedString?
    @State var attributedType: AttributedString?
    
    @State var information: PreviewGacha?
    @State var currentID: Int
    
    
    var preferHeavierFonts: Bool = true
    var locale: DoriAPI.Locale?
    var subtitle: LocalizedStringKey?
    var showDetails: Bool
    var showID: Bool
    //    @State var imageHeight: CGFloat = 100
    
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 24)
    init(_ gacha: DoriAPI.Gacha.PreviewGacha, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, subtitle: LocalizedStringKey? = nil, showDetails: Bool = false, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
        self.information = gacha
        self.currentID = gacha.id
        
        self.preferHeavierFonts = false
        self.locale = locale
        self.subtitle = subtitle
        self.showDetails = showDetails
        self.showID = showID
        self._searchedKeyword = searchedKeyword
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 24)
    init(_ gacha: DoriAPI.Gacha.Gacha, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, subtitle: LocalizedStringKey? = nil, showDetails: Bool = false, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
        self.information = PreviewGacha(gacha)
        self.currentID = gacha.id
        
        self.preferHeavierFonts = false
        self.locale = locale
        self.subtitle = subtitle
        self.showDetails = showDetails
        self.showID = showID
        self._searchedKeyword = searchedKeyword
    }
    init(id: Int, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, subtitle: LocalizedStringKey? = nil, showDetails: Bool = false, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
        self.information = nil
        self.currentID = id
        
        self.preferHeavierFonts = false
        self.locale = locale
        self.subtitle = subtitle
        self.showDetails = showDetails
        self.showID = showID
        self._searchedKeyword = searchedKeyword
    }
    
    let lighterVersionBannerScaleFactor: CGFloat = 0.85
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 33)
    
    var body: some View {
        CustomGroupBox(showGroupBox: showDetails) {
            HStack {
                if !preferHeavierFonts {
                    Spacer(minLength: 0)
                }
                VStack {
                    if preferHeavierFonts {
                        Spacer(minLength: 0)
                    }
                    WebImage(url: information?.bannerImageURL) { image in
                        image
                            .resizable()
                            .antialiased(true)
                            .scaledToFit()
                            .aspectRatio(3.0, contentMode: .fit)
                            .frame(maxWidth: 420*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), maxHeight: 140*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(getPlaceholderColor())
                            .aspectRatio(3.0, contentMode: .fit)
                            .frame(maxWidth: 420*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), maxHeight: 140*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                    }
                    .interpolation(.high)
                    .cornerRadius(10)
                    
                    if showDetails {
                        VStack {
                            Text(attributedTitle ?? "Lorem Ipsum")
                                .multilineTextAlignment(.center)
                                .bold()
                                .font((!preferHeavierFonts && !isMACOS) ? .body : .title3)
                                .typesettingLanguage(.explicit(((locale ?? .jp).nsLocale().language)))
                                .wrapIf(attributedTitle == nil, in: { content in
                                    content.redacted(reason: .placeholder)
                                })
                                .onAppear {
                                    attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (information?.gachaName.forLocale(locale!) ?? information?.gachaName.jp) : (information?.gachaName.forPreferredLocale())))
                                }
                                .onChange(of: searchedKeyword) {
                                    attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (information?.gachaName.forLocale(locale!) ?? information?.gachaName.jp) : (information?.gachaName.forPreferredLocale())))
                                }
                                .onChange(of: information) {
                                    attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (information?.gachaName.forLocale(locale!) ?? information?.gachaName.jp) : (information?.gachaName.forPreferredLocale())))
                                }
                            Group {
                                //                            if !searchedKeyword.isEmpty {
                                //                                Text("#\(gachaID)").fontDesign(.monospaced).foregroundStyle((searchedKeyword == "#\(gachaID)") ? Color.accentColor : .primary) + Text("Typography.dot-seperater").bold() + Text(attributedType)
                                if preferHeavierFonts {
                                    if let attributedType {
                                        HStack {
                                            Text(attributedType)
                                            if showID {
                                                Text("#\(String(currentID))").fontDesign(.monospaced).foregroundStyle((searchedKeyword == "#\(currentID)") ? Color.accentColor : .secondary)
                                            }
                                        }
                                        .foregroundStyle(.secondary)
                                    } else {
                                        Text(verbatim: "Lorem Ipsum Dolor")
                                            .foregroundStyle(.secondary)
                                            .redacted(reason: .placeholder)
                                    }
                                } else {
                                    Group {
                                        Text(attributedType ?? "Lorem Ipsum")
                                    }
                                    .foregroundStyle(.secondary)
                                    .wrapIf(attributedType == nil, in: { content in
                                        content.redacted(reason: .placeholder)
                                    })
                                }
                            }
                            .onAppear {
                                attributedType = highlightOccurrences(of: searchedKeyword, in: information?.type.localizedString)
                            }
                            .onChange(of: information) {
                                attributedType = highlightOccurrences(of: searchedKeyword, in: information?.type.localizedString)
                            }
                            .onChange(of: searchedKeyword, {
                                attributedType = highlightOccurrences(of: searchedKeyword, in: information?.type.localizedString)
                            })
                            
                            if let subtitle {
                                Text(subtitle)
                                    .foregroundStyle(.secondary)
                                    .wrapIf(information == nil, in: { content in
                                        content.redacted(reason: .placeholder)
                                    })
                            }
                        }
                        .frame(height: showDetails ? nil : 0)
                        .opacity(showDetails ? 1 : 0)
                    }
                    if preferHeavierFonts {
                        Spacer(minLength: 0)
                    }
                }
                if !preferHeavierFonts {
                    Spacer(minLength: 0)
                }
            }
        }
        .task {
            if information == nil {
                let fetchedGacha = await Gacha(id: currentID)
                if let fetchedGacha {
                    information = PreviewGacha(fetchedGacha)
                }
            }
        }
    }
}
