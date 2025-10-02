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

let correctDebugPassword = "Stolz-250912!Yuki"

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
    @State var updateCheckerResult: DoriOfflineAsset.UpdateCheckerResult?
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
                VStack(alignment: .leading) {
                    HStack {
                        Button(action: {
                            Task {
                                do {
                                    updateCheckerResult = try await DoriOfflineAsset.shared.isUpdateAvailable(in: DoriAPI.preferredLocale, of: .basic)
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                        }, label: {
                            Text(verbatim: "Check for Update")
                        })
                        Button(action: {
                            Task {
                                do {
                                    try await DoriOfflineAsset.shared.updateResource(of: .basic, in: DoriAPI.preferredLocale) { percentage, finished, total in
                                        print("\(percentage * 100)%, \(finished) / \(total)")
                                    }
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                        }, label: {
                            Text(verbatim: "Update preferred locale basic")
                        })
                    }
                    if let result = updateCheckerResult {
                        Text(verbatim: "Status: \(result.isUpdateAvailable)\nLocal: \(result.localSHA)\nRemote: \(result.remoteSHA)")
                    }
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
    @State var sorter: DoriFrontend.Sorter = DoriFrontend.Sorter(keyword: .id, direction: .descending)
    @State var updating = false
    @State var focusingList: Int = -1
    
    // 0 - Event
    @State var eventList: [DoriAPI.Event.PreviewEvent] = []
    @State var eventListFiltered: [DoriAPI.Event.PreviewEvent] = []
    
    // 1 - Gacha
    @State var gachaList: [DoriAPI.Gacha.PreviewGacha] = []
    @State var gachaListFiltered: [DoriAPI.Gacha.PreviewGacha] = []
    
    // 2 - Card
    @State var cardList: [DoriFrontend.Card.CardWithBand] = []
    @State var cardListFiltered: [DoriFrontend.Card.CardWithBand] = []
    
    // 3 - Song
    @State var songList: [DoriFrontend.Song.PreviewSong] = []
    @State var songListFiltered: [DoriFrontend.Song.PreviewSong] = []
    
    // 4 - Comic
    @State var comicList: [DoriAPI.Comic.Comic] = []
    @State var comicListFiltered: [DoriAPI.Comic.Comic] = []
    
    // 5 - Campaign
    @State var campaignList: [DoriAPI.LoginCampaign.PreviewCampaign] = []
    @State var campaignListFiltered: [DoriAPI.LoginCampaign.PreviewCampaign] = []
    
    // 6 - Costume
    @State var costumeList: [DoriAPI.Costume.PreviewCostume] = []
    @State var costumeListFiltered: [DoriAPI.Costume.PreviewCostume] = []
    
    @State var showFilterSheet = false
    @State var showOptimizedFilter = false
    @State var optimizedKeys: [Int: [DoriFrontend.Filter.Key]] = [:]
    @State var optimizedSortingTypes: [Int: [DoriFrontend.Sorter.Keyword]] = [:] // WIP
    @State var sortingItemsHaveEndingDate: [Int: Bool] = [:] // WIP
//    @State var allKeys = Set(DoriFrontend.Filter.Key.allCases)
//    @State var result: Array<>? = []
    var body: some View {
        NavigationStack {
            HStack {
                List {
                    Picker(selection: $focusingList, content: {
                        Text(verbatim: "Select...")
                            .tag(-1)
                        Text(verbatim: "EVENT")
                            .tag(0)
                        Text(verbatim: "GACHA")
                            .tag(1)
                        Text(verbatim: "CARD")
                            .tag(2)
                        Text(verbatim: "SONG")
                            .tag(3)
                        Text(verbatim: "CAMPAIGN")
                            .tag(5)
                        Text(verbatim: "COMIC")
                            .tag(4)
                        Text(verbatim: "COSTUME")
                            .tag(6)
                    }, label: {
                        Text(verbatim: "List Type")
                    })
                    Toggle(isOn: $showOptimizedFilter, label: {
                        Text(verbatim: "Use Optimized Filter")
                    })
                    .toggleStyle(.switch)
                    #if os(iOS)
                    Button(action: {
                        showFilterSheet = true
                    }, label: {
                        Text(verbatim: "Show Filter Sheet")
                    })
                    #endif
                    Text(verbatim: "Updating: \(updating ? "TRUE" : "FALSE")")
                        .bold(updating)
                        .foregroundStyle(updating ? .red : .green)
                    Group {
                        if focusingList == 0 {
                            Text(verbatim: "Events List Item: \(eventListFiltered.count)/\(eventList.count)")
                            ForEach(eventListFiltered) { element in
                                Text(verbatim: "#\(element.id) - \(element.eventName.jp ?? "nil")")
                            }
                        } else if focusingList == 1 {
                            Text(verbatim: "Gachas List Item: \(gachaListFiltered.count)/\(gachaList.count)")
                            ForEach(gachaListFiltered) { element in
                                Text(verbatim: "#\(element.id) - \(element.gachaName.jp ?? "nil")")
                            }
                        } else if focusingList == 2 {
                            Text(verbatim: "Cards List Item: \(cardListFiltered.count)/\(cardList.count)")
                            ForEach(cardListFiltered) { element in
                                Text(verbatim: "#\(element.id) - \(element.card.prefix.jp ?? "nil")")
                            }
                        } else if focusingList == 3 {
                            Text(verbatim: "Songs List Item: \(songListFiltered.count)/\(songList.count)")
                            ForEach(songListFiltered) { element in
                                Text(verbatim: "#\(element.id) - \(element.musicTitle.jp ?? "nil")")
                                ForEach(DoriAPI.Locale.allCases, id: \.self) { item in
                                    if let closedAt = element.closedAt.forLocale(item), closedAt < Calendar.current.date(from: DateComponents(year: 2090, month: 1, day: 1))! {
                                        Text(verbatim: "[\(item.rawValue.uppercased())] \(closedAt)")
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                        } else if focusingList == 4 {
                            Text(verbatim: "Comic List Item: \(comicListFiltered.count)/\(comicList.count)")
                            ForEach(comicListFiltered) { element in
                                Text(verbatim: "#\(element.id) - \(element.title.jp ?? "nil")")
                            }
                        } else if focusingList == 5 {
                            Text(verbatim: "Campaign List Item: \(campaignListFiltered.count)/\(campaignList.count)")
                            ForEach(campaignListFiltered) { element in
                                Text(verbatim: "#\(element.id) - \(element.caption.jp ?? "nil")")
                            }
                        } else if focusingList == 6 {
                            Text(verbatim: "Costume List Item: \(costumeListFiltered.count)/\(costumeList.count)")
                            ForEach(costumeListFiltered) { element in
                                Text(verbatim: "#\(element.id) - \(element.description.jp ?? "nil")")
                            }
                        }
                    }
                }
            }
        }
        .fontDesign(.monospaced)
        .multilineTextAlignment(.leading)
        .sheet(isPresented: $showFilterSheet, content: {
            FilterView(filter: $filter, includingKeys: showOptimizedFilter ? Set(optimizedKeys[focusingList]!) : Set(DoriFrontend.Filter.Key.allCases))
        })
        .inspector(isPresented: .constant(true), content: {
            FilterView(filter: $filter, includingKeys: showOptimizedFilter ? Set(optimizedKeys[focusingList]!) : Set(DoriFrontend.Filter.Key.allCases))
        })
        .onAppear {
//            focusingList = 0
            for i in 0...6 {
                if i == 0 {
                    optimizedKeys.updateValue(DoriAPI.Event.PreviewEvent.applicableFilteringKeys, forKey: i)
                    optimizedSortingTypes.updateValue(DoriFrontend.Event.PreviewEvent.applicableSortingTypes, forKey: i)
                    sortingItemsHaveEndingDate.updateValue(DoriFrontend.Event.PreviewEvent.hasEndingDate, forKey: i)
                } else if i == 1 {
                    optimizedKeys.updateValue(DoriAPI.Gacha.PreviewGacha.applicableFilteringKeys, forKey: i)
                    optimizedSortingTypes.updateValue(DoriFrontend.Gacha.PreviewGacha.applicableSortingTypes, forKey: i)
                    sortingItemsHaveEndingDate.updateValue(DoriFrontend.Gacha.PreviewGacha.hasEndingDate, forKey: i)
                } else if i == 2 {
                    optimizedKeys.updateValue(DoriFrontend.Card.CardWithBand.applicableFilteringKeys, forKey: i)
                    optimizedSortingTypes.updateValue(DoriFrontend.Card.CardWithBand.applicableSortingTypes, forKey: i)
                    sortingItemsHaveEndingDate.updateValue(DoriFrontend.Card.CardWithBand.hasEndingDate, forKey: i)
                } else if i == 3 {
                    optimizedKeys.updateValue(DoriAPI.Song.PreviewSong.applicableFilteringKeys, forKey: i)
                    optimizedSortingTypes.updateValue(DoriAPI.Song.PreviewSong.applicableSortingTypes, forKey: i)
                    sortingItemsHaveEndingDate.updateValue(DoriAPI.Song.PreviewSong.hasEndingDate, forKey: i)
                } else if i == 4 {
                    optimizedKeys.updateValue(DoriAPI.Comic.Comic.applicableFilteringKeys, forKey: i)
                    optimizedSortingTypes.updateValue(DoriAPI.Comic.Comic.applicableSortingTypes, forKey: i)
                    sortingItemsHaveEndingDate.updateValue(DoriAPI.Comic.Comic.hasEndingDate, forKey: i)
                } else if i == 5 {
                    optimizedKeys.updateValue(DoriAPI.LoginCampaign.PreviewCampaign.applicableFilteringKeys, forKey: i)
                    optimizedSortingTypes.updateValue(DoriAPI.LoginCampaign.PreviewCampaign.applicableSortingTypes, forKey: i)
                    sortingItemsHaveEndingDate.updateValue(DoriAPI.LoginCampaign.PreviewCampaign.hasEndingDate, forKey: i)
                } else if i == 6 {
                    optimizedKeys.updateValue(DoriFrontend.Costume.PreviewCostume.applicableFilteringKeys, forKey: i)
                    optimizedSortingTypes.updateValue(DoriFrontend.Costume.PreviewCostume.applicableSortingTypes, forKey: i)
                    sortingItemsHaveEndingDate.updateValue(DoriFrontend.Costume.PreviewCostume.hasEndingDate, forKey: i)
                }
            }
        }
        .onChange(of: focusingList, {
            updating = true
            Task {
                if focusingList == 0 {
                    eventList = await DoriFrontend.Event.list() ?? []
                    eventListFiltered = eventList.sorted(withDoriSorter: sorter).filter(withDoriFilter: filter)
                } else if focusingList == 1 {
                    gachaList = await DoriFrontend.Gacha.list() ?? []
                    gachaListFiltered = gachaList.sorted(withDoriSorter: sorter).filter(withDoriFilter: filter)
                } else if focusingList == 2 {
                    cardList = await DoriFrontend.Card.list() ?? []
                    cardListFiltered = cardList.sorted(withDoriSorter: sorter).filter(withDoriFilter: filter)
                } else if focusingList == 3 {
                    songList = await DoriFrontend.Song.list() ?? []
                    songListFiltered = songList.sorted(withDoriSorter: sorter).filter(withDoriFilter: filter)
                } else if focusingList == 4 {
                    comicList = await DoriFrontend.Comic.list() ?? []
                    comicListFiltered = comicList.sorted(withDoriSorter: sorter).filter(withDoriFilter: filter)
                } else if focusingList == 5 {
                    campaignList = await DoriFrontend.LoginCampaign.list() ?? []
                    campaignListFiltered = campaignList.sorted(withDoriSorter: sorter).filter(withDoriFilter: filter)
                } else if focusingList == 6 {
                    costumeList = await DoriFrontend.Costume.list() ?? []
                    costumeListFiltered = costumeList.sorted(withDoriSorter: sorter).filter(withDoriFilter: filter)
                }
                updating = false
            }
        })
        .onChange(of: filter) {
            // No need to update sorter. The list should already be sorted.
            updating = true
            if focusingList == 0 {
                eventListFiltered = eventList.filter(withDoriFilter: filter)
            } else if focusingList == 1 {
                gachaListFiltered = gachaList.filter(withDoriFilter: filter)
            } else if focusingList == 2 {
                cardListFiltered = cardList.filter(withDoriFilter: filter)
            } else if focusingList == 3 {
                songListFiltered = songList.filter(withDoriFilter: filter)
            } else if focusingList == 4 {
                comicListFiltered = comicList.filter(withDoriFilter: filter)
            } else if focusingList == 5 {
                campaignListFiltered = campaignList.filter(withDoriFilter: filter)
            } else if focusingList == 6 {
                costumeListFiltered = costumeList.filter(withDoriFilter: filter)
            }
            updating = false
        }
        .onChange(of: sorter) {
            updating = true
            if focusingList == 0 {
                eventListFiltered = eventList.sorted(withDoriSorter: sorter).filter(withDoriFilter: filter)
            } else if focusingList == 1 {
                gachaListFiltered = gachaList.sorted(withDoriSorter: sorter).filter(withDoriFilter: filter)
            } else if focusingList == 2 {
                cardListFiltered = cardList.sorted(withDoriSorter: sorter).filter(withDoriFilter: filter)
            } else if focusingList == 3 {
                songListFiltered = songList.filter(withDoriFilter: filter)
            } else if focusingList == 4 {
                comicListFiltered = comicList.filter(withDoriFilter: filter)
            } else if focusingList == 5 {
                campaignListFiltered = campaignList.filter(withDoriFilter: filter)
            } else if focusingList == 6 {
                costumeListFiltered = costumeList.filter(withDoriFilter: filter)
            }
            updating = false
        }
        .toolbar {
            ToolbarItem {
                if showOptimizedFilter {
                    SorterPickerView(sorter: $sorter, allOptions: optimizedSortingTypes[focusingList] ?? DoriFrontend.Sorter.Keyword.allCases, sortingItemsHaveEndingDate: sortingItemsHaveEndingDate[focusingList] ?? false)
                } else {
                    SorterPickerView(sorter: $sorter)
                }
            }
        }
    }
}

struct DebugRulerOverlay: View {
    @State var xLength: CGFloat = 0
    @State var xPosition: CGPoint = .zero
    @State var yLength: CGFloat = 0
    @State var yPosition: CGPoint = .zero
    @State var xLengthZoomBase: CGFloat = 0
    @State var yLengthZoomBase: CGFloat = 0
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ZStack {
                    Color.clear // hit testing
                        .frame(width: 20, height: xLength)
                        .contentShape(Rectangle())
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 3, height: xLength)
                    Text(verbatim: "x: \(unsafe String(format: "%.2f", xPosition.x)), y: \(unsafe String(format: "%.2f", xPosition.y)), \(unsafe String(format: "%.2f", xLength)) pt")
                        .rotationEffect(.degrees(xPosition.x < proxy.size.width / 2 ? 90 : -90))
                        .offset(x: xPosition.x < proxy.size.width / 2 ? -10 : 10)
                }
                .position(xPosition)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            xPosition = value.location
                        }
                )
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            xLength = xLengthZoomBase * value.magnification
                        }
                        .onEnded { _ in
                            xLengthZoomBase = xLength
                        }
                )
                ZStack {
                    Color.clear
                        .frame(width: yLength, height: 20)
                        .contentShape(Rectangle())
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: yLength, height: 3)
                    Text(verbatim: "x: \(unsafe String(format: "%.2f", yPosition.x)), y: \(unsafe String(format: "%.2f", yPosition.y)), \(unsafe String(format: "%.2f", yLength)) pt")
                        .offset(y: yPosition.y < proxy.size.height / 2 ? -10 : 10)
                }
                .position(yPosition)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            yPosition = value.location
                        }
                )
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            yLength = yLengthZoomBase * value.magnification
                        }
                        .onEnded { _ in
                            yLengthZoomBase = yLength
                        }
                )
            }
            .onAppear {
                xLength = proxy.size.height
                yLength = proxy.size.width
                xLengthZoomBase = xLength
                yLengthZoomBase = yLength
                let frame = proxy.frame(in: .global)
                xPosition = .init(x: frame.width / 2, y: frame.height / 2)
                yPosition = .init(x: frame.width / 2, y: frame.height / 2)
            }
        }
        .ignoresSafeArea()
    }
}
