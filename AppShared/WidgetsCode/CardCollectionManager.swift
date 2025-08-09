//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardCollectionManager.swift
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
import DoriKit
import Foundation
private import BuiltinCardCollections

class CardCollectionManager {
    static let shared = CardCollectionManager()
    
    private let encoder: PropertyListEncoder
    private let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.memz233.Greatdori.Widgets")!.path
    
    private init() {
        self.encoder = .init()
        self.encoder.outputFormat = .binary
        if let data = try? Data(contentsOf: URL(filePath: containerPath + "/Documents/UserCardCollections.plist")) {
            let decoder = PropertyListDecoder()
            self.userCollections = (try? decoder.decode([Collection].self, from: data)) ?? []
        }
    }
    
    private(set) var userCollections = [Collection]()
    
    @inline(__always)
    var builtinCollections: [Collection] {
        builtinCardCollectionNames.map { .init(builtin: .init(named: $0)!) }
    }
    @inline(__always)
    var allCollections: [Collection] {
        builtinCollections + userCollections
    }
    
    func append(_ collection: Collection) {
        userCollections.append(collection)
        updateStorage()
    }
    func insert(_ newElement: Collection, at index: Int) {
        userCollections.insert(newElement, at: index)
        updateStorage()
    }
    func remove(at index: Int) {
        userCollections.remove(at: index)
        updateStorage()
    }
    func remove(atOffsets offsets: IndexSet) {
        userCollections.remove(atOffsets: offsets)
        updateStorage()
    }
    func removeAll() {
        userCollections.removeAll()
        updateStorage()
    }
    
    @discardableResult
    func writeImageData(_ data: Data, named name: String) -> Card.File {
        if !FileManager.default.fileExists(atPath: containerPath + "/Documents/CardImages") {
            try? FileManager.default.createDirectory(atPath: containerPath + "/Documents/CardImages", withIntermediateDirectories: true)
        }
        try? data.write(to: URL(filePath: containerPath + "/Documents/CardImages/\(name).png"))
        return .path("/Documents/CardImages/\(name).png")
    }
    
    func nameAvailable(_ name: String) -> Bool {
        !builtinCardCollectionNames.contains(name) && !userCollections.contains(where: { $0.name == name })
    }
    
    func _collection(named name: String) -> Collection? {
        if builtinCardCollectionNames.contains(name) {
            return .init(builtin: .init(named: name)!)
        }
        return builtinCollections.first(where: { $0.name == name }) ?? userCollections.first(where: { $0.name == name })
    }
    
    private func updateStorage() {
        if let data = try? encoder.encode(userCollections) {
            try? data.write(to: URL(filePath: containerPath + "/Documents/UserCardCollections.plist"))
        }
    }
    
    @_eagerMove
    struct Collection: Codable {
        var name: String
        var _rawName: String?
        var cards: [Card]
        
        init(name: String, cards: [Card]) {
            self.name = name
            self.cards = cards
        }
        fileprivate init(name: String, _rawName: String? = nil, cards: [Card]) {
            self.name = name
            self._rawName = _rawName
            self.cards = cards
        }
    }
    @_eagerMove
    struct Card: Codable {
        var localizedName: DoriAPI.LocalizedData<String>
        var file: File
        
        enum File: Codable {
            case builtin(String)
            case path(String)
            
            #if !os(macOS)
            var image: UIImage? {
                let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.memz233.Greatdori.Widgets")!.path
                switch self {
                case .builtin(let name):
                    return builtinImage(named: name)
                case .path(let path):
                    return UIImage(contentsOfFile: containerPath + path)
                }
            }
            #else
            var image: NSImage? {
                let containerPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.memz233.Greatdori.Widgets")!.path
                switch self {
                case .builtin(let name):
                    return builtinImage(named: name)
                case .path(let path):
                    return NSImage(contentsOfFile: containerPath + path)
                }
            }
            #endif
        }
    }
}

extension CardCollectionManager.Collection {
    fileprivate init(builtin collection: BuiltinCardCollection) {
        self.init(
            name: NSLocalizedString(collection.name, bundle: .main, comment: ""),
            _rawName: collection.name,
            cards: collection.cards.map { .init(localizedName: $0.localizedName, file: .builtin($0.fileName)) }
        )
    }
}
