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

import DoriKit
import SwiftUI
import WidgetKit

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
    @State var builtinCollections = CardCollectionManager.shared.builtinCollections
    @State var userCollections = CardCollectionManager.shared.userCollections
    
    @State var destinationCollection: CardCollectionManager.Collection? = nil
    @State var showDestination = false
    @State var newCollectionSheetIsDisplaying = false
    @State var newCollectionInput = ""
    @State var newCollectionIsImporting = false
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
                        newCollectionInput = ""
                        newCollectionSheetIsDisplaying = true
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
        }
        .onAppear {
            userCollections = CardCollectionManager.shared.userCollections
        }
        .onChange(of: showDestination) {
            userCollections = CardCollectionManager.shared.userCollections
        }
        .onChange(of: newCollectionSheetIsDisplaying, {
            userCollections = CardCollectionManager.shared.userCollections
        })
        .navigationDestination(isPresented: $showDestination, destination: {
            if let destinationCollection {
                SettingsWidgetsCollectionDetailsView(collection: destinationCollection, isPresented: $showDestination)
            }
        })
        .alert("Settings.widgets.collections.user.add.alert.title", isPresented: $newCollectionSheetIsDisplaying, actions: {
            CollectionAddingActions(newCollectionTitle: $newCollectionInput, newCollectionIsAdding: $newCollectionIsImporting)
        }, message: {
            Text("Settings.widgets.collections.user.add.alert.message")
        })
    }
    
    struct CollectionAddingActions: View {
        @Binding var newCollectionTitle: String
        @Binding var newCollectionIsAdding: Bool
        var body: some View {
            TextField("Settings.widgets.collections.user.add.alert.prompt", text: $newCollectionTitle)
            Button(action: {
                if let decodeResult = decodeCollection(newCollectionTitle) {
                    Task {
                        newCollectionIsAdding = true
                        CardCollectionManager.shared.append(await decodeResult.toCollectionManagerStructure())
//                        userCollections = CardCollectionManager.shared.userCollections
                        newCollectionIsAdding = false
//                        userIsAddingNewCollection = false
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
    var collection: CardCollectionManager.Collection
    @Binding var isPresented: Bool
    @State var collectionName: String = ""
    @State var showCollectionDeleteAlert = false
    @State var cards: [Int: Card] = [:]
    @State var layoutType: Int = 1
    @State var collectionCode: String = ""
    @State var showCollectionCodeDialog = false
    @State var showExportCheckmark = false
    var body: some View {
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
                                HStack {
                                    Button(role: .destructive, action: {
                                        showCollectionDeleteAlert = true
                                    }, label: {
                                        Label("Settings.widgets.collections.delete", systemImage: "trash")
                                            .bold()
                                            .foregroundStyle(.red)
                                    })
                                    .buttonStyle(.plain)
                                    Spacer()
                                }
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
                ForEach(collection.cards.indices, id: \.self) { cardIndex in
                    SettingsWidgetsCollectionsItemView(collectionCard: collection.cards[cardIndex], layoutType: .constant(1))
                }
                .frame(maxWidth: 600)
            }
            .padding()
        }
        .withSystemBackground()
        .navigationTitle(collectionName)
        .onAppear {
            collectionName = collection.name
            if !collection.isBuiltIn {
                CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex{$0.name == collectionName}!].cards = collection.cards.sorted{ $0.id < $1.id }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction, content: {
                Button(action: {
                    collectionCode = encodeCollection(collection.toCollectionCodeStructure())
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
    }
}


struct SettingsWidgetsCollectionsItemView: View {
    var collectionCard: CardCollectionManager.Card
    @Binding var layoutType: Int
    @State var doriCard: Card?
    @State var characterName: LocalizedData<String>? = nil
    
    let titlePlaceholder = LocalizedData(_jp: "Lorem Ipsum Dolor", en: nil, tw: nil, cn: nil, kr: nil)
    var body: some View {
        SummaryViewBase(layoutType == 1 ? .horizontal : .vertical(), title: doriCard?.prefix ?? titlePlaceholder) {
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
            Group {
                if let doriCard {
                    Text(characterName?.forPreferredLocale() ?? "nil") + Text("Typography.bold-dot-seperater").bold() + Text(collectionCard.isTrained ? "Settings.widgets.collections.card.trained" : "Settings.widgets.collections.card.normal")
                } else {
                    Text(verbatim: "Lorem Ipsum Dolor Sit Amet")
                        .redacted(reason: .placeholder)
                }
            }
            .foregroundStyle(.secondary)
            .font(isMACOS ? .body : .caption)
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
