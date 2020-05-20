#version 450

/*
   Phosphor Afterglow Shader

   Copyright (C) 2018 guest(r) - guest.r@gmail.com

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

layout(push_constant) uniform Push
{
   float PH, SW, PER, sat;
} params;

// PER = 3.0 for realistic, Phosphor index it's the same as in the "grade" shader
#pragma parameter PH "Phosphor" -1.0 -1.0 3.0 1.0
#pragma parameter SW "Afterglow switch ON/OFF" 1.0 0.0 1.0 1.0
#pragma parameter PER "Persistence (more is less)" 3.0 0.5 3.0 0.1
#pragma parameter sat "Afterglow saturation" 0.20 0.0 1.0 0.01

#define PH params.PH
#define SW params.SW
#define PER params.PER
#define sat params.sat

#define COMPAT_TEXTURE(c,d) texture(c,d)

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
layout(set = 0, binding = 3) uniform sampler2D OriginalHistory1;
layout(set = 0, binding = 4) uniform sampler2D OriginalHistory2;
layout(set = 0, binding = 5) uniform sampler2D OriginalHistory3;
layout(set = 0, binding = 6) uniform sampler2D OriginalHistory4;
layout(set = 0, binding = 7) uniform sampler2D OriginalHistory5;
layout(set = 0, binding = 8) uniform sampler2D OriginalHistory6;

#define Prev1Texture OriginalHistory1
#define Prev2Texture OriginalHistory2
#define Prev3Texture OriginalHistory3
#define Prev4Texture OriginalHistory4
#define Prev5Texture OriginalHistory5
#define Prev6Texture OriginalHistory6

#define TEX0 vTexCoord

#define eps 1e-3

// PAL
const vec3 PAL = vec3(0.290, 0.600, 0.110);
// JAP
const vec3 NTSC_J = vec3(0.280, 0.605, 0.115);
// SMPTE
const vec3 NTSC = vec3(0.310, 0.595, 0.095);
// P22
const vec3 P22 = vec3(0.282, 0.620, 0.098);


vec3 afterglow(float Pho, float decay)
{
    vec3 p_in;

    if (Pho == -1.0) { p_in = P22;            } else
    if (Pho ==  1.0) { p_in = NTSC;           } else
    if (Pho ==  2.0) { p_in = NTSC_J;         } else
    if (Pho ==  3.0) { p_in = PAL;            }

// Phosphor Response / Cone Response
	vec3 p_res = (p_in / (vec3(0.21264933049678802, 0.71516913175582890,  0.07218152284622192))/10.0);

	float decr = clamp((log(1./p_res.r)+0.2)/(decay),0.0,1.0);
	float decg = clamp((log(1./p_res.g)+0.2)/(decay),0.0,1.0);
	float decb = clamp((log(1./p_res.b)+0.2)/(decay),0.0,1.0);
	float decmax = max(max(decr,decg),decb);

	return vec3(decr, decg, decb);
}

void main()
{
	vec3 color = COMPAT_TEXTURE(Source, TEX0.xy).rgb;
	vec3 color1 = COMPAT_TEXTURE(Prev1Texture, TEX0.xy).rgb * afterglow(PH, PER*10.0);
	vec3 color2 = COMPAT_TEXTURE(Prev2Texture, TEX0.xy).rgb * afterglow(PH, PER*20.0);
	vec3 color3 = COMPAT_TEXTURE(Prev3Texture, TEX0.xy).rgb * afterglow(PH, PER*30.0);
	vec3 color4 = COMPAT_TEXTURE(Prev4Texture, TEX0.xy).rgb * afterglow(PH, PER*40.0);
	vec3 color5 = COMPAT_TEXTURE(Prev5Texture, TEX0.xy).rgb * afterglow(PH, PER*50.0);
	vec3 color6 = COMPAT_TEXTURE(Prev6Texture, TEX0.xy).rgb * afterglow(PH, PER*60.0);

	vec3 glow = color1 + color2 + color3 + color4 + color5 + color6;

	float l = length(glow);
	glow = normalize(pow(glow + vec3(eps), vec3(sat)))*l;

	float w = 1.0;
	if ((color.r + color.g + color.b) > 7.0/255.0) w = 0.0;

	FragColor = vec4(clamp(color + SW*w*glow,0.0,1.0),1.0);
}