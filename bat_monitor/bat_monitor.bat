@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

:: ================================================================
::  [設定欄] ここだけ書き換えて使用する
::
::  使い方:
::    このファイルをコピーして home.bat / office.bat 等の名前で保存し、
::    それぞれの環境に合わせて下記の値を書き換える。
::
::  モニター番号について:
::    Windows の「ディスプレイの設定」で表示される番号順に対応する。
::    （プライマリモニターが 1 番）
::
::  倍率（SCALE）の目安:
::    100% → 96
::    125% → 120
::    150% → 144
::    175% → 168
::    200% → 192
:: ================================================================

:: --- モニター 1（プライマリ） ---
set MON1_WIDTH=1920
set MON1_HEIGHT=1080
set MON1_REFRESH=60
set MON1_SCALE=96

:: --- モニター 2（セカンダリ） ---
set MON2_WIDTH=2560
set MON2_HEIGHT=1440
set MON2_REFRESH=60
set MON2_SCALE=120

:: 接続モニター数（1 or 2）
set MONITOR_COUNT=2

:: ================================================================

echo.
echo ============================================
echo  bat_monitor - マルチモニター設定スクリプト
echo ============================================
echo.

:: --- 現在の接続モニター数を確認 ---
for /f "usebackq" %%n in (`powershell -NoProfile -Command "(Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorBasicDisplayParams | Where-Object {$_.Active -eq $true}).Count"`) do set DETECTED=%n
echo 検出されたモニター数: %DETECTED% 台

if %DETECTED% LSS 2 (
    echo.
    echo [警告] モニターが 1 台しか検出されていません。
    echo        外部モニターを接続してから再実行してください。
    echo.
    pause
    exit /b 1
)

:: --- 拡張モードへ切り替え ---
echo.
echo [1/3] 表示モードを「拡張」に切り替えています...
DisplaySwitch.exe /extend
timeout /t 2 /nobreak > nul
echo     完了

