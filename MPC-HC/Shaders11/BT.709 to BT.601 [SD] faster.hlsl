// $MinimumShaderProfile: ps_4_0
/*
 * 2023 Dogway (Jose Linares)
 *
 * Fix wrong matrix encoded pixels in SD sources (BT.709 [HD] pixels in BT.601 tagged SD video)
 *
 * Note 1: Beware only model conversion matrix coefficients, color space primaries are kept.
 *
 * Note 2: This fix is for actual wrong mastering (RGB to YCbCr) conversions, while the tagging
 *         is still specification correct for SD Video (BT.601).
 *         (https://forum.doom9.org/showpost.php?p=1988786)
 */


Texture2D tex : register(t0);
SamplerState samp : register(s0);


static const float3x3 HDtoSD = {
      1.086312532424926800, 0.09646914154291153, -0.01426598709076643,
     -0.072217509150505070, 0.84451305866241460, -0.02799798548221588,
     -0.014093538746237755, 0.05901721492409706,  1.04226386547088620};


float4 main(float4 pos : SV_POSITION, float2 coord : TEXCOORD) : SV_Target
{
    float3 c0 = tex.Sample(samp, coord).rgb;
    return float4(mul(c0,HDtoSD),1);
}
