//===---*- Greatdori! -*---------------------------------------------------===//
//
// OfflineAssetDispatch.swift
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

#if canImport(DoriAssetShims)

/// Configures requests occuring in closure to match the provided offline asset behavior.
///
/// - Parameters:
///   - behavior: The offline asset behavior in `body`,
///       see ``OfflineAssetBehavior`` for more details.
///   - body: A closure with provided offline asset behavior.
/// - Returns: Result of provided closure.
///
/// This function let requests in provided closure match the `behavior`.
/// You use this function to allow downloaded local assets work with DoriKit.
///
/// Simply wrap an expression that requests data to configure its offline asset behavior:
/// ```swift
/// let myFavoriteCharacter = await withOfflineAsset {
///     await DoriAPI.Character.Character(id: 39)
/// }
/// ```
///
/// You can also wrap multiple expressions in a single closure:
/// ```swift
/// await withOfflineAsset {
///     let myFavoriteCharacter = await DoriAPI.Character.Character(id: 39)
///     let myFavoriteCard = await DoriAPI.Card.Card(id: 2125)
/// }
/// ```
///
/// Use this function with ``DoriCache/withCache(id:trait:invocation:)``
/// to let them work together:
/// ```swift
/// DoriCache.withCache(id: "CacheID") {
///     await withOfflineAsset {
///         await DoriAPI.Card.Card(id: 2125)
///     }
/// }.onUpdate {
///     let myFavoriteCard = $0
/// }
/// ```
///
/// This function can be put outside of the `invocation` closure
/// of ``DoriCache/withCache(id:trait:invocation:)``
/// to make it easier to request and cache multiple items:
/// ```swift
/// withOfflineAsset {
///     DoriCache.withCache(id: "CacheID") {
///         await DoriAPI.Card.Card(id: 2125)
///     }.onUpdate {
///         let myFavoriteCard = $0
///     }
///     DoriCache.withCache(id: "AnotherCacheID") {
///         await DoriAPI.Costume.Costume(id: 2120)
///     }.onUpdate {
///         let coolSoyo = $0
///     }
/// }
/// ```
///
/// If a new task is created in `body`, it inherits the behavior:
/// ```swift
/// await withOfflineAsset(.enabled) {
///     Task {
///         // Configuration is `.enabled`
///         let efficiency = await DoriAPI.Song.Song(id: 325)
///     }
///     // Configuration is `.enabled`
///     let tanebi = await DoriAPI.Song.Song(id: 684)
/// }
/// ```
///
/// - IMPORTANT:
///     If a **detached** task is created in `body`, it **drops** the behavior.
///     ```swift
///     await withOfflineAsset(.enabled) {
///         Task.detached {
///             // Configuration is default (`.disabled`)
///             let efficiency = await DoriAPI.Song.Song(id: 325)
///         }
///         // Configuration is `.enabled`
///         let tanebi = await DoriAPI.Song.Song(id: 684)
///     }
///     ```
///
/// Resource accesses in `body` also respects the configuration:
/// ```swift
/// await withOfflineAsset {
///     if let itsMyGO = await DoriAPI.Event.Event(id: 235) {
///         let imageURL = itsMyGO.bannerImageURL
///         // imageURL refers to a local file if available.
///     }
/// }
/// ```
///
/// - SeeAlso:
///     Use ``Foundation/URL/withOfflineAsset(_:)``
///     to set offline asset behavior for URL inline.
public func withOfflineAsset<Result>(
    _ behavior: OfflineAssetBehavior = .enableIfAvailable,
    _ body: () throws -> Result
) rethrows -> Result {
    try DoriOfflineAsset.$localBehavior.withValue(behavior, operation: body)
}

