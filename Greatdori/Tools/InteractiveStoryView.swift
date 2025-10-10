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
import Combine
import DoriKit
import SwiftUI
import SDWebImageSwiftUI

@safe
struct InteractiveStoryView: View {
    var asset: DoriAPI.Misc.StoryAsset
    var voiceBundleURL: URL
    var locale: DoriLocale
    @Environment(\.dismiss) var dismiss
    @State var backgroundImageURL: URL?
    @State var scenarioImageURL: URL?
    @State var bgmPlayer = AVQueuePlayer()
    @State var bgmLooper: AVPlayerLooper!
    @State var sePlayer = AVPlayer()
    var voicePlayer: UnsafeMutablePointer<AVAudioPlayer>
    @State var live2dLoadSuccessCount = 0
    @State var voiceLoadSuccessCount = 0
    @State var loadErrorMessages = [String]()
    @State var isShowingLoadingOverlay = true
    @State var isShowingLoadingErrorOverlay = false
    @State var currentSnippetIndex = -1
    @State var currentTelop: String?
    @State var allDiffLayouts = [DoriAPI.Misc.StoryAsset.LayoutData]()
    @State var showingLayoutIndexs = [Int]()
    @State var currentTalk: DoriAPI.Misc.StoryAsset.TalkData?
    @State var talkAudios = [DoriAPI.Misc.StoryAsset.TalkData.Voice: Data]()
    @State var isDelaying = false
    @State var isShowingWhiteCover = false
    @State var isShowingBlackCover = false
    @State var isTalkTextAnimating = false
    @State var isHidingUI = false
    @State var isBacklogPresented = false
    @State var isAutoPlaying = false
    @State var autoPlayTimer: Timer?
    
