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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            #if os(macOS)
            if AppFlag.DEBUG {
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
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .background:
                break
            case .inactive:
                break
            case .active:
                #if os(iOS)
                UIApplication.shared.registerForRemoteNotifications()
                #endif
            @unknown default: break
            }
        }
        #if os(macOS)
        Settings {
            SettingsView()
        }
        
        Window(String("Window.offline-asset-debug"), id: "OfflineAssetDebugWindow") {
            DebugOfflineAssetView()
        }
        Window(String("Window.filter-experiment-debug"), id: "FilterExperimentDebugWindow") {
            DebugFilterExperimentView()
        }
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
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            handleURL(url)
        }
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
    default: break
    }
}
