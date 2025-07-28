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
            let birthdaysInExactBirthday = try #require(await DoriFrontend.Character.recentBirthdayCharacters(aroundDate: birthday.birthday))
            let birthdaysInExactBirthdayFromAll = allBirthdays.filter {
                $0.birthday.componentsRewritten(year: 0, hour: 0, minute: 0, second: 0)
                == birthday.birthday.componentsRewritten(year: 0, hour: 0, minute: 0, second: 0)
            }
            #expect(Set(birthdaysInExactBirthday.map { $0.id }) == Set(birthdaysInExactBirthdayFromAll.map { $0.id }), .init(birthdaysInExactBirthday, birthdaysInExactBirthdayFromAll))
            
            let dateAfter = Date(timeIntervalSince1970: birthday.birthday.timeIntervalSince1970 + 60 * 60 * 24)
            var tokyoCalendar = Calendar(identifier: .gregorian)
            tokyoCalendar.timeZone = .init(identifier: "Asia/Tokyo")!
            if allBirthdays.contains(where: {
                $0.birthday.componentsRewritten(calendar: tokyoCalendar, year: 0, hour: 0, minute: 0, second: 0)
                == dateAfter.componentsRewritten(calendar: tokyoCalendar, year: 0, hour: 0, minute: 0, second: 0)
            }) {
                continue
            }
            let recentBirthdays = try #require(await DoriFrontend.Character.recentBirthdayCharacters(aroundDate: dateAfter))
            #expect(recentBirthdays.contains { $0.id == birthday.id }, .init(birthday, recentBirthdays))
            if _fastPath(index + 1 < sortedBirthdays.count) {
                #expect(recentBirthdays.contains { $0.id == sortedBirthdays[index + 1].id }, "\(birthday)|||||\(recentBirthdays)")
            }
        }
    }
}
