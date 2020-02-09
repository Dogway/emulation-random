;#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; Script to Cycle through HeSuVi profiles with hotkeys
; AND raise or lower master volume.

; Notification is in audio file format (place inside HeSuVi\hrir folder)...
; so it doesn't interrupt with fullscreen applications in Exclusive Presentation mode

number := 0
vol := 100

RegRead, EqLoc, HKEY_LOCAL_MACHINE\SOFTWARE\EqualizerAPO, ConfigPath
HeSuVi_exe := EqLoc "\HeSuVi"

; HeSuVi Master Volume (Plus key)
SC01B::
	vol := Min(vol + 10, 120)
	Run, "%HeSuVi_exe%\HeSuVi.exe" -virtualizationvolume %vol%;100;100;100;100;200
Return

; HeSuVi Master Volume (Minus key)
-::
	vol := Max(vol - 10, 0)
	Run, "%HeSuVi_exe%\HeSuVi.exe" -virtualizationvolume %vol%;100;100;100;100;200
Return

; Cycle Up HeSuVi profiles
PgUp::
	number := Mod(number + 1, 5)
	number := if (number == 0) ? 1 : number
	num := Cycle(number)
	Run, "%HeSuVi_exe%\HeSuVi.exe" -virtualization %num%
	SoundPlay, %HeSuVi_exe%\hrir\Audio\%num%.wav, Wait
Return

; Cycle Down HeSuVi profiles
PgDn::
	number := Mod(number -1, 5)
	number := if (number == 0) ? 4 : number
	num := Cycle(number)
	Run, "%HeSuVi_exe%\HeSuVi.exe" -virtualization %num%
	SoundPlay, %HeSuVi_exe%\hrir\Audio\%num%.wav, Wait
Return

; These are my personal selection:
; Typically cmss_game for games
; dh++ for movies
; stereo (renamed from "none") for comparison
Cycle(num)
{
	LoadProfile = 
	( LTrim
			cmss_game
			dh++
			dtshx2+
			stereo
	)

	For i in LArray := StrSplit(LoadProfile, "`n") 
	Return LArray[num]
}