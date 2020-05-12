#version 450

layout(push_constant) uniform Push
{
    float g_gamma_out;
    float g_gamma_in;
    float g_gamma_type;
    float g_vignette;
    float g_vstr;
    float g_vpower;
    float g_csize;
    float g_bsize;
    float g_crtgamut;
    float g_hue_degrees;
    float g_I_SHIFT;
    float g_Q_SHIFT;
    float g_I_MUL;
    float g_Q_MUL;
    float g_sat;
    float g_vibr;
    float g_lum;
    float g_cntrst;
    float g_mid;
    float g_lift;
    float blr;
    float blg;
    float blb;
    float wlr;
    float wlg;
    float wlb;
    float rg;
    float rb;
    float gr;
    float gb;
    float br;
    float bg;
} params;

/*
   Grade
   > Ubershader grouping some color related monolithic shaders like color-mangler, lut_x2, white_point, and the addition of...
   > ...vibrance, crt-gamut, vignette, black level, corner size, rolled gain, sigmoidal contrast and proper gamma transforms.

   Author: hunterk, Guest, Dr. Venom, Dogway
   License: Public domain
*/

#pragma parameter g_gamma_out "LCD Gamma" 2.20 0.0 3.0 0.05
#pragma parameter g_gamma_in "CRT Gamma" 2.40 0.0 3.0 0.05
#pragma parameter g_gamma_type "CRT Gamma (POW:0, sRGB:1, SMPTE-C:2)" 1.0 0.0 2.0 1.0
#pragma parameter g_vignette "Vignette Toggle" 1.0 0.0 1.0 1.0
#pragma parameter g_vstr "Vignette Strength" 40.0 0.0 50.0 1.0
#pragma parameter g_vpower "Vignette Power" 0.20 0.0 0.5 0.01
#pragma parameter g_csize "Corner size" 0.0 0.0 0.07 0.01
#pragma parameter g_bsize "Border smoothness" 600.0 100.0 600.0 25.0
#pragma parameter g_crtgamut "Gamut (3:NTSC-U 4:NTSC-J 5:PAL)" 4.0 0.0 7.0 1.0
#pragma parameter g_display "Display Matrix" 0.0 0.0 1.0 1.0
#pragma parameter g_hue_degrees "Hue" 0.0 -360.0 360.0 1.0
#pragma parameter g_I_SHIFT "I/U Shift" 0.0 -1.0 1.0 0.02
#pragma parameter g_Q_SHIFT "Q/V Shift" 0.0 -1.0 1.0 0.02
#pragma parameter g_I_MUL "I/U Multiplier" 1.0 0.0 2.0 0.1
#pragma parameter g_Q_MUL "Q/V Multiplier" 1.0 0.0 2.0 0.1
#pragma parameter wp_temperature "White Point" 9305.0 1621.0 12055.0 50.0
#pragma parameter g_sat "Saturation" 0.0 -1.0 2.0 0.02
#pragma parameter g_vibr "Dullness/Vibrance" 0.0 -1.0 1.0 0.05
#pragma parameter g_lum "Brightness" 0.0 -0.5 1.0 0.01
#pragma parameter g_cntrst "Contrast" 0.0 -1.0 1.0 0.05
#pragma parameter g_mid "Contrast Pivot" 0.5 0.0 1.0 0.01
#pragma parameter g_lift "Black Level" 0.0 -0.5 0.5 0.01
#pragma parameter blr "Black-Red Tint" 0.0 0.0 1.0 0.01
#pragma parameter blg "Black-Green Tint" 0.0 0.0 1.0 0.01
#pragma parameter blb "Black-Blue Tint" 0.0 0.0 1.0 0.01
#pragma parameter wlr "White-Red Tint" 1.0 0.0 2.0 0.01
#pragma parameter wlg "White-Green Tint" 1.0 0.0 2.0 0.01
#pragma parameter wlb "White-Blue Tint" 1.0 0.0 2.0 0.01
#pragma parameter rg "Red-Green Tint" 0.0 -1.0 1.0 0.005
#pragma parameter rb "Red-Blue Tint" 0.0 -1.0 1.0 0.005
#pragma parameter gr "Green-Red Tint" 0.0 -1.0 1.0 0.005
#pragma parameter gb "Green-Blue Tint" 0.0 -1.0 1.0 0.005
#pragma parameter br "Blue-Red Tint" 0.0 -1.0 1.0 0.005
#pragma parameter bg "Blue-Green Tint" 0.0 -1.0 1.0 0.005
#pragma parameter LUT_Size1 "LUT Size 1" 16.0 8.0 64.0 16.0
#pragma parameter LUT1_toggle "LUT 1 Toggle" 0.0 0.0 1.0 1.0
#pragma parameter LUT_Size2 "LUT Size 2" 64.0 0.0 64.0 16.0
#pragma parameter LUT2_toggle "LUT 2 Toggle" 0.0 0.0 1.0 1.0

