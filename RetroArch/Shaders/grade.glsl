/*
   Grade
   > Ubershader grouping some color related monolithic shaders like color-mangler, vignette, lut,
   > white_point, and the addition of black level, sigmoidal contrast and proper gamma transforms.

   Author: hunterk, Guest, Dr. Venom, Dogway
   License: Public domain
*/

#pragma parameter gamma_in "CRT Gamma" 2.55 0.0 3.0 0.05
#pragma parameter vignette "Vignette Toggle" 1.0 0.0 1.0 1.0
#pragma parameter str "Vig.Strength" 15.0 10.0 40.0 1.0
#pragma parameter power "Vig.Power" 0.10 0.0 0.5 0.01
#pragma parameter LUT_Size1 "LUT Size 1" 16.0 0.0 64.0 16.0
#pragma parameter LUT1_toggle "LUT 1 Toggle" 0.0 0.0 1.0 1.0
#pragma parameter LUT_Size2 "LUT Size 2" 64.0 0.0 64.0 16.0
#pragma parameter LUT2_toggle "LUT 2 Toggle" 0.0 0.0 1.0 1.0
#pragma parameter temperature "White Point" 6504.0 1000.0 12000.0 100.0
#pragma parameter luma_preserve "WP Preserve Luminance" 1.0 0.0 1.0 1.0
#pragma parameter sat "Saturation" 1.0 0.0 3.0 0.01
#pragma parameter lum "Brightness" 1.0 0.0 5.0 0.01
#pragma parameter cntrst "Contrast" 0.0 -1.0 1.0 0.05
#pragma parameter mid "Contrast Pivot" 0.5 0.0 1.0 0.01
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
uniform COMPAT_PRECISION float gamma_in;
uniform COMPAT_PRECISION float vignette;
uniform COMPAT_PRECISION float str;
uniform COMPAT_PRECISION float power;
uniform COMPAT_PRECISION float LUT_Size1;
uniform COMPAT_PRECISION float LUT1_toggle;
uniform COMPAT_PRECISION float LUT_Size2;
uniform COMPAT_PRECISION float LUT2_toggle;
uniform COMPAT_PRECISION float temperature;
uniform COMPAT_PRECISION float luma_preserve;
uniform COMPAT_PRECISION float sat;
uniform COMPAT_PRECISION float lum;
uniform COMPAT_PRECISION float cntrst;
uniform COMPAT_PRECISION float mid;
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
#define gamma_in 2.4
#define vignette 1.0
#define str 15.0
#define power 0.1
#define LUT_Size1 16.0
#define LUT1_toggle 0.0
#define LUT_Size2 64.0
#define LUT2_toggle 0.0
#define temperature 6504.0
#define luma_preserve 1.0
#define sat 1.0
#define lum 1.0
#define cntrst 0.0
#define mid 0.5
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


// White Point Mapping function
//
// From the first comment post (sRGB and linear light compensated)
//      http://www.zombieprototypes.com/?p=210#comment-4695029660
// Based on the Neil Bartlett's blog update
//      http://www.zombieprototypes.com/?p=210
// Inspired itself by Tanner Helland's work
//      http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/

