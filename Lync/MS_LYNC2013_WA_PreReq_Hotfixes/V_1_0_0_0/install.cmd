@echo off
cls
set ScriptPath=%~dp0

set PSArguments=
if "%~1"=="" goto StartPowershell
:: Double quotes that need to be passed to the script when calling powershell.exe need to be escaped with backslashes:
set PSArguments= %*
set PSArguments=%PSArguments:"=\"%

set RunAs32=False
:Loop_Arguments
if "%~1"=="" goto StartPowershell
if /i "%~1"=="-RunAs32" (set RunAs32=True& goto StartPowershell)
shift & goto :Loop_Arguments

:StartPowershell
if "%RunAs32%"=="True" (
	if "%PROCESSOR_ARCHITECTURE%"=="x86" (
		%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe "& '%ScriptPath%Install-Script.ps1'%PSArguments%"
	) else (
		%SystemRoot%\SysWOW64\WindowsPowerShell\v1.0\powershell.exe "& '%ScriptPath%Install-Script.ps1'%PSArguments%"
	)
) else (
	REM To allow 64-bit powershell code execution even if powershell is being called from a 32-bit environment (SCCM) on 64-bit systems
	REM sysnative is being redirected to the 64-bit system32 directory in a WoW6432 environment
	if exist "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" (
		%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe "& '%ScriptPath%Install-Script.ps1'%PSArguments%"
	) else (
		%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe "& '%ScriptPath%Install-Script.ps1'%PSArguments%"
	)
)
