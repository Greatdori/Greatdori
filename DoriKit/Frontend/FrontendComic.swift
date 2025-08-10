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
    public class Comic {
        private init() {}
    }
}

extension DoriFrontend.Comic {
    public typealias Comic = DoriAPI.Comic.Comic
}

extension DoriAPI.Comic.Comic {
    @frozen
    public enum ComicType: Int {
        case singleFrame
        case fourFrame
    }
    
    @inlinable
    public var type: ComicType? {
        self.id > 0 && self.id <= 1000 ? .singleFrame : self.id > 1000 && self.id <= 2000 ? .fourFrame : nil
    }
}
