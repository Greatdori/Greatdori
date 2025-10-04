//===---*- Greatdori! -*---------------------------------------------------===//
//
// GreatdoriApp.swift
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

import Combine
import DoriKit
import SDWebImage
import SDWebImageSVGCoder
import SwiftUI
#if os(iOS)
import UIKit
import BackgroundTasks
#else
import AppKit
#endif


//MARK: System Orientation
#if os(macOS)
let isMACOS = true
#else
let isMACOS = false
#endif


//MARK: GreatdoriApp (@main)
@main
struct GreatdoriApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate
    #else
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    #endif
    @Environment(\.openWindow) var openWindow
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("EnableRulerOverlay") var enableRulerOverlay = false
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if enableRulerOverlay {
                    DebugRulerOverlay()
                }
            }
            .onOpenURL { url in
                handleURL(url)
            }
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(action: {
                    openWindow(id: "Secchi")
                }, label: {
                    Label("Settings.prompt", systemImage: "gear")
                })
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        /*
        .commands {
            #if os(macOS)
            if AppFlag.DEBUG {
//                /Users/t785/Xcode/Greatdori/Greatdori/GreatdoriApp.swift
                CommandGroup(after: .appSettings) {
                    Button(String("Menu-bar.window.offline-asset-debug"), systemImage: "ant.fill") {
                        openWindow(id: "OfflineAssetDebugWindow")
                    }
                }
                CommandGroup(after: .appSettings) {
                    Button(String("Menu-bar.window.filter-experiment-debug"), systemImage: "ant.fill") {
                        openWindow(id: "FilterExperimentDebugWindow")
                    }
                }
            }
            #endif
        }
        */
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .background:
                break
            case .inactive:
                break
            case .active:
                #if os(iOS)
                UNUserNotificationCenter.current().setBadgeCount(0)
                UIApplication.shared.registerForRemoteNotifications()
                #else
                NSApplication.shared.registerForRemoteNotifications()
                #endif
            @unknown default: break
            }
        }
        #if os(macOS)
//        Settings {
//            SettingsView()
//        }
        Window("Settings", id: "Secchi") {
            SettingsView()
        }
//        Window(String("Window.offline-asset-debug"), id: "OfflineAssetDebugWindow") {
//            DebugOfflineAssetView()
//        }
//        Window(String("Window.filter-experiment-debug"), id: "FilterExperimentDebugWindow") {
//            DebugFilterExperimentView()
//        }
        #endif
    }
}


//MARK: AppDelegate
#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    @Environment(\.locale) var locale
    @AppStorage("IsFirstLaunch") var isFirstLaunch = true
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        
//        if isFirstLaunch {
//            DoriAPI.preferredLocale = switch locale.language {
//            case let x where x.hasCommonParent(with: .init(identifier: "ja-JP")): .jp
//            case let x where x.hasCommonParent(with: .init(identifier: "en-US")): .en
//            case let x where x.isEquivalent(to: .init(identifier: "zh-TW")): .tw
//            case let x where x.hasCommonParent(with: .init(identifier: "zh-CN")): .cn
//            case let x where x.hasCommonParent(with: .init(identifier: "ko-KO")): .kr
//            default: .jp
//            }
//            isFirstLaunch = false
//        }
        
        // Don't say lazy
        _ = NetworkMonitor.shared
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            handleURL(url)
        }
    }
    
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserDefaults.standard.set(deviceToken, forKey: "RemoteNotifDeviceToken")
    }
}
#else
class AppDelegate: NSObject, UIApplicationDelegate {
    @Environment(\.locale) var locale
    @AppStorage("IsFirstLaunch") var isFirstLaunch = true
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        
//        if isFirstLaunch {
//            DoriAPI.preferredLocale = switch locale.language {
//            case let x where x.hasCommonParent(with: .init(identifier: "ja-JP")): .jp
//            case let x where x.hasCommonParent(with: .init(identifier: "en-US")): .en
//            case let x where x.isEquivalent(to: .init(identifier: "zh-TW")): .tw
//            case let x where x.hasCommonParent(with: .init(identifier: "zh-CN")): .cn
//            case let x where x.hasCommonParent(with: .init(identifier: "ko-KO")): .kr
//            default: .jp
//            }
//            isFirstLaunch = false
//        }
        
        // Don't say lazy
        _ = NetworkMonitor.shared
        
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        handleURL(url)
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserDefaults.standard.set(deviceToken, forKey: "RemoteNotifDeviceToken")
    }
}
#endif

private func handleURL(_ url: URL) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
    switch components.host {
    case "flag":
        if let items = components.queryItems {
            for item in items {
                if let value = item.value {
                    AppFlag.set((Int(value) ?? (value == "true" ? 1 : 0)) != 0, forKey: item.name)
                }
            }
        }
    case "info":
        let paths = components.path.split(separator: "/")
        if paths.count >= 2 {
            switch paths[0] {
            case "cards":
                if let id = Int(paths[1]) {
                    rootShowView {
                        CardDetailView(id: id)
                    }
                }
            default: break
            }
        }
    default: break
    }
}

@MainActor let _showRootViewSubject = PassthroughSubject<AnyView, Never>()
func rootShowView(@ViewBuilder content: () -> some View) {
    let view = AnyView(content())
    DispatchQueue.main.async {
        _showRootViewSubject.send(view)
    }
}
extension View {
    func handlesExternalView() -> some View {
        modifier(_ExternalViewHandlerModifier())
    }
}
private struct _ExternalViewHandlerModifier: ViewModifier {
    @State private var presentingView: AnyView?
    @State private var isViewPresented = false
    func body(content: Content) -> some View {
        content
            .navigationDestination(isPresented: $isViewPresented) {
                presentingView
            }
            .onReceive(_showRootViewSubject) { view in
                presentingView = view
                isViewPresented = true
            }
    }
}
