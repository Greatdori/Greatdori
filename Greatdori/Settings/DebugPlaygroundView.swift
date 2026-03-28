//===---*- Greatdori! -*---------------------------------------------------===//
//
// DebugPlaygroundView.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.com/LICENSE.txt for license information
// See https://greatdori.com/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import DoriKit
import SwiftUI
import UserNotifications

struct DebugPlaygroundView: View {
    @State private var builder: DoriFrontend.TeamBuilder?
    @State private var charts: [DoriAPI.Songs.Chart]?
    @State private var allCards: [PreviewCard]?
    @State private var allAreaItems: [DoriAPI.Misc.AreaItem]?
    @State private var enableHardwareAcceleration = true
    @State private var timeUsed = 0.0
    @State private var result = ""
    var body: some View {
        VStack {
            if let builder, let charts, let allCards, let allAreaItems {
                Toggle(String("Hardware Acceleration"), isOn: $enableHardwareAcceleration)
                Button(String("Calculate")) {
                    builder.liveInformation = .freeLive
                    builder.songInformation = .init(
                        chart: charts,
                        difficultyLevel: 26,
                        accuracy: 1
                    )
                    builder.cards = allCards.map {
                        DoriFrontend.TeamBuilder.CardInformation(
                            card: $0,
                            level: $0.stat.maximumLevel!,
                            masterRank: 4,
                            skillLevel: 4,
                            viewedStoryCount: 2,
                            trained: $0.stat.keys.contains(.training)
                        )
                    }
                    builder.areaItems = allAreaItems.map {
                        .init(item: $0, level: $0.maxLevel[.jp]!)
                    }
                    builder.isHardwareAccelerationDisabled = !enableHardwareAcceleration
                    Task.detached {
                        let _time = CFAbsoluteTimeGetCurrent()
                        result = await builder.calculateMaximize(target: .score).map {
                            ($0.cards.map { $0.id }.sorted(), $0.areaItems.map { $0.item.id }, $0.targetValue)
                        }.description
                        await MainActor.run {
                            timeUsed = CFAbsoluteTimeGetCurrent() - _time
                        }
                    }
                }
                Text(result)
                Text(unsafe String(format: "%.4f s", timeUsed))
            } else {
                ProgressView()
                    .controlSize(.large)
                    .onAppear {
                        Task {
                            builder = await DoriFrontend.TeamBuilder()
                            charts = await DoriAPI.Songs.charts(of: 125, in: .expert)
                            allCards = await PreviewCard.all()
                            allAreaItems = await DoriAPI.Misc.areaItems()
                        }
                    }
            }
        }
        .padding()
    }
}

//extension DoriAPI.Songs.Song.MusicVideoMetadata: Sequence {}

func scheduleLocalNotification() {
    let content = UNMutableNotificationContent()
    content.title = "交差点、ふたつ星が笑って"
    content.body = "Is Starting Today"
    content.sound = .default
    content.interruptionLevel = .active

    // 5 秒后触发
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

    let request = UNNotificationRequest(
        identifier: "local_5s_notification",
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Schedule error: \(error)")
        }
    }
}
