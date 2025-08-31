//===---*- Greatdori! -*---------------------------------------------------===//
//
// DebugView.swift
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

// Greatdori! Users will not expect to see any of these.
// For anyone curious: these are just some data algorithm tests (and some basic toggles in SettingsView.swift).
// It's not that fun.

import SwiftUI
import DoriKit
import SDWebImageSwiftUI

struct DebugBirthdayView: View {
    var dateList: [Date] = []
    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        var components = calendar.dateComponents([.month, .day], from: Date())
        components.year = 2000
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        let JanFirstOfY2K = calendar.date(from: components)!
        dateList.append(JanFirstOfY2K)
        for i in 0...364 {
            dateList.append(dateList[i].addingTimeInterval(60*60*24))
        }
    }
    var body: some View {
        ScrollView {
            VStack {
                ForEach(0..<dateList.count, id: \.self) { i in
                    DebugBirthdayViewUnit(receivedToday: dateList[i])
                }
                Divider()
            }
        }
    }
}

struct DebugBirthdayViewUnit: View {
    @State var birthdays: [DoriFrontend.Character.BirthdayCharacter]?
    var receivedToday: Date?
    var formatter = DateFormatter()
    init(receivedToday: Date? = Date.now) {
        self.receivedToday = receivedToday
//        formatter.timeZone = .init(identifier: "Asia/Tokyo")
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MM/dd")
        formatter.timeZone = .init(identifier: "Asia/Tokyo")
    }
//    init() {
//        
//    }
    var body: some View {
        Group {
            if let birthdays {
                HStack {
                    Text(formatter.string(from: receivedToday!))
                        .bold()
                    ForEach(birthdays) { character in
                        //                            HStack {
                        WebImage(url: character.iconImageURL)
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 30, height: 30)
                        Text(formatter.string(from: character.birthday))
                    }
                    Spacer()
                }
            } else {
                ProgressView()
            }
        }
        .task {
            birthdays = await DoriFrontend.Character.recentBirthdayCharacters(aroundDate: receivedToday ?? Date.now)
        }
    }
}