vec3 wp_adjust(vec3 color){

    float temp = temperature / 100.;
    float k = temperature / 10000.;
    float lk = log(k);

    vec3 wp = vec3(1.);

    // calculate RED
    wp.r = (temp <= 65.) ? 1. : 0.32068362618584273 + (0.19668730877673762 * pow(k - 0.21298613432655075, - 1.5139012907556737)) + (- 0.013883432789258415 * lk);

    // calculate GREEN
    float mg = 1.226916242502167 + (- 1.3109482654223614 * pow(k - 0.44267061967913873, 3.) * exp(- 5.089297600846147 * (k - 0.44267061967913873))) + (0.6453936305542096 * lk);
    float pg = 0.4860175851734596 + (0.1802139719519286 * pow(k - 0.14573069517701578, - 1.397716496795082)) + (- 0.00803698899233844 * lk);
    wp.g = (temp <= 65.5) ? ((temp <= 8.) ? 0. : mg) : pg;

    // calculate BLUE
    wp.b = (temp <= 19.) ? 0. : (temp >= 66.) ? 1. : 1.677499032830161 + (- 0.02313594016938082 * pow(k - 1.1367244820333684, 3.) * exp(- 4.221279555918655 * (k - 1.1367244820333684))) + (1.6550275798913296 * lk);

    // clamp
    wp.rgb = clamp(wp.rgb, vec3(0.), vec3(1.));

    // this is dumb, but various cores don't always show white as white. Use this to make white white...
    wp.rgb += vec3(red, green, blue);

    // Linear color input
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
    float Yxyg = (XYZrgb <= 0.0) ? 0.3805 : XYZ.r / XYZrgb;
    float Yxyb = (XYZrgb <= 0.0) ? 0.3769 : XYZ.g / XYZrgb;
    return vec3(XYZ.g, Yxyg, Yxyb);
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
    float Xsz = (Yxy.r <= 0.0) ? 0.0 : 1.0;
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


vec3 linear_to_sRGB(vec3 color, float gamma){

    color = clamp(color, 0.0, 1.0);
    color.r = (color.r <= 0.00313066844250063) ?
    color.r * 12.92 : 1.055 * pow(color.r, 1.0 / gamma) - 0.055;
    color.g = (color.g <= 0.00313066844250063) ?
    color.g * 12.92 : 1.055 * pow(color.g, 1.0 / gamma) - 0.055;
    color.b = (color.b <= 0.00313066844250063) ?
    color.b * 12.92 : 1.055 * pow(color.b, 1.0 / gamma) - 0.055;

    return color;
}


vec3 sRGB_to_linear(vec3 color, float gamma){

    color = clamp(color, 0.0, 1.0);
    color.r = (color.r <= 0.04045) ?
    color.r / 12.92 : pow((color.r + 0.055) / (1.055), gamma);
    color.g = (color.g <= 0.04045) ?
    color.g / 12.92 : pow((color.g + 0.055) / (1.055), gamma);
    color.b = (color.b <= 0.04045) ?
    color.b / 12.92 : pow((color.b + 0.055) / (1.055), gamma);

    return color;
}


//  Performs better in gamma encoded sources
vec3 contrast_sigmoid(vec3 color, float cntrst, float mid){

    cntrst = pow(cntrst + 1, 3.);

    float knee = 1. / (1. + exp(cntrst * mid));
    float shldr = 1. / (1. + exp(cntrst * (mid - 1.)));

    color.r = (1. / (1. + exp(cntrst * (mid - color.r))) - knee) / (shldr - knee);
    color.g = (1. / (1. + exp(cntrst * (mid - color.g))) - knee) / (shldr - knee);
    color.b = (1. / (1. + exp(cntrst * (mid - color.b))) - knee) / (shldr - knee);

    return color;
}


//  Performs better in gamma encoded sources
vec3 contrast_sigmoid_inv(vec3 color, float cntrst, float mid){

    cntrst = pow(cntrst - 1, 3.);

    float knee = 1. / (1. + exp (cntrst * mid));
    float shldr = 1. / (1. + exp (cntrst * (mid - 1.)));

    color.r = mid - log(1. / (color.r * (shldr - knee) + knee) - 1.) / cntrst;
    color.g = mid - log(1. / (color.g * (shldr - knee) + knee) - 1.) / cntrst;
    color.b = mid - log(1. / (color.b * (shldr - knee) + knee) - 1.) / cntrst;

    return color;
}



void main()
{

//  Pure power was crushing blacks (eg. DKC2). You can mimic pow(c, 2.4) by raising the gamma_in value to 2.55
    vec3 imgColor = sRGB_to_linear(COMPAT_TEXTURE(Source, vTexCoord).rgb, vec3(gamma_in));

//  Look LUT
    float red = ( imgColor.r * (LUT_Size1 - 1.0) + 0.4999 ) / (LUT_Size1 * LUT_Size1);
    float green = ( imgColor.g * (LUT_Size1 - 1.0) + 0.4999 ) / LUT_Size1;
    float blue1 = (floor( imgColor.b  * (LUT_Size1 - 1.0) ) / LUT_Size1) + red;
    float blue2 = (ceil( imgColor.b  * (LUT_Size1 - 1.0) ) / LUT_Size1) + red;
    float mixer = clamp(max((imgColor.b - blue1) / (blue2 - blue1), 0.0), 0.0, 32.0);
    vec3 color1 = COMPAT_TEXTURE( SamplerLUT1, vec2( blue1, green ));
    vec3 color2 = COMPAT_TEXTURE( SamplerLUT1, vec2( blue2, green ));
    vec3 vcolor =  (LUT1_toggle < 1.0) ? imgColor : mixfix(color1, color2, mixer);

//  Saturation agnostic sigmoidal contrast
    vec3 Yxy = XYZtoYxy(sRGB_to_XYZ(vcolor));
    vec3 toLinear = linear_to_sRGB(vec3(Yxy.r, 0.0, 0.0), 2.4);
    vec3 contrast = (cntrst > 0.0) ? contrast_sigmoid(toLinear, cntrst, mid) : contrast_sigmoid_inv(toLinear, cntrst, mid);
    contrast.rgb = vec3(sRGB_to_linear(contrast, 2.4).r, Yxy.g, Yxy.b);
    vec3 XYZsrgb = clamp(XYZ_to_sRGB(YxytoXYZ(contrast)), 0.0, 1.0);
    contrast = (cntrst == 0.0) ? vcolor : XYZsrgb;


//  Vignetting & Black Level
    vec2 vpos = vTexCoord * (TextureSize.xy / InputSize.xy);
    vpos *= 1.0 - vpos.xy;
    float vig = vpos.x * vpos.y * str;
    vig = min(pow(vig, power), 1.0);
    contrast *= (vignette > 0.5) ? vig : 1.0;

    contrast += vec3(black_level / 5.0) * (1.0 - contrast);


//  RGB related transforms
    vec4 screen = vec4(contrast, 1.0);
                   //  r    g    b  alpha ; alpha does nothing for our purposes
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

//  Color Temperature
    vec3 adjusted = wp_adjust(vec3(screen));
    vec3 base_luma = XYZtoYxy(sRGB_to_XYZ(vec3(screen)));
    vec3 adjusted_luma = XYZtoYxy(sRGB_to_XYZ(adjusted));
    adjusted = (luma_preserve > 0.5) ? adjusted_luma + (vec3(base_luma.r, 0.0, 0.0) - vec3(adjusted_luma.r, 0.0, 0.0)) : adjusted_luma;
    adjusted = clamp(XYZ_to_sRGB(YxytoXYZ(adjusted)), 0.0, 1.0);


//  Technical LUT
    float red_2 = ( adjusted.r * (LUT_Size2 - 1.0) + 0.4999 ) / (LUT_Size2 * LUT_Size2);
    float green_2 = ( adjusted.g * (LUT_Size2 - 1.0) + 0.4999 ) / LUT_Size2;
    float blue1_2 = (floor( adjusted.b  * (LUT_Size2 - 1.0) ) / LUT_Size2) + red_2;
    float blue2_2 = (ceil( adjusted.b  * (LUT_Size2 - 1.0) ) / LUT_Size2) + red_2;
    float mixer_2 = clamp(max((adjusted.b - blue1_2) / (blue2_2 - blue1_2), 0.0), 0.0, 32.0);
    vec3 color1_2 = COMPAT_TEXTURE( SamplerLUT2, vec2( blue1_2, green_2 ));
    vec3 color2_2 = COMPAT_TEXTURE( SamplerLUT2, vec2( blue2_2, green_2 ));
    vec3 LUT2_output = mixfix(color1_2, color2_2, mixer_2);

    FragColor = (LUT2_toggle < 1.0) ? vec4(linear_to_sRGB(adjusted, 2.4), 1.0) : vec4(linear_to_sRGB(LUT2_output, 2.4), 1.0);
}
#endif
