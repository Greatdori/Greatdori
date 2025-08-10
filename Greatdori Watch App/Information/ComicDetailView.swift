//===---*- Greatdori! -*---------------------------------------------------===//
//
// ComicDetailView.swift
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
import SDWebImageSwiftUI

struct ComicDetailView: View {
    var comic: DoriFrontend.Comic.Comic
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    Text("标题")
                        .font(.system(size: 16, weight: .medium))
                    Text(comic.title.forPreferredLocale() ?? "")
                        .font(.system(size: 14))
                        .opacity(0.6)
                }
                VStack(alignment: .leading) {
                    Text("副标题")
                        .font(.system(size: 16, weight: .medium))
                    Text(comic.subTitle.forPreferredLocale() ?? "")
                        .font(.system(size: 14))
                        .opacity(0.6)
                }
                if let type = comic.type {
                    VStack(alignment: .leading) {
                        Text("种类")
                            .font(.system(size: 16, weight: .medium))
                        Text(type.localizedString)
                            .font(.system(size: 14))
                            .opacity(0.6)
                    }
                }
                let characters = DoriCache.preCache.characterDetails.filter { comic.characterIDs.contains($0.key) }
                if !characters.isEmpty {
                    VStack(alignment: .leading) {
                        Text("角色")
                            .font(.system(size: 16, weight: .medium))
                        HStack {
                            ForEach(characters.sorted { $0.key < $1.key }, id: \.key) { (_, character) in
                                WebImage(url: character.iconImageURL)
                                    .resizable()
                                    .clipShape(Circle())
                                    .frame(width: 30, height: 30)
                            }
                        }
                    }
                }
                VStack(alignment: .leading) {
                    Text(verbatim: "ID")
                        .font(.system(size: 16, weight: .medium))
                    Text(String(comic.id))
                        .font(.system(size: 14))
                        .opacity(0.6)
                }
            }
            .listRowBackground(Color.clear)
            Section {
                if let url = comic.imageURL {
                    HStack {
                        Spacer()
                        WebImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                                .controlSize(.large)
                        }
                        .inspectable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .frame(width: screenBounds.width - 20)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())
                } else {
                    HStack {
                        Spacer()
                        Text("不可用")
                        Spacer()
                    }
                }
            } header: {
                Text("漫画")
            }
        }
        .navigationTitle(comic.title.forPreferredLocale() ?? "")
    }
}
