//
//  ContentView.swift
//  Greatdori
//
//  Created by Mark Chan on 7/18/25.
//

import SwiftUI


enum AppSection: Hashable {
  case home, community, leaderboard, info, tools, settings
}

struct ContentView: View {
    @State private var selection: AppSection? = .home
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.platform) var platform // 自定义 platform 判断（见下方拓展）
    
    var body: some View {
        if platform == .mac || sizeClass == .regular {
            NavigationSplitView {
                List(selection: $selection) {
                    Label("App.home", systemImage: "house").tag(AppSection.home)
                    Label("App.community", systemImage: "at").tag(AppSection.community)
                    Label("App.leaderboard", systemImage: "chart.bar").tag(AppSection.leaderboard)
                    Label("App.info", systemImage: "rectangle.stack").tag(AppSection.info)
                    Label("App.tools", systemImage: "slider.horizontal.3").tag(AppSection.tools)
                    Label("App.settings", systemImage: "gear").tag(AppSection.settings)
                }
                .navigationTitle("Greatdori")
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
        
        detailView(for: .info)
          .tabItem { Label("App.info", systemImage: "rectangle.stack") }
          .tag(AppSection.info)
        
        detailView(for: .tools)
          .tabItem { Label("App.tools", systemImage: "slider.horizontal.3") }
          .tag(AppSection.tools)
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
    @Environment(\.colorScheme) var colorScheme
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    var body: some View {
#if os(iOS)
        content()
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
#elseif os(macOS)
        GroupBox {
            content()
                .padding()
        }
#endif
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
