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

func copyStringToClipboard(_ content: String) {
#if os(macOS)
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(content, forType: .string)
#else
    UIPasteboard.general.string = content
#endif
}

func getGroupedBackgroundColor() -> Color {
#if os(iOS)
    return Color(UIColor.systemGroupedBackground)
#else
    return Color(NSColor.groupedBackgroundColor)
#endif
}

func getPlaceholderColor() -> Color {
#if os(iOS)
    return Color(UIColor.placeholderText)
#else
    return Color(NSColor.placeholderTextColor)
#endif
}

func getWindowBackgroundColor() -> Color {
#if os(iOS)
    return Color(UIColor.systemBackground)
#else
    return Color(NSColor.windowBackground)
#endif
}

//MARK:
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


