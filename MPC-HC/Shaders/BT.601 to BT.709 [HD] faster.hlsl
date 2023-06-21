// $MinimumShaderProfile: ps_2_0
/*
 * 2023 Dogway (Jose Linares)
 *
 * Fix wrong matrix* encoding in HD sources (BT.601 [SD] in HD)
 *
 * * Beware only model conversion matrix coefficients, color space primaries are kept.
 *
 */


sampler s0 : register(s0);
float4 p0 :  register(c0);


static const float3x3 SDtoHD = {
     0.913687467575073200, -0.10504773259162903, 0.009684234857559204,
     0.078395307064056400,  1.17288231849670400, 0.032579779624938965,
     0.007915861904621124, -0.06783381849527359, 0.957735955715179400};


float4 main(float2 tex : TEXCOORD0) : COLOR
{
    float3 c0 = tex2D(s0, tex).rgb;
    return float4(mul(c0,SDtoHD),1);
}
