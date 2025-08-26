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

public func withOfflineAsset<Result>(
    _ behavior: OfflineAssetBehavior = .enableIfAvailable,
    _ body: () throws -> Result
) rethrows -> Result {
    try DoriOfflineAsset.$localBehavior.withValue(behavior, operation: body)
}

public func withOfflineAsset<Result>(
    _ behavior: OfflineAssetBehavior = .enableIfAvailable,
    isolation: isolated (any Actor)? = #isolation,
    _ body: () async throws -> Result
) async rethrows -> Result {
    try await DoriOfflineAsset.$localBehavior.withValue(behavior, operation: body, isolation: isolation)
}

@frozen
public enum OfflineAssetBehavior: Sendable {
    case disabled
    case enableIfAvailable
    case enabled
}

extension DoriOfflineAsset {
    @TaskLocal
    internal static var localBehavior: OfflineAssetBehavior = .disabled
}

#endif
