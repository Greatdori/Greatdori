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
    @State var attributedType: AttributedString? = AttributedString("")
    var subtitle: LocalizedStringKey? = nil
    var showDetails: Bool
    @Environment(\.searchedKeyword) private var searchedKeyword: Binding<String>?
    @State var information: PreviewEvent
    
    init(_ event: DoriAPI.Event.PreviewEvent, subtitle: LocalizedStringKey? = nil, showDetails: Bool = false) {
        self.information = event
        self.subtitle = subtitle
        self.showDetails = showDetails
    }
    init(_ event: DoriAPI.Event.Event, subtitle: LocalizedStringKey? = nil, showDetails: Bool = false) {
        self.information = PreviewEvent(event)
        self.subtitle = subtitle
        self.showDetails = showDetails
    }
    
    var body: some View {
        SummaryViewBase(.vertical(hidesDetail: !showDetails), source: information) {
            FallbackableWebImage(throughURLs: [information.bannerImageURL, information.homeBannerImageURL]) { image in
                image
                    .resizable()
                    .antialiased(true)
                    .aspectRatio(3.0, contentMode: .fit)
                    .frame(maxWidth: 420, maxHeight: 140)
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(getPlaceholderColor())
                    .aspectRatio(3.0, contentMode: .fit)
                    .frame(maxWidth: 420, maxHeight: 140)
            }
            .interpolation(.high)
            .cornerRadius(10)
        } detail: {
            Group {
                if let attributedType {
                    Text(attributedType) + Text(verbatim: " • ").bold() + Text("#\(String(information.id))").fontDesign(.monospaced)
                } else {
                    Text(verbatim: "Lorem Ipsum Dolor")
                        .redacted(reason: .placeholder)
                }
            }
            .onAppear {
                attributedType = highlightOccurrences(of: searchedKeyword?.wrappedValue ?? "", in: information.eventType.localizedString)
            }
            .onChange(of: information) {
                attributedType = highlightOccurrences(of: searchedKeyword?.wrappedValue ?? "", in: information.eventType.localizedString)
            }
            .onChange(of: searchedKeyword?.wrappedValue) {
                attributedType = highlightOccurrences(of: searchedKeyword?.wrappedValue ?? "", in: information.eventType.localizedString)
            }
            
            if let subtitle {
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
