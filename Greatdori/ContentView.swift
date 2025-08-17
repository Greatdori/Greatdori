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

import SwiftUI
import DoriKit


enum AppSection: Hashable {
    case home, community, leaderboard, info(InfoTab), tools, settings
}

enum InfoTab: CaseIterable, Hashable {
    case home, characters, events
}

struct ContentView: View {
    @State private var selection: AppSection? = .home
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.platform) var platform
    @AppStorage("isFirstLaunch") var isFirstLaunch = true
    @AppStorage("isFirstLaunchResettable") var isFirstLaunchResettable = true
    @State var showWelcomeScreen = false
    @State var showPreCacheAlert = false
    
    var body: some View {
        Group {
            if #available(macOS 15.0, iOS 18.0, *) {
                TabView(selection: $selection) {
                    
                    Tab("App.home", systemImage: "house", value: .home) {
                        HomeView()
                    }
                    Tab("App.community", systemImage: "at", value: .community) {
//                        HomeView()
                        Text(verbatim: "community")
                    }
                    Tab("App.leaderboard", systemImage: "chart.bar", value: .leaderboard) {
//                        HomeView()
                        Text(verbatim: "leaderboard")
                    }
                    TabSection(content: {
                        Tab("App.info.characters", systemImage: "person.2", value: AppSection.info(.characters)) {
                            Text(verbatim: "char")
                        }
                        Tab("App.info.events", systemImage: "line.horizontal.star.fill.line.horizontal", value: AppSection.info(.events)) {
                            EventSearchView()
                        }
                    }, header: {
                        Text("App.info")
                    })

                    #if os(iOS)
                    if sizeClass == .regular {
                        Tab("App.settings", systemImage: "gear", value: .settings) {
                            //                        Text("settings")
                            SettingsView()
                        }
                    }
                    #endif
                    //                }
                    //                Tab($selection, tag: .community) { HomeView() }
                    //                Tab($selection, tag: .leaderboard) { HomeView() }
                    //                Tab($selection, tag: .info) { HomeView() }
                    //                Tab($selection, tag: .tools) { HomeView() }
                }
                .tabViewStyle(.sidebarAdaptable)
            } else {
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

enum Platform {
    case iOS, mac, tv, watch, unknown
}

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


struct CustomGroupBox<Content: View>: View {
    let content: () -> Content
    var showGroupBox: Bool = true
    let uuid = UUID()
    @Namespace private var groupBoxNamespace
    init(showGroupBox: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.showGroupBox = showGroupBox
        self.content = content
    }
    var body: some View {
        Group {
            if showGroupBox {
#if os(iOS)
                content()
                    .matchedGeometryEffect(id: uuid, in: groupBoxNamespace)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundStyle(Color(.secondarySystemGroupedBackground))
                    }
#elseif os(macOS)
                GroupBox {
                    content()
                        .matchedGeometryEffect(id: uuid, in: groupBoxNamespace)
                        .padding()
                }
#endif
            } else {
                content()
                    .matchedGeometryEffect(id: uuid, in: groupBoxNamespace)
            }
        }
    }
}

func groupedContentBackgroundColor() -> Color {
#if os(iOS)
    return Color(.systemGroupedBackground)
#elseif os(macOS)
    return Color(NSColor.windowBackgroundColor)
#endif
}

struct DismissButton<L: View>: View {
    var action: () -> Void
    var label: () -> L
    var doDismiss: Bool = true
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Button(action: {
            action()
            if doDismiss {
                dismiss()
            }
        }, label: {
            label()
        })
    }
}


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
            primaryLocale = localeToStringDict[DoriAPI.preferredLocale]?.lowercased() ?? "jp"
            secondaryLocale = localeToStringDict[DoriAPI.secondaryLocale]?.lowercased() ?? "en"
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
            })
        }
    }
}
