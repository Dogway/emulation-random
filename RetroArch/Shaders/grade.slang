#version 450

layout(push_constant) uniform Push
{
    float g_gamma_in;
    float g_gamma_type;
    float g_vignette;
    float g_vstr;
    float g_vpower;
    float g_crtgamut;
    float I_SHIFT;
    float Q_SHIFT;
    float I_MUL;
    float Q_MUL;
    float wp_temperature;
    float g_sat;
    float g_vibr;
    float g_lum;
    float g_cntrst;
    float g_mid;
    float g_lift;
    float wlr;
    float wlg;
    float wlb;
    float rg;
    float rb;
    float gr;
    float gb;
    float br;
    float bg;
    float g_csize;
    float g_bsize;
    float LUT_Size1;
    float LUT1_toggle;
    float LUT_Size2;
    float LUT2_toggle;
} params;

/*
   Grade
   > Ubershader grouping some color related monolithic shaders like color-mangler, lut_x2, white_point and crt-gamut...
   > and the addition of vibrance, vignette, black level, corner size, rolled gain, sigmoidal contrast and proper gamma transforms.

   Author: hunterk, Guest, Dr. Venom, Dogway
   License: Public domain
*/

#pragma parameter g_gamma_in "CRT Gamma" 2.40 0.0 3.0 0.05
#pragma parameter g_gamma_type "CRT Gamma (POW:0, sRGB:1, SMPTE-C:2)" 2.0 0.0 2.0 1.0
#pragma parameter g_vignette "Vignette Toggle" 1.0 0.0 1.0 1.0
#pragma parameter g_vstr "Vignette Strength" 40.0 0.0 50.0 1.0
#pragma parameter g_vpower "Vignette Power" 0.20 0.0 0.5 0.01
#pragma parameter g_crtgamut "CRT gamut" 0.0 0.0 9.0 1.0
#pragma parameter I_SHIFT "I/U Shift" 0.0 -1.0 1.0 0.02
#pragma parameter Q_SHIFT "Q/V Shift" 0.0 -1.0 1.0 0.02
#pragma parameter I_MUL "I/U Multiplier" 1.0 0.0 2.0 0.1
#pragma parameter Q_MUL "Q/V Multiplier" 1.0 0.0 2.0 0.1
#pragma parameter wp_temperature "White Point" 9305.0 1621.0 12055.0 50.0
#pragma parameter g_sat "Saturation" 0.0 -1.0 2.0 0.02
#pragma parameter g_vibr "Dullness/Vibrance" 0.0 -1.0 1.0 0.05
#pragma parameter g_lum "Brightness" 0.0 -0.5 1.0 0.01
#pragma parameter g_cntrst "Contrast" 0.0 -1.0 1.0 0.05
#pragma parameter g_mid "Contrast Pivot" 0.5 0.0 1.0 0.01
#pragma parameter g_lift "Black Level" 0.0 -0.5 0.5 0.01
#pragma parameter wlr "White-Red Tint" 1.0 0.0 2.0 0.01
#pragma parameter wlg "White-Green Tint" 1.0 0.0 2.0 0.01
#pragma parameter wlb "White-Blue Tint" 1.0 0.0 2.0 0.01
#pragma parameter rg "Red-Green Tint" 0.0 -1.0 1.0 0.005
#pragma parameter rb "Red-Blue Tint" 0.0 -1.0 1.0 0.005
#pragma parameter gr "Green-Red Tint" 0.0 -1.0 1.0 0.005
#pragma parameter gb "Green-Blue Tint" 0.0 -1.0 1.0 0.005
#pragma parameter br "Blue-Red Tint" 0.0 -1.0 1.0 0.005
#pragma parameter bg "Blue-Green Tint" 0.0 -1.0 1.0 0.005
#pragma parameter g_csize "Corner size" 0.0 0.0 0.07 0.01
#pragma parameter g_bsize "Border smoothness" 600.0 100.0 600.0 25.0
#pragma parameter LUT_Size1 "LUT Size 1" 16.0 8.0 64.0 16.0
#pragma parameter LUT1_toggle "LUT 1 Toggle" 0.0 0.0 1.0 1.0
#pragma parameter LUT_Size2 "LUT Size 2" 64.0 0.0 64.0 16.0
#pragma parameter LUT2_toggle "LUT 2 Toggle" 0.0 0.0 1.0 1.0

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
    vec4 SourceSize;
    vec4 OriginalSize;
    vec4 OutputSize;
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
// PAL: D65  NTSC-U: D65  NTSC-J: D93  NTSC-FCC: C
// PAL: 6504 NTSC-U: 6504 NTSC-J: 9305 NTSC-FCC: 6774

