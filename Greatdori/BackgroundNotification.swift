//===---*- Greatdori! -*---------------------------------------------------===//
//
// BackgroundNotification.swift
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
import Foundation
import UserNotifications

// FIXME: BackgroundTasks API is not available on macOS,
// FIXME: we have to do some other things for macOS.
#if os(iOS)
import UIKit
import BackgroundTasks
#endif

#if os(iOS)

func _scheduleNewsNotificationRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.memz233.Greatdori.background.news-notification")
    request.earliestBeginDate = .init(timeIntervalSinceNow: 60 * 60) // hourly
    try? BGTaskScheduler.shared.submit(request)
}

func _handleNewsNotificationRefresh(task: BGAppRefreshTask) {
    // Schedule next refresh
    _scheduleNewsNotificationRefresh()
    
    let operation = Task {
        await handleNewsNotification()
        task.setTaskCompleted(success: true)
    }
    task.expirationHandler = {
        operation.cancel()
        task.setTaskCompleted(success: false)
    }
}

extension BGAppRefreshTask: @unchecked @retroactive Sendable {}

#endif

private func handleNewsNotification() async {
    guard await isNotificationAuthorized() else { return }
    
    if let newsList = await DoriFrontend.News.list() {
        if let _cachedNewsList = try? Data(contentsOf: URL(filePath: NSHomeDirectory() + "/Documents/NotifNewsList.plist")),
           let cachedNewsList = try? PropertyListDecoder().decode(type(of: newsList), from: _cachedNewsList),
           let firstNews = cachedNewsList.first {
            // A news list fetched previously is available for diff
            let newsDiff = newsList.prefix { item in
                item != firstNews
            }
            for news in newsDiff {
                // Send notification for each news
                let content = UNMutableNotificationContent()
                content.title = news.subject
                content.body = switch news.timeMark {
                case .willStartAfter(let interval):
                    String(localized: "News.time-mark.will-start-after.\(interval)")
                case .willEndAfter(let interval):
                    String(localized: "News.time-mark.will-end-after.\(interval)")
                case .willEndToday:
                    String(localized: "News.time-mark.will-end-today")
                case .hasEnded:
                    String(localized: "News.time-mark.has-ended")
                case .hasPublished:
                    String(localized: "News.time-mark.has-published")
                case .willStartToday:
                    String(localized: "News.time-mark.will-start-today")
                @unknown default: ""
                }
                content.sound = .default
                
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                Task {
                    try? await UNUserNotificationCenter.current().add(request)
                }
            }
        } else {
            // News list for diff is not available, we create it for
            // notification next time
            let encoder = PropertyListEncoder()
            try? encoder.encode(newsList).write(to: URL(filePath: NSHomeDirectory() + "/Documents/NotifNewsList.plist"))
        }
    }
}

// MARK: - Notification helper functions

private func isNotificationAuthorized() async -> Bool {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    return settings.authorizationStatus == .authorized
}
