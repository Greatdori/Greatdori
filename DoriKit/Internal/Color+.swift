//===---*- Greatdori! -*---------------------------------------------------===//
//
// Color+.swift
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

import SwiftUI

extension Color {
    internal init?(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        let cleanedHex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        
        guard cleanedHex.count == 6 else { return nil }
        
        var rgbValue: UInt64 = 0
        unsafe Scanner(string: cleanedHex).scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255
        let b = Double(rgbValue & 0x0000FF) / 255
        
        self.init(.sRGB, red: r, green: g, blue: b)
    }
}
