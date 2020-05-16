#version 450

layout(push_constant) uniform Push
{
    float g_csize;
    float g_bsize;
    float g_flicker;
    float g_shaker;
    float g_refltog;
    float g_reflstr;
    float g_fresnel;
    float g_reflblur;
    float gz;
    float gx;
    float gy;
    float gzr;
    float gzg;
    float gzb;
    float goxr;
    float goyr;
    float goxg;
    float goyg;
    float goxb;
    float goyb;
}params;


/*
   CRT Glass shader
      > Emulation of CRT related artifacts:
        ::glass inner+outer reflection and chromatic aberration, convergence, rolling shutter, shaking.
      > Stack just before scanlines. Works better with curved geometry modes.

   Author: Dogway
   License: Public domain
*/

#pragma parameter g_csize "Corner size" 0.0 0.0 0.07 0.01
#pragma parameter g_bsize "Border smoothness" 600.0 100.0 600.0 25.0
#pragma parameter g_flicker "Screen Flicker" 0.25 0.0 1.0 0.01
#pragma parameter g_shaker "Screen Shake" 0.03 0.0 0.5 0.01
#pragma parameter g_refltog "Reflection Toggle" 1.0 0.0 1.0 1.00
#pragma parameter g_reflstr "Refl. Brightness" 0.25 0.0 1.0 0.01
#pragma parameter g_fresnel "Refl. Fresnel" 1.0 0.0 1.0 0.10
#pragma parameter g_reflblur "Refl. Blur" 0.6 0.0 1.0 0.10
#pragma parameter gz "Zoom" 1.2 1.0 1.5 0.01
#pragma parameter gx "Shift-X" 0.0 -1.0 1.0 0.01
#pragma parameter gy "Shift-Y" -0.01 -1.0 1.0 0.01
#pragma parameter gzr "Zoom Red" 1.03 1.0 1.5 0.01
#pragma parameter gzg "Zoom Green" 1.01 1.0 1.5 0.01
#pragma parameter gzb "Zoom Blue" 1.0 1.0 1.5 0.01
#pragma parameter goxr "Shift-X Red" 0.0 -1.0 1.0 0.01
#pragma parameter goyr "Shift-Y Red" -0.01 -1.0 1.0 0.01
#pragma parameter goxg "Shift-X Green" 0.0 -1.0 1.0 0.01
#pragma parameter goyg "Shift-Y Green" -0.01 -1.0 1.0 0.01
#pragma parameter goxb "Shift-X Blue" 0.0 -1.0 1.0 0.01
#pragma parameter goyb "Shift-Y Blue" 0.0 -1.0 1.0 0.01


layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    uint FrameCount;
#include "../include/img/param_floats.h"
} global;

#include "../include/img/helper_macros.h"
#include "../include/img/white_point.h"
#define temperature global.temperature

#define reflblur params.g_reflblur

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec4 t1;
layout(location = 2) out vec4 t2;
layout(location = 3) out vec4 t3;

void main()
{
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
    float blur = abs(1. - reflblur) + 1.;
    float dx = global.SourceSize.z / blur;
    float dy = global.SourceSize.w / blur;

    t1 = vTexCoord.xxxy + vec4( -dx,    0.0,    dx, -dy);
    t2 = vTexCoord.xxxy + vec4( -dx,    0.0,    dx, 0.0);
    t3 = vTexCoord.xxxy + vec4( -dx,    0.0,    dx, dy);
}


#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec4 t1;
layout(location = 2) in vec4 t2;
layout(location = 3) in vec4 t3;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;



//  Borrowed from cgwg's crt-geom, under GPL
float corner(vec2 coord)
{
    coord *= global.OriginalSize.xy / global.SourceSize.xy;
    coord = (coord - vec2(0.5)) * 1.0 + vec2(0.5);
    coord = min(coord, vec2(1.0)-coord) * vec2(1.0, global.OutputSize.y/global.OutputSize.x);
    vec2 cdist = vec2(max(params.g_csize, max((1.0-smoothstep(100.0,600.0,params.g_bsize))*0.01,0.002)));
    coord = (cdist - min(coord,cdist));
    float dist = sqrt(dot(coord,coord));
    return clamp((cdist.x-dist)*params.g_bsize,0.0, 1.0);
}


float rand(float co, float size){
    return fract(sin(dot(co, 12.9898)) * size);
}


