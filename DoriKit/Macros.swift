//===---*- Greatdori! -*---------------------------------------------------===//
//
// Macros.swift
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

#if canImport(DoriAssetShims)

@attached(body)
public macro OfflineAssetURL(_: OfflineAssetBehavior = .enableIfAvailable) = #externalMacro(module: "DoriKitMacros", type: "OfflineAssetURLMacro")

#endif
