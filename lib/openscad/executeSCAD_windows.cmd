@echo off
for /r %%i in (*.scad) do (
	echo Rendering the file %%i
	openscad -o %%~ni.stl "%%i"
	echo Done
)
PAUSE
