//===---*- Greatdori! -*---------------------------------------------------===//
//
// CornerstoneView.swift
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

// As name, this file is the cornerstone for the whole app, providing the most basic & repeative views.
// Views marked with [×] are deprecated.

import DoriKit
import SwiftUI


//MARK: CustomGroupBox
struct CustomGroupBox<Content: View>: View {
    let content: () -> Content
    var showGroupBox: Bool = true
    init(showGroupBox: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.showGroupBox = showGroupBox
        self.content = content
    }
    var body: some View {
        content()
        //            .wrapIf(showGroupBox) { content in
        //                content
        //                    .padding()
        //            }
            .padding(.all, showGroupBox ? nil : 0)
        //            .padding(.all, showGroupBox ? nil : 0)
            .background {
                if showGroupBox {
                    RoundedRectangle(cornerRadius: 15)
#if !os(macOS)
                        .foregroundStyle(Color(.secondarySystemGroupedBackground))
#else
                        .foregroundStyle(Color(NSColor.quaternarySystemFill))
#endif
                }
            }
    }
}


//MARK: CustomGroupBoxOld [×]
struct CustomGroupBoxOld<Content: View>: View {
    @Binding var backgroundOpacity: CGFloat
    let content: () -> Content
    init(backgroundOpacity: Binding<CGFloat> = .constant(1), @ViewBuilder content: @escaping () -> Content) {
        self._backgroundOpacity = backgroundOpacity
        self.content = content
    }
    var body: some View {
#if os(iOS)
        content()
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
#elseif os(macOS)
        GroupBox {
            content()
                .padding()
        }
#endif
    }
}


//MARK: DimissButton
struct DismissButton<L: View>: View {
    var action: () -> Void
    var label: () -> L
    var doDismiss: Bool = true
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Button(action: {
            action()
            if doDismiss {
                dismiss()
            }
        }, label: {
            label()
        })
    }
}


//MARK: MultilingualText
struct MultilingualText: View {
    let source: DoriAPI.LocalizedData<String>
    //    let locale: Locale
    var showLocaleKey: Bool = false
    @State var isHovering = false
    @State var allLocaleTexts: [String] = []
    @State var shownLocaleValueDict: [String: DoriAPI.Locale] = [:]
    @State var primaryDisplayString = ""
    @State var showCopyMessage = false
    @State var lastCopiedLocaleValue: DoriAPI.Locale? = nil
    
