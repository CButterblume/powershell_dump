@echo off
setlocal

Rem Paket "MS_EXCH2013_Server"
Rem Autor: baumh
Rem Änderung: 31.05.2016


REM Pfad der Hersteller-Datei (relativ zu SWSource\BaseIsos)
set ARCHIV=Microsoft\Exchange\SW_DVD9_EXCHANGE_SVR_2013W_SP1_MULTILANG_STD_ENT_MLF_X19-35118.ISO

REM Hier angeben, welche Dateien (mit Pfad) extrahiert werden sollen
REM leer lassen, wenn alle benötigt werden
REM Bsp:  amd64\*
set EXTRACTPATTERN=

REM Beispiel exclude option: -xr!"x86" -x!"autorun.inf" 
REM Falls Verzeichnisstruktur aus archiv nicht benötigt wird ist Kommand e (statt x) zu verwenden
7z.exe x -o"%DSTDir%\Source"  "%ISO_DIR%\%ARCHIV%" %EXTRACTPATTERN%
set EL=%ERRORLEVEL%

echo Returncode: %EL%

exit /b %EL%

