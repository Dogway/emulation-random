// $MinimumShaderProfile: ps_2_0
/*
 * 2023 Dogway (Jose Linares)
 *
 * Saturation shader for Rec709 RGB
 *
 */


sampler s0 : register(s0);
float4 p0 :  register(c0);


#define saturation (1.3)		 // Saturation multiplier. Increase to compensate for LED saturation reduction under lower than reference white levels (ie. using 48nits instead of typical 100nits for home consumer media) (see: https://www.lightillusion.com/advanced_operation.html#oled)
#define masked (1.0)		     // Saturation is masked via luminance, to affect more the mid to shadows areas


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


float4 main(float2 tex : TEXCOORD0) : COLOR
{
    float4 c0 = tex2D(s0, tex);
    float3x3 SYUV = {YUV[0],saturation*YUV[1],saturation*YUV[2]};
    float3 ou = mul(c0.rgb,mul(transpose(SYUV),SRGB));
           ou = masked==1.0 ? lerp(ou,c0.rgb,dot(c0.rgb,YUV[0])) : ou;
    return float4(ou,1);
}
