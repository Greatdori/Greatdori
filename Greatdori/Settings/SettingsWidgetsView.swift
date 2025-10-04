//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsWidgetsView.swift
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

import Combine
import DoriKit
import SwiftUI
import WidgetKit
@_spi(Advanced) import SwiftUIIntrospect

struct SettingsWidgetsView: View {
    @State var allCollections = CardCollectionManager.shared.allCollections
    var body: some View {
#if os(iOS)
        Section("Settings.widgets") {
            NavigationLink(destination: {
                List {
                    SettingsWidgetsCollectionView()
                }
                .navigationTitle("Settings.widgets.collections")
            }, label: {
                HStack {
                    Text("Settings.widgets.collections")
                    Spacer()
                    if !allCollections.isEmpty {
                        Text("\(allCollections.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            })
        }
        .onAppear {
            // Refresh every time the view appears.
            allCollections = CardCollectionManager.shared.allCollections
        }
#else
        SettingsWidgetsCollectionView()
            .navigationTitle("Settings.widgets")
#endif
    }
}


struct SettingsWidgetsCollectionView: View {
    @AppStorage("hideCollectionNameWhileSharing") var hideCollectionNameWhileSharing = false
    
    @State var builtinCollections = CardCollectionManager.shared.builtinCollections
    @State var userCollections = CardCollectionManager.shared.userCollections
    
    @State var destinationCollection: CardCollectionManager.Collection? = nil
    @State var showDestination = false
    @State var newCollectionSheetIsDisplaying = false // macOS only
    @State var newCollectionInput = ""
    @State var newCollectionIsImporting = false
    #if os(iOS)
    @State var currentViewController: UIViewController!
    #endif
    var body: some View {
        Group {
            Section(content: {
                if !userCollections.isEmpty {
                    ForEach(userCollections, id: \.self) { item in
                        Button(action: {
                            destinationCollection = item
                            showDestination = true
                        }, label: {
                            HStack {
                                Text(item.name)
                                Spacer()
                                if item.cards.count > 0 {
                                    Text("\(item.cards.count)")
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.forward")
                                    .foregroundStyle(.tertiary)
                                    .font(.footnote)
                                    .bold()
                            }
                            .contentShape(Rectangle())
                        })
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive, action: {
                                CardCollectionManager.shared.remove(at: userCollections.firstIndex{ $0.name == item.name }!)
                                userCollections = CardCollectionManager.shared.userCollections
                            }, label: {
                                Label("Settings.widgets.collections.user.delete", systemImage: "trash")
                            })
                            if let duplicationName = CardCollectionManager.shared.duplicationName(item.name) {
                                Button(action: {
                                    CardCollectionManager.shared.insert(CardCollectionManager.Collection(name: duplicationName, cards: item.cards), at: userCollections.firstIndex{ $0.name == item.name }!+1)
                                    userCollections = CardCollectionManager.shared.userCollections
                                }, label: {
                                    Label("Settings.widgets.collections.user.duplicate", systemImage: "plus.square.on.square")
                                })
                            }
                        }
                    }
                    .onMove { from, to in
                        CardCollectionManager.shared.move(fromOffsets: from, toOffset: to)
                        userCollections = CardCollectionManager.shared.userCollections
                    }
                } else {
                    Text("Settings.widgets.collections.user.empty")
                    //                        .bold()
                        .foregroundStyle(.secondary)
                }
                if !newCollectionIsImporting {
#if os(iOS)
                    Button(action: {
                        // We use `UIAlertController` for iOS to workaround
                        // some bugs about the alert presented by SwiftUI
                        let controller = UIAlertController(
                            title: .init(localized: "Settings.widgets.collections.user.add.alert.title"),
                            message: .init(localized: "Settings.widgets.collections.user.add.alert.message"),
                            preferredStyle: .alert
                        )
                        var alertTextField: UITextField!
                        controller.addTextField { textField in
                            alertTextField = textField
                            textField.placeholder = .init(localized: "Settings.widgets.collections.user.add.alert.prompt")
                        }
                        controller.addAction(.init(title: .init(localized: "Settings.widgets.collections.user.add.alert.cancel"), style: .cancel))
                        let confirmAction = UIAlertAction(
                            title: .init(localized: "Settings.widgets.collections.user.add.alert.create"),
                            style: .default) { _ in
                                guard let newTitle = alertTextField.text else { return }
                                if let decodeResult = decodeCollection(newTitle) {
                                    Task {
                                        newCollectionIsImporting = true
                                        CardCollectionManager.shared.append(await decodeResult.toCollectionManagerStructure())
                                        newCollectionIsImporting = false
                                    }
                                } else if CardCollectionManager.shared.nameIsAvailable(newTitle) {
                                    CardCollectionManager.shared.append(CardCollectionManager.Collection(name: newTitle, cards: []))
                                }
                            }
                        controller.addAction(confirmAction)
                        controller.preferredAction = confirmAction
                        NotificationCenter.default.addObserver(
                            forName: UITextField.textDidChangeNotification,
                            object: alertTextField,
                            queue: .main
                        ) { notifiction in
                            DispatchQueue.main.async {
                                guard let newTitle = alertTextField.text else { return }
                                confirmAction.isEnabled = CardCollectionManager.shared.nameIsAvailable(newTitle) || decodeCollection(newTitle) != nil
                                if decodeCollection(newTitle) != nil {
                                    confirmAction.setValue(String(localized: "Settings.widgets.collections.user.add.alert.import"), forKey: "title")
                                } else {
                                    confirmAction.setValue(String(localized: "Settings.widgets.collections.user.add.alert.create"), forKey: "title")
                                }
                            }
                        }
                        currentViewController.present(controller, animated: true) {
                            // confirm action must be disabled after the alert
                            // loads, or it won't be tinted
                            confirmAction.isEnabled = false
                        }
                    }, label: {
                        Label("Settings.widgets.collections.user.add", systemImage: "plus")
                    })
                    .onAppear {
                        builtinCollections = CardCollectionManager.shared.builtinCollections
                        userCollections = CardCollectionManager.shared.userCollections
                    }
#endif
                } else {
                    HStack {
                        //                        ProgressView()
                        Text("Settings.widgets.collections.user.importing")
                            .foregroundStyle(.secondary)
                    }
                }
            }, header: {
                Text("Settings.widgets.collections.user")
            }, footer: {
#if os(macOS)
                HStack {
                    Spacer()
                    Button(action: {
                        newCollectionInput = ""
                        newCollectionSheetIsDisplaying = true
                    }, label: {
                        Label("Settings.widgets.collections.user.add", systemImage: "plus")
                    })
                    .disabled(newCollectionIsImporting)
                    .onAppear {
                        builtinCollections = CardCollectionManager.shared.builtinCollections
                        userCollections = CardCollectionManager.shared.userCollections
                    }
                }
#endif
            })
            
            Section("Settings.widgets.collections.built-in") {
                ForEach(builtinCollections, id: \.self) { item in
                    Button(action: {
                        destinationCollection = item
                        showDestination = true
                    }, label: {
                        HStack {
                            Text(item.name)
                            Spacer()
                            if item.cards.count > 0 {
                                Text("\(item.cards.count)")
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.forward")
                                .foregroundStyle(.tertiary)
                                .font(.footnote)
                                .bold()
                        }
                        .contentShape(Rectangle())
                    })
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if let duplicationName = CardCollectionManager.shared.duplicationName(item.name) {
                            Button(action: {
                                CardCollectionManager.shared.insert(CardCollectionManager.Collection(name: duplicationName, cards: item.cards), at: userCollections.count)
                                userCollections = CardCollectionManager.shared.userCollections
                            }, label: {
                                Label("Settings.widgets.collections.user.duplicate", systemImage: "plus.square.on.square")
                            })
                        }
                    }
                }
            }
            
            Section {
                Toggle(isOn: $hideCollectionNameWhileSharing, label: {
                    VStack(alignment: .leading) {
                        Text("Settings.widgets.collections.share-without-name")
                        Text("Settings.widgets.collections.share-without-name.description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                })
            }
        }
        .onAppear {
            userCollections = CardCollectionManager.shared.userCollections
        }
        .onChange(of: showDestination) {
            userCollections = CardCollectionManager.shared.userCollections
        }
        .onChange(of: newCollectionSheetIsDisplaying) {
            userCollections = CardCollectionManager.shared.userCollections
        }
        .onChange(of: newCollectionIsImporting) {
            if !newCollectionIsImporting {
                userCollections = CardCollectionManager.shared.userCollections
            }
        }
        .navigationDestination(isPresented: $showDestination, destination: {
            if let destinationCollection {
                SettingsWidgetsCollectionDetailsView(collectionGivenName: destinationCollection.name, isPresented: $showDestination)
            }
        })
        .alert("Settings.widgets.collections.user.add.alert.title", isPresented: $newCollectionSheetIsDisplaying, actions: {
            CollectionAddingActions(newCollectionTitle: $newCollectionInput, newCollectionIsAdding: $newCollectionIsImporting)
        }, message: {
            Text("Settings.widgets.collections.user.add.alert.message")
        })
        #if os(iOS)
        .introspect(.viewController, on: .iOS(.v17...)) { viewController in
            currentViewController = viewController
        }
        #endif
    }
    
    struct CollectionAddingActions: View {
        @Binding var newCollectionTitle: String
        @Binding var newCollectionIsAdding: Bool
        @State private var cardPreload: PreloadDescriptor<[PreviewCard]>?
        var body: some View {
            TextField("Settings.widgets.collections.user.add.alert.prompt", text: $newCollectionTitle)
            Button(action: {
                if let decodeResult = decodeCollection(newCollectionTitle) {
                    Task {
                        await withPreloaded(cardPreload) {
                            newCollectionIsAdding = true
                            CardCollectionManager.shared.append(await decodeResult.toCollectionManagerStructure())
                            newCollectionIsAdding = false
                        }
                    }
                } else if CardCollectionManager.shared.nameIsAvailable(newCollectionTitle) {
                    CardCollectionManager.shared.append(CardCollectionManager.Collection(name: newCollectionTitle, cards: []))
                    //                    userCollections = CardCollectionManager.shared.userCollections
                    //                    userIsAddingNewCollection = false
                }
            }, label: {
                if newCollectionIsAdding {
                    ProgressView()
                } else {
                    if decodeCollection(newCollectionTitle) != nil {
                        Text("Settings.widgets.collections.user.add.alert.import")
                            .onAppear {
                                if cardPreload == nil {
                                    cardPreload = preload {
                                        await PreviewCard.all()
                                    }
                                }
                            }
                    } else {
                        Text("Settings.widgets.collections.user.add.alert.create")
                    }
                }
            })
            .disabled(!CardCollectionManager.shared.nameIsAvailable(newCollectionTitle) && decodeCollection(newCollectionTitle) == nil)
            .disabled(newCollectionIsAdding)
            .keyboardShortcut(.defaultAction)
            Button(role: .cancel, action: {}, label: {
                Text("Settings.widgets.collections.user.add.alert.cancel")
            })
        }
    }
}

struct SettingsWidgetsCollectionDetailsView: View {
    @AppStorage("hideCollectionNameWhileSharing") var hideCollectionNameWhileSharing = false
    var collectionGivenName: String
    @State var collection: CardCollectionManager.Collection?
    @Binding var isPresented: Bool
    @State var collectionName: String = ""
    @State var showCollectionDeleteAlert = false
    @State var cards: [Int: Card] = [:]
    @State var layoutType: Int = 1
    @State var collectionCode: String = ""
    @State var showCollectionCodeDialog = false
    @State var showExportCheckmark = false
    @State var showCollectionEditorSheet = false
    var body: some View {
        if let collection {
            ScrollView {
                LazyVStack {
                    CustomGroupBox(cornerRadius: isMACOS ? 15 : 25) {
                        LazyVStack {
                            Group {
                                HStack {
                                    Text("Settings.widgets.collections.name")
                                        .bold()
                                    Spacer()
                                    if !collection.isBuiltIn {
                                        TextField("Settings.widgets.collections.name", text: $collectionName)
                                            .multilineTextAlignment(.trailing)
                                            .onSubmit {
                                                if CardCollectionManager.shared.nameIsAvailable(collectionName) {
                                                    CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex{$0.name == collection.name}!].name = collectionName
                                                    CardCollectionManager.shared.updateStorage()
                                                } else {
                                                    collectionName = collection.name
                                                }
                                            }
                                            .textFieldStyle(.plain)
                                    } else {
                                        Text(collectionName)
                                            .textSelection(.enabled)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            if !collection.isBuiltIn {
                                Group {
                                    Button(role: .destructive, action: {
                                        showCollectionDeleteAlert = true
                                    }, label: {
                                        HStack {
                                            Label("Settings.widgets.collections.delete", systemImage: "trash")
                                                .bold()
                                                .foregroundStyle(.red)
                                            Spacer()
                                        }
                                        .contentShape(Rectangle())
                                    })
                                    .buttonStyle(.plain)
                                    .wrapIf(!isMACOS, in: { content in
                                        content
                                            .padding(.top, 3)
                                    })
                                }
                                .alert("Settings.widgets.collections.delete.alert.title.\(collection.name)", isPresented: $showCollectionDeleteAlert, actions: {
                                    Button(role: .destructive, action: {
                                        CardCollectionManager.shared.remove(at: CardCollectionManager.shared.userCollections.firstIndex{$0.name == collectionName}!)
                                        isPresented = false
                                    }, label: {
                                        Text("Settings.widgets.collections.delete.alert.delete")
                                    })
                                    Button(role: .cancel, action: {}, label: {
                                        Text("Settings.widgets.collections.delete.alert.cancel")
                                    })
                                }, message: {
                                    Text("Settings.widgets.collections.delete.alert.message")
                                })
                            } else {
                                Group {
                                    HStack {
                                        Text("Settings.widgets.collections.is-built-in")
                                            .bold()
                                        Spacer()
                                        Text("Settings.widgets.collections.is-built-in.yes")
                                            .textSelection(.enabled)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 600)
                    
                    DetailSectionsSpacer()
                    CustomGroupBox {
                        Button(action: {
                            showCollectionEditorSheet = true
                        }, label: {
                            HStack {
                                Spacer()
                                Label("Settings.widgets.collections.edit", systemImage: "square.and.pencil")
                                    .bold()
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        })
                    }
                    ForEach(collection.cards.indices, id: \.self) { cardIndex in
                        SettingsWidgetsCollectionsItemView(collectionCard: collection.cards[cardIndex], layoutType: .constant(1))
                    }
                    if collection.cards.isEmpty {
                        CustomGroupBox {
                            HStack {
                                Spacer()
                                Text("Settings.widgets.collections.no-card")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                }
                .frame(maxWidth: 600)
                .padding()
            }
            .withSystemBackground()
            .navigationTitle(collectionName)
            .wrapIf(true, in: { content in
                if #available(iOS 26.0, macOS 26.0, *) {
                    content
                        .navigationSubtitle("Settings.widgets.collections.count.\(collection.cards.count)")
                }
            })
            .onAppear {
                collectionName = collection.name
                if !collection.isBuiltIn {
                    CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex{$0.name == collectionName}!].cards = collection.cards.sorted{ $0.id < $1.id }
                }
            }
            .toolbar {
                if !collection.cards.isEmpty {
                    ToolbarItem {
                        LayoutPicker(selection: $layoutType, options: [("Filter.view.list", "list.bullet", 1), ("Filter.view.grid", "square.grid.2x2", 2), ("Filter.view.gallery", "text.below.rectangle", 3)])
                    }
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer()
                    }
                    ToolbarItem(placement: .primaryAction, content: {
                        Button(action: {
                            collectionCode = encodeCollection(collection.toCollectionCodeStructure(hideName: hideCollectionNameWhileSharing))
                            showCollectionCodeDialog = true
                        }, label: {
                            if showExportCheckmark {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                        })
                    })
                }
            }
            .sheet(isPresented: $showCollectionEditorSheet, onDismiss: {
                self.collection = CardCollectionManager.shared.allCollections.first(where: { $0.name == collectionGivenName })!
            }, content: {
                CollectionEditorView(collection: collection)
            })
            //        .sheet(isPresented: $showCollectionEditorSheet) {
            //            CollectionEditorView(collection: collection)
            //        }
            .alert("Settings.widgets.collections.code.dialog.title", isPresented: $showCollectionCodeDialog, actions: {
                Button(action: {
                    copyStringToClipboard(collectionCode)
                    withAnimation {
                        showExportCheckmark = true
                    }
                    showCollectionCodeDialog = false
                }, label: {
                    Label("Settings.widgets.collections.code.dialog.copy", systemImage: "document.on.document")
                })
                .keyboardShortcut(.defaultAction)
                ShareLink(item: collectionCode)
                Button(role: .cancel, action: {}, label: {
                    Text("Settings.widgets.collections.code.dialog.cancel")
                })
            }, message: {
                Text("Settings.widgets.collections.code.dialog.message")
            })
            .onChange(of: showExportCheckmark) {
                if showExportCheckmark {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showExportCheckmark = false
                        }
                    }
                }
            }
        } else {
            ProgressView()
                .onAppear {
                    collection = CardCollectionManager.shared.allCollections.first(where: { $0.name == collectionGivenName })
                }
        }
    }
}


struct SettingsWidgetsCollectionsItemView: View {
    var collectionCard: CardCollectionManager.Card
    @Binding var layoutType: Int
    @State var doriCard: Card?
    @State var characterName: LocalizedData<String>? = nil
    
    let titlePlaceholder = LocalizedData(_jp: "Lorem Ipsum Dolor", en: nil, tw: nil, cn: nil, kr: nil)
    var body: some View {
        CollectionItemViewBase(layoutType == 1 ? .horizontal : .vertical(), title: doriCard?.prefix ?? titlePlaceholder) {
            if layoutType != 3 {
                HStack(spacing: 5) {
                    if let doriCard {
                        if collectionCard.isTrained {
                            CardPreviewImage(doriCard, showTrainedVersion: true)
                            // FIXME: Some cards have normal version but have no corresponding thumbnail view.
                        } else {
                            CardPreviewImage(doriCard)
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(getPlaceholderColor())
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 67, height: 67)
                    }
                }
            } else {
                if let doriCard {
                    CardCoverImage(doriCard, band: DoriCache.preCache.categorizedCharacters.first(where: { $0.value.contains(where: { $0.id == doriCard.characterID }) })?.key)
#if !os(macOS)
                        .allowsHitTesting(false)
#endif
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(getPlaceholderColor())
                        .aspectRatio(480/320, contentMode: .fit)
                }
            }
        } detail: {
            VStack(alignment: .leading) {
                if let doriCard {
                    Text(characterName?.forPreferredLocale() ?? "nil") + Text("Typography.bold-dot-seperater").bold() + Text("#\(doriCard.id)").fontDesign(.monospaced)
                    Text(collectionCard.isTrained ? "Settings.widgets.collections.card.trained" : "Settings.widgets.collections.card.normal")
                } else {
                    Text(verbatim: "Lorem Ipsum Dolor")
                        .redacted(reason: .placeholder)
                    Text(verbatim: "Lorem")
                        .redacted(reason: .placeholder)
                }
            }
            .foregroundStyle(.secondary)
            .font(isMACOS ? .body : .caption)
        } menu: {
            EmptyView()
        }
        .onAppear {
            Task {
                doriCard = await Card(id: collectionCard.id)
                
                //                    isNormalCardAvailable = await DoriURLValidator.reachability(
                //                        of: layoutType != 3 ? previewCard.thumbNormalImageURL : previewCard.coverNormalImageURL
                //
                //                    )
                characterName = DoriCache.preCache.characterDetails[doriCard!.characterID]?.characterName
            }
            
        }
        .wrapIf(doriCard == nil, in: { content in
            content
                .redacted(reason: .placeholder)
        })
    }
}


struct CollectionItemViewBase<Image: View, Detail: View, Menu: View>: View {
    var layout: SummaryLayout
    var title: LocalizedData<String>
    var shouldHightlight: Bool
    var menuLayout: Axis
    var makeImageView: () -> Image
    var makeDetailView: () -> Detail
    var makeMenuView: () -> Menu
    
    init<Source: TitleDescribable>(
        _ layout: SummaryLayout,
        source: Source,
        shouldHightlight: Bool = false,
        menuLayout: Axis = .horizontal,
        @ViewBuilder image: @escaping () -> Image,
        @ViewBuilder detail: @escaping () -> Detail,
        @ViewBuilder menu: @escaping () -> Menu
    ) {
        self.layout = layout
        self.title = source.title
        self.shouldHightlight = shouldHightlight
        self.menuLayout = menuLayout
        self.makeImageView = image
        self.makeDetailView = detail
        self.makeMenuView = menu
    }
    init(
        _ layout: SummaryLayout,
        title: LocalizedData<String>,
        shouldHightlight: Bool = false,
        menuLayout: Axis = .horizontal,
        @ViewBuilder image: @escaping () -> Image,
        @ViewBuilder detail: @escaping () -> Detail,
        @ViewBuilder menu: @escaping () -> Menu
    ) {
        self.layout = layout
        self.title = title
        self.shouldHightlight = shouldHightlight
        self.menuLayout = menuLayout
        self.makeImageView = image
        self.makeDetailView = detail
        self.makeMenuView = menu
    }
    
    var body: some View {
        CustomGroupBox(showGroupBox: layout != .vertical(hidesDetail: true), strokeLineWidth: shouldHightlight ? 3 : 0) {
            CustomStack(axis: menuLayout) {
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
                            //                            .environment(\.isCompactHidden, layout != .horizontal)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: layout == .horizontal ? .leading : .center)
                        .multilineTextAlignment(layout == .horizontal ? .leading : .center)
                    }
                    Spacer(minLength: 0)
                }
                makeMenuView()
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
