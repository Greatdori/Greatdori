//===---*- Greatdori! -*---------------------------------------------------===//
//
// LyricsView.swift
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

struct LyricsView: View {
    @Binding var lyrics: Lyrics
    @Environment(\.appearsActive) var appearsActive
    @Environment(\.openWindow) var openWindow
    @State var lyricsForPreview: Lyrics?
    @State var isPreviewUpdating = false
    @State var previewUpdateTimer: Timer?
    @State var editingField = LyricField.original
    @State var temporaryCombinedText = ""
    @State var currentTextSelection: TextSelection?
    var body: some View {
        VSplitView {
            HSplitView {
                TextEditor(text: $temporaryCombinedText, selection: $currentTextSelection)
                inspector
            }
            preview
        }
        .navigationSubtitle("Lyrics")
        .task {
            temporaryCombinedText = combinedText(for: lyrics.lyrics, in: editingField)
            lyricsForPreview = lyrics
        }
        .onDisappear {
            writeBackLyrics(from: temporaryCombinedText, in: editingField, to: &lyrics)
        }
        .onChange(of: editingField) { oldValue, newValue in
            writeBackLyrics(from: temporaryCombinedText, in: oldValue, to: &lyrics)
            temporaryCombinedText = combinedText(for: lyrics.lyrics, in: newValue)
        }
        .onChange(of: appearsActive) {
            if !appearsActive {
                writeBackLyrics(from: temporaryCombinedText, in: editingField, to: &lyrics)
            }
        }
    }
    
