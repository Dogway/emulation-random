; HeSuVi Cycle Profiles.ahk
;    Jose Linares -Dogway- (2020)
;        >> https://github.com/Dogway

; Script to Cycle through HeSuVi profiles with hotkeys...
; ...AND raise or lower master volume.

; Notification is in audio file format (place them inside HeSuVi\hrir folder)...
; ...so it doesn't interrupt with fullscreen applications in Exclusive mode.

#NoEnv

SendMode Input
SetWorkingDir %A_ScriptDir%


number := 0
vol := 100

RegRead, EqLoc, HKEY_LOCAL_MACHINE\SOFTWARE\EqualizerAPO, ConfigPath
HeSuVi_exe := EqLoc "\HeSuVi"

; HeSuVi Master Volume (Plus key)
~SC01B::
	vol := Min(vol + 5, 150)
	FileRead, VolSUR, %HeSuVi_exe%\mix.txt
	FileRead, VolCLF, %HeSuVi_exe%\lfc.txt
	RegExMatch(VolSUR, "(\d\.\d+)\*L0\+(\d\.\d+)\*SL0\+(\d\.\d+)\*RL0", MX)
	RegExMatch(VolCLF, "(\d\.\d+)\*CVI\+(\d\.\d+)\*SUBVI", MC)
	FV:=% round(MX1 * 100)
	SV:=% round(MX2 * 100)
	RV:=% round(MX3 * 100)
	CV:=% round(MC1 * 100)
	EV:=% round(MC2 * 100)
	Run, "%HeSuVi_exe%\HeSuVi.exe" -virtualizationvolume %vol%;%CV%;%FV%;%SV%;%RV%;%EV%
Return

; HeSuVi Master Volume (Minus key)
~-::
	vol := Max(vol - 5, 0)
	FileRead, VolSUR, %HeSuVi_exe%\mix.txt
	FileRead, VolCLF, %HeSuVi_exe%\lfc.txt
	RegExMatch(VolSUR, "(\d\.\d+)\*L0\+(\d\.\d+)\*SL0\+(\d\.\d+)\*RL0", PX)
	RegExMatch(VolCLF, "(\d\.\d+)\*CVI\+(\d\.\d+)\*SUBVI", PC)
	FV:=% round(PX1 * 100)
	SV:=% round(PX2 * 100)
	RV:=% round(PX3 * 100)
	CV:=% round(PC1 * 100)
	EV:=% round(PC2 * 100)
	Run, "%HeSuVi_exe%\HeSuVi.exe" -virtualizationvolume %vol%;%CV%;%FV%;%SV%;%RV%;%EV%
Return

; Cycle Down HeSuVi profiles
~PgDn::
	number := Mod(number + 1, 6)
	number := if (number == 0) ? 1 : number
	num := Cycle(number)
	Run, "%HeSuVi_exe%\HeSuVi.exe" -virtualization %num%
	SoundPlay, %HeSuVi_exe%\hrir\Audio\%num%.wav, Wait
Return

; Cycle Up HeSuVi profiles
~PgUp::
	number := Mod(number - 1, 6)
	number := if (number == 0) ? 5 : number
	num := Cycle(number)
	Run, "%HeSuVi_exe%\HeSuVi.exe" -virtualization %num%
	SoundPlay, %HeSuVi_exe%\hrir\Audio\%num%.wav, Wait
Return

; Out of my personal selection:
; cmss_game for games
; dh++ for movies
; dts_hpx for music
; stereo (renamed from "none") for comparison
Cycle(num)
{
	LoadProfile = 
	( LTrim
			cmss_game
			dts_hpx_oe_bal
			dts_hpx_oe_spac
			dh++
			stereo
	)

	For i in LArray := StrSplit(LoadProfile, "`n") 
	Return LArray[num]
}