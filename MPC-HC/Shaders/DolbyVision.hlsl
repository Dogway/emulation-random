// $MinimumShaderProfile: ps_2_0
/*
 * 2023 Dogway (Jose Linares)
 *
 * DolbyVision IPTPQc2 model conversion to SDR Rec709 RGB over GPU (DirectX)
 * Still lacks MMR for DVp8 and polynomial reshaping for DVp5 which are...
 * ...scene-by-scene transfer characteristics driven by the RPU (metadata)
 * The RPU also allows for some grading trims which are not handled here either.
 *
 */


// Fail early with ps_2_0 and ps_2_b shader profiles
#ifdef MPC_HC_SHADER_PROFILE
#   if MPC_HC_SHADER_PROFILE < 2
#       error Usupported shader profile
#   endif
#endif


sampler s0 : register(s0);
float4 p0 :  register(c0);


#define EOTF (2.4)				 // Inverse EOTF power value matching display EOTF. Rec709_Dim: 2.4; Rec709_Dark: 2.45; Black-Box: 2.6
#define saturation (1.0)		 // Saturation multiplier. Increase to 1.05 to compensate for HDR to SDR desaturation, and/or LED saturation reduction under lower than reference white levels (ie. using 48nits instead of spec's 100nits for home consumer media) (see: https://www.lightillusion.com/advanced_operation.html#oled)
#define GC (1)					 // 0 or 1 gamut compression
#define scale (1.0)				 // 1 or 2 depending on source
#define Peak (11.2)				 // Peak White to tonemap for
#define Master (10000)			 // Mastering display nits

#define const_1 ( 16.0 / 255.0)
#define const_2 (255.0 / 219.0)

#define N1 ((2610./4096) * 0.25)
#define M1 ((2523./4096) * 128)
#define C1  (3424./4096)
#define C2 ((2413./4096) * 32)
#define C3 ((2392./4096) * 32)



float3 EOTF_PQ (float3 RGB) {

    float PL = Master/203.;

    // From BT.2124-0 Annex 2 Conversion 3
    float3 pw = pow(RGB, 1.0/M1);
    float3 pq = pow(max(0,pw - C1 ) / (C2-C3*pw), 1.0 / N1) * PL;
    return pq;
}


float3 EOTFi_PQ (float3 RGB) {

    float PL = 203./Master;

    // From BT.2124-0 Annex 2 Conversion 3
    float3 pw  = pow(RGB * PL, N1);
    float3 lin = pow((pw * C2 + C1) / (pw * C3 + 1), M1);
    return lin;
}



float3 TM_Hable (float3 RGB) {

//                                            F L A T               F I L M I C
// TONE:                    Default      Bright      Dark        Bright      Dark
// SHAPING:                 Default    T.Mansecal   Hejl match   MJP       T.Mansecal
    const float A = 0.150;  // 0.150,      0.220,      0.265,      0.340,      0.305))   # Shoulder Strength
    const float B = 0.500;  // 0.500,      0.300,      0.300,      0.250,      0.055))   # Linear Strength
    const float C = 0.100;  // 0.100,      0.100,      0.110,      0.100,      0.490))   # Linear Angle
    const float D = 0.200;  // 0.200,      0.200,      0.402,      0.140,      0.225))   # Toe Strength
    const float E = 0.020;  // 0.020,      0.010,      0.000,      0.020,      0.040))   # Toe Numerator
    const float F = 0.300;  // 0.300,      0.300,      0.220,      0.240,      0.220))   # Toe Denominator


    float CB      = C*B;
    float DE      = D*E;
    float DF      = D*F;
    float EF      = E/F;
    float Div     = (((Peak*(A*Peak+CB)+DE) / (Peak*(A*Peak+B)+DF)) - EF);
                 
    float3 RGB2   = RGB * 2;
    float3 RA     = F!=0.220 ?   RGB2 *  A : RGB * A;
    float3 TM     = F!=0.220 ? ((RGB2 * (RA + CB)+DE) / (RGB2 * (RA + B)+DF) - EF)/Div : \
                               ((RGB  * (RA + CB)+DE) / (RGB  * (RA + B)+DF) - EF)/Div ;
    return TM;
}


// RGB 'Desaturate' Gamut Compression (by Jed Smith: https://github.com/jedypod/gamut-compress)
float3 GamutCompression (float3 rgb) {

    // Amount of outer gamut to affect
    float3 th = 1.0-float3(0.114080,0.183988,0.108230)*(0.4*saturation+0.3);

    // Distance limit: How far beyond the gamut boundary to compress
    float3 dl = 1.0+float3(0.074934,0.518208,0.063424)*saturation;

    // Calculate scale so compression function passes through distance limit: (x=dl, y=1)
    float3 s = (1.0-th)/sqrt(max(1.001, dl)-1.0);

    // Achromatic axis
    float ac = max(rgb.x, max(rgb.y, rgb.z));

    // Inverse RGB Ratios: distance from achromatic axis
    float3 d = ac==0.0 ? 0.0 : (ac-rgb)/abs(ac);

    // Compressed distance. Parabolic compression function: https://www.desmos.com/calculator/nvhp63hmtj
    float  sf = s*s/4.0;
    float3 cd = d < th ? d : s*sqrt(d-th+sf)-s*sqrt(sf)+th;

    // Inverse RGB Ratios to RGB
    return ac-cd*abs(ac);
}



float4 main(float2 tex : TEXCOORD0) : COLOR
{
    // R'G'B' Full pixels
    float4 c0 = tex2D(s0, tex);

    const float3x3 YUV = {
            0.212600,-0.114575, 0.500000,
            0.715179,-0.385425,-0.454140,
            0.072221, 0.500000,-0.045861};

    // IPTPQc2 to LMS joint matrix

    float scl = scale*saturation;

    float3x3 LMS5 = {
            1.000000,     1.000000,     1.000000,
        scl*0.097600,scl*-0.113900,scl* 0.032600,
        scl*0.205200,scl* 0.133200,scl*-0.676900};

    float3 ictcp = mul(c0.rgb, mul(YUV,LMS5));

    // Joint matrix with 2% Crosstalk for Dolby Vision (IPTPQc2)
    const float3x3 XLMS = {
            5.801851749420166,-1.2182241678237915,  0.010416880249977112,
           -4.960931777954102, 2.4180879592895510, -0.226645365357399000,
            0.159257173538208,-0.19987814128398895, 1.215838909149170000};

    float3 rgbf = mul(EOTF_PQ(ictcp), XLMS);

    // RGB 'Desaturate' Gamut Compression
    float3 crgbf = GC==1 ? GamutCompression(rgbf) : rgbf;

    // Mask with "luma" (green channel)
    crgbf = lerp(rgbf, crgbf, pow(rgbf.g,1/EOTF));

    // Tonemappping
    rgbf = TM_Hable(crgbf);

    // Inverse EOTF
    return float4(pow(rgbf,1/EOTF), 1);
}
