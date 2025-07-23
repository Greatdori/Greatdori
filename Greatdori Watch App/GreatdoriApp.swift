//
//  GreatdoriApp.swift
//  Greatdori Watch App
//
//  Created by Mark Chan on 7/18/25.
//

import SwiftUI
import DoriKit
import SDWebImage
import SDWebImageSVGCoder

@main
struct GreatdoriWatchApp: App {
    @WKApplicationDelegateAdaptor var appDelegate: AppDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, WKApplicationDelegate {
    @Environment(\.locale) var locale
    @AppStorage("IsFirstLaunch") var isFirstLaunch = true
    
    func applicationDidFinishLaunching() {
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
