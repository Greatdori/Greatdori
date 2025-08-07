//
//  CardCollectionWidgets.swift
//  Greatdori Widgets
//
//  Created by Mark Chan on 8/7/25.
//

import DoriKit
import SwiftUI
import WidgetKit

struct CardCollectionWidgets: Widget {
    let kind: String = "com.memz233.Greatdori.Widgets.CardCollection"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CardCollectionWidgetIntent.self, provider: Provider()) { entry in
            CardWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
        .configurationDisplayName("卡面精选集")
        .description("随机展示指定卡面精选集")
    }
}

private struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CardEntry {
        .init()
    }

    func snapshot(for configuration: CardCollectionWidgetIntent, in context: Context) async -> CardEntry {
        if context.isPreview {
            return entry(in: "BUILTIN_CARD_COLLECTION_GREATDORI")
        }
        return entry(in: configuration.collectionName)
    }
    
    func timeline(for configuration: CardCollectionWidgetIntent, in context: Context) async -> Timeline<Entry> {
        var entries = [CardEntry]()
        var date = Date.now
        let calendar = Calendar.current
        for _ in 0..<48 {
            entries.append(entry(for: date, in: configuration.collectionName))
            date = calendar.date(byAdding: .minute, value: 30, to: date)!
        }
        return .init(
            entries: entries,
            policy: .atEnd
        )
    }
    
    func entry(for date: Date = .now, in collection: String?) -> CardEntry {
        guard let collectionName = collection else { return .init() }
        guard let collection = CardCollectionManager.shared._collection(named: collectionName) else { return .init() }
        var generator = seed(for: date)
        guard let card = collection.cards.randomElement(using: &generator) else { return .init() }
        guard let image = UIImage(data: card.imageData) else { return .init() }
        return .init(date: date, image: image)
    }
    
    func seed(for date: Date = .now) -> some RandomNumberGenerator {
        struct RandomNumberGeneratorWithSeed: RandomNumberGenerator {
            init(seed: Int) {
                srand48(seed)
            }
            func next() -> UInt64 {
                return withUnsafeBytes(of: drand48()) { bytes in
                    bytes.load(as: UInt64.self)
                }
            }
        }
        
        var date = date
        date = date.componentsRewritten(second: 0)
        let seed = Int(date.timeIntervalSince1970)
        return RandomNumberGeneratorWithSeed(seed: seed)
    }
}

private struct CardEntry: TimelineEntry {
    var date: Date = .now
    var image: UIImage?
}

private struct CardWidgetsEntryView : View {
    var entry: Provider.Entry
    var body: some View {
        if let image = entry.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Text("按住后轻触“编辑小组件”以选择精选集")
                .padding()
        }
    }
}
