//===---*- Greatdori! -*---------------------------------------------------===//
//
// InteractiveStoryView.swift
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

import AVKit
import DoriKit
import SwiftUI
import SDWebImageSwiftUI

@safe
struct InteractiveStoryView: View {
    var asset: DoriAPI.Misc.StoryAsset
    var voiceBundleURL: URL
    @Environment(\.dismiss) var dismiss
    @State var backgroundImageURL: URL?
    @State var scenarioImageURL: URL?
    @State var bgmPlayer = AVQueuePlayer()
    @State var bgmLooper: AVPlayerLooper!
    @State var sePlayer = AVPlayer()
    var voicePlayer: UnsafeMutablePointer<AVAudioPlayer>
    @State var currentSnippetIndex = -1
    @State var currentTelop: String?
    @State var allDiffLayouts = [DoriAPI.Misc.StoryAsset.LayoutData]()
    @State var showingLayoutIndexs = [Int]()
    @State var currentTalk: DoriAPI.Misc.StoryAsset.TalkData?
    @State var talkAudios = [DoriAPI.Misc.StoryAsset.TalkData.Voice: Data]()
    @State var isDelaying = false
    
    init(asset: DoriAPI.Misc.StoryAsset, voiceBundleURL: URL) {
        self.asset = asset
        self.voiceBundleURL = voiceBundleURL
        unsafe voicePlayer = .allocate(capacity: 1)
        unsafe voicePlayer.initialize(to: .init())
        
        #if os(iOS)
        AppDelegate.orientationLock = .landscape
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        #endif
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    ForEach(Array(allDiffLayouts.enumerated()), id: \.element.costumeType) { index, layout in
                        HStack {
                            Spacer()
                            VStack {
                                Spacer()
                                unsafe LayoutView(data: layout, voicePlayer: voicePlayer, currentSpeckerID: currentTalk?.talkCharacters.first?.characterID ?? -1)
                                    .frame(width: geometry.size.height, height: geometry.size.height)
                                    .offset(x: {
                                        switch layout.sideTo {
                                        case .none: 0
                                        case .left: -(geometry.size.width / 4)
                                        case .leftOver: -(geometry.size.width / 3)
                                        case .leftInside: -(geometry.size.width / 4)
                                        case .center: 0
                                        case .right: geometry.size.width / 4
                                        case .rightOver: geometry.size.width / 3
                                        case .rightInside: geometry.size.width / 4
                                        case .leftUnder: -(geometry.size.width / 4)
                                        case .leftInsideUnder: -(geometry.size.width / 4)
                                        case .centerUnder: 0
                                        case .rightUnder: geometry.size.width / 4
                                        case .rightInsideUnder: geometry.size.width / 4
                                        @unknown default: 0
                                        }
                                    }(), y: {
                                        switch layout.sideTo {
                                        case .leftUnder,
                                                .leftInsideUnder,
                                                .centerUnder,
                                                .rightUnder,
                                                .rightInsideUnder: geometry.size.height / 6
                                        default: 0
                                        }
                                    }())
                                    .opacity(showingLayoutIndexs.contains(index) ? 1 : 0)
                                    .animation(.spring(duration: 0.4, bounce: 0.2), value: layout)
                                    .animation(.spring(duration: 0.4, bounce: 0.25), value: showingLayoutIndexs)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .ignoresSafeArea()
            if let currentTalk {
                VStack {
                    Spacer()
                    TalkView(data: currentTalk)
                        .padding()
                }
            }
            if let currentTelop {
                ZStack {
                    Capsule()
                        .fill(Color.red.opacity(0.7))
                        .rotationEffect(.degrees(-0.5))
                        .frame(width: 400, height: 35)
                    Capsule()
                        .fill(Color.white)
                        .rotationEffect(.degrees(0.5))
                        .frame(width: 380, height: 32)
                    Text(currentTelop)
                        .font(.system(size: 20))
                }
                .transition(.flipFromRight)
            }
        }
        .background {
            WebImage(url: backgroundImageURL)
                .resizable()
                .scaledToFill()
                .clipped()
                .ignoresSafeArea()
            if let scenarioImageURL {
                WebImage(url: scenarioImageURL)
                    .resizable()
                    .aspectRatio(4 / 3, contentMode: .fill)
                    .clipped()
                    .ignoresSafeArea()
            }
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        #endif
        .onTapGesture {
            next()
        }
        .onAppear {
            backgroundImageURL = .init(string: "https://bestdori.com/assets/jp/\(asset.firstBackgroundBundleName)_rip/\(asset.firstBackground).png")!
            let bgmItem = AVPlayerItem(url: .init(string: "https://bestdori.com/assets/jp/sound/scenario/bgm/\(asset.firstBGM.lowercased())_rip/\(asset.firstBGM).mp3")!)
            bgmLooper = .init(player: bgmPlayer, templateItem: bgmItem)
            bgmPlayer.play()
            
            for layout in asset.layoutData {
                if !layout.costumeType.isEmpty && !allDiffLayouts.contains(where: {
                    $0.characterID == layout.characterID
                    && $0.costumeType == layout.costumeType
                }) {
                    allDiffLayouts.append(layout)
                }
            }
            
            for talk in asset.talkData {
                for voice in talk.voices {
                    DispatchQueue(label: "com.memz233.Greatdori.Interactive-Story-Get-Voices", qos: .userInitiated).async {
                        if let data = try? Data(contentsOf: URL(string: "\(voiceBundleURL.absoluteString)_rip/\(voice.voiceID).mp3")!) {
                            DispatchQueue.main.async {
                                talkAudios.updateValue(data, forKey: voice)
                            }
                        }
                    }
                }
            }
            
            next()
        }
        .onDisappear {
            #if os(iOS)
            AppDelegate.orientationLock = .portrait
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            #endif
        }
    }
    
    func next() {
        guard !isDelaying else { return }
        
        withAnimation {
            currentTelop = nil
        }
        
        currentSnippetIndex += 1
        
        if currentSnippetIndex >= asset.snippets.endIndex {
            exitViewer()
            return
        }
        
        let snippet = asset.snippets[currentSnippetIndex]
        switch snippet.actionType {
        case .none:
            isDelaying = true
            Task.detached {
                try? await Task.sleep(for: .seconds(snippet.delay))
                await MainActor.run {
                    isDelaying = false
                    next()
                }
            }
        case .talk:
            let talkData = asset.talkData[snippet.referenceIndex]
            currentTalk = talkData
            if let voice = talkData.voices.first, let data = talkAudios[voice] {
                if let newPlayer = try? AVAudioPlayer(data: data) {
                    newPlayer.isMeteringEnabled = true
                    unsafe voicePlayer.pointee = newPlayer
                    unsafe voicePlayer.pointee.play()
                }
            }
            for motion in talkData.motions {
                if let index = showingLayoutIndexs.first(where: { allDiffLayouts[$0].characterID == motion.characterID }) {
                    allDiffLayouts[index].motionName = motion.motionName
                    allDiffLayouts[index].expressionName = motion.expressionName
                } else {
                    print("Talk requires motion change to character \(motion.characterID), but she's not visible?!")
                }
            }
            if currentSnippetIndex + 1 < asset.snippets.endIndex && asset.snippets[currentSnippetIndex + 1].actionType == .motion {
                next()
            }
        case .layout, .motion:
            let layoutData = asset.layoutData[snippet.referenceIndex]
            isDelaying = true
            Task.detached {
                if snippet.delay > 0 {
                    try? await Task.sleep(for: .seconds(snippet.delay))
                }
                switch layoutData.type {
                case .none, .move, .appear:
                    var newData = layoutData
                    // Find before for each empty data
                    let dataBefore = asset.layoutData[asset.layoutData.startIndex...snippet.referenceIndex]
                        .filter { $0.characterID == layoutData.characterID }
                        .reversed()
                    if newData.costumeType.isEmpty {
                        for data in dataBefore where !data.costumeType.isEmpty {
                            newData.costumeType = data.costumeType
                            break
                        }
                    }
                    if newData.motionName.isEmpty {
                        for data in dataBefore where !data.motionName.isEmpty {
                            newData.motionName = data.motionName
                            break
                        }
                    }
                    if newData.expressionName.isEmpty {
                        for data in dataBefore where !data.expressionName.isEmpty {
                            newData.expressionName = data.expressionName
                            break
                        }
                    }
                    await MainActor.run {
                        if let index = allDiffLayouts.firstIndex(where: { $0.costumeType == newData.costumeType }) {
                            if layoutData.type == .none {
                                newData.sideFrom = allDiffLayouts[index].sideFrom
                                newData.sideTo = allDiffLayouts[index].sideTo
                                newData.sideFromOffsetX = allDiffLayouts[index].sideFromOffsetX
                                newData.sideToOffsetX = allDiffLayouts[index].sideToOffsetX
                            }
                            allDiffLayouts[index] = newData
                            if !showingLayoutIndexs.contains(index) {
                                showingLayoutIndexs.append(index)
                            }
                        } else {
                            print("A combined layout '\(newData)' doesn't match any layout in full list '\(allDiffLayouts)'?!")
                        }
                    }
                case .hide:
                    await MainActor.run {
                        showingLayoutIndexs.removeAll {
                            allDiffLayouts[$0].characterID == layoutData.characterID
                        }
                    }
                case .shakeX:
                    print("Not Implemented Layout: shakeY")
                case .shakeY:
                    print("Not Implemented Layout: shakeY")
                @unknown default: break
                }
                await MainActor.run {
                    isDelaying = false
                    if snippet.actionType == .layout {
                        next()
                    }
                }
            }
        case .input:
            print("Not Implemented Action: input")
        case .selectable:
            print("Not Implemented Action: selectable")
        case .effect:
            let effect = asset.specialEffectData[snippet.referenceIndex]
            switch effect.effectType {
            case .none:
                break
            case .blackIn:
                print("Not Implemented Effect: blackIn")
            case .blackOut:
                print("Not Implemented Effect: blackOut")
            case .whiteIn:
                print("Not Implemented Effect: whiteIn")
            case .whiteOut:
                print("Not Implemented Effect: whiteOut")
            case .shakeScreen:
                print("Not Implemented Effect: shakeScreen")
            case .shakeWindow:
                print("Not Implemented Effect: shakeWindow")
            case .changeBackground, .changeBackgroundStill, .changeCardStill:
                withAnimation {
                    backgroundImageURL = .init(string: "https://bestdori.com/assets/jp/\(effect.stringVal)_rip/\(effect.stringValSub).png")!
                }
                next()
            case .telop:
                withAnimation {
                    currentTelop = effect.stringVal
                }
            case .flashbackIn:
                print("Not Implemented Effect: flashbackIn")
            case .flashbackOut:
                print("Not Implemented Effect: flashbackOut")
            case .ambientColorNormal:
                print("Not Implemented Effect: ambientColorNormal")
            case .ambientColorEvening:
                print("Not Implemented Effect: ambientColorEvening")
            case .ambientColorNight:
                print("Not Implemented Effect: ambientColorNight")
            case .playScenarioEffect:
                withAnimation {
                    scenarioImageURL = .init(string: "https://bestdori.com/assets/jp/\(effect.stringValSub)_rip/bg.png")!
                }
                next()
            case .stopScenarioEffect:
                withAnimation {
                    scenarioImageURL = nil
                }
                next()
            @unknown default: break
            }
        case .sound:
            let soundData = asset.soundData[snippet.referenceIndex]
            if !soundData.bgm.isEmpty {
                bgmPlayer.pause()
                bgmPlayer.removeAllItems()
                let bgmItem = AVPlayerItem(url: .init(string: "https://bestdori.com/assets/jp/sound/scenario/bgm/\(soundData.bgm.lowercased())_rip/\(soundData.bgm).mp3")!)
                bgmLooper = .init(player: bgmPlayer, templateItem: bgmItem)
                bgmPlayer.play()
            } else if !soundData.se.isEmpty {
                sePlayer.replaceCurrentItem(with: .init(url: .init(string: "https://bestdori.com/assets/jp/sound/se/\(soundData.seBundleName)_rip/\(soundData.se).mp3")!))
                sePlayer.play()
            }
            next()
        @unknown default: break
        }
    }
    
    func exitViewer() {
        // clean up
        bgmPlayer.pause()
        sePlayer.pause()
        unsafe voicePlayer.pointee.stop()
        
        dismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            unsafe voicePlayer.deinitialize(count: 1)
            unsafe voicePlayer.deallocate()
        }
    }
}

@safe
private struct LayoutView: View {
    var data: DoriAPI.Misc.StoryAsset.LayoutData
    var voicePlayer: UnsafeMutablePointer<AVAudioPlayer>
    var currentSpeckerID: Int
    @State var motions = [Live2DMotion]()
    @State var expressions = [Live2DExpression]()
    @State var isVisible = false
    @State var lipSyncValue = 0.0
    @State var lipSyncTimer: Timer?
    var body: some View {
        Live2DView(resourceURL: URL(string: "https://bestdori.com/assets/jp/live2d/chara/\(data.costumeType)_rip/buildData.asset")!)
            .live2dMotion(isVisible ? motions.first(where: { $0.name == data.motionName }) : nil)
            .live2dExpression(isVisible ? expressions.first(where: { $0.name == data.expressionName }) : nil)
            .live2dLipSync(value: currentSpeckerID == data.characterID ? lipSyncValue : nil)
            .onLive2DMotionsUpdate { motions in
                self.motions = motions
            }
            .onLive2DExpressionsUpdate { expressions in
                self.expressions = expressions
            }
            .onAppear {
                isVisible = true
                lipSyncTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
                    DispatchQueue.main.async {
                        unsafe voicePlayer.pointee.updateMeters()
                        lipSyncValue = pow(10, Double(unsafe voicePlayer.pointee.peakPower(forChannel: 0)) / 20) - 0.3
                    }
                }
            }
            .onDisappear {
                isVisible = false
                lipSyncTimer?.invalidate()
            }
    }
}

private struct TalkView: View {
    var data: DoriAPI.Misc.StoryAsset.TalkData
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .containerRelativeFrame(.vertical) { length, _ in
                    min(length / 2 - 80, 130)
                }
            Text(data.body)
            #if os(macOS)
                .font(.system(size: 22))
            #else
                .font(.system(size: 18))
            #endif
                .foregroundStyle(.black)
                .padding(20)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.red)
                    .frame(width: 220, height: 32)
                Text(data.windowDisplayName)
                #if os(macOS)
                    .font(.system(size: 22))
                #else
                    .font(.system(size: 18))
                #endif
                    .foregroundStyle(.white)
                    .padding()
            }
            .offset(y: -35)
        }
    }
}
