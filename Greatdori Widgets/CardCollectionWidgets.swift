//
//  CardCollectionWidgets.swift
//  Greatdori Widgets
//
//  Created by Mark Chan on 8/7/25.
//

import DoriKit
import SwiftUI
import WidgetKit
import AppIntents

struct CardCollectionWidgets: Widget {
    let kind: String = "com.memz233.Greatdori.Widgets.CardCollection"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CardCollectionWidgetIntent.self, provider: Provider()) { entry in
            CardWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
        .configurationDisplayName("Widget.collection")
        .description("Widget.collections.description")
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
            entries.append(entry(for: date, align: false, in: configuration.collectionName))
            date = calendar.date(byAdding: .minute, value: 30, to: date)!
        }
        return .init(
            entries: entries,
            policy: .atEnd
        )
    }
    
    func entry(for date: Date = .now, align: Bool = true, in collection: String?) -> CardEntry {
        guard let collectionName = collection else { return .init() }
        guard let collection = CardCollectionManager.shared._collection(named: collectionName) else { return .init() }
        var generator = seed(for: date, align: align)
        guard let card = collection.cards.randomElement(using: &generator) else { return .init() }
        guard let image = card.file.image else { return .init() }
        return .init(date: date, image: image)
    }
    
    func seed(for date: Date = .now, align: Bool = true) -> some RandomNumberGenerator {
        struct RandomNumberGeneratorWithSeed: RandomNumberGenerator {
            private var state: UInt64
            init(seed: UInt64) {
                self.state = UInt64(seed) ^ 0x5DEECE66D
            }
            mutating func next() -> UInt64 {
                state = state &* 0x5851F42D4C957F2D &+ 1
                return state
            }
        }
        
        var date = date
        if align {
            date = date.componentsRewritten(second: 0)
        }
        let seed = align ? UInt64(date.timeIntervalSince1970) : UInt64(date.timeIntervalSince1970 * 1000000)
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
            Button(intent: CardCollectionWidgetIntent()) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .buttonStyle(.plain)
        } else {
            Text("Widget.collections.edit-tip")
                .padding()
        }
    }
}
