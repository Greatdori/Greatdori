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
                      Content: View,
                      SwitcherDestination: View>: View where Information.ID == Int, PreviewInformation.ID == Int {
    var titleKey: LocalizedStringResource
    var previewList: [PreviewInformation]?
    var initialID: Int
    var updateInformation: @Sendable (Int) async -> Information?
    var makeContent: (Information) -> Content
    var makeSwitcherDestination: () -> SwitcherDestination
    var unavailablePrompt: LocalizedStringResource
    
    init(
        _ titleKey: LocalizedStringResource,
        previewList: [PreviewInformation]?,
        initialID: Int,
        @ViewBuilder content: @escaping (Information) -> Content,
        @ViewBuilder switcherDestination: @escaping () -> SwitcherDestination
    ) where Information: GettableByID, PreviewInformation: ExtendedTypeConvertible, PreviewInformation.ExtendedType == Information {
        self.init(titleKey, previewList: previewList, initialID: initialID, updateInformation: {
            await PreviewInformation.ExtendedType.init(id: $0)
        }, content: content, switcherDestination: switcherDestination)
    }
    init(
        _ titleKey: LocalizedStringResource,
        forType infoType: Information.Type,
        previewList: [PreviewInformation]?,
        initialID: Int,
        @ViewBuilder content: @escaping (Information) -> Content,
        @ViewBuilder switcherDestination: @escaping () -> SwitcherDestination
    ) where Information: GettableByID {
        self.init(titleKey, previewList: previewList, initialID: initialID, updateInformation: {
            await infoType.init(id: $0)
        }, content: content, switcherDestination: switcherDestination)
    }
    init(
        _ titleKey: LocalizedStringResource,
        previewList: [PreviewInformation]?,
        initialID: Int,
        updateInformation: @Sendable @escaping (_ id: Int) async -> Information?,
        @ViewBuilder content: @escaping (Information) -> Content,
        @ViewBuilder switcherDestination: @escaping () -> SwitcherDestination
    ) {
        self.titleKey = titleKey
        self.previewList = previewList
        self.initialID = initialID
        self.updateInformation = updateInformation
        self.makeContent = content
        self.makeSwitcherDestination = switcherDestination
        self.unavailablePrompt = "Content.unavailable.\(String(localized: titleKey))"
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
                            ContentUnavailableView(unavailablePrompt, systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
                        }
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(Text(information?.title.forPreferredLocale() ?? "\(isMACOS ? String(localized: titleKey) : "")"))
        #if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.title.forPreferredLocale() != nil ? "#\(currentID)" : "")
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
                DetailsIDSwitcher(currentID: $currentID, allIDs: allPreviewIDs, destination: makeSwitcherDestination)
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
                    Spacer(minLength: 0)
                    content
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

enum SummaryLayout: Hashable {
    case horizontal
    case vertical(hidesDetail: Bool = false)
    
    var axis: Axis {
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

@MainActor let verticalAndHorizontalLayouts: [(LocalizedStringKey, String, SummaryLayout)] = [("Filter.view.list", "list.bullet", SummaryLayout.horizontal), ("Filter.view.grid", "square.grid.2x2", SummaryLayout.vertical(hidesDetail: false))]
@MainActor let bannerLayouts: [(LocalizedStringKey, String, Bool)] = [("Filter.view.banner-and-details", "text.below.rectangle", true), ("Filter.view.banner-only", "rectangle.grid.1x2", false)]

struct SearchViewBase<Element: Sendable & Hashable & DoriCacheable & DoriFilterable & DoriSortable & DoriSearchable, Layout, LayoutPicker: View, Container: View, Content: View, Destination: View>: View {
    var titleKey: LocalizedStringResource
    var updateList: @Sendable () async -> [Element]?
    var makeLayoutPicker: (Binding<Layout>) -> LayoutPicker
    var makeContainer: (Layout, [Element], AnyView, @escaping (Element) -> AnyView) -> Container
    var makeSomeContent: (Layout, Element) -> Content
    var makeDestination: (Element, [Element]) -> Destination
    @State var currentLayout: Layout
    
    var unavailablePrompt: LocalizedStringResource
    var unavailableSystemImage: String = "bolt.horizontal.fill"
    var searchPlaceholder: LocalizedStringResource
    var getResultCountDescription: ((Int) -> LocalizedStringResource)?

    init(
        _ titleKey: LocalizedStringResource,
        forType type: Element.Type,
        initialLayout: Layout,
        layoutOptions: [(LocalizedStringKey, String, Layout)],
        @ViewBuilder container: @escaping (_ layout: Layout, _ elements: [Element], _ content: AnyView, _ eachContent: @escaping (Element) -> AnyView) -> Container,
        @ViewBuilder eachContent: @escaping (_ layout: Layout, _ element: Element) -> Content,
        @ViewBuilder destination: @escaping (_ element: Element, _ list: [Element]) -> Destination
    ) where Element: ListGettable, Layout: Hashable, LayoutPicker == Greatdori.LayoutPicker<Layout> {
        self.init(
            titleKey,
            forType: type,
            initialLayout: initialLayout,
            layoutPicker: { layout in
                Greatdori.LayoutPicker(selection: layout, options: layoutOptions)
            },
            container: container,
            eachContent: eachContent,
            destination: destination
        )
    }
    init(
        _ titleKey: LocalizedStringResource,
        initialLayout: Layout,
        updateList: @Sendable @escaping () async -> [Element]?,
        layoutOptions: [(LocalizedStringKey, String, Layout)],
        @ViewBuilder container: @escaping (_ layout: Layout, _ elements: [Element], _ content: AnyView, _ eachContent: @escaping (Element) -> AnyView) -> Container,
        @ViewBuilder eachContent: @escaping (_ layout: Layout, _ element: Element) -> Content,
        @ViewBuilder destination: @escaping (_ element: Element, _ list: [Element]) -> Destination
    ) where Layout: Hashable, LayoutPicker == Greatdori.LayoutPicker<Layout> {
        self.init(
            titleKey,
            initialLayout: initialLayout,
            updateList: updateList,
            layoutPicker: { layout in
                Greatdori.LayoutPicker(selection: layout, options: layoutOptions)
            },
            container: container,
            eachContent: eachContent,
            destination: destination
        )
    }
    init(
        _ titleKey: LocalizedStringResource,
        forType _: Element.Type,
        initialLayout: Layout,
        @ViewBuilder layoutPicker: @escaping (Binding<Layout>) -> LayoutPicker,
        @ViewBuilder container: @escaping (_ layout: Layout, _ elements: [Element], _ content: AnyView, _ eachContent: @escaping (Element) -> AnyView) -> Container,
        @ViewBuilder eachContent: @escaping (_ layout: Layout, _ element: Element) -> Content,
        @ViewBuilder destination: @escaping (_ element: Element, _ list: [Element]) -> Destination
    ) where Element: ListGettable {
        self.init(
            titleKey,
            initialLayout: initialLayout,
            updateList: Element.all,
            layoutPicker: layoutPicker,
            container: container,
            eachContent: eachContent,
            destination: destination
        )
    }
    init(
        _ titleKey: LocalizedStringResource,
        initialLayout: Layout,
        updateList: @Sendable @escaping () async -> [Element]?,
        @ViewBuilder layoutPicker: @escaping (Binding<Layout>) -> LayoutPicker,
        @ViewBuilder container: @escaping (_ layout: Layout, _ elements: [Element], _ content: AnyView, _ eachContent: @escaping (Element) -> AnyView) -> Container,
        @ViewBuilder eachContent: @escaping (_ layout: Layout, _ element: Element) -> Content,
        @ViewBuilder destination: @escaping (_ element: Element, _ list: [Element]) -> Destination
    ) {
        self.titleKey = titleKey
        self.updateList = updateList
        self.makeLayoutPicker = layoutPicker
        self.makeContainer = container
        self.makeSomeContent = eachContent
        self.makeDestination = destination
        self._currentLayout = .init(initialValue: initialLayout)
        self.unavailablePrompt = "Search.unavailable.\(String(localized: titleKey))"
        self.searchPlaceholder = "Search.prompt.\(String(localized: titleKey))"
    }
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var navigationAnimationNamespace
    @State private var filter = DoriFrontend.Filter()
    @State private var sorter = DoriFrontend.Sorter(keyword: .releaseDate(in: .jp), direction: .descending)
    @State private var elements: [Element]?
    @State private var searchedElements: [Element]?
    @State private var infoIsAvailable = true
    @State private var searchedText = ""
    @State private var showFilterSheet = false
    @State private var presentingElement: Element?
    
    var body: some View {
        Group {
            Group {
                if let resultElements = searchedElements ?? elements {
                    Group {
                        if !resultElements.isEmpty {
                            ScrollView {
                                HStack {
                                    Spacer(minLength: 0)
                                    makeContainer(currentLayout, resultElements,
                                        AnyView(
                                            ForEach(resultElements, id: \.self) { element in
                                                Button(action: {
                                                    showFilterSheet = false
                                                    presentingElement = element
                                                }, label: {
                                                    makeSomeContent(currentLayout, element)
                                                        .highlightKeyword($searchedText)
                                                })
                                                .buttonStyle(.plain)
                                                .wrapIf(true) { content in
                                                    if #available(iOS 18.0, macOS 15.0, *) {
                                                        content
                                                            .matchedTransitionSource(id: element.hashValue, in: navigationAnimationNamespace)
                                                    } else {
                                                        content
                                                    }
                                                }
                                            }
                                        )
                                    ) { element in
                                        AnyView(
                                            Button(action: {
                                                showFilterSheet = false
                                                presentingElement = element
                                            }, label: {
                                                makeSomeContent(currentLayout, element)
                                                    .highlightKeyword($searchedText)
                                            })
                                            .buttonStyle(.plain)
                                            .wrapIf(true) { content in
                                                if #available(iOS 18.0, macOS 15.0, *) {
                                                    content
                                                        .matchedTransitionSource(id: element.hashValue, in: navigationAnimationNamespace)
                                                } else {
                                                    content
                                                }
                                            }
                                        )
                                    }
                                    .padding(.horizontal)
                                    Spacer(minLength: 0)
                                }
                            }
                            .geometryGroup()
                            .navigationDestination(item: $presentingElement) { element in
                                makeDestination(element, elements ?? [])
#if !os(macOS)
                                    .wrapIf(true, in: { content in
                                        if #available(iOS 18.0, *) {
                                            content
                                                .navigationTransition(.zoom(sourceID: element.hashValue, in: navigationAnimationNamespace))
                                        } else {
                                            content
                                        }
                                    })
                                #endif
                            }
                        } else {
                            ContentUnavailableView("Search.no-results", systemImage: "magnifyingglass", description: Text("Search.no-results.description"))
                        }
                    }
                    .onSubmit {
                        if let elements {
                            searchedElements = elements.search(for: searchedText)
                        }
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
                        }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView(unavailablePrompt, systemImage: unavailableSystemImage, description: Text("Search.unavailable.description"))
                                .onTapGesture {
                                    Task {
                                        await getList()
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $searchedText, prompt: searchPlaceholder)
            .navigationTitle(titleKey)
            .wrapIf(searchedElements != nil, in: { content in
                if #available(iOS 26.0, *) {
                    content.navigationSubtitle((searchedText.isEmpty && !filter.isFiltered) ? (getResultCountDescription?(searchedElements!.count) ?? "Search.item.\(searchedElements!.count)") :  "Search.result.\(searchedElements!.count)")
                } else {
                    content
                }
            })
            .toolbar {
                ToolbarItem {
                    makeLayoutPicker($currentLayout)
                }
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                ToolbarItemGroup {
                    FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: PreviewCard.applicableSortingTypes, hasEndingDate: false)
                }
            }
            .onDisappear {
                showFilterSheet = false
            }
        }
        .withSystemBackground()
        .inspector(isPresented: $showFilterSheet) {
            FilterView(filter: $filter, includingKeys: Set(Element.applicableFilteringKeys))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
        .withSystemBackground() // This modifier MUST be placed BOTH before
                                // and after `inspector` to make it work as expected
        .task {
            await getList()
        }
        .onChange(of: filter) {
            if let elements {
                searchedElements = elements.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: sorter) {
            if let elements {
                searchedElements = elements.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: searchedText, {
            if let elements {
                searchedElements = elements.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        })
    }
    
    func getList() async {
        infoIsAvailable = true
        withDoriCache(id: "\(titleKey.key)List_\(filter.identity)", trait: .realTime) {
            await updateList()
        }.onUpdate {
            if let cards = $0 {
                self.elements = cards.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending))
                searchedElements = cards.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            } else {
                infoIsAvailable = false
            }
        }
    }
}
extension SearchViewBase {
    func contentUnavailableImage(systemName: String) -> Self {
        var mutable = self
        mutable.unavailableSystemImage = systemName
        return mutable
    }
    func resultCountDescription(content: ((Int) -> LocalizedStringResource)?) -> Self {
        var mutable = self
        mutable.getResultCountDescription = content
        return mutable
    }
}