    @ViewBuilder
    var inspector: some View {
        VStack {
            Spacer()
            Form {
                Section {
                    Picker("Field", selection: $editingField) {
                        Text("Original").tag(LyricField.original)
                        Text("Translation (JP)").tag(LyricField.translation(.jp))
                        Text("Translation (EN)").tag(LyricField.translation(.en))
                        Text("Translation (TW)").tag(LyricField.translation(.tw))
                        Text("Translation (CN)").tag(LyricField.translation(.cn))
                        Text("Translation (KR)").tag(LyricField.translation(.kr))
                        Text("Ruby (Romaji)").tag(LyricField.rubyRomaji)
                        Text("Ruby (Kana)").tag(LyricField.rubyKana)
                    }
                } header: {
                    Text("Editing")
                }
                if let currentTextSelection,
                   !currentTextSelection.isInsertion,
                   case let .selection(range) = currentTextSelection.indices,
                   !temporaryCombinedText[range].contains("\n") {
                    Section {
                        Text(temporaryCombinedText[range])
                            .lineLimit(1)
                        if let (lineIndex, lineRange) = lyricsLineRange(from: range) {
                            let lyricLine = lyrics.lyrics[lineIndex]
                            let partialStyle = partialStyle(of: lyricLine, in: lineRange)
                            HStack {
                                if let partialStyle {
                                    TextStyleRender(text: String(temporaryCombinedText[range]), style: partialStyle)
                                        .lineLimit(1)
                                } else {
                                    Text("No Partial Style")
                                }
                                Spacer()
                                Button("Edit...") {
                                    let pUpdate = malloc(16)!
                                    let update: (Lyrics.Style) -> Void = { newStyle in
                                        if let sourceKey = lyricLine.partialStyle.keys.first(where: { $0.overlaps(lineRange) }) {
                                            let sourceKeySet = Set(sourceKey)
                                            let selectedKeySet = Set(lineRange)
                                            lyrics.lyrics[lineIndex].partialStyle.removeValue(forKey: sourceKey)
                                            lyrics.lyrics[lineIndex].partialStyle.updateValue(newStyle, forKey: lineRange)
                                            let sourceDiff = sourceKeySet.subtracting(selectedKeySet).sorted()
                                            if !sourceDiff.isEmpty {
                                                let sourceDiffKey = sourceDiff.first!...sourceDiff.last!
                                                lyrics.lyrics[lineIndex].partialStyle.updateValue(newStyle, forKey: sourceDiffKey)
                                            }
                                        } else {
                                            lyrics.lyrics[lineIndex].partialStyle.updateValue(newStyle, forKey: lineRange)
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                            unsafe pUpdate.deallocate()
                                        }
                                    }
                                    unsafe pUpdate.initializeMemory(as: ((Lyrics.Style) -> Void).self, to: update)
                                    openWindow(
                                        id: "StyleEditor",
                                        value: StyleEditorWindowData(
                                            style: partialStyle ?? lyrics.mainStyle ?? .init(),
                                            update: Int(bitPattern: pUpdate)
                                        )
                                    )
                                }
                            }
                        }
                    } header: {
                        Text("Selected Text")
                    }
                }
            }
            .formStyle(.grouped)
            Spacer()
        }
        .frame(minWidth: 200, idealWidth: 300, maxWidth: 350)
    }
    @ViewBuilder
    var preview: some View {
        ScrollView {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Preview")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                            .opacity(isPreviewUpdating ? 1 : 0)
                    }
                    .padding(.bottom, 5)
                    if let lyrics = lyricsForPreview {
                        ForEach(lyrics.lyrics, id: \.self) { lyricLine in
                            if let mainStyle = lyrics.mainStyle {
                                TextStyleRender(text: lyricLine.original, partialStyle: mergingMainStyle(mainStyle, with: lyricLine.partialStyle, for: lyricLine))
                            } else {
                                TextStyleRender(text: lyricLine.original, partialStyle: lyricLine.partialStyle)
                            }
                        }
                    } else {
                        HStack {
                            Spacer()
                            Text("Preview Unavailable")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                    }
                }
                .padding()
                Spacer()
            }
        }
        .onChange(of: temporaryCombinedText) {
            isPreviewUpdating = true
            previewUpdateTimer?.invalidate()
            previewUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                DispatchQueue.main.async {
                    var result = lyricsForPreview ?? lyrics
                    writeBackLyrics(from: temporaryCombinedText, in: editingField, to: &result)
                    lyricsForPreview = result
                    isPreviewUpdating = false
                }
            }
        }
        .onChange(of: lyrics) {
            lyricsForPreview = lyrics
        }
    }
    
    func writeBackLyrics(from temporaryText: String, in field: LyricField, to lyrics: inout Lyrics) {
        func setField(_ field: LyricField, of line: inout Lyrics.LyricLine, to text: String?) {
            switch field {
            case .original:
                line.original = text ?? ""
            case .translation(let locale):
                switch locale {
                case .jp:
                    line.translations.jp = text
                case .en:
                    line.translations.en = text
                case .tw:
                    line.translations.tw = text
                case .cn:
                    line.translations.cn = text
                case .kr:
                    line.translations.kr = text
                }
            case .rubyRomaji:
                if line.ruby != nil {
                    line.ruby!.romaji = text ?? ""
                } else {
                    line.ruby = .init(romaji: text ?? "", kana: "")
                }
                if line.ruby == .init(romaji: "", kana: "") {
                    line.ruby = nil
                }
            case .rubyKana:
                if line.ruby != nil {
                    line.ruby!.kana = text ?? ""
                } else {
                    line.ruby = .init(romaji: "", kana: text ?? "")
                }
                if line.ruby == .init(romaji: "", kana: "") {
                    line.ruby = nil
                }
            }
        }
        
        let lineText = temporaryText.components(separatedBy: "\n")
        var lineIterator = lineText.makeIterator()
        var removalLines = IndexSet()
        for case (let index, var lyricLine) in lyrics.lyrics.enumerated() {
            if let text = lineIterator.next() {
                setField(field, of: &lyricLine, to: text)
            } else {
                setField(field, of: &lyricLine, to: nil)
                if lyricLine.original.isEmpty
                    && lyricLine.translations == .init(jp: nil, en: nil, tw: nil, cn: nil, kr: nil)
                    && lyricLine.ruby == nil {
                    removalLines.insert(index)
                    continue
                }
            }
            lyrics.lyrics[index] = lyricLine
        }
        if !removalLines.isEmpty {
            lyrics.lyrics.remove(atOffsets: removalLines)
            return
        }
        while let text = lineIterator.next() {
            var newLine = Lyrics.LyricLine(original: "", translations: .init(jp: nil, en: nil, tw: nil, cn: nil, kr: nil), partialStyle: [:])
            setField(field, of: &newLine, to: text)
            lyrics.lyrics.append(newLine)
        }
    }
    func combinedText(for lyric: [Lyrics.LyricLine], in field: LyricField) -> String {
        lyric.compactMap {
            switch field {
            case .original:
                $0.original
            case .translation(let locale):
                $0.translations.forLocale(locale)
            case .rubyRomaji:
                $0.ruby?.romaji
            case .rubyKana:
                $0.ruby?.kana
            }
        }.joined(separator: "\n")
    }
    func lyricsLineRange(from range: Range<String.Index>) -> (lineIndex: Int, range: ClosedRange<Int>)? {
        let lineIndex = temporaryCombinedText[temporaryCombinedText.startIndex...range.lowerBound].count { $0 == "\n" }
        guard lineIndex < lyrics.lyrics.count else { return nil }
        var resultLower = 0
        while true {
            if let index = temporaryCombinedText.index(range.lowerBound, offsetBy: -resultLower - 1, limitedBy: temporaryCombinedText.startIndex) {
                if temporaryCombinedText[index] == "\n" {
                    break
                }
            } else {
                break
            }
            resultLower += 1
        }
        let resultUpper = resultLower + temporaryCombinedText[range].count - 1
        return (lineIndex, resultLower...resultUpper)
    }
    func partialStyle(of line: Lyrics.LyricLine, in range: ClosedRange<Int>) -> Lyrics.Style? {
        // Find exact match first
        if let style = line.partialStyle[range] {
            return style
        }
        // Find contained
        if let containedStyle = line.partialStyle.first(where: { pair in range.allSatisfy { pair.key.contains($0) } }) {
            return containedStyle.value
        }
        return nil
    }
    func mergingMainStyle(
        _ mainStyle: Lyrics.Style,
        with partialStyle: [ClosedRange<Int>: Lyrics.Style],
        for line: Lyrics.LyricLine
    ) -> [ClosedRange<Int>: Lyrics.Style] {
        var mainRangeSet = Set(0..<line.original.count)
        var result = [ClosedRange<Int>: Lyrics.Style]()
        for (range, style) in partialStyle {
            result.updateValue(style, forKey: range)
            mainRangeSet.subtract(Set(range))
        }
        let mainRanges = mainRangeSet.sorted().reduce(into: [ClosedRange<Int>]()) { ranges, index in
            if let last = ranges.last, index == last.upperBound + 1 {
                ranges[ranges.count - 1] = last.lowerBound...index
            } else {
                ranges.append(index...index)
            }
        }
        for range in mainRanges {
            result.updateValue(mainStyle, forKey: range)
        }
        return result
    }
    
    enum LyricField: Hashable {
        case original
        case translation(DoriAPI.Locale)
        case rubyRomaji
        case rubyKana
    }
}

