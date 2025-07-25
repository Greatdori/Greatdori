//
//  InMemoryCaches.swift
//  Greatdori
//
//  Created by Mark Chan on 7/25/25.
//

import Foundation

internal class InMemoryCache {
    private init() {}
    
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
