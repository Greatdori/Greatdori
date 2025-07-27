//
//  HomeView.swift
//  Greatdori
//
//  Created by ThreeManager785 on 2025/7/27.
//

import SwiftUI
import DoriKit
import SDWebImageSwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        NavigationStack {
            ScrollView {
                GeometryReader { geometry in
                    if geometry.size.width > 300 {
                        VStack {
                            CustomGroupBox {
                                HStack {
                                    HomeNewsView()
                                    Spacer()
                                }
                            }
                            HomeBirthdayView()
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        
                    } else {
//                        ScrollView {
                            HStack {
                                VStack {
                                    Text("1")
                                }
                                VStack {
                                    Text("2")
                                }
                            }
//                        }
                        //                    .navigationTitle("App.home")
                        
                    }
                }
            }
        }
        .navigationTitle("App.home")
        //        .padding()
    }
}


struct HomeNewsView: View {
    @State var news: [DoriFrontend.News.ListItem]?
    var dateFormatter = DateFormatter()
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
    }
    
    var body: some View {
        NavigationLink(destination: {
            
        }, label: {
            VStack(alignment: .leading) {
                Text("Home.news")
                    .font(.title2)
                    .bold()
                Rectangle()
                    .frame(height: 2)
                    .opacity(0)
                if let news {
                    ForEach(0..<news.prefix(5).count, id: \.self) { i in
                        
                        VStack(alignment: .leading) {
                            Text(news[i].title)
                                .foregroundStyle(.primary)
                                .bold()
                            Text(dateFormatter.string(from: news[i].timestamp))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if i != 4 {
                            Rectangle()
                                .frame(height: 6)
                                .opacity(0)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
        })
        .foregroundStyle(.primary)
        .task {
            DoriCache.withCache(id: "Home_News") {
                await DoriFrontend.News.list()
            } .onUpdate {
                news = $0
            }
        }
    }
}

struct HomeBirthdayView: View {
    @State var birthdays: [DoriFrontend.Character.BirthdayCharacter]?
    var formatter = DateFormatter()
    init() {
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        formatter.timeZone = .init(identifier: "Asia/Tokyo")
    }
    var body: some View {
        Group {
            if let birthdays {
                HStack {
                    ForEach(birthdays) { character in
                        NavigationLink(destination: {
                            //                        CharacterDetailView(id: character.id)
                        }) {
//                            HStack {
                                WebImage(url: character.iconImageURL)
                                    .resizable()
                                    .clipShape(Circle())
                                    .frame(width: 30, height: 30)
//                                Text("\(character.birthday)")c
                                Text(formatter.string(from: character.birthday))
//                            }
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
//            formatter.dateFormat = "MMM d"
//            formatter.timeStyle = .nill
//            formatter.timeZone = .init(identifier: "Asia/Tokyo")
//            let localized = formatter.string(from: date)
        }
        .task {
            DoriCache.withCache(id: "Home_Birthdays") {
                await DoriFrontend.Character.recentBirthdayCharacters()
            }.onUpdate {
                birthdays = $0
            }
        }
    }
}


/*
struct HomeView: View {
    @State var news: [DoriFrontend.News.ListItem]?
    @State var birthdays: [DoriFrontend.Character.BirthdayCharacter]?
    @State var latestEvents: DoriAPI.LocalizedData<DoriFrontend.Event.PreviewEvent>?
    var body: some View {
        Form {

            Section {
                if let latestEvents {
#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/HomeView.swift.gyb", line: 75)
                    NavigationLink(destination: { EventDetailView(id: latestEvents.jp!.id) }) {
                        if latestEvents.jp!.startAt.jp != nil {
                            EventCardView(latestEvents.jp!, inLocale: .jp, showsCountdown: true)
                        } else {
                            EventCardView(latestEvents.jp!, inLocale: .jp, showsCountdown: true)
                                .grayscale(1)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/HomeView.swift.gyb", line: 75)
                    NavigationLink(destination: { EventDetailView(id: latestEvents.en!.id) }) {
                        if latestEvents.en!.startAt.en != nil {
                            EventCardView(latestEvents.en!, inLocale: .en, showsCountdown: true)
                        } else {
                            EventCardView(latestEvents.en!, inLocale: .en, showsCountdown: true)
                                .grayscale(1)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/HomeView.swift.gyb", line: 75)
                    NavigationLink(destination: { EventDetailView(id: latestEvents.cn!.id) }) {
                        if latestEvents.cn!.startAt.cn != nil {
                            EventCardView(latestEvents.cn!, inLocale: .cn, showsCountdown: true)
                        } else {
                            EventCardView(latestEvents.cn!, inLocale: .cn, showsCountdown: true)
                                .grayscale(1)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/HomeView.swift.gyb", line: 75)
                    NavigationLink(destination: { EventDetailView(id: latestEvents.tw!.id) }) {
                        if latestEvents.tw!.startAt.tw != nil {
                            EventCardView(latestEvents.tw!, inLocale: .tw, showsCountdown: true)
                        } else {
                            EventCardView(latestEvents.tw!, inLocale: .tw, showsCountdown: true)
                                .grayscale(1)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/HomeView.swift.gyb", line: 75)
                    NavigationLink(destination: { EventDetailView(id: latestEvents.kr!.id) }) {
                        if latestEvents.kr!.startAt.kr != nil {
                            EventCardView(latestEvents.kr!, inLocale: .kr, showsCountdown: true)
                        } else {
                            EventCardView(latestEvents.kr!, inLocale: .kr, showsCountdown: true)
                                .grayscale(1)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/HomeView.swift.gyb", line: 86)
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

*/


struct CustomGroupBox<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        #if os(iOS)
        ZStack {
            RoundedRectangle(cornerRadius: 15)
//                .foregroundStyle(colorScheme == .dark ? Color(red: 44/255, green: 44/255, blue: 46/255) : Color(red: 1, green: 1, blue: 1))
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
            content()
                .padding()
        }
        #elseif os(macOS)
        GroupBox {
            content()
                .padding()
        }
        #endif
        
    }
}
