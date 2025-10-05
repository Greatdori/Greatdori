//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventTracker.swift
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

import Charts
import SwiftUI
import DoriKit
import SDWebImageSwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct EventTrackerView: View {
    @State private var locale: DoriLocale = DoriLocale.primaryLocale
    @State private var isEventSelectorPresented = false
    @State private var eventIDInput = ""
    @State private var eventList: [PreviewEvent]?
    @State private var eventListIsAvailabile = true
    @State private var selectedEvent: PreviewEvent?
    @State private var selectedTier = 1000
    @State private var trackerData: TrackerData?
    @State private var trackerIsAvailable = true
    var body: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                VStack {
                    CustomGroupBox(cornerRadius: 20) {
                        LazyVStack {
                            Group {
                                ListItemView(title: {
                                    Text("Tools.event-tracker.event")
                                        .bold()
                                }, value: {
                                    Button("Tools.event-tracker.event.select") {
                                        isEventSelectorPresented = true
                                    }
                                })
                                .window(isPresented: $isEventSelectorPresented) {
                                    EventSelector(selection: .init { [selectedEvent].compactMap { $0 } } set: { selectedEvent = $0.first })
                                        .selectorDisablesMultipleSelection()
                                        #if os(macOS)
                                        .introspect(.window, on: .macOS(.v14...)) { window in
                                            window.standardWindowButton(.zoomButton)?.isEnabled = false
                                            window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
                                            window.level = .floating
                                        }
                                        #endif
                                }
                                .onChange(of: selectedEvent) {
                                    isEventSelectorPresented = false
                                    Task {
                                        await updateTrackerData()
                                    }
                                }
                                Divider()
                            }
                            
                            Group {
                                ListItemView(title: {
                                    Text("Tools.event-tracker.locale")
                                        .bold()
                                }, value: {
                                    Picker(selection: $locale, content: {
                                        ForEach(DoriLocale.allCases, id: \.self) { item in
                                            Text(item.rawValue.uppercased())
                                                .tag(item)
                                        }
                                    }, label: {EmptyView()})
                                    .labelsHidden()
                                })
                                Divider()
                            }
                            
                            ListItemView(title: {
                                Text("Tools.event-tracker.tier")
                                    .bold()
                            }, value: {
                                Picker(selection: $selectedTier) {
                                    ForEach([10, 20, 30, 40, 50, 100, 200, 300, 400, 500, 1000, 2000, 3000, 4000, 5000, 10000, 20000, 30000], id: \.self) { t in
                                        Text(verbatim: "T\(t)").tag(t)
                                    }
                                } label: {
                                    EmptyView()
                                }
                                .labelsHidden()
                                .onChange(of: selectedTier) {
                                    Task {
                                        await updateTrackerData()
                                    }
                                }
                                
                            })
                        }
                    }
                    if let selectedEvent, let trackerData {
                        CustomGroupBox(cornerRadius: 20) {
                            LazyVStack {
                                switch trackerData {
                                case .tracker(let trackerData):
                                    if let startDate = selectedEvent.startAt.forPreferredLocale(),
                                       let endDate = selectedEvent.endAt.forPreferredLocale() {
                                        ListItemView {
                                            Text("Tools.event-tracker.status")
                                                .bold()
                                        } value: {
                                            VStack(alignment: .trailing) {
                                                if startDate > .now {
                                                    Text("Tools.event-tracker.status.not-started")
                                                } else if endDate > .now {
                                                    Text("Tools.event-tracker.stauts.completed.\(Int((Date.now.timeIntervalSince1970 - startDate.timeIntervalSince1970) / (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) * 100))")
                                                    Text("Tools.event-tracker.stauts.completed.end-in.\(Text(endDate, style: .relative))")
                                                } else {
                                                    Text("Tools.event-tracker.stauts.ended")
                                                }
                                            }
                                        }
                                        Divider()
                                    }
                                    if let latestCutoff = trackerData.cutoffs.last?.ep {
                                        ListItemView {
                                            Text("Tools.event-tracker.latest-cutoff")
                                                .bold()
                                        } value: {
                                            Text(String(latestCutoff))
                                        }
                                        Divider()
                                    }
                                    if let latestPrediction = trackerData.predictions.last?.ep {
                                        ListItemView {
                                            Text("Tools.event-tracker.latest-prediction")
                                                .bold()
                                        } value: {
                                            Text(String(latestPrediction))
                                        }
                                        Divider()
                                    }
                                    if let latestUpdateTime = trackerData.cutoffs.last?.time {
                                        ListItemView {
                                            Text("Tools.event-tracker.last-updated")
                                                .bold()
                                        } value: {
                                            Text("Tools.event-tracker.last-updated.ago.\(Text(latestUpdateTime, style: .relative))")
                                        }
                                    }
                                    VStack(alignment: .leading) {
                                        Chart {
                                            ForEach(trackerData.cutoffs, id: \.time) { cutoff in
                                                if let ep = cutoff.ep {
                                                    AreaMark(
                                                        x: .value("Tools.event-tracker.date", cutoff.time),
                                                        y: .value("Tools.event-tracker.ep", ep)
                                                    )
                                                    .foregroundStyle(.blue.opacity(0.7))
                                                    LineMark(
                                                        x: .value("Tools.event-tracker.date", cutoff.time),
                                                        y: .value("Tools.event-tracker.ep", ep)
                                                    )
                                                    .foregroundStyle(by: .value("Tools.event-tracker.type", String(localized: "Tools.event-tracker.current-cutoff")))
                                                }
                                            }
                                            ForEach(trackerData.predictions, id: \.time) { prediction in
                                                if let ep = prediction.ep {
                                                    LineMark(
                                                        x: .value("Tools.event-tracker.date", prediction.time),
                                                        y: .value("Tools.event-tracker.ep", ep)
                                                    )
                                                    .lineStyle(.init(lineWidth: 2, dash: [5, 3]))
                                                    .foregroundStyle(by: .value("Tools.event-tracker.type", String(localized: "Tools.event-tracker.predicted-cutoff")))
                                                }
                                            }
                                        }
                                        .chartForegroundStyleScale([
                                            String(localized: "Tools.event-tracker.current-cutoff"): .blue,
                                            String(localized: "Tools.event-tracker.predicted-cutoff"): .blue
                                        ])
                                        .chartLegend(.hidden)
                                        .chartXAxis {
                                            AxisMarks(values: .stride(by: .day)) { value in
                                                AxisGridLine()
                                                AxisTick()
                                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                            }
                                        }
                                        .chartYAxis {
                                            AxisMarks(position: .leading, values: .stride(by: stride(of: trackerData))) { value in
                                                AxisGridLine()
                                                AxisTick()
                                                AxisValueLabel {
                                                    if let number = value.as(Double.self) {
                                                        Text(formatNumber(number))
                                                    }
                                                }
                                            }
                                        }
                                        .containerRelativeFrame(.vertical) { length, _ in
                                            length / 5 * 3
                                        }
                                        HStack {
                                            Rectangle()
                                                .fill(Color.blue.opacity(0.7))
                                                .strokeBorder(Color.blue, lineWidth: 2)
                                                .frame(width: 30, height: 15)
                                            Text("Tools.event-tracker.current-cutoff")
                                            Rectangle()
                                                .stroke(style: .init(lineWidth: 2, dash: [5, 3]))
                                                .fill(Color.blue)
                                                .frame(width: 30, height: 15)
                                            Text("Tools.event-tracker.predicted-cutoff")
                                        }
                                    }
                                case .top(let topData):
                                    if let startDate = selectedEvent.startAt.forPreferredLocale(),
                                       let endDate = selectedEvent.endAt.forPreferredLocale() {
                                        ListItemView {
                                            Text("Tools.event-tracker.status")
                                                .bold()
                                        } value: {
                                            VStack(alignment: .trailing) {
                                                if startDate > .now {
                                                    Text("Tools.event-tracker.status.not-started")
                                                } else if endDate > .now {
                                                    Text("Tools.event-tracker.stauts.completed.\(Int((Date.now.timeIntervalSince1970 - startDate.timeIntervalSince1970) / (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970) * 100))")
                                                    Text("Tools.event-tracker.stauts.completed.end-in.\(Text(endDate, style: .relative))")
                                                } else {
                                                    Text("Tools.event-tracker.stauts.ended")
                                                }
                                            }
                                        }
                                        Divider()
                                    }
                                    if let latestUpdateTime = topData.last?.points.last?.time {
                                        ListItemView {
                                            Text("Tools.event-tracker.last-updated")
                                                .bold()
                                        } value: {
                                            Text("Tools.event-tracker.last-updated.ago.\(Text(latestUpdateTime, style: .relative))")
                                        }
                                    }
                                    Chart {
                                        ForEach(topData, id: \.uid) { data in
                                            ForEach(data.points, id: \.time) { point in
                                                LineMark(
                                                    x: .value("Tools.event-tracker.date", point.time),
                                                    y: .value("Tools.event-tracker.point", point.value)
                                                )
                                                .foregroundStyle(by: .value("Tools.event-tracker.name", data.name))
                                            }
                                        }
                                    }
                                    .chartXAxis {
                                        AxisMarks(values: .stride(by: .day)) { value in
                                            AxisGridLine()
                                            AxisTick()
                                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks(position: .leading, values: .stride(by: stride(of: topData))) { value in
                                            AxisGridLine()
                                            AxisTick()
                                            AxisValueLabel {
                                                if let number = value.as(Double.self) {
                                                    Text(formatNumber(number))
                                                }
                                            }
                                        }
                                    }
                                    .containerRelativeFrame(.vertical) { length, _ in
                                        length / 5 * 4
                                    }
                                    HStack {
                                        VStack(alignment: .leading) {
                                            ForEach(Array(topData.prefix(10).enumerated()), id: \.element.uid) { index, data in
                                                HStack {
                                                    if 1...3 ~= index + 1 {
                                                        Image("tier_\(DoriAPI.preferredLocale.rawValue)_\(index + 1)")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 40)
                                                    } else {
                                                        Text(verbatim: "#\(index + 1)")
                                                            .font(.headline)
                                                            .frame(width: 40)
                                                    }
                                                    CardPreviewImage(data.card, showTrainedVersion: data.trained)
                                                    VStack(alignment: .leading) {
                                                        Text(data.name)
                                                            .font(.title3)
                                                        Text(data.introduction)
                                                            .foregroundStyle(.gray)
                                                    }
                                                    Spacer()
                                                    if let score = data.points.last?.value {
                                                        Text("Tools.event-tracker.score.\(score)")
                                                    }
                                                }
                                                Divider()
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                Spacer(minLength: 0)
            }
        }
        .scrollDisablesMultilingualTextPopover()
        .navigationTitle("Tools.event-trackter")
        .task {
            await getEvents()
        }
    }
    
    func getEvents() async {
        eventListIsAvailabile = true
        withDoriCache(id: "EventList") {
            await PreviewEvent.all()
        }.onUpdate {
            if let events = $0 {
                self.eventList = events
            } else {
                eventListIsAvailabile = false
            }
        }
    }
    func updateTrackerData() async {
        if let event = selectedEvent {
            trackerData = nil
            trackerIsAvailable = true
            if selectedTier > 10 {
                if let trackerData = await DoriFrontend.Event.trackerData(for: event, in: locale, tier: selectedTier, smooth: true) {
                    self.trackerData = .tracker(trackerData)
                } else {
                    trackerIsAvailable = false
                }
            } else {
                if let topData = await DoriFrontend.Event.topData(of: event.id, in: locale) {
                    self.trackerData = .top(topData)
                } else {
                    trackerIsAvailable = false
                }
            }
        }
    }
    
    func stride(of trackerData: DoriFrontend.Event.TrackerData) -> Double {
        let cutoffs = trackerData.cutoffs
        let predictions = trackerData.predictions
        var maxValue = 0.0
        for cutoff in cutoffs where Double(cutoff.ep ?? 0) > maxValue {
            maxValue = Double(cutoff.ep ?? 0)
        }
        for prediction in predictions where Double(prediction.ep ?? 0) > maxValue {
            maxValue = Double(prediction.ep ?? 0)
        }
        let count = String(Int(maxValue)).count
        let result = "1" + String(repeating: "0", count: count - 1)
        return Double(result)!
    }
    func stride(of topData: [DoriFrontend.Event.TopData]) -> Double {
        var maxValue = 0.0
        for data in topData {
            for point in data.points where Double(point.value) > maxValue {
                maxValue = Double(point.value)
            }
        }
        let count = String(Int(maxValue)).count
        let result = "1" + String(repeating: "0", count: count - 1)
        return Double(result)!
    }
}

private func formatNumber(_ number: Double) -> String {
    switch number {
    case 1_000_000_000...:
        return unsafe String(format: "%.0fB", number / 1_000_000_000)
    case 1_000_000...:
        return unsafe String(format: "%.0fM", number / 1_000_000)
    case 1_000...:
        return unsafe String(format: "%.0fK", number / 1_000)
    default:
        return unsafe String(format: "%.0f", number)
    }
}

private enum TrackerData {
    case tracker(DoriFrontend.Event.TrackerData)
    case top([DoriFrontend.Event.TopData])
}
