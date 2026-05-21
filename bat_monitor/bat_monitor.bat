@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

:: ================================================================
::  [設定欄] ここだけ書き換えて使用する
::
::  使い方:
::    このファイルをコピーして home.bat / office.bat などの名前で保存し、
::    それぞれの環境に合わせて下記の値を書き換える。
::
::  モニター番号について:
::    ノートPCの内蔵画面は SKIP_INTERNAL=YES で自動除外される。
::    MON1 / MON2 は「外部モニターの 1 台目 / 2 台目」を指す。
::
::  LAYOUT について:
::    1-2    →  MON1 が左、MON2 が右
::    2-1    →  MON2 が左、MON1 が右
::    1-L-2  →  MON1 が左、内蔵ディスプレイが中央、MON2 が右（蓋が開いている時のみ）
::    2-L-1  →  MON2 が左、内蔵ディスプレイが中央、MON1 が右（蓋が開いている時のみ）
::
::  PRIMARY_MON について:
::    メインモニターにする外部モニター番号（1 または 2）
::
::  倍率（SCALE）の目安:
::    100% → 96   125% → 120   150% → 144
::    175% → 168  200% → 192
:: ================================================================

set SKIP_INTERNAL=YES
set PRIMARY_MON=1
set LAYOUT=1-2

:: --- 外部モニター 1 ---
set MON1_WIDTH=1920
set MON1_HEIGHT=1080
set MON1_REFRESH=60
set MON1_SCALE=96

:: --- 外部モニター 2 ---
set MON2_WIDTH=2560
set MON2_HEIGHT=1440
set MON2_REFRESH=60
set MON2_SCALE=120

:: 使用する外部モニター数（1 or 2）
set MONITOR_COUNT=2

:: ================================================================

echo.
echo ============================================
echo  bat_monitor - マルチモニター設定スクリプト
echo ============================================
echo.

:: --- 接続モニター数を確認 ---
for /f "usebackq" %%n in (`powershell -NoProfile -Command "(Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorBasicDisplayParams ^| Where-Object {$_.Active -eq $true}).Count"`) do set DETECTED=%%n
echo 検出されたアクティブモニター数: %DETECTED% 台

:: --- 蓋開閉検出 ---
set /a LID_THRESHOLD=%MONITOR_COUNT%+1
if %DETECTED% EQU %MONITOR_COUNT% (
    set LID_OPEN=NO
    echo 蓋の状態: 閉じている（LID_OPEN=NO）
) else (
    if %DETECTED% EQU %LID_THRESHOLD% (
        set LID_OPEN=YES
        echo 蓋の状態: 開いている（LID_OPEN=YES）
    ) else (
        set LID_OPEN=NO
        echo 蓋の状態: 判定不能 -> LID_OPEN=NO
    )
)

if %DETECTED% LSS 2 (
    echo.
    echo [警告] モニターが 1 台しか検出されていません。
    echo        外部モニターを接続してから再実行してください。
    echo.
    pause
    exit /b 1
)

:: --- [1/3] 拡張モードへ切り替え ---
echo.
echo [1/3] 表示モードを「拡張」に切り替えています...
DisplaySwitch.exe /extend
echo     完了

:: --- [2/3] 解像度・配置・メインモニター設定 ---
echo.
echo [2/3] 解像度・配置・メインモニターを設定しています...
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
    echo [エラー] PowerShell スクリプトが失敗しました。
    echo          管理者権限で実行するか、README を確認してください。
    echo.
    pause
    exit /b %ERRORLEVEL%
)

:: --- 完了メッセージ ---
echo.
echo ============================================
echo  設定完了
echo.
echo  ※ DPI スケール: 即時反映を試みています。
echo    反映されない場合はサインアウト後に再サインインしてください。
echo ============================================
echo.
pause
endlocal
