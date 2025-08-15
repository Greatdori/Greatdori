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
    @State var previewSecondaryField = LyricField.original
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
                if editingField == .original,
                   let currentTextSelection,
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
                                if let sourceKey = lyricLine.partialStyle.keys.first(where: { $0.overlaps(lineRange) }) {
                                    Button("Remove", role: .destructive) {
                                        if lyrics.lyrics[lineIndex].partialStyle.removeValue(forKey: lineRange) != nil {
                                            return
                                        }
                                        let sourceKeySet = Set(sourceKey)
                                        let selectedKeySet = Set(lineRange)
                                        lyrics.lyrics[lineIndex].partialStyle.removeValue(forKey: sourceKey)
                                        let sourceDiff = sourceKeySet.subtracting(selectedKeySet).sorted()
                                        if !sourceDiff.isEmpty {
                                            let sourceDiffKey = sourceDiff.first!...sourceDiff.last!
                                            lyrics.lyrics[lineIndex].partialStyle.updateValue(lyricLine.partialStyle[sourceKey]!, forKey: sourceDiffKey)
                                        }
                                    }
                                    .tint(.red)
                                }
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
                                                lyrics.lyrics[lineIndex].partialStyle.updateValue(lyricLine.partialStyle[sourceKey]!, forKey: sourceDiffKey)
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
        VStack {
            HStack {
                Text("Preview")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                ProgressView()
                    .controlSize(.small)
                    .opacity(isPreviewUpdating ? 1 : 0)
                Picker("Secondary Text", selection: $previewSecondaryField) {
                    Text("None").tag(LyricField.original)
                    Text("Translation (JP)").tag(LyricField.translation(.jp))
                    Text("Translation (EN)").tag(LyricField.translation(.en))
                    Text("Translation (TW)").tag(LyricField.translation(.tw))
                    Text("Translation (CN)").tag(LyricField.translation(.cn))
                    Text("Translation (KR)").tag(LyricField.translation(.kr))
                    Text("Ruby (Romaji)").tag(LyricField.rubyRomaji)
                    Text("Ruby (Kana)").tag(LyricField.rubyKana)
                }
            }
            .padding([.horizontal, .top])
            ScrollView {
                HStack {
                    VStack(alignment: .leading, spacing: previewSecondaryField == .original ? 5 : 10) {
                        if let lyrics = lyricsForPreview {
                            ForEach(lyrics.lyrics) { lyricLine in
                                VStack(alignment: .leading, spacing: 0) {
                                    Group {
                                        if let mainStyle = lyrics.mainStyle {
                                            TextStyleRender(text: lyricLine.original, partialStyle: mergingMainStyle(mainStyle, with: lyricLine.partialStyle, for: lyricLine))
                                        } else {
                                            TextStyleRender(text: lyricLine.original, partialStyle: lyricLine.partialStyle)
                                        }
                                    }
                                    .font(.system(size: 20))
                                    if previewSecondaryField != .original {
                                        let secondaryText = switch previewSecondaryField {
                                        case .original:
                                            lyricLine.original
                                        case .translation(let locale):
                                            lyricLine.translations.forLocale(locale) ?? ""
                                        case .rubyRomaji:
                                            lyricLine.ruby?.romaji ?? ""
                                        case .rubyKana:
                                            lyricLine.ruby?.kana ?? ""
                                        }
                                        if !secondaryText.isEmpty {
                                            if let mainStyle = lyrics.mainStyle {
                                                TextStyleRender(text: secondaryText, style: mainStyle)
                                            } else {
                                                TextStyleRender(text: secondaryText, style: .init())
                                            }
                                        }
                                    }
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
            .mask {
                LinearGradient(colors: [
                    .black.opacity(0),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1)
                ], startPoint: .top, endPoint: .bottom)
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
// {"id":489,"lyrics":[{"id":"1B1E64D0-812D-4F32-BF67-1D1700D63FAD","original":"交差点の真ん中　急ぐ人に紛れて","partialStyle":[],"translations":{"cn":"置身十字路口正中央　混入熙来攘往的人群","en":"In the middle of the intersection, mixed among the busy crowd"}},{"id":"49C8B73C-BA48-46E2-AF7C-5740E1A24BA1","original":"僕だけがあてもなく　漂うみたいだ","partialStyle":[],"translations":{"cn":"唯独我漫无目的　有如流浪者一般","en":"I'm the only one who seems to be drifting aimlessly"}},{"id":"3F8E09B5-42B5-4151-B5F3-C10CE7493D17","original":"流行りの歌はいつも　僕のことは歌ってない","partialStyle":[],"translations":{"cn":"那些流行的首首歌曲　总是唱不出我的心思","en":"The popular songs never sing about me"}},{"id":"8500D3CE-1BB2-406C-80E2-42998A2E603A","original":"ねえビジョンの中から　笑いかけないで","partialStyle":[],"translations":{"cn":"请别在幻象之中　对我露出微笑","en":"Please, don't laugh at me from within that billboard screen"}},{"id":"02768460-6393-439E-A467-18BE5BB61278","original":"また今日も声にならずに　飲み込んだ感情","partialStyle":[],"translations":{"cn":"今天又语不成声　将感情吞入心底","en":"Today's another day of swallowing my feelings without voicing them"}},{"id":"A60219EA-A29B-427E-8757-78E614A99115","original":"下書き埋め尽くして","partialStyle":[],"translations":{"cn":"书页写满了草稿","en":"Filling my drafts up to the brim"}},{"id":"8E6CA252-CEDB-4017-81F9-AF5FF8127EBF","original":"ああ　そうやって何千回夜を越える","partialStyle":[],"translations":{"cn":"啊啊　就这么度过了数千个夜晚","en":"Ah, and like that, I get through the night, thousands of times"}},{"id":"9710A991-8959-4D9A-ACD8-9736813FC69E","original":"僕のため　それだけ　それだけだったんだよ","partialStyle":[],"translations":{"cn":"为了我自己　只是如此　就仅仅是如此而已","en":"They're for my sake, that's all, that's all they ever were"}},{"id":"60874C39-FFA7-49AE-B92B-61CD3D2B374B","original":"出口探し　溢れただけの言葉","partialStyle":[],"translations":{"cn":"为从心头满溢而出的话语找寻出口","en":"The words that just happened to overflow, spilling out of me as they searched for an exit"}},{"id":"1CDB002F-5D30-47E8-A50A-A74D53BDADF2","original":"君の心へ届いて　隙間をちょっと埋めるなら","partialStyle":[],"translations":{"cn":"若能传达至你的心中　稍稍填补虚无的空隙","en":"If they reach your heart and fill in its cracks even a little"}},{"id":"DD4A19DA-DEBB-46E2-A61C-154D649A51B5","original":"こんな僕でも　ここにいる　叫ぶよ","partialStyle":[],"translations":{"cn":"即使是这样的我　也将大喊我在这里","en":"Then although I'm just me, I'll scream that I'm right here"}},{"id":"92648FE9-CE77-41CD-99D2-6B5F31269121","original":"迷い星のうた","partialStyle":[],"translations":{"cn":"唱着迷途之星的歌","en":"The song of a lost star"}},{"id":"18C29DF1-5B25-4CC2-9B17-B7B6E84D5254","original":"問われることは何故か　将来のことばかり","partialStyle":[],"translations":{"cn":"不知为何每每问起　谈论的总都是未来","en":"For some reason, people always ask about my distant future"}},{"id":"DBEA0AAD-1424-4456-8833-CADC24B974A9","original":"目の前にいる僕の　今はおざなりで","partialStyle":[],"translations":{"cn":"但讲到眼前的我　却总是敷衍了事","en":"Never bothering with the present me who stands before them"}},{"id":"06CBF4D4-A423-4909-9E1C-0F66663761A5","original":"華やぎに馴染めない　この心を無視して","partialStyle":[],"translations":{"cn":"无视于我无法融入亮丽世界的心绪","en":"Please don't ignore the fact that I can't fit in with all that shines bright"}},{"id":"7E933D65-A037-4979-AE47-1581FC4C11C3","original":"輝かしい明日を　推奨しないでくれ","partialStyle":[],"translations":{"cn":"请不要推荐我走向散发光辉的明天","en":"And push suggestions of a brilliant future onto me"}},{"id":"7E50212A-2572-4B21-88EC-996DA6371FD6","original":"夜空にチカチカ光る　頼りない星屑","partialStyle":[],"translations":{"cn":"夜空中闪烁光芒　无依无靠的星辰","en":"That speck of stardust flickering unreliably in the night sky,"}},{"id":"0B30328E-0D8C-4FB6-989D-9D81311351D4","original":"躊躇いながらはぐれて","partialStyle":[],"translations":{"cn":"在踌躇之中失散","en":"Straying off as it hesitates"}},{"id":"8043AC5C-8C3C-49F7-A5A0-7415ECA49820","original":"ああ　彷徨っているそれが僕","partialStyle":[],"translations":{"cn":"啊啊　那颗彷徨的星儿就是我啊","en":"Ah, it's wandering about; that is me"}},{"id":"ADA2F30D-653D-471D-9515-B362E76B5DAD","original":"僕になる　それしか　それしかできないだろう","partialStyle":[],"translations":{"cn":"成为我自己　只有如此　我能做的只有如此","en":"I'll become myself, that's all, that's all I really can do"}},{"id":"797A039C-A0A0-47E1-94FB-7FB44CDB13C6","original":"誰の真似も　上手くやれないんだ","partialStyle":[],"translations":{"cn":"模仿他人这种事　我也没办法做得好","en":"I can't pretend to be someone else, anyway"}},{"id":"506398D6-C5AA-4A6D-85C3-DAAE011D9BD5","original":"こんな痛い日々をなんで　退屈だって片付ける？","partialStyle":[],"translations":{"cn":"为何要将这种痛苦的日子　用一句无趣带过","en":"Why must these days that hurt so much be wrapped up nicely into the word \"boring\"?"}},{"id":"0FF87722-8878-418E-A190-7349C1E5294A","original":"よろめきながらでも　もがいているんだよ","partialStyle":[],"translations":{"cn":"就算步伐多踉跄　我也是在挣扎着啊","en":"Even though I stagger, I'm fighting my way through"}},{"id":"41482815-688D-4867-B824-8B7228E618C9","original":"迷い星のうた","partialStyle":[],"translations":{"cn":"唱着迷途之星的歌","en":"The song of a lost star"}},{"id":"A5302DA8-7C59-48D7-833F-4698A54D807B","original":"僕のため　それだけ　それだけだったんだよ","partialStyle":[],"translations":{"cn":"为了我自己　只是如此　就仅仅是如此而已","en":"They're for my sake, that's all, that's all they ever were"}},{"id":"F6141033-AF74-48E9-B396-FCD9F2B20C77","original":"涙流し　やっと生まれた言葉","partialStyle":[],"translations":{"cn":"在流下泪水之后　才终于诞生的话语","en":"The words that were finally born as I shed tears"}},{"id":"904FC662-7AF2-4845-BEA6-9196CA7CD985","original":"どこかで同じように　ヒリヒリする胸抱えて","partialStyle":[],"translations":{"cn":"彼此似乎有些许相似　怀抱隐隐作痛的胸口","en":"If somewhere out there, you're carrying a stinging heart like mine,"}},{"id":"9D3B8B21-1390-48DE-917A-F2F905F92727","original":"震える君に　僕もいる　叫ぶよ","partialStyle":[],"translations":{"cn":"面对在颤抖的你　大喊着我与你同在","en":"To that trembling you, I'll scream that I'm here too"}},{"id":"470C50B4-0F36-421E-BF26-566D152EE13F","original":"迷い星のうた","partialStyle":[],"translations":{"cn":"唱着迷途之星的歌","en":"The song of a lost star"}}],"mainStyle":{"color":{"blue":0.8244126,"green":0.701363,"red":0.4210273},"fontOverride":"HanziPen SC","id":"D8FB913C-7E04-4B7D-A065-854023E54190","maskLines":[{"color":{"blue":0.6904459,"green":0.99995595,"red":1.0000879},"end":[1,0.09234639830508476],"start":[0,0.7190033783783782],"width":5.499999999999997}],"shadow":{"blur":0.5,"color":{"blue":0,"green":0,"red":0},"x":2.000000000000001,"y":2.000000000000001},"stroke":{"color":{"blue":0.9098039,"green":0.7529412,"red":0},"radius":0,"width":0.20000000000000015}},"metadata":{"legends":[]},"version":1}
