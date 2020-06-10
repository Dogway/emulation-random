#version 450

layout(push_constant) uniform Push
{
    vec4 SourceSize;
    vec4 OriginalSize;
    vec4 OutputSize;
    uint FrameCount;
    float SPLIT;
    float S_PRESET;
    float PAL;
    float CH_SPC;
    float Y_RES;
    float I_RES;
    float Q_RES;
    float I_SHIFT;
    float Q_SHIFT;
    float Y_MUL;
    float I_MUL;
    float Q_MUL;
} params;

// mod of Doriphor ntsc shader
// https://forums.libretro.com/t/please-show-off-what-crt-shaders-can-do/19193/1482

// Other NTSC
// Y:2.0   I: 0.30   Q: 0.30 (1993-2020) (for FCC NTSC VHS analogue standard) (band limited)
// Y:4.2   I: 0.60   Q: 0.60 (1993-2020) (for FCC NTSC Broadcast analogue standard) (band limited)

// Suggestions (NTSC):
// Y:4.20   I: 1.30   Q: 0.40 (1953-1993) (for FCC NTSC analogue standard -old-)
// Y:4.20   I: 1.50   Q: 0.50 (1953-1993) (for FCC NTSC analogue standard -old-)
// Y:4.20   U: 1.30   V: 1.30 (1998-2020) (for FCC NTSC digital standard 4:1:1) (chroma band limited)
// Y:4.20   U: 1.79   V: 1.79 (1998-2020) (for FCC NTSC S-Video & digital -new- 4:2:2) (max subcarrier width)

// Suggestions (NTSC-J):
// Y:4.20   I: 1.30   Q: 0.40  (for NTSC-J analogue standard -old-)
// Y:4.20   I: 1.30   Q: 1.30  (for NTSC-J digital standard 4:1:1) (chroma band limited)
// Y:4.20   I: 1.79   Q: 1.79  (for NTSC-J S-Video & digital -new- 4:2:2) (max subcarrier width)

// Suggestions (PAL):
// PAL should be a little bit more desaturated than NTSC
// PAL chroma is also band limited -in analogue- to 1.30Mhz despite using a wider subcarrier than NTSC (4.4336)
// Y:5.0   U: 0.60   V: 0.60  PAL-B (for EBU 601 VHS analogue standard) (band limited)
// Y:5.5   U: 1.30   V: 1.30  PAL-A (for EBU 601 analogue standard -old-) (System I: UK, Italy, Australia)
// Y:5.0   U: 1.30   V: 1.30  PAL-B (for EBU 601 analogue standard -old-) (chroma band limited)
// Y:5.5   U: 1.80   V: 1.80  PAL-A (for EBU 601 digital standard 4:2:2)  (chroma band limited)
// Y:5.0   U: 1.80   V: 1.80  PAL-B (for EBU 601 digital standard 4:2:2)  (chroma band limited)
// Y:5.5   U: 2.217  V: 2.217 PAL-A (for EBU 601 digital standard 4:2:2) (max subcarrier width)


#pragma parameter SPLIT "Split" 0.0 -1.0 1.0 0.1
#pragma parameter S_PRESET "1:PALA|2:PALB|3:NTSC|4:NTSCJ|5:NTSC411|6:NTSC422" 0.0 0.0 6.0 1.0
#pragma parameter PAL "0:NTSC 1:PAL" 0.0 0.0 1.0 1.0
#pragma parameter CH_SPC "YIQ/YUV" 0.0 0.0 1.0 1.0
#pragma parameter Y_RES "Y Mhz" 4.2 2.5 6.0 0.01
#pragma parameter I_RES "I/U Mhz" 1.5 0.4 4.0 0.05
#pragma parameter Q_RES "Q/V Mhz" 0.5 0.4 4.0 0.05
#pragma parameter I_SHIFT "I/U Shift" 0.0 -1.0 1.0 0.02
#pragma parameter Q_SHIFT "Q/V Shift" 0.0 -1.0 1.0 0.02
#pragma parameter Y_MUL "Y Multiplier" 1.0 0.0 2.0 0.1
#pragma parameter I_MUL "I/U Multiplier" 1.0 0.0 2.0 0.1
#pragma parameter Q_MUL "Q/V Multiplier" 1.0 0.0 2.0 0.1

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
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


//--------------------- SMPTE RP 145 (C), 170M (1987) ------------------


vec4 RGB_YIQ(vec4 col)
 {
    const mat3 conv_mat = mat3(
    0.2990,  0.5870,  0.1140,
    0.5959, -0.2746, -0.3213,
    0.2115, -0.5227,  0.3112);

    return vec4(col.rgb * conv_mat,1.0);
 }

vec4 YIQ_RGB(vec4 col)
 {
    const mat3 conv_mat = mat3(
    1.0000000,  0.956,  0.619,
    1.0000000, -0.272, -0.647,
    1.0000000, -1.106,  1.703);

    return vec4(col.rgb * conv_mat,1.0);
 }


