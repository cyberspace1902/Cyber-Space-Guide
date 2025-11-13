@echo off
setlocal EnableDelayedExpansion

:: =====================================
::  Ubisoft Connect Online/Offline Toggler (By Cyber Space and ChatGPT)
:: =====================================

:: -------------------------
:: Self-elevate if not admin
:: -------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator permission...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c %~s0", "", "runas", 1 >> "%temp%\getadmin.vbs"
    cscript //nologo "%temp%\getadmin.vbs" >nul
    del "%temp%\getadmin.vbs"
    exit /b
)

:: -------------------------
:: Detect UplayWebCore.exe
:: -------------------------
set "UPLAY_EXE="

for /f "tokens=3*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\Ubisoft\Launcher" /v InstallDir 2^>nul') do (
    set "UPLAY_EXE=%%A %%BUplayWebCore.exe"
)

if not defined UPLAY_EXE (
    for /f "tokens=3*" %%A in ('reg query "HKLM\SOFTWARE\Ubisoft\Launcher" /v InstallDir 2^>nul') do (
        set "UPLAY_EXE=%%A %%BUplayWebCore.exe"
    )
)

if not defined UPLAY_EXE (
    set "UPLAY_EXE=C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\UplayWebCore.exe"
)

if not exist "!UPLAY_EXE!" (
    echo UplayWebCore.exe not found at:
    echo   !UPLAY_EXE!
    echo.
    set /p UPLAY_EXE=Enter full path to UplayWebCore.exe: 
    if not exist "!UPLAY_EXE!" (
        echo File not found. Exiting.
        timeout /t 3 >nul
        exit /b
    )
)

:: -------------------------
:: Firewall rule toggle
:: -------------------------
set "RULE_NAME=Ubisoft Connect Offline Rule (By Cyber Space)"

:: Create popup (Yes / No / Cancel)
set "vbs=%temp%\_uplaywebcore_firewall_prompt.vbs"
> "%vbs%" echo Set s = CreateObject^("WScript.Shell"^)
>>"%vbs%" echo msg = "Do you want to force Ubisoft Connect into Offline Mode?" ^& vbCrLf ^& "YES = Force Ubisoft Connect into Offline mode." ^& vbCrLf ^& "NO = Revert Ubisoft Connect Force Offline Changes." ^& vbCrLf ^& "CANCEL = Exit with no changes."
>>"%vbs%" echo r = s.Popup(msg, 0, "Ubisoft Connect Offline Toggler (By Cyber Space and ChatGPT)", 3 + 32)
>>"%vbs%" echo WScript.Quit r

cscript //nologo "%vbs%" >nul
set "exitcode=%errorlevel%"
del "%vbs%"

:: one shared temp vbs path for result popups
set "VBS_RESULT=%temp%\_uplaywebcore_result.vbs"

if "%exitcode%"=="6" (
    netsh advfirewall firewall add rule name="%RULE_NAME%" dir=out program="!UPLAY_EXE!" action=block enable=yes >nul 2>&1

    rem --- show confirmation popup: OFFLINE ---
    >"%VBS_RESULT%" echo Set sh = CreateObject^("WScript.Shell"^)
    >>"%VBS_RESULT%" echo sh.Popup "Ubisoft Connect has been forced into offline mode by firewall rule.", 0, "Ubisoft Connect Online/Offline Toggler (By Cyber Space and ChatGPT)", 64
    cscript //nologo "%VBS_RESULT%" >nul
    del "%VBS_RESULT%" >nul 2>&1

) else if "%exitcode%"=="7" (
    netsh advfirewall firewall delete rule name="%RULE_NAME%" >nul 2>&1

    rem --- show confirmation popup: ONLINE ---
    >"%VBS_RESULT%" echo Set sh = CreateObject^("WScript.Shell"^)
    >>"%VBS_RESULT%" echo sh.Popup "Ubisoft Connect has now reverted to online mode by removing firewall rule.", 0, "Ubisoft Connect Offline Toggler (By Cyber Space and ChatGPT)", 64
    cscript //nologo "%VBS_RESULT%" >nul
    del "%VBS_RESULT%" >nul 2>&1

) else (
    rem Cancel or anything else: do nothing
)

exit