#define M_PI            3.1415926535897932384626433832795
#define gamma_out       params.g_gamma_out
#define gamma_in        params.g_gamma_in
#define gamma_type      params.g_gamma_type
#define vignette        params.g_vignette
#define vstr            params.g_vstr
#define vpower          params.g_vpower
#define csize           params.g_csize
#define bsize           params.g_bsize
#define crtgamut        params.g_crtgamut
#define hue_degrees     params.g_hue_degrees
#define I_SHIFT         params.g_I_SHIFT
#define Q_SHIFT         params.g_Q_SHIFT
#define I_MUL           params.g_I_MUL
#define Q_MUL           params.g_Q_MUL
#define v_sat           params.g_sat
#define vibr            params.g_vibr
#define lum             params.g_lum
#define cntrst          params.g_cntrst
#define mid             params.g_mid
#define lift            params.g_lift
#define blr             params.blr
#define blg             params.blg
#define blb             params.blb
#define wlr             params.wlr
#define wlg             params.wlg
#define wlb             params.wlb
#define rg              params.rg
#define rb              params.rb
#define gr              params.gr
#define gb              params.gb
#define br              params.br
#define bg              params.bg

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
    vec4 SourceSize;
    vec4 OriginalSize;
    vec4 OutputSize;
    float wp_temperature;
    float LUT_Size1;
    float LUT1_toggle;
    float LUT_Size2;
    float LUT2_toggle;
} global;

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
layout(set = 0, binding = 3) uniform sampler2D SamplerLUT1;
layout(set = 0, binding = 4) uniform sampler2D SamplerLUT2;


// White Point Mapping function
//
// From the first comment post (sRGB primaries and linear light compensated)
//      http://www.zombieprototypes.com/?p=210#comment-4695029660
// Based on the Neil Bartlett's blog update
//      http://www.zombieprototypes.com/?p=210
// Inspired itself by Tanner Helland's work
//      http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/

// https://en.wikipedia.org/wiki/Standard_illuminant#White_points_of_standard_illuminants
// PAL: ~D65 NTSC-U: D65  NTSC-J: D93  NTSC-FCC: C
// PAL: 6489 NTSC-U: 6504 NTSC-J: 9305 NTSC-FCC: 6774 *correlated

vec3 wp_adjust(vec3 color){

    float temp = global.wp_temperature / 100.;
    float k = global.wp_temperature / 10000.;
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

    // Linear color input
    return color * wp;
}

vec3 sRGB_to_XYZ(vec3 RGB){

    const mat3x3 m = mat3x3(
    0.412390799, 0.357584339, 0.180480788,
    0.212639006, 0.715168679, 0.072192315,
    0.019330819, 0.11919478,  0.950532152);
    return RGB * m;
}


vec3 XYZtoYxy(vec3 XYZ){

    float XYZrgb = XYZ.r+XYZ.g+XYZ.b;
    float Yxyg = (XYZrgb <= 0.0) ? 0.3805 : XYZ.r / XYZrgb;
    float Yxyb = (XYZrgb <= 0.0) ? 0.3769 : XYZ.g / XYZrgb;
    return vec3(XYZ.g, Yxyg, Yxyb);
}


vec3 YxytoXYZ(vec3 Yxy){

    float Xs = Yxy.r * (Yxy.g/Yxy.b);
    float Xsz = (Yxy.r <= 0.0) ? 0.0 : 1.0;
    vec3 XYZ = vec3(Xsz,Xsz,Xsz) * vec3(Xs, Yxy.r, (Xs/Yxy.g)-Xs-Yxy.r);
    return XYZ;
}


vec3 XYZ_to_sRGB(vec3 XYZ){

    const mat3x3 m = mat3x3(
    3.240969942, -1.537383178, -0.49861076,
   -0.969243636,  1.875967502,  0.041555057,
    0.055630080, -0.203976959,  1.056971514);
   return XYZ * m;
}