    init(source: DoriAPI.LocalizedData<String>, showLocaleKey: Bool = false) {
        self.source = source
        self.showLocaleKey = showLocaleKey
        
        var __allLocaleTexts: [String] = []
        var __shownLocaleValueDict: [String: DoriAPI.Locale] = [:]
        for lang in DoriAPI.Locale.allCases {
            if let pendingString = source.forLocale(lang) {
                if !__allLocaleTexts.contains(pendingString) {
                    __allLocaleTexts.append("\(pendingString)\(showLocaleKey ? " (\(localeToStringDict[lang] ?? "?"))" : "")")
                    __shownLocaleValueDict.updateValue(lang, forKey: __allLocaleTexts.last!)
                }
            }
        }
        self._allLocaleTexts = .init(initialValue: __allLocaleTexts)
        self._shownLocaleValueDict = .init(initialValue: __shownLocaleValueDict)
    }
    var body: some View {
        Group {
#if !os(macOS)
            Menu(content: {
                ForEach(allLocaleTexts, id: \.self) { localeValue in
                    Button(action: {
                        copyStringToClipboard(localeValue)
                        print(shownLocaleValueDict)
                        lastCopiedLocaleValue = shownLocaleValueDict[localeValue]
                        print()
                        showCopyMessage = true
                    }, label: {
                        Text(localeValue)
                            .multilineTextAlignment(.trailing)
                            .textSelection(.enabled)
                    })
                }
            }, label: {
                ZStack(alignment: .trailing, content: {
                    Label(lastCopiedLocaleValue == nil ? "Message.copy.success" : "Message.copy.success.locale.\(lastCopiedLocaleValue!.rawValue.uppercased())", systemImage: "document.on.document")
                        .opacity(showCopyMessage ? 1 : 0)
                        .offset(y: 2)
                    MultilingualTextInternalLabel(source: source, showLocaleKey: showLocaleKey)
                        .opacity(showCopyMessage ? 0 : 1)
                })
                .animation(.easeIn(duration: 0.2), value: showCopyMessage)
                .onChange(of: showCopyMessage, {
                    if showCopyMessage {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopyMessage = false
                        }
                    }
                })
            })
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .foregroundStyle(.primary)
#else
            MultilingualTextInternalLabel(source: source, showLocaleKey: showLocaleKey)
                .onHover { isHovering in
                    self.isHovering = isHovering
                }
                .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                    VStack(alignment: .trailing) {
                        ForEach(allLocaleTexts, id: \.self) { text in
                            Text(text)
                        }
                    }
                    .padding()
                }
#endif
        }
    }
    struct MultilingualTextInternalLabel: View {
        let source: DoriAPI.LocalizedData<String>
        //    let locale: Locale
        let showLocaleKey: Bool
        let allowTextSelection: Bool = true
        @State var primaryDisplayString: String = ""
        var body: some View {
            VStack(alignment: .trailing) {
                if let sourceInPrimaryLocale = source.forPreferredLocale(allowsFallback: false) {
                    Text("\(sourceInPrimaryLocale)\(showLocaleKey ? " (\(localeToStringDict[DoriAPI.preferredLocale] ?? "?"))" : "")")
                        .onAppear {
                            primaryDisplayString = sourceInPrimaryLocale
                        }
                } else if let sourceInSecondaryLocale = source.forSecondaryLocale(allowsFallback: false) {
                    Text("\(sourceInSecondaryLocale)\(showLocaleKey ? " (\(localeToStringDict[DoriAPI.secondaryLocale] ?? "?"))" : "")")
                        .onAppear {
                            primaryDisplayString = sourceInSecondaryLocale
                        }
                } else if let sourceInJP = source.jp {
                    Text("\(sourceInJP)\(showLocaleKey ? " (JP)" : "")")
                        .onAppear {
                            primaryDisplayString = sourceInJP
                        }
                }
                if let secondarySourceInSecondaryLang = source.forSecondaryLocale(allowsFallback: false), secondarySourceInSecondaryLang != primaryDisplayString {
                    Text("\(secondarySourceInSecondaryLang)\(showLocaleKey ? " (\(localeToStringDict[DoriAPI.secondaryLocale] ?? "?"))" : "")")
                        .foregroundStyle(.secondary)
                } else if let secondarySourceInJP = source.jp, secondarySourceInJP != primaryDisplayString {
                    Text("\(secondarySourceInJP)\(showLocaleKey ? " (JP)" : "")")
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.trailing)
            .wrapIf(allowTextSelection, in: { content in
                content
                    .textSelection(.enabled)
            }, else: { content in
                content
                    .textSelection(.disabled)
            })
        }
    }
}


