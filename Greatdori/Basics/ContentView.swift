//===---*- Greatdori! -*---------------------------------------------------===//
//
// ContentView.swift
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

// This file is the root of the navigation system for the whole cross-platform, multi-system-version app.

// MARK: This file is root-navigation-related items only.

import DoriKit
import os
import SwiftUI


//MARK: ContentView
struct ContentView: View {
    @State private var selection: AppSection? = .home
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.platform) var platform
    @AppStorage("isFirstLaunch") var isFirstLaunch = true
    @AppStorage("isFirstLaunchResettable") var isFirstLaunchResettable = true
    @AppStorage("startUpSucceeded") var startUpSucceeded = true
    @AppStorage("lastDebugPassword") var lastDebugPassword = ""
    @State var mainAppShouldBeDisplayed = false
    @State var crashViewShouldBeDisplayed = false
    @State var lastStartUpWasSuccessful = true
    @State var showWelcomeScreen = false
    @State var showPreCacheAlert = false
    @State var showCrashAlert = false
    
    var body: some View {
        if mainAppShouldBeDisplayed {
            Group {
                if #available(macOS 15.0, iOS 18.0, *) {
                    // MARK: Currently Used Version
                    TabView {
                        Tab("App.home", systemImage: "house") {
                            HomeView()
                        }
                        Tab("App.community", systemImage: "at") {
                            //                        HomeView()
                            Text(verbatim: "community")
                        }
                        Tab("App.leaderboard", systemImage: "chart.bar") {
                            //                        HomeView()
                            Text(verbatim: "leaderboard")
                        }
                        if sizeClass == .regular {
                            TabSection(content: {
                                ForEach(0..<allInfoDestinationItems.count, id: \.self) { itemIndex in
                                    Tab(allInfoDestinationItems[itemIndex].title, systemImage: allInfoDestinationItems[itemIndex].symbol) {
                                        NavigationStack {
                                            allInfoDestinationItems[itemIndex].destination()
                                        }
                                    }
                                }
//                                Tab("App.info.characters", systemImage: "person.2") {
//                                    NavigationStack {
//                                        CharacterSearchView()
//                                    }
//                                }
//                                Tab("App.info.events", systemImage: "star.hexagon") {
//                                    NavigationStack {
//                                        EventSearchView()
//                                    }
//                                }
//                                Tab("App.info.gachas", systemImage: "line.horizontal.star.fill.line.horizontal") {
//                                    NavigationStack {
//                                        GachaSearchView()
//                                    }
//                                }
                            }, header: {
                                Text("App.info")
                            })
                        } else {
                            Tab("App.info", systemImage: "rectangle.stack") {
                                InfoView()
                            }
                        }
                        Tab("App.tools", systemImage: "slider.horizontal.3") {
                            Text(verbatim: "leaderboard")
                        }
#if os(iOS)
                        if sizeClass == .regular {
                            Tab("App.settings", systemImage: "gear") {
                                SettingsView()
                            }
                        }
#endif
                    }
                    .tabViewStyle(.sidebarAdaptable)
                    .wrapIf(true, in: { content in
                        if #available(iOS 26.0, macOS 26.0, *) {
                            content
                                .tabBarMinimizeBehavior(.automatic)
                        } else {
                            content
                        }
                    })
                } else {
                    // MARK: Fallback for Older Versions
                    if platform == .mac || sizeClass == .regular {
                        NavigationSplitView {
                            List(selection: $selection) {
                                Label("App.home", systemImage: "house").tag(AppSection.home)
                                Label("App.community", systemImage: "at").tag(AppSection.community)
                                Label("App.leaderboard", systemImage: "chart.bar").tag(AppSection.leaderboard)
                                Section("App.info", content: {
                                    //                            Label("App.info.characters", systemImage: "person.2").tag(AppSection.info)
                                })
                                //                    Label("App.info", systemImage: "rectangle.stack").tag(AppSection.info)
                                Label("App.tools", systemImage: "slider.horizontal.3").tag(AppSection.tools)
#if os(iOS)
                                Label("App.settings", systemImage: "gear").tag(AppSection.settings)
#endif
                            }
                            .navigationTitle("Greatdori!")
                        } detail: {
                            detailView(for: selection)
                        }
                    } else {
                        TabView(selection: $selection) {
                            detailView(for: .home)
                                .tabItem { Label("App.home", systemImage: "house") }
                                .tag(AppSection.home)
                            
                            detailView(for: .community)
                                .tabItem { Label("App.community", systemImage: "at") }
                                .tag(AppSection.community)
                            
                            detailView(for: .leaderboard)
                                .tabItem { Label("App.leaderboard", systemImage: "chart.bar") }
                                .tag(AppSection.leaderboard)
                            
                            detailView(for: .info(.home))
                                .tabItem { Label("App.info", systemImage: "rectangle.stack") }
                                .tag(AppSection.info(.home))
                            
                            detailView(for: .tools)
                                .tabItem { Label("App.tools", systemImage: "slider.horizontal.3") }
                                .tag(AppSection.tools)
                        }
                    }
                }
            }
            .onAppear {
                if isFirstLaunch {
                    showWelcomeScreen = true
                    isFirstLaunch = !isFirstLaunchResettable
                }
#if !DORIKIT_ENABLE_PRECACHE
                showPreCacheAlert = true
#endif
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    startUpSucceeded = true
                }
                
                if !lastDebugPassword.isEmpty && lastDebugPassword != correctDebugPassword {
                    lastDebugPassword = ""
                    AppFlag.set(false, forKey: "DEBUG")
                }
            }
            .sheet(isPresented: $showWelcomeScreen, content: {
                WelcomeView(showWelcomeScreen: $showWelcomeScreen)
            })
            .alert("Debug.pre-cache-unavailable-alert.title", isPresented: $showPreCacheAlert, actions: {
                Button(role: .destructive, action: {}, label: {
                    Text("Debug.pre-cache-unavailable-alert.dismiss")
                })
            }, message: {
                VStack {
                    Text("Debug.pre-cache-unavailable-alert.message")
                }
            })
        } else {
            if crashViewShouldBeDisplayed {
                // Crash View pretended to be the same as loading view below.
                ProgressView()
                    .onAppear {
                        os_log("CRASH VIEW HAD BEEN ENTERED")
                        if AppFlag.DEBUG {
                            showCrashAlert = true
                        } else {
                            DoriCache.invalidateAll()
                            mainAppShouldBeDisplayed = true
                        }
                    }
                    .alert("Debug.crash-detected.title", isPresented: $showCrashAlert, actions: {
                        Button(role: .destructive, action: {
                            DoriCache.invalidateAll()
                            mainAppShouldBeDisplayed = true
                        }, label: {
                            Text("Debug.crash-detected.invalidate-cache-enter")
                        })
                        Button(role: .destructive, action: {
                            mainAppShouldBeDisplayed = true
                        }, label: {
                            Text("Debug.crash-detected.direct-enter")
                        })
                    }, message: {
                        Text("Debug.crash-detected.message")
                    })
            } else {
                ProgressView()
                    .onAppear {
                        lastStartUpWasSuccessful = startUpSucceeded
                        startUpSucceeded = false
                        if lastStartUpWasSuccessful {
                            mainAppShouldBeDisplayed = true
                        } else {
                            crashViewShouldBeDisplayed = true
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    func detailView(for section: AppSection?) -> some View {
        switch section {
        case .home: HomeView()
        case .community: HomeView()
        case .leaderboard: HomeView()
        case .info: HomeView()
        case .tools: HomeView()
        case .settings: SettingsView()
        case nil: EmptyView()
        }
    }
}


//MARK: WelcomeView
struct WelcomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State var primaryLocale = "jp"
    @State var secondaryLocale = "en"
    @Binding var showWelcomeScreen: Bool
    var body: some View {
        VStack(alignment: .leading) {
            Image("MacAppIcon")
                .resizable()
                .antialiased(true)
                .frame(width: 64, height: 64)
            Rectangle()
                .frame(height: 1)
                .opacity(0)
            Text("Welcome.title")
                .font(.title)
                .bold()
            Rectangle()
                .frame(height: 1)
                .opacity(0)
            Text("Welcome.message")
            Rectangle()
                .frame(height: 1)
                .opacity(0)
            HStack {
#if os(iOS)
                Text("Welcome.primaryLocale")
                Spacer()
#endif
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
                    Text("Welcome.primaryLocale")
                })
                .onChange(of: primaryLocale, {
                    DoriAPI.preferredLocale = localeFromStringDict[primaryLocale] ?? .jp
                })
            }
            HStack {
                #if os(iOS)
                Text("Welcome.secondaryLocale")
                Spacer()
                #endif
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
                    Text("Welcome.secondaryLocale")
                })
                .onChange(of: secondaryLocale, {
                    DoriAPI.secondaryLocale = localeFromStringDict[secondaryLocale] ?? .en
                })
            }
            Rectangle()
                .frame(height: 1)
                .opacity(0)
            Text("Welcome.footnote")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            #if os(iOS)
            Button(action: {
                //ANIMATION?
                showWelcomeScreen = false
            }, label: {
                ZStack {
                    if #available(iOS 26.0, *) {
                        Capsule()
                        .frame(height: 50)
                        .glassEffect(.identity)
                    } else {
                        RoundedRectangle(cornerRadius: 50)
                            .frame(height: 20)
                    }
                    Text("Done")
                        .bold()
                        .foregroundStyle(colorScheme == .dark ? .black : .white)
//                        .colorInvert()
                }
            })
            #endif
        }
        .padding()
        .onAppear {
            primaryLocale = DoriAPI.preferredLocale.rawValue
            secondaryLocale = DoriAPI.secondaryLocale.rawValue
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction, content: {
                Button(action: {
                    //ANIMATION?
//                    dismiss()
                    showWelcomeScreen = false
                }, label: {
                    Text("Done")
                })
//                .background()
            })
        }
    }
}


enum AppSection: Hashable {
    case home, community, leaderboard, info(InfoTab?), tools, settings
}

enum InfoTab: CaseIterable, Hashable {
    case home, characters, events, cards, gachas
}

enum Platform {
    case iOS, mac, tv, watch, unknown
}

// [?]
struct PlatformKey: EnvironmentKey {
    static let defaultValue: Platform = {
#if os(iOS)
        return .iOS
#elseif os(macOS)
        return .mac
#elseif os(tvOS)
        return .tv
#elseif os(watchOS)
        return .watch
#else
        return .unknown
#endif
    }()
}

extension EnvironmentValues {
    var platform: Platform {
        self[PlatformKey.self]
    }
}
