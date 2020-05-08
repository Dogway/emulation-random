/*
   CRT Glass shader
      >> Emulation of CRT glass chromatic aberration and inner+outer reflection
      >> Stack just before scanlines. Works better with curved geometry modes.

   Author: Dogway
   License: Public domain
*/

#pragma parameter g_refltog "Toggle Reflection" 1.0 0.0 1.0 1.00
#pragma parameter g_reflstr "Reflection brightness" 0.25 0.0 1.0 0.01
#pragma parameter g_reflblur "Reflection blur" 1.6 1.0 2.0 0.01
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

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying
#define COMPAT_ATTRIBUTE attribute
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 t1;
COMPAT_VARYING vec4 t2;
COMPAT_VARYING vec4 t3;
COMPAT_VARYING float g_reflblur;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)
#define g_reflblur 1.5

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    vec2 ps = vec2(1.0/TextureSize.x, 1.0/TextureSize.y) / g_reflblur;
    float dx = ps.x;
    float dy = ps.y;

    t1 = TEX0.xxxy + vec4(    -dx,    0.0,     dx,    -dy);
    t2 = TEX0.xxxy + vec4(    -dx,    0.0,     dx,    0.0);
    t3 = TEX0.xxxy + vec4(    -dx,    0.0,     dx,     dy);
}

#elif defined(FRAGMENT)

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out COMPAT_PRECISION vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec4 t1;
COMPAT_VARYING vec4 t2;
COMPAT_VARYING vec4 t3;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float g_refltog;
uniform COMPAT_PRECISION float g_reflstr;
uniform COMPAT_PRECISION float g_reflblur;
uniform COMPAT_PRECISION float gz;
uniform COMPAT_PRECISION float gx;
uniform COMPAT_PRECISION float gy;
uniform COMPAT_PRECISION float gzr;
uniform COMPAT_PRECISION float gzg;
uniform COMPAT_PRECISION float gzb;
uniform COMPAT_PRECISION float goxr;
uniform COMPAT_PRECISION float goyr;
uniform COMPAT_PRECISION float goxg;
uniform COMPAT_PRECISION float goyg;
uniform COMPAT_PRECISION float goxb;
uniform COMPAT_PRECISION float goyb;
#else
#define g_refltog 1.00
#define g_reflstr 0.00
#define g_reflblur 1.00
#define gz 1.0
#define gx 0.0
#define gy 0.0
#define gzr 1.0
#define gzg 1.0
#define gzb 1.0
#define goxr 0.0
#define goyr 0.0
#define goxg 0.0
#define goyg 0.0
#define goxb 0.0
#define goyb 0.0
#endif


void main()
{

    vec2 c_dist = (vec2(0.5) * InputSize) / TextureSize;
    vec2 vpos = vTexCoord * (TextureSize.xy / InputSize.xy);

    float zoom   = fract(gz)/10.;
    vec2 coords  = vec2(gx, gy);
    vec2 coordsr = vec2(goxr, goyr);
    vec2 coordsg = vec2(goxg, goyg);
    vec2 coordsb = vec2(goxb, goyb);

    float cr = COMPAT_TEXTURE(Source, (vTexCoord - c_dist) / (fract(gzr)/20. + 1.) + c_dist + coordsr/40.).r;
    float cg = COMPAT_TEXTURE(Source, (vTexCoord - c_dist) / (fract(gzg)/20. + 1.) + c_dist + coordsg/40.).g;
    float cb = COMPAT_TEXTURE(Source, (vTexCoord - c_dist) / (fract(gzb)/20. + 1.) + c_dist + coordsb/40.).b;
    vec4 color = vec4(cr,cg,cb,1.0);


    float rA = COMPAT_TEXTURE(Source, (t1.xw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rB = COMPAT_TEXTURE(Source, (t1.yw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rC = COMPAT_TEXTURE(Source, (t1.zw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rD = COMPAT_TEXTURE(Source, (t2.xw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rE = COMPAT_TEXTURE(Source, (t2.yw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rF = COMPAT_TEXTURE(Source, (t2.zw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rG = COMPAT_TEXTURE(Source, (t3.xw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rH = COMPAT_TEXTURE(Source, (t3.yw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;
    float rI = COMPAT_TEXTURE(Source, (t3.zw - c_dist) / (fract(gzr)/10. + zoom + 1.) + c_dist + (coordsr + coords)/20.).x;

    float gA = COMPAT_TEXTURE(Source, (t1.xw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gB = COMPAT_TEXTURE(Source, (t1.yw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gC = COMPAT_TEXTURE(Source, (t1.zw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gD = COMPAT_TEXTURE(Source, (t2.xw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gE = COMPAT_TEXTURE(Source, (t2.yw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gF = COMPAT_TEXTURE(Source, (t2.zw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gG = COMPAT_TEXTURE(Source, (t3.xw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gH = COMPAT_TEXTURE(Source, (t3.yw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;
    float gI = COMPAT_TEXTURE(Source, (t3.zw - c_dist) / (fract(gzg)/10. + zoom + 1.) + c_dist + (coordsg + coords)/20.).y;

    float bA = COMPAT_TEXTURE(Source, (t1.xw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bB = COMPAT_TEXTURE(Source, (t1.yw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bC = COMPAT_TEXTURE(Source, (t1.zw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bD = COMPAT_TEXTURE(Source, (t2.xw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bE = COMPAT_TEXTURE(Source, (t2.yw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bF = COMPAT_TEXTURE(Source, (t2.zw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bG = COMPAT_TEXTURE(Source, (t3.xw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bH = COMPAT_TEXTURE(Source, (t3.yw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;
    float bI = COMPAT_TEXTURE(Source, (t3.zw - c_dist) / (fract(gzb)/10. + zoom + 1.) + c_dist + (coordsb + coords)/20.).z;


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

    float vert = vpos.y;
    float vert_msk = abs(1. - vert);
    float center_msk = abs(1. - (vTexCoord.x + 0.1) * SourceSize.x / InputSize.x - c_dist.x);
    float horiz_msk = max(center_msk - 0.2, 0.0) + 0.1;

    vpos *= 1. - vpos.xy;
    float vig = vpos.x * vpos.y * 10.;
    float vig_msk = abs(1. - vig) * (center_msk * 2. + 0.3);
    vig = abs(1. - pow(vig, 0.1)) * vert_msk * (center_msk * 2. + 0.3);

    blurred = vig_msk * blurred;
    vec4 reflection = vec4((1. - (1. - color.rgb ) * (1. - blurred.rgb * g_reflstr)) / (1. + g_reflstr / 3.), 1.);
    reflection = vec4(1. - (1. - reflection.rgb ) * (1. - vec3(vig / 3.)), 1.);


    FragColor = (g_refltog == 0.0) ? COMPAT_TEXTURE(Source, vTexCoord) : reflection;
}
#endif