vec3 wp_adjust(vec3 color){

    float temp = params.wp_temperature / 100.;
    float k = params.wp_temperature / 10000.;
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
    0.4124564, 0.3575761, 0.1804375,
    0.2126729, 0.7151522, 0.0721750,
    0.0193339, 0.1191920, 0.9503041);
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
    3.2404542, -1.5371385, -0.4985314,
   -0.9692660,  1.8760108,  0.0415560,
    0.0556434, -0.2040259,  1.0572252);
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


const mat3 C_D65_Brad = 
mat3(
 0.9904476, -0.0071683, -0.0116156,
-0.0123712,  1.0155950, -0.0029282,
-0.0035635,  0.0067697,  0.9181569);

const mat3 D65_D93_Brad = 
mat3(
 0.9515, -0.0030, -0.0528,
-0.0085,  0.9983, -0.0155,
-0.0087,  0.0162,  1.0899);

const mat3 D93_D65_Brad = 
mat3(
 1.0515,  0.0023, 0.0510,
 0.0091,  1.0015, 0.0147,
 0.0083, -0.0149, 0.9177);

// This is from the PDF
const mat3 P22_Identity = 
mat3(
 0.640, 0.352, 0.008,
 0.282, 0.620, 0.098,
 0.146, 0.061, 0.793);

// Illuminant C
const mat3 NTSC_FCC_Identity = 
mat3(
 0.670, 0.330, 0.000,
 0.210, 0.710, 0.080,
 0.140, 0.080, 0.780);

const mat3 SMPTE_Identity = 
mat3(
 0.630, 0.340, 0.030,
 0.310, 0.595, 0.095,
 0.155, 0.070, 0.775);

// from Japanese PDF
const mat3 NTSC_J_Identity = 
mat3(
 0.618, 0.350, 0.032,
 0.280, 0.605, 0.115,
 0.152, 0.063, 0.785);

const mat3 EBU_Identity = 
mat3(
 0.640, 0.330, 0.030,
 0.290, 0.600, 0.110,
 0.150, 0.060, 0.790);

const mat3 Sony20_20_Identity = 
mat3(
 0.625, 0.340, 0.035,
 0.280, 0.595, 0.135,
 0.155, 0.070, 0.775);

const mat3 Hitachi_Identity = 
mat3(
 0.595, 0.354, 0.051,
 0.308, 0.585, 0.117,
 0.160, 0.084, 0.766);

const mat3 Barco_Identity = 
mat3(
 0.618, 0.350, 0.032,
 0.280, 0.605, 0.115,
 0.152, 0.063, 0.785);

const mat3 Tektronics_Identity = 
mat3(
 0.610, 0.340, 0.050,
 0.280, 0.590, 0.130,
 0.152, 0.063, 0.785);


