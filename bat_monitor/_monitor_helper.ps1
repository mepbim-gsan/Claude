<#
.SYNOPSIS
    Monitor helper for bat_monitor.bat. Do not run directly.
#>
param(
    [string]$SkipInternal = 'YES',
    [int]   $PrimaryMon   = 1,
    [string]$Layout       = '1-2',
    [int]   $Mon1W = 1920, [int]$Mon1H = 1080, [int]$Mon1R = 60, [int]$Mon1S = 96,
    [int]   $Mon2W = 2560, [int]$Mon2H = 1440, [int]$Mon2R = 60, [int]$Mon2S = 120,
    [int]   $MonCount = 2
)

$skipInternal = $SkipInternal -eq 'YES'
$primaryIdx   = $PrimaryMon - 1
$settings = @(
    @{ Width=$Mon1W; Height=$Mon1H; Refresh=$Mon1R; Scale=$Mon1S },
    @{ Width=$Mon2W; Height=$Mon2H; Refresh=$Mon2R; Scale=$Mon2S }
)

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class DisplayHelper {

    [DllImport("user32.dll", CharSet=CharSet.Ansi)]
    public static extern bool EnumDisplayDevices(
        string lpDevice, uint iDevNum, ref DISPLAY_DEVICE dd, uint dwFlags);

    [DllImport("user32.dll", CharSet=CharSet.Ansi)]
    public static extern int EnumDisplaySettings(
        string deviceName, int modeNum, ref DEVMODE dm);

    [DllImport("user32.dll", EntryPoint="ChangeDisplaySettingsExA")]
    public static extern int ApplyDisplaySettings(
        string deviceName, ref DEVMODE dm, IntPtr hwnd, uint flags, IntPtr lp);

    [DllImport("user32.dll", EntryPoint="ChangeDisplaySettingsExA")]
    public static extern int CommitDisplaySettings(
        string deviceName, IntPtr dm, IntPtr hwnd, uint flags, IntPtr lp);

    [DllImport("user32.dll")]
    public static extern int GetDisplayConfigBufferSizes(
        uint flags, out uint numPaths, out uint numModes);

    [DllImport("user32.dll")]
    public static extern int QueryDisplayConfig(
        uint flags, ref uint numPaths,
        [Out] DISPLAYCONFIG_PATH_INFO[] paths,
        ref uint numModes,
        [Out] DISPLAYCONFIG_MODE_INFO[] modes,
        out uint topology);

    [DllImport("user32.dll")]
    public static extern int DisplayConfigGetDeviceInfo(
        ref DISPLAYCONFIG_TARGET_DEVICE_NAME request);

    [DllImport("user32.dll")]
    public static extern int DisplayConfigGetDeviceInfo(
        ref DISPLAYCONFIG_SOURCE_DEVICE_NAME request);

    public const uint DISPLAY_DEVICE_ACTIVE = 0x00000001;
    public const uint QDC_ONLY_ACTIVE_PATHS = 0x00000002;
    public const uint DCDI_GET_SOURCE_NAME  = 1;
    public const uint DCDI_GET_TARGET_NAME  = 2;
    public const uint OUTPUT_TECH_INTERNAL  = 0x80000000;
    public const uint OUTPUT_TECH_DP_EMBED  = 11;
    public const uint DM_POSITION      = 0x00000020;
    public const uint DM_PELSWIDTH     = 0x00080000;
    public const uint DM_PELSHEIGHT    = 0x00100000;
    public const uint DM_FREQ          = 0x00400000;
    public const uint CDS_UPDATEREG    = 0x00000001;
    public const uint CDS_NORESET      = 0x10000000;
    public const uint CDS_SET_PRIMARY  = 0x00000010;

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)]
    public struct DISPLAY_DEVICE {
        public uint cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)]  public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string DeviceString;
        public uint StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string DeviceKey;
    }

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmDeviceName;
        public ushort dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra;
        public uint   dmFields;
        public int    dmPositionX, dmPositionY;
        public uint   dmDisplayOrientation, dmDisplayFixedOutput;
        public short  dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmFormName;
        public ushort dmLogPixels;
        public uint   dmBitsPerPel, dmPelsWidth, dmPelsHeight;
        public uint   dmDisplayFlags, dmDisplayFrequency;
        public uint   dmICMMethod, dmICMIntent, dmMediaType, dmDitherType;
        public uint   dmReserved1, dmReserved2, dmPanningWidth, dmPanningHeight;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct LUID { public uint LowPart; public int HighPart; }

    [StructLayout(LayoutKind.Sequential)]
    public struct DISPLAYCONFIG_RATIONAL { public uint Numerator; public uint Denominator; }

    [StructLayout(LayoutKind.Sequential)]
    public struct DISPLAYCONFIG_PATH_SOURCE_INFO {
        public LUID adapterId; public uint id; public uint modeInfoIdx; public uint statusFlags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DISPLAYCONFIG_PATH_TARGET_INFO {
        public LUID   adapterId;
        public uint   id, modeInfoIdx, outputTechnology, rotation, scaling;
        public DISPLAYCONFIG_RATIONAL refreshRate;
        public uint   scanLineOrdering;
        [MarshalAs(UnmanagedType.Bool)] public bool targetAvailable;
        public uint   statusFlags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DISPLAYCONFIG_PATH_INFO {
        public DISPLAYCONFIG_PATH_SOURCE_INFO sourceInfo;
        public DISPLAYCONFIG_PATH_TARGET_INFO targetInfo;
        public uint flags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DISPLAYCONFIG_2DREGION { public uint cx; public uint cy; }

    [StructLayout(LayoutKind.Sequential)]
    public struct DISPLAYCONFIG_VIDEO_SIGNAL_INFO {
        public ulong pixelRate;
        public DISPLAYCONFIG_RATIONAL hSyncFreq, vSyncFreq;
        public DISPLAYCONFIG_2DREGION activeSize, totalSize;
        public uint videoStandard, scanLineOrdering;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DISPLAYCONFIG_TARGET_MODE {
        public DISPLAYCONFIG_VIDEO_SIGNAL_INFO targetVideoSignalInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINTL { public int x; public int y; }

    [StructLayout(LayoutKind.Sequential)]
    public struct DISPLAYCONFIG_SOURCE_MODE {
        public uint width, height, pixelFormat;
        public POINTL position;
    }

    [StructLayout(LayoutKind.Explicit, Size=48)]
    public struct DISPLAYCONFIG_MODE_INFO_UNION {
        [FieldOffset(0)] public DISPLAYCONFIG_TARGET_MODE targetMode;
        [FieldOffset(0)] public DISPLAYCONFIG_SOURCE_MODE sourceMode;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DISPLAYCONFIG_MODE_INFO {
        public uint infoType, id;
        public LUID adapterId;
        public DISPLAYCONFIG_MODE_INFO_UNION modeInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DISPLAYCONFIG_DEVICE_INFO_HEADER {
        public uint type, size;
        public LUID adapterId;
        public uint id;
    }

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct DISPLAYCONFIG_TARGET_DEVICE_NAME {
        public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
        public uint   flags, outputTechnology;
        public ushort edidManufactureId, edidProductCodeId;
        public uint   connectorInstance;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=64)]  public string monitorFriendlyDeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string monitorDevicePath;
    }

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct DISPLAYCONFIG_SOURCE_DEVICE_NAME {
        public DISPLAYCONFIG_DEVICE_INFO_HEADER header;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string viewGdiDeviceName;
    }

    public static string[] GetActiveDeviceNames() {
        var names = new List<string>();
        uint i = 0;
        var dd = new DISPLAY_DEVICE();
        dd.cb = (uint)Marshal.SizeOf(dd);
        while (EnumDisplayDevices(null, i, ref dd, 0)) {
            if ((dd.StateFlags & DISPLAY_DEVICE_ACTIVE) != 0)
                names.Add(dd.DeviceName.TrimEnd());
            i++;
            dd = new DISPLAY_DEVICE();
            dd.cb = (uint)Marshal.SizeOf(dd);
        }
        return names.ToArray();
    }

    public static HashSet<string> GetInternalGdiNames() {
        var result = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        uint numPaths = 0, numModes = 0;
        if (GetDisplayConfigBufferSizes(QDC_ONLY_ACTIVE_PATHS, out numPaths, out numModes) != 0)
            return result;
        var paths = new DISPLAYCONFIG_PATH_INFO[numPaths];
        var modes = new DISPLAYCONFIG_MODE_INFO[numModes];
        uint topology = 0;
        if (QueryDisplayConfig(QDC_ONLY_ACTIVE_PATHS, ref numPaths, paths, ref numModes, modes, out topology) != 0)
            return result;
        foreach (var path in paths) {
            var tn = new DISPLAYCONFIG_TARGET_DEVICE_NAME();
            tn.header.type      = DCDI_GET_TARGET_NAME;
            tn.header.size      = (uint)Marshal.SizeOf(tn);
            tn.header.adapterId = path.targetInfo.adapterId;
            tn.header.id        = path.targetInfo.id;
            if (DisplayConfigGetDeviceInfo(ref tn) != 0) continue;
            bool isInternal = (tn.outputTechnology == OUTPUT_TECH_INTERNAL)
                           || (tn.outputTechnology == OUTPUT_TECH_DP_EMBED);
            if (!isInternal) continue;
            var sn = new DISPLAYCONFIG_SOURCE_DEVICE_NAME();
            sn.header.type      = DCDI_GET_SOURCE_NAME;
            sn.header.size      = (uint)Marshal.SizeOf(sn);
            sn.header.adapterId = path.sourceInfo.adapterId;
            sn.header.id        = path.sourceInfo.id;
            if (DisplayConfigGetDeviceInfo(ref sn) != 0) continue;
            result.Add(sn.viewGdiDeviceName.TrimEnd());
        }
        return result;
    }

    public static string ApplySettings(
            string deviceName, int x, int y, int w, int h, int refresh, bool isPrimary) {
        var dm = new DEVMODE();
        dm.dmSize = (ushort)Marshal.SizeOf(dm);
        if (EnumDisplaySettings(deviceName, -1, ref dm) == 0)
            return "ERR: EnumDisplaySettings failed";
        dm.dmPositionX        = x;
        dm.dmPositionY        = y;
        dm.dmPelsWidth        = (uint)w;
        dm.dmPelsHeight       = (uint)h;
        dm.dmDisplayFrequency = (uint)refresh;
        dm.dmFields = DM_POSITION | DM_PELSWIDTH | DM_PELSHEIGHT | DM_FREQ;
        uint flags = CDS_UPDATEREG | CDS_NORESET;
        if (isPrimary) flags |= CDS_SET_PRIMARY;
        int r = ApplyDisplaySettings(deviceName, ref dm, IntPtr.Zero, flags, IntPtr.Zero);
        return r == 0 ? "OK" : ("ERR:" + r);
    }

    public static void Commit() {
        CommitDisplaySettings(null, IntPtr.Zero, IntPtr.Zero, 0, IntPtr.Zero);
    }
}
'@

# Helper: get external device list
function Get-ExternalDevices {
    $all      = [DisplayHelper]::GetActiveDeviceNames()
    $internal = [DisplayHelper]::GetInternalGdiNames()
    if ($skipInternal) {
        return @($all | Where-Object { -not $internal.Contains($_) })
    } else {
        return @($all)
    }
}

# 1. Wait until expected number of external monitors are active (max 20 sec)
Write-Host "  Waiting for $MonCount external monitor(s)..."
$maxWait = 20
$waited  = 0
$extDevices = @()
while ($true) {
    $extDevices = Get-ExternalDevices
    if ($extDevices.Count -ge $MonCount) { break }
    if ($waited -ge $maxWait) {
        Write-Host "  WARNING: Timeout. Expected $MonCount, found $($extDevices.Count) external monitor(s)."
        if ($extDevices.Count -eq 0) { exit 1 }
        break
    }
    Write-Host "  Found $($extDevices.Count)/$MonCount - retrying in 1s... ($waited/$maxWait)"
    Start-Sleep -Seconds 1
    $waited++
}
Write-Host "  Detected $($extDevices.Count) external monitor(s):"
foreach ($d in $extDevices) { Write-Host "    $d" }

# 2. Calculate positions
#    LAYOUT=1-2: MON1=left(x=0), MON2=right(x=MON1.Width)
#    LAYOUT=2-1: MON2=left(x=0), MON1=right(x=MON2.Width)
if ($Layout -eq '1-2') {
    $positions = @(
        @{ X = 0;                  Y = 0 },
        @{ X = $settings[0].Width; Y = 0 }
    )
} else {
    $positions = @(
        @{ X = $settings[1].Width; Y = 0 },
        @{ X = 0;                  Y = 0 }
    )
}

# 3. Apply resolution, position, primary
Write-Host "  Applying settings..."
$applyCount = [Math]::Min($extDevices.Count, $MonCount)
for ($i = 0; $i -lt $applyCount; $i++) {
    $s   = $settings[$i]
    $p   = $positions[$i]
    $pri = ($i -eq $primaryIdx)
    $tag = if ($pri) { '[PRIMARY]' } else { '         ' }
    $r   = [DisplayHelper]::ApplySettings(
               $extDevices[$i], $p.X, $p.Y, $s.Width, $s.Height, $s.Refresh, $pri)
    Write-Host "    MON$($i+1) $tag $($extDevices[$i]) : $($s.Width)x$($s.Height) @$($s.Refresh)Hz pos=($($p.X),$($p.Y)) -> $r"
}
[DisplayHelper]::Commit()
Write-Host "  Display settings committed"

# 4. DPI scale via registry
Write-Host "  Writing DPI scale to registry..."
$regBase = 'HKCU:\Control Panel\Desktop\PerMonitorSettings'
for ($j = 0; $j -lt $applyCount; $j++) {
    $dd = New-Object DisplayHelper+DISPLAY_DEVICE
    $dd.cb = [Runtime.InteropServices.Marshal]::SizeOf($dd)
    [DisplayHelper]::EnumDisplayDevices($extDevices[$j], 0, [ref]$dd, 0) | Out-Null
    $monId = $dd.DeviceID -replace '.*\\', '' -replace '#', '_'
    if (-not $monId) {
        Write-Host "    MON$($j+1): DeviceID not found, DPI skipped"
        continue
    }
    $key = Join-Path $regBase $monId
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    Set-ItemProperty -Path $key -Name 'DpiValue' -Value $settings[$j].Scale -Type DWord -Force
    Write-Host "    MON$($j+1): DpiValue=$($settings[$j].Scale) -> $key"
}
Write-Host "  DPI settings written (sign out required to apply)"
