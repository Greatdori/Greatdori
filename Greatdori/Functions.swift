//===---*- Greatdori! -*---------------------------------------------------===//
//
// Functions.swift
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

// (In Alphabetic Order)

import DoriKit
import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: compare
func compare<T: Comparable>(_ lhs: T?, _ rhs: T?, ascending: Bool = true) -> Bool {
    if lhs == nil {
        return false
    } else if rhs == nil {
        return true
    } else {
        if ascending {
            return lhs! > rhs!
        } else {
            return lhs! < rhs!
        }
    }
}

//MARK: copyStringToClipboard
func copyStringToClipboard(_ content: String) {
#if os(macOS)
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(content, forType: .string)
#else
    UIPasteboard.general.string = content
#endif
}

//MARK: getBirthdayTimeZone
func getBirthdayTimeZone(from input: BirthdayTimeZone? = nil) -> TimeZone {
    switch (input != nil ? input! : BirthdayTimeZone(rawValue: UserDefaults.standard.string(forKey: "BirthdayTimeZone") ?? "JST"))! {
    case .adaptive:
        return TimeZone.autoupdatingCurrent
    case .JST:
        return TimeZone(identifier: "Asia/Tokyo")!
    case .UTC:
        return TimeZone.gmt
    case .CST:
        return TimeZone(identifier: "Asia/Shanghai")!
    case .PT:
        return TimeZone(identifier: "America/Los_Angeles")!
    }
}


//MARK: getPlaceholderColor
func getPlaceholderColor() -> Color {
#if os(iOS)
    return Color(UIColor.placeholderText)
#else
    return Color(NSColor.placeholderTextColor)
#endif
}

//MARK: getProperDataSourceType
@MainActor func getProperDataSourceType(dataPrefersInternet: Bool = false) -> OfflineAssetBehavior {
    let dataSourcePreference = DataSourcePreference(rawValue: UserDefaults.standard.string(forKey: "DataSourcePreference") ?? "hybrid") ?? .hybrid
    switch dataSourcePreference {
    case .hybrid :
        if dataPrefersInternet && NetworkMonitor.shared.isConnected {
            return .disabled
        } else {
            return .enableIfAvailable
        }
    case .useLocal:
        return .enabled
    case .useInternet:
        return .disabled
    }
}

//MARK: getSecondaryBackgroundColor
func getTertiaryLabelColor() -> Color {
#if os(iOS)
    return Color(UIColor.tertiaryLabel)
#else
    return Color(NSColor.tertiaryLabelColor)
#endif
}

//MARK: highlightOccurrences
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

//MARK: ListItemType
enum ListItemType: Hashable, Equatable {
    case compactOnly
    case expandedOnly
    case automatic
}