//  This shouldn't be necessary but it seems some undefined values can
//  creep in and each GPU vendor handles that differently. This keeps
//  all values within a safe range
vec3 mixfix(vec3 a, vec3 b, float c)
{
    return (a.z < 1.0) ? mix(a, b, c) : a;
}


vec4 mixfix_v4(vec4 a, vec4 b, float c)
{
    return (a.z < 1.0) ? mix(a, b, c) : a;
}


float SatMask(float color_r, float color_g, float color_b)
{
    float max_rgb = max(color_r, max(color_g, color_b));
    float min_rgb = min(color_r, min(color_g, color_b));
    float msk = clamp((max_rgb - min_rgb) / (max_rgb + min_rgb), 0.0, 1.0);
    return msk;
}


float moncurve_f( float color, float gamma, float offs)
{
    // Forward monitor curve
    color = clamp(color, 0.0, 1.0);
    float fs = (( gamma - 1.0) / offs) * pow( offs * gamma / ( ( gamma - 1.0) * ( 1.0 + offs)), gamma);
    float xb = offs / ( gamma - 1.0);

    color = ( color > xb) ? pow( ( color + offs) / ( 1.0 + offs), gamma) : color * fs;
    return color;
}


vec3 moncurve_f_f3( vec3 color, float gamma, float offs)
{
    color.r = moncurve_f( color.r, gamma, offs);
    color.g = moncurve_f( color.g, gamma, offs);
    color.b = moncurve_f( color.b, gamma, offs);
    return color.rgb;
}


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


//  Performs better in gamma encoded space
float contrast_sigmoid(float color, float cont, float pivot){

    cont = pow(cont + 1., 3.);

    float knee = 1. / (1. + exp(cont * pivot));
    float shldr = 1. / (1. + exp(cont * (pivot - 1.)));

    color = (1. / (1. + exp(cont * (pivot - color))) - knee) / (shldr - knee);

    return color;
}


//  Performs better in gamma encoded space
float contrast_sigmoid_inv(float color, float cont, float pivot){

    cont = pow(cont - 1., 3.);

    float knee = 1. / (1. + exp (cont * pivot));
    float shldr = 1. / (1. + exp (cont * (pivot - 1.)));

    color = pivot - log(1. / (color * (shldr - knee) + knee) - 1.) / cont;

    return color;
}


float rolled_gain(float color, float gain){

    float gx = gain + 1.0;
    float ax = (max(0.5 - (gx / 2.0), 0.5));
    float cx = (gx > 0.0) ? (1.0 - gx + (gx / 2.0)) : abs(gx) / 2.0;

    float gain_plus = ((color * gx) > ax) ? (ax + cx * tanh((color * gx - ax) / cx)) : (color * gx);
    float ax_g = 1.0 - abs(gx);
    float gain_minus = (color > ax_g) ? (ax_g + cx * tanh((color - ax_g) / cx)) : color;
    color = (gx > 0.0) ? gain_plus : gain_minus;

    return color;
}

vec4 rolled_gain_v4(vec4 color, float gain){

    color.r = rolled_gain(color.r, gain);
    color.g = rolled_gain(color.g, gain);
    color.b = rolled_gain(color.b, gain);

    return vec4(color.rgb, 1.0);
}


//  Borrowed from cgwg's crt-geom, under GPL
float corner(vec2 coord)
{
    coord *= global.OriginalSize.xy / global.SourceSize.xy;
    coord = (coord - vec2(0.5)) * 1.0 + vec2(0.5);
    coord = min(coord, vec2(1.0)-coord) * vec2(1.0, global.OutputSize.y/global.OutputSize.x);
    vec2 cdist = vec2(max(params.g_csize, max((1.0-smoothstep(100.0,600.0,params.g_bsize))*0.01,0.002)));
    coord = (cdist - min(coord,cdist));
    float dist = sqrt(dot(coord,coord));
    return clamp((cdist.x-dist)*params.g_bsize,0.0, 1.0);
}


vec3 RGB_YIQ(vec3 col)
 {
    mat3 conv_mat = mat3(
    0.299996928307425,  0.590001575542717,  0.110001496149858,
    0.599002392519453, -0.277301256521204, -0.321701135998249,
    0.213001700342824, -0.52510120528935,  0.312099504946526);

    return col.rgb *= conv_mat;
 }

