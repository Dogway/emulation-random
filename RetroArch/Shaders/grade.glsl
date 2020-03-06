/*
   Grade
   Author: hunterk, Guest, Dr. Venom, Dogway
   License: Public domain
*/

#pragma parameter vignette "Vignette Toggle" 1.0 0.0 1.0 1.0
#pragma parameter hotspot "Hotspot" 0.0 0.0 1.0 0.1
#pragma parameter inner "Inner Ring" 0.35 0.0 1.0 0.01
#pragma parameter outer "Outer Ring" 0.7 0.0 1.0 0.01
#pragma parameter LUT_Size1 "LUT Size 1" 16.0 0.0 64.0 16.0
#pragma parameter LUT1_toggle "LUT 1 Toggle" 1.0 0.0 1.0 1.0
#pragma parameter LUT_Size2 "LUT Size 2" 64.0 0.0 64.0 16.0
#pragma parameter LUT2_toggle "LUT 2 Toggle" 1.0 0.0 1.0 1.0
#pragma parameter temperature "White Point" 6500.0 1000.0 12000.0 100.0
#pragma parameter luma_preserve "Preserve Luminance" 1.0 0.0 1.0 1.0
#pragma parameter sat "Saturation" 1.0 0.0 3.0 0.01
#pragma parameter lum "Luminance" 1.0 0.0 5.0 0.01
#pragma parameter cntrst "Contrast" 1.0 0.0 2.0 0.01
#pragma parameter black_level "Black Level" 0.0 0.0 1.0 0.01
#pragma parameter blr "Black-Red Tint" 0.0 0.0 1.0 0.005
#pragma parameter blg "Black-Green Tint" 0.0 0.0 1.0 0.005
#pragma parameter blb "Black-Blue Tint" 0.0 0.0 1.0 0.005
#pragma parameter r "Red" 1.0 0.0 2.0 0.01
#pragma parameter g "Green" 1.0 0.0 2.0 0.01
#pragma parameter b "Blue" 1.0 0.0 2.0 0.01
#pragma parameter red "Red Shift" 0.0 -1.0 1.0 0.01
#pragma parameter green "Green Shift" 0.0 -1.0 1.0 0.01
#pragma parameter blue "Blue Shift" 0.0 -1.0 1.0 0.01
#pragma parameter rg "Red-Green Tint" 0.0 0.0 1.0 0.005
#pragma parameter rb "Red-Blue Tint" 0.0 0.0 1.0 0.005
#pragma parameter gr "Green-Red Tint" 0.0 0.0 1.0 0.005
#pragma parameter gb "Green-Blue Tint" 0.0 0.0 1.0 0.005
#pragma parameter br "Blue-Red Tint" 0.0 0.0 1.0 0.005
#pragma parameter bg "Blue-Green Tint" 0.0 0.0 1.0 0.005


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
uniform sampler2D SamplerLUT1;
uniform sampler2D SamplerLUT2;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float hotspot;
uniform COMPAT_PRECISION float vignette;
uniform COMPAT_PRECISION float inner;
uniform COMPAT_PRECISION float outer;
uniform COMPAT_PRECISION float LUT_Size1;
uniform COMPAT_PRECISION float LUT1_toggle;
uniform COMPAT_PRECISION float LUT_Size2;
uniform COMPAT_PRECISION float LUT2_toggle;
uniform COMPAT_PRECISION float temperature;
uniform COMPAT_PRECISION float luma_preserve;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float lum;
uniform COMPAT_PRECISION float cntrst;
uniform COMPAT_PRECISION float black_level;
uniform COMPAT_PRECISION float blr;
uniform COMPAT_PRECISION float blg;
uniform COMPAT_PRECISION float blb;
uniform COMPAT_PRECISION float r;
uniform COMPAT_PRECISION float g;
uniform COMPAT_PRECISION float b;
uniform COMPAT_PRECISION float red;
uniform COMPAT_PRECISION float green;
uniform COMPAT_PRECISION float blue;
uniform COMPAT_PRECISION float rg;
uniform COMPAT_PRECISION float rb;
uniform COMPAT_PRECISION float gr;
uniform COMPAT_PRECISION float gb;
uniform COMPAT_PRECISION float br;
uniform COMPAT_PRECISION float bg;
#else
#define vignette 1.0
#define hotspot 1.0
#define inner 0.0
#define outer 1.0
#define LUT_Size1 16.0
#define LUT1_toggle 1.0
#define LUT_Size2 64.0
#define LUT2_toggle 1.0
#define temperature 6500.0
#define luma_preserve 1.0
#define sat 1.0
#define lum 1.0
#define cntrst 1.0
#define black_level 0.0
#define blr 0.0
#define blg 0.0
#define blb 0.0
#define r 1.0
#define g 1.0
#define b 1.0
#define red 0.0
#define green 0.0
#define blue 0.0
#define rg 0.0
#define rb 0.0
#define gr 0.0
#define gb 0.0
#define br 0.0
#define bg 0.0
#endif

