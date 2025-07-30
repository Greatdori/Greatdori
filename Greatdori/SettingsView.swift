//
//  SettingsView.swift
//  Greatdori
//
//  Created by ThreeManager785 on 2025/7/29.
//

import SwiftUI
import DoriKit

struct SettingsView: View {
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
        NavigationLink(destination: {
            DebugBirthdayView()
        }, label: {
            Text(verbatim: "DebugBirthdayView")
                .fontDesign(.monospaced)
        })
    }
}
