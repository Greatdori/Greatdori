//===---*- Greatdori! -*---------------------------------------------------===//
//
// ChartSimulator.swift
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
import SwiftUI

struct ChartSimulatorView: View {
    @State var selectedSong: PreviewSong?
    @State var isSongSelectorPresented = false
    @State var selectedDifficulty: DoriAPI.Song.DifficultyType = .easy
    var body: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                VStack {
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            ListItemView {
                                Text("歌曲")
                                    .bold()
                            } value: {
                                Button(action: {
                                    isSongSelectorPresented = true
                                }, label: {
                                    if let selectedSong {
                                        Text(selectedSong.title.forPreferredLocale() ?? "")
                                    } else {
                                        Text("选择歌曲…")
                                    }
                                })
                                .window(isPresented: $isSongSelectorPresented) {
                                    SongSelector(selection: .init { [selectedSong].compactMap { $0 } } set: { selectedSong = $0.first })
                                        .selectorDisablesMultipleSelection()
                                }
                            }
                            if let selectedSong {
                                ListItemView {
                                    Text("难度")
                                        .bold()
                                } value: {
                                    Picker(selection: $selectedDifficulty) {
                                        ForEach(selectedSong.difficulty.keys.sorted { $0.rawValue < $1.rawValue }, id: \.rawValue) { key in
                                            Text(String(selectedSong.difficulty[key]!.playLevel)).tag(key)
                                        }
                                    } label: {
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .navigationTitle("谱面模拟器")
    }
}
