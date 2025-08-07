//
//  CardWidgets.swift
//  Greatdori Widgets
//
//  Created by Mark Chan on 8/5/25.
//

import DoriKit
import SwiftUI
import WidgetKit
import AppIntents

struct CardWidgets: Widget {
    let kind: String = "com.memz233.Greatdori.Widgets.Card"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CardWidgetIntent.self, provider: Provider()) { entry in
            CardWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.accessoryRectangular])
        .contentMarginsDisabled()
        .configurationDisplayName("卡面")
        .description("展示指定卡面")
    }
}

private struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CardEntry {
        .init()
    }
    
    func recommendations() -> [AppIntentRecommendation<CardWidgetIntent>] {
        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.memz233.Greatdori.Widgets")!.path
        let decoder = PropertyListDecoder()
        guard let data = try? Data(contentsOf: URL(filePath: containerPath + "/CardWidgetDescriptors.plist")) else { return [] }
        guard let descriptors = try? decoder.decode([CardWidgetDescriptor].self, from: data) else { return [] }
        return descriptors.map { .init(intent: .init(cardName: .init(title: .init(stringLiteral: $0.localizedName))), description: Text($0.localizedName)) }
    }
    
    func snapshot(for configuration: CardWidgetIntent, in context: Context) async -> CardEntry {
        if context.isPreview {
            return .init(image: .init(named: "CardWidgetPlaceholder", in: #bundle, with: nil))
        }
        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.memz233.Greatdori.Widgets")!.path
        let decoder = PropertyListDecoder()
        guard let data = try? Data(contentsOf: URL(filePath: containerPath + "/CardWidgetDescriptors.plist")) else { return .init() }
        guard let descriptors = try? decoder.decode([CardWidgetDescriptor].self, from: data) else { return .init() }
        guard let imageURL = descriptors.first(where: { $0.localizedName == configuration.cardName })?.imageURL else { return .init() }
        guard let imageData = try? Data(contentsOf: imageURL) else { return .init() }
        let image = UIImage(data: imageData)?.resized(to: .init(width: 204, height: 90))
        return .init(image: image)
    }
    
    func timeline(for configuration: CardWidgetIntent, in context: Context) async -> Timeline<Entry> {
        .init(
            entries: [await snapshot(for: configuration, in: context)],
            policy: .never
        )
    }
}

private struct CardEntry: TimelineEntry {
    let date: Date = .now
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
            Text("按住后轻触“编辑小组件”以选择卡面")
                .padding()
        }
    }
}
