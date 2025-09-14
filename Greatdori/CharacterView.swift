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
import SDWebImageSwiftUI
import SwiftUI

fileprivate let bandLogoScaleFactor: CGFloat = 1.2
fileprivate let charVisualImageCornerRadius: CGFloat = 10

struct CharacterSearchView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var charactersDict: DoriFrontend.Character.CategorizedCharacters?
    @State var bandArray: [DoriAPI.Band.Band?] = []
    @State var infoIsAvailable = true
    @State var infoIsReady = false
    var body: some View {
        Group {
            if infoIsReady {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            ForEach(bandArray, id: \.self) { band in
                                if let band {
                                    WebImage(url: band.logoImageURL)
                                        .resizable()
                                        .frame(width: 160*bandLogoScaleFactor, height: 82*bandLogoScaleFactor)
//                                        .border(.red)
//                                        .scaleEffect(1.5)
                                    HStack {
                                        ForEach(charactersDict![band]!, id: \.self) { char in
                                            Group {
                                                if sizeClass == .regular {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: charVisualImageCornerRadius)
                                                            .foregroundStyle(char.color ?? .gray)
                                                        WebImage(url: char.keyVisualImageURL)
                                                            .resizable()
                                                            .scaledToFit()
                                                    }
                                                    .frame(width: 122, height: 480)
                                                } else {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: charVisualImageCornerRadius)
                                                            .foregroundStyle(char.color ?? .gray)
                                                        WebImage(url: char.keyVisualImageURL)
                                                            .resizable()
                                                            .scaledToFit()
                                                    }
//                                                    .border(.red)
//                                                    .scaledToFill()
                                                    .aspectRatio(122/480, contentMode: .fill)
                                                    
                                                }
                                            }
                                            .mask {
                                                RoundedRectangle(cornerRadius: charVisualImageCornerRadius)
                                                    .aspectRatio(122/480, contentMode: .fill)
                                                    .border(.red)
                                            }
                                            .border(.blue)
                                        }
                                    }
                                    Rectangle()
                                        .frame(width: 0, height: 20)
                                }
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal)
                }
            } else {
                if infoIsAvailable {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        Spacer()
                    }
                } else {
                    ContentUnavailableView("Character.search.unavailable", systemImage: "person.2.fill", description: Text("Search.unavailable.description"))
                        .onTapGesture {
                            Task {
                                await getCharacters()
                            }
                        }
                }
            }
        }
//        .withSystemBackground()
        .navigationTitle("Character")
        .task {
            await getCharacters()
        }
        .withSystemBackground()
    }
    
    func getCharacters() async {
        infoIsAvailable = true
        infoIsReady = false
        DoriCache.withCache(id: "CharacterList") {
            await DoriFrontend.Character.categorizedCharacters()
        }.onUpdate {
            if let characters = $0 {
                self.charactersDict = characters
                bandArray = []
                if let charactersDict {
                    for (key, _) in charactersDict {
                        bandArray.append(key)
                    }
                    bandArray.sort { ($0?.id ?? 9999) < ($1?.id ?? 9999) }
                }
                infoIsReady = true
            } else {
                infoIsAvailable = false
            }
        }
    }
}
