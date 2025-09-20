//===---*- Greatdori! -*---------------------------------------------------===//
//
// InfoView.swift
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


@MainActor let allInfoDestinationItems: [InfoDestinationItem] = [
    InfoDestinationItem(
        title: "App.info.characters",
        symbol: "person.2",
        lightColor: .mint,
        destination: {CharacterSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.cards",
        symbol: "person.crop.square.on.square.angled",
        lightColor: .orange,
        destination: {GachaSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.costumes",
        symbol: "swatchpalette",
        lightColor: .blue,
        destination: {CostumeSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.events",
        symbol: "star.hexagon",
        lightColor: .green,
        destination: {EventSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.gachas",
        symbol: "line.horizontal.star.fill.line.horizontal",
        lightColor: .yellow,
        destination: {GachaSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.songs",
        symbol: "music.note",
        lightColor: .red,
        destination: {GachaSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.song-meta",
        symbol: "music.note.list",
        lightColor: .pink,
        destination: {GachaSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.miracle-ticket",
        symbol: "ticket",
        lightColor: .indigo,
        destination: {GachaSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.comics",
        symbol: "book",
        lightColor: .brown,
        destination: {GachaSearchView()}
    ),
]

struct InfoDestinationItem {
    let title: LocalizedStringKey
    let symbol: String
    let lightColor: Color
    let darkColor: Color?
    let destination: () -> AnyView
    
    init<T: View>(title: LocalizedStringKey, symbol: String, lightColor: Color, darkColor: Color? = nil, @ViewBuilder destination: @escaping () -> T) {
        self.title = title
        self.symbol = symbol
        self.lightColor = lightColor
        self.darkColor = darkColor
        self.destination = { AnyView(destination()) }
    }
}

struct InfoView: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        NavigationStack {
            ScrollView {
//                ColorPicker(selec)
                LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) {
                    ForEach(0..<allInfoDestinationItems.count, id: \.self) { itemIndex in
                        InfoViewCard(title: allInfoDestinationItems[itemIndex].title, symbol: allInfoDestinationItems[itemIndex].symbol, color: (colorScheme == .dark && allInfoDestinationItems[itemIndex].darkColor != nil) ? (allInfoDestinationItems[itemIndex].darkColor!) : (allInfoDestinationItems[itemIndex].lightColor), destination: { allInfoDestinationItems[itemIndex].destination() })
                    }
                }
                .padding()
            }
            .navigationTitle("App.info")
        }
    }
}

// MARK: InfoViewCard
struct InfoViewCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let title: LocalizedStringKey
    let symbol: String
    let color: Color
    let destination: () -> Content
    init(title: LocalizedStringKey, symbol: String, color: Color, @ViewBuilder destination: @escaping () -> Content) {
        self.title = title
        self.symbol = symbol
        self.color = color
        self.destination = destination
    }
    var body: some View {
        NavigationLink(destination: {
            destination()
        }, label: {
            ZStack {
//                RoundedRectangle(cornerRadius: 20)
//                    .foregroundStyle(.white)
//                    .opacity(0.7)
                RoundedRectangle(cornerRadius: 20)
//                    .foregroundStyle(color.gradient)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.saturation(factor: 0.9).brightness(factor: 2.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                HStack {
                    VStack(alignment: .leading) {
                        Image(systemName: symbol)
                            .font(.largeTitle)
                        Spacer()
                        Text(title)
                            .font(.title3)
                            .bold()
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(.white)
                    Spacer()
                }
                .padding()
            }
        })
    }
}
