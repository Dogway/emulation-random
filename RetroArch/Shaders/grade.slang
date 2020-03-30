#version 450

layout(push_constant) uniform Push
{
    float gamma_in;
    float gamma_type;
    float vignette;
    float str;
    float power;
    float LUT_Size1;
    float LUT1_toggle;
    float LUT_Size2;
    float LUT2_toggle;
    float temperature;
    float luma_preserve;
    float sat;
    float lum;
    float size;
    float cntrst;
    float mid;
    float black_level;
    float blr;
    float blg;
    float blb;
    float r;
    float g;
    float b;
    float rg;
    float rb;
    float gr;
    float gb;
    float br;
    float bg;
} params;

/*
   Grade
   > Ubershader grouping some color related monolithic shaders like color-mangler, vignette, lut,
   > white_point, and the addition of black level, sigmoidal contrast and proper gamma transforms.

   Author: hunterk, Guest, Dr. Venom, Dogway
   License: Public domain
*/

#pragma parameter gamma_in "CRT Gamma" 2.55 0.0 3.0 0.05
#pragma parameter gamma_type "CRT Gamma (POW = 0, sRGB = 1)" 1.0 0.0 1.0 1.0
#pragma parameter vignette "Vignette Toggle" 1.0 0.0 1.0 1.0
#pragma parameter str "Vig.Strength" 40.0 10.0 40.0 1.0
#pragma parameter power "Vig.Power" 0.20 0.0 0.5 0.01
#pragma parameter LUT_Size1 "LUT Size 1" 16.0 0.0 64.0 16.0
#pragma parameter LUT1_toggle "LUT 1 Toggle" 0.0 0.0 1.0 1.0
#pragma parameter LUT_Size2 "LUT Size 2" 64.0 0.0 64.0 16.0
#pragma parameter LUT2_toggle "LUT 2 Toggle" 0.0 0.0 1.0 1.0
#pragma parameter temperature "White Point" 9311.0 1031.0 12047.0 72.0
#pragma parameter luma_preserve "WP Preserve Luminance" 1.0 0.0 1.0 1.0
#pragma parameter sat "Saturation" 1.0 0.0 3.0 0.01
#pragma parameter lum "Brightness" 1.0 0.0 2.0 0.01
#pragma parameter cntrst "Contrast" 0.0 -1.0 1.0 0.05
#pragma parameter mid "Contrast Pivot" 0.5 0.0 1.0 0.01
#pragma parameter black_level "Black Level" 0.0 -0.5 0.5 0.01
#pragma parameter blr "Black-Red Tint" 0.0 0.0 1.0 0.005
#pragma parameter blg "Black-Green Tint" 0.0 0.0 1.0 0.005
#pragma parameter blb "Black-Blue Tint" 0.0 0.0 1.0 0.005
#pragma parameter r "White-Red Tint" 1.0 0.0 2.0 0.01
#pragma parameter g "White-Green Tint" 1.0 0.0 2.0 0.01
#pragma parameter b "White-Blue Tint" 1.0 0.0 2.0 0.01
#pragma parameter rg "Red-Green Tint" 0.0 -1.0 1.0 0.005
#pragma parameter rb "Red-Blue Tint" 0.0 -1.0 1.0 0.005
#pragma parameter gr "Green-Red Tint" 0.0 -1.0 1.0 0.005
#pragma parameter gb "Green-Blue Tint" 0.0 -1.0 1.0 0.005
#pragma parameter br "Blue-Red Tint" 0.0 -1.0 1.0 0.005
#pragma parameter bg "Blue-Green Tint" 0.0 -1.0 1.0 0.005

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
// From the first comment post (sRGB and linear light compensated)
//      http://www.zombieprototypes.com/?p=210#comment-4695029660
// Based on the Neil Bartlett's blog update
//      http://www.zombieprototypes.com/?p=210
// Inspired itself by Tanner Helland's work
//      http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/

vec3 wp_adjust(vec3 color){

    float temp = params.temperature / 100.;
    float k = params.temperature / 10000.;
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

    return color.rgb;
}


vec3 sRGB_to_linear(vec3 color, float gamma){

    color = clamp(color, 0.0, 1.0);
    color.r = (color.r <= 0.04045) ?
    color.r / 12.92 : pow((color.r + 0.055) / (1.055), gamma);
    color.g = (color.g <= 0.04045) ?
    color.g / 12.92 : pow((color.g + 0.055) / (1.055), gamma);
    color.b = (color.b <= 0.04045) ?
    color.b / 12.92 : pow((color.b + 0.055) / (1.055), gamma);

    return color.rgb;
}


