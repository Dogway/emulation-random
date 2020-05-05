#version 450

/*
   mod of AGS-001 shader
   A pristine recreation of the illuminated Game Boy Advance SP
   Author: endrift
   License: MPL 2.0

   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. 
*/

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
	vec4 OutputSize;
	vec4 OriginalSize;
	vec4 SourceSize;
} global;

layout(push_constant) uniform Push
{
	float togglereflection;
	float reflectionBrightness;
	float reflectionDistanceX;
	float reflectionDistanceY;
}params;

#pragma parameter togglereflection "Toggle Reflection" 1.0 0.0 1.0 1.00
#pragma parameter reflectionBrightness "Reflection brightness" 0.07 0.0 1.0 0.01
#pragma parameter reflectionDistanceX "Reflection Distance X" 0.0 -1.0 1.0 0.01
#pragma parameter reflectionDistanceY "Reflection Distance Y" 0.1 -1.0 1.0 0.01

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


void main()
{
	vec2 reflectionDistance = vec2(params.reflectionDistanceX,params.reflectionDistanceY);

	vec4 color = texture(Source, vTexCoord);

	vec4 reflection = texture(Source, vTexCoord - (reflectionDistance / 10.));
	FragColor = (params.togglereflection == 0.0) ? color : vec4(1. - (1. - color.rgb) * (1. - reflection * params.reflectionBrightness), 1.0);
}
