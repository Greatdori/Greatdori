//
//  SongMetaView.swift
//  Greatdori
//
//  Created by Mark Chan on 8/9/25.
//

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
                        NavigationLink(destination: {  }) {
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
