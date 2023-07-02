#version 450

#include "../include/subpixel_masks.h"

layout(push_constant) uniform Push
{
    float msk_str;
    float phosphor;
} params;

// For testing the different subpixels masks
// using the updated "include" file from hunterk:
// https://forums.libretro.com/t/please-show-off-what-crt-shaders-can-do/19193/1510

#pragma parameter msk_str "mask_intensity" 1.0 0.0 1.0 0.1
#pragma parameter phosphor "phosphor_layout" 0.0 0.0 21.0 1.0


layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
    vec4 SourceSize;
    vec4 OriginalSize;
    vec4 OutputSize;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord * 1.00001;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
    vec3 col = texture(Source, vTexCoord.xy).rgb;

    vec2 xy = vTexCoord.xy * global.OutputSize.xy;
    vec3 mask = mask_weights(xy, params.msk_str, int(params.phosphor));

    FragColor = vec4(col*mask, 1.0);
}