:: --- 解像度を設定（PowerShell + Win32 API） ---
echo.
echo [2/3] 解像度を設定しています...
echo     モニター 1: %MON1_WIDTH%x%MON1_HEIGHT% @%MON1_REFRESH%Hz
echo     モニター 2: %MON2_WIDTH%x%MON2_HEIGHT% @%MON2_REFRESH%Hz

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class DisplayHelper {
    [DllImport(\"user32.dll\", CharSet = CharSet.Ansi)]
    public static extern int EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE dm);

    [DllImport(\"user32.dll\", CharSet = CharSet.Ansi)]
    public static extern int ChangeDisplaySettingsEx(string deviceName, ref DEVMODE dm, IntPtr hwnd, uint dwFlags, IntPtr lParam);

    [DllImport(\"user32.dll\", CharSet = CharSet.Ansi)]
    public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public ushort dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra;
        public uint dmFields;
        public int dmPositionX, dmPositionY;
        public uint dmDisplayOrientation, dmDisplayFixedOutput;
        public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public ushort dmLogPixels;
        public uint dmBitsPerPel, dmPelsWidth, dmPelsHeight;
        public uint dmDisplayFlags, dmDisplayFrequency;
        public uint dmICMMethod, dmICMIntent, dmMediaType, dmDitherType, dmReserved1, dmReserved2, dmPanningWidth, dmPanningHeight;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DISPLAY_DEVICE {
        public uint cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
        public uint StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
    }

    public const uint DM_PELSWIDTH    = 0x00080000;
    public const uint DM_PELSHEIGHT   = 0x00100000;
    public const uint DM_DISPLAYFREQUENCY = 0x00400000;
    public const uint CDS_UPDATEREGISTRY  = 0x00000001;
    public const uint DISPLAY_DEVICE_ACTIVE = 0x00000001;

    public static string SetResolution(string deviceName, int width, int height, int refresh) {
        DEVMODE dm = new DEVMODE();
        dm.dmSize = (ushort)Marshal.SizeOf(dm);
        if (EnumDisplaySettings(deviceName, -1, ref dm) == 0)
            return \"ERR: EnumDisplaySettings failed for \" + deviceName;
        dm.dmPelsWidth       = (uint)width;
        dm.dmPelsHeight      = (uint)height;
        dm.dmDisplayFrequency = (uint)refresh;
        dm.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT | DM_DISPLAYFREQUENCY;
        int result = ChangeDisplaySettingsEx(deviceName, ref dm, IntPtr.Zero, CDS_UPDATEREGISTRY, IntPtr.Zero);
        return result == 0 ? \"OK\" : \"ERR: ChangeDisplaySettingsEx returned \" + result;
    }

    public static string[] GetActiveDeviceNames() {
        var names = new System.Collections.Generic.List<string>();
        uint i = 0;
        DISPLAY_DEVICE dd = new DISPLAY_DEVICE();
        dd.cb = (uint)Marshal.SizeOf(dd);
        while (EnumDisplayDevices(null, i, ref dd, 0)) {
            if ((dd.StateFlags & DISPLAY_DEVICE_ACTIVE) != 0)
                names.Add(dd.DeviceName);
            i++;
            dd = new DISPLAY_DEVICE();
            dd.cb = (uint)Marshal.SizeOf(dd);
        }
        return names.ToArray();
    }
}
'@
    $devices = [DisplayHelper]::GetActiveDeviceNames();
    $settings = @(
        @{ Width=%MON1_WIDTH%; Height=%MON1_HEIGHT%; Refresh=%MON1_REFRESH% },
        @{ Width=%MON2_WIDTH%; Height=%MON2_HEIGHT%; Refresh=%MON2_REFRESH% }
    );
    for ($i = 0; $i -lt [Math]::Min($devices.Count, $settings.Count); $i++) {
        $s = $settings[$i];
        $r = [DisplayHelper]::SetResolution($devices[$i], $s.Width, $s.Height, $s.Refresh);
        Write-Host ('    DISPLAY' + ($i+1) + ' (' + $devices[$i] + '): ' + $r);
    }"

echo     完了

:: --- DPI スケールをレジストリに設定 ---
echo.
echo [3/3] DPI スケールを設定しています...
echo     モニター 1: %MON1_SCALE% （倍率 %MON1_SCALE%%%）
echo     モニター 2: %MON2_SCALE% （倍率 %MON2_SCALE%%%）

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$devices = @();
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class DevEnum {
    [DllImport(\"user32.dll\", CharSet = CharSet.Ansi)]
    public static extern bool EnumDisplayDevices(string lp, uint i, ref DD dd, uint f);
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DD {
        public uint cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)]  public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string DeviceString;
        public uint StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string DeviceKey;
    }
    public const uint ACTIVE = 1;
}
'@
    $dd = New-Object DevEnum+DD; $dd.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($dd);
    $i = 0;
    while ([DevEnum]::EnumDisplayDevices($null, $i, [ref]$dd, 0)) {
        if ($dd.StateFlags -band [DevEnum]::ACTIVE) { $devices += $dd.DeviceName }
        $i++; $dd = New-Object DevEnum+DD; $dd.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($dd);
    }
    $scales = @(%MON1_SCALE%, %MON2_SCALE%);
    $regBase = 'HKCU:\Control Panel\Desktop\PerMonitorSettings';
    for ($j = 0; $j -lt [Math]::Min($devices.Count, $scales.Count); $j++) {
        $devName = $devices[$j] -replace '\\\\', '';
        $devSub  = New-Object DevEnum+DD; $devSub.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($devSub);
        [DevEnum]::EnumDisplayDevices($devices[$j], 0, [ref]$devSub, 0) | Out-Null;
        $id = $devSub.DeviceID -replace '.*\\', '' -replace '#', '_';
        $key = Join-Path $regBase $id;
        if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
        Set-ItemProperty -Path $key -Name 'DpiValue' -Value $scales[$j] -Type DWord -Force;
        Write-Host ('    DISPLAY' + ($j+1) + ': DpiValue=' + $scales[$j] + ' -> ' + $key);
    }"

echo     完了

echo.
echo ============================================
echo  設定完了
echo.
echo  [注意] DPI スケールの変更を完全に反映するには
echo         サインアウト後に再サインインしてください。
echo ============================================
echo.
pause
endlocal
