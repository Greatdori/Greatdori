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
                            .foregroundStyle(.accent)
                    }
                }
            }
            Section {
                NavigationLink(value: NavigationPage.character) {
                    Label {
                        Text("角色")
                    } icon: {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.card) {
                    Label {
                        Text("卡牌")
                    } icon: {
                        Image(systemName: "person.text.rectangle.fill")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.costume) {
                    Label {
                        Text("服装")
                    } icon: {
                        Image(systemName: "tshirt.fill")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.event) {
                    Label {
                        Text("活动")
                    } icon: {
                        Image(systemName: "star.hexagon.fill")
                            .foregroundStyle(.accent)
                    }
                }
            } header: {
                Text("信息")
            }
        }
        .navigationTitle("Greatdori!")
    }
}
