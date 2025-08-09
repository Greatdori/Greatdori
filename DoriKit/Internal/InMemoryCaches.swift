//===---*- Greatdori! -*---------------------------------------------------===//
//
// InMemoryCaches.swift
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

internal class InMemoryCache {
    private init() {}
    
    nonisolated(unsafe)
    internal static var allSkills = [DoriAPI.Skill.Skill]()
    
    internal static func updateAll() async {
        let groupResult = await withTasksResult {
            await DoriAPI.Skill.all()
        }
        if let skills = groupResult {
            Self.allSkills = skills
        }
    }
}
