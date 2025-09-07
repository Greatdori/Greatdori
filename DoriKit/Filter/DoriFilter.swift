//===---*- Greatdori! -*---------------------------------------------------===//
//
// DoriFilter.swift
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

public protocol DoriFilter: Equatable, Hashable {
    init()
    
    associatedtype Element
    func filter(_ elements: [Element]) -> [Element]
    
    associatedtype Key: DoriFilterKey
}
extension DoriFilter {
    public var isFiltered: Bool {
        self == .init()
    }
}

public protocol DoriFilterKey: RawRepresentable, CaseIterable, Comparable, Hashable {
    var localizedString: String { get }
}
extension DoriFilterKey where RawValue: Comparable {
    // Default implmentation for Comparable conformance
    
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
