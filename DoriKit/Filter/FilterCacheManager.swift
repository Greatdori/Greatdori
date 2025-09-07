//===---*- Greatdori! -*---------------------------------------------------===//
//
// FilterCacheManager.swift
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

internal final class FilterCacheManager: Sendable {
    internal static let shared = FilterCacheManager()
    
    nonisolated(unsafe) private var allCache = _FilterCache()
    private let lock = NSLock()
    
    internal func writeCardCache(_ cardsList: [DoriAPI.Card.PreviewCard]?) {
        lock.lock()
        defer { lock.unlock() }
        if cardsList != nil {
            unsafe allCache.cardsList = cardsList
            unsafe allCache.cardsDict.removeAll()
            if let cards = cardsList {
                for card in cards {
                    unsafe allCache.cardsDict[card.id] = card
                }
            }
        }
    }
    
    internal func writeBandsList(_ bandsList: [DoriAPI.Band.Band]?) {
        lock.lock()
        defer { lock.unlock() }
        if bandsList != nil {
            unsafe allCache.bandsList = bandsList
        }
    }
    
    internal func writeCharactersList(_ charactersList: [DoriAPI.Character.PreviewCharacter]?) {
        lock.lock()
        defer { lock.unlock() }
        if charactersList != nil {
            unsafe allCache.charactersList = charactersList
        }
    }
    
    internal func read() -> _FilterCache {
        lock.lock()
        defer { lock.unlock() }
        return unsafe allCache
    }
    
    internal func erase() {
        lock.lock()
        defer { lock.unlock() }
        unsafe allCache = .init()
    }
}

public struct _FilterCache {
    internal var cardsList: [DoriAPI.Card.PreviewCard]?
    internal var cardsDict: [Int: DoriAPI.Card.PreviewCard] = [:]
    internal var bandsList: [DoriAPI.Band.Band]?
    internal var charactersList: [DoriAPI.Character.PreviewCharacter]?
}