    init(asset: DoriAPI.Misc.StoryAsset, voiceBundleURL: URL, locale: DoriLocale) {
        self.asset = asset
        self.voiceBundleURL = voiceBundleURL
        self.locale = locale
        unsafe voicePlayer = .allocate(capacity: 1)
        unsafe voicePlayer.initialize(to: .init())
        
        #if os(iOS)
        AppDelegate.orientationLock = .landscape
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeLeft))
        } else {
            // This is deprecated, we use it as a fallback
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        }
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
                                Spacer(minLength: 0)
                                unsafe LayoutView(data: layout, voicePlayer: voicePlayer, currentSpeckerID: currentTalk?.talkCharacters.first?.characterID ?? -1)
                                    .frame(width: geometry.size.height, height: geometry.size.height)
                                    .offset(x: {
                                        switch layout.sideTo {
                                        case .none: 0
                                        case .left: -(geometry.size.width / 4)
                                        case .leftOver: -(geometry.size.width / 3)
                                        case .leftInside: -(geometry.size.width / 6)
                                        case .center: 0
                                        case .right: geometry.size.width / 4
                                        case .rightOver: geometry.size.width / 3
                                        case .rightInside: geometry.size.width / 6
                                        case .leftUnder: -(geometry.size.width / 4)
                                        case .leftInsideUnder: -(geometry.size.width / 6)
                                        case .centerUnder: 0
                                        case .rightUnder: geometry.size.width / 4
                                        case .rightInsideUnder: geometry.size.width / 6
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
                                    .environment(\._layoutViewVisible, showingLayoutIndexs.contains(index))
                                    .animation(.spring(duration: 0.4, bounce: 0.2), value: layout)
                                    .animation(.spring(duration: 0.4, bounce: 0.25), value: showingLayoutIndexs)
                                    .onLive2DLoadSuccess {
                                        live2dLoadSuccessCount += 1
                                    }
                                    .onLive2DLoadFailure { error in
                                        loadErrorMessages.append((error as CustomDebugStringConvertible).debugDescription)
                                    }
                            }
                            Spacer()
                        }
                    }
                }
            }
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            if let currentTalk, !isHidingUI {
                VStack {
                    Spacer()
                    TalkView(data: currentTalk, locale: locale, isAnimating: $isTalkTextAnimating)
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
                        .font(.custom(fontName(in: locale), size: 18))
                        .foregroundStyle(Color(red: 80 / 255, green: 80 / 255, blue: 80 / 255))
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
            }
            #if os(iOS)
            if !isHidingUI {
                HStack {
                    Spacer()
                    VStack {
                        if #available(iOS 26.0, *) {
                            actionMenu
                                .buttonStyle(.glass)
                                .buttonBorderShape(.circle)
                        } else {
                            actionMenu
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.circle)
                        }
                        Spacer()
                    }
                }
            }
            #endif
            Rectangle()
                .fill(Color.white)
                .opacity(isShowingWhiteCover ? 1 : 0)
                .ignoresSafeArea()
            Rectangle()
                .fill(Color.black)
                .opacity(isShowingBlackCover ? 1 : 0)
                .ignoresSafeArea()
            
            if isShowingLoadingOverlay {
                ZStack {
                    Rectangle()
                        .fill(.background)
                    VStack {
                        ProgressView()
                            .controlSize(.large)
                        Text("正在载入…")
                    }
                }
                .ignoresSafeArea()
            }
            
            if isShowingLoadingErrorOverlay {
                ZStack {
                    Rectangle()
                        .fill(.background)
                    VStack {
                        Text("载入数据时出错")
                        ForEach(loadErrorMessages, id: \.self) { message in
                            Text(message)
                        }
                    }
                }
                .ignoresSafeArea()
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
        .navigationBarBackButtonHidden()
        #if os(macOS)
        .toolbar {
            ToolbarItem {
                actionMenu
            }
        }
        #endif
        .onTapGesture {
            if isHidingUI {
                isHidingUI = false
                return
            }
            if isAutoPlaying {
                autoPlayTimer?.invalidate()
                isAutoPlaying = false
                return
            }
            if isTalkTextAnimating {
                isTalkTextAnimating = false
                return
            }
            next()
        }
        .onKeyPress(keys: [.return, .space], phases: [.down]) { _ in
            if isHidingUI {
                isHidingUI = false
                return .handled
            }
            if isAutoPlaying {
                autoPlayTimer?.invalidate()
                isAutoPlaying = false
                return .handled
            }
            if isTalkTextAnimating {
                isTalkTextAnimating = false
                return .handled
            }
            next()
            return .handled
        }
        .sheet(isPresented: $isBacklogPresented) {
            if let talk = currentTalk {
                NavigationStack {
                    BacklogView(asset: asset, currentTalk: talk, locale: locale, audios: talkAudios)
                    #if os(macOS)
                        .frame(width: 500, height: 350)
                    #endif
                }
            }
        }
        .onAppear {
            if backgroundImageURL != nil {
                return
            }
            
            backgroundImageURL = .init(string: "https://bestdori.com/assets/jp/\(asset.firstBackgroundBundleName)_rip/\(asset.firstBackground).png")!
            let bgmItem = AVPlayerItem(url: .init(string: "https://bestdori.com/assets/jp/sound/scenario/bgm/\(asset.firstBGM.lowercased())_rip/\(asset.firstBGM).mp3")!)
            bgmLooper = .init(player: bgmPlayer, templateItem: bgmItem)
            
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
                                voiceLoadSuccessCount += 1
                            }
                        } else {
                            DispatchQueue.main.async {
                                loadErrorMessages.append("Failed to load voice '\(voice.voiceID)'")
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: live2dLoadSuccessCount) {
            processLoadingProgressChange()
        }
        .onChange(of: voiceLoadSuccessCount) {
            processLoadingProgressChange()
        }
        .onChange(of: loadErrorMessages) {
            processLoadingProgressChange()
        }
    }
    
    @ViewBuilder
    var actionMenu: some View {
        Menu {
            Section {
                Button(isAutoPlaying ? "取消自动" : "自动", systemImage: isAutoPlaying ? "play.slash.fill" : "play.fill") {
                    isAutoPlaying.toggle()
                    if isAutoPlaying {
                        next()
                    } else {
                        autoPlayTimer?.invalidate()
                    }
                }
                Button("全屏自动播放", systemImage: "pano.badge.play.fill") {
                    isAutoPlaying = true
                    isHidingUI = true
                    next()
                }
                .disabled(talkAudios.isEmpty)
                Button("快进", systemImage: "forward.fill") {
                    
                }
                .disabled(true)
                Button("记录", systemImage: "text.document.fill") {
                    isBacklogPresented = true
                }
                .disabled(currentTalk == nil)
                Button("不显示", systemImage: "xmark") {
                    isHidingUI = true
                }
                Button("退出", systemImage: "escape", role: .destructive) {
                    exitViewer()
                }
                .foregroundStyle(.red)
            }
        } label: {
            Image(systemName: "ellipsis")
            #if os(iOS)
                .font(.system(size: 20))
                .padding(12)
            #endif
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
    }
    
    func processLoadingProgressChange() {
        if !loadErrorMessages.isEmpty {
            isShowingLoadingErrorOverlay = true
            return
        }
        
        let voiceCount = asset.talkData.flatMap { $0.voices }.count
        
        if live2dLoadSuccessCount == allDiffLayouts.count
            && voiceLoadSuccessCount == voiceCount {
            isShowingLoadingOverlay = false
            
            bgmPlayer.play()
            next()
        }
    }
    
    func next(ignoresDelay: Bool = false) {
        guard !isDelaying || ignoresDelay else { return }
        
        currentSnippetIndex += 1
        
        if currentSnippetIndex == asset.snippets.endIndex {
            return
        }
        if currentSnippetIndex > asset.snippets.endIndex {
            exitViewer()
            return
        }
        
        let snippet = asset.snippets[currentSnippetIndex]
        
        if currentTelop != nil {
            if snippet.actionType == .effect,
               asset.specialEffectData[snippet.referenceIndex].effectType == .telop {
                isDelaying = true
                currentSnippetIndex -= 1
                withAnimation {
                    currentTelop = nil
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isDelaying = false
                    next()
                }
                return
            } else {
                withAnimation {
                    currentTelop = nil
                }
            }
        }
        
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
            if let voice = talkData.voices.first,
               let data = talkAudios[voice],
               let newPlayer = try? AVAudioPlayer(data: data) {
                newPlayer.isMeteringEnabled = true
                unsafe voicePlayer.pointee = newPlayer
                unsafe voicePlayer.pointee.play()
                if isAutoPlaying {
                    autoPlayTimer = .scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                        if unsafe !voicePlayer.pointee.isPlaying {
                            timer.invalidate()
                            autoPlayTimer = .scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                                DispatchQueue.main.async {
                                    next()
                                }
                            }
                        }
                    }
                }
            } else if isAutoPlaying {
                autoPlayTimer = .scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                    DispatchQueue.main.async {
                        next()
                    }
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
                    if await currentSnippetIndex + 1 < asset.snippets.endIndex {
                        // Motions can appear continuously
                        // and share the same start time for delay.
                        // We find the motion snippets immediately after this
                        // (if present) and perform them
                        let s = asset.snippets[await currentSnippetIndex + 1]
                        if s.actionType == .motion && s.delay > 0 {
                            DispatchQueue.main.async {
                                // If the snippet after the next is still a motion,
                                // the same code here in this call handles it
                                next(ignoresDelay: true)
                            }
                        }
                    }
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
                                if layoutData.type == .appear {
                                    showingLayoutIndexs.append(index)
                                } else {
                                    print("Scheduled a layout change, but it's not even visible?!")
                                }
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
                withAnimation(.linear(duration: effect.duration)) {
                    isShowingBlackCover = false
                }
                next()
            case .blackOut:
                withAnimation(.linear(duration: effect.duration)) {
                    isShowingBlackCover = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + effect.duration) {
                    isShowingWhiteCover = false
                }
                next()
            case .whiteIn:
                withAnimation(.linear(duration: effect.duration)) {
                    isShowingWhiteCover = false
                }
                next()
            case .whiteOut:
                withAnimation(.linear(duration: effect.duration)) {
                    isShowingWhiteCover = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + effect.duration) {
                    isShowingBlackCover = false
                }
                next()
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
                if isAutoPlaying {
                    autoPlayTimer = .scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                        DispatchQueue.main.async {
                            next()
                        }
                    }
                }
            case .flashbackIn:
                print("Not Implemented Effect: flashbackIn")
            case .flashbackOut:
                print("Not Implemented Effect: flashbackOut")
            case .ambientColorNormal:
                // FIXME: What does this action change?
                next()
            case .ambientColorEvening:
                // FIXME: What does this action change?
                next()
            case .ambientColorNight:
                // FIXME: What does this action change?
                next()
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
        autoPlayTimer?.invalidate()
        bgmPlayer.pause()
        sePlayer.pause()
        unsafe voicePlayer.pointee.stop()
        
        dismiss()
        
        #if os(iOS)
        AppDelegate.orientationLock = .portrait
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        } else {
            // This is deprecated, we use it as a fallback
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        UIViewController.attemptRotationToDeviceOrientation()
        #endif
        
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
    @Environment(\._layoutViewVisible) private var isVisible
    @State private var motions = [Live2DMotion]()
    @State private var expressions = [Live2DExpression]()
    @State private var lipSyncValue = 0.0
    @State private var lipSyncTimer: Timer?
    var body: some View {
        Live2DView(resourceURL: URL(string: "https://bestdori.com/assets/jp/live2d/chara/\(data.costumeType)_rip/buildData.asset")!)
            .live2dPauseAnimations(!isVisible) // performance
            .live2dMotion(isVisible ? motions.first(where: { $0.name == data.motionName }) : nil)
            .live2dExpression(isVisible ? expressions.first(where: { $0.name == data.expressionName }) : nil)
            .live2dLipSync(value: currentSpeckerID == data.characterID ? lipSyncValue : nil)
            ._live2dZoomFactor(1.9)
            ._live2dCoordinateMatrix("""
            [ s, 0, 0, 0,
              0,-s, 0, 0,
              0, 0, 1, 0,
              -19/20, 6/5, 0, 1 ]
            """)
            .onLive2DMotionsUpdate { motions in
                self.motions = motions
            }
            .onLive2DExpressionsUpdate { expressions in
                self.expressions = expressions
            }
            .onChange(of: isVisible) {
                if isVisible {
                    lipSyncTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
                        DispatchQueue.main.async {
                            unsafe voicePlayer.pointee.updateMeters()
                            lipSyncValue = pow(10, Double(unsafe voicePlayer.pointee.peakPower(forChannel: 0)) / 20) - 0.3
                        }
                    }
                } else {
                    lipSyncTimer?.invalidate()
                }
            }
            .onDisappear {
                lipSyncTimer?.invalidate()
            }
    }
}

