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
                            NewsPreview(news: news[newsIndex], showLocale: {
                                if case .locale = filter { false } else { true }
                            }(), showDetails: true, showImages: true)
                        })
//                        .navigationBarBackButtonHidden()
//                        .navigationLinkIndicatorVisibility(.hidden)
                    }
                }
                .toolbar {
                    ToolbarItem(content: {
                        Menu(content: {
                            ForEach(0..<filterOptions.count, id: \.self) { filterIndex in
                                Button(action: {
                                    filter = filterOptions[filterIndex]
                                }, label: {
                                    HStack {
                                        if filter == filterOptions[filterIndex] {
                                            Image(systemName: "checkmark")
                                        }
                                        Text(filterLocalizedString[filterOptions[filterIndex]]!)
                                    }
                                })
                            }
                        }, label: {
                            if let filter {
                                Image(systemName: "line.3.horizontal.decrease")
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    .background {
                                        Capsule().foregroundStyle(.blue).scaledToFill().scaleEffect(1.3)
                                    }
                            } else {
                                Image(systemName: "line.3.horizontal.decrease")
                            }
                        })
                    })
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Home.news")
        .wrapIf(true, in: { content in
            if filter != nil {
                if #available(iOS 26.0, *) {
                    content
                        .navigationSubtitle(filterLocalizedString[filter]!)
                } else {
                    content
                }
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

//MARK: NewsPreview
struct NewsPreview: View {
    @Environment(\.horizontalSizeClass) var sizeClass
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
                if sizeClass == .regular {
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
}

let newsItemTypeIcon: [DoriFrontend.News.ListItem.ItemType: String] = [.article: "text.page", .event: "star.hexagon", .gacha: "dice", .loginCampaign: "calendar", .song: "music.microphone"]
let newsItemTypeColor: [DoriFrontend.News.ListItem.ItemType: Color] = [.article: .gray, .event: .green, .gacha: .blue, .loginCampaign: .red, .song: .purple]
let newsItemTypeLocalizedString: [DoriFrontend.News.ListItem.ItemType: LocalizedStringResource] = [.article: "News.type.article", .event: "News.type.event", .gacha: "News.type.gacha", .loginCampaign: "News.type.login-campaign", .song: "News.type.song"]
//let newsTimeMarkTypeLocalizedString: [Dori]


extension View {
      public func inverseMask<Mask: View>(
        @ViewBuilder _ mask: () -> Mask,
        alignment: Alignment = .center
      ) -> some View {
            self.mask {
                  Rectangle()
                    .overlay(alignment: alignment) {
                          mask().blendMode(.destinationOut)
                        }
                }
          }
}
