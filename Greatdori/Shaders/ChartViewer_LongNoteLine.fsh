//===---*- Greatdori! -*---------------------------------------------------===//
//
// ChartViewer_LongNoteLine.fsh
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.com/LICENSE.txt for license information
// See https://greatdori.com/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

// Uniforms:
// float u_is_trailing_end;
// float u_lane_factor;

void main() {
    float transformedX;
    if (u_is_trailing_end != 0.0) {
        transformedX = (v_tex_coord.x - v_tex_coord.y) / u_lane_factor + v_tex_coord.y;
    } else {
        transformedX = (v_tex_coord.x - (1 - u_lane_factor) + v_tex_coord.y) / u_lane_factor - v_tex_coord.y;
    }
    vec2 texCoords = vec2(transformedX, v_tex_coord.y);
    vec4 texColor = texture2D(u_texture, texCoords);
    float renderFactor = step(0.0, transformedX) * step(transformedX, 1.0);
    gl_FragColor = texColor * v_color_mix * renderFactor;
}
