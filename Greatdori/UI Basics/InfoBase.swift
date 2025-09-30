//===---*- Greatdori! -*---------------------------------------------------===//
//
// InfoBase.swift
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
import DoriKit

struct DetailViewBase<Information: Sendable & Identifiable & DoriCacheable, PreviewInformation: Identifiable, Content: View, UnavailableContent: View>: View where Information.ID == Int, PreviewInformation.ID == Int {
    var titleKey: LocalizedStringResource
    var previewList: [PreviewInformation]
    var initialID: Int
    var updateInformation: @Sendable (Int) async -> Information?
    var makeContent: (Information) -> Content
    var makeUnavailableContent: () -> UnavailableContent
    var provideName: (Information) -> String?
    var makeArts: (Information) -> [ArtsTab]
    
    init(
        _ titleKey: LocalizedStringResource,
        previewList: [PreviewInformation],
        initialID: Int,
        updateInformation: @Sendable @escaping (_ id: Int) async -> Information?,
        @ViewBuilder content: @escaping (Information) -> Content,
        @ViewBuilder unavailableContent: @escaping () -> UnavailableContent,
        nameProvider: @escaping (Information) -> String?,
        @ArtsBuilder makeArts: @escaping (Information) -> [ArtsTab]
    ) {
        self.titleKey = titleKey
        self.previewList = previewList
        self.initialID = initialID
        self.updateInformation = updateInformation
        self.makeContent = content
        self.makeUnavailableContent = unavailableContent
        self.provideName = nameProvider
        self.makeArts = makeArts
    }
    
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var currentID: Int = 0
    @State var informationLoadPromise: DoriCache.Promise<Information?>?
    @State var information: Information?
    @State var infoIsAvailable = true
    @State var cardNavigationDestinationID: Int?
    @State var showSubtitle: Bool = false
    @State var allEventIDs: [Int] = []
    @State var arts: [ArtsTab] = []
    
    var body: some View {
        EmptyContainer {
            if let information {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            makeContent(information)
                            if !arts.isEmpty {
                                DetailSectionsSpacer()
                                DetailArtsSection(information: arts)
                            }
                        }
                        .padding()
                        Spacer(minLength: 0)
                    }
                }
                .scrollDisablesMultilingualTextPopover()
            } else {
                if infoIsAvailable {
                    ExtendedConstraints {
                        ProgressView()
                    }
                } else {
                    Button(action: {
                        Task {
                            await getInformation(id: currentID)
                        }
                    }, label: {
                        ExtendedConstraints {
                            makeUnavailableContent()
                        }
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(item: $cardNavigationDestinationID, destination: { id in
            Text("\(id)")
        })
        .navigationTitle(Text((information != nil ? provideName(information!) : nil) ?? "\(isMACOS ? String(localized: "Event") : "")"))
        #if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle((information != nil ? provideName(information!) : nil) != nil ? "#\(currentID)" : "")
            } else {
                content
            }
        }
        #endif
        .onChange(of: currentID) {
            Task {
                await getInformation(id: currentID)
            }
        }
        .task {
            currentID = initialID
            await getInformation(id: currentID)
            allEventIDs = previewList.map { $0.id }
        }
        .toolbar {
            ToolbarItemGroup(content: {
                DetailsIDSwitcher(currentID: $currentID, allIDs: allEventIDs, destination: { EventSearchView() })
                    .onChange(of: currentID) {
                        information = nil
                    }
                    .onAppear {
                        showSubtitle = (sizeClass == .compact)
                    }
            })
        }
        .withSystemBackground()
    }
    
    func getInformation(id: Int) async {
        infoIsAvailable = true
        informationLoadPromise?.cancel()
        informationLoadPromise = withDoriCache(id: "\(titleKey.key)Detail_\(id)", trait: .realTime) {
            await updateInformation(id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
                self.arts = makeArts(information)
            } else {
                infoIsAvailable = false
            }
        }
    }
}

extension TupleView {
    var rawMetadata: UnsafeRawPointer {
        unsafe unsafeBitCast(T.self as Any.Type, to: UnsafeRawPointer.self)
    }
}