vec3 YIQ_RGB(vec3 col)
 {
    mat3 conv_mat = mat3(
    1.0,  0.946882217090069,  0.623556581986143,
    1.0, -0.274787646298978, -0.635691079187380,
    1.0, -1.108545034642030,  1.709006928406470);

    return col.rgb *= conv_mat;
 }

vec3 RGB_YUV(vec3 RGB)
 {
     mat3 conv_mat = mat3(
     0.299,    0.587,   0.114,
    -0.14713,-0.28886,  0.436,
     0.615, -0.514991, -0.10001);

    return RGB.rgb *= conv_mat;
 }

vec3 YUV_RGB(vec3 YUV)
 {
     mat3 conv_mat = mat3(
     1.000, 0.000,   1.13983,
     1.000,-0.39465,-0.58060,
     1.000, 2.03211, 0.00000);

    return YUV.rgb *= conv_mat;
 }


// to Studio Swing or SMPTE legal (in YIQ space) (for footroom and headroom)
vec3 PCtoTV(vec3 col)
{
   col *= 255.;
   col.x = ((col.x * 219.) / 255.) + 16.;
   col.y = (((col.y - 128.) * 224.) / 255.) + 112.;
   col.z = (((col.z - 128.) * 224.) / 255.) + 112.;
   return col.xyz / 255.;
}


// to Full Swing (in YIQ space)
vec3 TVtoPC(vec3 col)
{
   col *= 255.;
   float colx = ((col.x - 16.) / 219.) * 255.;
   float coly = (((col.y - 112.) / 224.) * 255.) + 128.;
   float colz = (((col.z - 112.) / 224.) * 255.) + 128.;
   return vec3(colx,coly,colz) / 255.;
}


// in XYZ space
const mat3 C_D65_Brad = 
mat3(
 1.0063, 0.0029, -0.0071,
 0.0036, 0.9992, -0.0024,
-0.0013, 0.0022,  0.9645);

// in XYZ space
const mat3 D93_D65_Brad = 
mat3(
 1.0472, 0.0198, -0.0476,
 0.0250, 0.9988, -0.0160,
-0.0090, 0.0148,  0.7659);

// in XYZ space
const mat3 PAL_D65_Brad = 
mat3(
 0.9992, -0.0005, 0.0003,
-0.0007,  1.0005, 0.0001,
 0.0000, -0.0000, 1.0008);


// Generic CRT NTSC Standard Phosphor
const mat3 P22_transform = 
mat3(
 0.4665, 0.2566, 0.0058,
 0.3039, 0.6682, 0.1056,
 0.1800, 0.0752, 0.9776);

// use with Illuminant C white point
const mat3 NTSC_FCC_transform = 
mat3(
 0.5803, 0.2858, 0.0000,
 0.1791, 0.6055, 0.0682,
 0.1902, 0.1087, 1.0599);

// Conrac phosphor gamut
const mat3 SMPTE_transform = 
mat3(
 0.3935, 0.2124, 0.0187,
 0.3653, 0.7011, 0.1119,
 0.1917, 0.0866, 0.9584);

// SMPTE compliant Conrad 7211N19 CRT
const mat3 Conrad_transform = 
mat3(
 0.5584, 0.2858, 0.0352,
 0.2061, 0.6371, 0.0937,
 0.1859, 0.0771, 0.9602);

// use with D93 white point
const mat3 NTSC_J_transform = 
mat3(
 0.3960, 0.2243, 0.0205,
 0.3120, 0.6742, 0.1281,
 0.2450, 0.1015, 1.2651);

// PAL phosphor gamut
const mat3 EBU_transform = 
mat3(
 0.4319, 0.2227, 0.0202,
 0.3412, 0.7060, 0.1294,
 0.1782, 0.0713, 0.9385);

// Sony Trinitron KV-20M20 (D93 assumed)
const mat3 Sony20_20_transform = 
mat3(
 0.3863, 0.2101, 0.0216,
 0.3191, 0.6780, 0.1538,
 0.2477, 0.1118, 1.2383);



