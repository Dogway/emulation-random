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

vec4 RGB_YIQ(vec4 col)
{
    mat3 conv_mat = mat3(
    0.299996928307425,  0.590001575542717,  0.110001496149858,
    0.599002392519453, -0.277301256521204, -0.321701135998249,
    0.213001700342824, -0.52510120528935,  0.312099504946526);

    col.rgb *= conv_mat;

    return vec4(col, 1.0);
}

vec4 YIQ_RGB(vec4 col)
{
    mat3 conv_mat = mat3(
    1.0,  0.946882217090069,  0.623556581986143,
    1.0, -0.274787646298978, -0.635691079187380,
    1.0, -1.108545034642030,  1.709006928406470);

    col.rgb *= conv_mat;

    return vec4(col, 1.0);
}

vec4 RGBtoYUV(vec4 RGB)
 {
     mat3 conv_mat = mat3(
     0.299,    0.587,   0.114,
    -0.14713,-0.28886,  0.436,
     0.615, -0.514991, -0.10001);
 
    RGB.rgb *= conv_mat;
    return vec4(RGB, 1.0);
 }

vec4 YUVtoRGB(vec4 YUV)
 {
     mat3 conv_mat = mat3(
     1.000, 0.000,   1.13983,
     1.000,-0.39465,-0.58060,
     1.000, 2.03211, 0.00000);
 
    YUV.rgb *= conv_mat;
    return vec4(YUV, 1.0);
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
    if (S_PRESET == 0.0)
    {
        float blank =   (PAL==1.0)     ? 12.0                      : 10.9;
        float scan_ms = (PAL==1.0)     ? 1000000.*(1./625.)*(1./25.)-blank : \
                                         1000000.*(1./525.)*(1./30.)-blank;
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
        max_col_res_I = (1.30 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_col_res_Q = (0.40 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_lum_res = 52.6 ms * 369.6/88.0 MHz;
    }
    if (S_PRESET == 4.0)
    {
        max_col_res_I = (1.30 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_col_res_Q = (1.30 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_lum_res = 52.6 ms * 369.6/88.0 MHz;
    }
    if (S_PRESET == 5.0)
    {
        max_col_res_I = (1.79 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_col_res_Q = (1.79 / 2.0) * 52.6 ms * 315.0/88.0 MHz;
        max_lum_res = 52.6 ms * 369.6/88.0 MHz;
    }

    const int viewport_col_resy = int(ceil((OutputSize.x / TextureSize.x) * (TextureSize.x / max_col_res_I)));
    const int viewport_col_resz = int(ceil((OutputSize.x / TextureSize.x) * (TextureSize.x / max_col_res_Q)));
    const int viewport_lum_res =  int(ceil((OutputSize.x / TextureSize.x) * (TextureSize.x / max_lum_res)));

    if(vTexCoord.x - SPLIT - 1.0 > 0.0 || vTexCoord.x - SPLIT < 0.0)
    {
        FragColor = vec4(COMPAT_TEXTURE(Source, vTexCoord).rgb, 1.0);
    }
    else
    {
        vec4 col = vec4(0.0, 0.0, 0.0, 1.0);

        if ((S_PRESET == 0.0) || (S_PRESET == 3.0) || (CH_SPC == 0.0))
        {
            col += RGB_YIQ(COMPAT_TEXTURE(Source, vTexCoord));

            for(int i = 1; i < viewport_col_resy; i++)
            {
                col.y += RGB_YIQ(COMPAT_TEXTURE(Source, vTexCoord - vec2((i - viewport_col_resy/2) * OutputSize.z, 0.0))).y;
            }
            for(int i = 1; i < viewport_col_resz; i++)
            {
                col.z += RGB_YIQ(COMPAT_TEXTURE(Source, vTexCoord - vec2((i - viewport_col_resz/2) * OutputSize.z, 0.0))).z;
            }
            for(int i = 1; i < viewport_lum_res; i++)
            {
                col.x += RGB_YIQ(COMPAT_TEXTURE(Source, vTexCoord - vec2((i - viewport_col_resy/2) * OutputSize.z, 0.0))).x;
            }
        }
        else
        {
            col += RGBtoYUV(COMPAT_TEXTURE(Source, vTexCoord));

            for(int i = 1; i < viewport_col_resy; i++)
            {
                col.y += RGBtoYUV(COMPAT_TEXTURE(Source, vTexCoord - vec2((i - viewport_col_resy/2) * OutputSize.z, 0.0))).y;
            }
            for(int i = 1; i < viewport_col_resz; i++)
            {
                col.z += RGBtoYUV(COMPAT_TEXTURE(Source, vTexCoord - vec2((i - viewport_col_resz/2) * OutputSize.z, 0.0))).z;
            }
            for(int i = 1; i < viewport_lum_res; i++)
            {
                col.x += RGBtoYUV(COMPAT_TEXTURE(Source, vTexCoord - vec2((i - viewport_col_resy/2) * OutputSize.z, 0.0))).x;
            }
        }


        col.y /= viewport_col_resy;
        col.z /= viewport_col_resz;
        col.x /= viewport_lum_res;
        col = PCtoTV(col);


        col.y = mod((col.y + 1.0) + I_SHIFT, 2.0) - 1.0;
//      col.y = 0.9 * col.y + 0.1 * col.y * col.x;
//
        col.z = mod((col.z + 1.0) + Q_SHIFT, 2.0) - 1.0;
//      col.z = 0.4 * col.z + 0.6 * col.z * col.x;
//      col.x += 0.5*col.y;

        col.z *= Q_MUL;
        col.y *= I_MUL;
        col.x *= Y_MUL;

        if ((S_PRESET == 0.0) || (S_PRESET == 3.0) || (CH_SPC == 0.0))
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
#endif