private struct TalkView: View {
    var data: DoriAPI.Misc.StoryAsset.TalkData
    var locale: DoriLocale
    @Binding var isAnimating: Bool
    @State private var currentBody = ""
    @State private var bodyAnimationTimer: Timer?
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.gray.opacity(0.8))
                }
                .containerRelativeFrame(.vertical) { length, _ in
                    min(length / 2 - 80, 130)
                }
            Text({
                var result = AttributedString()
                for character in currentBody {
                    var str = AttributedString(String(character))
                    if locale == .cn && "[，。！？；：（）【】「」『』、“”‘’——…]".contains(character) {
                        // The font for cn has too wide punctuations,
                        // we have to fix it here
                        #if os(macOS)
                        str.font = .system(size: 20, weight: .medium)
                        #else
                        str.font = .system(size: 16, weight: .medium)
                        #endif
                    }
                    result.append(str)
                }
                return result
            }())
            #if os(macOS)
                .font(.custom(fontName(in: locale), size: 20))
            #else
                .font(.custom(fontName(in: locale), size: 16))
            #endif
                .wrapIf(locale == .en || locale == .tw) { content in
                    content
                        .lineSpacing(locale == .en ? 10 : -5)
                }
                .typesettingLanguage(locale.nsLocale().language)
                .foregroundStyle(Color(red: 80 / 255, green: 80 / 255, blue: 80 / 255))
                .padding(.horizontal, 20)
                .padding(.top, 12)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 255 / 255, green: 59 / 255, blue: 114 / 255))
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.white, lineWidth: 2)
                    }
                    .frame(width: 200, height: 32)
                Text(data.windowDisplayName)
                #if os(macOS)
                    .font(.custom(fontName(in: locale), size: 21))
                #else
                    .font(.custom(fontName(in: locale), size: 17))
                #endif
                    .foregroundStyle(.white)
                    .padding()
            }
            .offset(y: -38)
        }
        .onAppear {
            animateText()
        }
        .onChange(of: data.body) {
            animateText()
        }
        .onChange(of: isAnimating) {
            if !isAnimating {
                bodyAnimationTimer?.invalidate()
                currentBody = data.body
            }
        }
    }
    
    func animateText() {
        isAnimating = true
        currentBody = ""
        var iterator = data.body.makeIterator()
        bodyAnimationTimer?.invalidate()
        bodyAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                if let character = iterator.next() {
                    currentBody += String(character)
                } else {
                    isAnimating = false
                }
            }
        }
    }
}

