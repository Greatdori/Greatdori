//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsView.swift
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

import SwiftUI
import DoriKit
import WidgetKit
import AuthenticationServices

struct SettingsView: View {
    @State var preferredLocale = DoriAPI.preferredLocale
    @State var cardIDInput = ""
    var body: some View {
        List {
            Section {
                Picker("首选服务器", selection: $preferredLocale) {
                    ForEach(DoriAPI.Locale.allCases, id: \.rawValue) { locale in
                        Text(locale.rawValue.uppercased()).tag(locale)
                    }
                }
                .onChange(of: preferredLocale) {
                    DoriAPI.preferredLocale = preferredLocale
                    DoriCache.invalidateAll()
                }
            }
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
                        Task.detached(priority: .userInitiated) {
                            if let cards = await DoriAPI.Card.all() {
                                let relatedCards = cards.compactMap { card in
                                    if ids.map({ $0.id }).contains(card.id) {
                                        (card: card, trained: ids.first(where: { $0.id == card.id })!.trained)
                                    } else {
                                        nil
                                    }
                                }
                                var descriptors = [CardWidgetDescriptor]()
                                let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.memz233.Greatdori.Widgets")!.path
                                try? FileManager.default.createDirectory(atPath: containerPath + "/Documents/WidgetSingleCards", withIntermediateDirectories: true)
                                for (card, trained) in relatedCards {
                                    let imageData = try? Data(contentsOf: trained ? (card.coverAfterTrainingImageURL ?? card.coverNormalImageURL) : card.coverNormalImageURL)
                                    let imageURL = URL(filePath: "/Documents/WidgetSingleCards/\(card.id).png")
                                    try? imageData?.write(to: imageURL)
                                    descriptors.append(
                                        .init(
                                            cardID: card.id,
                                            trained: trained,
                                            localizedName: card.prefix.forPreferredLocale() ?? "",
                                            imageURL: imageURL
                                        )
                                    )
                                }
                                let encoder = PropertyListEncoder()
                                encoder.outputFormat = .binary
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
            Section {
                NavigationLink(destination: { AboutView() }) {
                    Label("关于", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AboutView: View {
    var body: some View {
        List {
            Section {
                Button(action: {
                    let url = URL(string: "https://github.com/WindowsMEMZ/Greatdori")!
                    let session = ASWebAuthenticationSession(url: url, callbackURLScheme: nil) { _, _ in }
                    session.prefersEphemeralWebBrowserSession = true
                    session.start()
                }, label: {
                    HStack {
                        Text(verbatim: "GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                })
            } header: {
                Text("源代码")
            }
            Section {
                Text("App 内数据来源为 Bestdori!")
            } header: {
                Text("数据来源")
            }
            if NSLocale.current.language.languageCode!.identifier == "zh" {
                Section {
                    Button(action: {
                        let session = ASWebAuthenticationSession(
                            url: URL(string: "https://beian.miit.gov.cn")!,
                            callbackURLScheme: nil
                        ) { _, _ in }
                        session.prefersEphemeralWebBrowserSession = true
                        session.start()
                    }, label: {
                        Text(verbatim: "蜀ICP备2025125473号-NNA") // FIXME
                    })
                } header: {
                    Text(verbatim: "中国大陆ICP备案号")
                }
            }
        }
        .navigationTitle("关于")
    }
}
