//
//  LocalizedStrings.swift
//  Greatdori
//
//  Created by Mark Chan on 7/23/25.
//

import Foundation

extension DoriAPI.Constellation {
    @inline(never)
    public var localizedString: String {
        switch self {
        case .aries: String(localized: "CONSTELLATION_ARIES", bundle: #bundle)
        case .taurus: String(localized: "CONSTELLATION_TAURUS", bundle: #bundle)
        case .gemini: String(localized: "CONSTELLATION_GEMINI", bundle: #bundle)
        case .cancer: String(localized: "CONSTELLATION_CANCER", bundle: #bundle)
        case .leo: String(localized: "CONSTELLATION_LEO", bundle: #bundle)
        case .virgo: String(localized: "CONSTELLATION_VIRGO", bundle: #bundle)
        case .libra: String(localized: "CONSTELLATION_LIBRA", bundle: #bundle)
        case .scorpio: String(localized: "CONSTELLATION_SCORPIO", bundle: #bundle)
        case .sagittarius: String(localized: "CONSTELLATION_SAGITTARIUS", bundle: #bundle)
        case .capricorn: String(localized: "CONSTELLATION_CAPRICORN", bundle: #bundle)
        case .aquarius: String(localized: "CONSTELLATION_AQUARIUS", bundle: #bundle)
        case .pisces: String(localized: "CONSTELLATION_PISCES", bundle: #bundle)
        }
    }
}

extension DoriAPI.Card.CardType {
    @inline(never)
    public var localizedString: String {
        NSLocalizedString("card" + self.rawValue, bundle: #bundle, comment: "")
    }
}

extension DoriAPI.Character.Character.Profile.Part {
    @inline(never)
    public var localizedString: String {
        switch self {
        case .vocal: String(localized: "CHARACTER_PROFILE_PART_VOCAL", bundle: #bundle)
        case .keyboard: String(localized: "CHARACTER_PROFILE_PART_KEYBOARD", bundle: #bundle)
        case .guitar: String(localized: "CHARACTER_PROFILE_PART_GUITAR", bundle: #bundle)
        case .guitarVocal: String(localized: "CHARACTER_PROFILE_PART_GUITAR_VOCAL", bundle: #bundle)
        case .bass: String(localized: "CHARACTER_PROFILE_PART_BASS", bundle: #bundle)
        case .bassVocal: String(localized: "CHARACTER_PROFILE_PART_BASS_VOCAL", bundle: #bundle)
        case .drum: String(localized: "CHARACTER_PROFILE_PART_DRUM", bundle: #bundle)
        case .violin: String(localized: "CHARACTER_PROFILE_PART_VIOLIN", bundle: #bundle)
        case .dj: String(localized: "CHARACTER_PROFILE_PART_DJ", bundle: #bundle)
        }
    }
}
