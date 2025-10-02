//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsLocaleView.swift
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

struct SettingsLocaleView: View {
    var body: some View {
#if os(iOS)
        Section(content: {
            Group {
                SettingsPrimaryAndSecondaryLocalePicker()
                SettingsBirthdayTimeZonePicker()
            }
        }, header: {
            Text("Settings.locale")
        })
#else
        Group {
            Section {
                SettingsPrimaryAndSecondaryLocalePicker()
            }
            Section {
                SettingsBirthdayTimeZonePicker()
            }
        }
        .navigationTitle("Settings.locale")
#endif
    }
    
    
    struct SettingsPrimaryAndSecondaryLocalePicker: View {
        @State var primaryLocale = "jp"
        @State var secondaryLocale = "en"
        var body: some View {
            Group {
                Picker(selection: $primaryLocale, content: {
                    Text("Home.servers.selection.jp")
                        .tag("jp")
                    Text("Home.servers.selection.en")
                        .tag("en")
                    Text("Home.servers.selection.cn")
                        .tag("cn")
                    Text("Home.servers.selection.tw")
                        .tag("tw")
                    Text("Home.servers.selection.kr")
                        .tag("kr")
                        .disabled(secondaryLocale == "kr")
                }, label: {
                    Text("Settings.servers.primaryLocale")
                })
                .onChange(of: primaryLocale, { oldValue, newValue in
                    if DoriLocale.secondaryLocale == DoriLocale(rawValue: newValue) {
                        DoriLocale.secondaryLocale = DoriLocale(rawValue: oldValue)!
                    }
                    DoriAPI.preferredLocale = localeFromStringDict[primaryLocale] ?? .jp
                    
                    primaryLocale = DoriAPI.preferredLocale.rawValue
                    secondaryLocale = DoriAPI.secondaryLocale.rawValue
                })
                Picker(selection: $secondaryLocale, content: {
                    Text("Home.servers.selection.jp")
                        .tag("jp")
                    Text("Home.servers.selection.en")
                        .tag("en")
                    Text("Home.servers.selection.cn")
                        .tag("cn")
                    Text("Home.servers.selection.tw")
                        .tag("tw")
                    Text("Home.servers.selection.kr")
                        .tag("kr")
                }, label: {
                    Text("Settings.servers.secondaryLocale")
                })
                .onChange(of: secondaryLocale, { oldValue, newValue in
                    if DoriLocale.primaryLocale == DoriLocale(rawValue: newValue) {
                        DoriLocale.primaryLocale = DoriLocale(rawValue: oldValue)!
                    }
                    DoriAPI.secondaryLocale = localeFromStringDict[secondaryLocale] ?? .en
                    
                    primaryLocale = DoriAPI.preferredLocale.rawValue
                    secondaryLocale = DoriAPI.secondaryLocale.rawValue
                })
            }
            .onAppear {
                primaryLocale = DoriAPI.preferredLocale.rawValue
                secondaryLocale = DoriAPI.secondaryLocale.rawValue
            }
        }
    }
    
    struct SettingsBirthdayTimeZonePicker: View {
        @State var birthdayTimeZone: BirthdayTimeZone = .JST
        var body: some View {
            Group {
                if #available(iOS 18.0, macOS 15.0, *) {
                    Picker(selection: $birthdayTimeZone, content: {
                        Text("Settings.birthday-time-zone.selection.adaptive")
                            .tag(BirthdayTimeZone.adaptive)
                        Text("Settings.birthday-time-zone.selection.JST")
                            .tag(BirthdayTimeZone.JST)
                        Text("Settings.birthday-time-zone.selection.UTC")
                            .tag(BirthdayTimeZone.UTC)
                        Text("Settings.birthday-time-zone.selection.CST")
                            .tag(BirthdayTimeZone.CST)
                        Text(TimeZone(identifier: "America/Los_Angeles")!.isDaylightSavingTime() ? "Settings.birthday-time-zone.selection.PT.PDT" : "Settings.birthday-time-zone.selection.PT.PST")
                            .tag(BirthdayTimeZone.PT)
                    }, label: {
                        VStack(alignment: .leading) {
                            Text("Settings.birthday-time-zone")
                            Text("Settings.birthday-time-zone.description")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }, currentValueLabel: {
                        switch birthdayTimeZone {
                        case .adaptive:
                            Text("Settings.birthday-time-zone.selection.adaptive.abbr")
                        case .JST:
                            Text("Settings.birthday-time-zone.selection.JST.abbr")
                        case .UTC:
                            Text("Settings.birthday-time-zone.selection.UTC.abbr")
                        case .CST:
                            Text("Settings.birthday-time-zone.selection.CST.abbr")
                        case .PT:
                            Text("Settings.birthday-time-zone.selection.PT.abbr")
                        }
                    })
                } else {
                    Picker(selection: $birthdayTimeZone, content: {
                        Text("Settings.birthday-time-zone.selection.adaptive")
                            .tag(BirthdayTimeZone.adaptive)
                        Text("Settings.birthday-time-zone.selection.JST")
                            .tag(BirthdayTimeZone.JST)
                        Text("Settings.birthday-time-zone.selection.UTC")
                            .tag(BirthdayTimeZone.UTC)
                        Text("Settings.birthday-time-zone.selection.CST")
                            .tag(BirthdayTimeZone.CST)
                        Text(TimeZone(identifier: "America/Los_Angeles")!.isDaylightSavingTime() ? "Settings.birthday-time-zone.selection.PT.PDT" : "Settings.birthday-time-zone.selection.PT.PST")
                            .tag(BirthdayTimeZone.PT)
                    }, label: {
                        VStack(alignment: .leading) {
                            Text("Settings.birthday-time-zone")
                            Text("Settings.birthday-time-zone.description")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                    })
                }
            }
            .onAppear {
                birthdayTimeZone = BirthdayTimeZone(rawValue: UserDefaults.standard.string(forKey: "BirthdayTimeZone") ?? "JST") ?? .JST
            }
            .onChange(of: birthdayTimeZone) {
                UserDefaults.standard.setValue(birthdayTimeZone.rawValue, forKey: "BirthdayTimeZone")
            }
            
        }
    }
}

