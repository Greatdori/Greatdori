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
    var usedAsSheet: Bool = false
    var body: some View {
        NavigationStack {
            Form {
                SettingsLocaleView()
                SettingsHomeView()
                SettingsNotificationView()
                #if os(iOS)
                SettingsWidgetView()
                #endif
                SettingsOfflineDataView()
                if AppFlag.DEBUG {
                    SettingsDebugView()
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            #if !os(macOS)
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
            #endif
        }
    }
}

struct SettingsLocaleView: View {
    @State var primaryLocale = "jp"
    @State var secondaryLocale = "en"
    @State var server: String = "jp"
    @State var birthdayTimeZone: BirthdayTimeZone = .JST
    @State var showDebugVerificationAlert = false
    
    @State var password = ""
    @State var showDebugUnlockAlert = false
    @AppStorage("lastDebugPassword") var lastDebugPassword = ""
    var body: some View {
        Section(content: {
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
                Group {
                    if #available(iOS 18.0, macOS 15.0, *) {
                        Picker("Settings.birthday-time-zone", selection: $birthdayTimeZone, content: {
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
                            Text("Settings.birthday-time-zone")
                        })
                    }
                }
                .onChange(of: birthdayTimeZone, {
                    UserDefaults.standard.setValue(birthdayTimeZone.rawValue, forKey: "BirthdayTimeZone")
                })
            }
            .onAppear {
                primaryLocale = DoriAPI.preferredLocale.rawValue
                secondaryLocale = DoriAPI.secondaryLocale.rawValue
                birthdayTimeZone = BirthdayTimeZone(rawValue: UserDefaults.standard.string(forKey: "BirthdayTimeZone") ?? "JST") ?? .JST
                //            birthdayTimeZone = (UserDefaults.standard.value(forKey: "BirthdayTimeZone") ?? "JST")
            }
        }, header: {
            Text("Settings.locale")
        }, footer: {
            Text("Settings.birthday-time-zone.footer.\(String(localized: birthdayTimeZoneNameDict[birthdayTimeZone]!))")
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
        })
    }
}

