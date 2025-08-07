//
//  SettingsView.swift
//  Greatdori
//
//  Created by Mark Chan on 8/7/25.
//

import SwiftUI
import DoriKit
import WidgetKit

struct SettingsView: View {
    @State var cardIDInput = ""
    var body: some View {
        List {
            Section {
                TextField("卡牌 ID", text: $cardIDInput)
                    .submitLabel(.done)
                    .onSubmit {
                        let ids = cardIDInput
                            .replacingOccurrences(of: " ", with: "")
                            .components(separatedBy: ",")
                            .compactMap {
                                if let direct = Int($0) {
                                    // "2125"
                                    return (id: direct, trained: false)
                                } else if $0.contains(":") {
                                    // "1954:after"
                                    let separated = $0.components(separatedBy: ":")
                                    guard separated.count == 2 else { return nil }
                                    guard let id = Int(separated[0]) else { return nil }
                                    return (id: id, trained: separated[1] == "after")
                                } else {
                                    return nil
                                }
                            }
                        Task {
                            if let cards = await DoriAPI.Card.all() {
                                let relatedCards = cards.compactMap { card in
                                    if ids.map({ $0.id }).contains(card.id) {
                                        (card: card, trained: ids.first(where: { $0.id == card.id })!.trained)
                                    } else {
                                        nil
                                    }
                                }
                                var descriptors = [CardWidgetDescriptor]()
                                for (card, trained) in relatedCards {
                                    descriptors.append(
                                        .init(
                                            cardID: card.id,
                                            trained: trained,
                                            localizedName: card.prefix.forPreferredLocale() ?? "",
                                            imageURL: trained ? (card.coverAfterTrainingImageURL ?? card.coverNormalImageURL) : card.coverNormalImageURL
                                        )
                                    )
                                }
                                let encoder = PropertyListEncoder()
                                encoder.outputFormat = .binary
                                let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.memz233.Greatdori.Widgets")!.path
                                try? encoder.encode(descriptors).write(to: URL(filePath: containerPath + "/CardWidgetDescriptors.plist"))
                                WidgetCenter.shared.reloadTimelines(ofKind: "com.memz233.Greatdori.Widgets.Card")
                                print("Widget update succeeded")
                            }
                        }
                    }
                    .task {
                        let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.memz233.Greatdori.Widgets")!.path
                        let decoder = PropertyListDecoder()
                        if let data = try? Data(contentsOf: URL(filePath: containerPath + "/CardWidgetDescriptors.plist")),
                           let descriptors = try? decoder.decode([CardWidgetDescriptor].self, from: data) {
                            cardIDInput = descriptors.map { String($0.cardID) + ($0.trained ? ":after" : ":before") }.joined(separator: ", ")
                        }
                    }
            } header: {
                Text("小组件设置 [INTERNAL]")
            } footer: {
                Text(verbatim: "[Card ID]:[before|after]\nWait console until 'Widget update succeeded' is printed.")
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}
