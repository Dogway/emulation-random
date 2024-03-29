// mod of Doriphor ntsc shader
// https://forums.libretro.com/t/please-show-off-what-crt-shaders-can-do/19193/1482

// Other NTSC
// Y:2.0    U: 0.30   V: 0.30 (1993-2020) (for     NTSC   VHS analogue standard) (band limited)
// Y:5.5    U: 0.30   V: 0.30 (1993-2020) (for     NTSC S-VHS or LD analogue standard) (chroma band limited)

// Suggestions (NTSC-U and NTSC-J):
// Y:4.20   I: 1.30   Q: 0.40 (1953-1979) (for FCC NTSC analogue standard -old-)
// Y:4.20   I: 1.50   Q: 0.50 (1953-1979) (for FCC NTSC analogue standard -old-)
// Y:4.20   U: 0.60   V: 0.60 (1979-2020) (for     NTSC Broadcast analogue standard) (band limited)
// Y:4.20   U: 1.30   V: 1.30 (1998-2020) (for     NTSC digital standard 4:1:1, DVDs) (chroma band limited)
// Y:4.20   U: 1.79   V: 1.79 (1998-2020) (for     NTSC S-Video & digital -new- 4:2:2) (max subcarrier width)

// Suggestions (PAL):
// PAL should be a little bit more desaturated than NTSC
// PAL chroma is also band limited -in analogue- to 1.30Mhz despite using a wider subcarrier than NTSC (4.4336)
// Y:5.0   U: 0.60   V: 0.60  PAL-B       (for     EBU 601 VHS analogue standard) (band limited)
// Y:5.5   U: 1.30   V: 1.30  PAL-A       (for     EBU 601 analogue standard -old-) (System I: UK, Italy, Australia)
// Y:5.0   U: 1.30   V: 1.30  PAL-B       (for     EBU 601 analogue standard -old-) (chroma band limited)
// Y:5.5   U: 1.80   V: 1.80  PAL-A       (for     EBU 601 digital standard 4:2:2)  (chroma band limited)
// Y:5.0   U: 1.80   V: 1.80  PAL-B       (for     EBU 601 digital standard 4:2:2)  (chroma band limited)
// Y:5.5   U: 2.217  V: 2.217 PAL-A       (for     EBU 601 digital standard 4:2:2) (max subcarrier width)


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
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float SPLIT;
uniform COMPAT_PRECISION float S_PRESET;
uniform COMPAT_PRECISION float PAL;
uniform COMPAT_PRECISION float CH_SPC;
uniform COMPAT_PRECISION float Y_RES;
uniform COMPAT_PRECISION float I_RES;
uniform COMPAT_PRECISION float Q_RES;
uniform COMPAT_PRECISION float I_SHIFT;
uniform COMPAT_PRECISION float Q_SHIFT;
uniform COMPAT_PRECISION float Y_MUL;
uniform COMPAT_PRECISION float I_MUL;
uniform COMPAT_PRECISION float Q_MUL;
#else
#define SPLIT 0.0
#define S_PRESET 0.0
#define PAL 0.0
#define CH_SPC 0.0
#define Y_RES 4.2
#define I_RES 1.3
#define Q_RES 0.4
#define I_SHIFT 0.0
#define Q_SHIFT 0.0
#define Y_MUL 1.0
#define I_MUL 1.0
#define Q_MUL 1.0
#endif

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
    if (S_PRESET == 0.0)
    {
        float blank =   (PAL==1.0)     ? 12.0                      : 10.9;
        float scan_ms = (PAL==1.0)     ? 1000000.*(1./625.)*(1./25.)-blank : \
                                         1000000.*(1./525.)*(1./(30./1.001))-blank;
        float Ch_SubC = (PAL==1.0)     ? 390.15845                 : 315.0;
        float Y_Carr =  (PAL==1.0)     ? 440.0                     : 369.6;
        float Y_CUS =   (Y_RES != 4.2) ? Y_RES * 88.0          : Y_Carr;

        max_col_res_I = (I_RES / 2.0) * scan_ms ms * Ch_SubC/88.0 MHz;
        max_col_res_Q = (Q_RES / 2.0) * scan_ms ms * Ch_SubC/88.0 MHz;
        max_lum_res = scan_ms ms * Y_CUS/88.0 MHz;
    }
    if (S_PRESET == 1.0)
    {
        max_col_res_I = (1.30 / 2.0) * 52.0 ms * 390.15845/88.0 MHz;
        max_col_res_Q = (1.30 / 2.0) * 52.0 ms * 390.15845/88.0 MHz;
        max_lum_res = 52.0 ms * 484.0/88.0 MHz;
    }
    if (S_PRESET == 2.0)
    {
        max_col_res_I = (1.30 / 2.0) * 52.0 ms * 390.15845/88.0 MHz;
        max_col_res_Q = (1.30 / 2.0) * 52.0 ms * 390.15845/88.0 MHz;
        max_lum_res = 52.0 ms * 440.0/88.0 MHz;
    }
    if (S_PRESET == 3.0)
    {
        max_col_res_I = (1.50 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_col_res_Q = (0.50 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_lum_res = 52.6 ms * 369.6/88.0 MHz;
    }
    if (S_PRESET == 4.0)
    {
        max_col_res_I = (1.50 / 2.0) * 52.6 ms * 315.0/90.0 MHz;
        max_col_res_Q = (0.50 / 2.0) * 52.6 ms * 315.0/90.0 MHz;
        max_lum_res = 52.6 ms * 369.6/90.0 MHz;
    }
    if (S_PRESET == 5.0)
    {
        max_col_res_I = (1.30 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_col_res_Q = (1.30 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_lum_res = 52.6 ms * 369.6/88.0 MHz;
    }
    if (S_PRESET == 6.0)
    {
        max_col_res_I = (1.79 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_col_res_Q = (1.79 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_lum_res = 52.6 ms * 369.6/88.0 MHz;
    }

    int viewport_col_resy = int(ceil((OutputSize.x / TextureSize.x) * (TextureSize.x / max_col_res_I)));
    int viewport_col_resz = int(ceil((OutputSize.x / TextureSize.x) * (TextureSize.x / max_col_res_Q)));
    int viewport_lum_res =  int(ceil((OutputSize.x / TextureSize.x) * (TextureSize.x / max_lum_res)));

    if(vTexCoord.x - SPLIT - 1.0 > 0.0 || vTexCoord.x - SPLIT < 0.0)
    {
        FragColor = vec4(COMPAT_TEXTURE(Source, vTexCoord).rgb, 1.0);
    }
    else
    {
        vec4 col = vec4(0.0, 0.0, 0.0, 1.0);
        float Region = (CH_SPC == 1.0) || (S_PRESET == 1.0) || (S_PRESET == 2.0) ? 1.0 : 0.0 ;

        if (Region == 0.0)
        {
            col += RGB_YIQ(COMPAT_TEXTURE(Source, vTexCoord));

            for(int i = 1; i < viewport_col_resy; i++)
            {
                col.y += RGB_YIQ(COMPAT_TEXTURE(Source, vTexCoord - vec2(float(i - viewport_col_resy/2) * OutSize.z, 0.0))).y;
            }
            for(int i = 1; i < viewport_col_resz; i++)
            {
                col.z += RGB_YIQ(COMPAT_TEXTURE(Source, vTexCoord - vec2(float(i - viewport_col_resz/2) * OutSize.z, 0.0))).z;
            }
            for(int i = 1; i < viewport_lum_res; i++)
            {
                col.x += RGB_YIQ(COMPAT_TEXTURE(Source, vTexCoord - vec2(float(i - viewport_col_resy/2) * OutSize.z, 0.0))).x;
            }
        }
        else
        {
            col += r601_YUV(COMPAT_TEXTURE(Source, vTexCoord));

            for(int i = 1; i < viewport_col_resy; i++)
            {
                col.y += r601_YUV(COMPAT_TEXTURE(Source, vTexCoord - vec2(float(i - viewport_col_resy/2) * OutSize.z, 0.0))).y;
            }
            for(int i = 1; i < viewport_col_resz; i++)
            {
                col.z += r601_YUV(COMPAT_TEXTURE(Source, vTexCoord - vec2(float(i - viewport_col_resz/2) * OutSize.z, 0.0))).z;
            }
            for(int i = 1; i < viewport_lum_res; i++)
            {
                col.x += r601_YUV(COMPAT_TEXTURE(Source, vTexCoord - vec2(float(i - viewport_col_resy/2) * OutSize.z, 0.0))).x;
            }
        }



        col.y /= float(viewport_col_resy);
        col.z /= float(viewport_col_resz);
        col.x /= float(viewport_lum_res);


// Clipping Logic / Gamut Limiting
        vec2 UVmax = (Region == 1.0) ? vec2(0.436798, 0.614777) : \
                                       vec2(0.5959,   0.5227)   ;

        col = vec4(clamp(col.xyz, vec3(0.0, -UVmax.x, -UVmax.y), vec3(1.0, UVmax.x, UVmax.y)),1.0);
        col = (Region == 1.0) ? col : PCtoTV(col, 1.0, UVmax.x, UVmax.y, 1.0, false);


// Analogue Color Controls
        col.y = mod((col.y + 1.0) + I_SHIFT, 2.0) - 1.0;
//      col.y = 0.9 * col.y + 0.1 * col.y * col.x;
//
        col.z = mod((col.z + 1.0) + Q_SHIFT, 2.0) - 1.0;
//      col.z = 0.4 * col.z + 0.6 * col.z * col.x;
//      col.x += 0.5*col.y;

        col.z *= Q_MUL;
        col.y *= I_MUL;
        col.x *= Y_MUL;

        col = (Region == 1.0) ? YUV_r601(col) : YIQ_RGB(TVtoPC(col, 1.0, UVmax.x, UVmax.y, 1.0, false));

        FragColor = clamp(col,0.0,1.0);

    }
}
#endif