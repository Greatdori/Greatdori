//
//  PagedContent.swift
//  Greatdori
//
//  Created by Mark Chan on 8/3/25.
//

import Foundation

public protocol PagedContent {
    associatedtype Content
    
    var total: Int { get }
    var currentOffset: Int { get }
    var content: [Content] { get }
}

extension PagedContent {
    @inlinable
    public var pageCapacity: Int {
        content.count
    }
    @inlinable
    public var hasMore: Bool {
        currentOffset + pageCapacity < total
    }
    @inlinable
    public var nextOffset: Int {
        currentOffset + pageCapacity
    }
    @inlinable
    public var pageCount: Int {
        Int(ceil(Double(total) / Double(pageCapacity)))
    }
    @inlinable
    public var currentPage: Int {
        currentOffset / pageCount + 1
    }
}
