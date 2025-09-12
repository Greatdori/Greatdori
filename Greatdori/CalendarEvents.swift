//===---*- Greatdori! -*---------------------------------------------------===//
//
// CalendarEvents.swift
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

import DoriKit
import EventKit
import Foundation

func updateBirthdayCalendar() async throws {
    guard let characters = await DoriAPI.Character.allBirthday() else { return }
    
    let store = EKEventStore()
    
    if let id = UserDefaults.standard.string(forKey: "BirthdaysCalendarID"),
       let calendar = store.calendar(withIdentifier: id) {
        try? store.removeCalendar(calendar, commit: false)
    }
    
    let calendar = EKCalendar(for: .event, eventStore: store)
    calendar.title = "GBP Birthdays"
    UserDefaults.standard.set(calendar.calendarIdentifier, forKey: "BirthdaysCalendarID")
    try store.saveCalendar(calendar, commit: false)
    
    var birthdaySourceCalendar = Calendar(identifier: .gregorian)
    birthdaySourceCalendar.timeZone = .init(identifier: "Asia/Tokyo")!
    let userCalendar = Calendar.current
    
    for character in characters {
        let birthdayComponents = birthdaySourceCalendar.dateComponents([.month, .day], from: character.birthday)
        
        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.isAllDay = true
        event.startDate = userCalendar.date(
            from: .init(
                year: 2015,
                month: birthdayComponents.month,
                day: birthdayComponents.day,
                hour: 0,
                minute: 0,
                second: 0
            )
        )!
        event.endDate = userCalendar.date(
            from: .init(
                year: 2015,
                month: birthdayComponents.month,
                day: birthdayComponents.day,
                hour: 23,
                minute: 59,
                second: 59
            )
        )!
        event.recurrenceRules = [.init(
            recurrenceWith: .yearly,
            interval: 1,
            daysOfTheWeek: nil,
            daysOfTheMonth: nil,
            monthsOfTheYear: [birthdayComponents.month! as NSNumber],
            weeksOfTheYear: nil,
            daysOfTheYear: [birthdayComponents.day! as NSNumber],
            setPositions: nil,
            end: nil
        )]
        try store.save(event, span: .futureEvents, commit: false)
    }
    
    try store.commit()
}
