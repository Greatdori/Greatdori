//===---*- Greatdori! -*---------------------------------------------------===//
//
// StyleView.swift
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
@_spi(GreatLyrics) import DoriKit

struct StyleView: View {
    @Binding var lyrics: Lyrics
    @State var presetStyles = [Lyrics.Style]()
    var body: some View {
        Form {
            Section {
                if !presetStyles.isEmpty {
                    ForEach(Array(presetStyles.enumerated()), id: \.element.id) { (index, style) in
                        NavigationLink {
                            StyleEditorView(style: style) { newStyle in
                                presetStyles[index] = newStyle
                                savePresets()
                            }
                        } label: {
                            TextStyleRender(text: "迷い星のうた", style: style)
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("No Presets")
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                }
                HStack {
                    Button {
                        presetStyles.append(.init(color: Color.primary))
                        savePresets()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.primary)
                    }
                }
                .buttonStyle(.borderless)
                .listRowInsets(.init())
            } header: {
                Text("Presets")
            }
        }
        .formStyle(.grouped)
        .navigationSubtitle("Style")
        .task {
            let decoder = PropertyListDecoder()
            let source = URL(filePath: NSHomeDirectory() + "/Documents/StylePresets.plist")
            if let _data = try? Data(contentsOf: source),
               let presets = try? decoder.decode([Lyrics.Style].self, from: _data) {
                presetStyles = presets
            }
        }
    }
    
    func savePresets() {
        let encoder = PropertyListEncoder()
        let destination = URL(filePath: NSHomeDirectory() + "/Documents/StylePresets.plist")
        try? encoder.encode(presetStyles).write(to: destination)
    }
}
