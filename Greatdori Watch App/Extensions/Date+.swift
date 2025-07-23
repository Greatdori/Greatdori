//
//  Date+.swift
//  Greatdori
//
//  Created by Mark Chan on 7/23/25.
//

import Foundation

extension Date {
    private var calendar: Calendar {
        Calendar.autoupdatingCurrent
    }
    
    var components: DateComponents {
        calendar.dateComponents(
            [
                .era,
                .year,
                .month,
                .day,
                .hour,
                .minute,
                .second,
                .weekday,
                .weekdayOrdinal,
                .quarter,
                .weekOfMonth,
                .weekOfYear,
                .yearForWeekOfYear,
                .nanosecond,
                .calendar,
                .timeZone
            ],
            from: self
        )
    }
    func components(in timezone: TimeZone) -> DateComponents {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar.dateComponents(
            [
                .era,
                .year,
                .month,
                .day,
                .hour,
                .minute,
                .second,
                .weekday,
                .weekdayOrdinal,
                .quarter,
                .weekOfMonth,
                .weekOfYear,
                .yearForWeekOfYear,
                .nanosecond,
                .calendar,
                .timeZone
            ],
            from: self
        )
    }
}
