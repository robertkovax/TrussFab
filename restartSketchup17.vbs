'Restarts SketchUp in Windows.'
'Adjust Path to your SketchUp executable.'
'Adjust Welcome Screen Title to your language.'
'To run from taskbar, create shortcut and edit (shift-rightclick) it to'
'wscript.exe "C:\full\path\to\restartSketchup.vbs"'


Set shell = WScript.CreateObject("WScript.Shell")
shell.Run "tskill SketchUp"
WScript.Sleep 200
shell.Run """C:\Program Files\SketchUp\SketchUp 2017\SketchUp.exe"""
shell.AppActivate "Welcome to SketchUp"
Do Until shell.AppActivate("Welcome to SketchUp")
Loop
If shell.AppActivate("Welcome to SketchUp") Then
shell.SendKeys "%{F4}"
End If

Do Until shell.AppActivate("Load Error")
Loop
If shell.AppActivate("Load Error") Then
shell.SendKeys "%{F4}"
End If