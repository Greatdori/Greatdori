//
//  HomeView.swift
//  Greatdori
//
//  Created by ThreeManager785 on 2025/7/27.
//

import SwiftUI
import DoriKit
import SDWebImageSwiftUI

let debug = false

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var pageWidth: CGFloat = 600
    var body: some View {
        NavigationStack {
            ScrollView {
                if pageWidth > 675 {
                    HStack {
                        VStack {
                            CustomGroupBox {
                                HomeNewsView()
                            }
                            CustomGroupBox {
                                HomeBirthdayView()
                            }
                        }
                        VStack {
                            
                        }
                    }
                    .padding()
                } else {
                    VStack {
                        CustomGroupBox {
                            HomeNewsView()
                        }
                        CustomGroupBox {
                            HomeBirthdayView()
                        }
                        NavigationLink(destination: {
                            DebugBirthdayView()
                        }, label: {
                            Text(verbatim: "DebugBirthdayView()")
                                .fontDesign(.monospaced)
                        })
                    }
                    .padding()
                }
                //                        .background(groupedContentBackgroundColor())
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.size.width) {
                            pageWidth = geometry.size.width
                        }
                }
            )
            .navigationTitle("App.home")
        }
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
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Home.news")
                            .font(.title2)
                            .bold()
                        Spacer()
                        if news == nil {
                            ProgressView()
                        }
                    }
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
                                    .frame(height: 1)
                                    .opacity(0)
                            }
                        }
                    }
                }
                Spacer()
            }
        })
        .buttonStyle(.plain)
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
    var calendar = Calendar(identifier: .gregorian)
    @State var debugDate: Date = Date.now
    init() {
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        formatter.timeZone = .init(identifier: "Asia/Tokyo")
    }
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    if birthdays != nil && todaysHerBirthday(birthdays!.first!.birthday, debugDate) {
                        Text("Home.birthday.happy-birthday")
                            .font(.title2)
                            .bold()
                    } else {
                        Text("Home.birthday")
                            .font(.title2)
                            .bold()
                    }
                    Spacer()
                    
                    if debug {
                        DatePicker("", selection: $debugDate)
                        Button(action: {
                            Task {
                                DoriCache.withCache(id: "Home_Birthdays") {
                                    await DoriFrontend.Character.recentBirthdayCharacters(aroundDate: debugDate)
                                } .onUpdate {
                                    birthdays = $0
                                }
                            }
                        }, label: {
                            Text(verbatim: "[DEBUG REFRESH DATE]")
                        })
                    }
                    
                    if birthdays == nil {
                        ProgressView()
                    }
                }
                if let birthdays {
                    HStack {
                        ForEach(0..<birthdays.count, id: \.self) { i in
                            if (i != birthdays.count-1) && (birthdays[i].birthday == birthdays[i+1].birthday) && (!todaysHerBirthday(birthdays[i].birthday, debugDate)) {
                                // If she is not the last person & the person next have the same birthday & today's not her birthday.
                                // (Cond. 3 is because labels should be expanded to show their full name during their birthday.)
                                Menu(content: {
                                    NavigationLink(destination: {
                                        //TODO: Duo 1st
                                    }, label: {
                                        HStack {
#if os(iOS)
                                            WebImage(url: birthdays[i].iconImageURL)
                                                .resizable()
                                                .clipShape(Circle())
                                                .frame(width: 30, height: 30)
#endif
                                            Text(birthdays[i].characterName.forPreferredLocale() ?? "")
                                        }
                                    })
                                    NavigationLink(destination: {
                                        //TODO: Duo 2nd
                                    }, label: {
                                        HStack {
#if os(iOS)
                                            WebImage(url: birthdays[i+1].iconImageURL)
                                                .resizable()
                                                .clipShape(Circle())
                                                .frame(width: 30, height: 30)
#endif
                                            Text(birthdays[i+1].characterName.forPreferredLocale() ?? "")
                                        }
                                    })
                                }, label: {
                                    WebImage(url: birthdays[i].iconImageURL)
                                        .resizable()
                                        .clipShape(Circle())
                                        .frame(width: 30, height: 30)
                                        .zIndex(2)
                                    WebImage(url: birthdays[i+1].iconImageURL)
                                        .resizable()
                                        .clipShape(Circle())
                                        .frame(width: 30, height: 30)
                                        .padding(.leading, -15)
                                        .zIndex(1)
                                    Text(formatter.string(from: birthdays[i].birthday))
                                })
                                Rectangle()
                                    .opacity(0)
                                    .frame(width: 2)
                            } else if (i != 0) && (birthdays[i].birthday == birthdays[i-1].birthday) && (!todaysHerBirthday(birthdays[i].birthday, debugDate)) {
                                // If she is not the first person & the person in front have the same birthday & today's not her birthday.
                                EmptyView()
                            } else {
                                NavigationLink(destination: {
                                    //birthdays[i].id
                                }, label: {
                                    WebImage(url: birthdays[i].iconImageURL)
                                        .resizable()
                                        .clipShape(Circle())
                                        .frame(width: 30, height: 30)
                                    if todaysHerBirthday(birthdays[i].birthday, debugDate) {
                                        Text(birthdays[i].characterName.forPreferredLocale() ?? "")
                                    } else {
                                        Text(formatter.string(from: birthdays[i].birthday))
                                    }
                                })
                                .buttonStyle(.plain)
                                Rectangle()
                                    .opacity(0)
                                    .frame(width: 2)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .task {
            DoriCache.withCache(id: "Home_Birthdays") {
                                await DoriFrontend.Character.recentBirthdayCharacters()
//                await DoriFrontend.Character.recentBirthdayCharacters(aroundDate: debugDate)
            } .onUpdate {
                birthdays = $0
            }
        }
    }
    func todaysHerBirthday(_ date1: Date, _ date2: Date = Date()) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        var jstCalendar = calendar
        jstCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        
        
        var components = jstCalendar.dateComponents([.month, .day], from: date2)
        components.year = 2000
        let inputtedToday = jstCalendar.date(from: components)!
        
        
        
        return jstCalendar.isDate(date1, equalTo: inputtedToday, toGranularity: .day)
    }
}

struct HomeEventsView: View {
    @State var latestEvents: DoriAPI.LocalizedData<DoriFrontend.Event.PreviewEvent>?
    var dateFormatter = DateFormatter()
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
    }
    
    var body: some View {
        NavigationLink(destination: {
            
        }, label: {
            if let latestEvents {
//#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/HomeView.swift.gyb", line: 75)
                NavigationLink(destination: {
                    
                }, label: {
                    if latestEvents.jp!.startAt.jp != nil {
                        EventCardView(latestEvents.jp!, inLocale: .jp, showsCountdown: true)
                    } else {
                        EventCardView(latestEvents.jp!, inLocale: .jp, showsCountdown: true)
                            .grayscale(1)
                    }
                })
                
                /*
                 
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
                 */
                
            }
        })
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .task {
            DoriCache.withCache(id: "Home_LatestEvents") {
                await DoriFrontend.Event.localizedLatestEvent()
            } .onUpdate {
                latestEvents = $0
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