//----------------------- ITU-R BT.470/601 (B/G) -----------------------


vec4 r601_YUV(vec4 RGB)
 {
    const mat3 conv_mat = mat3(
    0.299000,  0.587000,  0.114000,
   -0.147407, -0.289391,  0.436798,
    0.614777, -0.514799, -0.099978);

    return vec4(RGB.rgb * conv_mat,1.0);
 }

vec4 YUV_r601(vec4 RGB)
 {
    const mat3 conv_mat = mat3(
    1.0000000,  0.00000000000000000,  1.14025080204010000,
    1.0000000, -0.39393067359924316, -0.58080917596817020,
    1.0000000,  2.02839756011962900, -0.00000029356581166);

    return vec4(RGB.rgb * conv_mat,1.0);
 }


//---------------------- Range Expansion/Compression -------------------


//  to Studio Swing/Broadcast Safe/SMPTE legal
vec4 PCtoTV(vec4 col, float luma_swing, float Umax, float Vmax, float max_swing, bool rgb_in)
{
   col *= 255.;
   Umax = (max_swing == 1.0) ? Umax * 224. : Umax * 239.;
   Vmax = (max_swing == 1.0) ? Vmax * 224. : Vmax * 239.;

   col.x = (luma_swing == 1.0) ? ((col.x * 219.) / 255.) + 16. : col.x;
   col.y = (rgb_in == true) ? ((col.y * 219.) / 255.) + 16. : (((col.y - 128.) * (Umax * 2.)) / 255.) + Umax;
   col.z = (rgb_in == true) ? ((col.z * 219.) / 255.) + 16. : (((col.z - 128.) * (Vmax * 2.)) / 255.) + Vmax;
   return vec4(col.xyz / 255.,1.0);
}


//  to Full Swing
vec4 TVtoPC(vec4 col, float luma_swing, float Umax, float Vmax, float max_swing, bool rgb_in)
{
   col *= 255.;
   Umax = (max_swing == 1.0) ? Umax * 224. : Umax * 239.;
   Vmax = (max_swing == 1.0) ? Vmax * 224. : Vmax * 239.;

   float colx = (luma_swing == 1.0) ? ((col.x - 16.) / 219.) * 255. : col.x;
   float coly = (rgb_in == true) ? ((col.y - 16.) / 219.) * 255. : (((col.y - Umax) / (Umax * 2.)) * 255.) + 128.;
   float colz = (rgb_in == true) ? ((col.z - 16.) / 219.) * 255. : (((col.z - Vmax) / (Vmax * 2.)) * 255.) + 128.;
   return vec4(colx,coly,colz,1.0) / 255.;
}




//*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/



