//===---*- Greatdori! -*---------------------------------------------------===//
//
// NewsView.swift
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
import SwiftUI

struct NewsView: View {
    @State var news: [DoriFrontend.News.ListItem]?
    var dateFormatter = DateFormatter()
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
    }
    var body: some View {
        Group {
            if let news {
                List {
                    ForEach(0..<news.count, id: \.self) { newsIndex in
                        NewsPreview(news: news[newsIndex])
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Home.news")
        .onAppear {
            DoriCache.withCache(id: "News", trait: .realTime) {
                await DoriFrontend.News.list()
            } .onUpdate {
                news = $0
            }
        }
    }
}

struct NewsPreview: View {
    var news: DoriFrontend.News.ListItem
    var showLocale: Bool = true
    var dateFormatter = DateFormatter()
    init(news: DoriFrontend.News.ListItem, showLocale: Bool = true) {
        self.news = news
        self.showLocale = showLocale
//        dateFormatter.dateStyle = .short
//        dateFormatter.timeStyle = .short
        dateFormatter.setLocalizedDateFormatFromTemplate("Mdjm")
    }
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Group {
                    Image(systemName: newsItemTypeIcon[news.type]!)
                    Group {
                        Text(newsItemTypeLocalizedString[news.type]!) + Text((showLocale && news.locale != nil) ? "(\(news.locale!.rawValue.uppercased()))" : "")
                    }
                        .offset(x: -3)
                }
                .foregroundStyle(newsItemTypeColor[news.type]!)
                Text(dateFormatter.string(from: news.timestamp))
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
            .bold()
//            .font(.caption)
            Text(news.subject)
                .lineLimit(2)
                .foregroundStyle(.primary)
                .font(.body)
                .bold()
                 
            Group {
                switch news.timeMark {
                case .willStartAfter(let interval):
                    Text("News.time-mark.will-start-after.\(interval)")
                case .willEndAfter(let interval):
                    Text("News.time-mark.will-end-after.\(interval)")
                case .willEndToday:
                    Text("News.time-mark.will-end-today")
                case .hasEnded:
                    Text("News.time-mark.has-ended")
                case .hasPublished:
                    Text("News.time-mark.has-published")
                @unknown default:
//                    Text("")
                    EmptyView()
                }
            }
            .foregroundStyle(.primary)
            .font(.body)
            .fontWeight(.light)
        }
    }
}

let newsItemTypeIcon: [DoriFrontend.News.ListItem.ItemType: String] = [.article: "text.page", .event: "star.hexagon", .gacha: "dice", .loginCampaign: "calendar", .song: "music.microphone"]
let newsItemTypeColor: [DoriFrontend.News.ListItem.ItemType: Color] = [.article: .gray, .event: .green, .gacha: .blue, .loginCampaign: .red, .song: .purple]
let newsItemTypeLocalizedString: [DoriFrontend.News.ListItem.ItemType: LocalizedStringResource] = [.article: "News.type.article", .event: "News.type.event", .gacha: "News.type.gacha", .loginCampaign: "News.type.login-campaign", .song: "News.type.song"]
//let newsTimeMarkTypeLocalizedString: [Dori]
