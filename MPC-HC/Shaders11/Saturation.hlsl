// $MinimumShaderProfile: ps_4_0
/*
 * 2023 Dogway (Jose Linares)
 *
 * Saturation shader for Rec709 RGB
 * Tailored to Projectors or LED Displays with a Cinema Reference White (~48nits)
 *
 * For a simple saturation control set the last 2 parameters to 0.0
 *
 */


Texture2D tex : register(t0);
SamplerState samp : register(s0);


#define saturation (1.2)		 // Saturation multiplier. Increase to compensate for the sum of the Hunt Effect (colorfulness increases with luminance -at low luminance levels-)
								 // and LED saturation reduction under lower than reference white levels (ie. using 48nits instead of typical 100nits for home consumer media) (see: https://www.lightillusion.com/advanced_operation.html#oled)
#define BezoldBrucke (1.0)		 // Bezold-Brücke effect. Enable to decrease saturation more in the red/green (magenta/cyan) axis to compensate for the HUE shift in low reference white levels (ie. 48nits)
#define masked (1.0)		     // Saturation is masked via luminance, to affect more the mid to shadow areas given the LED desaturation effect


static const float3x3 YUV = {
     0.212600, 0.715179, 0.072221,
    -0.114575,-0.385425, 0.500000,
     0.500000,-0.454140,-0.045861};

static const float3x3 SRGB = {
     1.000000, 1.000000, 1.000000,
     0.000000,-0.187380, 1.855558,
     1.574800,-0.468138, 0.000000};


float4 main(float4 pos : SV_POSITION, float2 coord : TEXCOORD) : SV_Target
{
    float3 c0 = tex.Sample(samp, coord).rgb;
    float3x3 SYUV = {YUV[0],saturation*YUV[1],(BezoldBrucke==1.0?(((saturation-1)/2.0)+1):saturation)*YUV[2]};
    float3 ou = mul(c0,mul(transpose(SYUV),SRGB));
           ou = masked==1.0 ? lerp(ou,c0,dot(c0,YUV[0])) : ou;
    return float4(ou,1);
}