void main()
{

//  Analogue Color Knobs
    vec3 source = texture(Source, vTexCoord.xy).rgb;
    vec3 col = (crtgamut == 5.0) ? RGB_YUV(source) : \
               (crtgamut == 4.0) ? RGB_YIQ(source) : \
                                   PCtoTV(RGB_YIQ(source));

    float hue_radians = hue_degrees * (M_PI / 180.0);
    float hue = atan(col.z, col.y) + hue_radians;
    float chroma = sqrt(col.z * col.z + col.y * col.y);
    col = vec3(col.x, chroma * cos(hue), chroma * sin(hue));

    col.y = mod((col.y + 1.0) + I_SHIFT, 2.0) - 1.0;
    col.z = mod((col.z + 1.0) + Q_SHIFT, 2.0) - 1.0;

    col.z *= Q_MUL;
    col.y *= I_MUL;

    float TV_lvl = (crtgamut == 5.0) ? 0.0627  : \
                   (crtgamut == 4.0) ? 0.0627  : \
                                       0.0;

    col = (crtgamut == 5.0) ? clamp(col.xyz,vec3(0.0627-TV_lvl,0.0627-0.5-TV_lvl,0.0627-0.5-TV_lvl),vec3(0.92157,0.94118-0.5,0.94118-0.5)) : \
							  clamp(col.xyz,vec3(0.0627-TV_lvl,-0.5957-TV_lvl,  -0.5226-TV_lvl),    vec3(0.92157,0.5957,0.5226));

    col = (crtgamut == 0.0) ? source       : \
          (crtgamut == 5.0) ? YUV_RGB(col) : \
          (crtgamut == 4.0) ? YIQ_RGB(col) : \
                              YIQ_RGB(TVtoPC(col));

//  OETF - Opto-Electronic Transfer Function
    vec3 imgColor = (gamma_type == 2.0) ? moncurve_f_f3(col, gamma_in - 0.18, 0.1115) : (gamma_type == 1.0) ? moncurve_f_f3(col, gamma_in, 0.055) : pow(col, vec3(gamma_in));


//  Look LUT
    float red = (imgColor.r * (global.LUT_Size1 - 1.0) + 0.4999) / (global.LUT_Size1 * global.LUT_Size1);
    float green = (imgColor.g * (global.LUT_Size1 - 1.0) + 0.4999) / global.LUT_Size1;
    float blue1 = (floor(imgColor.b * (global.LUT_Size1 - 1.0)) / global.LUT_Size1) + red;
    float blue2 = (ceil(imgColor.b * (global.LUT_Size1 - 1.0)) / global.LUT_Size1) + red;
    float mixer = clamp(max((imgColor.b - blue1) / (blue2 - blue1), 0.0), 0.0, 32.0);
    vec3 color1 = texture(SamplerLUT1, vec2(blue1, green)).rgb;
    vec3 color2 = texture(SamplerLUT1, vec2(blue2, green)).rgb;
    vec3 vcolor = (global.LUT1_toggle == 0.0) ? imgColor : mixfix(color1, color2, mixer);


//  Saturation agnostic sigmoidal contrast
    vec3 Yxy = XYZtoYxy(sRGB_to_XYZ(vcolor));
    float toGamma = clamp(moncurve_r(Yxy.r, 2.40, 0.055), 0.0, 1.0);
    toGamma = (Yxy.r > 0.5) ? contrast_sigmoid_inv(toGamma, 2.3, 0.5) : toGamma;
    float sigmoid = (cntrst > 0.0) ? contrast_sigmoid(toGamma, cntrst, mid) : contrast_sigmoid_inv(toGamma, cntrst, mid);
    vec3 contrast = vec3(moncurve_f(sigmoid, 2.40, 0.055), Yxy.g, Yxy.b);
    vec3 XYZsrgb = clamp(XYZ_to_sRGB(YxytoXYZ(contrast)), 0.0, 1.0);
    contrast = (cntrst == 0.0) ? vcolor : XYZsrgb;


//  Vignetting & Black Level
    vec2 vpos = vTexCoord*(global.OriginalSize.xy/global.SourceSize.xy);

    vpos *= 1.0 - vpos.xy;
    float vig = vpos.x * vpos.y * vstr;
    vig = min(pow(vig, vpower), 1.0);
    contrast *= (vignette == 1.0) ? vig : 1.0;

    contrast += (lift / 20.0) * (1.0 - contrast);


//  RGB Related Transforms
    vec4 screen = vec4(max(contrast, 0.0), 1.0);
    float sat = v_sat + 1.0;

                   //  r    g    b  alpha ; alpha does nothing for our purposes
    mat4 color = mat4(wlr, rg,  rb,   0.0,              //red tint
                      gr,  wlg, gb,   0.0,              //green tint
                      br,  bg,  wlb,  0.0,              //blue tint
                      blr/20., blg/20., blb/20., 0.0);  //black tint

    mat4 adjust = mat4((1.0 - sat) * 0.2126 + sat, (1.0 - sat) * 0.2126, (1.0 - sat) * 0.2126, 1.0,
                       (1.0 - sat) * 0.7152, (1.0 - sat) * 0.7152 + sat, (1.0 - sat) * 0.7152, 1.0,
                       (1.0 - sat) * 0.0722, (1.0 - sat) * 0.0722, (1.0 - sat) * 0.0722 + sat, 1.0,
                        0.0, 0.0, 0.0, 1.0);

    screen = clamp(rolled_gain_v4(screen, lum * 2.0), 0.0, 1.0);
    screen = color * screen;
    float sat_msk = (vibr > 0.0) ? clamp(1.0 - (SatMask(screen.r, screen.g, screen.b) * vibr), 0.0, 1.0) : clamp(1.0 - abs(SatMask(screen.r, screen.g, screen.b) - 1.0) * abs(vibr), 0.0, 1.0);
    screen = mixfix_v4(screen, adjust * screen, sat_msk);


//  CRT Phosphor Gamut
    mat3 m_in;

    if (crtgamut == 1.0) { m_in = NTSC_FCC_transform;           } else
    if (crtgamut == 2.0) { m_in = P22_transform;                } else
    if (crtgamut == 3.0) { m_in = SMPTE_transform;              } else
    if (crtgamut == 4.0) { m_in = NTSC_J_transform;             } else
    if (crtgamut == 5.0) { m_in = EBU_transform;                } else
    if (crtgamut == 6.0) { m_in = Sony20_20_transform;          } else
    if (crtgamut == 7.0) { m_in = Conrad_transform;             }

    vec3 gamut = (crtgamut == 1.0) ? (m_in*screen.rgb)*C_D65_Brad    : \
                 (crtgamut == 4.0) ? (m_in*screen.rgb)*D93_D65_Brad  : \
                 (crtgamut == 5.0) ? (m_in*screen.rgb)*PAL_D65_Brad  : \
                 (crtgamut == 6.0) ? (m_in*screen.rgb)*D93_D65_Brad  : \
                                      m_in*screen.rgb;

//  Color Temperature
    vec3 adjusted = (crtgamut == 0.0) ? wp_adjust(screen.rgb) : wp_adjust(XYZ_to_sRGB(gamut));
    vec3 base_luma = XYZtoYxy(gamut);
    vec3 adjusted_luma = XYZtoYxy(sRGB_to_XYZ(adjusted));
    adjusted = adjusted_luma + (vec3(base_luma.r, 0.0, 0.0) - vec3(adjusted_luma.r, 0.0, 0.0));
    adjusted = clamp(XYZ_to_sRGB(YxytoXYZ(adjusted)), 0.0, 1.0);


//  Technical LUT
    float red_2 = (adjusted.r * (global.LUT_Size2 - 1.0) + 0.4999) / (global.LUT_Size2 * global.LUT_Size2);
    float green_2 = (adjusted.g * (global.LUT_Size2 - 1.0) + 0.4999) / global.LUT_Size2;
    float blue1_2 = (floor(adjusted.b * (global.LUT_Size2 - 1.0)) / global.LUT_Size2) + red_2;
    float blue2_2 = (ceil(adjusted.b * (global.LUT_Size2 - 1.0)) / global.LUT_Size2) + red_2;
    float mixer_2 = clamp(max((adjusted.b - blue1_2) / (blue2_2 - blue1_2), 0.0), 0.0, 32.0);
    vec3 color1_2 = texture(SamplerLUT2, vec2(blue1_2, green_2)).rgb;
    vec3 color2_2 = texture(SamplerLUT2, vec2(blue2_2, green_2)).rgb;
    vec3 LUT2_output = mixfix(color1_2, color2_2, mixer_2);

    LUT2_output = (global.LUT2_toggle == 0.0) ? adjusted : LUT2_output;
    LUT2_output = (gamma_out == 1.00) ? LUT2_output : moncurve_r_f3(LUT2_output, gamma_out + 0.20, 0.055);

    vpos *= (global.SourceSize.xy/global.OriginalSize.xy);
    FragColor = vec4(LUT2_output*corner(vpos), 1.0);
}