struct SettingsHomeView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @AppStorage("showBirthdayDate") var showBirthdayDate = showBirthdayDateDefaultValue
    var body: some View {
        Section(content: {
            HomeEditEventsPicker(id: 1)
            HomeEditEventsPicker(id: 2)
            HomeEditEventsPicker(id: 3)
            HomeEditEventsPicker(id: 4)
            Picker(selection: $showBirthdayDate, content: {
                Text("Home.home.show-current-date.selection.always")
                    .tag(3)
                Text("Home.home.show-current-date.selection.during-birthday")
                    .tag(2)
                Text("Home.home.show-current-date.selection.automatic")
                    .tag(1)
                Text("Home.home.show-current-date.selection.never")
                    .tag(0)
            }, label: {
                Text("Home.home.show-current-date")
            })
        }, header: {
            Text("Settings.home-edit")
        }, footer: {
            Text(sizeClass == .compact ? "Settings.home-edit.footer.compact" : "Settings.home-edit.footer")
        })
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

struct SettingsNotificationView: View {
    @Environment(\.openURL) var openURL
    @AppStorage("IsNewsNotifEnabled") var isNewsNotificationEnabled = false
    @AppStorage("BirthdaysCalendarID") var birthdaysCalendarID = ""
    @State var birthdayCalendarIsEnabled = false
    @State var notificationIsAuthorized = false
    @State var notificationIsRejected = false
    @State var showErrorAlert = false
    @State var errorCode = 0
    @State var calendarIsAuthorized = false
    @State var calendarIsRejected = false
    @State var shouldRespondToggleChange = true
    var body: some View {
        Section(content: {
            Group {
                if notificationIsAuthorized || notificationIsRejected {
                    Toggle(isOn: $isNewsNotificationEnabled, label: {
                        Text("Settings.notifications.news")
                            .foregroundStyle((!notificationIsAuthorized && notificationIsRejected) ? .secondary : .primary)
                            .onTapGesture {
                                if (!notificationIsAuthorized && notificationIsRejected) {
#if os(iOS)
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        openURL(url)
                                    }
#else
                                    openURL(.init(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
#endif
                                }
                            }
                    })
                    .onChange(of: isNewsNotificationEnabled) {
                        guard shouldRespondToggleChange else {
                            shouldRespondToggleChange = true
                            return
                        }
                        if isNewsNotificationEnabled {
                            if let token = UserDefaults.standard.data(forKey: "RemoteNotifDeviceToken") {
                                Task {
                                    if let id = await DoriNotification.registerRemoteNewsNotification(deviceToken: token) {
                                        UserDefaults.standard.set(id.uuidString, forKey: "NewsNotifID")
                                    } else {
                                        shouldRespondToggleChange = false
                                        isNewsNotificationEnabled = false
                                        errorCode = -401
                                        showErrorAlert = true
                                    }
                                }
                            } else {
                                shouldRespondToggleChange = false
                                isNewsNotificationEnabled = false
                                errorCode = -402
                                showErrorAlert = true
                            }
                        } else {
                            if let id = UserDefaults.standard.string(forKey: "NewsNotifID"),
                               let uuid = UUID(uuidString: id) {
                                Task {
                                    let success = await DoriNotification.unregisterRemoteNewsNotification(id: uuid)
                                    if !success {
                                        shouldRespondToggleChange = false
                                        isNewsNotificationEnabled = true
                                        errorCode = -403
                                        showErrorAlert = true
                                    }
                                }
                            }
                        }
                    }
                    .disabled(!notificationIsAuthorized && notificationIsRejected)
                    .alert("Settings.notifications.news.error-alert.title", isPresented: $showErrorAlert, actions: {}, message: {
                        Text("Settings.notifications.news.error-alert.message.\(errorCode)")
                    })
                } else {
                    Button(action: {
                        Task {
                            do {
                                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                                notificationIsAuthorized = granted
                                notificationIsRejected = true
                                if let token = UserDefaults.standard.data(forKey: "RemoteNotifDeviceToken") {
                                    isNewsNotificationEnabled = true
                                    Task {
                                        if let id = await DoriNotification.registerRemoteNewsNotification(deviceToken: token) {
                                            UserDefaults.standard.set(id.uuidString, forKey: "NewsNotifID")
                                        } else {
                                            isNewsNotificationEnabled = false
                                        }
                                    }
                                }
                            } catch {
                                print(error)
                            }
                        }
                    }, label: {
                        Text("Settings.notifications.news.enable")
                    })
                }
            }
            Group {
                if calendarIsAuthorized || calendarIsRejected {
                    Toggle(isOn: $birthdayCalendarIsEnabled, label: {
                        Text("Settings.notifications.birthday-calendar")
                            .foregroundStyle((!calendarIsAuthorized && calendarIsRejected) ? .secondary : .primary)
                            .onTapGesture {
                                if (!calendarIsAuthorized && calendarIsRejected) {
#if os(iOS)
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        openURL(url)
                                    }
#else
                                    openURL(.init(string: "x-apple.systempreferences:com.apple.preference.general")!)
#endif
                                }
                            }
                    })
                    .onChange(of: birthdayCalendarIsEnabled) {
                        if birthdayCalendarIsEnabled {
                            Task {
                                try? await updateBirthdayCalendar()
                            }
                        } else {
                            try? removeBirthdayCalendar()
                        }
                    }
                    .disabled(!calendarIsAuthorized && calendarIsRejected)
                } else {
                    Button(action: {
                        Task {
                            do {
                                let granted = try await EKEventStore().requestFullAccessToEvents()
                                calendarIsAuthorized = granted
                                calendarIsRejected = true
                            } catch {
                                print(error)
                            }
                        }
                    }, label: {
                        Text("Settings.notifications.birthday-calendar.enable")
                    })
                }
            }
        }, header: {
            Text("Settings.notifications")
        }, footer: {
            if !notificationIsAuthorized || !calendarIsAuthorized {
                Text("Settings.notifications.authorization-required")
                    .onTapGesture {
#if os(iOS)
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
#else
                        openURL(.init(string: "x-apple.systempreferences:com.apple.preference.general")!)
#endif
                    }
            }
        })
        .task {
            let notificationStatus = await UNUserNotificationCenter.current().notificationSettings()
            notificationIsAuthorized = notificationStatus.authorizationStatus == .authorized
            notificationIsRejected = notificationStatus.authorizationStatus != .notDetermined
            
            let calendarStatus = EKEventStore.authorizationStatus(for: .event)
            calendarIsAuthorized = calendarStatus == .fullAccess
            calendarIsRejected = calendarStatus != .notDetermined
            
            if notificationIsRejected {
                isNewsNotificationEnabled = false
            }
            if calendarIsRejected {
                birthdayCalendarIsEnabled = false
            }
            birthdayCalendarIsEnabled = !birthdaysCalendarID.isEmpty
        }
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

struct SettingsDebugView: View {
    @AppStorage("debugShowHomeBirthdayDatePicker") var debugShowHomeBirthdayDatePicker = false
    @AppStorage("isFirstLaunch") var isFirstLaunch = true
    @AppStorage("isFirstLaunchResettable") var isFirstLaunchResettable = true
    @AppStorage("startUpSucceeded") var startUpSucceeded = true
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





