#version 110

/*
    zfast_crt_geo - A simple, fast CRT shader.

    Copyright (C) 2017 Greg Hogan (SoltanGris42)
    Copyright (C) 2023 Jose Linares (Dogway)

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.


Notes:  This shader does scaling with a weighted linear filter for adjustable
        sharpness on the x and y axes based on the algorithm by Inigo Quilez here:
        http://http://www.iquilezles.org/www/articles/texture/texture.htm
        but modified to be somewhat sharper.  Then a scanline effect that varies
        based on pixel brighness is applied along with a monochrome aperture mask.
        This shader runs at 60fps on the Raspberry Pi 3 hardware at 2mpix/s
        resolutions (1920x1080 or 1600x1200).
*/

//For testing compilation
//#define FRAGMENT
//#define VERTEX

// Parameter lines go here:
#pragma parameter PHOSPHOR    "P22 Phosphor D93"                1.0 0.0 1.0 1.0
#pragma parameter CURVATURE   "CURVATURE"                       1.0 0.0 1.0 1.0
#pragma parameter CURVATURE_X "  Screen curvature - horizontal" 0.12 0.0 1.0 0.01
#pragma parameter CURVATURE_Y "  Screen curvature - vertical"   0.18 0.0 1.0 0.01
#pragma parameter LOWLUMSCAN  "Scanline Darkness - Low"         8.0 0.0 10.0 0.5
#pragma parameter HILUMSCAN   "Scanline Darkness - High"        0.0 0.0 50.0 1.0
#pragma parameter BRIGHTBOOST "Dark Pixel Brightness Boost"     1.5 0.5 1.5 0.05
#pragma parameter MASK_DARK   "Mask Effect Amount"              0.5 0.0 1.0 0.05
#pragma parameter MASK_FADE   "Mask/Scanline Fade"              0.9 0.0 1.0 0.05
#pragma parameter g_vstr      "Vignette Strength"               40.0 0.0 50.0 1.0
#pragma parameter g_vpower    "Vignette Power"                  0.20 0.0 0.5 0.01
#pragma parameter g_csize     "Corner Size"                     0.02 0.0 0.07 0.01
#pragma parameter g_bsize     "Border Smoothness"               150.0 100.0 600.0 25.0

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
COMPAT_VARYING float maskFade;
COMPAT_VARYING vec2 invDims;
COMPAT_VARYING vec2 scale;

vec4 _oPosition1;
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float PHOSPHOR;
uniform COMPAT_PRECISION float CURVATURE;
uniform COMPAT_PRECISION float CURVATURE_X;
uniform COMPAT_PRECISION float CURVATURE_Y;
uniform COMPAT_PRECISION float LOWLUMSCAN;
uniform COMPAT_PRECISION float HILUMSCAN;
uniform COMPAT_PRECISION float BRIGHTBOOST;
uniform COMPAT_PRECISION float MASK_DARK;
uniform COMPAT_PRECISION float MASK_FADE;
uniform COMPAT_PRECISION float g_vstr;
uniform COMPAT_PRECISION float g_vpower;
uniform COMPAT_PRECISION float g_csize;
uniform COMPAT_PRECISION float g_bsize;
#else
#define PHOSPHOR 1.0
#define CURVATURE 1.0
#define CURVATURE_X 0.12
#define CURVATURE_Y 0.18
#define LOWLUMSCAN 8.0
#define HILUMSCAN  0.0
#define BRIGHTBOOST 1.5
#define MASK_DARK 0.5
#define MASK_FADE 0.9
#define g_vstr 40.0
#define g_vpower 0.20
#define g_csize 0.02
#define g_bsize 150.0
#endif

