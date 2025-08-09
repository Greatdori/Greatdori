//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongMetaView.swift
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

import SwiftUI
import DoriKit

struct SongMetaView: View {
    @State var meta: [DoriFrontend.Song.SongWithMeta]?
    @State var allSkills: [DoriAPI.Skill.Skill]?
    @State var selectedSkill: DoriAPI.Skill.Skill?
    @State var sort = DoriFrontend.Song.MetaSort.efficiency
    @State var locale = DoriAPI.preferredLocale
    @State var skillLevel = 4
    @State var perfectRate = 100.0
    @State var downtime = 30.0
    @State var fever = true
    @State var availability = true
    var body: some View {
        List {
            if let meta {
                Section {
                    ForEach(Array(meta.enumerated()), id: \.element.self) { (index, meta) in
                        NavigationLink(destination: { SongMetaDetailView(meta: meta) }) {
                            HStack {
                                Text(verbatim: "#\(index + 1)")
                                    .bold()
                                Text(meta.song.musicTitle.forPreferredLocale() ?? "")
                                Spacer(minLength: 0)
                                Text(String(meta.meta.playLevel))
                                    .foregroundStyle(.black)
                                    .frame(width: 20, height: 20)
                                    .background {
                                        Circle()
                                            .fill(meta.meta.difficulty.color)
                                    }
                            }
                        }
                    }
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入歌曲 Meta 时出错", systemImage: "music.pages.fill", retryHandler: getMeta)
                }
            }
        }
        .navigationTitle("歌曲 Meta")
        .task {
            await getMeta()
        }
    }
    
    func getMeta() async {
        availability = true
        DoriCache.withCache(id: "SkillList") {
            await DoriAPI.Skill.all()
        }.onUpdate {
            if let skills = $0 {
                self.allSkills = skills
                if selectedSkill == nil {
                    selectedSkill = skills.first
                }
                if let selectedSkill {
                    Task {
                        await _getMeta(skill: selectedSkill)
                    }
                }
            } else {
                availability = false
            }
        }
    }
    func _getMeta(skill: DoriAPI.Skill.Skill) async {
        availability = true
        DoriCache.withCache(id: "MetaList_\(sort.rawValue)") {
            await DoriFrontend.Song.allMeta(
                with: skill,
                in: locale,
                skillLevel: skillLevel,
                perfectRate: perfectRate,
                downtime: downtime,
                fever: fever,
                sort: sort
            )
        }.onUpdate {
            if let meta = $0 {
                self.meta = meta
            } else {
                availability = false
            }
        }
    }
}

private struct SongMetaDetailView: View {
    var meta: DoriFrontend.Song.SongWithMeta
    var body: some View {
        List {
            Section {
                NavigationLink(destination: { SongDetailView(id: meta.song.id) }) {
                    SongCardView(meta.song)
                }
            }
            Section {
                VStack(alignment: .leading) {
                    Text("时长")
                        .font(.system(size: 16, weight: .medium))
                    Text({
                        let minutes = Int(meta.meta.length) / 60
                        let remainingSeconds = Int(meta.meta.length) % 60
                        let tenths = Int((meta.meta.length - floor(meta.meta.length)) * 10)
                        return String(format: "%d:%02d.%d", minutes, remainingSeconds, tenths)
                    }())
                    .font(.system(size: 14))
                    .opacity(0.6)
                }
                VStack(alignment: .leading) {
                    Text("分数")
                        .font(.system(size: 16, weight: .medium))
                    Text(verbatim: "\(Int(meta.meta.score * 100))%")
                        .font(.system(size: 14))
                        .opacity(0.6)
                }
                VStack(alignment: .leading) {
                    Text("效率")
                        .font(.system(size: 16, weight: .medium))
                    Text(verbatim: "\(Int(meta.meta.efficiency * 100))%")
                        .font(.system(size: 14))
                        .opacity(0.6)
                }
                VStack(alignment: .leading) {
                    Text(verbatim: "BPM")
                        .font(.system(size: 16, weight: .medium))
                    Text(String(meta.meta.bpm))
                        .font(.system(size: 14))
                        .opacity(0.6)
                }
                VStack(alignment: .leading) {
                    Text("音符总数")
                        .font(.system(size: 16, weight: .medium))
                    Text(String(meta.meta.notes))
                        .font(.system(size: 14))
                        .opacity(0.6)
                }
                VStack(alignment: .leading) {
                    Text("每秒音符总数")
                        .font(.system(size: 16, weight: .medium))
                    Text(String(format: "%.1f", meta.meta.notesPerSecond))
                        .font(.system(size: 14))
                        .opacity(0.6)
                }
                VStack(alignment: .leading) {
                    Text("技能依赖度")
                        .font(.system(size: 16, weight: .medium))
                    Text(verbatim: "\(Int(meta.meta.sr * 100))%")
                        .font(.system(size: 14))
                        .opacity(0.6)
                }
            } header: {
                HStack {
                    Text("Meta")
                    Spacer()
                    Text(String(meta.meta.playLevel))
                        .foregroundStyle(.black)
                        .frame(width: 20, height: 20)
                        .background {
                            Circle()
                                .fill(meta.meta.difficulty.color)
                        }
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle(meta.song.musicTitle.forPreferredLocale() ?? "")
    }
}
