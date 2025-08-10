//===---*- Greatdori! -*---------------------------------------------------===//
//
// ImageViewer.swift
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

extension WebImage {
    func inspectable() -> some View {
        ModifiedContent(content: self, modifier: ImageInspectableModifier(image: self))
    }
}
private struct ImageInspectableModifier<V: View>: ViewModifier {
    var image: WebImage<V>
    @State var isInspectorPresented = false
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isInspectorPresented) {
                image
                    .scaledToFit()
                    .interactiveFrameTransformable()
            }
            .onTapGesture {
                isInspectorPresented = true
            }
    }
}

extension View {
    func interactiveFrameTransformable() -> some View {
        ModifiedContent(content: self, modifier: Zoomable())
    }
}
private struct Zoomable: ViewModifier {
    @State var scale: CGFloat = 1.0
    @State var offset = CGSize.zero
    @State var lastOffset = CGSize.zero
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .focusable()
            .digitalCrownRotation($scale, from: 0.5, through: .infinity, by: 0.02, sensitivity: .low, isHapticFeedbackEnabled: false)
            .scrollIndicators(.never)
            .offset(x: offset.width, y: offset.height)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = CGSize(width: gesture.translation.width + lastOffset.width, height: gesture.translation.height + lastOffset.height)
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            .onDisappear {
                offset = CGSize.zero
                lastOffset = CGSize.zero
            }
            .onChange(of: scale) {
                if scale < 2.0 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        offset = CGSize.zero
                        lastOffset = CGSize.zero
                    }
                }
            }
    }
}