// white point adjustment
// based on blog post by Neil Bartlett (inspired by Tanner Helland's work)
// http://www.zombieprototypes.com/?p=210
vec3 wp_adjust(vec3 color){
   float temp = temperature / 100.0;

   // all calculations assume a scale of 255. We'll normalize this at the end
   vec3 wp = vec3(255.);

   // calculate RED
   wp.r = (temp <= 66.) ? 255. : 351.97690566805693 + 0.114206453784165 * (temp - 55.) - 40.25366309332127 * log(temp - 55.);

   // calculate GREEN
   float mg = - 155.25485562709179 - 0.44596950469579133 * (temp - 2.)  + 104.49216199393888 * log(temp - 2.);
   float pg =   325.4494125711974  + 0.07943456536662342 * (temp - 50.) - 28.0852963507957   * log(temp - 50.);
   wp.g = (temp <= 66.) ? mg : pg;

   // calculate BLUE
   wp.b = (temp >= 66.) ? 255. : (temp <= 19.) ? 0. : - 254.76935184120902 + 0.8274096064007395 * (temp - 10.) + 115.67994401066147 * log(temp - 10.) ;

   // clamp and normalize
   wp.rgb = clamp(wp.rgb, vec3(0.), vec3(255.)) / vec3(255.);

   // this is dumb, but various cores don't always show white as white. Use this to make white white...
   wp.rgb += vec3(red, green, blue);

   return (color * wp);
}

vec3 sRGB_to_XYZ(vec3 RGB){

    const mat3x3 m = mat3x3(
    0.4124564,  0.3575761,  0.1804375,
    0.2126729,  0.7151522,  0.0721750,
    0.0193339,  0.1191920,  0.9503041);
    return RGB * m;
}


vec3 XYZtoYxy(vec3 XYZ){

    float XYZrgb = XYZ.r+XYZ.g+XYZ.b;
    float Yxyr = XYZ.g;
    float Yxyg = (XYZrgb <= 0.0) ? 0.3805 : XYZ.r / XYZrgb;
    float Yxyb = (XYZrgb <= 0.0) ? 0.3769 : XYZ.g / XYZrgb;
    return vec3(Yxyr,Yxyg,Yxyb);
}

vec3 XYZ_to_sRGB(vec3 XYZ){

    const mat3x3 m = mat3x3(
    3.2404542, -1.5371385, -0.4985314,
   -0.9692660,  1.8760108,  0.0415560,
    0.0556434, -0.2040259,  1.0572252);
    return XYZ * m;
}


vec3 YxytoXYZ(vec3 Yxy){

    float Xs = Yxy.r * (Yxy.g/Yxy.b);
    float Xsz = (Yxy.r <= 0.0) ? 0 : 1;
    vec3 XYZ = vec3(Xsz,Xsz,Xsz) * vec3(Xs, Yxy.r, (Xs/Yxy.g)-Xs-Yxy.r);
    return XYZ;
}

// This shouldn't be necessary but it seems some undefined values can
// creep in and each GPU vendor handles that differently. This keeps
// all values within a safe range
vec3 mixfix(vec3 a, vec3 b, float c)
{
    return (a.z < 1.0) ? mix(a, b, c) : a;
}

