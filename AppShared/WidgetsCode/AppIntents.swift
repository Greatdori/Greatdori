//===---*- Greatdori! -*---------------------------------------------------===//
//
// AppIntents.swift
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
import WidgetKit
import AppIntents

struct CardWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Widget.cards" }
    static var description: IntentDescription { "Widget.cards.description" }
    
    @Parameter(title: "Widget.cards.parameter.name", optionsProvider: CardOptionsProvider())
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

struct CardCollectionWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Widget.collections" }
    static var description: IntentDescription { "Widget.collections.description" }
    
    @Parameter(title: "Widget.collections.parameter.name", optionsProvider: CollectionOptionsProvider())
    var collectionName: String?
    
    func perform() async throws -> some IntentResult {
        .result()
    }
    
    struct CollectionOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [String] {
            let collections = CardCollectionManager.shared.allCollections
            return collections.map { $0.name }
        }
    }
}
