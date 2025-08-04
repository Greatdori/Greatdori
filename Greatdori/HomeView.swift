//
//  HomeView.swift
//  Greatdori
//
//  Created by ThreeManager785 on 2025/7/27.
//

import SwiftUI
import DoriKit
import SDWebImageSwiftUI

let loadingAnimationDuration = 0.1
let localeFromStringDict: [String: DoriAPI.Locale] = ["jp": .jp, "cn": .cn, "tw": .tw, "en": .en, "kr": .kr]
let localeToStringDict: [DoriAPI.Locale: String] = [.jp: "JP", .en: "EN", .tw: "TW", .cn: "CN", .kr: "KR"]

struct HomeView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.platform) var platform
    @Environment(\.colorScheme) var colorScheme
    @State var pageWidth: CGFloat = 600
    @State var showSettingsSheet = false
    @AppStorage("homeEventServer1") var homeEventServer1 = "jp"
    @AppStorage("homeEventServer2") var homeEventServer2 = "cn"
    @AppStorage("homeEventServer3") var homeEventServer3 = "tw"
    @AppStorage("homeEventServer4") var homeEventServer4 = "en"
    var body: some View {
        NavigationStack {
            ScrollView {
                if pageWidth > 675 {
                    HStack {
                        VStack {
                            CustomGroupBox { HomeNewsView() }
                            CustomGroupBox { HomeBirthdayView() }
                            CustomGroupBox { HomeEventsView(locale: localeFromStringDict[homeEventServer4] ?? .jp) }
                            Spacer()
                        }
                        VStack {
                            CustomGroupBox { HomeEventsView(locale: localeFromStringDict[homeEventServer1] ?? .jp) }
                            CustomGroupBox { HomeEventsView(locale: localeFromStringDict[homeEventServer2] ?? .jp) }
                            CustomGroupBox { HomeEventsView(locale: localeFromStringDict[homeEventServer3] ?? .jp) }
                            Spacer()
                        }
                    }
                    .padding()
                } else {
                    VStack {
                        CustomGroupBox { HomeNewsView() }
                        CustomGroupBox { HomeBirthdayView() }
                        CustomGroupBox { HomeEventsView(locale: localeFromStringDict[homeEventServer1] ?? .jp) }
                        CustomGroupBox { HomeEventsView(locale: localeFromStringDict[homeEventServer2] ?? .jp) }
                        CustomGroupBox { HomeEventsView(locale: localeFromStringDict[homeEventServer3] ?? .jp) }
                        CustomGroupBox { HomeEventsView(locale: localeFromStringDict[homeEventServer4] ?? .jp) }
                    }
                    .padding()
                }
                
            }
            
            .background(groupedContentBackgroundColor())
            .navigationTitle("App.home")
            .toolbar {
                if platform != .mac && sizeClass == .compact {
                    ToolbarItem(placement: .automatic, content: {
                        Button(action: {
                            showSettingsSheet = true
                        }, label: {
                            Image(systemName: "gear")
                        })
                    })
                }
            }
            .sheet(isPresented: $showSettingsSheet, content: {
                SettingsView()
            })
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        pageWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) {
                        pageWidth = geometry.size.width
                    }
            }
        )
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
                        if news != nil {
                            Text("Home.news")
                                .font(.title2)
                                .bold()
                        } else {
                            Text("Home.news")
                                .font(.title2)
                                .bold()
                                .redacted(reason: .placeholder)
                        }
                        Spacer()
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
                    } else {
                        ForEach(0..<5, id: \.self) { i in
                            VStack(alignment: .leading) {
                                Text(verbatim: "Lorem ipsum dolor sit amet consectetur adipiscing elit.")
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                                    .bold()
                                    .redacted(reason: .placeholder)
                                Text(verbatim: "2000/01/01 12:00")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .redacted(reason: .placeholder)
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
        .animation(.easeInOut(duration: loadingAnimationDuration), value: news?.count)
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
    @AppStorage("debugShowHomeBirthdayDatePicker") var debugShowHomeBirthdayDatePicker = false
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
                    } else if birthdays != nil {
                        Text("Home.birthday")
                            .font(.title2)
                            .bold()
                    } else {
                        Text("Home.birthday")
                            .font(.title2)
                            .bold()
                            .redacted(reason: .placeholder)
                    }
                    Spacer()
                    if debugShowHomeBirthdayDatePicker {
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
                                                .frame(width: imageButtonSize, height: imageButtonSize)
#endif
                                            Text(birthdays[i+1].characterName.forPreferredLocale() ?? "")
                                        }
                                    })
                                }, label: {
                                    WebImage(url: birthdays[i].iconImageURL)
                                        .resizable()
                                        .clipShape(Circle())
                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                        .zIndex(2)
                                    WebImage(url: birthdays[i+1].iconImageURL)
                                        .resizable()
                                        .clipShape(Circle())
                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                        .padding(.leading, -15)
                                        .zIndex(1)
                                    Text(formatter.string(from: birthdays[i].birthday))
                                })
                                Rectangle()
                                    .opacity(0)
                                    .frame(width: 2, height: 2)
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
                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                    if todaysHerBirthday(birthdays[i].birthday, debugDate) {
                                        Text(birthdays[i].characterName.forPreferredLocale() ?? "")
                                    } else {
                                        Text(formatter.string(from: birthdays[i].birthday))
                                    }
                                })
                                .buttonStyle(.plain)
                                Rectangle()
                                    .opacity(0)
                                    .frame(width: 2, height: 2)
                            }
                        }
                    }
                } else {
                    HStack {
                        Text(verbatim: "Lorem ipsum")
                            .redacted(reason: .placeholder)
                        Rectangle()
                            .opacity(0)
                            .frame(width: 2, height: 2)
                        Text(verbatim: "dolor sit")
                            .redacted(reason: .placeholder)
                        Spacer()
                    }
                }
            }
            Spacer()
        }
        .animation(.easeInOut(duration: loadingAnimationDuration), value: birthdays?.count)
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .task {
            DoriCache.withCache(id: "Home_Birthdays") {
                await DoriFrontend.Character.recentBirthdayCharacters()
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
    @State var imageOpacity: Double = 0
    @State var placeholderOpacity: Double = 1
    var locale: DoriAPI.Locale = .jp
    var dateFormatter = DateFormatter()
    init(locale: DoriAPI.Locale = .jp) {
        self.locale = locale
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
    }
    
    var body: some View {
        ZStack {
            Group {
                if let latestEvents {
                    NavigationLink(destination: {
                        EventDetailView(id: latestEvents.forLocale(locale)!.id)
//                        EventDetailView(id: 1)
                    }, label: {
                        EventCardView(latestEvents.forLocale(locale)!, inLocale: locale, showsCountdown: true)
                    })
                    .buttonStyle(.plain)
                }
            }
            .opacity(imageOpacity)
            .zIndex(2)
            Group {
                if latestEvents == nil {
                    VStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.15))
                            .aspectRatio(3.0, contentMode: .fit)
                        Text(verbatim: "Lorem ipsum dolor sit amet consectetur")
                            .bold()
                            .font(.title3)
                            .redacted(reason: .placeholder)
                        Text(verbatim: "Lorem ipsum dolor")
                            .redacted(reason: .placeholder)
                    }
                }
            }
            .opacity(placeholderOpacity)
            .zIndex(1)
        }
        .foregroundStyle(.primary)
        .task {
            DoriCache.withCache(id: "Home_LatestEvents") {
                await DoriFrontend.Event.localizedLatestEvent()
            } .onUpdate {
                latestEvents = $0
                withAnimation(.easeInOut(duration: loadingAnimationDuration), {
//                    placeholderOpacity = 0
                    imageOpacity = 1
                })
            }
        }
    }
}






