/*
   Vignette
   Author: hunterk, Dogway
   License: Public domain
*/
/*
   Vignette
   License: Public domain
*/

#pragma parameter vignette "Vignette Toggle" 1.0 0.0 1.0 1.0
#pragma parameter inner "Inner Ring" 0.25 0.0 1.0 0.01
#pragma parameter outer "Outer Ring" 0.60 0.0 1.0 0.01


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

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
   gl_Position = MVPMatrix * VertexCoord;
   TEX0.xy = TexCoord.xy;
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

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

struct output_dummy {
    vec4 _color;
};

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
uniform COMPAT_PRECISION float vignette;
uniform COMPAT_PRECISION float inner;
uniform COMPAT_PRECISION float outer;
#else
#define vignette 1.0
#define inner 0.0
#define outer 1.0
#endif

void main()
{

    vec3 vcolor = COMPAT_TEXTURE(Source, TEX0.xy).rgb;
// a simple calculation for the vignette effect
	vec2 mid = vec2(0.49999, 0.49999) * InputSize / TextureSize;
	vec2 middle = TEX0.xy - mid;
	float len = length(middle);
	float vig = smoothstep(inner, outer, len);

	vcolor *= (vignette > 0.5) ? (1.0 - vig) : 1.0; // Vignette

	FragColor = vec4(vcolor,1.0);
	
} 
#endif
