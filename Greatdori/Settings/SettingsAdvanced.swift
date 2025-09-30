//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsAdvanced.swift
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
import SDWebImageSwiftUI

#if os(iOS)
import UIKit
#endif

struct SettingsAdvancedView: View {
    @AppStorage("preferSystemVisionModel") var preferSystemVisionModel = false
    @State var subjectImageData: Data? = nil
    var body: some View {
        List {
            Section(content: {
                Toggle(isOn: $preferSystemVisionModel, label: {
                    VStack(alignment: .leading) {
                        Text("Settings.advanced.image.subject-prefer-system-model")
                        Text("Settings.advanced.image.subject-prefer-system-model.description")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                })
            }, header: {
                Text("Settings.advanced.image")
            })
            
            /*
            Section {
                HStack {
                    WebImage(url: URL(string: "https://bestdori.com/assets/jp/characters/resourceset/res022077_rip/card_after_training.png")!, content: { image in
                        image
                            .resizable()
                            .scaledToFit()
                    }, placeholder: {
                        ProgressView()
                    })
                    .interpolation(.high)
                    
                    Divider()
                    
                    if preferSystemVisionModel {
                        if let subjectImageData {
#if os(iOS)
                            if let uiImage = UIImage(data: subjectImageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                            }
#else
                            if let nsImage = NSImage(data: subjectImageData) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFit()
                            }
#endif
                        } else {
                            Label("Settings.advanced.image.subject.failure", systemImage: "exclamationmark.circle")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        WebImage(url: URL(string: "https://bestdori.com/assets/jp/characters/resourceset/res022077_rip/trim_after_training.png")!, content: { image in
                            image
                                .resizable()
                                .scaledToFit()
                        }, placeholder: {
                            ProgressView()
                        })
                        .interpolation(.high)
                    }
                }
            }
            .onAppear {
                DispatchQueue(label: "com.memz233.Greatdori.Resolve-Image-From-URL", qos: .userInitiated).async {
                    let imageData = try? Data(contentsOf: URL(string: "https://bestdori.com/assets/jp/characters/resourceset/res022077_rip/card_after_training.png")!)
                    Task {
                        if let imageData {
                            subjectImageData = await getImageSubject(imageData)
                        }
                    }
                }
            }
            */
        }
        .navigationTitle("Settings.advanced")
    }
}
