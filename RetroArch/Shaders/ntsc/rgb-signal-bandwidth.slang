#version 450

///////////////
//	TV-out tweaks
//	Author: aliaspider - aliaspider@gmail.com
//	License: GPLv3
////////////////////////////////////////////////////////


// This shader is meant to be used when running
// an emulator on a real CRT-TV @240p or @480i
////////////////////////////////////////////////////////

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float s_gamma_out;
	float TOGGLE;
	float TVOUT_RESOLUTION;
} params;

// Basic settings:
//
//   signal resolution
//   higher = sharper
//
//   SNES, Genesis 259
//   NeoGeo 264
//   CPS2 262
//   CPS3 264
//   Naomi 480

#pragma parameter s_gamma_out "Signal LCD Gamma" 1.00 0.0 3.0 0.05
#pragma parameter TOGGLE "Toggle Signal" 0.0 0.0 1.0 1.0
#pragma parameter TVOUT_RESOLUTION "TVOut Signal Resolution" 256.0 0.0 1024.0 1.0 // default, minimum, maximum, optional step

// simulate a composite connection instead of RGB
// #pragma parameter TVOUT_COMPOSITE_CONNECTION "TVOut Composite Enable" 0.0 0.0 1.0 1.0

// use TV video color range (16-235)
// instead of PC full range (0-255)
// #pragma parameter TVOUT_TV_COLOR_LEVELS "TVOut TV Color Levels Enable" 0.0 0.0 1.0 1.0
////////////////////////////////////////////////////////

////////////////////////////////////////////////////////
// Advanced settings:
//
// these values will be used instead
// if COMPOSITE_CONNECTION is defined
// to simulate different signal resolutions(bandwidth)
// for luma (Y) and chroma ( I and Q )
// this is just an approximation
// and will only simulate the low bandwidth aspect of
// composite signal, not the crosstalk between luma and chroma
// Y = 4MHz I=1.3MHz Q=0.4MHz
// #pragma parameter TVOUT_RESOLUTION_Y "TVOut Luma (Y) Resolution" 256.0 0.0 1024.0 32.0
// #pragma parameter TVOUT_RESOLUTION_I "TVOut Chroma (I) Resolution" 83.2 0.0 256.0 8.0
// #pragma parameter TVOUT_RESOLUTION_Q "TVOut Chroma (Q) Resolution" 25.6 0.0 256.0 8.0

// formula is MHz=resolution*15750Hz
// 15750Hz being the horizontal Frequency of NTSC
// (=262.5*60Hz)
////////////////////////////////////////////////////////

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;


#define pi			3.14159265358
#define a(x) abs(x)
#define d(x,b) (pi*b*min(a(x)+0.5,1.0/b))
#define e(x,b) (pi*b*min(max(a(x)-0.5,-1.0/b),1.0/b))
#define STU(x,b) ((d(x,b)+sin(d(x,b))-e(x,b)-sin(e(x,b)))/(2.0*pi))
//#define X(i) (offset-(i))

#define mul(a,b) (b*a)


#define GETC(c) \
      c = (texture(Source, vec2(vTexCoord.x - X*oneT,vTexCoord.y)).xyz)

#define VAL(tempColor) \
      tempColor += (c*STU(X,(params.TVOUT_RESOLUTION*oneI)))

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;



float moncurve_r( float color, float gamma, float offs)
{
    // Reverse monitor curve
    color = clamp(color, 0.0, 1.0);
    float yb = pow( offs * gamma / ( ( gamma - 1.0) * ( 1.0 + offs)), gamma);
    float rs = pow( ( gamma - 1.0) / offs, gamma - 1.0) * pow( ( 1.0 + offs) / gamma, gamma);

    color = ( color > yb) ? ( 1.0 + offs) * pow( color, 1.0 / gamma) - offs : color * rs;
    return color;
}


vec3 moncurve_r_f3( vec3 color, float gamma, float offs)
{
    color.r = moncurve_r( color.r, gamma, offs);
    color.g = moncurve_r( color.g, gamma, offs);
    color.b = moncurve_r( color.b, gamma, offs);
    return color.rgb;
}

void main()
{
   vec3	sourcetex = texture(Source, vTexCoord.xy).rgb;
   vec3	tempColor	=	vec3(0.0,0.0,0.0);
   float	offset	=	fract((vTexCoord.x * params.SourceSize.x) - 0.5);
   float	oneT	=	params.SourceSize.z;
   float	oneI	=	params.SourceSize.z;

   float X;
   vec3 c;

    X = (offset-(-1));
    GETC(c);
    VAL(tempColor);

    X = (offset-(0));
    GETC(c);
    VAL(tempColor);

    X = (offset-(1));
    GETC(c);
    VAL(tempColor);

    X = (offset-(2));
    GETC(c);
    VAL(tempColor);

   tempColor = (params.TOGGLE > 0.5) ? tempColor : sourcetex;
   FragColor = (params.s_gamma_out == 1.00) ? vec4(tempColor, 1.0) : vec4(moncurve_r_f3(tempColor, params.s_gamma_out + 0.20, 0.055), 1.0);
}