/// Configures requests occuring in closure to match the provided offline asset behavior.
///
/// - Parameters:
///   - behavior: The offline asset behavior in `body`,
///       see ``OfflineAssetBehavior`` for more details.
///   - body: A closure with provided offline asset behavior.
/// - Returns: Result of provided closure.
///
/// This function let requests in provided closure match the `behavior`.
/// You use this function to allow downloaded local assets work with DoriKit.
///
/// Simply wrap an expression that requests data to configure its offline asset behavior:
/// ```swift
/// let myFavoriteCharacter = await withOfflineAsset {
///     await DoriAPI.Character.Character(id: 39)
/// }
/// ```
///
/// You can also wrap multiple expressions in a single closure:
/// ```swift
/// await withOfflineAsset {
///     let myFavoriteCharacter = await DoriAPI.Character.Character(id: 39)
///     let myFavoriteCard = await DoriAPI.Card.Card(id: 2125)
/// }
/// ```
///
/// Use this function with ``DoriCache/withCache(id:trait:invocation:)``
/// to let them work together:
/// ```swift
/// DoriCache.withCache(id: "CacheID") {
///     await withOfflineAsset {
///         await DoriAPI.Card.Card(id: 2125)
///     }
/// }.onUpdate {
///     let myFavoriteCard = $0
/// }
/// ```
///
/// This function can be put outside of the `invocation` closure
/// of ``DoriCache/withCache(id:trait:invocation:)``
/// to make it easier to request and cache multiple items:
/// ```swift
/// withOfflineAsset {
///     DoriCache.withCache(id: "CacheID") {
///         await DoriAPI.Card.Card(id: 2125)
///     }.onUpdate {
///         let myFavoriteCard = $0
///     }
///     DoriCache.withCache(id: "AnotherCacheID") {
///         await DoriAPI.Costume.Costume(id: 2120)
///     }.onUpdate {
///         let coolSoyo = $0
///     }
/// }
/// ```
///
/// If a new task is created in `body`, it inherits the behavior:
/// ```swift
/// await withOfflineAsset(.enabled) {
///     Task {
///         // Configuration is `.enabled`
///         let efficiency = await DoriAPI.Song.Song(id: 325)
///     }
///     // Configuration is `.enabled`
///     let tanebi = await DoriAPI.Song.Song(id: 684)
/// }
/// ```
///
/// - IMPORTANT:
///     If a **detached** task is created in `body`, it **drops** the behavior.
///     ```swift
///     await withOfflineAsset(.enabled) {
///         Task.detached {
///             // Configuration is default (`.disabled`)
///             let efficiency = await DoriAPI.Song.Song(id: 325)
///         }
///         // Configuration is `.enabled`
///         let tanebi = await DoriAPI.Song.Song(id: 684)
///     }
///     ```
///
/// Resource accesses in `body` also respects the configuration:
/// ```swift
/// await withOfflineAsset {
///     if let itsMyGO = await DoriAPI.Event.Event(id: 235) {
///         let imageURL = itsMyGO.bannerImageURL
///         // imageURL refers to a local file if available.
///     }
/// }
/// ```
///
/// - SeeAlso:
///     Use ``Foundation/URL/withOfflineAsset(_:)``
///     to set offline asset behavior for URL inline.
public func withOfflineAsset<Result>(
    _ behavior: OfflineAssetBehavior = .enableIfAvailable,
    isolation: isolated (any Actor)? = #isolation,
    _ body: () async throws -> Result
) async rethrows -> Result {
    try await DoriOfflineAsset.$localBehavior.withValue(behavior, operation: body, isolation: isolation)
}

/// Behavior of using offline asset in DoriKit.
///
/// The default behavior is `disabled`, unless you use ``withOfflineAsset(_:_:)``
/// or ``Foundation/URL/withOfflineAsset(_:)`` to change it.
///
/// - IMPORTANT:
///     ``enabled`` implies "**never** use online asset",
///     if requested asset isn't available in local, you'll get nil.
///     Use ``enableIfAvailable`` to make it flexible.
@frozen
public enum OfflineAssetBehavior: Sendable {
    /// Never use offline asset.
    case disabled
    /// Use offline asset if available.
    case enableIfAvailable
    /// Always use offline asset.
    ///
    /// - IMPORTANT:
    ///     `enabled` implies "**never** use online asset",
    ///     if requested asset isn't available in local, you'll get nil.
    ///     Use ``enableIfAvailable`` to make it flexible.
    case enabled
}

extension DoriOfflineAsset {
    @TaskLocal
    internal static var localBehavior: OfflineAssetBehavior = .disabled
}

#endif
