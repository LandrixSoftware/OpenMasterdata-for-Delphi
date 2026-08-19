@echo off
rem Baut die Login-Pruefung und fuehrt sie aus. Parameter werden durchgereicht:
rem   run-logintest.bat            alle Zugaenge
rem   run-logintest.bat Sonepar    nur passende Zugaenge
rem   run-logintest.bat Sonepar cc Grant-Type uebersteuern
rem
rem Voraussetzung: eine installierte Delphi-Version. Der Pfad wird ueber
rem rsvars.bat aus der Umgebung gesucht, notfalls BDS setzen.

setlocal

if "%BDS%"=="" (
  for %%v in (37.0 36.0 35.0 34.0) do (
    if exist "%ProgramFiles(x86)%\Embarcadero\Studio\%%v\bin\rsvars.bat" (
      call "%ProgramFiles(x86)%\Embarcadero\Studio\%%v\bin\rsvars.bat"
      goto :found
    )
  )
  echo Keine Delphi-Installation gefunden. Bitte BDS setzen oder rsvars.bat aufrufen.
  exit /b 2
) else (
  call "%BDS%\bin\rsvars.bat"
)

:found
cd /d "%~dp0"
if not exist dcu mkdir dcu

dcc32 -B -CC -E. -N.\dcu -U"..\.." -NSSystem;System.Win;Winapi;Vcl;Data;REST;Xml;Web;Soap LoginTest.dpr
if errorlevel 1 (
  echo Kompilierung fehlgeschlagen.
  exit /b 2
)

".\LoginTest.exe" %*
exit /b %errorlevel%