private struct BacklogView: View {
    var asset: DoriAPI.Misc.StoryAsset
    var currentTalk: DoriAPI.Misc.StoryAsset.TalkData
    var locale: DoriLocale
    var audios: [DoriAPI.Misc.StoryAsset.TalkData.Voice: Data]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .fontWeight(.semibold)
                        .padding(8)
                })
                .buttonBorderShape(.circle)
                .wrapIf(true) { content in
                    if #available(macOS 26.0, *) {
                        content
                            .buttonStyle(.glass)
                    } else {
                        content
                            .buttonStyle(.bordered)
                    }
                }
                .padding([.top, .trailing], 10)
            }
            .padding(.bottom, 5)
            Divider()
                .padding(.horizontal, -15)
            #endif
            ScrollView {
                HStack {
                    VStack(alignment: .leading) {
                        ForEach(asset.talkData[asset.talkData.startIndex...asset.talkData.firstIndex(of: currentTalk)!], id: \.self) { talk in
                            HStack(alignment: .top) {
                                ZStack(alignment: .bottomTrailing) {
                                    WebImage(url: URL(string: "https://bestdori.com/res/icon/chara_icon_\(talk.talkCharacters.first?.characterID ?? -1).png"))
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    if let voice = talk.voices.first, let audioData = audios[voice] {
                                        Button(action: {
                                            if let player = try? AVAudioPlayer(data: audioData) {
                                                player.play()
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                                    _fixLifetime(player)
                                                }
                                            }
                                        }, label: {
                                            ZStack {
                                                Image(systemName: "speaker.wave.3.fill")
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                Image(systemName: "speaker.wave.3.fill")
                                                    .foregroundStyle(Color(red: 255 / 255, green: 59 / 255, blue: 114 / 255))
                                            }
                                            .shadow(radius: 1)
                                        })
                                        .buttonStyle(.plain)
                                        .offset(x: 5, y: 5)
                                    }
                                }
                                VStack(alignment: .leading) {
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color(red: 255 / 255, green: 59 / 255, blue: 114 / 255))
                                            .frame(width: 200, height: 20)
                                        Text(talk.windowDisplayName)
                                            .font(.custom(fontName(in: locale), size: 15))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 10)
                                    }
                                    Text(talk.body)
                                        .font(.custom(fontName(in: locale), size: 16))
                                        .foregroundStyle(colorScheme == .light ? Color(red: 80 / 255, green: 80 / 255, blue: 80 / 255) : .init(red: 238 / 255, green: 238 / 255, blue: 238 / 255))
                                        .padding(.leading, 20)
                                }
                            }
                            .padding(.bottom)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
        }
        #if !os(macOS)
        .toolbar {
            ToolbarItem {
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                })
            }
        }
        #endif
    }
}

private func fontName(in locale: DoriLocale) -> String {
    switch locale {
    case .jp: "RodinPro-DB"
    case .en: "NewRodinPro-DB"
    case .tw: "SourceHanSansTC-Bold"
    case .cn: "Tensentype-JiaLiDaYuanGB18030"
    case .kr: "JejuGothic"
    }
}

extension EnvironmentValues {
    @Entry fileprivate var _layoutViewVisible: Bool = false
}
