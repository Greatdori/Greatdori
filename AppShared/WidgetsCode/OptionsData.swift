//
//  OptionsData.swift
//  Greatdori
//
//  Created by Mark Chan on 8/5/25.
//

import DoriKit
import Foundation

struct CardWidgetDescriptor: Codable {
    var cardID: Int
    var trained: Bool
    var localizedName: String
    var imageURL: URL
}
