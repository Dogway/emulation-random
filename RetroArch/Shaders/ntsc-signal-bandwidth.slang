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
// Y:4.2   I: 0.60   Q: 0.60 (1993-2020) (for FCC NTSC Broadcast analogue standard) (band limited)
// Y:2.0   I: 0.30   Q: 0.30 (1993-2020) (for FCC NTSC VHS analogue standard) (band limited)

// Suggestions (NTSC):
// Y:4.20   I: 1.30   Q: 0.40 (1953-1993) (for FCC NTSC analogue standard -old-)
// Y:4.20   I: 1.50   Q: 0.50 (1953-1993) (for FCC NTSC analogue standard -old-)
// Y:4.20   U: 1.30   V: 1.30 (1998-2020) (for FCC NTSC digital standard 4:1:1) (chroma band limited)
// Y:4.20   U: 1.79   V: 1.79 (1998-2020) (for FCC NTSC S-Video & digital -new- 4:2:2) (max subcarrier width)

// Suggestions (PAL):
// PAL should be a little bit more desaturated than NTSC
// PAL chroma is also band limited -in analogue- to 1.30Mhz despite using a wider subcarrier than NTSC (4.4336)
// Y:5.5   U: 1.30   V: 1.30  PAL-A (for EBU 601 analogue standard -old-) (System I: UK, Italy, Australia)
// Y:5.0   U: 1.30   V: 1.30  PAL-B (for EBU 601 analogue standard -old-) (chroma band limited)
// Y:5.5   U: 1.80   V: 1.80  PAL-A (for EBU 601 digital standard 4:2:2)  (chroma band limited)
// Y:5.0   U: 1.80   V: 1.80  PAL-B (for EBU 601 digital standard 4:2:2)  (chroma band limited)
// Y:5.5   U: 2.217  V: 2.217 PAL-A (for EBU 601 digital standard 4:2:2) (max subcarrier width)


#pragma parameter SPLIT "Split" 0.0 -1.0 1.0 0.1
#pragma parameter S_PRESET "0:CUS|1:PALA|2:PALB|3:NTSC|4:NTSC411|5:NTSC422" 0.0 0.0 5.0 1.0
#pragma parameter PAL "0:NTSC 1:PAL" 0.0 0.0 1.0 1.0
#pragma parameter CH_SPC "YIQ/YUV" 0.0 0.0 1.0 1.0
#pragma parameter Y_RES "Y Mhz" 4.2 2.5 6.0 0.01
#pragma parameter I_RES "I/U Mhz" 1.3 0.4 4.0 0.05
#pragma parameter Q_RES "Q/V Mhz" 0.4 0.4 4.0 0.05
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

vec4 RGB_YIQ(vec4 col)
{
    mat3 conv_mat = mat3(
    0.299996928307425,  0.590001575542717,  0.110001496149858,
    0.599002392519453, -0.277301256521204, -0.321701135998249,
    0.213001700342824, -0.52510120528935,  0.312099504946526);

    col.rgb *= conv_mat;

    return col;
}

vec4 YIQ_RGB(vec4 col)
{
    mat3 conv_mat = mat3(
    1.0,  0.946882217090069,  0.623556581986143,
    1.0, -0.274787646298978, -0.635691079187380,
    1.0, -1.108545034642030,  1.709006928406470);

    col.rgb *= conv_mat;

    return col;
}

vec4 RGBtoYUV(vec4 RGB)
 {
     mat3 conv_mat = mat3(
     0.299,    0.587,   0.114,
    -0.14713,-0.28886,  0.436,
     0.615, -0.514991, -0.10001);
 
    RGB.rgb *= conv_mat;
    return RGB;
 }

vec4 YUVtoRGB(vec4 YUV)
 {
     mat3 conv_mat = mat3(
     1.000, 0.000,   1.13983,
     1.000,-0.39465,-0.58060,
     1.000, 2.03211, 0.00000);
 
    YUV.rgb *= conv_mat;
    return YUV;
  }


