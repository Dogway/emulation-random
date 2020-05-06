/*
   CRT Glass shader
      >> Emulation of CRT glass chromatic aberration and inner+outer reflection

   Author: Dogway
   License: Public domain
/*

#pragma parameter g_refltog "Toggle Reflection" 1.0 0.0 1.0 1.00
#pragma parameter g_reflstr "Reflection brightness" 0.07 0.0 1.0 0.01
#pragma parameter gzr "Zoom Red" 1.0 -0.5 1.5 0.001
#pragma parameter gzg "Zoom Green" 1.0 -0.5 1.5 0.001
#pragma parameter gzb "Zoom Blue" 1.0 -0.5 1.5 0.001
#pragma parameter goxr "Shift-X Red" 0.0 -1.0 1.0 0.01
#pragma parameter goyr "Shift-Y Red" 0.0 -1.0 1.0 0.01
#pragma parameter goxg "Shift-X Green" 0.0 -1.0 1.0 0.01
#pragma parameter goyg "Shift-Y Green" 0.0 -1.0 1.0 0.01
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

void main()
{
	gl_Position = MVPMatrix * VertexCoord;
	TEX0.xy = TexCoord.xy;
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

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float g_refltog;
uniform COMPAT_PRECISION float g_reflstr;
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
#define g_reflstr 0.07
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

    vec4 color = COMPAT_TEXTURE(Source, vTexCoord);
    vec2 c_dist = (vec2(0.5) * InputSize) / TextureSize;

    vec2 coordsr = vec2(goxr, goyr);
    vec2 coordsg = vec2(goxg, goyg);
    vec2 coordsb = vec2(goxb, goyb);
    float imgColorr = COMPAT_TEXTURE(Source, (vTexCoord - c_dist) / gzr + c_dist + coordsr).r;
    float imgColorg = COMPAT_TEXTURE(Source, (vTexCoord - c_dist) / gzg + c_dist + coordsg).g;
    float imgColorb = COMPAT_TEXTURE(Source, (vTexCoord - c_dist) / gzb + c_dist + coordsb).b;

    vec3 imgColor = vec3(imgColorr, imgColorg, imgColorb);

    vec4 reflection = vec4((1. - (1. - color.rgb ) * (1. - imgColor.rgb * g_reflstr)) / (1. + g_reflstr / 3.), 1.0);
    FragColor = (g_refltog == 0.0) ? color : reflection;
}
#endif
