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
#else
        SettingsWidgetsCollectionView()
#endif
    }
}


struct SettingsWidgetsCollectionView: View {
    @State var builtinCollections = CardCollectionManager.shared.builtinCollections
    @State var userCollections = CardCollectionManager.shared.userCollections
    
    @State var userIsAddingNewCollection = false
    @State var newCollectionTitle = ""
    var body: some View {
        Group {
            Section("Settings.widgets.collections.user") {
                if !userCollections.isEmpty {
                    ForEach(userCollections, id: \.self) { item in
                        NavigationLink(destination: {
                            SettingsWidgetsCollectionDetailsView(collection: item)
                        }, label: {
                            HStack {
                                Text(item.name)
                                Spacer()
                                if item.cards.count > 0 {
                                    Text("\(item.cards.count)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        })
                    }
                    .onDelete { item in
                        CardCollectionManager.shared.remove(atOffsets: item)
                        userCollections = CardCollectionManager.shared.userCollections
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
            .alert("Settings.widget.collections.user.add.alert.title", isPresented: $userIsAddingNewCollection, actions: {
                TextField("Settings.widget.collections.user.add.alert.prompt", text: $newCollectionTitle)
                Button(action: {
                    if CardCollectionManager.shared.nameAvailable(newCollectionTitle) {
                        CardCollectionManager.shared.append(CardCollectionManager.Collection(name: newCollectionTitle, cards: []))
                        userCollections = CardCollectionManager.shared.userCollections
                        userIsAddingNewCollection = false
                    }
                }, label: {
                    Text("Settings.widget.collections.user.add.alert.confirm")
                })
                .disabled(!CardCollectionManager.shared.nameAvailable(newCollectionTitle))
                .disabled(newCollectionTitle.isEmpty)
//                .keyboardShortcut(.defaultAction)
                Button(role: .cancel, action: {}, label: {
                    Text("Settings.widget.collections.user.add.alert.cancel")
                })
            })
            
            
            Section("Settings.widgets.collections.built-in") {
                ForEach(builtinCollections, id: \.self) { item in
                    NavigationLink(destination: {
                        SettingsWidgetsCollectionDetailsView(collection: item)
                    }, label: {
                        HStack {
                            Text(item.name)
                            Spacer()
                            if item.cards.count > 0 {
                                Text("\(item.cards.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    })
                }
            }
        }
        .navigationTitle("Settings.widgets")
    }
}

struct SettingsWidgetsCollectionDetailsView: View {
    var collection: CardCollectionManager.Collection
    var body: some View {
        Text(verbatim: "?")
    }
}
