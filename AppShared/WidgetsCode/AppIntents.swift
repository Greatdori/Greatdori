//
//  AppIntents.swift
//  Greatdori
//
//  Created by Mark Chan on 8/5/25.
//

import DoriKit
import WidgetKit
import AppIntents

struct CardWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Widget.cards" }
    static var description: IntentDescription { "Widget.cards.description" }
    
    @Parameter(title: "Widget.cards.name", optionsProvider: CardOptionsProvider())
    var cardName: String?
    
    struct CardOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [String] {
            let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.memz233.Greatdori.Widgets")!.path
            let decoder = PropertyListDecoder()
            guard let data = try? Data(contentsOf: URL(filePath: containerPath + "/CardWidgetDescriptors.plist")) else { return [] }
            guard let descriptors = try? decoder.decode([CardWidgetDescriptor].self, from: data) else { return [] }
            return descriptors.map { $0.localizedName }
        }
    }
}
