//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsView.swift
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
import WidgetKit
import AuthenticationServices

struct SettingsView: View {
    @State var preferredLocale = DoriAPI.preferredLocale
    var body: some View {
        List {
            Section {
                Picker("首选服务器", selection: $preferredLocale) {
                    ForEach(DoriAPI.Locale.allCases, id: \.rawValue) { locale in
                        Text(locale.rawValue.uppercased()).tag(locale)
                    }
                }
                .onChange(of: preferredLocale) {
                    DoriAPI.preferredLocale = preferredLocale
                    DoriCache.invalidateAll()
                }
            }
            Section {
                NavigationLink(destination: { AboutView() }) {
                    Label("关于", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AboutView: View {
    var body: some View {
        List {
            Section {
                Button(action: {
                    let url = URL(string: "https://github.com/WindowsMEMZ/Greatdori")!
                    let session = ASWebAuthenticationSession(url: url, callbackURLScheme: nil) { _, _ in }
                    session.prefersEphemeralWebBrowserSession = true
                    session.start()
                }, label: {
                    HStack {
                        Text(verbatim: "GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                })
            } header: {
                Text("源代码")
            }
            Section {
                Text("App 内数据来源为 Bestdori!")
            } header: {
                Text("数据来源")
            }
            if NSLocale.current.language.languageCode!.identifier == "zh" {
                Section {
                    Button(action: {
                        let session = ASWebAuthenticationSession(
                            url: URL(string: "https://beian.miit.gov.cn")!,
                            callbackURLScheme: nil
                        ) { _, _ in }
                        session.prefersEphemeralWebBrowserSession = true
                        session.start()
                    }, label: {
                        Text(verbatim: "蜀ICP备2025125473号-17A")
                    })
                } header: {
                    Text(verbatim: "中国大陆ICP备案号")
                }
            }
        }
        .navigationTitle("关于")
    }
}
