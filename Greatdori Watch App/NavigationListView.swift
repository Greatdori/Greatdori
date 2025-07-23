//
//  NavigationListView.swift
//  Greatdori
//
//  Created by Mark Chan on 7/22/25.
//

import SwiftUI

struct NavigationListView: View {
    @Binding var navigation: NavigationPage?
    var body: some View {
        List(selection: $navigation) {
            Section {
                NavigationLink(value: NavigationPage.home) {
                    Label {
                        Text("主页")
                    } icon: {
                        Image(_internalSystemName: "home.fill")
                            .foregroundStyle(.highlight)
                    }
                }
            }
            Section {
                NavigationLink(value: NavigationPage.character) {
                    Label {
                        Text("角色")
                    } icon: {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.highlight)
                    }
                }
            } header: {
                Text("信息")
            }
        }
        .navigationTitle("Greatdori!")
    }
}
