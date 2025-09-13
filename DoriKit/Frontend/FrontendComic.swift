//===---*- Greatdori! -*---------------------------------------------------===//
//
// FrontendComic.swift
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

extension DoriFrontend {
    /// Request and fetch data about comics in Bandori.
    public enum Comic {
        /// List all comics.
        ///
        /// - Returns: All comics, nil if failed to fetch.
        public static func list() async -> [Comic]? {
            guard let comics = await DoriAPI.Comic.all() else { return nil }
            return comics
        }
    }
}

extension DoriFrontend.Comic {
    public typealias Comic = DoriAPI.Comic.Comic
}

extension DoriAPI.Comic.Comic {
    @frozen
    public enum ComicType: String, CaseIterable, Hashable, Codable {
        case singleFrame
        case fourFrame
        
        @inline(never)
        public var localizedString: String {
            NSLocalizedString(rawValue, bundle: #bundle, comment: "")
        }
    }
    
    @inlinable
    public var type: ComicType? {
        self.id > 0 && self.id <= 1000 ? .singleFrame : self.id > 1000 ? .fourFrame : nil
    }
}
