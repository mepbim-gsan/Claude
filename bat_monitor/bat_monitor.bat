@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

REM ================================================================
REM  [Settings] Edit only this section
REM
REM  Usage:
REM    Copy this file as home.bat / office.bat etc. and
REM    configure the values below for each environment.
REM
REM  Monitor numbers:
REM    Internal display is excluded when SKIP_INTERNAL=YES.
REM    MON1 / MON2 refer to external monitor 1 and 2.
REM
REM  LAYOUT:
REM    1-2    ->  MON1 left, MON2 right
REM    2-1    ->  MON2 left, MON1 right
REM    1-L-2  ->  MON1 left, Laptop center, MON2 right  (lid open only)
REM    2-L-1  ->  MON2 left, Laptop center, MON1 right  (lid open only)
REM
REM  PRIMARY_MON:
REM    External monitor number to set as primary (1 or 2)
REM
REM  SCALE values (DPI percentage):
REM    100% -> 96   125% -> 120   150% -> 144
REM    175% -> 168  200% -> 192
REM ================================================================

set SKIP_INTERNAL=YES
set PRIMARY_MON=1
set LAYOUT=1-2

REM --- External Monitor 1 ---
set MON1_WIDTH=1920
set MON1_HEIGHT=1080
set MON1_REFRESH=60
set MON1_SCALE=96

REM --- External Monitor 2 ---
set MON2_WIDTH=2560
set MON2_HEIGHT=1440
set MON2_REFRESH=60
set MON2_SCALE=120

REM Number of external monitors (1 or 2)
set MONITOR_COUNT=2

REM ================================================================

echo.
echo ============================================
echo  bat_monitor
echo ============================================
echo.

REM --- Check active monitor count ---
for /f "usebackq" %%n in (`powershell -NoProfile -Command "(Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorBasicDisplayParams ^| Where-Object {$_.Active -eq $true}).Count"`) do set DETECTED=%%n
echo Active monitors detected: %DETECTED%

REM --- Lid open/close detection ---
set /a LID_THRESHOLD=%MONITOR_COUNT%+1
if %DETECTED% EQU %MONITOR_COUNT% (
    set LID_OPEN=NO
    echo Lid: closed (LID_OPEN=NO^)
) else (
    if %DETECTED% EQU %LID_THRESHOLD% (
        set LID_OPEN=YES
        echo Lid: open (LID_OPEN=YES^)
    ) else (
        set LID_OPEN=NO
        echo Lid: unknown -^> LID_OPEN=NO
    )
)

if %DETECTED% LSS 2 (
    echo.
    echo [WARNING] Only 1 monitor detected.
    echo           Connect external monitors and try again.
    echo.
    pause
    exit /b 1
)

REM --- [1/3] Switch to Extend mode ---
echo.
echo [1/3] Switching to Extend mode...
DisplaySwitch.exe /extend
echo     Done

REM --- [2/3] Resolution / position / primary ---
echo.
echo [2/3] Applying resolution, position, primary...
echo     SKIP_INTERNAL = %SKIP_INTERNAL%
echo     PRIMARY_MON   = %PRIMARY_MON%
echo     LAYOUT        = %LAYOUT%

set "PSHELPER=%~dp0_monitor_helper.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PSHELPER%" ^
    -SkipInternal "%SKIP_INTERNAL%" ^
    -PrimaryMon %PRIMARY_MON% ^
    -Layout "%LAYOUT%" ^
    -Mon1W %MON1_WIDTH% -Mon1H %MON1_HEIGHT% -Mon1R %MON1_REFRESH% -Mon1S %MON1_SCALE% ^
    -Mon2W %MON2_WIDTH% -Mon2H %MON2_HEIGHT% -Mon2R %MON2_REFRESH% -Mon2S %MON2_SCALE% ^
    -MonCount %MONITOR_COUNT% ^
    -LidOpen "%LID_OPEN%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] PowerShell script failed.
    echo         Run as administrator or check README.
    echo.
    pause
    exit /b %ERRORLEVEL%
)

REM --- Done ---
echo.
echo ============================================
echo  Done.
echo  Note: DPI scale is applied immediately.
echo  If not reflected, sign out and back in.
echo ============================================
echo.
pause
endlocal