//MARK: MultilingualTextForCountdown
struct MultilingualTextForCountdown: View {
    let source: DoriAPI.Event.Event
    @State var isHovering = false
    @State var allAvailableLocales: [DoriAPI.Locale] = []
    @State var primaryDisplayLocale: DoriAPI.Locale?
    @State var showCopyMessage = false
    var body: some View {
        Group {
#if !os(macOS)
            Menu(content: {
                VStack(alignment: .trailing) {
                    ForEach(allAvailableLocales, id: \.self) { localeValue in
                        Button(action: {
//                            copyStringToClipboard(getCountdownLocalizedString(source, forLocale: localeValue) ?? LocalizedStringResource(""))
                            showCopyMessage = true
                        }, label: {
                            MultilingualTextForCountdownInternalNumbersView(event: source, locale: localeValue)
                        })
                    }
                }
            }, label: {
                ZStack(alignment: .trailing, content: {
                    Label("Message.copy.unavailable.for.countdown", systemImage: "exclamationmark.circle")
                        .offset(y: 2)
                        .opacity(showCopyMessage ? 1 : 0)
                    MultilingualTextForCountdownInternalLabel(source: source, allAvailableLocales: allAvailableLocales)
                        .opacity(showCopyMessage ? 0 : 1)
                })
                .animation(.easeIn(duration: 0.2), value: showCopyMessage)
                .onChange(of: showCopyMessage, {
                    if showCopyMessage {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopyMessage = false
                        }
                    }
                })
            })
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .foregroundStyle(.primary)
#else
            MultilingualTextForCountdownInternalLabel(source: source, allAvailableLocales: allAvailableLocales)
                .onHover { isHovering in
                    self.isHovering = isHovering
                }
                .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                    VStack(alignment: .trailing) {
                        ForEach(allAvailableLocales, id: \.self) { localeValue in
                            MultilingualTextForCountdownInternalNumbersView(event: source, locale: localeValue)
                        }
                    }
                    .padding()
                }
#endif
        }
        .onAppear {
            allAvailableLocales = []
            for lang in DoriAPI.Locale.allCases {
                if source.startAt.availableInLocale(lang) {
                    allAvailableLocales.append(lang)
                }
            }
        }
    }
    struct MultilingualTextForCountdownInternalLabel: View {
        let source: DoriAPI.Event.Event
        let allAvailableLocales: [DoriAPI.Locale]
        let allowTextSelection: Bool = true
        @State var primaryDisplayingLocale: DoriAPI.Locale? = nil
        var body: some View {
            VStack(alignment: .trailing) {
                if allAvailableLocales.contains(DoriAPI.preferredLocale) {
                    MultilingualTextForCountdownInternalNumbersView(event: source, locale: DoriAPI.preferredLocale)
                        .onAppear {
                            primaryDisplayingLocale = DoriAPI.preferredLocale
                        }
                } else if allAvailableLocales.contains(DoriAPI.secondaryLocale) {
                    MultilingualTextForCountdownInternalNumbersView(event: source, locale: DoriAPI.secondaryLocale)
                        .onAppear {
                            primaryDisplayingLocale = DoriAPI.secondaryLocale
                        }
                } else if allAvailableLocales.contains(.jp) {
                    MultilingualTextForCountdownInternalNumbersView(event: source, locale: .jp)
                        .onAppear {
                            primaryDisplayingLocale = .jp
                        }
                }
                
                if allAvailableLocales.contains(DoriAPI.secondaryLocale), DoriAPI.secondaryLocale != primaryDisplayingLocale {
                    MultilingualTextForCountdownInternalNumbersView(event: source, locale: DoriAPI.secondaryLocale)
                        .foregroundStyle(.secondary)
                } else if allAvailableLocales.contains(.jp), .jp != primaryDisplayingLocale {
                    MultilingualTextForCountdownInternalNumbersView(event: source, locale: .jp)
                        .foregroundStyle(.secondary)
                }
            }
            .wrapIf(allowTextSelection, in: { content in
                content
                    .textSelection(.enabled)
            }, else: { content in
                content
                    .textSelection(.disabled)
            })
        }
    }
    struct MultilingualTextForCountdownInternalNumbersView: View {
        let event: DoriFrontend.Event.Event
        let locale: DoriAPI.Locale
        var body: some View {
            if let startDate = event.startAt.forLocale(locale),
               let endDate = event.endAt.forLocale(locale),
               let aggregateEndDate = event.aggregateEndAt.forLocale(locale),
               let distributionStartDate = event.distributionStartAt.forLocale(locale) {
                if startDate > .now {
                    Text("Event.countdown.start-at.\(Text(startDate, style: .relative)).\(localeToStringDict[locale] ?? "??")")
                } else if endDate > .now {
                    Text("Event.countdown.end-at.\(Text(endDate, style: .relative)).\(localeToStringDict[locale] ?? "??")")
                } else if aggregateEndDate > .now {
                    Text("Event.countdown.results-in.\(Text(endDate, style: .relative)).\(localeToStringDict[locale] ?? "??")")
                } else if distributionStartDate > .now {
                    Text("Event.countdown.rewards-in.\(Text(endDate, style: .relative)).\(localeToStringDict[locale] ?? "??")")
                } else {
                    Text("Event.countdown.completed.\(localeToStringDict[locale] ?? "??")")
                }
            }
        }
    }
}


//MARK: ListItemView
struct ListItemView<Content1: View, Content2: View>: View {
    let title: Content1
    let value: Content2
    var compactModeOnly: Bool = true
    var allowTextSelection: Bool = true
    @State private var totalAvailableWidth: CGFloat = 0
    @State private var titleAvailableWidth: CGFloat = 0
    @State private var valueAvailableWidth: CGFloat = 0
    
    init(@ViewBuilder title: () -> Content1, @ViewBuilder value: () -> Content2, compactModeOnly: Bool = true, allowTextSelection: Bool = true) {
        self.title = title()
        self.value = value()
        self.compactModeOnly = compactModeOnly
        self.allowTextSelection = allowTextSelection
    }
    