void main()
{

//  Analogue color knobs
    vec3 source = texture(Source, vTexCoord.xy).rgb;
    vec3 col = (params.g_crtgamut == 5.0) ? RGB_YUV(source) : (params.g_crtgamut == 2.0) || (params.g_crtgamut == 3.0) ? PCtoTV(RGB_YIQ(source)) : RGB_YIQ(source);

//    float hue_radians = params.hue_degrees * (3.14159 / 180.0);
//    float hue = atan(col.z, col.y) + hue_radians;
//    float chroma = sqrt(col.z * col.z + col.y * col.y);
//    col = vec3(col.x, chroma * cos(hue), chroma * sin(hue));

    col.y = mod((col.y + 1.0) + params.I_SHIFT, 2.0) - 1.0;
    col.z = mod((col.z + 1.0) + params.Q_SHIFT, 2.0) - 1.0;

    col.z *= params.Q_MUL;
    col.y *= params.I_MUL;

    col = (params.g_crtgamut == 5.0) ? clamp(col.xyz,vec3(0.0627,0.0627-0.5,0.0627-0.5),vec3(0.92157,0.94118-0.5,0.94118-0.5)) : clamp(col.xyz,vec3(0.0627,-0.5957,-0.5226),vec3(0.92157,0.5957,0.5226));
    col = (params.g_crtgamut == 0.0) ? source : (params.g_crtgamut == 5.0) ? YUV_RGB(col) : (params.g_crtgamut == 2.0) || (params.g_crtgamut == 3.0) ? YIQ_RGB(TVtoPC(col)) : YIQ_RGB(col);

//  Pure power was crushing blacks (eg. DKC2). You can mimic pow(c, 2.40) by raising the g_gamma_in value to 2.55
    vec3 imgColor = (params.g_gamma_type == 2.0) ? moncurve_f_f3(col, params.g_gamma_in - 0.18, 0.1115) : (params.g_gamma_type == 1.0) ? moncurve_f_f3(col, params.g_gamma_in, 0.055) : pow(col, vec3(params.g_gamma_in));


//  Look LUT
    float red = (imgColor.r * (params.LUT_Size1 - 1.0) + 0.4999) / (params.LUT_Size1 * params.LUT_Size1);
    float green = (imgColor.g * (params.LUT_Size1 - 1.0) + 0.4999) / params.LUT_Size1;
    float blue1 = (floor(imgColor.b * (params.LUT_Size1 - 1.0)) / params.LUT_Size1) + red;
    float blue2 = (ceil(imgColor.b * (params.LUT_Size1 - 1.0)) / params.LUT_Size1) + red;
    float mixer = clamp(max((imgColor.b - blue1) / (blue2 - blue1), 0.0), 0.0, 32.0);
    vec3 color1 = texture(SamplerLUT1, vec2(blue1, green)).rgb;
    vec3 color2 = texture(SamplerLUT1, vec2(blue2, green)).rgb;
    vec3 vcolor = (params.LUT1_toggle == 0.0) ? imgColor : mixfix(color1, color2, mixer);


//  Saturation agnostic sigmoidal contrast
    vec3 Yxy = XYZtoYxy(sRGB_to_XYZ(vcolor));
    float toGamma = clamp(moncurve_r(Yxy.r, 2.40, 0.055), 0.0, 1.0);
    toGamma = (Yxy.r > 0.5) ? contrast_sigmoid_inv(toGamma, 2.3, 0.5) : toGamma;
    float sigmoid = (params.g_cntrst > 0.0) ? contrast_sigmoid(toGamma, params.g_cntrst, params.g_mid) : contrast_sigmoid_inv(toGamma, params.g_cntrst, params.g_mid);
    vec3 contrast = vec3(moncurve_f(sigmoid, 2.40, 0.055), Yxy.g, Yxy.b);
    vec3 XYZsrgb = clamp(XYZ_to_sRGB(YxytoXYZ(contrast)), 0.0, 1.0);
    contrast = (params.g_cntrst == 0.0) ? vcolor : XYZsrgb;


//  Vignetting & Black Level
    vec2 vpos = vTexCoord*(global.OriginalSize.xy/global.SourceSize.xy);

    vpos *= 1.0 - vpos.xy;
    float vig = vpos.x * vpos.y * params.g_vstr;
    vig = min(pow(vig, params.g_vpower), 1.0);
    contrast *= (params.g_vignette == 1.0) ? vig : 1.0;

    contrast += (params.g_lift / 20.0) * (1.0 - contrast);


//  RGB related transforms
    vec4 screen = vec4(max(contrast, 0.0), 1.0);
    float sat = params.g_sat + 1.0;

                   //  r               g           b  alpha ; alpha does nothing for our purposes
    mat4 color = mat4(params.wlr, params.rg,  params.rb,   0.0,  //red tint
                      params.gr,  params.wlg, params.gb,   0.0,  //green tint
                      params.br,  params.bg,  params.wlb,  0.0,  //blue tint
                      0.0, 0.0, 0.0, 0.0);  //black tint

    mat4 adjust = mat4((1.0 - sat) * 0.2126 + sat, (1.0 - sat) * 0.2126, (1.0 - sat) * 0.2126, 1.0,
                       (1.0 - sat) * 0.7152, (1.0 - sat) * 0.7152 + sat, (1.0 - sat) * 0.7152, 1.0,
                       (1.0 - sat) * 0.0722, (1.0 - sat) * 0.0722, (1.0 - sat) * 0.0722 + sat, 1.0,
                        0.0, 0.0, 0.0, 1.0);

    screen = clamp(rolled_gain_v4(screen, params.g_lum * 2.0), 0.0, 1.0);
    screen = color * screen;
    float sat_msk = (params.g_vibr > 0.0) ? clamp(1.0 - (SatMask(screen.r, screen.g, screen.b) * params.g_vibr), 0.0, 1.0) : clamp(1.0 - abs(SatMask(screen.r, screen.g, screen.b) - 1.0) * abs(params.g_vibr), 0.0, 1.0);
    screen = mixfix_v4(screen, adjust * screen, sat_msk);


//  CRT Phosphor gamut
    mat3 m_in = Identity;

    if (params.g_crtgamut == 1.0) { m_in = P22_Identity;                } else
    if (params.g_crtgamut == 2.0) { m_in = NTSC_FCC_Identity;           } else
    if (params.g_crtgamut == 3.0) { m_in = SMPTE_Identity;              } else
    if (params.g_crtgamut == 4.0) { m_in = NTSC_J_Identity;             } else
    if (params.g_crtgamut == 5.0) { m_in = EBU_Identity;                } else
    if (params.g_crtgamut == 6.0) { m_in = Sony20_20_Identity;          } else
    if (params.g_crtgamut == 7.0) { m_in = Hitachi_Identity;            } else
    if (params.g_crtgamut == 8.0) { m_in = Barco_Identity;              } else
    if (params.g_crtgamut == 9.0) { m_in = Tektronics_Identity;         }

    vec3 gamut = (params.g_crtgamut == 0.0) ? sRGB_to_XYZ(screen.rgb)                   : \
                 (params.g_crtgamut == 2.0) ? sRGB_to_XYZ(screen.rgb*C_D65_Brad)*m_in   : \
                 (params.g_crtgamut == 4.0) ? sRGB_to_XYZ(screen.rgb*D93_D65_Brad)*m_in : \
                                              sRGB_to_XYZ(screen.rgb)*m_in;

//  Color Temperature
    vec3 adjusted = wp_adjust(XYZ_to_sRGB(gamut));
    vec3 base_luma = XYZtoYxy(gamut);
    vec3 adjusted_luma = XYZtoYxy(sRGB_to_XYZ(adjusted));
    adjusted = adjusted_luma + (vec3(base_luma.r, 0.0, 0.0) - vec3(adjusted_luma.r, 0.0, 0.0));
    adjusted = clamp(XYZ_to_sRGB(YxytoXYZ(adjusted)), 0.0, 1.0);


//  Technical LUT
    float red_2 = (adjusted.r * (params.LUT_Size2 - 1.0) + 0.4999) / (params.LUT_Size2 * params.LUT_Size2);
    float green_2 = (adjusted.g * (params.LUT_Size2 - 1.0) + 0.4999) / params.LUT_Size2;
    float blue1_2 = (floor(adjusted.b * (params.LUT_Size2 - 1.0)) / params.LUT_Size2) + red_2;
    float blue2_2 = (ceil(adjusted.b * (params.LUT_Size2 - 1.0)) / params.LUT_Size2) + red_2;
    float mixer_2 = clamp(max((adjusted.b - blue1_2) / (blue2_2 - blue1_2), 0.0), 0.0, 32.0);
    vec3 color1_2 = texture(SamplerLUT2, vec2(blue1_2, green_2)).rgb;
    vec3 color2_2 = texture(SamplerLUT2, vec2(blue2_2, green_2)).rgb;
    vec3 LUT2_output = mixfix(color1_2, color2_2, mixer_2);

    LUT2_output = (params.LUT2_toggle == 0.0) ? adjusted : LUT2_output;
    LUT2_output = moncurve_r_f3(LUT2_output, 2.20 + 0.20, 0.055);

    vpos *= (global.SourceSize.xy/global.OriginalSize.xy);
    FragColor = vec4(LUT2_output*corner(vpos), 1.0);
}