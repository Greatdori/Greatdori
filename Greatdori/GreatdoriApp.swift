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
import UIKit

#if os(macOS)
let imageButtonSize: CGFloat = 30
let cardThumbnailSideLength: CGFloat = 64
let isMACOS = true
#else
let imageButtonSize: CGFloat = 35
let cardThumbnailSideLength: CGFloat = 72
let isMACOS = false
#endif


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
    
    @ViewBuilder
    func withSystemBackground() -> some View {
#if os(iOS)
        self
            .background(Color(.systemGroupedBackground))
#else
        self
#endif
    }
}

extension Int?: @retroactive Identifiable {
    public var id: Int? { self }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension Optional {
    var id: Self { self }
}

extension View {
    /// Performs action when frame of attached view changes.
    ///
    /// ```swift
    /// struct MyView: View {
    ///     var body: some View {
    ///         MyView()
    ///             .onFrameChange { geometry in
    ///                 print(geometry)
    ///             }
    ///     }
    /// }
    /// ```
    /// 
    /// - Parameter action: The action to perform.
    /// - Returns: A view that triggers `action` when its frame changes.
    func onFrameChange(perform action: @escaping (_ geometry: GeometryProxy) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        action(geometry)
                    }
                    .onChange(of: geometry.size) {
                        action(geometry)
                    }
            }
        )
    }
}

func highlightKeyword(in content: String, keyword: String) -> AttributedString {
    var attributed = AttributedString(content)
    
    var searchRange = attributed.startIndex..<attributed.endIndex
    while let range = attributed.range(of: keyword,
                                       options: [.caseInsensitive]
                                       /*range: searchRange*/) {
        attributed[range].foregroundColor = .blue
        //        attributed[range].font = .headline
        searchRange = range.upperBound..<attributed.endIndex
    }
    
    return attributed
}

/// Highlights all occurrences of a keyword within a string in blue.
/// - Parameters:
///   - keyword: The substring to highlight within `content`. If empty or only whitespace, no highlighting occurs.
///   - content: The string to search in.
/// - Returns: An AttributedString (from `content`) with all `keyword` occurrences colored blue.
func highlightOccurrences(of keyword: String, in content: String) -> AttributedString {
    var attributedString = AttributedString(content)
    guard !keyword.isEmpty else { return attributedString }
    guard !content.isEmpty else { return attributedString }
//    let keywordTrimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let range = attributedString.range(of: keyword, options: .caseInsensitive) else { return attributedString }
    attributedString[range].foregroundColor = .accent

    return attributedString
}

func highlightOccurrencesOld(of keyword: String, in content: String) -> AttributedString {
    var attributed = AttributedString(content)
    let keywordTrimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !keywordTrimmed.isEmpty else { return attributed }
    
    var searchRange = attributed.startIndex..<attributed.endIndex
    while let range = attributed.range(of: keywordTrimmed, options: [.caseInsensitive]/*, range: searchRange*/) {
        attributed[range].foregroundColor = .blue
        searchRange = range.upperBound..<attributed.endIndex
    }
    return attributed
}

func copyStringToClipboard(_ content: String) {
    #if os(macOS)
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(content, forType: .string)
    #else
    UIPasteboard.general.string = content
    #endif
}
