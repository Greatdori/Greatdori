//
//  FrontendTests.swift
//  Greatdori
//
//  Created by Mark Chan on 7/27/25.
//

import Testing
import Foundation
@testable import DoriKit

private struct FrontendTests {
    init() {
        // We set _preferredLocale directly to prevent it being stored.
        DoriAPI._preferredLocale = .init(rawValue: ProcessInfo.processInfo.environment["DORIKIT_TESTING_PREFERRED_LOCALE"]!)!
    }
    
    @Test
    func testCharacter() async throws {
        let allBirthdays = try #require(await DoriAPI.Character.allBirthday())
        let sortedBirthdays = allBirthdays.sorted(by: { $0.birthday < $1.birthday })
        for (index, birthday) in sortedBirthdays.enumerated() {
            let dateAfter = Date(timeIntervalSince1970: birthday.birthday.timeIntervalSince1970 + 1)
            let recentBirthdays = try #require(await DoriFrontend.Character.recentBirthdayCharacters(aroundDate: dateAfter))
            #expect(recentBirthdays.contains { $0.id == birthday.id }, "\(birthday)|||||\(recentBirthdays)")
            if _fastPath(index + 1 < sortedBirthdays.count) {
                #expect(recentBirthdays.contains { $0.id == sortedBirthdays[index + 1].id }, "\(birthday)|||||\(recentBirthdays)")
            }
        }
    }
}
