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
    For NTSC:
    // For "Wave Race"                       use "Stretch to Window" (for a 16:9 display), and then 1.33 for PAR and 0.75 for Zoom (results into DAR: 1.73)
    // For "Beyond Good & Evil"              use "Stretch to Window" (for a 16:9 display), and then 1.33 for PAR
    For PAL:
    // For "Star Fox: Assault"               use "Stretch to Window" (for a 16:9 display), and then 1.25 for PAR and 0.80 for Zoom (results into DAR: 1.63 -aiming to European Widescreen?-)
    // For "Star Wars: Rogue Leader II"      use "Auto",                                   and then 0.92 for PAR and 1.00 for Zoom
    // For "Star Wars: Rogue Squadron III"   use "Force 16:9",                             and then 1.25 for PAR and 0.80 for Zoom

    With AR Widescreen Patch (HUD and some cut-scenes will look highly stretched tho)
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
MinValue = 0.5
MaxValue = 2.0
StepAmount = 0.01
DefaultValue = 1.00

[OptionRangeFloat]
GUIName = Zoom
OptionName = ZOOM
MinValue = 0.5
MaxValue = 1.5
StepAmount = 0.01
DefaultValue = 1.00

[OptionRangeFloat]
GUIName = Y Offset
OptionName = OFFSET
MinValue = 0.8
MaxValue = 1.25
StepAmount = 0.01
DefaultValue = 1.00

[/configuration]
*/


void main()
{
    float2   ZMA = GetOption(ZOOM)*float2(1.0,GetOption(ASPECT));
    float2 coord = (GetCoordinates()-float2(0.5)) / ZMA + float2(0.5,GetOption(OFFSET)-0.5);
    SetOutput(clamp(coord,0.0,1.0)==coord ? SampleLocation(coord) : float4(0.0));
}