void main()
{
    gl_Position = MVPMatrix * VertexCoord;

    TEX0.xy = TexCoord.xy*1.00001;
    maskFade = 0.3333*MASK_FADE;
    invDims = 1.0/TextureSize.xy;
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
COMPAT_VARYING float maskFade;
COMPAT_VARYING vec2 invDims;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define scale vec2(TextureSize.xy/InputSize.xy)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float PHOSPHOR;
uniform COMPAT_PRECISION float CURVATURE;
uniform COMPAT_PRECISION float CURVATURE_X;
uniform COMPAT_PRECISION float CURVATURE_Y;
uniform COMPAT_PRECISION float LOWLUMSCAN;
uniform COMPAT_PRECISION float HILUMSCAN;
uniform COMPAT_PRECISION float BRIGHTBOOST;
uniform COMPAT_PRECISION float MASK_DARK;
uniform COMPAT_PRECISION float MASK_FADE;
uniform COMPAT_PRECISION float g_vstr;
uniform COMPAT_PRECISION float g_vpower;
uniform COMPAT_PRECISION float g_csize;
uniform COMPAT_PRECISION float g_bsize;
#else
#define PHOSPHOR 1.0
#define CURVATURE 1.0
#define CURVATURE_X 0.12
#define CURVATURE_Y 0.18
#define LOWLUMSCAN 8.0
#define HILUMSCAN  0.0
#define BRIGHTBOOST 1.5
#define MASK_DARK 0.5
#define MASK_FADE 0.9
#define g_vstr 40.0
#define g_vpower 0.20
#define g_csize 0.02
#define g_bsize 150.0
#endif


// NTSC-J (D93) -> Rec709 D65 Joint Matrix (with D93 simulation)
// This is compensated (7604K) for a linearization hack (RGB*RGB and then sqrt())
const mat3 P22D93 = mat3(
     0.818379,-0.099110,-0.070670,
     0.034175, 1.027733, 0.005360,
    -0.005770, 0.036670, 1.382350);


//  Borrowed from cgwg's crt-geom, under GPL
float corner(vec2 coord) {

    coord = coord * scale;
    coord = min(coord, 1.0-coord) * vec2(1.0, OutputSize.y/OutputSize.x);
    vec2 cdist = vec2(max(g_csize, max((1.0-smoothstep(100.0,600.0,g_bsize))*0.01, 0.002)));

    coord = (cdist - min(coord,cdist));
    float dist = sqrt(dot(coord,coord));
    return clamp((cdist.x-dist)*g_bsize, 0.0, 1.0);
 }


vec2 Distort(vec2 coord) {

    vec2 CURVATURE_DISTORTION = vec2(CURVATURE_X, CURVATURE_Y);

    // Barrel distortion shrinks the display area a bit, this will allow us to counteract that.
    vec2 barrelScale = 1.0 - (0.23 * CURVATURE_DISTORTION);
    coord = (coord * scale) - 0.5;
    float rsq = coord.x * coord.x + coord.y * coord.y;
    coord += coord * (CURVATURE_DISTORTION * rsq);

    // If out of bounds, return an invalid value.
    return (coord * barrelScale + 0.5) / scale;
 }



void main()
{
    vec2 vpos = vTexCoord*scale;

    vpos *= (1.0 - vpos.xy);
    float vig = vpos.x * vpos.y * g_vstr;
    vig = min(pow(vig, g_vpower), 1.0);
    vig = g_vpower < 0.01 ? 1.0 : vig >= 0.5 ? smoothstep(0.0,1.0,vig) : vig;

    vec2 xy = CURVATURE == 1.0 ? Distort(TEX0.xy) : TEX0.xy;
    float cmask = g_csize == 0.0 ? 1.0 : corner(xy);

    // Of all the pixels that are mapped onto the texel we are
    // currently rendering, which pixel are we currently rendering?
    float ratio_scale = xy.y * TextureSize.y - 0.5;
    float uv_ratio = fract(ratio_scale);

    // Snap to the center of the underlying texel.
    float i = floor(ratio_scale) + 0.5;

    //This is just like "Quilez Scaling" but sharper
    float f = ratio_scale - i;
    COMPAT_PRECISION float Y = f*f;
    float p = (i + 4.0*Y*f)*invDims.y;
    COMPAT_PRECISION float YY = Y*Y;

    COMPAT_PRECISION float whichmask = floor(vTexCoord.x*4.0*OutputSize.x)*-0.499999;
    COMPAT_PRECISION float mask = 1.0 + float(fract(whichmask) < 0.5000) * -MASK_DARK;
    COMPAT_PRECISION vec3 colour = COMPAT_TEXTURE(Source, vec2(xy.x,p)).rgb;

    vec3 P22 = ((colour*colour) * P22D93) * vig;
    colour = PHOSPHOR == 1.0 ? sqrt(max(vec3(0.0),P22)) : colour * vig;

    COMPAT_PRECISION float scanLineWeight = (BRIGHTBOOST - LOWLUMSCAN*(Y - 2.05*YY));
    COMPAT_PRECISION float scanLineWeightB = 1.0 - HILUMSCAN*(YY-2.8*YY*Y);

    FragColor.rgba = vec4(colour.rgb*(cmask*mix(scanLineWeight*mask, scanLineWeightB, dot(colour.rgb,vec3(maskFade)))),1.0);

}
#endif
