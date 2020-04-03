
///////////////
//	TV-out tweaks Linearized Multipass - Pass1
//	Author: aliaspider and RiskyJumps
//	License: GPLv3
////////////////////////////////////////////////////////


// this shader is meant to be used when running
// an emulator on a real CRT-TV @240p or @480i
////////////////////////////////////////////////////////
// Basic settings:

// signal resolution
// higher = sharper
#pragma parameter TOGGLE "Toggle Signal" 0.0 0.0 1.0 1.0
#pragma parameter TVOUT_RESOLUTION "TVOut Signal Resolution" 256.0 0.0 1024.0 1.0 // default, minimum, maximum, optional step

// simulate a composite connection instead of RGB
//#pragma parameter TVOUT_COMPOSITE_CONNECTION "TVOut Composite Enable" 0.0 0.0 1.0 1.0

//// use TV video color range (16-235)
//// instead of PC full range (0-255)
//#pragma parameter TVOUT_TV_COLOR_LEVELS "TVOut TV Color Levels Enable" 0.0 0.0 1.0 1.0
////////////////////////////////////////////////////////

////////////////////////////////////////////////////////
// Advanced settings:
//
// these values will be used instead
// if COMPOSITE_CONNECTION is defined
// to simulate different signal resolutions(bandwidth)
// for luma (Y) and chroma ( I and Q )
// this is just an approximation
// and will only simulate the low bandwidth anspect of
// composite signal, not the crosstalk between luma and chroma
// Y = 4MHz I=1.3MHz Q=0.4MHz
//#pragma parameter TVOUT_RESOLUTION_Y "TVOut Luma (Y) Resolution" 256.0 0.0 1024.0 32.0
//#pragma parameter TVOUT_RESOLUTION_I "TVOut Chroma (I) Resolution" 83.2 0.0 256.0 8.0
//#pragma parameter TVOUT_RESOLUTION_Q "TVOut Chroma (Q) Resolution" 25.6 0.0 256.0 8.0

// formula is MHz=resolution*15750Hz
// 15750Hz being the horizontal Frequency of NTSC
// (=262.5*60Hz)
////////////////////////////////////////////////////////

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

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

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


#ifdef PARAMETER_UNIFORM // If the shader implementation understands #pragma parameters, this is defined.
uniform COMPAT_PRECISION float TVOUT_RESOLUTION;
uniform COMPAT_PRECISION float TOGGLE;
#else
// Fallbacks if parameters are not supported.
#define TVOUT_RESOLUTION 256.0 // Default
#define TOGGLE 0.0
#endif

#define Source Texture
#define vTexCoord TEX0.xy
#define pi			3.14159265358
#define a(x) abs(x)
#define d(x,b) (pi*b*min(a(x)+0.5,1.0/b))
#define e(x,b) (pi*b*min(max(a(x)-0.5,-1.0/b),1.0/b))
#define STU(x,b) ((d(x,b)+sin(d(x,b))-e(x,b)-sin(e(x,b)))/(2.0*pi))

#define GETC(c) \
    c = ((COMPAT_TEXTURE(Texture, vec2(TEX0.x - X*oneT,TEX0.y)).xyz))

#define VAL(tempColor) \
    tempColor += (c*STU(X,(TVOUT_RESOLUTION*oneI)))


uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

void main()
{
    vec3 sourcetex = COMPAT_TEXTURE(Source, vTexCoord).rgb;
    vec3 tempColor = vec3(0.0,0.0,0.0);
    float offset = fract((TEX0.x * TextureSize.x) - 0.5);
    float oneT = 1.0 / TextureSize.x;
    float oneI = 1.0 / InputSize.x;

    float X;
    vec3 c;

    X = (offset-(-1.0));//X(-1.0);
    GETC(c);
    VAL(tempColor);

    X = (offset-(0.0));//X(0.0);
    GETC(c);
    VAL(tempColor);

    X = (offset-(1.0));//X(1.0);
    GETC(c);
    VAL(tempColor);

    X = (offset-(2.0));//X(2.0);
    GETC(c);
    VAL(tempColor);

    FragColor = (TOGGLE == 1.0) ? vec4(tempColor, 1.0) : vec4(sourcetex, 1.0);
}
#endif