//  Performs better in gamma encoded space
vec3 contrast_sigmoid(vec3 color, float cont, float pivot){

    cont = pow(cont + 1., 3.);

    float knee = 1. / (1. + exp(cont * pivot));
    float shldr = 1. / (1. + exp(cont * (pivot - 1.)));

    color.r = (1. / (1. + exp(cont * (pivot - color.r))) - knee) / (shldr - knee);
    color.g = (1. / (1. + exp(cont * (pivot - color.g))) - knee) / (shldr - knee);
    color.b = (1. / (1. + exp(cont * (pivot - color.b))) - knee) / (shldr - knee);

    return color.rgb;
}


//  Performs better in gamma encoded space
vec3 contrast_sigmoid_inv(vec3 color, float cont, float pivot){

    cont = pow(cont - 1., 3.);

    float knee = 1. / (1. + exp (cont * pivot));
    float shldr = 1. / (1. + exp (cont * (pivot - 1.)));

    color.r = pivot - log(1. / (color.r * (shldr - knee) + knee) - 1.) / cont;
    color.g = pivot - log(1. / (color.g * (shldr - knee) + knee) - 1.) / cont;
    color.b = pivot - log(1. / (color.b * (shldr - knee) + knee) - 1.) / cont;

    return color.rgb;
}



void main()
{

//  Pure power was crushing blacks (eg. DKC2). You can mimic pow(c, 2.4) by raising the gamma_in value to 2.55
    vec3 imgColor = texture(Source, vTexCoord.xy).rgb;
    imgColor = (params.gamma_type == 1.0) ? sRGB_to_linear(imgColor, params.gamma_in) : pow(imgColor, vec3(params.gamma_in - 0.15));


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
    vec3 toLinear = linear_to_sRGB(vec3(Yxy.r, 0.0, 0.0), 2.4);
    vec3 contrast = (params.cntrst > 0.0) ? contrast_sigmoid(toLinear, params.cntrst, params.mid) : contrast_sigmoid_inv(toLinear, params.cntrst, params.mid);
    contrast.rgb = vec3(sRGB_to_linear(contrast, 2.4).r, Yxy.g, Yxy.b);
    vec3 XYZsrgb = clamp(XYZ_to_sRGB(YxytoXYZ(contrast)), 0.0, 1.0);
    contrast = (params.cntrst == 0.0) ? vcolor : XYZsrgb;


//  Vignetting & Black Level
    vec2 vpos = vTexCoord*(global.OriginalSize.xy/global.SourceSize.xy);

    vpos *= 1.0 - vpos.yx;
    float vig = vpos.x*vpos.y * params.str;
    vig = min(pow(vig, params.power), 1.0);
    contrast *= (params.vignette == 1.0) ? vig : 1.0;

    contrast += (params.black_level / 20.0) * (1.0 - contrast);


//  RGB related transforms
    vec4 screen = vec4(max(contrast, 0.0), 1.0);

    mat4 color = mat4(params.r, params.rg,  params.rb,  0.0,
                     params.gr,  params.g,  params.gb,  0.0,
                     params.br, params.bg,   params.b,  0.0,
                    params.blr, params.blg, params.blb, 0.0);

    mat4 adjust = mat4((1.0 - params.sat) * 0.2126 + params.sat, (1.0 - params.sat) * 0.2126, (1.0 - params.sat) * 0.2126, 1.0,
                       (1.0 - params.sat) * 0.7152, (1.0 - params.sat) * 0.7152 + params.sat, (1.0 - params.sat) * 0.7152, 1.0,
                       (1.0 - params.sat) * 0.0722, (1.0 - params.sat) * 0.0722, (1.0 - params.sat) * 0.0722 + params.sat, 1.0,
                        0.0, 0.0, 0.0, 1.0);

    color *= adjust;
    screen = clamp(screen * ((params.lum - 1.0) * 2.0 + 1.0), 0.0, 1.0);
    screen = color * screen;


//  Color Temperature
    vec3 adjusted = wp_adjust(screen.rgb);
    vec3 base_luma = XYZtoYxy(sRGB_to_XYZ(screen.rgb));
    vec3 adjusted_luma = XYZtoYxy(sRGB_to_XYZ(adjusted));
    adjusted = (params.luma_preserve == 1.0) ? adjusted_luma + (vec3(base_luma.r, 0.0, 0.0) - vec3(adjusted_luma.r, 0.0, 0.0)) : adjusted_luma;
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

    FragColor = (params.LUT2_toggle == 0.0) ? vec4(linear_to_sRGB(adjusted, 2.4), 1.0) : vec4(linear_to_sRGB(LUT2_output, 2.4), 1.0);
} 