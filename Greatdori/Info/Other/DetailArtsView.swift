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


struct InfoArtsTab: Identifiable {
    let id: UUID = UUID()
    var tabName: LocalizedStringResource
    var content: [InfoArtsItem]
}

struct InfoArtsItem: Identifiable {
    let id = UUID()
    var title: LocalizedStringResource
    var url: URL
}

// MARK: DetailArtsSection
struct DetailArtsSection: View {
    var information: [InfoArtsTab]
    @State var tab: UUID? = nil
#if os(macOS)
    @State private var previewController = PreviewController()
#endif
    @State var showQuickLook = false
    @State var quickLookOnFocusItem: URL? = nil
    
    let itemMinimumWidth: CGFloat = 280
    let itemMaximumWidth: CGFloat = 320
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if let tab, let tabContent = information.first(where: {$0.id == tab}) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: itemMinimumWidth, maximum: itemMaximumWidth))]) {
                            ForEach(tabContent.content, id: \.id) { item in
                                Button(action: {
#if os(iOS)
                                    quickLookOnFocusItem = item.url
                                    showQuickLook = true
#else
                                    previewController.fileURLs = tabContent.content.map((\.url))
                                    previewController.showPanel()
#endif
                                }, label: {
                                    CustomGroupBox {
                                        VStack {
                                            WebImage(url: item.url) { image in
                                                image
                                                    .resizable()
                                                    .antialiased(true)
                                                    .scaledToFit()
                                            } placeholder: {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(getPlaceholderColor())
                                            }
                                            .interpolation(.high)
                                            Text(item.title)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                })
                                .buttonStyle(.plain)
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
                    DetailSectionOptionPicker(selection: $tab, options: information.map(\.id), labels: information.reduce(into: [UUID?: String]()) { $0.updateValue(String(localized: $1.tabName), forKey: $1.id) })
                    //                    }
                    Spacer()
                }
                .frame(maxWidth: 615)
            })
        }
        .onAppear {
            if !information.isEmpty {
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
