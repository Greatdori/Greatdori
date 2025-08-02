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
                NavigationLink(value: NavigationPage.gacha) {
                    Label {
                        Text("招募")
                    } icon: {
                        Image(systemName: "line.horizontal.star.fill.line.horizontal")
                            .foregroundStyle(.accent)
                    }
                }
            } header: {
                Text("信息")
            }
            Section {
                NavigationLink(value: NavigationPage.eventTracker) {
                    Label {
                        Text("活动Pt&排名追踪器")
                    } icon: {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.storyViewer) {
                    Label {
                        Text("故事浏览器")
                    } icon: {
                        Image(systemName: "text.rectangle.page")
                            .foregroundStyle(.accent)
                    }
                }
            } header: {
                Text("工具")
            }
        }
        .navigationTitle("Greatdori!")
    }
}
