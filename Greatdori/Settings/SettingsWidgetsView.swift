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
#endif
    }
}


struct SettingsWidgetsCollectionView: View {
    @State var builtinCollections = CardCollectionManager.shared.builtinCollections
    @State var userCollections = CardCollectionManager.shared.userCollections
    
    @State var destinationCollection: CardCollectionManager.Collection? = nil
    @State var showDestination = false
    @State var userIsAddingNewCollection = false
    @State var newCollectionTitle = ""
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
                                Label("Settings.widget.collections.user.delete", systemImage: "trash")
                            })
                        }
                    }
                    .onMove { from, to in
                        CardCollectionManager.shared.move(fromOffsets: from, toOffset: to)
                        userCollections = CardCollectionManager.shared.userCollections
                    }
                } else {
                    Text("Settings.widget.collections.user.empty")
                        .bold()
                        .foregroundStyle(.secondary)
                }
                #if os(iOS)
                Button(action: {
                    newCollectionTitle = ""
                    userIsAddingNewCollection = true
                }, label: {
                    Label("Settings.widget.collections.user.add", systemImage: "plus")
                })
                .onAppear {
                    builtinCollections = CardCollectionManager.shared.builtinCollections
                    userCollections = CardCollectionManager.shared.userCollections
                }
                #endif
            }, header: {
                Text("Settings.widgets.collections.user")
            }, footer: {
                #if os(macOS)
                HStack {
                    Spacer()
                    Button(action: {
                        newCollectionTitle = ""
                        userIsAddingNewCollection = true
                    }, label: {
                        Label("Settings.widget.collections.user.add", systemImage: "plus")
                    })
                    .onAppear {
                        builtinCollections = CardCollectionManager.shared.builtinCollections
                        userCollections = CardCollectionManager.shared.userCollections
                    }
                }
                #endif
            })
            .alert("Settings.widget.collections.user.add.alert.title", isPresented: $userIsAddingNewCollection, actions: {
                TextField("Settings.widget.collections.user.add.alert.prompt", text: $newCollectionTitle)
                Button(action: {
                    if CardCollectionManager.shared.nameAvailable(newCollectionTitle) {
                        CardCollectionManager.shared.append(CardCollectionManager.Collection(name: newCollectionTitle, cards: []))
                        userCollections = CardCollectionManager.shared.userCollections
                        userIsAddingNewCollection = false
                    }
                }, label: {
                    Text("Settings.widget.collections.user.add.alert.create")
                    //Text("Settings.widget.collections.user.add.alert.import")
                })
                .disabled(!CardCollectionManager.shared.nameAvailable(newCollectionTitle))
//                .disabled(newCollectionTitle.isEmpty)
                .keyboardShortcut(.defaultAction)
                Button(role: .cancel, action: {}, label: {
                    Text("Settings.widget.collections.user.add.alert.cancel")
                })
            }, message: {
                Text("Settings.widget.collections.user.add.alert.message")
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
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Settings.widgets")
        .onAppear {
            userCollections = CardCollectionManager.shared.userCollections
        }
        .navigationDestination(isPresented: $showDestination, destination: {
            if let destinationCollection {
                SettingsWidgetsCollectionDetailsView(collection: destinationCollection, isPresented: $showDestination)
            }
        })
    }
}

struct SettingsWidgetsCollectionDetailsView: View {
    var collection: CardCollectionManager.Collection
    @Binding var isPresented: Bool
    @State var collectionName: String = ""
    @State var showCollectionDeleteAlert = false
    var body: some View {
        ScrollView {
            VStack {
                CustomGroupBox(cornerRadius: 25) {
                    LazyVStack {
                        Group {
                            HStack {
                                Text("Settings.widgets.collections.name")
                                    .bold()
                                Spacer()
                                TextField("Settings.widgets.collections.name", text: $collectionName)
                                    .disabled(collection.isBuiltIn)
                                    .multilineTextAlignment(.trailing)
                                    .onSubmit {
                                        if CardCollectionManager.shared.nameAvailable(collectionName) {
                                            CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex{$0.name == collection.name}!].name = collectionName
                                            CardCollectionManager.shared.updateStorage()
                                        } else {
                                            collectionName = collection.name
                                        }
                                    }
                            }
                        }
                        
                        if !collection.isBuiltIn {
                            Group {
                                Divider()
                                HStack {
                                    Button(role: .destructive, action: {
                                        showCollectionDeleteAlert = true
                                    }, label: {
                                        Label("Settings.widgets.collections.delete", systemImage: "trash")
                                    })
                                    Spacer()
                                }
                                .padding(.top, 3)
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
                        }
                    }
                }
                .frame(maxWidth: 600)
            }
            .padding()
        }
        .withSystemBackground()
        .navigationTitle(collectionName)
        .onAppear {
            collectionName = collection.name
        }
    }
}
