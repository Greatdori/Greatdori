//
//  CharacterListView.swift
//  Greatdori
//
//  Created by Mark Chan on 7/23/25.
//

import SwiftUI
import DoriKit
import SDWebImageSwiftUI

struct CharacterListView: View {
    @State var characters: DoriFrontend.Character.CategorizedCharacters?
    var body: some View {
        List {
            if let characters {
                let bands = characters.keys.sorted {
                    if let lhs = $0 {
                        if let rhs = $1 {
                            lhs.id < rhs.id
                        } else {
                            true
                        }
                    } else {
                        false
                    }
                }
                ForEach(bands, id: \.?.id) { band in
                    if let band {
                        Section {
                            ForEach(characters[band]!) { character in
                                NavigationLink(destination: { CharacterDetailView(id: character.id) }) {
                                    HStack {
                                        WebImage(url: character.iconImageURL)
                                            .resizable()
                                            .clipShape(Circle())
                                            .frame(width: 30, height: 30)
                                        Text(character.characterName.forPreferredLocale() ?? "")
                                    }
                                }
                            }
                        } header: {
                            Text(band.bandName.forPreferredLocale() ?? "")
                        }
                    } else {
                        Section {
                            ForEach(characters[nil]!) { character in
                                NavigationLink(destination: { CharacterDetailView(id: character.id) }) {
                                    HStack {
                                        Text(character.characterName.forPreferredLocale() ?? "")
                                    }
                                }
                            }
                        } header: {
                            Text("其他")
                        }
                    }
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .navigationTitle("角色")
        .task {
            characters = await DoriFrontend.Character.categorizedCharacters()
        }
    }
}
