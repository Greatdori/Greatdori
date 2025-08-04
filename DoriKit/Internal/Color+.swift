//
//  Color+.swift
//  Greatdori
//
//  Created by Mark Chan on 7/18/25.
//

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
