//
//  GreatdoriApp.swift
//  Greatdori
//
//  Created by Mark Chan on 7/18/25.
//

import SwiftUI
import DoriKit
import SDWebImage
import SDWebImageSVGCoder

@main
struct GreatdoriApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate
    #else
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    #endif
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    @Environment(\.locale) var locale
    @AppStorage("IsFirstLaunch") var isFirstLaunch = true
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        
        if isFirstLaunch {
            DoriAPI.preferredLocale = switch locale.language {
            case let x where x.hasCommonParent(with: .init(identifier: "ja-JP")): .jp
            case let x where x.hasCommonParent(with: .init(identifier: "en-US")): .en
            case let x where x.isEquivalent(to: .init(identifier: "zh-TW")): .tw
            case let x where x.hasCommonParent(with: .init(identifier: "zh-CN")): .cn
            case let x where x.hasCommonParent(with: .init(identifier: "ko-KO")): .kr
            default: .jp
            }
            isFirstLaunch = false
        }
    }
}
#else
class AppDelegate: NSObject, UIApplicationDelegate {
    @Environment(\.locale) var locale
    @AppStorage("IsFirstLaunch") var isFirstLaunch = true
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        
        if isFirstLaunch {
            DoriAPI.preferredLocale = switch locale.language {
            case let x where x.hasCommonParent(with: .init(identifier: "ja-JP")): .jp
            case let x where x.hasCommonParent(with: .init(identifier: "en-US")): .en
            case let x where x.isEquivalent(to: .init(identifier: "zh-TW")): .tw
            case let x where x.hasCommonParent(with: .init(identifier: "zh-CN")): .cn
            case let x where x.hasCommonParent(with: .init(identifier: "ko-KO")): .kr
            default: .jp
            }
            isFirstLaunch = false
        }
    }
}
#endif
