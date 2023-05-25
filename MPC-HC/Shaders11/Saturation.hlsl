// $MinimumShaderProfile: ps_4_0
/*
 * 2023 Dogway (Jose Linares)
 *
 * Simple saturation shader for Rec709 RGB
 *
 */


Texture2D tex : register(t0);
SamplerState samp : register(s0);


#define saturation (1.1)		 // Saturation multiplier to compensate for the Abney effect on low nits (48nits)


static float3x3 YUV = {
     0.212600, 0.715179, 0.072221,
    -0.114575,-0.385425, 0.500000,
     0.500000,-0.454140,-0.045861,
};

static float3x3 SRGB = {
     1.000000, 1.000000, 1.000000,
     0.000000,-0.187380, 1.855558,
     1.574800,-0.468138, 0.000000,
};


float4 main(float4 pos : SV_POSITION, float2 coord : TEXCOORD) : SV_Target
{
    float4 c0 = tex.Sample(samp, coord);
    float3x3 SYUV = {YUV[0],saturation*YUV[1],saturation*YUV[2]};
    float3 sat = mul(c0.rgb,mul(transpose(SYUV),SRGB));
    return float4(sat,1);
}
