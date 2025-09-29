//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDifficultyIndicators.swift
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
import SDWebImageSwiftUI
import SwiftUI


// MARK: SongDifficultiesIndicator
struct SongDifficultiesIndicator: View {
    var information: [DoriAPI.Song.DifficultyType: Int]
    
    init(_ difficulty: [DoriAPI.Song.DifficultyType : DoriAPI.Song.Song.Difficulty]) {
        self.information = difficulty.mapValues{ $0.playLevel }
    }
    
    init(_ difficulty: [DoriAPI.Song.DifficultyType : DoriAPI.Song.PreviewSong.Difficulty]) {
        self.information = difficulty.mapValues{ $0.playLevel }
    }
    
    init (_ difficulty: [DoriAPI.Song.DifficultyType : Int]) {
        self.information = difficulty
    }
    var body: some View {
        HStack {
            ForEach(DoriAPI.Song.DifficultyType.allCases, id: \.self) { item in
                if information[item] != nil {
                    SongDifficultyIndicator(difficulty: item, level: information[item]!)
                }
            }
        }
    }
}


// MARK: SongDifficultyIndicator
struct SongDifficultyIndicator: View {
    @Environment(\.colorScheme) var colorScheme
    var difficulty: DoriAPI.Song.DifficultyType
    var level: Int
    let diameter: CGFloat = imageButtonSize*0.75
    
    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(colorScheme == .dark ? difficulty.darkColor : difficulty.color)
                .frame(width: diameter, height: diameter)
            Text("\(level)")
                .fontWeight(.semibold)
        }
    }
}
