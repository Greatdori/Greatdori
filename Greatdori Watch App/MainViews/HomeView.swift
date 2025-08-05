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
    @State var availability = [true, true, true]
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
                    if availability[0] {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        UnavailableView("载入资讯时出错", systemImage: "newspaper.fill", retryHandler: getNews)
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
                    if availability[1] {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        UnavailableView("载入生日时出错", systemImage: "birthday.cake.fill", retryHandler: getBirthdays)
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
                    if availability[2] {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        UnavailableView("载入活动时出错", systemImage: "star.hexagon.fill", retryHandler: getEvents)
                    }
                }
            } header: {
                Text("活动")
            }
        }
        .navigationTitle("主页")
        .task {
            await getNews()
        }
        .task {
            await getBirthdays()
        }
        .task {
            await getEvents()
        }
    }
    
    func getNews() async {
        availability[0] = true
        DoriCache.withCache(id: "Home_News") {
            await DoriFrontend.News.list()
        }.onUpdate {
            if let news = $0 {
                self.news = news
            } else {
                availability[0] = false
            }
        }
    }
    func getBirthdays() async {
        availability[1] = true
        DoriCache.withCache(id: "Home_Birthdays") {
            await DoriFrontend.Character.recentBirthdayCharacters()
        }.onUpdate {
            if let birthdays = $0 {
                self.birthdays = birthdays
            } else {
                availability[1] = false
            }
        }
    }
    func getEvents() async {
        availability[2] = true
        DoriCache.withCache(id: "Home_LatestEvents") {
            await DoriFrontend.Event.localizedLatestEvent()
        }.onUpdate {
            if let latestEvents = $0 {
                self.latestEvents = latestEvents
            } else {
                availability[2] = false
            }
        }
    }
}
