//===---*- Greatdori! -*---------------------------------------------------===//
//
// GreatLyricsApp.swift
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

typealias Lyrics = DoriFrontend.Song.Lyrics

/// A utility for generating lyric files.
///
/// This app is only used for development and is not intended to publish.
@main
struct GreatLyricsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