void main()
{


    vec3 imgColor = COMPAT_TEXTURE(Source, TEX0.xy);
    float red = ( imgColor.r * (LUT_Size1 - 1.0) + 0.4999 ) / (LUT_Size1 * LUT_Size1);
    float green = ( imgColor.g * (LUT_Size1 - 1.0) + 0.4999 ) / LUT_Size1;
    float blue1 = (floor( imgColor.b  * (LUT_Size1 - 1.0) ) / LUT_Size1) + red;
    float blue2 = (ceil( imgColor.b  * (LUT_Size1 - 1.0) ) / LUT_Size1) + red;
    float mixer = clamp(max((imgColor.b - blue1) / (blue2 - blue1), 0.0), 0.0, 32.0);
    vec3 color1 = COMPAT_TEXTURE( SamplerLUT1, vec2( blue1, green ));
    vec3 color2 = COMPAT_TEXTURE( SamplerLUT1, vec2( blue2, green ));
    vec3 vcolor =  (LUT1_toggle < 1.0) ? imgColor : mixfix(color1, color2, mixer);

//  a simple calculation for the vignette/hotspot effects
    vec2 mid = vec2(0.49999, 0.49999) * InputSize / TextureSize;
    vec2 middle = TEX0.xy - mid;
    float len = length(middle);
    float vig = smoothstep(inner, outer, len);

    vcolor += vec3(black_level) * (1.0-vcolor); // apply black level
    vcolor *= (vignette > 0.5) ? (1.0 - vig) : 1.0; // Vignette
    vcolor += ((1.0 - vig) * 0.2) * hotspot; // Hotspot
    vec4 vignetted = vec4(vcolor,1.0);


    vec4 avglum = vec4(0.5);
    vec4 screen = mix(vignetted.rgba, avglum, (1.0 - cntrst));

//                      r    g    b  alpha ; alpha does nothing for our purposes
    mat4 color = mat4(  r,  rg,  rb, 0.0,  //red tint
                       gr,   g,  gb, 0.0,  //green tint
                       br,  bg,   b, 0.0,  //blue tint
                      blr, blg, blb, 0.0); //black tint

    mat4 adjust = mat4((1.0 - sat) * 0.2126 + sat, (1.0 - sat) * 0.2126, (1.0 - sat) * 0.2126, 1.0,
                       (1.0 - sat) * 0.7152, (1.0 - sat) * 0.7152 + sat, (1.0 - sat) * 0.7152, 1.0,
                       (1.0 - sat) * 0.0722, (1.0 - sat) * 0.0722, (1.0 - sat) * 0.0722 + sat, 1.0,
                       0.0, 0.0, 0.0, 1.0);

    color *= adjust;
    screen = clamp(screen * lum, 0.0, 1.0);
    screen = color * screen;

    vec3 adjusted = wp_adjust(vec3(screen));
    vec3 base_luma = XYZtoYxy(sRGB_to_XYZ(vec3(screen)));
    vec3 adjusted_luma = XYZtoYxy(sRGB_to_XYZ(adjusted));
    adjusted = (luma_preserve > 0.5) ? adjusted_luma + (vec3(base_luma.r,0.,0.) - vec3(adjusted_luma.r,0.,0.)) : adjusted_luma;
    adjusted = clamp(XYZ_to_sRGB(YxytoXYZ(adjusted)), 0.0, 1.0);

    float red_2 = ( adjusted.r * (LUT_Size2 - 1.0) + 0.4999 ) / (LUT_Size2 * LUT_Size2);
    float green_2 = ( adjusted.g * (LUT_Size2 - 1.0) + 0.4999 ) / LUT_Size2;
    float blue1_2 = (floor( adjusted.b  * (LUT_Size2 - 1.0) ) / LUT_Size2) + red_2;
    float blue2_2 = (ceil( adjusted.b  * (LUT_Size2 - 1.0) ) / LUT_Size2) + red_2;
    float mixer_2 = clamp(max((adjusted.b - blue1_2) / (blue2_2 - blue1_2), 0.0), 0.0, 32.0);
    vec3 color1_2 = COMPAT_TEXTURE( SamplerLUT2, vec2( blue1_2, green_2 ));
    vec3 color2_2 = COMPAT_TEXTURE( SamplerLUT2, vec2( blue2_2, green_2 ));
    vec3 LUT2_output = mixfix(color1_2, color2_2, mixer_2);

    FragColor = (LUT2_toggle < 1.0) ? vec4(adjusted, 1.0) : vec4(LUT2_output, 1.0);
}
#endif
