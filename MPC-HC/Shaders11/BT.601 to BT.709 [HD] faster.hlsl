// $MinimumShaderProfile: ps_4_0
/*
 * 2023 Dogway (Jose Linares)
 *
 * Fix wrong matrix encoded pixels in HD sources (BT.601 [SD] pixels in BT.709 tagged HD video)
 *
 * Note 1: Beware only model conversion matrix coefficients, color space primaries are kept.
 *
 * Note 2: This fix is for actual wrong mastering (RGB to YCbCr) conversions, while the tagging
 *         is still specification correct for HD Video. Differs from MPC-HC bundled "BT.601 to BT.709 [HD].hlsl"
 *         in that it only tries to correct wrong metadata (HD Video tagged as BT.601 instead of BT.709)
 *         (https://forum.doom9.org/showpost.php?p=1988786)
 */


Texture2D tex : register(t0);
SamplerState samp : register(s0);


static const float3x3 SDtoHD = {
     0.913687467575073200, -0.10504773259162903, 0.009684234857559204,
     0.078395307064056400,  1.17288231849670400, 0.032579779624938965,
     0.007915861904621124, -0.06783381849527359, 0.957735955715179400};


float4 main(float4 pos : SV_POSITION, float2 coord : TEXCOORD) : SV_Target
{
    float3 c0 = tex.Sample(samp, coord).rgb;
    return float4(mul(c0,SDtoHD),1);
}
