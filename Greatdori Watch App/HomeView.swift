//
//  HomeView.swift
//  Greatdori
//
//  Created by Mark Chan on 7/23/25.
//

import SwiftUI
import DoriKit
import SDWebImageSwiftUI

struct HomeView: View {
    @State var news: [DoriFrontend.News.ListItem]?
    @State var birthdays: [DoriFrontend.Character.BirthdayCharacter]?
    @State var latestEvents: DoriAPI.LocalizedData<DoriFrontend.Event.PreviewEvent>?
    var body: some View {
        Form {
            Section {
                if let news {
                    ForEach(news.prefix(5), id: \.title) { item in
                        NavigationLink(destination: {  }) {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold))
                                Text({
                                    let df = DateFormatter()
                                    df.dateStyle = .medium
                                    df.timeStyle = .short
                                    return df.string(from: item.timestamp)
                                }())
                                .font(.system(size: 12))
                                .opacity(0.6)
                            }
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } header: {
                Text("资讯")
            }
            Section {
                if let birthdays {
                    ForEach(birthdays) { character in
                        NavigationLink(destination: { CharacterDetailView(id: character.id) }) {
                            HStack {
                                WebImage(url: character.iconImageURL)
                                    .resizable()
                                    .clipShape(Circle())
                                    .frame(width: 30, height: 30)
                                Text("\(character.birthday.components(in: .init(identifier: "Asia/Tokyo")!).month!)月\(character.birthday.components(in: .init(identifier: "Asia/Tokyo")!).day!)日")
                            }
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } header: {
                Text("生日")
            }
            Section {
                if let latestEvents {
                    ForEach(DoriAPI.Locale.allCases, id: \.rawValue) { locale in
                        NavigationLink(destination: { EventDetailView(id: latestEvents.forLocale(locale)!.id) }) {
                            if locale != .kr {
                                EventCardView(latestEvents.forLocale(locale)!, inLocale: locale, showsCountdown: true)
                            } else {
                                EventCardView(latestEvents.forLocale(locale)!, inLocale: locale, showsCountdown: true)
                                    .grayscale(1)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                } else {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } header: {
                Text("活动")
            }
        }
        .navigationTitle("主页")
        .task {
            DoriCache.withCache(id: "Home_News") {
                await DoriFrontend.News.list()
            }.onUpdate {
                news = $0
            }
        }
        .task {
            DoriCache.withCache(id: "Home_Birthdays") {
                await DoriFrontend.Character.recentBirthdayCharacters()
            }.onUpdate {
                birthdays = $0
            }
        }
        .task {
            DoriCache.withCache(id: "Home_LatestEvents") {
                await DoriFrontend.Event.localizedLatestEvent()
            }.onUpdate {
                latestEvents = $0
            }
        }
    }
}
