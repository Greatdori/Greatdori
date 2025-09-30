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

import CoreImage.CIFilterBuiltins
import DoriKit
import Network
import SDWebImageSwiftUI
import SwiftUI
import UniformTypeIdentifiers
import Vision

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

/* NO USAGE
func compareWithinNormalRange(_ lhs: Int, _ rhs: Int, largetAcceptableNumber: Int, ascending: Bool = true) -> Bool {
    let correctedLHS = lhs > largetAcceptableNumber ? lhs : nil
    let correctedRHS = rhs > largetAcceptableNumber ? rhs : nil
    return compare(correctedLHS, correctedRHS, ascending: ascending)
}
*/


// MARK: copyStringToClipboard
func copyStringToClipboard(_ content: String) {
#if os(macOS)
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(content, forType: .string)
#else
    UIPasteboard.general.string = content
#endif
}

// MARK: formattedSongLength
func formattedSongLength(_ time: Double) -> String {
    let minutes = Int(time / 60)
    let seconds = time.truncatingRemainder(dividingBy: 60)
    return String(format: "%d:%04.1f", minutes, seconds) // 1:42.6
}

// MARK: getBirthdayTimeZone
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

// MARK: getCharactersRelatingBand [?]
//func getCharactersRelatingBand(_ characterID: Int) -> Int {
//    return DoriCache.preCache.categorizedCharacters.first { (_, characters) in
//        characters.contains(where: { $0.id == characterID })
//    }?.key?.id ?? 0
//}


// MARK: getAttributedString
func getAttributedString(_ source: String, fontSize: Font.TextStyle = .body, fontWeight: Font.Weight = .regular, foregroundColor: Color = .primary) -> AttributedString {
    var attrString = AttributedString()
    attrString = AttributedString(source)
    attrString.font = .system(fontSize, weight: fontWeight)
    attrString.foregroundColor = foregroundColor
    return attrString
}

// MARK: getImageSubject
func getImageSubject(_ data: Data) async -> Data? {
    if #available(iOS 18.0, macOS 15.0, *) {
            guard var image = CIImage(data: data) else { return nil }
            do {
                image = image.oriented(.up)
               
                let request = GenerateForegroundInstanceMaskRequest()
                let result = try await request.perform(on: image)
                
                guard let cgImage = result?.allInstances.compactMap({ (index) -> (CGImage, Int)? in
                    let buffer = try? result?.generateMaskedImage(for: [index], imageFrom: .init(data))
                    if buffer != nil {
                        let _image = CIImage(cvPixelBuffer: unsafe buffer.unsafelyUnwrapped)
                        let context = CIContext()
                        guard let image = context.createCGImage(_image, from: _image.extent) else { return nil }
                        return (image, image.width * image.height)
                    } else {
                        return nil
                    }
                }).min(by: { $0.1 < $1.1 })?.0 else { return nil }
                
                let _imageData = NSMutableData()
                if let dest = CGImageDestinationCreateWithData(_imageData, UTType.png.identifier as CFString, 1, nil) {
                    CGImageDestinationAddImage(dest, cgImage, nil)
                    if CGImageDestinationFinalize(dest) {
                        return _imageData as Data
//#if os(macOS)
//                        NSPasteboard.general.clearContents()
//                        NSPasteboard.general.setData(_imageData as Data, forType: .png)
//#else
//                        UIPasteboard.general.image = .init(data: _imageData as Data)!
//#endif
                    }
                }
            } catch {
                print(error)
            }
    } else {
        return nil
    }
    return nil
}


// MARK: getPlaceholderColor
func getPlaceholderColor() -> Color {
#if os(iOS)
    return Color(UIColor.placeholderText)
#else
    return Color.gray
#endif
}

// MARK: getProperDataSourceType
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

// MARK: getSecondaryBackgroundColor
func getTertiaryLabelColor() -> Color {
#if os(iOS)
    return Color(UIColor.tertiaryLabel)
#else
    return Color(NSColor.tertiaryLabelColor)
#endif
}

// MARK: highlightOccurrences
/// Highlights all occurrences of a keyword within a string in blue.
/// - Parameters:
///   - keyword: The substring to highlight within `content`. If empty or only whitespace, no highlighting occurs.
///   - content: The string to search in.
/// - Returns: An AttributedString (from `content`) with all `keyword` occurrences colored blue.
func highlightOccurrences(of keyword: String, in content: String?) -> AttributedString? {
    if let content {
        var attributedString = AttributedString(content)
        guard !keyword.isEmpty else { return attributedString }
        guard !content.isEmpty else { return attributedString }
        //    let keywordTrimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let range = attributedString.range(of: keyword, options: .caseInsensitive) else { return attributedString }
        attributedString[range].foregroundColor = .accent
        
        return attributedString
    } else {
        return nil
    }
}

// MARK: ListItemType
enum ListItemType: Hashable, Equatable {
    case compactOnly
    case expandedOnly
    case automatic
    case basedOnUISizeClass
}
