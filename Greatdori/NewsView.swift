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

struct NewsView: View {
    @State var news: [DoriFrontend.News.ListItem]?
    @State var filter: DoriFrontend.News.ListFilter? = nil
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
                        NavigationLink(destination: {
                            switch news[newsIndex].type {
                            case .article:
                                //FIXME: [NAVI785]
                                EmptyView()
                            case .event:
                                EventDetailView(id: news[newsIndex].relatedID)
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
                            NewsPreview(news: news[newsIndex], showDetails: true, showImages: true)
                        })
                        .navigationBarBackButtonHidden()
                    }
                }
                .toolbar {
                    ToolbarItem(content: {
                        //TODO: PICKER -> MENU
                        Menu(content: {
                            Text("News.filter.selection.all")
                                .tag(nil as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.bestdori")
                                .tag(.bestdori as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.article")
                                .tag(.article as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.patch-note")
                                .tag(.patchNote as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.update")
                                .tag(.update as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.jp")
                                .tag(.locale(.jp) as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.en")
                                .tag(.locale(.en) as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.tw")
                                .tag(.locale(.tw) as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.cn")
                                .tag(.locale(.cn) as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.kr")
                                .tag(.locale(.kr) as DoriFrontend.News.ListFilter?)
                        }, label: {
                            Image(systemName: "line.3.horizontal.decrease")
                        })
                        Picker(selection: $filter, content: {
                            Text("News.filter.selection.all")
                                .tag(nil as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.bestdori")
                                .tag(.bestdori as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.article")
                                .tag(.article as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.patch-note")
                                .tag(.patchNote as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.update")
                                .tag(.update as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.jp")
                                .tag(.locale(.jp) as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.en")
                                .tag(.locale(.en) as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.tw")
                                .tag(.locale(.tw) as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.cn")
                                .tag(.locale(.cn) as DoriFrontend.News.ListFilter?)
                            Text("News.filter.selection.kr")
                                .tag(.locale(.kr) as DoriFrontend.News.ListFilter?)
                        }, label: {
                            
                        })
                        .pickerStyle(.menu)
                    })
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Home.news")
        .task {
            DoriCache.withCache(id: "News", trait: .realTime) {
                await DoriFrontend.News.list(filter: filter)
            } .onUpdate {
                news = $0
            }
        }
        .onChange(of: filter, {
            Task {
                DoriCache.withCache(id: "News", trait: .realTime) {
                    await DoriFrontend.News.list(filter: filter)
                } .onUpdate {
                    news = $0
                }
            }
        })
    }
}

struct NewsPreview: View {
    @State var imageURL: URL? = nil
    var news: DoriFrontend.News.ListItem
    var showLocale: Bool = true
    var showDetails: Bool = false
    var showImages: Bool = false
    var dateFormatter = DateFormatter()
    init(news: DoriFrontend.News.ListItem, showLocale: Bool = true, showDetails: Bool = false, showImages: Bool = false) {
        self.news = news
        self.showLocale = showLocale
        self.showDetails = showDetails
        self.showImages = showImages
        //        dateFormatter.dateStyle = .short
        //        dateFormatter.timeStyle = .short
        dateFormatter.setLocalizedDateFormatFromTemplate(showDetails ? "YMdjm" : "Mdjm")
    }
    var body: some View {
        HStack {
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
                
                if showDetails {
                    HStack {
                        //                    Text("News.author.\(news.author)")
                        Text(news.author)
                            .font(.caption)
                            .bold()
                        ForEach(0..<news.tags.count, id: \.self) { tagIndex in
                            Text("#\(news.tags[tagIndex])")
                                .font(.caption)
                            //                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            Spacer()
            
            if showImages {
                ViewThatFits {
                    Group {
                        if let imageURL {
                            WebImage(url: imageURL)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 75)
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
                }
                .task {
                    switch news.type {
                    case .event:
                        imageURL = await DoriFrontend.Event.Event(id: news.relatedID)?.logoImageURL(in: news.locale ?? .jp) ?? nil
                    case .gacha:
                        imageURL = await DoriFrontend.Gacha.Gacha(id: news.relatedID)?.logoImageURL(in: news.locale ?? .jp) ?? nil
                    case .song:
                        imageURL = await DoriAPI.Song.detail(of: news.relatedID)?.jacketImageURL(in: news.locale ?? .jp) ?? nil
                    default:
                        imageURL = nil
                    }
                }
            }
        }
        
    }
}

let newsItemTypeIcon: [DoriFrontend.News.ListItem.ItemType: String] = [.article: "text.page", .event: "star.hexagon", .gacha: "dice", .loginCampaign: "calendar", .song: "music.microphone"]
let newsItemTypeColor: [DoriFrontend.News.ListItem.ItemType: Color] = [.article: .gray, .event: .green, .gacha: .blue, .loginCampaign: .red, .song: .purple]
let newsItemTypeLocalizedString: [DoriFrontend.News.ListItem.ItemType: LocalizedStringResource] = [.article: "News.type.article", .event: "News.type.event", .gacha: "News.type.gacha", .loginCampaign: "News.type.login-campaign", .song: "News.type.song"]
//let newsTimeMarkTypeLocalizedString: [Dori]