void main()
{
    #define ms *pow(10.0, -9.0)
    #define MHz *pow(10.0, 9.0);

    float max_col_res_I = 0.0;
    float max_col_res_Q = 0.0;
    float max_lum_res = 0.0;

    //  88 Mhz is VHF FM modulation (NTSC-M and PAL-AB. NTSC-J uses 90 Mhz)
    //  Luma signal runs over 4.2Mhz (5.0 PAL), whereas Chroma does on 3.579545 (4.43361875 PAL)
    if (params.S_PRESET == 0.0)
    {
        float blank =   (params.PAL==1.0) ? 12.0                      : 10.9;
        float scan_ms = (params.PAL==1.0) ? 1000000.*(1./625.)*(1./25.)-blank : \
                                            1000000.*(1./525.)*(1./(30./1.001))-blank;
        float Ch_SubC = (params.PAL==1.0) ? 390.15845                 : 315.0;
        float Y_Carr =  (params.PAL==1.0) ? 440.0                     : 369.6;
        float Y_CUS =   (params.Y_RES != 4.2) ? params.Y_RES * 88.0   : Y_Carr;

        max_col_res_I = (params.I_RES / 2.0) * scan_ms ms * Ch_SubC/88.0 MHz;
        max_col_res_Q = (params.Q_RES / 2.0) * scan_ms ms * Ch_SubC/88.0 MHz;
        max_lum_res = scan_ms ms * Y_CUS/88.0 MHz;
    }
    if (params.S_PRESET == 1.0)
    {
        max_col_res_I = (1.30 / 2.0) * 52.0 ms * 390.15845/88.0 MHz;
        max_col_res_Q = (1.30 / 2.0) * 52.0 ms * 390.15845/88.0 MHz;
        max_lum_res = 52.0 ms * 484.0/88.0 MHz;
    }
    if (params.S_PRESET == 2.0)
    {
        max_col_res_I = (1.30 / 2.0) * 52.0 ms * 390.15845/88.0 MHz;
        max_col_res_Q = (1.30 / 2.0) * 52.0 ms * 390.15845/88.0 MHz;
        max_lum_res = 52.0 ms * 440.0/88.0 MHz;
    }
    if (params.S_PRESET == 3.0)
    {
        max_col_res_I = (1.50 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_col_res_Q = (0.50 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_lum_res = 52.6 ms * 369.6/88.0 MHz;
    }
    if (params.S_PRESET == 4.0)
    {
        max_col_res_I = (1.50 / 2.0) * 52.6 ms * 315.0/90.0 MHz;
        max_col_res_Q = (0.50 / 2.0) * 52.6 ms * 315.0/90.0 MHz;
        max_lum_res = 52.6 ms * 369.6/90.0 MHz;
    }
    if (params.S_PRESET == 5.0)
    {
        max_col_res_I = (1.30 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_col_res_Q = (1.30 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_lum_res = 52.6 ms * 369.6/88.0 MHz;
    }
    if (params.S_PRESET == 6.0)
    {
        max_col_res_I = (1.79 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_col_res_Q = (1.79 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_lum_res = 52.6 ms * 369.6/88.0 MHz;
    }

    const int viewport_col_resy = int(ceil((params.OutputSize.x / params.OriginalSize.x) * (params.OriginalSize.x / max_col_res_I)));
    const int viewport_col_resz = int(ceil((params.OutputSize.x / params.OriginalSize.x) * (params.OriginalSize.x / max_col_res_Q)));
    const int viewport_lum_res =  int(ceil((params.OutputSize.x / params.OriginalSize.x) * (params.OriginalSize.x / max_lum_res)));

    if(vTexCoord.x - params.SPLIT - 1.0 > 0.0 || vTexCoord.x - params.SPLIT < 0.0)
    {
        FragColor = vec4(texture(Source, vTexCoord).rgb, 1.0);
    }
    else
    {
        vec4 col = vec4(0.0, 0.0, 0.0, 1.0);
        float Region = (params.CH_SPC == 1.0) || (params.S_PRESET == 1.0) || (params.S_PRESET == 2.0) ? 1.0 : 0.0 ;

        if (Region == 0.0)
        {
            col += RGB_YIQ(texture(Source, vTexCoord));

            for(int i = 1; i < viewport_col_resy; i++)
            {
                col.y += RGB_YIQ(texture(Source, vTexCoord - vec2((i - viewport_col_resy/2) * params.OutputSize.z, 0.0))).y;
            }
            for(int i = 1; i < viewport_col_resz; i++)
            {
                col.z += RGB_YIQ(texture(Source, vTexCoord - vec2((i - viewport_col_resz/2) * params.OutputSize.z, 0.0))).z;
            }
            for(int i = 1; i < viewport_lum_res; i++)
            {
                col.x += RGB_YIQ(texture(Source, vTexCoord - vec2((i - viewport_col_resy/2) * params.OutputSize.z, 0.0))).x;
            }
        }
        else
        {
            col += r601_YUV(texture(Source, vTexCoord));

            for(int i = 1; i < viewport_col_resy; i++)
            {
                col.y += r601_YUV(texture(Source, vTexCoord - vec2((i - viewport_col_resy/2) * params.OutputSize.z, 0.0))).y;
            }
            for(int i = 1; i < viewport_col_resz; i++)
            {
                col.z += r601_YUV(texture(Source, vTexCoord - vec2((i - viewport_col_resz/2) * params.OutputSize.z, 0.0))).z;
            }
            for(int i = 1; i < viewport_lum_res; i++)
            {
                col.x += r601_YUV(texture(Source, vTexCoord - vec2((i - viewport_col_resy/2) * params.OutputSize.z, 0.0))).x;
            }
        }


        col.y /= viewport_col_resy;
        col.z /= viewport_col_resz;
        col.x /= viewport_lum_res;


// Clipping Logic / Gamut Limiting
        vec2 UVmax = (Region == 1.0) ? vec2(0.436798, 0.614777) : \
                                       vec2(0.5959,   0.5227)   ;

        col = vec4(clamp(col.xyz, vec3(0.0, -UVmax.x, -UVmax.y), vec3(1.0, UVmax.x, UVmax.y)),1.0);
        col = (Region == 1.0) ? col : PCtoTV(col, 1.0, UVmax.x, UVmax.y, 1.0, false);


// Analogue Color Controls
        col.y = mod((col.y + 1.0) + params.I_SHIFT, 2.0) - 1.0;
//      col.y = 0.9 * col.y + 0.1 * col.y * col.x;
//
        col.z = mod((col.z + 1.0) + params.Q_SHIFT, 2.0) - 1.0;
//      col.z = 0.4 * col.z + 0.6 * col.z * col.x;
//      col.x += 0.5*col.y;

        col.z *= params.Q_MUL;
        col.y *= params.I_MUL;
        col.x *= params.Y_MUL;

        col = (Region == 1.0) ? YUV_r601(col) : YIQ_RGB(TVtoPC(col, 1.0, UVmax.x, UVmax.y, 1.0, false));

        FragColor = clamp(col,0.0,1.0);

    }
}