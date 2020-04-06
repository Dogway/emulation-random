#version 450


layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
    float LUT_Size1;
    float LUT1_toggle;
    float LUT_Size2;
    float LUT2_toggle;
} params;


// Parameter lines go here:
#pragma parameter LUT_Size1 "LUT 1 Size" 32.0 8.0 64.0 16.0
#pragma parameter LUT1_toggle "LUT 1 Toggle" 0.0 0.0 1.0 1.0
#pragma parameter LUT_Size2 "LUT 2 Size" 64.0 16.0 64.0 16.0
#pragma parameter LUT2_toggle "LUT 2 Toggle" 0.0 0.0 1.0 1.0

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
layout(set = 0, binding = 3) uniform sampler2D SamplerLUT1;
layout(set = 0, binding = 4) uniform sampler2D SamplerLUT2;


// This shouldn't be necessary but it seems some undefined values can
// creep in and each GPU vendor handles that differently. This keeps
// all values within a safe range
vec3 mixfix(vec3 a, vec3 b, float c)
{
    return (a.z < 1.0) ? mix(a, b, c) : a;
}



void main()
{

    vec3 imgColor = texture(Source, vTexCoord.xy).rgb;

//  Look LUT
    float red = (imgColor.r * (params.LUT_Size1 - 1.0) + 0.499999) / (params.LUT_Size1 * params.LUT_Size1);
    float green = (imgColor.g * (params.LUT_Size1 - 1.0) + 0.499999) / params.LUT_Size1;
    float blue1 = (floor(imgColor.b * (params.LUT_Size1 - 1.0)) / params.LUT_Size1) + red;
    float blue2 = (ceil(imgColor.b * (params.LUT_Size1 - 1.0)) / params.LUT_Size1) + red;
    float mixer = clamp(max((imgColor.b - blue1) / (blue2 - blue1), 0.0), 0.0, 32.0);
    vec3 color1 = texture( SamplerLUT1, vec2(blue1, green)).rgb;
    vec3 color2 = texture( SamplerLUT1, vec2(blue2, green)).rgb;
    vec3 res = mixfix(color1, color2, mixer);
    float l = mix(length(imgColor), length(res.rgb), 0.4);
    vec3 vcolor = (params.LUT1_toggle < 1.0) ? imgColor : clamp(normalize(res.rgb + 1e-10)*l, 0.0, 1.0);

//  Technical LUT
    float red_2 = ( vcolor.r * (params.LUT_Size2 - 1.0) + 0.499999 ) / (params.LUT_Size2 * params.LUT_Size2);
    float green_2 = ( vcolor.g * (params.LUT_Size2 - 1.0) + 0.499999 ) / params.LUT_Size2;
    float blue1_2 = (floor( vcolor.b  * (params.LUT_Size2 - 1.0) ) / params.LUT_Size2) + red_2;
    float blue2_2 = (ceil( vcolor.b  * (params.LUT_Size2 - 1.0) ) / params.LUT_Size2) + red_2;
    float mixer_2 = clamp(max((vcolor.b - blue1_2) / (blue2_2 - blue1_2), 0.0), 0.0, 32.0);
    vec3 color1_2 = texture( SamplerLUT2, vec2( blue1_2, green_2 )).rgb;
    vec3 color2_2 = texture( SamplerLUT2, vec2( blue2_2, green_2 )).rgb;
    vec3 res_2 = mixfix(color1_2, color2_2, mixer_2);
    float l_2 = mix(length(vcolor), length(res_2.rgb), 0.4);
    vec3 vcolor_2 = (params.LUT2_toggle < 1.0) ? vcolor : clamp(normalize(res_2.rgb + 1e-10)*l_2, 0.0, 1.0);

    FragColor = vec4(vcolor_2, 1.0);
}