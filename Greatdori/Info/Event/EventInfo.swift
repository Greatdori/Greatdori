//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventInfo.swift
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

// MARK: EventInfo
struct EventInfo: View {
    @Binding var searchedKeyword: String
    @State var attributedTitle: AttributedString? = AttributedString("")
    @State var attributedType: AttributedString? = AttributedString("")
    @State var currentID: Int
    
    var preferHeavierFonts: Bool = true
    var subtitle: LocalizedStringKey? = nil
    var locale: DoriAPI.Locale?
    var showDetails: Bool
    var showID: Bool
    
    @State var information: PreviewEvent?
    //    @State var imageHeight: CGFloat = 100
    
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 24)
    init(_ event: DoriAPI.Event.PreviewEvent, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, subtitle: LocalizedStringKey? = nil, showDetails: Bool = false, showID: Bool = true, searchedKeyword: Binding<String> = .constant("")) {
        self.information = event
        self.currentID = event.id
        
        
        //        self.eventImageURL = event.bannerImageURL(in: locale ?? DoriAPI.preferredLocale)!
        //        self.title = event.eventName
        //        self.eventID = event.id
        //        self.eventType = event.eventType
        
        
        self.preferHeavierFonts = preferHeavierFonts
        self.locale = locale
        self.subtitle = subtitle
        self.showDetails = showDetails
        self.showID = showID
        self._searchedKeyword = searchedKeyword
        //        self.dataIsReady = true
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 24)
    init(_ event: DoriAPI.Event.Event, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, subtitle: LocalizedStringKey? = nil, showDetails: Bool = false, showID: Bool = true, searchedKeyword: Binding<String> = .constant("")) {
        self.information = PreviewEvent(event)
        self.currentID = event.id
        
        self.preferHeavierFonts = preferHeavierFonts
        self.locale = locale
        self.subtitle = subtitle
        self.showDetails = showDetails
        self.showID = showID
        self._searchedKeyword = searchedKeyword
        //        self.dataIsReady = true
    }
    
    init(id: Int, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, subtitle: LocalizedStringKey? = nil, showDetails: Bool = false, showID: Bool = true, searchedKeyword: Binding<String> = .constant("")) {
        self.information = nil
        self.currentID = id
        
        
        //        self.eventImageURL = URL(string: "")
        //        self.title = nil
        //        self.eventID = id
        //        self.eventType = .story
        
        self.preferHeavierFonts = preferHeavierFonts
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
                    WebImage(url: information?.bannerImageURL) { image in
                        image
                            .resizable()
                            .antialiased(true)
                        //                        .scaledToFit()
                            .aspectRatio(3.0, contentMode: .fit)
                            .frame(maxWidth: 420*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), maxHeight: 140*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                        //                        .fill(Color.gray.opacity(0.15))
                            .fill(getPlaceholderColor())
                            .aspectRatio(3.0, contentMode: .fit)
                            .frame(maxWidth: 420*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), maxHeight: 140*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
                    }
                    .interpolation(.high)
                    .cornerRadius(10)
                    
                    if showDetails {
                        VStack { // Accually Title & Countdown
                                 //                        Text(locale != nil ? (title.forLocale(locale!) ?? title.jp ?? "") : (title.forPreferredLocale() ?? ""))
                            Group {
                                Text(attributedTitle ?? "Lorem Ipsum")
                                    .multilineTextAlignment(.center)
                                    .bold()
                                    .font((!preferHeavierFonts && !isMACOS) ? .body : .title3)
                                    .typesettingLanguage(.explicit(((locale ?? .jp).nsLocale().language)))
                                    .wrapIf(attributedTitle == nil, in: { content in
                                        content
                                            .redacted(reason: .placeholder)
                                    })
                            }
                            .onAppear {
                                attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (information?.eventName.forLocale(locale!) ?? information?.eventName.jp ?? "") : (information?.eventName.forPreferredLocale())))
                            }
                            .onChange(of: information) {
                                attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (information?.eventName.forLocale(locale!) ?? information?.eventName.jp ?? "") : (information?.eventName.forPreferredLocale())))
                            }
                            .onChange(of: searchedKeyword, {
                                attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (information?.eventName.forLocale(locale!) ?? information?.eventName.jp ?? "") : (information?.eventName.forPreferredLocale())))
                            })
                            
                            Group {
                                if let attributedType {
                                    if preferHeavierFonts {
                                        HStack {
                                            Text(attributedType)
                                            if showID {
                                                Text("#\(String(currentID))").fontDesign(.monospaced).foregroundStyle((searchedKeyword == "#\(currentID)") ? Color.accentColor : .secondary)
                                            }
                                        }
                                    } else {
                                        Group {
                                            Text(attributedType) + Text(verbatim: " • ").bold() + Text("#\(String(currentID))").fontDesign(.monospaced)
                                        }
                                        .foregroundStyle(.secondary)
                                        //                                    .font(.caption)
                                    }
                                } else {
                                    Text(verbatim: "Lorem Ipsum Dolor")
                                        .redacted(reason: .placeholder)
                                }
                            }
                            .onAppear {
                                attributedType = highlightOccurrences(of: searchedKeyword, in: information?.eventType.localizedString)
                            }
                            .onChange(of: information) {
                                attributedType = highlightOccurrences(of: searchedKeyword, in: information?.eventType.localizedString)
                            }
                            .onChange(of: searchedKeyword) {
                                attributedType = highlightOccurrences(of: searchedKeyword, in: information?.eventType.localizedString)
                            }
                            
                            if let subtitle {
                                Group {
                                    Text(subtitle)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(height: showDetails ? nil : 0)
                        .opacity(showDetails ? 1 : 0)
                    }
                }
                if !preferHeavierFonts {
                    Spacer(minLength: 0)
                }
            }
        }
        .task {
            if information == nil {
                let fetchedEvent = await Event(id: currentID)
                if let fetchedEvent {
                    information = PreviewEvent(fetchedEvent)
                }
            }
        }
    }
}
