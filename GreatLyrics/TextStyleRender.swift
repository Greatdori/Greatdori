//===---*- Greatdori! -*---------------------------------------------------===//
//
// TextStyleRender.swift
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
@_private(sourceFile: "FrontendSong.swift") import DoriKit

struct TextStyleRender: View {
    var text: String
    var style: Lyrics.Style
    @Environment(\.font) var envFont
    @Environment(\.fontResolutionContext) var envFontContext
    @State var factor: CGFloat = 14
    var body: some View {
        ZStack {
            baseText
                .wrapIfLet(style.stroke) { content, stroke in
                    ZStack {
                        ZStack {
                            content.offset(x:  stroke.width / 30 * factor, y:  stroke.width / 30 * factor)
                            content.offset(x: -stroke.width / 30 * factor, y: -stroke.width / 30 * factor)
                            content.offset(x: -stroke.width / 30 * factor, y:  stroke.width / 30 * factor)
                            content.offset(x:  stroke.width / 30 * factor, y: -stroke.width / 30 * factor)
                        }
                        .foregroundStyle(stroke.color)
                        .blur(radius: stroke.radius / 30 * factor)
                        content
                    }
                }
                .wrapIfLet(style.shadow) { content, shadow in
                    content
                        .shadow(color: shadow.color, radius: shadow.blur / 30 * factor, x: shadow.x / 30 * factor, y: shadow.y / 30 * factor)
                }
            baseText
                .wrapIf(!style.maskLines.isEmpty) { content in
                    let maskLines = style.maskLines
                    content
                        .overlay {
                            ForEach(maskLines, id: \.self) { maskLine in
                                GeometryReader { proxy in
                                    Path { path in
                                        let startAbs = CGPoint(
                                            x: maskLine.start.x * proxy.size.width,
                                            y: maskLine.start.y * proxy.size.height
                                        )
                                        let endAbs = CGPoint(
                                            x: maskLine.end.x * proxy.size.width,
                                            y: maskLine.end.y * proxy.size.height
                                        )
                                        path.move(to: startAbs)
                                        path.addLine(to: endAbs)
                                    }
                                    .stroke(maskLine.color, lineWidth: maskLine.width / 30 * factor)
                                }
                                .mask {
                                    content
                                }
                            }
                        }
                }
        }
    }
    
    var baseText: some View {
        Text(text)
            .foregroundStyle(style.color ?? Color.primary)
            .wrapIfLet(style.fontOverride) { content, fontName in
                if let envFont {
                    content
                        .font(.custom(fontName, size: envFont.resolve(in: envFontContext).pointSize))
                        .onAppear {
                            factor = envFont.resolve(in: envFontContext).pointSize
                        }
                } else {
                    content
                        .font(.custom(fontName, size: 14))
                }
            }
    }
}
