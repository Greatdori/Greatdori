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

public struct BuiltinCardCollection: Codable {
    public var name: String
    public var cards: [BuiltinCard]
}
public struct BuiltinCard: Codable {
    public var name: DoriAPI.LocalizedData<String>
    public var imageData: Data
}

extension Array<BuiltinCardCollection> {
    public static func all() -> Self {
        let names = [
            "GreatdoriCollection",
            "MyGOCollection"
        ]
        let decoder = PropertyListDecoder()
        var result = Self()
        for name in names {
            let data = NSDataAsset(name: name, bundle: #bundle)!.data
            result.append(try! decoder.decode(BuiltinCardCollection.self, from: data))
        }
        return result
    }
}
