//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardCollectionWidgets.swift
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
        .configurationDisplayName("Widget.collections")
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
        .init(
            entries: [entry(align: false, in: configuration.collectionName)],
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
    #if !os(macOS)
    var image: UIImage?
    #else
    var image: NSImage?
    #endif
}

private struct CardWidgetsEntryView : View {
    var entry: Provider.Entry
    var body: some View {
        if let image = entry.image {
            Button(intent: CardCollectionWidgetIntent()) {
                #if !os(macOS)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                #else
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                #endif
            }
            .buttonStyle(.plain)
        } else {
            Text("Widget.collections.edit-tip")
                .padding()
        }
    }
}
