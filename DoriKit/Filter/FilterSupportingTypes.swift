//===---*- Greatdori! -*---------------------------------------------------===//
//
// FilterSupportingTypes.swift
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

import Foundation

public enum DoriFilterCharacter: Int, Sendable, CaseIterable, Hashable, Codable {
    // Poppin'Party
    case kasumi = 1
    case tae
    case rimi
    case saya
    case arisa
    
    // Afterglow
    case ran
    case moca
    case himari
    case tomoe
    case tsugumi
    
    // Hello, Happy World!
    case kokoro
    case kaoru
    case hagumi
    case kanon
    case misaki
    
    // Pastel＊Palettes
    case aya
    case hina
    case chisato
    case maya
    case eve
    
    // Roselia
    case yukina
    case sayo
    case lisa
    case ako
    case rinko
    
    // Morfonica
    case mashiro
    case toko
    case nanami
    case tsukushi
    case rui
    
    // RAISE A SUILEN
    case rei
    case rokka
    case masuki
    case reona
    case chiyu
    
    // MyGO!!!!!
    case tomori
    case anon
    case rana
    case soyo
    case taki
    
    /// Localized character name.
    @inline(never)
    public var name: String {
        NSLocalizedString("CHARACTER_NAME_ID_" + String(self.rawValue), bundle: #bundle, comment: "")
    }
}

@frozen
public enum DoriFilterTimelineStatus: Int, CaseIterable, Hashable, Codable {
    case ended
    case ongoing
    case upcoming
    
    /// Localized description text for status.
    @inline(never)
    internal var localizedString: String {
        switch self {
        case .ended: String(localized: "TIMELINE_STATUS_ENDED", bundle: #bundle)
        case .ongoing: String(localized: "TIMELINE_STATUS_ONGOING", bundle: #bundle)
        case .upcoming: String(localized: "TIMELINE_STATUS_UPCOMING", bundle: #bundle)
        }
    }
}
