#version 450

layout(push_constant) uniform Push
{
    float g_space_out;
    float g_gamma_in;
    float g_gamma_type;
    float g_crtgamut;
    float g_hue_degrees;
    float g_I_SHIFT;
    float g_Q_SHIFT;
    float g_I_MUL;
    float g_Q_MUL;
    float g_vignette;
    float g_vstr;
    float g_vpower;
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
   > Ubershader grouping some monolithic color related shaders:
    ::color-mangler (hunterk), ntsc color tuning knobs (Doriphor), white_point (hunterk, Dogway), lut_x2 (Guest, Dr. Venom).
   > and the addition of:
    ::analogue color emulation, phosphor gamut, color space + TRC support, vibrance, vignette (shared by Syh), black level, rolled gain and sigmoidal contrast.

   Author: Dogway
   License: Public domain


    ######################################...PRESETS...#######################################
    ##########################################################################################
    ###                                                                                    ###
    ###      PAL                                                                           ###
    ###          Gamut: EBU (#3) (or an EBU based CRT gamut)                               ###
    ###          WP: D65 (6504K)                                                           ###
    ###          TRC: 2.8 Gamma (POW or sRGB)*                                             ###
    ###          Saturation: -0.02                                                         ###
    ###                                                                                    ###
    ###      NTSC-U                                                                        ###
    ###          Gamut: SMPTE-C (#1)     (or a NTSC-U based CRT gamut)                     ###
    ###          WP: D65 (6504K)         (in practice more like ~8000K)                    ###
    ###          TRC: 2.22 SMPTE-C Gamma (in practice more like 2.35-2.55)                 ###
    ###                                                                                    ###
    ###      NTSC-J (Default)                                                              ###
    ###          Gamut: NTSC-J (#2)      (or a NTSC-J based CRT gamut)                     ###
    ###          WP: D93 (9305K)         (or keep D65 and set "I/Q = -0.04")               ###
    ###          TRC: 2.22 SMPTE-C Gamma (in practice more like 2.35-2.55)                 ###
    ###                                                                                    ###
    ###      *Despite the standard of 2.22, a good faithful approximation to CRT...        ###
    ###       ...is to use SMPTE-C gamma type with a value of 2.40-2.55 as "CRT Gamma".    ###
    ###                                                                                    ###
    ###                                                                                    ###
    ##########################################################################################
    ##########################################################################################
*/


#pragma parameter g_space_out "Diplay Color Space" 0.0 0.0 2.0 1.0
#pragma parameter g_gamma_in "CRT Gamma" 2.40 1.80 3.0 0.05
#pragma parameter g_gamma_type "Signal Gamma (POW:0, sRGB:1, SMPTE-C:2)" 2.0 0.0 2.0 1.0
#pragma parameter g_crtgamut "Gamut (1:NTSC-U 2:NTSC-J 3:PAL)" 2.0 -4.0 3.0 1.0
#pragma parameter g_hue_degrees "Hue" 0.0 -360.0 360.0 1.0
#pragma parameter g_I_SHIFT "I/U Shift" 0.0 -1.0 1.0 0.01
#pragma parameter g_Q_SHIFT "Q/V Shift" 0.0 -1.0 1.0 0.01
#pragma parameter g_I_MUL "I/U Multiplier" 1.0 0.0 2.0 0.01
#pragma parameter g_Q_MUL "Q/V Multiplier" 1.0 0.0 2.0 0.01
#pragma parameter g_vignette "Vignette Toggle" 1.0 0.0 1.0 1.0
#pragma parameter g_vstr "Vignette Strength" 40.0 0.0 50.0 1.0
#pragma parameter g_vpower "Vignette Power" 0.20 0.0 0.5 0.01
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
#define SPC             params.g_space_out
#define gamma_out       params.g_gamma_out
#define gamma_in        params.g_gamma_in
#define gamma_type      params.g_gamma_type
#define vignette        params.g_vignette
#define vstr            params.g_vstr
#define vpower          params.g_vpower
#define crtgamut        params.g_crtgamut
#define hue_degrees     params.g_hue_degrees
#define I_SHIFT         params.g_I_SHIFT
#define Q_SHIFT         params.g_Q_SHIFT
#define I_MUL           params.g_I_MUL
#define Q_MUL           params.g_Q_MUL
#define g_sat           params.g_sat
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


///////////////////////// Color Space Transformations //////////////////////////



vec3 XYZ_to_RGB(vec3 XYZ, float CSPC){

    // to sRGB
    const mat3x3 sRGB = mat3x3(
    3.24081254005432130, -0.969243049621582000,  0.055638398975133896,
   -1.53730857372283940,  1.875966310501098600, -0.204007431864738460,
   -0.49858659505844116,  0.041555050760507584,  1.057129383087158200);

    // to DCI-P3
    const mat3x3 DCIP3 = mat3x3(
     2.7253935337066650, -0.7951678037643433,  0.04124189168214798,
    -1.0180026292800903,  1.6897318363189697, -0.08763901889324188,
    -0.4401630759239197,  0.0226471945643425,  1.10092937946319580);

    // to Rec.2020
    const mat3x3 rec2020 = mat3x3(
     1.71660947799682620, -0.66668272018432620,  0.017642205581068993,
    -0.35566213726997375,  1.61647748947143550, -0.042776308953762054,
    -0.25336012244224550,  0.01576850563287735,  0.942228555679321300);


   return (CSPC == 2.0) ? rec2020 * XYZ : (CSPC == 1.0) ? DCIP3 * XYZ : sRGB * XYZ;
}


vec3 RGB_to_XYZ(vec3 RGB, float CSPC){

    // from sRGB
    const mat3x3 sRGB = mat3x3(
    0.41241079568862915, 0.21264933049678802, 0.019331756979227066,
    0.35758456587791443, 0.71516913175582890, 0.119194857776165010,
    0.18045382201671600, 0.07218152284622192, 0.950390160083770800);

    // from DCI-P3
    const mat3x3 DCIP3 = mat3x3(
    0.44516983628273010, 0.33465281128883360, 0.00000000000000000,
    0.17348529398441315, 0.72159516811370850, 0.05168478935956955,
    0.09819923341274261, 0.06274740397930145, 0.90735518932342530);

    // from Rec.2020
    const mat3x3 rec2020 = mat3x3(
    0.63697350025177000, 0.24840137362480164, 0.00000000000000000,
    0.15294560790061950, 0.67799961566925050, 0.04253686964511871,
    0.11785808950662613, 0.03913172334432602, 1.06084382534027100);

   return (CSPC == 2.0) ? rec2020 * RGB : (CSPC == 1.0) ? DCIP3 * RGB : sRGB * RGB;
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

///////////////////////// White Point Mapping function /////////////////////////
//
//
// From the first comment post (sRGB primaries and linear light compensated)
//    >> http://www.zombieprototypes.com/?p=210#comment-4695029660
// Based on the Neil Bartlett's blog update
//    >> http://www.zombieprototypes.com/?p=210
// Inspired itself by Tanner Helland's work
//    >> http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/
//
// PAL: D65  NTSC-U: D65  NTSC-J: D93  NTSC-FCC: C
// PAL: 6504 NTSC-U: 6504 NTSC-J: 9305 NTSC-FCC: 6779.65 *correlated from (0.310, 0.316)

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
    return color * XYZ_to_RGB(RGB_to_XYZ(wp, 0.), SPC);
}

////////////////////////////////////////////////////////////////////////////////


// Monitor Curve Functions: https://github.com/ampas/aces-dev
//----------------------------------------------------------------------


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


//-------------------------- Luma Functions ----------------------------


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


float SatMask(float color_r, float color_g, float color_b)
{
    float max_rgb = max(color_r, max(color_g, color_b));
    float min_rgb = min(color_r, min(color_g, color_b));
    float msk = clamp((max_rgb - min_rgb) / (max_rgb + min_rgb), 0.0, 1.0);
    return msk;
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


//---------------------- Range Expansion/Compression -------------------


//  to Studio Swing/Broadcast Safe/SMPTE legal
vec3 PCtoTV(vec3 col, float luma_swing, float Umax, float Vmax, float max_swing, bool rgb_in)
{
   col *= 255.;
   Umax = (max_swing == 1.0) ? Umax * 224. : Umax * 239.;
   Vmax = (max_swing == 1.0) ? Vmax * 224. : Vmax * 239.;

   col.x = (luma_swing == 1.0) ? ((col.x * 219.) / 255.) + 16. : col.x;
   col.y = (rgb_in == true) ? ((col.y * 219.) / 255.) + 16. : (((col.y - 128.) * (Umax * 2.)) / 255.) + Umax;
   col.z = (rgb_in == true) ? ((col.z * 219.) / 255.) + 16. : (((col.z - 128.) * (Vmax * 2.)) / 255.) + Vmax;
   return col.xyz / 255.;
}


//  to Full Swing
vec3 TVtoPC(vec3 col, float luma_swing, float Umax, float Vmax, float max_swing, bool rgb_in)
{
   col *= 255.;
   Umax = (max_swing == 1.0) ? Umax * 224. : Umax * 239.;
   Vmax = (max_swing == 1.0) ? Vmax * 224. : Vmax * 239.;

   float colx = (luma_swing == 1.0) ? ((col.x - 16.) / 219.) * 255. : col.x;
   float coly = (rgb_in == true) ? ((col.y - 16.) / 219.) * 255. : (((col.y - Umax) / (Umax * 2.)) * 255.) + 128.;
   float colz = (rgb_in == true) ? ((col.z - 16.) / 219.) * 255. : (((col.z - Vmax) / (Vmax * 2.)) * 255.) + 128.;
   return vec3(colx,coly,colz) / 255.;
}


//*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/


//--------------------- ITU-R BT.470/601 (M) (1953) --------------------


//  FCC (Sanctioned) YIQ matrix
vec3 RGB_FCC(vec3 col)
 {
    const mat3 conv_mat = mat3(
    0.299996928307425,  0.590001575542717,  0.110001496149858,
    0.599002392519453, -0.277301256521204, -0.321701135998249,
    0.213001700342824, -0.525101205289350,  0.312099504946526);

    return col.rgb * conv_mat;
 }

//  FCC (Sanctioned) YIQ matrix (inverse)
vec3 FCC_RGB(vec3 col)
 {
    const mat3 conv_mat = mat3(
    1.0000000,  0.946882217090069,  0.623556581986143,
    1.0000000, -0.274787646298978, -0.635691079187380,
    1.0000000, -1.108545034642030,  1.709006928406470);

    return col.rgb * conv_mat;
 }


//--------------------- SMPTE RP 145 (C), 170M (1987) ------------------


vec3 RGB_YIQ(vec3 col)
 {
    const mat3 conv_mat = mat3(
    0.2990,  0.5870,  0.1140,
    0.5959, -0.2746, -0.3213,
    0.2115, -0.5227,  0.3112);

    return col.rgb * conv_mat;
 }

vec3 YIQ_RGB(vec3 col)
 {
    const mat3 conv_mat = mat3(
    1.0000000,  0.956,  0.619,
    1.0000000, -0.272, -0.647,
    1.0000000, -1.106,  1.703);

    return col.rgb * conv_mat;
 }

//----------------------- ITU-R BT.470/601 (B/G) -----------------------


vec3 r601_YUV(vec3 RGB)
 {
    const mat3 conv_mat = mat3(
    0.299000,  0.587000,  0.114000,
   -0.147407, -0.289391,  0.436798,
    0.614777, -0.514799, -0.099978);

    return RGB.rgb * conv_mat;
 }

vec3 YUV_r601(vec3 RGB)
 {
    const mat3 conv_mat = mat3(
    1.0000000,  0.00000000000000000,  1.14025080204010000,
    1.0000000, -0.39393067359924316, -0.58080917596817020,
    1.0000000,  2.02839756011962900, -0.00000029356581166);

    return RGB.rgb * conv_mat;
 }

//  Custom - not Standard
vec3 YUV_r709(vec3 YUV)
 {
    const mat3 conv_mat = mat3(
    1.0000000,  0.0000000000000000,  1.14025092124938960,
    1.0000000, -0.2047683298587799, -0.33895039558410645,
    1.0000001,  2.0283975601196290,  0.00000024094399364);

    return YUV.rgb * conv_mat;
 }

//  Custom - not Standard
vec3 r709_YUV(vec3 RGB)
 {
    const mat3 conv_mat = mat3(
    0.2126000,  0.715200,   0.0722000,
   -0.1048118, -0.3525936,  0.4574054,
    0.6905498, -0.6272304, -0.0633194);

    return RGB.rgb * conv_mat;
 }


//------------------------- SMPTE-240M Y’PbPr --------------------------


//  RGB to YPbPr with Rec.601 primaries
vec3 r601_YCC(vec3 RGB)
 {
    const mat3 conv_mat = mat3(
    0.299,                   0.587,                   0.114,
   -0.16873589164785553047, -0.33126410835214446953,  0.500,
    0.500,                  -0.41868758915834522111, -0.08131241084165477889);

    return RGB.rgb * conv_mat;
 }

//  YPbPr to RGB with Rec.601 primaries
vec3 YCC_r601(vec3 YUV)
 {
    const mat3 conv_mat = mat3(
    1.0000000,  0.000,                   1.402,
    1.0000000, -0.34413628620102214651, -0.71413628620102214651,
    1.0000000,  1.772,                   0.000);

    return YUV.rgb * conv_mat;
 }

//  RGB to YPbPr with Rec.709 primaries
vec3 r709_YCC(vec3 RGB)
 {
    const mat3 conv_mat = mat3(
    0.2126,                  0.7152,                  0.0722,
   -0.11457210605733994395, -0.38542789394266005605,  0.5000,
    0.5000,                 -0.45415290830581661163, -0.04584709169418338837);

    return RGB.rgb * conv_mat;
 }

//  YPbPr to RGB with Rec.709 primaries
vec3 YCC_r709(vec3 YUV)
 {
    const mat3 conv_mat = mat3(
    1.0000000,  0.00000000000000000000,  1.5748,
    1.0000000, -0.18732427293064876957, -0.46812427293064876957,
    1.0000000,  1.8556,                  0.00000000000000000000);

    return YUV.rgb * conv_mat;
 }



//*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/



const mat3 C_D65_Brad =
mat3(
 1.0062731504440308000, 0.0028941007331013680, -0.0070838485844433310,
 0.0036507491022348404, 0.9992200732231140000, -0.0023814644664525986,
-0.0013438384048640728, 0.0022154981270432472,  0.9643852710723877000);

const mat3 D93_D65_Brad =
mat3(
 1.047182083129882800, 0.019761435687541960, -0.047600898891687390,
 0.025015428662300110, 0.998820304870605500, -0.016028285026550293,
-0.008994228206574917, 0.014804697595536709,  0.765806019306182900);


//----------------------------------------------------------------------


// ITU-R BT.470/601 (M) (proof of concept, actually never used)
// NTSC-FCC 1953 Standard Phosphor (use with temperature C: 6780K)
const mat3 NTSC_FCC_transform =
mat3(
 0.60699284076690670, 0.2989666163921356, 0.00000000000000000,
 0.17344850301742554, 0.5864211320877075, 0.06607561558485031,
 0.20057128369808197, 0.1146121546626091, 1.11746847629547120);

// ITU-R BT.470/601 (M)
// Conrac 7211N19 CRT Phosphor
const mat3 Conrac_transform =
mat3(
 0.55842006206512450, 0.28580552339553833, 0.03517606481909752,
 0.20613566040992737, 0.63714659214019780, 0.09369802474975586,
 0.18589359521865845, 0.07704800367355347, 0.96004259586334230);

// NTSC-J (use with D93 white point)
// Sony Trinitron KV-20M20
const mat3 Sony20_20_transform =
mat3(
 0.38629359006881714, 0.21014373004436493, 0.021632442250847816,
 0.31906270980834960, 0.67800831794738770, 0.153833806514740000,
 0.24766337871551514, 0.11184798181056976, 1.238316893577575700);

// SMPTE RP 145 (C), 170M
// SMPTE-C - Measured Average Phosphor
const mat3 P22_transform =
mat3(
 0.4665636420249939, 0.25661000609397890, 0.005832045804709196,
 0.3039233088493347, 0.66820019483566280, 0.105618737637996670,
 0.1799621731042862, 0.07518967241048813, 0.977465748786926300);

// SMPTE RP 145 (C), 170M
// SMPTE-C - Standard Phosphor
const mat3 SMPTE_transform =
mat3(
 0.39354196190834045, 0.21238772571086884, 0.01874009333550930,
 0.36525884270668030, 0.70106136798858640, 0.11193416267633438,
 0.19164848327636720, 0.08655092865228653, 0.95824241638183590);

// NTSC-J (use with D93 white point)
// NTSC-J - Standard Phosphor
const mat3 NTSC_J_transform =
mat3(
 0.39603787660598755, 0.22429330646991730, 0.02050681784749031,
 0.31201449036598206, 0.67417418956756590, 0.12814880907535553,
 0.24496731162071228, 0.10153251141309738, 1.26512730121612550);

// ITU-R BT.470/601 (B/G)
// EBU PAL - Standard Phosphor
const mat3 EBU_transform =
mat3(
 0.43057379126548767, 0.22201462090015410, 0.020183145999908447,
 0.34154993295669556, 0.70665508508682250, 0.129553422331810000,
 0.17832535505294800, 0.07133013755083084, 0.939180195331573500);






void main()
{

    vec3 src = texture(Source, vTexCoord.xy).rgb;
         src = moncurve_f_f3(src, 2.40, 0.055);

    vec3 gamma_fix = (gamma_type == 2.0) ? moncurve_r_f3(src,         gamma_in + 0.077778,  0.099)  : \
                     (gamma_type == 1.0) ? moncurve_r_f3(src,         gamma_in,             0.055)  : \
                                               clamp(pow(src, vec3(1./gamma_in)), 0.0, 1.0)         ;

    vec3 col = r709_YCC(gamma_fix);

    col = (crtgamut ==  3.0) ? r601_YUV(YCC_r601(col))   : \
          (crtgamut ==  2.0) ?  RGB_YIQ(YCC_r601(col))   : \
          (crtgamut == -3.0) ?  RGB_FCC(YCC_r601(col))   : \
          (crtgamut == -4.0) ?  RGB_FCC(YCC_r601(col))   : \
                                RGB_YIQ(YCC_r601(col))   ;

// Clipping Logic / Gamut Limiting
    vec2 UVmax = (crtgamut ==  3.0) ? vec2(0.436798,          0.614777)          : \
                 (crtgamut == -4.0) ? vec2(0.599002392519453, 0.312099504946526) : \
                 (crtgamut == -3.0) ? vec2(0.599002392519453, 0.312099504946526) : \
                                      vec2(0.5959,            0.3112)            ;


    col = (crtgamut ==  3.0) ?        col                                       : \
          (crtgamut ==  2.0) ?        col                                       : \
          (crtgamut == -3.0) ? PCtoTV(col, 1.0, UVmax.x, UVmax.y, 1.0, false)   : \
          (crtgamut == -4.0) ? PCtoTV(col, 1.0, UVmax.x, UVmax.y, 1.0, false)   : \
                               PCtoTV(col, 1.0, UVmax.x, UVmax.y, 1.0, false)   ;

// YIQ/YUV Analogue Color Controls
    float hue_radians = hue_degrees * (M_PI / 180.0);
    float hue = atan(col.z, col.y) + hue_radians;
    float chroma = sqrt(col.z * col.z + col.y * col.y);
    col = vec3(col.x, chroma * cos(hue), chroma * sin(hue));

    col.y = (mod((col.y + 1.0) + I_SHIFT, 2.0) - 1.0) * I_MUL;
    col.z = (mod((col.z + 1.0) + Q_SHIFT, 2.0) - 1.0) * Q_MUL;


// Back to RGB

    col = (crtgamut ==  3.0) ?        col                                       : \
          (crtgamut ==  2.0) ?        col                                       : \
          (crtgamut == -3.0) ? TVtoPC(col, 1.0, UVmax.x, UVmax.y, 1.0, false)   : \
          (crtgamut == -4.0) ? TVtoPC(col, 1.0, UVmax.x, UVmax.y, 1.0, false)   : \
                               TVtoPC(col, 1.0, UVmax.x, UVmax.y, 1.0, false)   ;

    col = (crtgamut ==  3.0) ?     YUV_r601(col)    : \
          (crtgamut ==  2.0) ?      YIQ_RGB(col)    : \
          (crtgamut == -3.0) ?      FCC_RGB(col)    : \
          (crtgamut == -4.0) ?      FCC_RGB(col)    : \
                                    YIQ_RGB(col)    ;

// Gamut Clipping and Conversion to Rec.709 (todo: study other "intents")
    col = clamp(col, 0.0, 1.0);
    col = YCC_r709(r601_YCC(col));
    col = clamp(col, 0.0, 1.0);

// OETF - Opto-Electronic Transfer Function
    vec3 imgColor = (crtgamut == 0.0) ? src                                          : \
                         (SPC == 2.0) ? moncurve_f_f3(col,  2.20 + 0.022222, 0.0993) : \
                         (SPC == 1.0) ? pow(col, vec3(      2.20 + 0.40))            : \
                                        moncurve_f_f3(col,  2.20 + 0.20,     0.055)  ;


// Look LUT - (in sRGB space)
    float red =   (imgColor.r * (global.LUT_Size1 - 1.0) + 0.4999) / (global.LUT_Size1 * global.LUT_Size1);
    float green = (imgColor.g * (global.LUT_Size1 - 1.0) + 0.4999) /  global.LUT_Size1;
    float blue1 = (floor(imgColor.b * (global.LUT_Size1 - 1.0)) / global.LUT_Size1) + red;
    float blue2 =  (ceil(imgColor.b * (global.LUT_Size1 - 1.0)) / global.LUT_Size1) + red;
    float mixer = clamp(max((imgColor.b - blue1) / (blue2 - blue1), 0.0), 0.0, 32.0);
    vec3 color1 = texture(SamplerLUT1, vec2(blue1, green)).rgb;
    vec3 color2 = texture(SamplerLUT1, vec2(blue2, green)).rgb;
    vec3 vcolor = (global.LUT1_toggle == 0.0) ? imgColor : mixfix(color1, color2, mixer);

    vcolor = RGB_to_XYZ(vcolor, 0.);


// Sigmoidal Contrast
    vec3 Yxy = XYZtoYxy(vcolor);
    float toGamma = clamp(moncurve_r(Yxy.r, 2.40, 0.055), 0.0, 1.0);
    toGamma = (Yxy.r > 0.5) ? contrast_sigmoid_inv(toGamma, 2.3, 0.5) : toGamma;
    float sigmoid = (cntrst > 0.0) ? contrast_sigmoid(toGamma, cntrst, mid) : contrast_sigmoid_inv(toGamma, cntrst, mid);
    vec3 contrast = vec3(moncurve_f(sigmoid, 2.40, 0.055), Yxy.g, Yxy.b);
    vec3 XYZsrgb = clamp(XYZ_to_RGB(YxytoXYZ(contrast), SPC), 0.0, 1.0);
    contrast = (cntrst == 0.0) ? XYZ_to_RGB(vcolor, SPC) : XYZsrgb;


// Vignetting & Black Level
    vec2 vpos = vTexCoord*(global.OriginalSize.xy/global.SourceSize.xy);

    vpos *= 1.0 - vpos.xy;
    float vig = vpos.x * vpos.y * vstr;
    vig = min(pow(vig, vpower), 1.0);
    contrast *= (vignette == 1.0) ? vig : 1.0;

    contrast += (lift / 20.0) * (1.0 - contrast);


// RGB Related Transforms
    vec4 screen = vec4(max(contrast, 0.0), 1.0);
    float sat = g_sat + 1.0;

                   //  r    g    b  alpha ; alpha does nothing for our purposes
    mat4 color = mat4(wlr, rg,  rb,   0.0,              //red tint
                      gr,  wlg, gb,   0.0,              //green tint
                      br,  bg,  wlb,  0.0,              //blue tint
                      blr/20., blg/20., blb/20., 0.0);  //black tint


    vec3 coeff = (SPC == 2.) ? vec3(0.20949168503284454, 0.7215951681137085,  0.0689130499958992000) : \
                 (SPC == 1.) ? vec3(0.29749885201454160, 0.7059980034828186, -0.0034969625994563103) : \
                               vec3(0.21263903379440308, 0.7151687145233154,  0.0721923187375068700) ;


    mat4 adjust = mat4((1.0 - sat) * coeff.x + sat, (1.0 - sat) * coeff.x, (1.0 - sat) * coeff.x, 1.0,
                       (1.0 - sat) * coeff.y, (1.0 - sat) * coeff.y + sat, (1.0 - sat) * coeff.y, 1.0,
                       (1.0 - sat) * coeff.z, (1.0 - sat) * coeff.z, (1.0 - sat) * coeff.z + sat, 1.0,
                        0.0, 0.0, 0.0, 1.0);


    screen = clamp(rolled_gain_v4(screen, lum * 2.0), 0.0, 1.0);
    screen = color * screen;
    float sat_msk = (vibr > 0.0) ? clamp(1.0 -    (SatMask(screen.r, screen.g, screen.b) * vibr),            0.0, 1.0) : \
                                   clamp(1.0 - abs(SatMask(screen.r, screen.g, screen.b) - 1.0) * abs(vibr), 0.0, 1.0) ;

    screen = mixfix_v4(screen, clamp(adjust * screen, 0.0, 1.0), sat_msk);


// CRT Phosphor Gamut
    mat3 m_in;

    if (crtgamut == -4.0) { m_in = NTSC_FCC_transform;          } else
    if (crtgamut == -3.0) { m_in = Conrac_transform;            } else
    if (crtgamut == -2.0) { m_in = Sony20_20_transform;         } else
    if (crtgamut == -1.0) { m_in = P22_transform;               } else
    if (crtgamut ==  1.0) { m_in = SMPTE_transform;             } else
    if (crtgamut ==  2.0) { m_in = NTSC_J_transform;            } else
    if (crtgamut ==  3.0) { m_in = EBU_transform;               }

    vec3 gamut = (crtgamut == -4.0) ? (m_in*screen.rgb)*C_D65_Brad    : \
                 (crtgamut == -3.0) ? (m_in*screen.rgb)*C_D65_Brad    : \
                 (crtgamut == -2.0) ? (m_in*screen.rgb)*D93_D65_Brad  : \
                 (crtgamut ==  2.0) ? (m_in*screen.rgb)*D93_D65_Brad  : \
                                       m_in*screen.rgb;

// White Point Mapping
    vec3 adjusted =  (crtgamut == 0.0) ?           wp_adjust(screen.rgb)       : wp_adjust(XYZ_to_RGB(gamut, SPC));
    vec3 base_luma = (crtgamut == 0.0) ? XYZtoYxy(RGB_to_XYZ(screen.rgb, SPC)) :             XYZtoYxy(gamut);
    vec3 adjusted_luma =                 XYZtoYxy(RGB_to_XYZ(adjusted,   SPC)) ;
    adjusted = adjusted_luma + (vec3(base_luma.r, 0.0, 0.0) - vec3(adjusted_luma.r, 0.0, 0.0));
    adjusted = clamp(XYZ_to_RGB(YxytoXYZ(adjusted), SPC), 0.0, 1.0);


// Technical LUT - (in SPC space)
    float red_2 =   (adjusted.r * (global.LUT_Size2 - 1.0) + 0.4999) / (global.LUT_Size2 * global.LUT_Size2);
    float green_2 = (adjusted.g * (global.LUT_Size2 - 1.0) + 0.4999) / global.LUT_Size2;
    float blue1_2 = (floor(adjusted.b * (global.LUT_Size2 - 1.0)) / global.LUT_Size2) + red_2;
    float blue2_2 =  (ceil(adjusted.b * (global.LUT_Size2 - 1.0)) / global.LUT_Size2) + red_2;
    float mixer_2 = clamp(max((adjusted.b - blue1_2) / (blue2_2 - blue1_2), 0.0), 0.0, 32.0);
    vec3 color1_2 = texture(SamplerLUT2, vec2(blue1_2, green_2)).rgb;
    vec3 color2_2 = texture(SamplerLUT2, vec2(blue2_2, green_2)).rgb;
    vec3 LUT2_output = mixfix(color1_2, color2_2, mixer_2);

    LUT2_output = (global.LUT2_toggle == 0.0) ? adjusted : LUT2_output;

// EOTF - Electro-Optical Transfer Function
    vec3 TRC = (SPC == 2.0) ? moncurve_r_f3(LUT2_output,          2.20 + 0.022222, 0.0993)   : \
               (SPC == 1.0) ?     clamp(pow(LUT2_output, vec3(1./(2.20 + 0.40))),  0.0, 1.0) : \
                              moncurve_r_f3(LUT2_output,          2.20 + 0.20,     0.055)    ;

    FragColor = vec4(TRC, 1.0);
}