// FIXME: Delete this comment after finishing debugging
// {"id":489,"lyrics":[{"original":"交差点の真ん中　急ぐ人に紛れて","partialStyle":[[4,6],{"color":{"blue":0.8244126,"green":0.701363,"red":0.4210273},"fontOverride":"HanziPen SC","id":"D8FB913C-7E04-4B7D-A065-854023E54190","maskLines":[],"shadow":{"blur":0.5,"color":{"blue":0,"green":0,"red":0},"x":2.000000000000001,"y":2.000000000000001},"stroke":{"color":{"blue":-0.27578682,"green":0.9078494,"red":-0.36141714},"radius":0,"width":0.20000000000000015}}],"translations":{}},{"original":"僕だけがあてもなく　漂うみたいだ","partialStyle":[],"translations":{}},{"original":"流行りの歌はいつも　僕のことは歌ってない","partialStyle":[],"translations":{}},{"original":"ねえビジョンの中から　笑いかけないで","partialStyle":[],"translations":{}},{"original":"また今日も声にならずに　飲み込んだ感情","partialStyle":[],"translations":{}},{"original":"下書き埋め尽くして","partialStyle":[],"translations":{}},{"original":"ああ　そうやって何千回夜を越える","partialStyle":[],"translations":{}},{"original":"僕のため　それだけ　それだけだったんだよ","partialStyle":[],"translations":{}},{"original":"出口探し　溢れただけの言葉","partialStyle":[],"translations":{}},{"original":"君の心へ届いて　隙間をちょっと埋めるなら","partialStyle":[],"translations":{}},{"original":"こんな僕でも　ここにいる　叫ぶよ","partialStyle":[],"translations":{}},{"original":"迷い星のうた","partialStyle":[[0,5],{"color":{"blue":0.8244126,"green":0.701363,"red":0.4210273},"fontOverride":"HanziPen SC","id":"D8FB913C-7E04-4B7D-A065-854023E54190","maskLines":[],"shadow":{"blur":0.5,"color":{"blue":0,"green":0,"red":0},"x":2.000000000000001,"y":2.000000000000001},"stroke":{"color":{"blue":-0.33642805,"green":0.97861725,"red":0.95413417},"radius":0,"width":0.1}}],"translations":{}},{"original":"問われることは何故か　将来のことばかり","partialStyle":[],"translations":{}},{"original":"目の前にいる僕の　今はおざなりで","partialStyle":[],"translations":{}},{"original":"華やぎに馴染めない　この心を無視して","partialStyle":[],"translations":{}},{"original":"輝かしい明日を　推奨しないでくれ","partialStyle":[],"translations":{}},{"original":"夜空にチカチカ光る　頼りない星屑","partialStyle":[],"translations":{}},{"original":"躊躇いながらはぐれて","partialStyle":[],"translations":{}},{"original":"ああ　彷徨っているそれが僕","partialStyle":[],"translations":{}},{"original":"僕になる　それしか　それしかできないだろう","partialStyle":[],"translations":{}},{"original":"誰の真似も　上手くやれないんだ","partialStyle":[],"translations":{}},{"original":"こんな痛い日々をなんで　退屈だって片付ける？","partialStyle":[],"translations":{}},{"original":"よろめきながらでも　もがいているんだよ","partialStyle":[],"translations":{}},{"original":"迷い星のうた","partialStyle":[],"translations":{}},{"original":"僕のため　それだけ　それだけだったんだよ","partialStyle":[],"translations":{}},{"original":"涙流し　やっと生まれた言葉","partialStyle":[],"translations":{}},{"original":"どこかで同じように　ヒリヒリする胸抱えて","partialStyle":[],"translations":{}},{"original":"震える君に　僕もいる　叫ぶよ","partialStyle":[],"translations":{}},{"original":"迷い星のうた","partialStyle":[],"translations":{}}],"mainStyle":{"color":{"blue":0.8244126,"green":0.701363,"red":0.4210273},"fontOverride":"HanziPen SC","id":"D8FB913C-7E04-4B7D-A065-854023E54190","maskLines":[{"color":{"blue":0.6904459,"green":0.99995595,"red":1.0000879},"end":[1,0.09234639830508476],"start":[0,0.7190033783783782],"width":5.499999999999997}],"shadow":{"blur":0.5,"color":{"blue":0,"green":0,"red":0},"x":2.000000000000001,"y":2.000000000000001},"stroke":{"color":{"blue":0.9098039,"green":0.7529412,"red":0},"radius":0,"width":0.20000000000000015}},"metadata":{"legends":[]},"version":1}
