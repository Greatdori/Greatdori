//===---*- Greatdori! -*---------------------------------------------------===//
//
// StoryViewer.metal
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

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 continuableMark(float2 position, half4 color, float2 size) {
    float2 normalizedPosition = position / size;
    float2 reversedPos = 1 - normalizedPosition;
    return half4(color.r + reversedPos.y / 2.5,
                 color.g + reversedPos.y / 2.5,
                 color.b + reversedPos.y / 2.5,
                 color.a);
}
