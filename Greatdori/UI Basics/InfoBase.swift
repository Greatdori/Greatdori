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

struct DetailViewBase<Information: Sendable & Identifiable & DoriCacheable & TitleDescribable,
                      PreviewInformation: Identifiable,
                      Content: View>: View where Information.ID == Int, PreviewInformation.ID == Int {
    var titleKey: LocalizedStringResource
    var previewList: [PreviewInformation]?
    var initialID: Int
    var updateInformation: @Sendable (Int) async -> Information?
    var makeContent: (Information) -> Content
    var unavailablePrompt: LocalizedStringResource?
    
    init(
        _ titleKey: LocalizedStringResource,
        previewList: [PreviewInformation]?,
        initialID: Int,
        @ViewBuilder content: @escaping (Information) -> Content,
    ) where Information: GettableByID, PreviewInformation: ExtendedTypeConvertible, PreviewInformation.ExtendedType == Information {
        self.init(titleKey, previewList: previewList, initialID: initialID, updateInformation: {
            await PreviewInformation.ExtendedType.init(id: $0)
        }, content: content)
    }
    init(
        _ titleKey: LocalizedStringResource,
        forType infoType: Information.Type,
        previewList: [PreviewInformation]?,
        initialID: Int,
        @ViewBuilder content: @escaping (Information) -> Content,
    ) where Information: GettableByID {
        self.init(titleKey, previewList: previewList, initialID: initialID, updateInformation: {
            await infoType.init(id: $0)
        }, content: content)
    }
    init(
        _ titleKey: LocalizedStringResource,
        previewList: [PreviewInformation]?,
        initialID: Int,
        updateInformation: @Sendable @escaping (_ id: Int) async -> Information?,
        @ViewBuilder content: @escaping (Information) -> Content,
    ) {
        self.titleKey = titleKey
        self.previewList = previewList
        self.initialID = initialID
        self.updateInformation = updateInformation
        self.makeContent = content
    }
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var currentID: Int = 0
    @State private var informationLoadPromise: DoriCache.Promise<Information?>?
    @State private var information: Information?
    @State private var infoIsAvailable = true
    @State private var showSubtitle: Bool = false
    @State private var allPreviewIDs: [Int] = []
    
    var body: some View {
        EmptyContainer {
            if let information {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack(spacing: 40) {
                            makeContent(information)
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
                            if let unavailablePrompt {
                                ContentUnavailableView(unavailablePrompt, systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
                            } else {
                                ContentUnavailableView("Content.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
                            }
                        }
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(Text(information?.title.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Event") : "")"))
        #if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.title.forPreferredLocale() ? "#\(currentID)" : "")
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
            if let previewList {
                allPreviewIDs = previewList.map { $0.id }
            } else if let ListGettableType = PreviewInformation.self as? (any (Sendable & Identifiable & ListGettable).Type) {
                // We can always assume that the ID of elements are `Int`
                // because it has been constrainted in the generic decls
                allPreviewIDs = await ListGettableType.all()?.map { $0.id as! Int } ?? []
            }
        }
        .toolbar {
            ToolbarItemGroup(content: {
                DetailsIDSwitcher(currentID: $currentID, allIDs: allPreviewIDs, destination: { EventSearchView() })
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
    
    private func getInformation(id: Int) async {
        infoIsAvailable = true
        informationLoadPromise?.cancel()
        informationLoadPromise = withDoriCache(id: "\(titleKey.key)Detail_\(id)", trait: .realTime) {
            await updateInformation(id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
            } else {
                infoIsAvailable = false
            }
        }
    }
}
extension DetailViewBase {
    func contentUnavailablePrompt(_ prompt: LocalizedStringResource?) -> Self {
        var mutable = self
        mutable.unavailablePrompt = prompt
        return mutable
    }
}

struct SummaryViewBase<Image: View, Detail: View>: View {
    var layout: SummaryLayout
    var title: LocalizedData<String>
    var makeImageView: () -> Image
    var makeDetailView: () -> Detail
    
    init<Source: TitleDescribable>(
        _ layout: SummaryLayout,
        source: Source,
        @ViewBuilder image: @escaping () -> Image,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.layout = layout
        self.title = source.title
        self.makeImageView = image
        self.makeDetailView = detail
    }
    init(
        _ layout: SummaryLayout,
        title: LocalizedData<String>,
        @ViewBuilder image: @escaping () -> Image,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.layout = layout
        self.title = title
        self.makeImageView = image
        self.makeDetailView = detail
    }
    
    var body: some View {
        CustomGroupBox(showGroupBox: layout != .vertical(hidesDetail: true)) {
            CustomStack(axis: layout.axis) {
                makeImageView()
                if layout != .vertical(hidesDetail: true) {
                    if layout != .horizontal {
                        Spacer()
                    } else {
                        Spacer()
                            .frame(maxWidth: 15)
                    }
                    
                    VStack(alignment: layout == .horizontal ? .leading : .center) {
                        HighlightableText(title.forPreferredLocale() ?? "")
                            .bold()
                            .font(!isMACOS ? .body : .title3)
                            .layoutPriority(1)
                        makeDetailView()
                            .environment(\.isCompactHidden, layout != .horizontal)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: layout == .horizontal ? .leading : .center)
                    .multilineTextAlignment(layout == .horizontal ? .leading : .center)
                }
                Spacer(minLength: 0)
            }
            .wrapIf(layout != .horizontal) { content in
                HStack {
                    Spacer()
                    content
                    Spacer()
                }
            }
        }
    }
}
enum SummaryLayout: Hashable {
    case horizontal
    case vertical(hidesDetail: Bool = false)
    
    fileprivate var axis: Axis {
        switch self {
        case .horizontal: .horizontal
        case .vertical: .vertical
        }
    }
}
extension View {
    func preferHiddenInCompactLayout() -> some View {
        modifier(_CompactHiddenModifier())
    }
    
    func highlightKeyword(_ keyword: Binding<String>?) -> some View {
        environment(\.searchedKeyword, keyword)
    }
}
private struct _CompactHiddenModifier: ViewModifier {
    @Environment(\.isCompactHidden) private var isCompactHidden: Bool
    func body(content: Content) -> some View {
        if !isCompactHidden {
            content
        }
    }
}
extension EnvironmentValues {
    @Entry fileprivate var isCompactHidden: Bool = false
    @Entry var searchedKeyword: Binding<String>? = nil
}
