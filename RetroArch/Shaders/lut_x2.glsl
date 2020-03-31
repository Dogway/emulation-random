// Parameter lines go here:
#pragma parameter LUT_Size1 "LUT 1 Size" 32.0 0.0 64.0 16.0
#pragma parameter LUT1_toggle "LUT 1 Toggle" 0.0 0.0 1.0 1.0
#pragma parameter LUT_Size2 "LUT 2 Size" 64.0 0.0 64.0 16.0
#pragma parameter LUT2_toggle "LUT 2 Toggle" 0.0 0.0 1.0 1.0

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

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
uniform sampler2D SamplerLUT1;
uniform sampler2D SamplerLUT2;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float LUT_Size1;
uniform COMPAT_PRECISION float LUT1_toggle;
uniform COMPAT_PRECISION float LUT_Size2;
uniform COMPAT_PRECISION float LUT2_toggle;
#else
#define LUT_Size1 32.0
#define LUT1_toggle 0.0
#define LUT_Size2 64.0
#define LUT2_toggle 0.0
#endif

// This shouldn't be necessary but it seems some undefined values can
// creep in and each GPU vendor handles that differently. This keeps
// all values within a safe range
vec4 mixfix(vec4 a, vec4 b, float c)
{
	return (a.z < 1.0) ? mix(a, b, c) : a;
}

void main()
{
//  First LUT
	vec4 imgColor = COMPAT_TEXTURE(Source, vTexCoord.xy);
	float red = ( imgColor.r * (LUT_Size1 - 1.0) + 0.4999 ) / (LUT_Size1 * LUT_Size1);
	float green = ( imgColor.g * (LUT_Size1 - 1.0) + 0.4999 ) / LUT_Size1;
	float blue1 = (floor( imgColor.b  * (LUT_Size1 - 1.0) ) / LUT_Size1) + red;
	float blue2 = (ceil( imgColor.b  * (LUT_Size1 - 1.0) ) / LUT_Size1) + red;
	float mixer = clamp(max((imgColor.b - blue1) / (blue2 - blue1), 0.0), 0.0, 32.0);
	vec4 color1 = COMPAT_TEXTURE( SamplerLUT1, vec2( blue1, green ));
	vec4 color2 = COMPAT_TEXTURE( SamplerLUT1, vec2( blue2, green ));
	vec4 vcolor = (LUT1_toggle < 1.0) ? imgColor.rgba : mixfix(color1, color2, mixer);

//  Second LUT
	float red_2 = ( vcolor.r * (LUT_Size2 - 1.0) + 0.4999 ) / (LUT_Size2 * LUT_Size2);
	float green_2 = ( vcolor.g * (LUT_Size2 - 1.0) + 0.4999 ) / LUT_Size2;
	float blue1_2 = (floor( vcolor.b  * (LUT_Size2 - 1.0) ) / LUT_Size2) + red_2;
	float blue2_2 = (ceil( vcolor.b  * (LUT_Size2 - 1.0) ) / LUT_Size2) + red_2;
	float mixer_2 = clamp(max((vcolor.b - blue1_2) / (blue2_2 - blue1_2), 0.0), 0.0, 32.0);
	vec4 color1_2 = COMPAT_TEXTURE( SamplerLUT2, vec2( blue1_2, green_2 ));
	vec4 color2_2 = COMPAT_TEXTURE( SamplerLUT2, vec2( blue2_2, green_2 ));
	FragColor = (LUT2_toggle < 1.0) ? vcolor.rgba : mixfix(color1_2, color2_2, mixer_2);

}
#endif