    var body: some View {
        Group {
            if compactModeOnly || (totalAvailableWidth - titleAvailableWidth - valueAvailableWidth) > 5 { // HStack (SHORT)
                HStack {
                    title
                        .fixedSize(horizontal: true, vertical: true)
                        .onFrameChange(perform: { geometry in
                            titleAvailableWidth = geometry.size.width
                        })
                    Spacer()
                    value
                        .wrapIf(allowTextSelection, in: { content in
                            content.textSelection(.enabled)
                        }, else: { content in
                            content.textSelection(.disabled)
                        })
                        .onFrameChange(perform: { geometry in
                            valueAvailableWidth = geometry.size.width
                        })
                }
            } else { // VStack (LONG)
                VStack(alignment: .leading) {
                    title
                        .fixedSize(horizontal: true, vertical: true)
                        .onFrameChange(perform: { geometry in
                            titleAvailableWidth = geometry.size.width
                        })
                    HStack {
                        Spacer()
                        value
                            .wrapIf(allowTextSelection, in: { content in
                                content.textSelection(.enabled)
                            }, else: { content in
                                content.textSelection(.disabled)
                            })
                            .onFrameChange(perform: { geometry in
                                valueAvailableWidth = geometry.size.width
                            })
                    }
                }
            }
        }
        .onFrameChange(perform: { geometry in
            totalAvailableWidth = geometry.size.width
        })
    }
}


//MARK: ListItemWithWrappingView
struct ListItemWithWrappingView<Content1: View, Content2: View, Content3: View, T>: View {
    let title: Content1
    let element: (T?) -> Content2
    let caption: Content3
    let columnNumbers: Int
    let elementWidth: CGFloat
    var contentArray: [T?]
    @State var contentArrayChunked: [[T?]] = []
    @State var titleWidth: CGFloat = 0 // Fixed
    @State var captionWidth: CGFloat = 0 // Fixed
    //    @State var cardsContentRegularWidth: CGFloat = 0 // Fixed
    @State var fixedWidth: CGFloat = 0 //Fixed
    @State var useCompactLayout = true
    
    init(@ViewBuilder title: () -> Content1, @ViewBuilder element: @escaping (T?) -> Content2, @ViewBuilder caption: () -> Content3, contentArray: [T] , columnNumbers: Int, elementWidth: CGFloat) {
        self.title = title()
        self.element = element
        self.caption = caption()
        self.contentArray = contentArray
        self.elementWidth = elementWidth
        self.columnNumbers = columnNumbers
    }
    var body: some View {
        ListItemView(title: {
            title
                .onFrameChange(perform: { geometry in
                    titleWidth = geometry.size.width
                    fixedWidth = (CGFloat(contentArray.count)*elementWidth) + titleWidth + captionWidth
                })
        }, value: {
            HStack {
                if !useCompactLayout {
                    HStack {
                        ForEach(0..<contentArray.count, id: \.self) { elementIndex in
                            element(contentArray[elementIndex])
                            //contentArray[elementIndex]
                        }
                    }
                } else {
                    Grid(alignment: .trailing) {
                        ForEach(0..<contentArrayChunked.count, id: \.self) { rowIndex in
                            GridRow {
                                ForEach(0..<contentArrayChunked[rowIndex].count, id: \.self) { columnIndex in
                                    if contentArrayChunked[rowIndex][columnIndex] != nil {
                                        NavigationLink(destination: {
                                            //TODO: [NAVI785]CardD
                                        }, label: {
                                            element(contentArrayChunked[rowIndex][columnIndex]!)
                                        })
                                        .buttonStyle(.plain)
                                    } else {
                                        Rectangle()
                                            .opacity(0)
                                            .frame(width: 0, height: 0)
                                    }
                                }
                            }
                        }
                    }
                    .gridCellAnchor(.trailing)
                }
                caption
                    .onFrameChange(perform: { geometry in
                        captionWidth = geometry.size.width
                        fixedWidth = (CGFloat(contentArray.count)*elementWidth) + titleWidth + captionWidth
                    })
            }
        })
        .onAppear {
            fixedWidth = (CGFloat(contentArray.count)*elementWidth) + titleWidth + captionWidth
            
            contentArrayChunked = contentArray.chunked(into: columnNumbers)
            for i in 0..<contentArrayChunked.count {
                while contentArrayChunked[i].count < columnNumbers {
                    contentArrayChunked[i].insert(nil, at: 0)
                }
            }
        }
        .onFrameChange(perform: { geometry in
            if (geometry.size.width - fixedWidth) < 50 && !useCompactLayout {
                useCompactLayout = true
            } else if (geometry.size.width - fixedWidth) > 50 && useCompactLayout {
                useCompactLayout = false
            }
        })
    }
}


////MARK: groupedContentBackgroundColor
//func groupedContentBackgroundColor() -> Color {
//#if os(iOS)
//    return Color(.systemGroupedBackground)
//#elseif os(macOS)
//    return Color(NSColor.windowBackgroundColor)
//#endif
//}
