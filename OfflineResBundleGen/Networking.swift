//===---*- Greatdori! -*---------------------------------------------------===//
//
// Networking.swift
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

func retryUntilNonNil<T>(maxRetry: Int = 10, perform: () async -> T?) async -> T {
    for _ in 0..<maxRetry {
        if let result = await perform() {
            return result
        }
    }
    print("error: Failed to fetch: \(T.self)", to: &stderr)
    exit(EXIT_FAILURE)
}