@available(iOS, unavailable)
struct DebugOfflineAssetView: View {
    @AppStorage("_OfflineAssetDebugFilePath") var filePath = ""
    @State var contents = [String]()
    @State var testCard: DoriAPI.Card.Card?
    var body: some View {
        #if os(macOS)
        Form {
            Section {
                Button(action: {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: NSHomeDirectory() + "/Documents")
                }, label: {
                    Text(verbatim: "Open documents directory")
                })
            } header: {
                Text(verbatim: "Inspection")
            }
            Section {
                HStack {
                    Button(action: {
                        Task {
                            do {
                                try await DoriOfflineAsset.shared.downloadResource(of: .main, in: DoriAPI.preferredLocale) { percentage, finished, total in
                                    print("\(percentage * 100)%, \(finished) / \(total)")
                                }
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    }, label: {
                        Text(verbatim: "Download main")
                    })
                    Button(action: {
                        Task {
                            do {
                                try await DoriOfflineAsset.shared.downloadResource(of: .basic, in: DoriAPI.preferredLocale) { percentage, finished, total in
                                    print("\(percentage * 100)%, \(finished) / \(total)")
                                }
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    }, label: {
                        Text(verbatim: "Download preferred locale basic")
                    })
                }
            } header: {
                Text(verbatim: "Download")
            } footer: {
                Text(verbatim: "Check console for downloading progress")
            }
            Section {
                TextField(String("File Path"), text: $filePath)
                HStack {
                    Button(String("Exists")) {
                        print(DoriOfflineAsset.shared.fileExists(filePath, in: .cn, of: .basic))
                    }
                    Button(action: {
                        do {
                            print(try DoriOfflineAsset.shared.fileHash(forPath: filePath, in: .cn, of: .basic))
                        } catch {
                            print(error.localizedDescription)
                        }
                    }, label: {
                        Text(verbatim: "Print hash")
                    })
                    Button(action: {
                        do {
                            try DoriOfflineAsset.shared.writeFile(atPath: filePath, in: .cn, of: .basic, toPath: NSHomeDirectory() + "/Documents/\(filePath.split(separator: "/").last!)")
                        } catch {
                            print(error.localizedDescription)
                        }
                    }, label: {
                        Text(verbatim: "Write to Documents")
                    })
                }
                VStack(alignment: .leading) {
                    Button(action: {
                        do {
                            contents = try DoriOfflineAsset.shared.contentsOfDirectory(atPath: filePath, in: .cn, of: .basic)
                        } catch {
                            print(error.localizedDescription)
                        }                    }, label: {
                        Text(verbatim: "Contentss")
                    })
                    ForEach(contents, id: \.self) { name in
                        Text(name)
                    }
                }
            } header: {
                Text(verbatim: "File")
            }
            Section {
                if let testCard {
                    WebImage(url: testCard.coverNormalImageURL.withOfflineAsset())
                        .resizable()
                        .scaledToFit()
                    Text(testCard.coverNormalImageURL.absoluteString)
                    Text(testCard.coverNormalImageURL.withOfflineAsset().absoluteString)
                }
            } header: {
                Text(verbatim: "Dispatcher")
            }
        }
        .formStyle(.grouped)
        .task {
            await withOfflineAsset {
                testCard = await DoriAPI.Card.detail(of: 2125)
            }
        }
        #else
        preconditionFailure()
        #endif
    }
}

struct DebugFilterExperimentView: View {
    @State var filter: DoriFrontend.Filter = .init()
    @State var eventList: [DoriAPI.Event.PreviewEvent] = []
    @State var eventListFiltered: [DoriAPI.Event.PreviewEvent] = []
    @State var eventListLegacy: [DoriAPI.Event.PreviewEvent] = []
    @State var gachaList: [DoriAPI.Gacha.PreviewGacha] = []
    @State var gachaListFiltered: [DoriAPI.Gacha.PreviewGacha] = []
    @State var gachaListLegacy: [DoriAPI.Gacha.PreviewGacha] = []
    @State var updating = true
    @State var focusingList: Int = -1
    @State var showLegacy = false
    let lists: [Int: String] = [0: "EVENT", 1: "GACHA"]
//    @State var result: Array<>? = []
    var body: some View {
        NavigationStack {
            HStack {
                List {
                    Picker(selection: $focusingList, content: {
                        Text("EVENT")
                            .tag(0)
                        Text("GACHA")
                            .tag(1)
                    }, label: {
                        Text(verbatim: "List Type")
                    })
                    Toggle(isOn: $showLegacy, label: {
                        Text("Show Legacy")
                    })
                    .toggleStyle(.switch)
                    Text(verbatim: "Updating: \(updating ? "TRUE" : "FALSE")")
                        .bold(updating)
                        .foregroundStyle(updating ? .red : .green)
                    Group {
                        if focusingList == 0 {
                            Text(verbatim: "Event List Item: \(eventListFiltered.count)/\(eventList.count)")
                            ForEach(eventListFiltered) { element in
                                Text(verbatim: "#\(element.id) - \(element.eventName.jp)")
                            }
                        } else if focusingList == 1 {
                            Text(verbatim: "Gacha List Item: \(gachaListFiltered.count)/\(gachaList.count)")
                            ForEach(gachaListFiltered) { element in
                                Text(verbatim: "#\(element.id) - \(element.gachaName.jp)")
                            }
                        }
                    }
                }
                if showLegacy {
                    List {
                        Text(verbatim: "LEGACY")
                        Group {
                            if focusingList == 0 {
                                Text(verbatim: "Event List Item: \(eventListLegacy.count)/\(eventList.count)")
                                ForEach(eventListLegacy) { element in
                                    Text(verbatim: "#\(element.id) - \(element.eventName.jp)")
                                }
                            } else if focusingList == 1 {
                                Text(verbatim: "Gacha List Item: \(gachaListLegacy.count)/\(gachaList.count)")
                                ForEach(gachaListLegacy) { element in
                                    Text(verbatim: "#\(element.id) - \(element.gachaName.jp)")
                                }
                            }
                        }
                    }
                }
            }
        }
        .fontDesign(.monospaced)
        .multilineTextAlignment(.leading)
        .inspector(isPresented: .constant(true), content: {
            FilterView(filter: $filter, includingKeys: Set(DoriFrontend.Filter.Key.allCases))
        })
        .onAppear {
            focusingList = 0
        }
        .onChange(of: focusingList, {
            updating = true
            Task {
                if focusingList == 0 {
                    eventList = await DoriFrontend.Event.list()!
                    eventListFiltered = eventList.filterByDori(with: filter)
                    if showLegacy {
                        eventListLegacy = await DoriFrontend.Event.list(filter: filter)!
                    }
                } else if focusingList == 1 {
                    gachaList = await DoriFrontend.Gacha.list()!
                    gachaListFiltered = gachaList.filterByDori(with: filter)
                    if showLegacy {
                        gachaListLegacy = await DoriFrontend.Gacha.list(filter: filter)!
                    }
                }
                updating = false
            }
        })
        .onChange(of: filter) {
            updating = true
            if focusingList == 0 {
                eventListFiltered = eventList.filterByDori(with: filter)
                if showLegacy {
                    Task {
                        eventListLegacy = await DoriFrontend.Event.list(filter: filter)!
                    }
                }
            } else if focusingList == 1 {
                gachaListFiltered = gachaList.filterByDori(with: filter)
                if showLegacy {
                    Task {
                        gachaListLegacy = await DoriFrontend.Gacha.list(filter: filter)!
                    }
                }
            }
            updating = false
        }
    }
}
