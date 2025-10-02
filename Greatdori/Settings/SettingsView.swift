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

// Settings.

import SwiftUI
import DoriKit
import EventKit
import WidgetKit
import UserNotifications

let birthdayTimeZoneNameDict: [BirthdayTimeZone: LocalizedStringResource] = [.adaptive: "Settings.birthday-time-zone.name.adaptive", .JST: "Settings.birthday-time-zone.name.JST", .UTC: "Settings.birthday-time-zone.name.UTC", .CST: "Settings.birthday-time-zone.name.CST", .PT: "Settings.birthday-time-zone.name.PT"]
let showBirthdayDateDefaultValue = 1

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var selectionItem: Int = 0
    var usedAsSheet: Bool = false
    
    let SettingsTabs: [(LocalizedStringResource, )] = []
    var body: some View {
        #if os(iOS)
        NavigationStack {
            Form {
                SettingsLocaleView()
                SettingsHomeView()
                SettingsPermissionsView()
                #if os(iOS)
                SettingsWidgetView()
                #endif
                SettingsOfflineDataView()
                SettingsAboutView()
                if AppFlag.DEBUG {
                    SettingsDebugView()
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .wrapIf(usedAsSheet, in: { content in
                content
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            DismissButton(action: dismiss.callAsFunction) {
                                Image(systemName: "xmark")
                            }
                        }
                    }
            })
        }
        #else
        NavigationSplitView(sidebar: {
            List(selection: $selectionItem, content: {
                Label("Settings.locale", systemImage: "globe")
                    .tag(0)
                Label("Settings.home-edit", systemImage: "rectangle.3.group")
                    .tag(1)
                Label("Settings.permissions", systemImage: "bell.badge")
                    .tag(2)
                Label("Settings.advanced", systemImage: "hammer")
                    .tag(20)
                if AppFlag.DEBUG {
                    Label("Settings.debug", systemImage: "ant")
                        .tag(23)
                }
            })
        }, detail: {
            Form {
                switch selectionItem {
                case 0:
                    SettingsLocaleView()
                case 1:
                    SettingsHomeView()
                case 2:
                    SettingsPermissionsView()
                case 20:
                    SettingsAdvancedView()
                case 23:
                    SettingsDebugView()
                default:
                    ProgressView()
                }
            }
            .formStyle(.grouped)
        })
        .toolbar(removing: .sidebarToggle)
        #endif
    }
}





#if os(iOS)
struct SettingsWidgetView: View {
    @State var cardIDInput = ""
    var body: some View {
        Section {
            TextField("Settings.widget.ids", text: $cardIDInput)
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
            Text("Settings.widgets")
        }
    }
}
#endif

struct SettingsOfflineDataView: View {
    @State var dataSourcePreference: DataSourcePreference = .hybrid
    var body: some View {
        Section(content: {
            Picker("Settings.offline-data.source-preference", selection: $dataSourcePreference, content: {
                Text("Settings.offline-data.source-preference.selection.hybrid")
                    .tag(DataSourcePreference.hybrid)
                Text("Settings.offline-data.source-preference.selection.internet")
                    .tag(DataSourcePreference.useInternet)
                Text("Settings.offline-data.source-preference.selection.local")
                    .tag(DataSourcePreference.useLocal)
            })
            .onChange(of: dataSourcePreference, {
                UserDefaults.standard.setValue(dataSourcePreference.rawValue, forKey: "DataSourcePreference")
            })
        }, header: {
            Text("Settings.offline-data")
        })
        .onAppear {
            dataSourcePreference = DataSourcePreference(rawValue: UserDefaults.standard.string(forKey: "DataSourcePreference") ?? "hybrid") ?? .hybrid
        }
    }
}

struct SettingsAboutView: View {
    @State var showDebugVerificationAlert = false
    @State var password = ""
    @State var showDebugUnlockAlert = false
    @AppStorage("lastDebugPassword") var lastDebugPassword = ""
    var body: some View {
        Section(content: {
            Text(verbatim: "Greatdori!")
                .onTapGesture(count: 3, perform: {
                    showDebugVerificationAlert = true
                })
                .alert("Settings.debug.activate-alert.title", isPresented: $showDebugVerificationAlert, actions: {
#if os(iOS)
                    TextField("Settings.debug.activate-alert.prompt", text: $password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .fontDesign(.monospaced)
#else
                    TextField("Settings.debug.activate-alert.prompt", text: $password)
                        .autocorrectionDisabled()
                    //                        .textInputSuggestions(nil)
                        .fontDesign(.monospaced)
#endif
                    Button(action: {
                        if password == correctDebugPassword {
                            lastDebugPassword = password
                            AppFlag.set(true, forKey: "DEBUG")
                            showDebugVerificationAlert = false
                            showDebugUnlockAlert = true
                        }
                        password = ""
                    }, label: {
                        Text("Settings.debug.activate-alert.confirm")
                    })
                    .keyboardShortcut(.defaultAction)
                    Button(role: .cancel, action: {}, label: {
                        Text("Settings.debug.activate-alert.cancel")
                    })
                }, message: {
                    Text("Settings.debug.activate-alert.message")
                })
                .alert("Settings.debug.activate-alert.succeed", isPresented: $showDebugUnlockAlert, actions: {})
            NavigationLink(destination: {
                SettingsAdvancedView()
            }, label: {
                Text("Settings.advanced")
            })
        }, header: {
            Text("Settings.about")
        })
    }
}

struct SettingsDebugView: View {
    @AppStorage("debugShowHomeBirthdayDatePicker") var debugShowHomeBirthdayDatePicker = false
    @AppStorage("isFirstLaunch") var isFirstLaunch = true
    @AppStorage("isFirstLaunchResettable") var isFirstLaunchResettable = true
    @AppStorage("startUpSucceeded") var startUpSucceeded = true
    @AppStorage("EnableRulerOverlay") var enableRulerOverlay = false
    @State var showDebugDisactivationAlert = false
    var body: some View {
        Section(content: {
            Group {
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
                    
                })
                Toggle(isOn: $startUpSucceeded, label: {
                    Text(verbatim: "startUpSucceeded")
                    
                })
                Toggle(isOn: $enableRulerOverlay) {
                    Text(verbatim: "Enable Ruler Overlay")
                }
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
                NavigationLink(destination: {
                    DebugFilterExperimentView()
                }, label: {
                    Text(verbatim: "DebugFilterExperimentView")
                })
                Button(role: .destructive, action: {
                    DoriCache.invalidateAll()
                }, label: {
                    Text("Settings.debug.clear-cache")
                })
                Button(role: .destructive, action: {
                    showDebugDisactivationAlert = true
                }, label: {
                    Text("Settings.debug.disable")
                })
                .alert("Settings.debug.disable.title", isPresented: $showDebugDisactivationAlert, actions: {
                    Button(role: .destructive, action: {
                        AppFlag.set(false, forKey: "DEBUG")
                        showDebugDisactivationAlert = false
                    }, label: {
                        Text("Settings.debug.disable.turn-off")
                    })
                })
            }
            .fontDesign(.monospaced)
        }, header: {
            Text("Settings.debug")
        })
    }
}

enum BirthdayTimeZone: String, CaseIterable {
    case adaptive
    case JST
    case UTC
    case CST
    case PT
    
    
}

enum DataSourcePreference: String, CaseIterable {
    case useInternet
    case hybrid
    case useLocal
}





