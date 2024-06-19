@echo off
REM moving %1 so the DLL can be compiled even though it is currently loaded in the IDE
move %1 %1~
exit /b 0

REM Thanks to dummzeuch for providing this amazing batch file for developing RAD Studio dll experts