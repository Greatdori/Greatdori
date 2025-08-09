//===---*- Greatdori! -*---------------------------------------------------===//
//
// AudioPlaying.swift
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

import Foundation
import AVFoundation

var _globalAudioPlayer = AVPlayer()

func playAudio(url: URL) {
    _globalAudioPlayer.replaceCurrentItem(with: .init(url: url))
    _globalAudioPlayer.seek(to: .init(seconds: 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    _globalAudioPlayer.play()
}
