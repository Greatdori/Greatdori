//
//  BuiltinCardCollections.swift
//  Greatdori
//
//  Created by Mark Chan on 8/7/25.
//

import DoriKit
import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@_eagerMove
public struct BuiltinCardCollection: Codable {
    public var name: String
    public var cards: [BuiltinCard]
}
@_eagerMove
public struct BuiltinCard: Codable {
    public var name: DoriAPI.LocalizedData<String>
    public var imageData: Data
}

public let builtinCardCollectionNames = [
    "BUILTIN_CARD_COLLECTION_GREATDORI",
    "BUILTIN_CARD_COLLECTION_MYGO"
]

extension BuiltinCardCollection {
    @inline(never)
    @_optimize(size)
    public init?(named name: String) {
        let decoder = PropertyListDecoder()
        let data = NSDataAsset(name: name, bundle: #bundle)!.data
        if let collection = try? decoder.decode(BuiltinCardCollection.self, from: data) {
            self = collection
        } else {
            return nil
        }
    }
}

extension Array<BuiltinCardCollection> {
    @_optimize(size)
    public static func all() -> Self {
        let decoder = PropertyListDecoder()
        var result = Self()
        for name in builtinCardCollectionNames {
            let data = NSDataAsset(name: name, bundle: #bundle)!.data
            result.append(try! decoder.decode(BuiltinCardCollection.self, from: data))
        }
        return result
    }
}
