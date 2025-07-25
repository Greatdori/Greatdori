//
//  AudioPlaying.swift
//  Greatdori
//
//  Created by Mark Chan on 7/25/25.
//

import Foundation
import AVFoundation

var _globalAudioPlayer = AVPlayer()

func playAudio(url: URL) {
    _globalAudioPlayer.replaceCurrentItem(with: .init(url: url))
    _globalAudioPlayer.seek(to: .init(seconds: 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    _globalAudioPlayer.play()
}
