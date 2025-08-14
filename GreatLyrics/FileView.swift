//===---*- Greatdori! -*---------------------------------------------------===//
//
// FileView.swift
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
@_private(sourceFile: "FrontendSong.swift") import DoriKit

struct FileView: View {
    @Binding var lyrics: Lyrics
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Decodable File")
                    Spacer()
                    Button("Export...") {
                        
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationSubtitle("File")
    }
}
