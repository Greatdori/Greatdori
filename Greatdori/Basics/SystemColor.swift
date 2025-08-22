//===---*- Greatdori! -*---------------------------------------------------===//
//
// SystemColor.swift
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


//MARK: The reason I make it comments is that it does not really work well.

import SwiftUI

/*
extension Color {
    public static let label = Self.init(.label)
    public static let secondaryLebel = Self.init(.secondaryLabel)
    public static let tertiaryLabel = Self.init(.tertiaryLabel)
    public static let quaternaryLabel = Self.init(.quaternaryLabel)
    public static let systemBlue = Self.init(.systemBlue)
    public static let systemBrown = Self.init(.systemBrown)
    public static let systemCyan = Self.init(.systemCyan)
    public static let systemGray = Self.init(.systemGray)
    public static let systemGreen = Self.init(.systemGreen)
    public static let systemIndigo = Self.init(.systemIndigo)
    public static let systemMint = Self.init(.systemMint)
    public static let systemOrange = Self.init(.systemOrange)
    public static let systemPink = Self.init(.systemPink)
    public static let systemPurple = Self.init(.systemPurple)
    public static let systemRed = Self.init(.systemRed)
    public static let systemTeal = Self.init(.systemTeal)
    public static let systemYellow = Self.init(.systemYellow)
    
    @available(macOS, unavailable)
    public static var darkText: Self {
        #if os(iOS)
        .init(.darkText)
        #else
        preconditionFailure()
        #endif
    }
    @available(macOS, unavailable)
    public static var lightText: Self {
        #if os(iOS)
        .init(.lightText)
        #else
        preconditionFailure()
        #endif
    }
    @available(macOS, unavailable)
    public static var opaqueSeparator: Self {
        #if os(iOS)
        .init(.opaqueSeparator)
        #else
        preconditionFailure()
        #endif
    }
    public static var placeholderText: Self {
        #if os(iOS)
        .init(.placeholderText)
        #else
        .init(.placeholderTextColor)
        #endif
    }
    public static var separator: Self {
        #if os(iOS)
        .init(.separator)
        #else
        .init(.separatorColor)
        #endif
    }
    @available(macOS, unavailable)
    public static var systemBackground: Self {
        #if os(iOS)
        .init(.systemBackground)
        #else
        preconditionFailure()
        #endif
    }
    @available(macOS, unavailable)
    public static var secondarySystemBackground: Self {
        #if os(iOS)
        .init(.secondarySystemBackground)
        #else
        preconditionFailure()
        #endif
    }
    @available(macOS, unavailable)
    public static var tertiarySystemBackground: Self {
        #if os(iOS)
        .init(.tertiarySystemBackground)
        #else
        preconditionFailure()
        #endif
    }
    public static var systemFill: Self {
        #if os(iOS)
        .init(.systemFill)
        #else
        .init(nsColor: .systemFill)
        #endif
    }
    public static var secondarySystemFill: Self {
        #if os(iOS)
        .init(.secondarySystemFill)
        #else
        .init(nsColor: .secondarySystemFill)
        #endif
    }
    public static var tertiarySystemFill: Self {
        #if os(iOS)
        .init(.tertiarySystemFill)
        #else
        .init(nsColor: .tertiarySystemFill)
        #endif
    }
    public static var quaternarySystemFill: Self {
        #if os(iOS)
        .init(.quaternarySystemFill)
        #else
        .init(nsColor: .quaternarySystemFill)
        #endif
    }
    @available(macOS, unavailable)
    public static var systemGroupedBackground: Self {
        #if os(iOS)
        .init(.systemGroupedBackground)
        #else
        preconditionFailure()
        #endif
    }
    @available(macOS, unavailable)
    public static var secondarySystemGroupedBackground: Self {
        #if os(iOS)
        .init(.secondarySystemGroupedBackground)
        #else
        preconditionFailure()
        #endif
    }
    @available(macOS, unavailable)
    public static var tertiarySystemGroupedBackground: Self {
        #if os(iOS)
        .init(.tertiarySystemGroupedBackground)
        #else
        preconditionFailure()
        #endif
    }
    
    @available(iOS, unavailable)
    public static var controlAccentColor: Self {
        #if os(macOS)
        .init(.controlAccentColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var controlBackgroundColor: Self {
        #if os(macOS)
        .init(.controlBackgroundColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var controlColor: Self {
        #if os(macOS)
        .init(.controlColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var controlTextColor: Self {
        #if os(macOS)
        .init(.controlTextColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var disabledControlTextColor: Self {
        #if os(macOS)
        .init(.disabledControlTextColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var findHighlightColor: Self {
        #if os(macOS)
        .init(.findHighlightColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var gridColor: Self {
        #if os(macOS)
        .init(.gridColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var headerTextColor: Self {
        #if os(macOS)
        .init(.headerTextColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var keyboardFocusIndicatorColor: Self {
        #if os(macOS)
        .init(.keyboardFocusIndicatorColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var selectedContentBackgroundColor: Self {
        #if os(macOS)
        .init(.selectedContentBackgroundColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var unemphasizedSelectedContentBackgroundColor: Self {
        #if os(macOS)
        .init(.unemphasizedSelectedContentBackgroundColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var selectedControlColor: Self {
        #if os(macOS)
        .init(.selectedControlColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var selectedControlTextColor: Self {
        #if os(macOS)
        .init(.selectedControlTextColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var alternateSelectedControlTextColor: Self {
        #if os(macOS)
        .init(.alternateSelectedControlTextColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var selectedTextBackgroundColor: Self {
        #if os(macOS)
        .init(.selectedTextBackgroundColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var selectedTextColor: Self {
        #if os(macOS)
        .init(.selectedTextColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var unemphasizedSelectedTextColor: Self {
        #if os(macOS)
        .init(.unemphasizedSelectedTextColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var textBackgroundColor: Self {
        #if os(macOS)
        .init(.textBackgroundColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var underPageBackgroundColor: Self {
        #if os(macOS)
        .init(.underPageBackgroundColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var windowBackgroundColor: Self {
        #if os(macOS)
        .init(.windowBackgroundColor)
        #else
        preconditionFailure()
        #endif
    }
    @available(iOS, unavailable)
    public static var windowFrameTextColor: Self {
        #if os(macOS)
        .init(.windowFrameTextColor)
        #else
        preconditionFailure()
        #endif
    }
}
*/
