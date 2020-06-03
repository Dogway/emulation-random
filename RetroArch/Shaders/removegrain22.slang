#version 450

/*
   removegrain(mode=22) median filter ported to slang by Dogway
   Shader template based on Hyllian's Smart-Blur Shader
  
   Copyright (C) 2011-2016 Hyllian - sergiogdb@gmail.com
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:
   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
*/

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
layout(location = 1) out vec4 t1;
layout(location = 2) out vec4 t2;
layout(location = 3) out vec4 t3;

void main()
{
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
    float dx = params.SourceSize.z;
    float dy = params.SourceSize.w;

    t1 = vTexCoord.xxxy + vec4( -dx,    0.0,    dx, -dy); //  A B C
    t2 = vTexCoord.xxxy + vec4( -dx,    0.0,    dx, 0.0); //  D E F
    t3 = vTexCoord.xxxy + vec4( -dx,    0.0,    dx, dy); //  G H I
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec4 t1;
layout(location = 2) in vec4 t2;
layout(location = 3) in vec4 t3;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

/*       
           a1  a2  a3
           a4  E   a5 
           a6  a7  a8
*/

void main()
{
    vec3   a1 = texture(Source, t1.xw).xyz;
    vec3   a2 = texture(Source, t1.yw).xyz;
    vec3   a3 = texture(Source, t1.zw).xyz;
    vec3   a4 = texture(Source, t2.xw).xyz;
    vec3   E  = texture(Source, t2.yw).xyz;
    vec3   a5 = texture(Source, t2.zw).xyz;
    vec3   a6 = texture(Source, t3.xw).xyz;
    vec3   a7 = texture(Source, t3.yw).xyz;
    vec3   a8 = texture(Source, t3.zw).xyz;

    vec3 l1 = (a1 + a8) / 2.;
    vec3 l2 = (a2 + a7) / 2.;
    vec3 l3 = (a3 + a6) / 2.;
    vec3 l4 = (a4 + a5) / 2.;

    vec3 ma = max(max(max(l1, l2), l3), l4);
    vec3 mi = min(min(min(l1, l2), l3), l4);

    FragColor = vec4(clamp(E,mi,ma), 1.0);
}