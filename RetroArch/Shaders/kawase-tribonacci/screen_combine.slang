#version 450

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
} params;

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
layout(set = 0, binding = 2) uniform sampler2D Reference;
layout(set = 0, binding = 3) uniform sampler2D kawase0;
layout(set = 0, binding = 4) uniform sampler2D kawase1;
layout(set = 0, binding = 5) uniform sampler2D kawase2;
layout(set = 0, binding = 6) uniform sampler2D kawase3;
layout(set = 0, binding = 7) uniform sampler2D kawase4;
layout(set = 0, binding = 8) uniform sampler2D kawase5;

void main()
{
   vec4 blur = texture(kawase0, vTexCoord) + \
			   texture(kawase1, vTexCoord) + \
			   texture(kawase2, vTexCoord) + \
			   texture(kawase3, vTexCoord) + \
			   texture(kawase4, vTexCoord) + \
			   texture(kawase5, vTexCoord) ;
   FragColor = 1.0 - (1.0 - clamp(blur/vec4(5.), vec4(0.0), vec4(1.0))) * (1.0 - texture(Reference, vTexCoord));
   FragColor = pow(FragColor, vec4(2.2));
}
