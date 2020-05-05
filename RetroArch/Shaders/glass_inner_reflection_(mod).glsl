/*
   mod of AGS-001 shader
   A pristine recreation of the illuminated Game Boy Advance SP
   Author: endrift
   License: MPL 2.0

   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. 
*/

#pragma parameter togglereflection "Toggle Reflection" 1.0 0.0 1.0 1.00
#pragma parameter reflectionBrightness "Reflection brightness" 0.07 0.0 1.0 0.01
#pragma parameter reflectionDistanceX "Reflection Distance X" 0.0 -1.0 1.0 0.01
#pragma parameter reflectionDistanceY "Reflection Distance Y" 0.1 -1.0 1.0 0.01

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
uniform COMPAT_PRECISION float togglereflection;
uniform COMPAT_PRECISION float reflectionBrightness;
uniform COMPAT_PRECISION float reflectionDistanceX;
uniform COMPAT_PRECISION float reflectionDistanceY;
#else
#define togglereflection 1.00
#define reflectionBrightness 0.07
#define reflectionDistanceX 0.0
#define reflectionDistanceY 0.1
#endif


void main()
{
	vec2 reflectionDistance = vec2(reflectionDistanceX,reflectionDistanceY);

	vec4 color = COMPAT_TEXTURE(Source, vTexCoord);

	vec4 reflection = COMPAT_TEXTURE(Source, vTexCoord - (reflectionDistance / 10.));
	FragColor = (togglereflection == 0.0) ? color : vec4(1. - (1. - color.rgb) * (1. - reflection * reflectionBrightness), 1.0);

}
#endif
