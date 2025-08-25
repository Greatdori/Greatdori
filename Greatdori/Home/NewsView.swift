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
import SDWebImageSwiftUI

//MARK: NewsView
struct NewsView: View {
    let filterLocalizedString: [DoriFrontend.News.ListFilter?: LocalizedStringResource] = [nil: "News.filter.selection.all", .bestdori: "News.filter.selection.bestdori", .article: "News.filter.selection.article", .patchNote: "News.filter.selection.patch-note", .update: "News.filter.selection.update", .locale(.jp): "News.filter.selection.jp", .locale(.en): "News.filter.selection.en", .locale(.tw): "News.filter.selection.tw", .locale(.cn): "News.filter.selection.cn", .locale(.kr): "News.filter.selection.kr"]
    let filterOptions: [DoriFrontend.News.ListFilter?] = [nil, .bestdori, .article, .patchNote, .update, .locale(.jp), .locale(.en), .locale(.tw), .locale(.cn), .locale(.kr)]
    @Environment(\.colorScheme) var colorScheme
    @State var news: [DoriFrontend.News.ListItem]?
    @State var filter: DoriFrontend.News.ListFilter? = nil
    @State var allEvents: [DoriAPI.Event.PreviewEvent]?
    @State var allGacha: [DoriAPI.Gacha.PreviewGacha]?
    @State var allSongs: [DoriAPI.Song.PreviewSong]?
    var dateFormatter = DateFormatter()
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
    }
    var body: some View {
        Group {
            if let news {
                List {
                    ForEach(news, id: \.self) { news in
                        NavigationLink(destination: {
                            switch news.type {
                            case .article:
                                //FIXME: [NAVI785]
                                EmptyView()
                            case .event:
                                EventDetailView(id: news.relatedID)
                            case .gacha:
                                //FIXME: [NAVI785]
                                EmptyView()
                            case .loginCampaign:
                                //FIXME: [NAVI785]
                                EmptyView()
                            case .song:
                                //FIXME: [NAVI785]
                                EmptyView()
                            @unknown default:
                                EmptyView()
                            }
                        }, label: {
                            NewsPreview(allEvents: allEvents, allGacha: allGacha, allSongs: allSongs, news: news, showLocale: {
                                if case .locale = filter { false } else { true }
                            }(), showDetails: true, showImages: true)
                        })
//                        .navigationBarBackButtonHidden()
//                        .navigationLinkIndicatorVisibility(.hidden)
                    }
                }

            } else {
                ProgressView()
            }
        }
        .navigationTitle("Home.news")
        .wrapIf(filter != nil && !isMACOS, in: { content in
            if #available(iOS 26.0, *) {
                content
                    .navigationSubtitle(filterLocalizedString[filter]!)
            } else {
                content
            }
        })
        .task {
            DoriCache.withCache(id: "News", trait: .realTime) {
                await DoriFrontend.News.list(filter: filter)
            } .onUpdate {
                news = $0
            }
            await withTaskGroup { group in
                group.addTask {
                    let events = await DoriAPI.Event.all()
                    await MainActor.run {
                        allEvents = events
                    }
                }
                group.addTask {
                    let gacha = await DoriAPI.Gacha.all()
                    await MainActor.run {
                        allGacha = gacha
                    }
                }
                group.addTask {
                    let songs = await DoriAPI.Song.all()
                    await MainActor.run {
                        allSongs = songs
                    }
                }
            }
        }
        .onChange(of: filter) {
            Task {
                news = await DoriFrontend.News.list(filter: filter)
            }
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem {
                Menu {
                    Picker("", selection: $filter) {
                        ForEach(0..<filterOptions.count, id: \.self) { filterIndex in
                            //                                Button(action: {
                            //                                    filter = filterOptions[filterIndex]
                            //                                }, label: {
                            //                                    HStack {
                            //                                        if filter == filterOptions[filterIndex] {
                            //                                            Image(systemName: "checkmark")
                            //                                        }
                            Text(filterLocalizedString[filterOptions[filterIndex]]!)
                                .tag(filterOptions[filterIndex])
                            //                                    }
                            //                                })
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } label: {
                    if filter != nil {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundStyle(.white)
                            .background {
                                Capsule().foregroundStyle(Color.accentColor).scaledToFill().scaleEffect(1.3)
                            }
                    } else {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
            }
#else
            ToolbarItem {
                Picker(selection: $filter, content: {
                    ForEach(0..<filterOptions.count, id: \.self) { filterIndex in
                        //                                Button(action: {
                        //                                    filter = filterOptions[filterIndex]
                        //                                }, label: {
                        //                                    HStack {
                        //                                        if filter == filterOptions[filterIndex] {
                        //                                            Image(systemName: "checkmark")
                        //                                        }
                        Text(filterLocalizedString[filterOptions[filterIndex]]!)
                            .tag(filterOptions[filterIndex])
                        //                                    }
                        //                                })
                    }
                }, label: {
                    if filter != nil {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .background {
                                Capsule().foregroundStyle(Color.accentColor).scaledToFill().scaleEffect(1.3)
                            }
                    } else {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                })
                .pickerStyle(.menu)
            }
#endif
        }
    }
}

//MARK: NewsPreview
struct NewsPreview: View {
    var allEvents: [DoriAPI.Event.PreviewEvent]?
    var allGacha: [DoriAPI.Gacha.PreviewGacha]?
    var allSongs: [DoriAPI.Song.PreviewSong]?
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var imageURL: URL? = nil
    var news: DoriFrontend.News.ListItem
    var showLocale: Bool = true
    var showDetails: Bool = false
    var showImages: Bool = false
    var dateFormatter = DateFormatter()
    init(
        allEvents: [DoriAPI.Event.PreviewEvent]?,
        allGacha: [DoriAPI.Gacha.PreviewGacha]?,
        allSongs: [DoriAPI.Song.PreviewSong]?,
        news: DoriFrontend.News.ListItem,
        showLocale: Bool = true,
        showDetails: Bool = false,
        showImages: Bool = false
    ) {
        self.allEvents = allEvents
        self.allGacha = allGacha
        self.allSongs = allSongs
        self.news = news
        self.showLocale = showLocale
        self.showDetails = showDetails
        self.showImages = showImages
        dateFormatter.setLocalizedDateFormatFromTemplate(showDetails ? "YMdjm" : "Mdjm")
    }
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Group {
                        Image(systemName: newsItemTypeIcon[news.type]!)
                        Group {
                            Text(newsItemTypeLocalizedString[news.type]!) + Text((showLocale && news.locale != nil) ? "Typography.brackets.with-space.\(news.locale!.rawValue.uppercased())" : "")
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
                
                if showDetails {
//                    HStack {
//                        //                    Text("News.author.\(news.author)")
//                        Text(news.author)
//                            .font(.caption)
//                            .bold()
//                        ForEach(0..<news.tags.count, id: \.self) { tagIndex in
//                            Text("#\(news.tags[tagIndex])")
//                                .font(.caption)
//                            //                            .foregroundStyle(.secondary)
//                        }
//                        Spacer()
//                    }
                    getDetailsLineString(author: news.author, tags: news.tags)
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
            }
            Spacer()
            
            if showImages {
                if sizeClass == .regular {
                    Group {
                        if let imageURL {
                            WebImage(url: imageURL)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: news.type == .song ? 100 : 75)
                                .cornerRadius(5)
                        } else {
                            Rectangle()
                                .frame(width: 0, height: 0)
                                .opacity(0)
                        }
                    }
                    Rectangle()
                        .frame(width: 0, height: 0)
                        .opacity(0)
                        .wrapIf({ if case .event = news.type { true } else { false } }()) { content in
                            content
                                .onAppear {
                                    if let allEvents {
                                        imageURL = allEvents.first { $0.id == news.relatedID }?.logoImageURL(in: news.locale ?? .jp) ?? nil
                                    }
                                }
                                .onChange(of: allEvents) {
                                    if imageURL == nil, let allEvents {
                                        imageURL = allEvents.first { $0.id == news.relatedID }?.logoImageURL(in: news.locale ?? .jp) ?? nil
                                    }
                                }
                        }
                        .wrapIf({ if case .gacha = news.type { true } else { false } }()) { content in
                            content
                                .onAppear {
                                    if let allGacha {
                                        imageURL = allGacha.first { $0.id == news.relatedID }?.logoImageURL(in: news.locale ?? .jp) ?? nil
                                    }
                                }
                                .onChange(of: allEvents) {
                                    if imageURL == nil, let allGacha {
                                        imageURL = allGacha.first { $0.id == news.relatedID }?.logoImageURL(in: news.locale ?? .jp) ?? nil
                                    }
                                }
                        }
                        .wrapIf({ if case .song = news.type { true } else { false } }()) { content in
                            content
                                .onAppear {
                                    if let allSongs {
                                        imageURL = allSongs.first { $0.id == news.relatedID }?.jacketImageURL(in: news.locale ?? .jp) ?? nil
                                    }
                                }
                                .onChange(of: allEvents) {
                                    if imageURL == nil, let allSongs {
                                        imageURL = allSongs.first { $0.id == news.relatedID }?.jacketImageURL(in: news.locale ?? .jp) ?? nil
                                    }
                                }
                        }
                }
            }
        }
    }
    func getDetailsLineString(author: String, tags: [String], separator: String = "  ") -> SwiftUI.Text {
        let tagsCombined = news.tags.map { "#\($0)" }.joined(separator: separator)
        return Text(author).bold() + Text(separator) + Text(tagsCombined)
    }
}

let newsItemTypeIcon: [DoriFrontend.News.ListItem.ItemType: String] = [.article: "text.page", .event: "star.hexagon", .gacha: "dice", .loginCampaign: "calendar", .song: "music.microphone"]
let newsItemTypeColor: [DoriFrontend.News.ListItem.ItemType: Color] = [.article: .yellow, .event: .green, .gacha: .blue, .loginCampaign: .red, .song: .purple]
let newsItemTypeLocalizedString: [DoriFrontend.News.ListItem.ItemType: LocalizedStringResource] = [.article: "News.type.article", .event: "News.type.event", .gacha: "News.type.gacha", .loginCampaign: "News.type.login-campaign", .song: "News.type.song"]
//let newsTimeMarkTypeLocalizedString: [Dori]
