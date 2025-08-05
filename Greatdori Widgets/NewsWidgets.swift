//
//  NewsWidgets.swift
//  Greatdori
//
//  Created by Mark Chan on 8/5/25.
//

import DoriKit
import SwiftUI
import WidgetKit

struct NewsWidgets: Widget {
    let kind: String = "com.memz233.Greatdori.Widgets.News"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CardWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
        .configurationDisplayName("资讯")
        .description("查看最新资讯")
    }
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NewsEntry {
        .init(date: .now, news: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NewsEntry) -> Void) {
        if context.isPreview {
            completion(.init(date: .now))
            return
        }
        getNewsList { news in
            completion(.init(date: .now, news: news))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let calendar = Calendar.current
        let now = Date.now
        let nextUpdateDate: Date
        if now.components.minute! < 30 {
            nextUpdateDate = calendar.date(byAdding: .hour, value: 1, to: now)!.componentsRewritten(minute: 1, second: 30)
        } else {
            nextUpdateDate = calendar.date(byAdding: .hour, value: 2, to: now)!.componentsRewritten(minute: 1, second: 30)
        }
        getNewsList { news in
            completion(.init(entries: [.init(date: .now, news: news)], policy: .after(nextUpdateDate)))
        }
    }
    
    func getNewsList(completion: @escaping ([DoriFrontend.News.ListItem]?) -> Void) {
        Task {
            let cacheURL = URL(filePath: NSHomeDirectory() + "/Library/Caches/Greatdori_Widget_News.cache")
            
            for _ in 0..<5 {
                if let news = await DoriFrontend.News.list() {
                    completion(news)
                    try? news.dataForCache.write(to: cacheURL)
                    return
                }
            }
            
            if let cachedData = try? Data(contentsOf: cacheURL) {
                completion(.init(fromCache: cachedData))
                return
            }
            
            completion(nil)
        }
    }
}

private struct NewsEntry: TimelineEntry {
    let date: Date
    var news: [DoriFrontend.News.ListItem]?
}

private struct CardWidgetsEntryView : View {
    var entry: Provider.Entry
    let dateFormatter = {
        let result = DateFormatter()
        result.dateStyle = .medium
        result.timeStyle = .short
        return result
    }()
    
    @Environment(\.widgetFamily) var widgetFamily
    var capacity: Int {
        switch widgetFamily {
        case .systemMedium: 1
        case .systemLarge: 5
        case .systemExtraLarge: 5
        default: 5
        }
    }
    var titleFont: Font {
        switch widgetFamily {
        case .systemMedium: .subheadline
        case .systemLarge: .body
        case .systemExtraLarge: .body
        default: .body
        }
    }
    var dateFont: Font {
        switch widgetFamily {
        case .systemMedium: .caption2
        case .systemLarge: .caption
        case .systemExtraLarge: .caption
        default: .caption
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("资讯")
                        .font(.title2)
                        .bold()
                    _HSpacer()
                }
                Rectangle()
                    .frame(height: 2)
                    .opacity(0)
                if let news = entry.news {
                    ForEach(0..<news.prefix(capacity).count, id: \.self) { i in
                        VStack(alignment: .leading) {
                            Text(news[i].title)
                                .font(titleFont)
                                .foregroundStyle(.primary)
                                .bold()
                                .lineLimit(2)
                            Text(dateFormatter.string(from: news[i].timestamp))
                                .font(dateFont)
                                .foregroundStyle(.secondary)
                        }
                        
                        if widgetFamily == .systemLarge || widgetFamily == .systemExtraLarge && i != 4 {
                            Rectangle()
                                .frame(height: 1)
                                .opacity(0)
                        }
                    }
                } else {
                    ForEach(0..<capacity, id: \.self) { i in
                        VStack(alignment: .leading) {
                            Text(verbatim: "Lorem ipsum dolor sit amet consectetur adipiscing elit.")
                                .font(titleFont)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                                .bold()
                                .redacted(reason: .placeholder)
                            Text(verbatim: "2000/01/01 12:00")
                                .font(dateFont)
                                .foregroundStyle(.secondary)
                                .redacted(reason: .placeholder)
                        }
                        
                        if widgetFamily == .systemLarge || widgetFamily == .systemExtraLarge && i != 4 {
                            Rectangle()
                                .frame(height: 1)
                                .opacity(0)
                        }
                    }
                }
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.1), value: entry.news?.count)
    }
}
