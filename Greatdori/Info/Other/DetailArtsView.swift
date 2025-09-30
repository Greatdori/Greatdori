//===---*- Greatdori! -*---------------------------------------------------===//
//
// DetailArtsView.swift
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


import DoriKit
import SDWebImageSwiftUI
import SwiftUI
#if os(macOS)
import QuickLook
#endif

@resultBuilder
struct ArtsBuilder {
    static func buildExpression(_ expression: ArtsTab) -> [ArtsTab] {
        [expression]
    }
    
    static func buildBlock(_ components: [ArtsTab]...) -> [ArtsTab] {
        components.flatMap { $0 }
    }
    
    static func buildOptional(_ component: [ArtsTab]?) -> [ArtsTab] {
        component ?? []
    }
    static func buildEither(first component: [ArtsTab]) -> [ArtsTab] {
        component
    }
    static func buildEither(second component: [ArtsTab]) -> [ArtsTab] {
        component
    }
    
    static func buildArray(_ components: [[ArtsTab]]) -> [ArtsTab] {
        components.flatMap { $0 }
    }
}

@resultBuilder
struct ArtsItemBuilder {
    static func buildExpression(_ expression: ArtsItem) -> [ArtsItem] {
        [expression]
    }
    
    static func buildBlock(_ components: [ArtsItem]...) -> [ArtsItem] {
        components.flatMap { $0 }
    }
    
    static func buildOptional(_ component: [ArtsItem]?) -> [ArtsItem] {
        component ?? []
    }
    static func buildEither(first component: [ArtsItem]) -> [ArtsItem] {
        component
    }
    static func buildEither(second component: [ArtsItem]) -> [ArtsItem] {
        component
    }
    
    static func buildArray(_ components: [[ArtsItem]]) -> [ArtsItem] {
        components.flatMap { $0 }
    }
}

struct ArtsTab: Identifiable, Hashable, Equatable {
    let id: String
    var tabName: LocalizedStringResource
    var content: [ArtsItem]
}
extension ArtsTab {
    init(id: String, name: LocalizedStringResource, @ArtsItemBuilder content: () -> [ArtsItem]) {
        self.id = id
        self.tabName = name
        self.content = content()
    }
}

struct ArtsItem: Hashable, Equatable {
    let id = UUID()
    var title: LocalizedStringResource
    var url: URL
    var expectedRatio: CGFloat = 3.0
}

// MARK: DetailArtsSection
struct DetailArtsSection: View {
    var information: [ArtsTab]
    @State var tab: String? = nil
#if os(macOS)
    @State private var previewController = PreviewController()
#endif
    @State var showQuickLook = false
    @State var quickLookOnFocusItem: URL? = nil
    @State var hiddenItems: [UUID] = []
    
    let itemMinimumWidth: CGFloat = 280
    let itemMaximumWidth: CGFloat = 320
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if let tab, let tabContent = information.first(where: {$0.id == tab}) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: itemMinimumWidth, maximum: itemMaximumWidth))]) {
                            ForEach(tabContent.content, id: \.self) { item in
                                if !hiddenItems.contains(item.id) {
                                    Button(action: {
#if os(iOS)
                                        quickLookOnFocusItem = item.url
                                        showQuickLook = true
#else
                                        // Build visible items and open Quick Look at the tapped item
                                        let visibleItems = tabContent.content.filter { !hiddenItems.contains($0.id) }
                                        previewController.fileURLs = visibleItems.map(\.url)
                                        if let selectedIndex = visibleItems.firstIndex(where: { $0.id == item.id }) {
                                            previewController.showPanel(startingAt: selectedIndex)
                                        } else {
                                            previewController.showPanel()
                                        }
#endif
                                    }, label: {
                                        CustomGroupBox {
                                            VStack {
                                                Spacer(minLength: 0)
                                                WebImage(url: item.url) { image in
                                                    image
                                                        .resizable()
                                                        .antialiased(true)
                                                        .scaledToFit()
                                                } placeholder: {
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(getPlaceholderColor())
                                                        .aspectRatio(3, contentMode: .fit)
                                                }
                                                .interpolation(.high)
                                                .onFailure(perform: { _ in
                                                    hiddenItems.append(item.id)
                                                })
                                                
                                                Text(item.title)
                                                    .multilineTextAlignment(.center)
                                                Spacer(minLength: 0)
                                            }
                                        }
                                    })
                                    .buttonStyle(.plain)
                                }
                                //                                .hidden()
                            }
                        }
                    } else {
                        DetailUnavailableView(title: "Details.arts.unavailable", symbol: "photo.on.rectangle.angled")
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.arts")
                        .font(.title2)
                        .bold()
                    //                    if information.count > 1 {
                    DetailSectionOptionPicker(selection: $tab, options: information.map(\.id), labels: information.reduce(into: [String?: String]()) { $0.updateValue(String(localized: $1.tabName), forKey: $1.id) })
                    //                    }
                    Spacer()
                }
                .frame(maxWidth: 615)
            })
        }
        .onAppear {
            if tab == nil {
                tab = information.first!.id
            }
        }
        .sheet(isPresented: $showQuickLook, content: {
#if os(iOS)
            QuickLookPreview(url: quickLookOnFocusItem!)
#endif
        })
    }
}
extension DetailArtsSection {
    init(@ArtsBuilder content: () -> [ArtsTab]) {
        self.information = content()
    }
}
