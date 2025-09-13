//===---*- Greatdori! -*---------------------------------------------------===//
//
// CharacterView.swift
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

struct CharacterSearchView: View {
    @State var characters: DoriFrontend.Character.CategorizedCharacters?
    @State var availability = true
    var body: some View {
        ScrollView {
            VStack {
                if let characters {
//                    ForEach(characters, id: \.self) { key, value in
//                        
//                    }
                    Text(verbatim: "TODO")
                } else {
                    if availability {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        ContentUnavailableView("Character.search.unavailable", systemImage: "person.2.fill", description: Text("Search.unavailable.description"))
                    }
                }
            }
        }
        .navigationTitle("Character")
        .task {
            await getCharacters()
        }
    }
    
    func getCharacters() async {
        availability = true
        DoriCache.withCache(id: "CharacterList") {
            await DoriFrontend.Character.categorizedCharacters()
        }.onUpdate {
            if let characters = $0 {
                self.characters = characters
            } else {
                availability = false
            }
        }
    }
}
