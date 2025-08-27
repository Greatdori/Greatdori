//===---*- Greatdori! -*---------------------------------------------------===//
//
// ListSectionsView.swift
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

struct ListGachaView: View {
    @State var locale: DoriAPI.Locale = DoriAPI.preferredLocale
    var body: some View {
        VStack {
            HStack {
                Text("Details.gacha")
                HStack {
                    Picker(selection: $locale, content: {
                        ForEach(DoriAPI.Locale.allCases, id: \.self) { locale in
                            Text(locale.rawValue.uppercased())
                                .tag(locale)
                        }
                    }, label: {
                        Text("")
                    })
                    .labelsHidden()
                }
            }
        }
    }
}
