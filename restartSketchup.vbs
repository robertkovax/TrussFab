'Restarts SketchUp in Windows.'
'Adjust Path to your SketchUp executable.'
'Adjust Welcome Screen Title to your language.'
'To run from taskbar, create shortcut and edit (shift-rightclick) it to'
'wscript.exe "C:\Full Path\To My\restartSketchup.vbs"'


Set shell = WScript.CreateObject("WScript.Shell")
shell.Run "tskill SketchUp"
WScript.Sleep 200
shell.Run """C:\Program Files\SketchUp\SketchUp 2016\SketchUp.exe"""
shell.AppActivate "Willkommen bei SketchUp"
WScript.Sleep 500
shell.SendKeys " "