void main()
{

    vec2 c_dist = (vec2(0.5) * global.SourceSize.xy) / global.OutputSize.xy;
    vec2 vpos = vTexCoord * (global.OutputSize.xy / global.SourceSize.xy);

    float vert = vpos.y;
    float vert_msk = abs(1. - vert);
    float center_msk = abs(1. - (vTexCoord.x + 0.1) * global.SourceSize.x / global.OutputSize.x - c_dist.x);
    float horiz_msk = max(center_msk - 0.2, 0.0) + 0.1;

    float zoom   = fract(params.gz)/10.;

// Screen Jitter
    float shaker  = rand(      float(global.FrameCount), 43758.5453)                   * \
                    rand(      float(global.FrameCount), 4.37585453) * params.g_shaker * \
                    round(rand(float(global.FrameCount), 53.7585453) * 1.0);

    vec2 coords  = vec2(params.gx, params.gy+shaker*0.5);
    vec2 coordsr = vec2(params.goxr, params.goyr+shaker);
    vec2 coordsg = vec2(params.goxg, params.goyg+shaker);
    vec2 coordsb = vec2(params.goxb, params.goyb+shaker);

// Screen Zoom
    float cr = texture(Source, (vTexCoord.xy - c_dist) / (fract(params.gzr)/20. + 1.) + c_dist + coordsr/40.).r;
    float cg = texture(Source, (vTexCoord.xy - c_dist) / (fract(params.gzg)/20. + 1.) + c_dist + coordsg/40.).g;
    float cb = texture(Source, (vTexCoord.xy - c_dist) / (fract(params.gzb)/20. + 1.) + c_dist + coordsb/40.).b;
    vec4 color = vec4(cr,cg,cb,1.0);

    float rA = texture(Source, (t1.xw - c_dist) / (fract(params.gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rB = texture(Source, (t1.yw - c_dist) / (fract(params.gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rC = texture(Source, (t1.zw - c_dist) / (fract(params.gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rD = texture(Source, (t2.xw - c_dist) / (fract(params.gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rE = texture(Source, (t2.yw - c_dist) / (fract(params.gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rF = texture(Source, (t2.zw - c_dist) / (fract(params.gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rG = texture(Source, (t3.xw - c_dist) / (fract(params.gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rH = texture(Source, (t3.yw - c_dist) / (fract(params.gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rI = texture(Source, (t3.zw - c_dist) / (fract(params.gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;

    float gA = texture(Source, (t1.xw - c_dist) / (fract(params.gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gB = texture(Source, (t1.yw - c_dist) / (fract(params.gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gC = texture(Source, (t1.zw - c_dist) / (fract(params.gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gD = texture(Source, (t2.xw - c_dist) / (fract(params.gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gE = texture(Source, (t2.yw - c_dist) / (fract(params.gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gF = texture(Source, (t2.zw - c_dist) / (fract(params.gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gG = texture(Source, (t3.xw - c_dist) / (fract(params.gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gH = texture(Source, (t3.yw - c_dist) / (fract(params.gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gI = texture(Source, (t3.zw - c_dist) / (fract(params.gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;

    float bA = texture(Source, (t1.xw - c_dist) / (fract(params.gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bB = texture(Source, (t1.yw - c_dist) / (fract(params.gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bC = texture(Source, (t1.zw - c_dist) / (fract(params.gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bD = texture(Source, (t2.xw - c_dist) / (fract(params.gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bE = texture(Source, (t2.yw - c_dist) / (fract(params.gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bF = texture(Source, (t2.zw - c_dist) / (fract(params.gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bG = texture(Source, (t3.xw - c_dist) / (fract(params.gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bH = texture(Source, (t3.yw - c_dist) / (fract(params.gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bI = texture(Source, (t3.zw - c_dist) / (fract(params.gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;


    vec3 sumA = vec3(rA, gA, bA);
    vec3 sumB = vec3(rB, gB, bB);
    vec3 sumC = vec3(rC, gC, bC);
    vec3 sumD = vec3(rD, gD, bD);
    vec3 sumE = vec3(rE, gE, bE);
    vec3 sumF = vec3(rF, gF, bF);
    vec3 sumG = vec3(rG, gG, bG);
    vec3 sumH = vec3(rH, gH, bH);
    vec3 sumI = vec3(rI, gI, bI);

    vec3 blurred = (sumE+sumA+sumC+sumD+sumF+sumG+sumI+sumB+sumH)/9.0;


    vpos *= 1. - vpos.xy;
    float vig = vpos.x * vpos.y * 10.;
    float vig_msk = abs(1. - vig) * (center_msk * 2. + 0.3);
    vig = abs(1. - pow(vig, 0.1)) * vert_msk * (center_msk * 2. + 0.3);

    blurred = min((vig_msk + (1. - params.g_fresnel)), 1.0) * blurred;
    vig = clamp(vig * params.g_fresnel, 0.001, 1.0);
    vec3 vig_c = white_point(vec3(vig));

// Reflection in
    vec4 reflection = clamp(vec4((1. - (1. - color.rgb ) * (1. - blurred.rgb * params.g_reflstr)) / (1. + params.g_reflstr / 3.), 1.), 0.0, 1.0);

// Reflection out
    reflection = clamp(vec4(1. - (1. - reflection.rgb ) * (1. - vec3(vig_c / 3.)), 1.), 0.0, 1.0);

// Corner Size
    vpos *= (global.SourceSize.xy/global.OutputSize.xy);

// Screen Flicker
    float flicker = (params.g_flicker == 0.0) ? 1.0 : mix(1. - params.g_flicker / 10., 1.0, rand(float(global.FrameCount), 4.37585453));

    FragColor = (params.g_refltog == 0.0) ? clamp(texture(Source, vTexCoord.xy)*corner(vpos)*flicker, 0.0, 1.0) : clamp(reflection*corner(vpos)*flicker, 0.0, 1.0);
}
