//===---*- Greatdori! -*---------------------------------------------------===//
//
// NewsDetailsView.swift
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
import MarkdownUI
import SwiftUI


struct NewsDetailView: View {
    var id: Int
    var title: String
    @State var information: DoriAPI.News.Item? = nil
    @State var informationIsLoading = true
    init(previewNews: DoriAPI.News.PreviewItem) {
        self.id = previewNews.id
        self.title = previewNews.title
    }
    init(id: Int, title: String = String(localized: "News")) {
        self.id = id
        self.title = title
    }
    
    
    let newsDebugContent = """
This is a comprehensive patch note for asset patch `9.2.0.180` (from `9.2.0.170`)

## Assets

New assets added:

- ![Placeholder](greatdori://rich-content/event/1)
- ![Placeholder](greatdori://rich-content/event/11)
- ![Placeholder](greatdori://rich-content/event/12)
- ![Placeholder](greatdori://rich-content/event/111)
- ![Placeholder](greatdori://rich-content/event/159)
- ![Placeholder](greatdori://rich-content/event/195)
- ![Placeholder](greatdori://rich-content/event/222)
"""
    
    var body: some View {
        Group {
            if let information {
                ScrollView {
                    Markdown(newsDebugContent)
                        .markdownImageProvider(.greatdoriRichContentProvider)
                    
                    
                    //                    RichContentView(information.content.forRichRendering)
                    //                    Text("\(information)")
                    //                        .searchSelection()
                    //                        .textSelection(.enabled)
                }
            } else {
                if informationIsLoading {
                    ExtendedConstraints {
                        ProgressView()
                    }
                } else {
                    ExtendedConstraints {
                        ContentUnavailableView("News.unavailable", systemImage: "newspaper", description: Text("News.unavailable.description"))
                            .onTapGesture {
                                Task {
                                    await getInformation()
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(title)
        .onAppear {
            Task {
                await getInformation()
            }
        }
    }
    
    private func getInformation() async {
        informationIsLoading = true
        //        informationLoadPromise?.cancel()
        withDoriCache(id: "NewsDetail_\(id)") {
            await DoriAPI.News.Item(id: id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
            }
            informationIsLoading = false
        }
    }
}

struct GreatdoriRichContentProvider: ImageProvider {
    let validContentSources = ["event"]
    func makeImage(url: URL?) -> some View {
        if let richContentID = extractRichContentIDFromPath(url), validContentSources.contains(richContentID.0) {
            GreatdoriRichContentRenderer(richContentID: richContentID)
        } else {
            // Normal Image Renderer
            // Editable
            DefaultImageProvider().makeImage(url: url)
        }
    }
    
    func extractRichContentIDFromPath(_ url: URL?) -> (String, Int)? {
        guard url != nil else { return nil }
        if url!.absoluteString.hasPrefix("greatdori://rich-content/") {
            let path = url!.absoluteString.dropFirst("greatdori://rich-content/".count)
            let spliitedPath = path.split(separator: "/")
            
            guard spliitedPath.count >= 2 else { return nil }
            guard Int(spliitedPath[1]) != nil else { return nil }
            
            return (String(spliitedPath[0]), Int(spliitedPath[1])!)
        } else {
            return nil
        }
    }
    
    private struct GreatdoriRichContentRenderer: View {
        var richContentID: (String, Int)
        @State var information: Any? = nil
        var body: some View {
            Group {
                if let information {
                    switch richContentID.0 {
                    case "event":
                        EventInfo(information as! Event)
                    default:
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ProgressView()
                }
            }
            .padding(5)
            .onAppear {
                Task {
                    switch richContentID.0 {
                    case "event":
                        information = await Event(id: richContentID.1)
                    default:
                        information = 0
                    }
                }
            }
        }
    }
}

extension ImageProvider where Self == GreatdoriRichContentProvider {
    static var greatdoriRichContentProvider: Self {
        .init()
    }
}

