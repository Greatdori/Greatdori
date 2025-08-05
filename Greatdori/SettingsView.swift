//
//  SettingsView.swift
//  Greatdori
//
//  Created by ThreeManager785 on 2025/7/29.
//

import SwiftUI
import DoriKit
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Settings.server") {
                    SettingsServerView()
                }
                Section(content: {
                    SettingsHomeView()
                }, header: {
                    Text("Settings.home-edit")
                }, footer: {
                    Text("Settings.home-edit.footer")
                })
                Section {
                    SettingsWidgetView()
                } header: {
                    Text("小组件")
                }
                
                #if DEBUG
                Section(content: {
                    SettingsDebugView()
                }, header: {
                    Text("Settings.debug")
                })
                #endif
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            #if !os(macOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton(action: dismiss.callAsFunction) {
                        Image(systemName: "xmark")
                    }
                }
            }
            #endif
        }
    }
}

struct SettingsServerView: View {
    @State var primaryLocale = "jp"
    @State var secondaryLocale = "en"
    @State var server: String = "jp"
    var body: some View {
        Group {
            Picker(selection: $primaryLocale, content: {
                Text("Home.servers.selection.jp")
                    .tag("jp")
                    .disabled(secondaryLocale == "jp")
                Text("Home.servers.selection.en")
                    .tag("en")
                    .disabled(secondaryLocale == "en")
                Text("Home.servers.selection.cn")
                    .tag("cn")
                    .disabled(secondaryLocale == "cn")
                Text("Home.servers.selection.tw")
                    .tag("tw")
                    .disabled(secondaryLocale == "tw")
                Text("Home.servers.selection.kr")
                    .tag("kr")
                    .disabled(secondaryLocale == "kr")
            }, label: {
                Text("Settings.servers.primaryLocale")
            })
            .onChange(of: primaryLocale, {
                DoriAPI.preferredLocale = localeFromStringDict[primaryLocale] ?? .jp
            })
            Picker(selection: $secondaryLocale, content: {
                Text("Home.servers.selection.jp")
                    .tag("jp")
                    .disabled(primaryLocale == "jp")
                Text("Home.servers.selection.en")
                    .tag("en")
                    .disabled(primaryLocale == "en")
                Text("Home.servers.selection.cn")
                    .tag("cn")
                    .disabled(primaryLocale == "cn")
                Text("Home.servers.selection.tw")
                    .tag("tw")
                    .disabled(primaryLocale == "tw")
                Text("Home.servers.selection.kr")
                    .tag("kr")
                    .disabled(primaryLocale == "kr")
            }, label: {
                Text("Settings.servers.secondaryLocale")
            })
            .onChange(of: secondaryLocale, {
                DoriAPI.secondaryLocale = localeFromStringDict[secondaryLocale] ?? .en
            })
        }
        .onAppear {
            primaryLocale = localeToStringDict[DoriAPI.preferredLocale]?.lowercased() ?? "jp"
            secondaryLocale = localeToStringDict[DoriAPI.secondaryLocale]?.lowercased() ?? "en"
        }
    }
}

struct SettingsHomeView: View {
    var body: some View {
        HomeEditEventsPicker(id: 1)
        HomeEditEventsPicker(id: 2)
        HomeEditEventsPicker(id: 3)
        HomeEditEventsPicker(id: 4)
    }
    
    struct HomeEditEventsPicker: View {
        @AppStorage("homeEventServer1") var homeEventServer1 = "jp"
        @AppStorage("homeEventServer2") var homeEventServer2 = "cn"
        @AppStorage("homeEventServer3") var homeEventServer3 = "tw"
        @AppStorage("homeEventServer4") var homeEventServer4 = "en"
        var id: Int = 1
        init(id: Int = 1) {
            self.id = id
        }
        var body: some View {
            Picker(selection: (id == 1) ? $homeEventServer1 : ((id == 2) ? $homeEventServer2 : ((id == 3) ? $homeEventServer3 : $homeEventServer4)), content: {
                Text("Home.servers.selection.jp")
                    .tag("jp")
                Text("Home.servers.selection.en")
                    .tag("en")
                Text("Home.servers.selection.cn")
                    .tag("cn")
                Text("Home.servers.selection.tw")
                    .tag("tw")
            }, label: {
                Text("Home.servers.slot.\(id)")
            })
        }
    }
}

struct SettingsWidgetView: View {
    @State var cardIDInput = ""
    var body: some View {
        TextField("卡牌小组件 ID", text: $cardIDInput)
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
    }
}

struct SettingsDebugView: View {
    @AppStorage("debugShowHomeBirthdayDatePicker") var debugShowHomeBirthdayDatePicker = false
    @AppStorage("isFirstLaunch") var isFirstLaunch = true
    @AppStorage("isFirstLaunchResettable") var isFirstLaunchResettable = true
    var body: some View {
        Toggle(isOn: $debugShowHomeBirthdayDatePicker, label: {
            Text(verbatim: "debugShowHomeBirthdayDatePicker")
                .fontDesign(.monospaced)
        })
        Toggle(isOn: $isFirstLaunch, label: {
            Text(verbatim: "isFirstLaunch")
                .fontDesign(.monospaced)
        })
        Toggle(isOn: $isFirstLaunchResettable, label: {
            Text(verbatim: "isFirstLaunchResettable")
                .fontDesign(.monospaced)
        })
        #if !DORIKIT_ENABLE_PRECACHE
        Text("Settings.debug.pre-cache-unavailable")
            .foregroundStyle(.red)
            .fontDesign(.monospaced)
        #endif
        NavigationLink(destination: {
            DebugBirthdayView()
        }, label: {
            Text(verbatim: "DebugBirthdayView")
                .fontDesign(.monospaced)
        })
    }
}
