//
//  UnavailableView.swift
//  Greatdori
//
//  Created by Mark Chan on 7/28/25.
//

import SwiftUI

struct UnavailableView: View {
    private var text: LocalizedStringResource
    private var systemImage: String
    private var retryHandler: () -> Void
    
    init(_ text: LocalizedStringResource, systemImage: String, retryHandler: @escaping () -> Void) {
        self.text = text
        self.systemImage = systemImage
        self.retryHandler = retryHandler
    }
    init(_ text: LocalizedStringResource, systemImage: String, retryHandler: @escaping () async -> Void) {
        self.text = text
        self.systemImage = systemImage
        self.retryHandler = {
            Task {
                await retryHandler()
            }
        }
    }
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                if !systemImage.hasPrefix("_") {
                    ContentUnavailableView(text, systemImage: systemImage)
                } else {
                    ContentUnavailableView {
                        Label {
                            Text(text)
                        } icon: {
                            Image(_internalSystemName: String(systemImage.dropFirst()))
                        }
                    }
                }
                Button("重试", systemImage: "arrow.clockwise", action: retryHandler)
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .listRowBackground(Color.clear)
    }
}
