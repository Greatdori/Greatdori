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
}
#endif


public extension View {
    /// Wraps a view into a specific container when `condition` is `true`.
    ///
    /// Use this modifier to conditionally wrap a view into a container.
    /// ```swift
    /// struct MyView: View {
    ///     @State private var navigatable = false
    ///     var body: some View {
    ///         List {
    ///             Button("Switch Navigatability") {
    ///                 navigatable.toggle()
    ///             }
    ///             NavigationLink("Navigate", destination: { /* some view... */ })
    ///         }
    ///         .wrapIf(navigatable) { content in
    ///             NavigationStack { content }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: When the condition changes, SwiftUI redraws the whole contained view.
    ///
    /// - Parameters:
    ///   - condition: Whether to wrap the view into the specific container.
    ///   - container: Wrapping container which makes sence when `condition` is `true`.
    /// - Returns: A view that wrapped into the specific container when `condition` is `true`.
    @ViewBuilder
    func wrapIf(_ condition: Bool, @ViewBuilder in container: (Self) -> some View) -> some View {
        if condition {
            container(self)
        } else {
            self
        }
    }
    
    /// Wraps a view into a specific container when `condition` is `true`,
    /// and wraps it into the other container when `condition` is `false`.
    ///
    /// ```swift
    /// struct MyView: View {
    ///     @State private var appearance = false
    ///     var body: some View {
    ///         Button("Switch Appearance") {
    ///             appearance.toggle()
    ///         }
    ///         .wrapIf(appearance) { content in
    ///             VStack { content }
    ///         } else: { content in
    ///             List { content }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: When the condition changes, SwiftUI redraws the whole contained view.
    ///
    /// - Parameters:
    ///   - condition: Whether to wrap the view into the `true` container or the `false` container.
    ///   - container: Wrapping container which makes sence when `condition` is `true`.
    ///   - elseContainer: Wrapping container which makes sence when `condition` is `false`.
    /// - Returns: A view that wrapped into the `true` container when `condition` is `true`, vice versa.
    @ViewBuilder
    func wrapIf(_ condition: Bool, @ViewBuilder in container: (Self) -> some View, @ViewBuilder else elseContainer: (Self) -> some View) -> some View {
        if condition {
            container(self)
        } else {
            elseContainer(self)
        }
    }
}
