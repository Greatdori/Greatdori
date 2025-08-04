//
//  RichContent.swift
//  Greatdori
//
//  Created by Mark Chan on 8/2/25.
//

import Foundation
internal import SwiftyJSON

public typealias RichContentGroup = [RichContent]

public enum RichContent: Sendable, Equatable, DoriCache.Cacheable {
    case br
    case text(String)
    case image([URL])
    case link(URL)
    case emoji(Emoji)
    
    internal init?(parsing json: JSON) {
        if let type = json["type"].string {
            self = switch type {
            case "br": .br
            case "text": .text(json["data"].stringValue)
            case "image": .image(json["objects"].compactMap { .init(string: $0.1.stringValue) })
            case "link": if let url = URL(string: json["data"].stringValue) { .link(url) } else { .br }
            case "emoji": .emoji(.init(_resourceName: json["data"].stringValue))
            default: .br
            }
            if type != "br" && self == .br {
                return nil
            }
        } else {
            return nil
        }
    }
}

extension RichContentGroup {
    internal init(parsing json: JSON) {
        self = []
        for (_, value) in json {
            if let content = RichContent(parsing: value) {
                self.append(content)
            }
        }
    }
}