// to Studio Swing (in YIQ space) (for footroom and headroom)
vec4 PCtoTV(vec4 col)
{
   col *= 255;
   col.x = ((col.x * 219) / 255) + 16;
   col.y = (((col.y - 128) * 224) / 255) + 112;
   col.z = (((col.z - 128) * 224) / 255) + 112;
   return vec4(col.xyz, 1.0) / 255;
}


// to Full Swing (in YIQ space)
vec4 TVtoPC(vec4 col)
{
   col *= 255;
   float colx = ((col.x - 16) / 219) * 255;
   float coly = (((col.y - 112) / 224) * 255) + 128;
   float colz = (((col.z - 112) / 224) * 255) + 128;
   return vec4(colx,coly,colz, 1.0) / 255;
}


void main()
{
    #define ms *pow(10.0, -9.0)
    #define MHz *pow(10.0, 9.0);

    float max_col_res_I = 0.0;
    float max_col_res_Q = 0.0;
    float max_lum_res = 0.0;

    //  88 Mhz is VHF FM modulation (NTSC-M and PAL-AB. NTSC-J uses 90 Mhz)
    //  Luma signal runs over 4.2Mhz (5.0 PAL), whereas Chroma does on 3.5795 (4.4336 PAL)
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
        max_col_res_I = (1.30 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_col_res_Q = (0.40 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_lum_res = 52.6 ms * 369.6/88.0 MHz;
    }
    if (params.S_PRESET == 4.0)
    {
        max_col_res_I = (1.30 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_col_res_Q = (1.30 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_lum_res = 52.6 ms * 369.6/88.0 MHz;
    }
    if (params.S_PRESET == 5.0)
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

        if ((params.S_PRESET == 0.0) || (params.S_PRESET == 3.0) || (params.CH_SPC == 0.0))
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
            col += RGBtoYUV(texture(Source, vTexCoord));

            for(int i = 1; i < viewport_col_resy; i++)
            {
                col.y += RGBtoYUV(texture(Source, vTexCoord - vec2((i - viewport_col_resy/2) * params.OutputSize.z, 0.0))).y;
            }
            for(int i = 1; i < viewport_col_resz; i++)
            {
                col.z += RGBtoYUV(texture(Source, vTexCoord - vec2((i - viewport_col_resz/2) * params.OutputSize.z, 0.0))).z;
            }
            for(int i = 1; i < viewport_lum_res; i++)
            {
                col.x += RGBtoYUV(texture(Source, vTexCoord - vec2((i - viewport_col_resy/2) * params.OutputSize.z, 0.0))).x;
            }
        }


        col.y /= viewport_col_resy;
        col.z /= viewport_col_resz;
        col.x /= viewport_lum_res;
        col = PCtoTV(col);


        col.y = mod((col.y + 1.0) + params.I_SHIFT, 2.0) - 1.0;
//      col.y = 0.9 * col.y + 0.1 * col.y * col.x;
//
        col.z = mod((col.z + 1.0) + params.Q_SHIFT, 2.0) - 1.0;
//      col.z = 0.4 * col.z + 0.6 * col.z * col.x;
//      col.x += 0.5*col.y;

        col.z *= params.Q_MUL;
        col.y *= params.I_MUL;
        col.x *= params.Y_MUL;

        if ((params.S_PRESET == 0.0) || (params.S_PRESET == 3.0) || (params.CH_SPC == 0.0))
        {
            col = clamp(col,vec4(0.0627,-0.5957,-0.5226,0.0),vec4(0.92157,0.5957,0.5226,1.0));
            col = YIQ_RGB(TVtoPC(col));
        }
        else
        {
            col = clamp(col,vec4(0.0627,0.0627-0.5,0.0627-0.5,0.0),vec4(0.92157,0.94118-0.5,0.94118-0.5,1.0));
            col = YUVtoRGB(TVtoPC(col));
        }

        FragColor = clamp(col,0.0,1.0);

    }
}