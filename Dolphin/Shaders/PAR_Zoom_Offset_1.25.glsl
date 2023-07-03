/*
   PAR/ZOOM/OFFSET (or stretch/scale/offset)

   Copyright (C) 2023 Dogway (Jose Linares)

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


/*
Exact PAR
          PAL     NTSC
    4:3  128/117  4320/4739
    16:9 512/351  5760/4739

MPEG-4 PAR taken directly from the MPEG-4 standard documents. Very similar to exact ITU figures and usually used for MPEG-4 encodings.
          PAL   NTSC
    4:3  12/11  10/11
    16:9 16/11  40/33

Generic PAR (i.e. ignoring ITU)
This leads to an exact 16:9 DAR for an uncropped 16:9 PAL frame.
          PAL   NTSC
    4:3  16/15  8/9
    16:9 64/45  32/27

PAL  720x574 (SAR 16:15) (PAR 4:5)
NTSC 720x480 (SAR  8:9 ) (PAR 5:4)


https://es.dolphin-emu.org/blog/2015/08/01/dolphin-progress-report-july-2015/?cr=es#40-7138-pixel-aspect-ratio-adjustment-vi-scaling-fix-by-mirrorbender
https://forums.dolphin-emu.org/Thread-game-configuration-ini-s
https://forums.dolphin-emu.org/Thread-correct-aspect-ratio-option?page=12
https://bugs.dolphin-emu.org/issues/9024
https://bugs.dolphin-emu.org/issues/12684
https://github.com/dolphin-emu/dolphin/pull/2796


    For NTSC:
    // For "Wave Race"                       use "Stretch to Window" (for a 16:9 display), and then 1.33 for PAR and 0.75 for Zoom (results into DAR: 1.73)
    // For "Beyond Good & Evil"              use "Stretch to Window" (for a 16:9 display), and then 1.33 for PAR
    For PAL:
    // For "Star Fox: Assault"               use "Stretch to Window" (for a 16:9 display), and then 1.25 for PAR and 0.80 for Zoom (results into DAR: 1.63 -aiming to European Widescreen?-)
    // For "Star Wars: Rogue Leader II"      use "Auto",                                   and then 0.92 for PAR and 1.00 for Zoom
    // For "Star Wars: Rogue Squadron III"   use "Force 16:9",                             and then 1.25 for PAR and 0.80 for Zoom

    With NTSC Dolphin internal Widescreen Hack (no patches seemed to work)
    // For "Wave Race"                       use "Stretch to Window" (for a 16:9 display), and then 0.92 for PAR and 1.00 for Zoom
    // For "Beyond Good & Evil"              use "Stretch to Window" (for a 16:9 display), and shader disabled
    With PAL AR Widescreen Patches (HUD and some cut-scenes will look highly stretched tho)
    // For "Prince of Persia: Two thrones"   use "Stretch to Window" (for a 16:9 display), and shader disabled (HUD and FMVs are not adapted though)
    // For "Prince of Persia: Warrior Within"use "Force 16:9",                             and then 0.92 for PAR and 1.00 for Zoom (HUD and FMVs are not adapted though)
    // For "Prince of Persia: Sands of Time" use "Auto",                                   and then 1.09 for PAR and 1.00 for Zoom
    // For "Star Fox: Assault"               use "Stretch to Window" (for a 16:9 display), and then 0.92 for PAR and 1.00 for Zoom
    // For "Star Wars: Rogue Leader II"      use "Stretch to Window" (for a 16:9 display), and shader disabled
*/


/*
[configuration]

[OptionRangeFloat]
GUIName = Pixel Aspect Ratio (PAR)
OptionName = ASPECT
MinValue = 0.50
MaxValue = 2.00
StepAmount = 0.01
DefaultValue = 1.25

[OptionRangeFloat]
GUIName = Zoom
OptionName = ZOOM
MinValue = 0.50
MaxValue = 1.50
StepAmount = 0.01
DefaultValue = 0.80

[OptionRangeFloat]
GUIName = Y Offset
OptionName = OFFSET
MinValue = 0.80
MaxValue = 1.25
StepAmount = 0.01
DefaultValue = 1.00

[/configuration]
*/


void main()
{
    float2   ZMA = GetOption(ZOOM)*float2(1.0,GetOption(ASPECT));
    float2 coord = (GetCoordinates()-float2(0.5,0.5)) / ZMA + float2(0.5,GetOption(OFFSET)-0.5);
    float2 crdcl = clamp(coord,0.0,1.0);
    SetOutput(crdcl.x==coord.x && crdcl.y==coord.y ? SampleLocation(coord) : float4(0.0, 0.0, 0.0, 0.0));
}
