@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
set "EB_SELF=%~f0"
title EB_Optimizer v13.5

rem ===========================================================================
rem  EB_Optimizer v13.5 - Einzeldatei-Start (Batch + PowerShell)
rem
rem  Diese Datei enthaelt das komplette PowerShell-Programm im unteren Teil.
rem  Der Code wird eingelesen und per Invoke-Expression ausgefuehrt - dadurch
rem  greift KEINE ExecutionPolicy (AllSigned / Restricted spielen keine Rolle,
rem  es wird keine .ps1-Datei geladen) und es ist keine Signatur noetig.
rem
rem  Start:       einfach doppelklicken.
rem  Bearbeiten:  alles ab der Markierungszeile ganz unten ist reines
rem               PowerShell - mit UTF-8 speichern, BOM ist egal/unnoetig.
rem ===========================================================================

rem --- Farbunterstuetzung: ANSI gibt es erst ab Windows 10 Build 10586. ---
rem --- Auf aelteren Konsolen bleiben die Variablen leer, damit dort keine ---
rem --- Steuerzeichen als Buchstabensalat erscheinen.                      ---
set "ESC="
set "EB_BUILD="
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2^>nul') do set "EB_BUILD=%%v"
if defined EB_BUILD for /f "delims=0123456789" %%x in ("%EB_BUILD%") do set "EB_BUILD="
if defined EB_BUILD if %EB_BUILD% GEQ 10586 for /f %%e in ('echo prompt $E^| cmd') do set "ESC=%%e"

set "CR="
set "CT="
set "CD="
set "CG="
set "CY="
set "CX="
if defined ESC set "CR=%ESC%[0m"
if defined ESC set "CT=%ESC%[1;96m"
if defined ESC set "CD=%ESC%[90m"
if defined ESC set "CG=%ESC%[92m"
if defined ESC set "CY=%ESC%[93m"
if defined ESC set "CX=%ESC%[91m"

call :BANNER
echo   %CD%[1/3]%CR% Berechtigungen werden geprueft ...

net session >nul 2>&1
if not errorlevel 1 goto :RUN

:ELEVATE
echo   %CY%[!]%CR%   Administratorrechte erforderlich - Abfrage wird geoeffnet ...
echo.
powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -Verb RunAs -ArgumentList ('/c call ' + [char]34 + $env:EB_SELF + [char]34)" 2>nul
if not errorlevel 1 exit /b 0
echo   %CX%[X]%CR%   Die Rechteerhoehung wurde abgebrochen.
echo         Das Programm aendert Systemeinstellungen und laeuft nur als Administrator.
echo.
choice /c WB /n /m "   [W] Erneut versuchen    [B] Beenden  :  "
if errorlevel 2 goto :END
echo.
goto :ELEVATE

:RUN
echo   %CG%[OK]%CR%  Administratorrechte vorhanden.
echo   %CD%[2/3]%CR% Windows PowerShell wird gesucht ...
where powershell.exe >nul 2>&1
if not errorlevel 1 goto :RUNPS
echo   %CX%[X]%CR%   powershell.exe wurde nicht gefunden.
echo         Bitte Windows PowerShell 5.1 nachinstallieren oder den Pfad pruefen.
echo.
pause
goto :END

:RUNPS
echo   %CG%[OK]%CR%  Windows PowerShell gefunden.
echo   %CD%[3/3]%CR% Oberflaeche wird geladen - das dauert einen Moment ...
echo.
title EB_Optimizer v13.5 - wird gestartet ...
powershell -NoProfile -STA -Command "$ErrorActionPreference='Stop'; try { $raw=[IO.File]::ReadAllText($env:EB_SELF,[Text.Encoding]::UTF8); $m=[char]10 + '#__EB_PAYLOAD' + '__'; $i=$raw.LastIndexOf($m); if($i -lt 0){ throw 'Payload-Markierung nicht gefunden - Datei beschaedigt.' }; $code=$raw.Substring($raw.IndexOf([char]10,$i+1)+1); Invoke-Expression $code } catch { Write-Host ''; Write-Host ('[X] ' + $_.Exception.Message) -ForegroundColor Red; if($_.InvocationInfo){ Write-Host $_.InvocationInfo.PositionMessage -ForegroundColor DarkGray }; Write-Host ''; Read-Host 'ENTER zum Schliessen' }"
set "EB_RC=%ERRORLEVEL%"
title EB_Optimizer v13.5
if "%EB_RC%"=="0" goto :END

echo.
echo   %CX%[X]%CR%   Das Programm wurde mit Fehlercode %EB_RC% beendet.
echo.
choice /c WB /n /m "   [W] Neu starten    [B] Beenden  :  "
if errorlevel 2 goto :END
cls
call :BANNER
goto :RUNPS

:BANNER
cls
echo.
echo   %CT%================================================================%CR%
echo   %CT%        E B _ O P T I M I Z E R        v 1 3 . 5%CR%
echo   %CD%             Windows Performance Suite%CR%
echo   %CT%================================================================%CR%
echo.
goto :eof

:END
endlocal
exit /b 0

#__EB_PAYLOAD__
<#
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    ███████╗██████╗         ███████╗██╗  ██╗ █████╗ ██████╗                   ║
║    ██╔════╝██╔══██╗        ██╔════╝██║  ██║██╔══██╗██╔══██╗                  ║
║    █████╗  ██████╔╝        █████╗  ███████║███████║██████╔╝                  ║
║    ██╔══╝  ██╔══██╗        ██╔══╝  ██╔══██║██╔══██║██╔══██╗                  ║
║    ███████╗██████╔╝███████╗███████╗██║  ██║██║  ██║██████╔╝                  ║
║    ╚══════╝╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝                   ║
║                                                                              ║
║                      EB_Optimizer  v13.5                                     ║
║                       (repaired / hardened build)                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
#>

#requires -Version 5.1

#region 0. BOOTSTRAP, ADMIN CHECK, ASSEMBLIES, NATIVE

Set-StrictMode -Off
$ErrorActionPreference = 'Continue'

# ---- Admin check / self elevation -------------------------------------------
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$script:IsAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $script:IsAdmin) {
    # Der Starter (.cmd) erhoeht die Rechte normalerweise selbst - hierher
    # kommt man nur, wenn diese Pruefung uebersprungen wurde. Dann wird die
    # .cmd erneut aufgerufen, NICHT powershell -File: Auf Rechnern mit
    # AllSigned waere ein Neustart per -File ohne Signatur wirkungslos, und
    # -ExecutionPolicy Bypass soll bewusst nirgends vorkommen.
    # $PSCommandPath ist leer, weil die Nutzlast per Invoke-Expression laeuft;
    # der Starter hinterlegt den eigenen Pfad deshalb in EB_SELF.
    $selfPath = $env:EB_SELF
    if (-not $selfPath -and $PSCommandPath) { $selfPath = $PSCommandPath }
    if ($selfPath -and (Test-Path -LiteralPath $selfPath)) {
        try {
            # cmd /c "pfad mit leerzeichen" verschluckt die Anfuehrungszeichen -
            # 'call "pfad"' als EIN Argument ist die zuverlaessige Schreibweise.
            Start-Process -FilePath $env:ComSpec -Verb RunAs `
                -ArgumentList "/c call `"$selfPath`"" | Out-Null
            exit 0
        }
        catch {
            Write-Host "Elevation was cancelled or failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host "Dieses Skript muss als Administrator ausgefuehrt werden." -ForegroundColor Red
    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    [void](Read-Host "ENTER")
    exit 1
}

# ---- Assemblies --------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# DPI awareness (must run before any window is created)
if ([Environment]::OSVersion.Version.Major -ge 6) {
    try {
        if (-not ('Win32.Win32Dpi' -as [type])) {
            $dpiCode = '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();'
            Add-Type -MemberDefinition $dpiCode -Name 'Win32Dpi' -Namespace 'Win32' | Out-Null
        }
        [Win32.Win32Dpi]::SetProcessDPIAware() | Out-Null
    }
    catch { }
}

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# Console encoding only makes sense in a real console host
try {
    if ($Host.Name -eq 'ConsoleHost') { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 }
}
catch { }

# ---- Native acrylic / dark title bar ----------------------------------------
if (-not ('EBHost.Native' -as [type])) {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    namespace EBHost {
        [StructLayout(LayoutKind.Sequential)]
        public struct WindowCompositionAttributeData {
            public int Attribute;
            public IntPtr Data;
            public int SizeOfData;
        }
        [StructLayout(LayoutKind.Sequential)]
        public struct AccentPolicy {
            public int AccentState;
            public int AccentFlags;
            public int GradientColor;
            public int AnimationId;
        }
        public static class Native {
            [DllImport("user32.dll")]
            public static extern int SetWindowCompositionAttribute(IntPtr hwnd, ref WindowCompositionAttributeData data);
            [DllImport("dwmapi.dll")]
            public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
            [DllImport("user32.dll", CharSet = CharSet.Auto)]
            public static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);
            [DllImport("user32.dll", CharSet = CharSet.Unicode)]
            public static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, string lParam);
            [DllImport("user32.dll")]
            public static extern bool ReleaseCapture();
            [DllImport("user32.dll", CharSet = CharSet.Unicode)]
            public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
            [DllImport("user32.dll")]
            public static extern bool SetForegroundWindow(IntPtr hWnd);
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
            [DllImport("user32.dll")]
            public static extern bool IsIconic(IntPtr hWnd);
            [DllImport("uxtheme.dll", CharSet = CharSet.Unicode)]
            public static extern int SetWindowTheme(IntPtr hWnd, string pszSubAppName, string pszSubIdList);
            [DllImport("uxtheme.dll", EntryPoint = "#135", CharSet = CharSet.Unicode)]
            public static extern int SetPreferredAppMode(int appMode);
            [DllImport("user32.dll")]
            public static extern bool DestroyIcon(IntPtr handle);
        }
    }
"@
}

function Enable-EBAcrylic {
    param([System.Windows.Forms.Form]$Form)

    if (-not $Form -or $Form.IsDisposed -or -not $Form.IsHandleCreated) { return }

    $accentPtr = [IntPtr]::Zero
    try {
        $accent = New-Object EBHost.AccentPolicy
        $accent.AccentState = 4                 # ACCENT_ENABLE_ACRYLICBLURBEHIND
        $accent.GradientColor = 0x0111151C      # ABGR dark tint

        $accentSize = [System.Runtime.InteropServices.Marshal]::SizeOf($accent)
        $accentPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($accentSize)
        [System.Runtime.InteropServices.Marshal]::StructureToPtr($accent, $accentPtr, $false)

        $data = New-Object EBHost.WindowCompositionAttributeData
        $data.Attribute = 19                    # WCA_ACCENT_POLICY
        $data.SizeOfData = $accentSize
        $data.Data = $accentPtr

        [EBHost.Native]::SetWindowCompositionAttribute($Form.Handle, [ref]$data) | Out-Null

        $trueVal = 1
        # 20 = DWMWA_USE_IMMERSIVE_DARK_MODE (newer builds), 19 = older builds
        [EBHost.Native]::DwmSetWindowAttribute($Form.Handle, 20, [ref]$trueVal, 4) | Out-Null
        [EBHost.Native]::DwmSetWindowAttribute($Form.Handle, 19, [ref]$trueVal, 4) | Out-Null
    }
    catch { }
    finally {
        if ($accentPtr -ne [IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($accentPtr)
        }
    }
}

# ---- Mouse wheel: scroll the control under the cursor, not the focused one --
if (-not ('EBHost.WheelFilter' -as [type])) {
    try {
        Add-Type -ReferencedAssemblies 'System.Windows.Forms', 'System.Drawing' -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        using System.Windows.Forms;
        namespace EBHost {
            public class WheelFilter : IMessageFilter {
                [DllImport("user32.dll")]
                private static extern IntPtr WindowFromPoint(System.Drawing.Point pt);
                [DllImport("user32.dll")]
                private static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wp, IntPtr lp);

                private static bool CanScroll(Control c) {
                    if (c == null) return false;
                    if (c is ListView || c is ListBox || c is TreeView ||
                        c is TextBoxBase || c is ComboBox) return true;
                    ScrollableControl s = c as ScrollableControl;
                    return (s != null && s.AutoScroll && s.VerticalScroll.Visible);
                }

                public bool PreFilterMessage(ref Message m) {
                    if (m.Msg == 0x020A) {                       // WM_MOUSEWHEEL
                        IntPtr h = WindowFromPoint(Cursor.Position);
                        if (h == IntPtr.Zero) return false;
                        Control c = Control.FromHandle(h);
                        if (c == null) return false;

                        // The cursor usually sits on a button or a label - those
                        // cannot scroll, so walk up to the panel that can (the
                        // sidebar and the card area used to ignore the wheel).
                        Control t = c;
                        while (t != null && !CanScroll(t)) t = t.Parent;
                        if (t == null) return false;

                        if (t.Handle != m.HWnd) {
                            SendMessage(t.Handle, m.Msg, m.WParam, m.LParam);
                            return true;
                        }
                    }
                    return false;
                }
            }
        }
"@
    }
    catch { }
}

# ---- Fast performance counters (WMI is far too slow for a 1s timer) --------
if (-not ('EBHost.Perf' -as [type])) {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    namespace EBHost {
        [StructLayout(LayoutKind.Sequential)]
        public class MEMORYSTATUSEX {
            public uint  dwLength;
            public uint  dwMemoryLoad;
            public ulong ullTotalPhys;
            public ulong ullAvailPhys;
            public ulong ullTotalPageFile;
            public ulong ullAvailPageFile;
            public ulong ullTotalVirtual;
            public ulong ullAvailVirtual;
            public ulong ullAvailExtendedVirtual;
            public MEMORYSTATUSEX() { this.dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX)); }
        }
        public static class Perf {
            [DllImport("kernel32.dll", SetLastError = true)]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX lpBuffer);

            [DllImport("kernel32.dll", SetLastError = true)]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool GetSystemTimes(out long idleTime, out long kernelTime, out long userTime);
        }
    }
"@
}

#endregion 0. BOOTSTRAP


#region 1. CONFIGURATION, THEME, TYPOGRAPHY

# Resolve script root safely (empty when pasted into a host)
$script:AppRoot = if ($PSScriptRoot) { $PSScriptRoot }
elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath }
else { (Get-Location).Path }

$script:Config = [ordered]@{
    AppName       = 'EB_Optimizer'
    Version       = '13.5'
    BackupDir     = Join-Path $env:USERPROFILE 'Documents\EB_Optimizer_Backups'
    CurrentLang   = 'DE'
    CurrentView   = 'Dashboard'
    HardwareCache = $null
    LogoPath      = Join-Path $script:AppRoot 'EB_Logo.png'
    TimerInterval = 1000
    EnableLogging = $true
    MaxLogLines   = 500
    EnableNotify  = $true
    CrashRecovery = $true
    SettingsPath  = Join-Path $env:APPDATA 'EB_Optimizer\settings.json'
    RememberWin   = $true
    MinimizeToTray = $false
    LogCollapsed  = $false
    ProcAutoRefresh = $false
    ShowWindowsTasks = $false
    CleanConfirm  = $true
    BackupKeepDays = 60
    BackupMaxMB   = 512
    BackupMinKeep = 10
    RestoreView   = $false
    LastView      = 'Dashboard'
    LastBench     = $null
    WinBounds     = $null
    WinMaximized  = $false
}

if (-not (Test-Path -LiteralPath $script:Config.BackupDir)) {
    try { New-Item -Path $script:Config.BackupDir -ItemType Directory -Force | Out-Null } catch { }
}

# ---- Live state (MUST exist before the timer or any view touches it) --------
$script:CurrentStats = @{
    CPU    = 0
    RAM    = 0
    Disk   = 0
    Net    = 0.0
    Health = 100
    Time   = Get-Date
}

$script:SparklineHistory = @{
    CPU        = [System.Collections.Generic.List[single]]::new()
    RAM        = [System.Collections.Generic.List[single]]::new()
    NET        = [System.Collections.Generic.List[single]]::new()
    BufferSize = 40
}

$script:CachedHealthScore = 100
$script:HealthFactors = @()
$script:HardwareModel = $null
$script:DefenderHealth = $null
$script:DefenderHealthTime = $null
$script:RestoreAge = $null
$script:RestoreAgeTime = $null
$script:StartupCountCache = 0
$script:StartupCountTime = $null
$script:LastHealthCheck = Get-Date
$script:NetLastBytes = $null
$script:NetLastTime = $null
$script:txtLog = $null
$script:btnMinimize = $null
$script:btnLogClear = $null
$script:txtLogSearch = $null
$script:ProcTimer = $null
$script:RebootHint = $false
$script:lblLogMatch = $null
$script:LogTabsFloor = 200
$script:RebootState = $null
$script:RebootStateTime = $null
$script:RebootWarned = $false
$script:ProcRowKeys = @()
$script:btnProcAuto = $null
$script:LogSearch = ''
$script:LogSearchTimer = $null
$script:LogMatchInfo = ''
$script:btnLogToggle = $null
$script:btnRun = $null
$script:WindowsRelease = $null
$script:lblPrompt = $null
$script:LogPanel = $null
$script:LogPanelHeight = 158
$script:LogLineCount = 0

# Fonts that are reused all over the UI - created once, disposed on exit
$script:Fonts = @{}
$script:RegionCache = @{}
function Get-AppFont {
    # NOTE: the returned Font is shared and owned by the cache.
    # Callers must NEVER dispose it - it is released in Stop-AppFonts.
    param([string]$Family = 'Segoe UI', [single]$Size = 10, [string]$Style = 'Regular')
    $key = "$Family|$Size|$Style"

    # Guard against a disposed entry (a caller that disposed what it borrowed):
    # touching a property of a disposed Font throws, so rebuild it instead of
    # handing out a dead object.
    if ($script:Fonts.ContainsKey($key)) {
        try { [void]$script:Fonts[$key].GetHeight() }
        catch { [void]$script:Fonts.Remove($key) }
    }

    if (-not $script:Fonts.ContainsKey($key)) {
        try {
            $script:Fonts[$key] = New-Object System.Drawing.Font($Family, $Size, [System.Drawing.FontStyle]::$Style)
        }
        catch {
            $script:Fonts[$key] = New-Object System.Drawing.Font('Segoe UI', $Size)
        }
    }
    return $script:Fonts[$key]
}

# ---- Farbpalette -------------------------------------------------------------
# Eine einzige Quelle fuer das Blau der Anwendung. Jede Flaeche, jede Linie und
# jede Schriftfarbe ist eine Mischung aus diesen Werten - so bleibt kein
# Grauton uebrig, der sich dem Rest widersetzt.
$script:Palette = [ordered]@{
    Light = '#5D9CD6'   # hell    - Akzent, aktive Elemente, Verlaufsbeginn
    Mid   = '#3778B5'   # mittel  - gedrueckte Knoepfe, Verlaufsmitte
    Deep  = '#1D5188'   # tief    - Verlaufsende
    Navy  = '#2A4A7B'   # navy    - aktiver Menuepunkt, Linien
    Dark  = '#1F3A61'   # sehr dunkel - Karten
    Base  = '#14263F'   # fast schwarzblau - Grundflaeche
    Black = '#000000'
    White = '#FFFFFF'
}

function ConvertFrom-HexColor {
    param([string]$Hex)
    $h = ([string]$Hex).TrimStart('#')
    if ($h.Length -ne 6) { return [System.Drawing.Color]::Black }
    return [System.Drawing.Color]::FromArgb(
        [Convert]::ToInt32($h.Substring(0, 2), 16),
        [Convert]::ToInt32($h.Substring(2, 2), 16),
        [Convert]::ToInt32($h.Substring(4, 2), 16))
}

function ConvertTo-HexColor {
    param($Color)
    if (-not $Color) { return '#000000' }
    return ('#{0:X2}{1:X2}{2:X2}' -f [int]$Color.R, [int]$Color.G, [int]$Color.B)
}

function Get-PaletteColor {
    # Mischt zwei Palettenwerte. Ratio 0 = ganz A, 1 = ganz B.
    param(
        [string]$Name,
        [string]$Toward = '',
        [double]$Ratio = 0.0,
        [int]$Alpha = 255
    )
    $a = ConvertFrom-HexColor -Hex ([string]$script:Palette[$Name])
    if (-not $Toward) {
        if ($Alpha -ge 255) { return $a }
        return [System.Drawing.Color]::FromArgb($Alpha, $a.R, $a.G, $a.B)
    }
    $b = ConvertFrom-HexColor -Hex ([string]$script:Palette[$Toward])
    if ($Ratio -lt 0) { $Ratio = 0 }
    if ($Ratio -gt 1) { $Ratio = 1 }
    $r = [int][math]::Round($a.R + (($b.R - $a.R) * $Ratio))
    $g = [int][math]::Round($a.G + (($b.G - $a.G) * $Ratio))
    $bl = [int][math]::Round($a.B + (($b.B - $a.B) * $Ratio))
    return [System.Drawing.Color]::FromArgb($Alpha, $r, $g, $bl)
}

# ---- Theme -------------------------------------------------------------------
$script:Theme = [ordered]@{
    # Flaechenstufen von der dunkelsten zur hellsten - alle auf der Linie
    # Base -> Dark -> Navy, damit der Verlauf ueber das ganze Fenster stimmt.
    BgPrimary     = (Get-PaletteColor -Name 'Base')
    BgSecondary   = (Get-PaletteColor -Name 'Base' -Toward 'Dark' -Ratio 0.70)
    BgTertiary    = (Get-PaletteColor -Name 'Navy')
    BgCard        = (Get-PaletteColor -Name 'Dark')
    BgCardHover   = (Get-PaletteColor -Name 'Dark' -Toward 'Navy' -Ratio 0.55)
    BgInput       = (Get-PaletteColor -Name 'Base' -Toward 'Dark' -Ratio 0.55)
    BgHeader      = (Get-PaletteColor -Name 'Base' -Toward 'Dark' -Ratio 0.35)
    BgSidebar     = (Get-PaletteColor -Name 'Base' -Toward 'Dark' -Ratio 0.35)
    BgLog         = (Get-PaletteColor -Name 'Base' -Toward 'Black' -Ratio 0.25)

    Accent        = (Get-PaletteColor -Name 'Light')
    AccentLight   = (Get-PaletteColor -Name 'Light' -Toward 'White' -Ratio 0.32)
    AccentDark    = (Get-PaletteColor -Name 'Mid')

    # Meldefarben bleiben eigenstaendig: Gruen, Gelb und Rot muessen sich vom
    # Blau abheben, sonst ist eine Warnung im Protokoll nicht mehr zu erkennen.
    Success       = [System.Drawing.Color]::FromArgb(52, 199, 123)
    Warning       = [System.Drawing.Color]::FromArgb(250, 184, 60)
    Error         = [System.Drawing.Color]::FromArgb(255, 99, 99)
    Info          = (Get-PaletteColor -Name 'Light')

    Cyan          = [System.Drawing.Color]::FromArgb(79, 190, 221)
    Purple        = [System.Drawing.Color]::FromArgb(150, 150, 240)
    Orange        = [System.Drawing.Color]::FromArgb(245, 158, 86)
    Teal          = [System.Drawing.Color]::FromArgb(64, 186, 196)
    Pink          = [System.Drawing.Color]::FromArgb(226, 124, 186)

    # Schrift: aufgehellte Palettenfarbe statt Grau - sonst wirkt der Text
    # neben dem Blau immer leicht schmutzig.
    TextPrimary   = (Get-PaletteColor -Name 'Light' -Toward 'White' -Ratio 0.86)
    TextSecondary = (Get-PaletteColor -Name 'Light' -Toward 'White' -Ratio 0.40)
    TextMuted     = (Get-PaletteColor -Name 'Light' -Toward 'White' -Ratio 0.16)
    TextWhite     = [System.Drawing.Color]::White

    SidebarActive = (Get-PaletteColor -Name 'Navy')
    SidebarHover  = (Get-PaletteColor -Name 'Base' -Toward 'Navy' -Ratio 0.45)

    Border        = (Get-PaletteColor -Name 'Navy' -Toward 'Mid' -Ratio 0.25)
    NeonGlow      = (Get-PaletteColor -Name 'Light' -Alpha 150)
    Shadow        = [System.Drawing.Color]::FromArgb(30, 0, 0, 0)
    Divider       = (Get-PaletteColor -Name 'Base' -Toward 'Navy' -Ratio 0.40)

    GlassBg       = (Get-PaletteColor -Name 'Dark' -Alpha 70)
    GlassLight    = (Get-PaletteColor -Name 'Navy' -Alpha 90)
}

$script:Spacing = [ordered]@{ xs = 2; sm = 4; md = 8; lg = 12; xl = 16; xxl = 24 }

# Pick a monospace font that actually exists on the machine
function Get-MonoFontName {
    $installed = (New-Object System.Drawing.Text.InstalledFontCollection).Families | Select-Object -ExpandProperty Name
    foreach ($candidate in @('Cascadia Code', 'Cascadia Mono', 'Consolas', 'Courier New')) {
        if ($installed -contains $candidate) { return $candidate }
    }
    return 'Courier New'
}
$script:MonoFont = Get-MonoFontName

#region 1b. VECTOR ICONS (SVG path data -> GDI+)

# The UI used emoji glyphs, which look different on every Windows build, cannot
# be coloured and render blurry at small sizes. Icons are now vectors: each one
# is SVG-style geometry on a 24x24 grid, stroked in the colour of the control
# it belongs to and cached as a bitmap per size/colour.
#
# Shape syntax (one icon = one or more shapes):
#   P <svg path data>   path, supports M L H V C Q Z (absolute and relative)
#   L x1 y1 x2 y2       line
#   R x y w h [r]       rectangle, optionally rounded
#   C cx cy r           circle (stroked)
#   D cx cy r           dot (filled circle)

$script:IconCache = @{}

$script:IconShapes = @{
    'tray'       = @('P M4 13.5 L4 19.5 L20 19.5 L20 13.5', 'L 12 3.5 12 14', 'P M7.8 10 L12 14.2 L16.2 10')
    'flag'       = @('L 5.5 3.2 5.5 20.8', 'P M5.5 4.6 L18.6 4.6 L15.4 9 L18.6 13.4 L5.5 13.4 Z')
    'home'       = @('P M3 11.5 L12 4 L21 11.5', 'P M5.5 10 L5.5 20 L18.5 20 L18.5 10', 'R 10 14 4 6')
    'monitor'    = @('R 3 4 18 12 2', 'L 9 20 15 20', 'L 12 16 12 20')
    'chart'      = @('P M3 17 L9 11 L13 15 L20 6', 'P M15 6 L20 6 L20 11')
    'bars'       = @('R 4 12 4 8 1', 'R 10 7 4 13 1', 'R 16 3 4 17 1')
    'save'       = @('R 3 3 18 18 2', 'R 7.5 3 9 6 1', 'R 7 13 10 8 1')
    'disc'       = @('C 12 12 8.5', 'C 12 12 2.4')
    'gamepad'    = @('R 2.5 8 19 10 5', 'L 7 13 11 13', 'L 9 11 9 15', 'D 16 11.5 1.2', 'D 18.5 14 1.2')
    'wrench'     = @('P M15 4.2 C 12.8 4.2 11 6 11 8.2 C 11 9 11.2 9.7 11.6 10.3 L4 17.9 L6.1 20 L13.7 12.4 C 14.3 12.8 15 13 15.8 13 C 18 13 19.8 11.2 19.8 9 C 19.8 8.3 19.6 7.7 19.3 7.1 L16.4 10 L14 7.6 L16.9 4.7 C 16.3 4.4 15.7 4.2 15 4.2 Z')
    'mouse'      = @('R 7.5 3 9 18 4.5', 'L 12 7 12 10.5')
    'lock'       = @('R 5 11 14 9 2', 'P M8 11 L8 8 C 8 5.8 9.8 4 12 4 C 14.2 4 16 5.8 16 8 L16 11')
    'shield'     = @('P M12 3 L20 6 L20 12 C 20 16.5 16.5 19.8 12 21 C 7.5 19.8 4 16.5 4 12 L4 6 Z')
    'refresh'    = @('P M19.6 12 C 19.6 16.2 16.2 19.6 12 19.6 C 7.8 19.6 4.4 16.2 4.4 12 C 4.4 7.8 7.8 4.4 12 4.4 C 14.9 4.4 17.4 6 18.7 8.4', 'P M18.9 3.6 L18.9 8.7 L13.8 8.7')
    'gear'       = @('C 12 12 3.2', 'P M12 2.6 L13.4 5.3 L16.3 4.7 L16.7 7.7 L19.4 8.9 L17.8 11.3 L19.4 13.7 L16.7 14.9 L16.3 17.9 L13.4 17.3 L12 20 L10.6 17.3 L7.7 17.9 L7.3 14.9 L4.6 13.7 L6.2 11.3 L4.6 8.9 L7.3 7.7 L7.7 4.7 L10.6 5.3 Z')
    'rocket'     = @('P M12 3 C 15.5 6.2 17 9.6 17 13 L17 16 L7 16 L7 13 C 7 9.6 8.5 6.2 12 3 Z', 'C 12 10 1.7', 'P M7 16 L4.6 20.2 L8.2 19.2', 'P M17 16 L19.4 20.2 L15.8 19.2')
    'calendar'   = @('R 3.5 5 17 15 2', 'L 3.5 10 20.5 10', 'L 8 3 8 7', 'L 16 3 16 7')
    'globe'      = @('C 12 12 8.8', 'L 3.2 12 20.8 12', 'P M12 3.2 C 8.6 6.6 8.6 17.4 12 20.8 C 15.4 17.4 15.4 6.6 12 3.2 Z')
    'folders'    = @('P M3 7.5 L9 7.5 L11 10 L21 10 L21 19.5 L3 19.5 Z', 'P M6 7.5 L6 5 L11.5 5 L13.5 7.5')
    'folder'     = @('P M3 6.5 L9.5 6.5 L11.5 9 L21 9 L21 19 L3 19 Z')
    'folderopen' = @('P M3.5 19 L6 11.5 L22 11.5 L19.5 19 Z', 'P M3.5 19 L3.5 6 L9.5 6 L11.5 8.5 L18.5 8.5 L18.5 11.5')
    'note'       = @('R 4.5 3 15 18 2', 'L 8 8 16 8', 'L 8 12 16 12', 'L 8 16 13 16')
    'help'       = @('C 12 12 8.8', 'P M9.3 9.4 C 9.5 7.7 10.7 6.8 12.2 6.8 C 13.9 6.8 15 7.8 15 9.3 C 15 11.5 12 11.7 12 14.1', 'D 12 17.3 1')
    'info'       = @('C 12 12 8.8', 'D 12 7.6 1', 'L 12 11 12 17')
    'broom'      = @('L 14.6 3.6 19.4 8.4', 'P M12.6 5.6 L18.4 11.4 L9.6 20.2 L3.8 14.4 Z')
    'file'       = @('P M6 3 L14 3 L19 8 L19 21 L6 21 Z', 'P M14 3 L14 8 L19 8')
    'camera'     = @('R 3 7 18 12 2', 'C 12 13 3.4', 'P M8 7 L9.5 4.5 L14.5 4.5 L16 7')
    'trash'      = @('L 5 7 19 7', 'P M8 7 L8 20 L16 20 L16 7', 'P M10 7 L10 4 L14 4 L14 7', 'L 10.6 10 10.6 17', 'L 13.4 10 13.4 17')
    'search'     = @('C 10.5 10.5 5.8', 'L 14.8 14.8 20 20')
    'clock'      = @('C 12 12 8.8', 'P M12 6.6 L12 12.2 L15.6 14.2')
    'play'       = @('P M8 5 L19 12 L8 19 Z')
    'pause'      = @('R 8 5 3 14 1', 'R 13 5 3 14 1')
    'stop'       = @('R 6.5 6.5 11 11 2')
    'skipback'   = @('P M18 5 L8 12 L18 19 Z', 'L 6 5 6 19')
    'ban'        = @('C 12 12 8.8', 'L 5.8 5.8 18.2 18.2')
    'cpu'        = @('R 7.5 7.5 9 9 1', 'R 4.5 4.5 15 15 2', 'L 9 2.5 9 4.5', 'L 15 2.5 15 4.5', 'L 9 19.5 9 21.5', 'L 15 19.5 15 21.5', 'L 2.5 9 4.5 9', 'L 2.5 15 4.5 15', 'L 19.5 9 21.5 9', 'L 19.5 15 21.5 15')
    'window'     = @('R 3.5 4 17 16 2', 'L 3.5 9 20.5 9', 'L 12 9 12 20')
    'undo'       = @('P M9 7 L4 12 L9 17', 'P M4 12 L15 12 C 18 12 20 14.2 20 17 L20 19')
    'hourglass'  = @('L 7 3 17 3', 'L 7 21 17 21', 'P M7 3 C 7 8 12 10 12 12 C 12 14 7 16 7 21', 'P M17 3 C 17 8 12 10 12 12 C 12 14 17 16 17 21')
    'clipboard'  = @('R 5 5 14 16 2', 'R 9 3 6 4 1')
    'package'    = @('P M3 7.5 L12 3 L21 7.5 L21 16.5 L12 21 L3 16.5 Z', 'P M3 7.5 L12 12 L21 7.5', 'L 12 12 12 21')
    'image'      = @('R 3.5 5 17 14 2', 'C 9 10 1.6', 'P M5 17.5 L10 12.5 L14 16.5 L16.8 13.7 L19.8 16.7')
    'target'     = @('C 12 12 8.8', 'C 12 12 5', 'D 12 12 1.6')
    'signal'     = @('R 4 15 3 5 1', 'R 10.5 10 3 10 1', 'R 17 5 3 15 1')
    'pulse'      = @('P M3 12 L8 12 L10 7 L14 17 L16 12 L21 12')
    'check'      = @('C 12 12 8.8', 'P M7.6 12.4 L10.8 15.6 L16.4 8.8')
    'keyboard'   = @('R 2.5 6 19 12 2', 'L 6 10 8 10', 'L 10.5 10 13.5 10', 'L 16 10 18 10', 'L 8 14 16 14')
    'slider'     = @('L 4 8 20 8', 'L 4 16 20 16', 'C 9 8 2.2', 'C 15 16 2.2')
    'bulb'       = @('L 9.5 20 14.5 20', 'P M12 3 C 8.7 3 6 5.7 6 9 C 6 11.4 7.4 13.1 8.6 14.4 L8.6 17.2 L15.4 17.2 L15.4 14.4 C 16.6 13.1 18 11.4 18 9 C 18 5.7 15.3 3 12 3 Z')
    'bell'       = @('P M6 17 L18 17 C 16.6 15.4 16.5 13 16.5 11 C 16.5 7.6 14.5 5.5 12 5.5 C 9.5 5.5 7.5 7.6 7.5 11 C 7.5 13 7.4 15.4 6 17 Z', 'P M10.4 20 C 11.4 21.1 12.6 21.1 13.6 20')
    'bolt'       = @('P M13 2.5 L5 13.6 L11 13.6 L10.2 21.5 L19 10.4 L13 10.4 Z')
    'warning'    = @('P M12 3.5 L21.5 20 L2.5 20 Z', 'L 12 9.5 12 14.2', 'D 12 17 1')
    'plug'       = @('L 9 3 9 9', 'L 15 3 15 9', 'P M6.5 9 L17.5 9 L17.5 12.5 C 17.5 15.5 15 18 12 18 C 9 18 6.5 15.5 6.5 12.5 Z', 'L 12 18 12 21')
    'puzzle'     = @('P M4 5.5 L9.5 5.5 C 9.5 3.4 14 3.4 14 5.5 L19.5 5.5 L19.5 11 C 21.6 11 21.6 15.5 19.5 15.5 L19.5 20 L4 20 Z')
    'mic'        = @('R 9.5 3 5 10 2.5', 'P M6 11.5 C 6 15 8.7 17.6 12 17.6 C 15.3 17.6 18 15 18 11.5', 'L 12 17.6 12 21')
    'chat'       = @('P M4 5 L20 5 L20 16 L13 16 L8 20 L8 16 L4 16 Z')
    'megaphone'  = @('P M4 10 L4 14.2 L8 14.2 L16 19 L16 5 L8 10 Z', 'P M18.2 9.6 C 19.7 10.7 19.7 13.4 18.2 14.5')
    'pin'        = @('P M12 21 C 12 21 19 14.4 19 9.8 C 19 6 15.9 3 12 3 C 8.1 3 5 6 5 9.8 C 5 14.4 12 21 12 21 Z', 'C 12 9.6 2.3')
    'moon'       = @('P M19 14.6 C 17.9 15.5 16.5 16 15 16 C 11.4 16 8.5 13.1 8.5 9.5 C 8.5 8 9 6.6 9.9 5.5 C 6.4 6.2 3.8 9.1 3.8 12.7 C 3.8 16.8 7.2 20.2 11.3 20.2 C 14.9 20.2 17.9 17.7 18.7 14.4 Z')
    'close'      = @('L 6.5 6.5 17.5 17.5', 'L 17.5 6.5 6.5 17.5')
    'square'     = @('R 6 6 12 12 1.5')
    'restore'    = @('R 4.5 8.5 11 11 1.5', 'P M8.5 8.5 L8.5 4.5 L19.5 4.5 L19.5 15.5 L15.5 15.5')
    'chevronup'  = @('L 5.5 14.5 12 8', 'L 12 8 18.5 14.5')
    'chevrondown' = @('L 5.5 9.5 12 16', 'L 12 16 18.5 9.5')
    'minus'      = @('L 6 12 18 12')
    'plus'       = @('L 6 12 18 12', 'L 12 6 12 18')
    'dot'        = @('D 12 12 2.6')
}

# Emoji -> icon name. Keeping the map here means the ~60 existing call sites
# can keep passing their glyph; nothing else has to know about icons.
#
# NOT a hash literal: Windows PowerShell 5.1 compares hash keys with the
# current culture, and under that comparison several emoji count as the same
# key ("Duplicate keys are not allowed in hash literals" at parse time).
# An ordinal dictionary compares the characters themselves.
$script:IconMap = New-Object -TypeName 'System.Collections.Generic.Dictionary[string,string]' -ArgumentList ([System.StringComparer]::Ordinal)
foreach ($pair in @(
    @('🏠','home'), @('🖥','monitor'), @('📈','chart'), @('📊','bars'), @('💾','save'),
    @('💿','disc'), @('📀','disc'), @('💽','disc'), @('🎮','gamepad'), @('🔧','wrench'),
    @('🛠','wrench'), @('🖱','mouse'), @('🔒','lock'), @('🛡','shield'), @('🔄','refresh'),
    @('🔁','refresh'), @('♻','refresh'), @('⚙','gear'), @('🚀','rocket'), @('📅','calendar'),
    @('🌐','globe'), @('🌍','globe'), @('🗂','folders'), @('📁','folder'), @('📂','folderopen'),
    @('📝','note'), @('🗒','note'), @('📜','note'), @('❓','help'), @('🧹','broom'), @('🧽','broom'),
    @('📄','file'), @('🧾','file'), @('📸','camera'), @('📹','camera'), @('🗑','trash'),
    @('🔍','search'), @('🔎','search'), @('🕒','clock'), @('🕘','clock'), @('⏱','clock'),
    @('🐢','clock'), @('▶','play'), @('⏸','pause'), @('🅿','pause'), @('⏹','stop'),
    @('⏮','skipback'), @('🚫','ban'), @('⛔','ban'), @('📵','ban'), @('🧮','cpu'), @('🧠','cpu'),
    @('🪟','window'), @('↩','undo'), @('⏳','hourglass'), @('📋','clipboard'), @('📦','package'),
    @('🖼','image'), @('🎯','target'), @('📡','signal'), @('📶','signal'), @('🩺','pulse'),
    @('✅','check'), @('⌨','keyboard'), @('🎚','slider'), @('💡','bulb'), @('✨','bulb'),
    @('🔔','bell'), @('⚡','bolt'), @('⚠','warning'), @('🔌','plug'), @('🧩','puzzle'),
    @('🎤','mic'), @('💬','chat'), @('📢','megaphone'), @('📍','pin'), @('🛌','moon'),
    @('✕','close'), @('✖','close'), @('▢','square'), @('❐','restore')
    )) { $script:IconMap[$pair[0]] = $pair[1] }

function Get-IconName {
    # Accepts an icon name or the emoji that used to sit in the UI
    param([string]$Glyph)
    if ([string]::IsNullOrWhiteSpace($Glyph)) { return $null }
    $g = $Glyph.Trim().TrimEnd([char]0xFE0F)
    # Marker-Schreibweise {icon:name} - sie ersetzt die frueheren Emoji in
    # Beschriftungen, damit im gesamten Programm kein Emoji mehr vorkommt.
    if ($g -match '^\{icon:([a-z0-9_]+)\}$') {
        $n = $Matches[1]
        if ($script:IconShapes.ContainsKey($n)) { return $n }
        return $null
    }
    if ($script:IconShapes.ContainsKey($g)) { return $g }
    if ($script:IconMap.ContainsKey($g)) { return $script:IconMap[$g] }
    return $null
}

function Add-SvgPathData {
    # Minimal SVG path reader: M L H V C Q Z, absolute and relative.
    param([System.Drawing.Drawing2D.GraphicsPath]$Path, [string]$Data)

    $tokens = [regex]::Matches($Data, '([MmLlHhVvCcQqZz])|(-?\d*\.?\d+)')
    $cmd = ''
    $nums = New-Object System.Collections.Generic.List[double]
    $cur = New-Object System.Drawing.PointF(0, 0)
    $start = $cur
    $open = $false

    $flush = {
        param($c, $n)
        switch -CaseSensitive ($c) {
            'M' { $cur = New-Object System.Drawing.PointF([single]$n[0], [single]$n[1]); $start = $cur; $open = $false }
            'm' { $cur = New-Object System.Drawing.PointF([single]($cur.X + $n[0]), [single]($cur.Y + $n[1])); $start = $cur; $open = $false }
            'L' {
                $p = New-Object System.Drawing.PointF([single]$n[0], [single]$n[1])
                $Path.AddLine($cur, $p); $cur = $p; $open = $true
            }
            'l' {
                $p = New-Object System.Drawing.PointF([single]($cur.X + $n[0]), [single]($cur.Y + $n[1]))
                $Path.AddLine($cur, $p); $cur = $p; $open = $true
            }
            'H' {
                $p = New-Object System.Drawing.PointF([single]$n[0], $cur.Y)
                $Path.AddLine($cur, $p); $cur = $p; $open = $true
            }
            'h' {
                $p = New-Object System.Drawing.PointF([single]($cur.X + $n[0]), $cur.Y)
                $Path.AddLine($cur, $p); $cur = $p; $open = $true
            }
            'V' {
                $p = New-Object System.Drawing.PointF($cur.X, [single]$n[0])
                $Path.AddLine($cur, $p); $cur = $p; $open = $true
            }
            'v' {
                $p = New-Object System.Drawing.PointF($cur.X, [single]($cur.Y + $n[0]))
                $Path.AddLine($cur, $p); $cur = $p; $open = $true
            }
            'C' {
                $c1 = New-Object System.Drawing.PointF([single]$n[0], [single]$n[1])
                $c2 = New-Object System.Drawing.PointF([single]$n[2], [single]$n[3])
                $p = New-Object System.Drawing.PointF([single]$n[4], [single]$n[5])
                $Path.AddBezier($cur, $c1, $c2, $p); $cur = $p; $open = $true
            }
            'c' {
                $c1 = New-Object System.Drawing.PointF([single]($cur.X + $n[0]), [single]($cur.Y + $n[1]))
                $c2 = New-Object System.Drawing.PointF([single]($cur.X + $n[2]), [single]($cur.Y + $n[3]))
                $p = New-Object System.Drawing.PointF([single]($cur.X + $n[4]), [single]($cur.Y + $n[5]))
                $Path.AddBezier($cur, $c1, $c2, $p); $cur = $p; $open = $true
            }
            'Q' {
                $q = New-Object System.Drawing.PointF([single]$n[0], [single]$n[1])
                $p = New-Object System.Drawing.PointF([single]$n[2], [single]$n[3])
                $c1 = New-Object System.Drawing.PointF([single]($cur.X + 2.0 / 3.0 * ($q.X - $cur.X)), [single]($cur.Y + 2.0 / 3.0 * ($q.Y - $cur.Y)))
                $c2 = New-Object System.Drawing.PointF([single]($p.X + 2.0 / 3.0 * ($q.X - $p.X)), [single]($p.Y + 2.0 / 3.0 * ($q.Y - $p.Y)))
                $Path.AddBezier($cur, $c1, $c2, $p); $cur = $p; $open = $true
            }
        }
        return @{ Cur = $cur; Start = $start; Open = $open }
    }

    # PowerShell hash keys are case-insensitive, so the table is keyed on the
    # upper case command - the argument count is the same for both cases.
    $perCmd = @{ 'M' = 2; 'L' = 2; 'H' = 1; 'V' = 1; 'C' = 6; 'Q' = 4 }

    foreach ($t in $tokens) {
        if ($t.Groups[1].Success) {
            $c = $t.Groups[1].Value
            if ($c -eq 'Z' -or $c -eq 'z') {
                if ($open) { $Path.CloseFigure() }
                $cur = $start
                $open = $false
                $cmd = ''
                $nums.Clear()
                continue
            }
            $cmd = $c
            $nums.Clear()
            continue
        }

        if (-not $cmd) { continue }
        $nums.Add([double]$t.Groups[2].Value)
        $need = $perCmd[$cmd.ToUpperInvariant()]
        if (-not $need) { continue }
        if ($nums.Count -ge $need) {
            $r = & $flush $cmd $nums.ToArray()
            $cur = $r.Cur; $start = $r.Start; $open = $r.Open
            $nums.Clear()
            # "M 1 2 3 4" means moveto + lineto, same for repeated coordinates
            if ($cmd -eq 'M') { $cmd = 'L' } elseif ($cmd -eq 'm') { $cmd = 'l' }
        }
    }
}

function Get-IconBitmap {
    # Renders one icon into a cached bitmap. The result is cache-owned -
    # never dispose it (same rule as Get-AppFont).
    param(
        [string]$Name,
        [int]$Size = 18,
        [System.Drawing.Color]$Color = [System.Drawing.Color]::White
    )

    $icon = Get-IconName $Name
    if (-not $icon) { return $null }
    if ($Size -lt 8) { $Size = 8 }

    $key = "$icon|$Size|$($Color.ToArgb())"
    if ($script:IconCache.ContainsKey($key)) {
        $cached = $script:IconCache[$key]
        # A property getter that throws is swallowed by PowerShell, so the
        # liveness probe has to be a method call (same trick as the font cache)
        try { [void]$cached.GetPixel(0, 0); return $cached } catch { [void]$script:IconCache.Remove($key) }
    }

    $bmp = $null
    $g = $null
    $pen = $null
    $brush = $null
    try {
        $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
        $bmp.SetResolution(96, 96)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear([System.Drawing.Color]::Transparent)

        $scale = $Size / 24.0
        $g.ScaleTransform([single]$scale, [single]$scale)

        $stroke = [single]([math]::Max(1.1, 1.8 / [math]::Max($scale, 0.35)))
        $pen = New-Object System.Drawing.Pen($Color, $stroke)
        $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
        $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $brush = New-Object System.Drawing.SolidBrush($Color)

        foreach ($shape in $script:IconShapes[$icon]) {
            $kind = $shape.Substring(0, 1)
            $rest = $shape.Substring(1).Trim()
            switch ($kind) {
                'L' {
                    $n = $rest -split '\s+'
                    $g.DrawLine($pen, [single]$n[0], [single]$n[1], [single]$n[2], [single]$n[3])
                }
                'R' {
                    $n = $rest -split '\s+'
                    $rad = if ($n.Count -ge 5) { [single]$n[4] } else { [single]0 }
                    if ($rad -le 0) {
                        $g.DrawRectangle($pen, [single]$n[0], [single]$n[1], [single]$n[2], [single]$n[3])
                    }
                    else {
                        $rp = New-Object System.Drawing.Drawing2D.GraphicsPath
                        try {
                            $x = [single]$n[0]; $y = [single]$n[1]; $w = [single]$n[2]; $h = [single]$n[3]
                            $d = [single]($rad * 2)
                            $rp.AddArc($x, $y, $d, $d, 180, 90)
                            $rp.AddArc(($x + $w - $d), $y, $d, $d, 270, 90)
                            $rp.AddArc(($x + $w - $d), ($y + $h - $d), $d, $d, 0, 90)
                            $rp.AddArc($x, ($y + $h - $d), $d, $d, 90, 90)
                            $rp.CloseFigure()
                            $g.DrawPath($pen, $rp)
                        }
                        finally { $rp.Dispose() }
                    }
                }
                'C' {
                    $n = $rest -split '\s+'
                    $cx = [single]$n[0]; $cy = [single]$n[1]; $r = [single]$n[2]
                    $g.DrawEllipse($pen, ($cx - $r), ($cy - $r), ($r * 2), ($r * 2))
                }
                'D' {
                    $n = $rest -split '\s+'
                    $cx = [single]$n[0]; $cy = [single]$n[1]; $r = [single]$n[2]
                    $g.FillEllipse($brush, ($cx - $r), ($cy - $r), ($r * 2), ($r * 2))
                }
                'P' {
                    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                    try {
                        Add-SvgPathData -Path $path -Data $rest
                        if ($path.PointCount -gt 0) { $g.DrawPath($pen, $path) }
                    }
                    finally { $path.Dispose() }
                }
            }
        }

        $script:IconCache[$key] = $bmp
        return $bmp
    }
    catch {
        if ($bmp) { try { $bmp.Dispose() } catch { } }
        return $null
    }
    finally {
        if ($g) { $g.Dispose() }
        if ($pen) { $pen.Dispose() }
        if ($brush) { $brush.Dispose() }
    }
}

function Get-LeadingGlyph {
    # First text element of a string, if it maps to an icon
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    if ($Text.TrimStart() -match '^(\{icon:[a-z0-9_]+\})') {
        $tok = $Matches[1]
        if (Get-IconName $tok) { return $tok }
        return $null
    }
    $e = [System.Globalization.StringInfo]::GetTextElementEnumerator($Text.TrimStart())
    if (-not $e.MoveNext()) { return $null }
    $first = [string]$e.Current
    if (Get-IconName $first) { return $first }
    return $null
}

$script:IconPainters = New-Object -TypeName 'System.Runtime.CompilerServices.ConditionalWeakTable[System.Object,System.Object]'

function Set-RichTextLtr {
    # Protokoll, Hardware-Tabelle, Update-Liste und Netzwerkdaten sind
    # Spaltensatz mit Zeitstempeln, Pfaden und Befehlen. Im arabischen Modus
    # erbten sie RightToLeft vom Fenster - dann rutscht der Zeitstempel an den
    # rechten Rand, die Spalten brechen auseinander und Zeilen werden
    # abgeschnitten. Diese Flaechen bleiben darum immer linkslaeufig; die
    # arabischen Woerter darin setzt Windows innerhalb der Zeile trotzdem
    # richtig herum.
    param([System.Windows.Forms.Control]$Root)
    if (-not $Root -or $Root.IsDisposed) { return }
    foreach ($c in @($Root.Controls)) {
        if (-not $c -or $c.IsDisposed) { continue }
        try {
            if ($c -is [System.Windows.Forms.RichTextBox]) {
                $c.RightToLeft = [System.Windows.Forms.RightToLeft]::No
            }
        }
        catch { }
        if ($c.HasChildren) { Set-RichTextLtr -Root $c }
    }
}

function Test-RightToLeftUi {
    # Nur Arabisch laeuft rechtslaeufig; RightToLeft der Steuerelemente steht
    # beim Erzeugen oft noch auf 'Inherit', deshalb die Sprache fragen.
    try { return ($script:Config -and $script:Config.CurrentLang -eq 'AR') }
    catch { return $false }
}

function Set-LabelIconPainter {
    # WICHTIG: Ein Label zeichnet Bild UND Text in dasselbe Rechteck
    # (ClientRectangle minus Padding). Ein linker Innenabstand verschiebt also
    # beides - genau deshalb lagen Icon und Text in der Kopfzeile uebereinander.
    # Loesung: Das Label bekommt kein Image mehr, der Innenabstand haelt links
    # Platz frei und das Icon wird im Paint-Ereignis dorthin gezeichnet.
    param(
        [System.Windows.Forms.Control]$Control,
        [System.Drawing.Image]$Image,
        [bool]$Rtl = $false
    )
    if (-not $Control -or -not $Image) { return }
    $holder = $null
    if ($script:IconPainters.TryGetValue($Control, [ref]$holder)) {
        # Schon vorhanden: nur das Bild austauschen, keinen zweiten Handler.
        $holder.Image = $Image
        $holder.Rtl = $Rtl
        $Control.Invalidate()
        return
    }
    $holder = New-Object psobject -Property @{ Image = $Image; Rtl = $Rtl }
    $script:IconPainters.Add($Control, $holder)
    $Control.Add_Paint(({
                param($s, $e)
                try {
                    $im = $holder.Image
                    if (-not $im) { return }
                    $y = [int][math]::Max(0, ($s.Height - $im.Height) / 2)
                    $x = 2
                    if ($holder.Rtl) { $x = [int][math]::Max(0, $s.Width - $im.Width - 2) }
                    $e.Graphics.DrawImageUnscaled($im, $x, $y)
                }
                catch { }
            }).GetNewClosure())
    $Control.Invalidate()
}

function Set-ControlIcon {
    # Puts a vector icon on a button or label, optionally removing the emoji
    # that used to stand in for it.
    param(
        [System.Windows.Forms.Control]$Control,
        [string]$Glyph,
        [int]$Size = 16,
        $Color = $null,
        [switch]$StripText,
        [switch]$IconOnly
    )
    if (-not $Control -or $Control.IsDisposed) { return $false }
    $name = Get-IconName $Glyph
    if (-not $name) { return $false }

    # An omitted [Color] parameter arrives as Color::Empty (alpha 0) - that
    # would paint an invisible icon, so fall back to the control's colour.
    $col = if (($Color -is [System.Drawing.Color]) -and ($Color.A -gt 0)) { $Color } else { $Control.ForeColor }
    if ($col.A -eq 0) { $col = $script:Theme.TextPrimary }
    $img = Get-IconBitmap -Name $name -Size $Size -Color $col
    if (-not $img) { return $false }

    $text = [string]$Control.Text
    if ($StripText -and $text -and $text.TrimStart() -match '^\{icon:[a-z0-9_]+\}\s*') {
        $text = $text.TrimStart() -replace '^\{icon:[a-z0-9_]+\}\s*', ''
    }
    elseif ($StripText -and $text) {
        $trimmed = $text.TrimStart()
        $e = [System.Globalization.StringInfo]::GetTextElementEnumerator($trimmed)
        if ($e.MoveNext()) {
            $first = [string]$e.Current
            if ((Get-IconName $first)) { $text = $trimmed.Substring($first.Length).TrimStart() }
        }
    }

    try {
    if ($IconOnly -or [string]::IsNullOrWhiteSpace($text)) {
        $Control.Image = $img
        $Control.Text = ''
        $Control.ImageAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        if ($Control -is [System.Windows.Forms.Label]) {
            $Control.AutoSize = $false
            $Control.Size = New-Object System.Drawing.Size(($Size + 6), ($Size + 6))
        }
    }
    else {
        $Control.Text = $text
        if ($Control -is [System.Windows.Forms.Button]) {
            # Knoepfe koennen Bild und Text selbst nebeneinander setzen.
            $Control.Image = $img
            $Control.ImageAlign = [System.Drawing.ContentAlignment]::MiddleLeft
            $Control.TextImageRelation = [System.Windows.Forms.TextImageRelation]::ImageBeforeText
            # Bei mittig gesetztem Text zentriert WinForms Bild und Text
            # gemeinsam - ein linker Innenabstand wuerde das Paar verschieben.
            if ($Control.TextAlign -eq [System.Drawing.ContentAlignment]::MiddleLeft) {
                $Control.Padding = New-Object System.Windows.Forms.Padding(8, 0, 0, 0)
            }
            else {
                $Control.ImageAlign = [System.Drawing.ContentAlignment]::MiddleCenter
            }
        }
        else {
            # Label: Bild und Text wuerden sich ueberlagern - siehe
            # Set-LabelIconPainter.
            $Control.Image = $null
            $rtl = Test-RightToLeftUi
            if ($rtl) {
                $Control.Padding = New-Object System.Windows.Forms.Padding(0, 0, ($Size + 8), 0)
            }
            else {
                $Control.Padding = New-Object System.Windows.Forms.Padding(($Size + 8), 0, 0, 0)
            }
            Set-LabelIconPainter -Control $Control -Image $img -Rtl $rtl
        }
    }
    }
    catch { return $false }
    return $true
}

$script:PolishedControls = New-Object -TypeName 'System.Runtime.CompilerServices.ConditionalWeakTable[System.Object,System.Object]'

function Test-ControlPolished {
    # Merkt sich pro Steuerelement, ob es schon behandelt wurde - und zwar in
    # einer schwachen Tabelle, damit geschlossene Ansichten trotzdem vom
    # Speicherbereiniger abgeraeumt werden. Liefert $true, wenn das Element
    # bereits behandelt war, und markiert es sonst.
    param([System.Windows.Forms.Control]$Control)
    if (-not $Control) { return $true }
    $v = $null
    try {
        if ($script:PolishedControls.TryGetValue($Control, [ref]$v)) { return $true }
        $script:PolishedControls.Add($Control, [object]$true)
    }
    catch { return $true }
    return $false
}

function Set-ButtonPolish {
    # Runde Ecken fuer die groesseren Aktionsknoepfe und ein sichtbarer
    # Fokusrahmen: Mit der Tastatur war bisher nicht erkennbar, wo man steht.
    param([System.Windows.Forms.Button]$Button)
    if (-not $Button -or $Button.IsDisposed) { return }
    # Der Icon-Durchlauf laeuft bei jedem Ansichtswechsel erneut. Ohne diese
    # Sperre bekaeme derselbe Knopf jedes Mal weitere Ereignis-Handler -
    # das waere ein Leck und wuerde den Fokusrahmen mehrfach zeichnen.
    if (Test-ControlPolished -Control $Button) { return }
    try {
        $isNav = ($Button.Tag -is [hashtable] -and $Button.Tag.ContainsKey('View'))
        if (-not $isNav -and $Button.Width -ge 70 -and $Button.Height -ge 28 -and -not $Button.Region) {
            Set-RoundedRegion -Control $Button -Radius 8
            # Ein Bereich gilt fuer genau eine Groesse - nach jeder Breiten-
            # aenderung (verankerte Knoepfe) muss er neu gesetzt werden.
            $Button.Add_Resize({
                    try { Set-RoundedRegion -Control $this -Radius 8 } catch { }
                })
        }
        if ($Button.TabStop) {
            # Den vorhandenen Rahmen merken und spaeter genau so
            # wiederherstellen - sonst verlieren umrandete Knoepfe ihr Aussehen.
            $baseSize = 0
            $baseColor = $Button.BackColor
            try {
                $baseSize = [int]$Button.FlatAppearance.BorderSize
                $baseColor = $Button.FlatAppearance.BorderColor
            }
            catch { }
            $Button.Add_GotFocus({
                    try {
                        $this.FlatAppearance.BorderColor = $script:Theme.Accent
                        $this.FlatAppearance.BorderSize = 2
                    }
                    catch { }
                })
            $Button.Add_LostFocus(({
                        try {
                            $this.FlatAppearance.BorderSize = $baseSize
                            $this.FlatAppearance.BorderColor = $baseColor
                        }
                        catch { }
                    }).GetNewClosure())
        }
    }
    catch { }
}

function Update-ControlIcons {
    # Walks a container and replaces every leading emoji of a button or label
    # with its vector icon. Called after a view is built and for the chrome.
    param([System.Windows.Forms.Control]$Root, [int]$Size = 16)
    if (-not $Root -or $Root.IsDisposed) { return }

    foreach ($c in @($Root.Controls)) {
        if (-not $c -or $c.IsDisposed) { continue }
        try {
        # The status mirror and the log keep their plain text symbols
        if ($script:lblStatus -and $c -eq $script:lblStatus) { continue }
        if ($c -is [System.Windows.Forms.TextBoxBase]) { continue }

        # Kategorie-Beschriftungen der Seitenleiste bleiben, wie sie sind
        if ($c.Tag -is [hashtable] -and $c.Tag['IsCategory']) { continue }
        if ($c -is [System.Windows.Forms.CheckBox] -or $c -is [System.Windows.Forms.RadioButton]) {
            # Kaestchen und Text ruecken nach rechts, das Symbol wird links
            # daneben gezeichnet - ein Image wuerde das Kaestchen ueberdecken.
            $g = Get-LeadingGlyph $c.Text
            if ($g) {
                $c.Text = $c.Text.TrimStart().Substring($g.Length).TrimStart()
                $nm = Get-IconName $g
                if ($nm) {
                    $img = Get-IconBitmap -Name $nm -Size $Size -Color $c.ForeColor
                    if ($img) {
                        if ($c.Padding.Left -lt ($Size + 6)) {
                            $c.Padding = New-Object System.Windows.Forms.Padding(($Size + 6), 0, 0, 0)
                        }
                        Set-LabelIconPainter -Control $c -Image $img -Rtl (Test-RightToLeftUi)
                    }
                }
            }
        }
        elseif (($c -is [System.Windows.Forms.Button] -or $c -is [System.Windows.Forms.Label]) -and $null -eq $c.Image) {
            $g = Get-LeadingGlyph $c.Text
            if ($g) { [void](Set-ControlIcon -Control $c -Glyph $g -Size $Size -StripText) }
        }
        if ($c -is [System.Windows.Forms.Button]) { Set-ButtonPolish -Button $c }
        }
        catch { }
        if ($c.HasChildren) { Update-ControlIcons -Root $c -Size $Size }
    }
}

function Add-ListIcon {
    # ListView rows cannot carry a picture directly - they need an ImageList.
    # Returns the key to assign to ListViewItem.ImageKey ('' when unavailable).
    param(
        [System.Windows.Forms.ListView]$ListView,
        [string]$Name,
        [int]$Size = 16,
        $Color = $null
    )
    if (-not $ListView -or $ListView.IsDisposed) { return '' }
    $icon = Get-IconName $Name
    if (-not $icon) { return '' }

    try {
    if (-not $ListView.SmallImageList) {
        $il = New-Object System.Windows.Forms.ImageList
        $il.ImageSize = New-Object System.Drawing.Size($Size, $Size)
        $il.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit
        $ListView.SmallImageList = $il
    }
    $list = $ListView.SmallImageList
    if (-not $list.Images.ContainsKey($icon)) {
        $col = if (($Color -is [System.Drawing.Color]) -and ($Color.A -gt 0)) { $Color } else { $ListView.ForeColor }
        $bmp = Get-IconBitmap -Name $icon -Size $list.ImageSize.Width -Color $col
        if (-not $bmp) { return '' }
        # ImageList copies the bitmap, the cache keeps owning the original
        $list.Images.Add($icon, $bmp)
    }
    }
    catch { return '' }
    return $icon
}

function Stop-AppIcons {
    try {
        if ($script:IconCache) {
            foreach ($b in @($script:IconCache.Values)) {
                if ($b -is [System.IDisposable]) { try { $b.Dispose() } catch { } }
            }
            $script:IconCache.Clear()
        }
    }
    catch { }
}

#endregion 1b. VECTOR ICONS


#endregion 1. CONFIGURATION


#region 2. LOCALIZATION (DE / EN / TR / AR)

$script:Languages = @{
    'DE' = @{
        Name                = 'Deutsch'
        Flag                = '{icon:flag}'
        Welcome             = 'Willkommen'
        Ready               = 'System bereit'
        Loading             = 'Lade...'
        Success             = 'Erfolgreich'
        Error               = 'Fehler'
        Warning             = 'Warnung'
        Info                = 'Info'
        Yes                 = 'Ja'
        No                  = 'Nein'
        OK                  = 'OK'
        Cancel              = 'Abbrechen'
        Close               = 'Schließen'
        Refresh             = 'Aktualisieren'
        Export              = 'Exportieren'
        Import              = 'Importieren'
        Start               = 'Starten'
        Stop                = 'Stoppen'
        Enable              = 'Aktivieren'
        Disable             = 'Deaktivieren'
        Delete              = 'Löschen'
        Clean               = 'Bereinigen'
        Optimize            = 'Optimieren'
        Apply               = 'Anwenden'
        Confirm             = 'Bestätigen'
        Reset               = 'Zurücksetzen'
        Restart             = 'Neu starten'
        Restore             = 'Wiederherstellen'
        Analyze             = 'Analysieren'
        ServiceSearch       = 'Dienste suchen'
        RestorePoint        = 'Wiederherstellungspunkt'
        RestorePointDesc    = 'Systemwiederherstellungspunkt erstellen'
        RPCreating          = 'Erstelle Wiederherstellungspunkt...'
        RPError             = 'Fehler beim Erstellen'
        RPDisabled          = 'Systemwiederherstellung ist per Richtlinie deaktiviert'
        RPNotCreated        = 'Kein Wiederherstellungspunkt angelegt - Windows laesst nur einen pro 24 Stunden zu'
        RPRetry             = 'Zeitsperre voruebergehend aufgehoben, zweiter Versuch'
        RPVerified          = 'Wiederherstellungspunkt geprueft vorhanden'
        Protected           = 'Geschützter Eintrag – Aktion blockiert'

        MenuDashboard       = 'Dashboard'
        MenuHardware        = 'Hardware Info'
        MenuDisk            = 'Disk Cleaner'
        MenuGaming          = 'Gaming Modus'
        MenuPrivacy         = 'Datenschutz'
        MenuDefender        = 'Defender Ausnahmen'
        MenuServices        = 'Dienste'
        MenuStartup         = 'Autostart'
        MenuUpdates         = 'Updates'
        MenuNetwork         = 'Netzwerk'
        MenuRepair          = 'Reparatur'
        MenuProcesses       = 'Prozesse'
        MenuRegistry        = 'Registry'
        MenuBenchmark       = 'Benchmark'
        MenuTweaks          = 'Tweaks'
        MenuSettings        = 'Einstellungen'
        MenuTasks           = 'Aufgabenplanung'

        ServicesSubtitle    = 'Windows-Dienste verwalten'
        StartupSubtitle     = 'Autostart-Einträge verwalten'
        TasksSubtitle       = 'Geplante Aufgaben verwalten'
        UpdatesSubtitle     = 'Windows Update steuern'
        NetworkSubtitle     = 'Verbindung optimieren & reparieren'
        ProcSubtitle        = 'Laufende Prozesse überwachen'
        RegistrySubtitle    = 'Registry-Reste bereinigen'
        TweaksSubtitle      = 'System-Feinabstimmung'
        SettingsSubtitle    = 'Sprache & Programminfo'

        CatMain             = 'HAUPTMENÜ'
        CatOptimize         = 'OPTIMIERUNG'
        CatSecurity         = 'SICHERHEIT'
        CatSystem           = 'SYSTEM'
        CatAdvanced         = 'ERWEITERT'

        DashTitle           = 'Dashboard'
        DashSubtitle        = 'Echtzeit-Systemüberwachung'
        BenchSubtitle       = 'Systemleistung im Test'
        DashCPU             = 'CPU AUSLASTUNG'
        DashRAM             = 'RAM AUSLASTUNG'
        DashHealth          = 'SYSTEMZUSTAND'
        DashHealthDesc      = "Leistungsindex.`nAuf 100 % optimieren."
        DashHealthOptimal   = 'Optimal'
        DashHealthTune      = 'Optimierung empfohlen'
        DashNetTitle        = 'NETZWERK-TELEMETRIE'
        DashDisk            = 'SPEICHER'
        DashProcs           = 'PROZESSE'
        DashQuick           = 'QUICK ACTIONS'

        QuickClean          = 'Quick Clean'
        QuickCleanDesc      = 'Temp-Dateien und Cache bereinigen'
        QuickRAM            = 'RAM Optimieren'
        QuickRAMDesc        = 'Arbeitsspeicher freigeben'
        QuickDNS            = 'DNS Flush'
        QuickDNSDesc        = 'DNS-Cache leeren'
        QuickExplorer       = 'Explorer Neustart'
        QuickExplorerDesc   = 'Windows Explorer neu starten'
        QuickAuto           = 'Auto-Optimierung'
        QuickAutoDesc       = 'Vollständige System-Wartung'

        HWTitle             = 'Hardware Info'
        HWSubtitle          = 'System-Spezifikationen'
        HWProcessor         = 'PROZESSOR'
        HWGraphics          = 'GRAFIKKARTE'
        HWMemory            = 'ARBEITSSPEICHER'
        HWStorage           = 'SPEICHER'
        HWOS                = 'BETRIEBSSYSTEM'

        DiskTitle           = 'Disk Cleaner'
        DiskSubtitle        = 'Speicherplatz freigeben'
        DiskTemp            = 'Temp-Dateien'
        DiskTempDesc        = 'Temporäre Systemdateien löschen'
        DiskBrowser         = 'Browser-Cache'
        DiskBrowserDesc     = 'Chrome- und Edge-Cache leeren'
        DiskLogs            = 'Windows Logs'
        DiskLogsDesc        = 'Ereignisprotokolle leeren'
        DiskRecycle         = 'Papierkorb'
        DiskRecycleDesc     = 'Papierkorb leeren'
        DiskDeep            = 'Deep Clean'
        DiskDeepDesc        = 'Update-Cache & Prefetch löschen'
        DiskTotal           = 'Gesamt bereinigt'

        GameTitle           = 'Gaming Modus'
        GameSubtitle        = 'Maximum Performance für Spiele'
        GamePower           = 'Power Plan'
        GamePowerDesc       = 'Ultimate Performance aktivieren'
        GameMode            = 'Game Mode'
        GameModeDesc        = 'Windows Spielmodus einschalten'
        GameTCP             = 'TCP Optimierung'
        GameTCPDesc         = 'Netzwerk-Latenz reduzieren'
        GameGPU             = 'GPU Scheduling'
        GameGPUDesc         = 'Hardwarebeschleunigte GPU-Planung'
        GameDVR             = 'GameDVR Aus'
        GameDVRDesc         = 'Hintergrundaufnahme deaktivieren'
        GameMega            = 'MEGA GAMING MODE'
        GameMegaDesc        = 'Alle Optimierungen aktivieren'

        PrivTitle           = 'Datenschutz'
        PrivSubtitle        = 'Telemetrie & Tracking kontrollieren'
        PrivApplyAll        = 'Alle aktivieren'
        PrivTelemetry       = 'Telemetrie deaktivieren'
        PrivAds             = 'Werbe-ID deaktivieren'
        PrivCortana         = 'Cortana deaktivieren'
        PrivFeedback        = 'Feedback-Anfragen aus'
        PrivBing            = 'Bing-Suche deaktivieren'
        PrivActivity        = 'Aktivitätsverlauf aus'

        DlgConfirm          = 'Bestätigung'
        DlgWarning          = 'Warnung'
        DlgRisk             = 'Ich verstehe das Risiko'
        DlgContinue         = 'Fortfahren'
        DlgCompleted        = 'Abgeschlossen'
        DlgBackupCreated    = 'Backup erstellt'
        DlgRestartReq       = 'Neustart erforderlich'

        DefTitle            = 'Defender Ausnahmen'
        DefSubtitle         = 'Ausschlusslisten verwalten'
        DefAddPath          = 'Pfad hinzufügen'
        DefAddProcess       = 'Prozess hinzufügen'
        DefRemove           = 'Entfernen'
        DefType             = 'Typ'
        DefValue            = 'Wert'

        StatusBackup        = 'Auto-Backup aktiv'
        ShortcutInfo        = 'Tastenkürzel'
        ProcSearch          = 'Prozesse suchen'
        ProcThreads         = 'THREADS'
        ProcAuto            = 'Automatisch'
        TipProcAuto         = 'Liste alle 2,5 Sekunden auffrischen - Auswahl und Bildlauf bleiben erhalten'
        ProcKill            = 'Prozess beenden'
        BenchTitle          = 'System Benchmark'
        BenchCPU            = 'CPU Test'
        BenchRAM            = 'RAM Test'
        BenchDisk           = 'Disk Test'
        Search              = 'Suche'
        StartUser           = 'Benutzer'
        StartSystem         = 'System'

        TweakAnimations     = 'Animationen deaktivieren'
        TweakSysMain        = 'Superfetch (SysMain) stoppen'
        TweakFastStart      = 'Schnellstart aktivieren'
        TweakThrottling     = 'Netzwerk-Drosselung aus'
        TweakParking        = 'Core Parking deaktivieren'
        TweakPriority       = 'Gaming Prioritäts-Boost'
        TweakDebloat        = 'System De-bloat (Telemetrie aus)'
        TweakSearchIdx      = 'Windows Search Indexing aus'
        TweakHibernate      = 'Ruhezustand deaktivieren'
        TweakBgApps         = 'Hintergrund-Apps deaktivieren'
        TweakTips           = 'Windows Tipps/Benachrichtigungen aus'
        TweakTransparency   = 'Transparenz-Effekte deaktivieren'

        GameMouseAccel      = 'Mausbeschleunigung deaktivieren'
        GameMouseAccelDesc  = 'Rohe Mausdaten für Präzision'
        GameFullscreen      = 'Fullscreen-Optimierungen aus'
        GameFullscreenDesc  = 'Weniger Input-Lag in Spielen'
        GameHPET            = 'HPET deaktivieren'
        GameHPETDesc        = 'Niedrigere Latenz (Neustart nötig)'

        DiskWUCache         = 'Windows Update Cache'
        DiskWUCacheDesc     = 'Update-Download-Dateien löschen'
        DiskThumbnails      = 'Thumbnail-Cache'
        DiskThumbnailsDesc  = 'Vorschaubilder-Cache leeren'

        NetDNS              = 'DNS Optimierung'
        NetDNSDesc          = 'Schnellen DNS-Server setzen'
        NetNagle            = 'Nagle-Algorithmus aus'
        NetNagleDesc        = 'Weniger Paket-Verzögerung'
        NetWinsock          = 'Winsock Reset'
        NetWinsockDesc      = 'Netzwerkstack zurücksetzen'
        NetPing             = 'Ping-Test'
        NetPingDesc         = 'Latenz zu google.com messen'
        NetSpeed            = 'Speedtest'
        NetSpeedDesc        = 'Speedtest.net im Browser öffnen'

        PrivLocation        = 'Standort-Tracking deaktivieren'
        PrivWiFiSense       = 'WiFi Sense deaktivieren'
        PrivClipboard       = 'Zwischenablage-Verlauf aus'
        PrivDiagnostics     = 'App-Diagnose deaktivieren'
        PrivTailored        = 'Personalisierte Erfahrungen aus'
        PrivTimeline        = 'Zeitachse deaktivieren'

        RepairCHKDSK        = 'Festplatten-Prüfung'
        RepairCHKDSKDesc    = 'CHKDSK Festplattenanalyse'
        RepairComponent     = 'Komponentenbereinigung'
        RepairComponentDesc = 'Windows Komponentenspeicher aufräumen'
        RepairNetwork       = 'Netzwerk-Reset'
        RepairNetworkDesc   = 'Netzwerkadapter zurücksetzen'
        RepairExplorer      = 'Explorer Neustart'
        RepairExplorerDesc  = 'Windows Explorer neu starten'
        RepairWU            = 'Windows Update Reset'
        RepairWUDesc        = 'Update-Komponenten zurücksetzen'

        UpdPause            = 'Updates pausieren'
        UpdPauseDesc        = 'Windows Update 7 Tage anhalten'
        UpdResume           = 'Updates fortsetzen'
        UpdResumeDesc       = 'Pause aufheben'
        UpdRepair           = 'Update-Dienste reparieren'
        UpdRepairDesc       = 'Dienste neu starten & Cache leeren'

        ContextTitle        = 'Kontextmenü-Manager'
        ContextSubtitle     = 'Shell-Erweiterungen & klassische Menüs'
        MenuContext         = 'Kontextmenü'
        ClassicMenu         = 'Klassisches Menü'
        ClassicMenuDesc     = 'Win 10 Stil Menü in Win 11'
        ModernMenu          = 'Modernes Menü'
        ModernMenuDesc      = 'Standard Win 11 Menü'
        HideShare           = 'Zugriff ausblenden'
        HideShareDesc       = '"Zugriff gewähren" entfernen'

        MenuInput           = 'Eingabe-Tuning'
        InputTitle          = 'Eingabe-Optimierung'
        InputSubtitle       = 'Latenz & FilterKeys Tuning'
        FilterKeys          = 'FilterKeys Boost'
        FilterKeysDesc      = 'Tastatur-Reaktionszeit optimieren'
        RepairTitle         = 'Reparatur-Center'
        RepairSubtitle      = 'System-Selbstheilung & Scans'
        SysScan             = 'System-Scan'
        SysScanDesc         = 'SFC & DISM Reparatur ausführen'

        RegMui              = 'MUI Cache bereinigen'
        RegRecent           = 'Zuletzt verwendete Dokumente'
        RegRunMRU           = 'Ausführen-Verlauf'
        RegTyped            = 'Eingegebene Pfade'
    }

    'EN' = @{
        Name                = 'English'
        Flag                = '{icon:flag}'
        Welcome             = 'Welcome'
        Ready               = 'System ready'
        Loading             = 'Loading...'
        Success             = 'Success'
        Error               = 'Error'
        Warning             = 'Warning'
        Info                = 'Info'
        Yes                 = 'Yes'
        No                  = 'No'
        OK                  = 'OK'
        Cancel              = 'Cancel'
        Close               = 'Close'
        Refresh             = 'Refresh'
        Export              = 'Export'
        Import              = 'Import'
        Start               = 'Start'
        Stop                = 'Stop'
        Enable              = 'Enable'
        Disable             = 'Disable'
        Delete              = 'Delete'
        Clean               = 'Clean'
        Optimize            = 'Optimize'
        Apply               = 'Apply'
        Confirm             = 'Confirm'
        Reset               = 'Reset'
        Restart             = 'Restart'
        Restore             = 'Restore'
        Analyze             = 'Analyze'
        ServiceSearch       = 'Search Services'
        RestorePoint        = 'Restore Point'
        RestorePointDesc    = 'Create a system restore point'
        RPCreating          = 'Creating Restore Point...'
        RPError             = 'Restore Point failed'
        RPDisabled          = 'System Restore is disabled by policy'
        RPNotCreated        = 'No restore point was created - Windows allows only one per 24 hours'
        RPRetry             = 'Rate limit lifted temporarily, second attempt'
        RPVerified          = 'Restore point verified'
        Protected           = 'Protected item - action blocked'

        MenuDashboard       = 'Dashboard'
        MenuHardware        = 'Hardware Info'
        MenuDisk            = 'Disk Cleaner'
        MenuGaming          = 'Gaming Mode'
        MenuPrivacy         = 'Privacy'
        MenuDefender        = 'Defender Exclusions'
        MenuServices        = 'Services'
        MenuStartup         = 'Startup'
        MenuUpdates         = 'Updates'
        MenuNetwork         = 'Network'
        MenuRepair          = 'Repair'
        MenuProcesses       = 'Processes'
        MenuRegistry        = 'Registry'
        MenuBenchmark       = 'Benchmark'
        MenuTweaks          = 'Tweaks'
        MenuSettings        = 'Settings'
        MenuTasks           = 'Scheduled Tasks'

        ServicesSubtitle    = 'Manage Windows services'
        StartupSubtitle     = 'Manage startup entries'
        TasksSubtitle       = 'Manage scheduled tasks'
        UpdatesSubtitle     = 'Control Windows Update'
        NetworkSubtitle     = 'Optimize & repair connectivity'
        ProcSubtitle        = 'Monitor running processes'
        RegistrySubtitle    = 'Clean registry leftovers'
        TweaksSubtitle      = 'System fine tuning'
        SettingsSubtitle    = 'Language & application info'

        CatMain             = 'MAIN MENU'
        CatOptimize         = 'OPTIMIZATION'
        CatSecurity         = 'SECURITY'
        CatSystem           = 'SYSTEM'
        CatAdvanced         = 'ADVANCED'

        DashTitle           = 'Dashboard'
        DashSubtitle        = 'Real-time system monitoring'
        BenchSubtitle       = 'Test system performance'
        DashCPU             = 'CPU USAGE'
        DashRAM             = 'RAM USAGE'
        DashHealth          = 'SYSTEM HEALTH'
        DashHealthDesc      = "Performance efficiency level.`nOptimize to reach 100%."
        DashHealthOptimal   = 'Optimal'
        DashHealthTune      = 'Tuning required'
        DashNetTitle        = 'NETWORK TELEMETRY'
        DashDisk            = 'STORAGE'
        DashProcs           = 'PROCESSES'
        DashQuick           = 'QUICK ACTIONS'

        QuickClean          = 'Quick Clean'
        QuickCleanDesc      = 'Clean temp files and cache'
        QuickRAM            = 'Optimize RAM'
        QuickRAMDesc        = 'Free up memory'
        QuickDNS            = 'DNS Flush'
        QuickDNSDesc        = 'Clear DNS cache'
        QuickExplorer       = 'Restart Explorer'
        QuickExplorerDesc   = 'Restart Windows Explorer'
        QuickAuto           = 'Auto-Optimize'
        QuickAutoDesc       = 'Complete system maintenance'

        HWTitle             = 'Hardware Info'
        HWSubtitle          = 'System specifications'
        HWProcessor         = 'PROCESSOR'
        HWGraphics          = 'GRAPHICS'
        HWMemory            = 'MEMORY'
        HWStorage           = 'STORAGE'
        HWOS                = 'OPERATING SYSTEM'

        DiskTitle           = 'Disk Cleaner'
        DiskSubtitle        = 'Free up disk space'
        DiskTemp            = 'Temp Files'
        DiskTempDesc        = 'Delete temporary system files'
        DiskBrowser         = 'Browser Cache'
        DiskBrowserDesc     = 'Clear Chrome and Edge cache'
        DiskLogs            = 'Windows Logs'
        DiskLogsDesc        = 'Clear event logs'
        DiskRecycle         = 'Recycle Bin'
        DiskRecycleDesc     = 'Empty the recycle bin'
        DiskDeep            = 'Deep Clean'
        DiskDeepDesc        = 'Clear update cache & prefetch'
        DiskTotal           = 'Total cleaned'

        GameTitle           = 'Gaming Mode'
        GameSubtitle        = 'Maximum performance for games'
        GamePower           = 'Power Plan'
        GamePowerDesc       = 'Enable Ultimate Performance'
        GameMode            = 'Game Mode'
        GameModeDesc        = 'Turn on Windows Game Mode'
        GameTCP             = 'TCP Optimization'
        GameTCPDesc         = 'Reduce network latency'
        GameGPU             = 'GPU Scheduling'
        GameGPUDesc         = 'Hardware accelerated GPU scheduling'
        GameDVR             = 'GameDVR Off'
        GameDVRDesc         = 'Disable background recording'
        GameMega            = 'MEGA GAMING MODE'
        GameMegaDesc        = 'Enable all optimizations'

        PrivTitle           = 'Privacy'
        PrivSubtitle        = 'Control telemetry & tracking'
        PrivApplyAll        = 'Apply all'
        PrivTelemetry       = 'Disable Telemetry'
        PrivAds             = 'Disable Advertising ID'
        PrivCortana         = 'Disable Cortana'
        PrivFeedback        = 'Disable Feedback requests'
        PrivBing            = 'Disable Bing Search'
        PrivActivity        = 'Disable Activity Feed'

        DlgConfirm          = 'Confirmation'
        DlgWarning          = 'Warning'
        DlgRisk             = 'I understand the risk'
        DlgContinue         = 'Continue'
        DlgCompleted        = 'Completed'
        DlgBackupCreated    = 'Backup created'
        DlgRestartReq       = 'Restart required'

        DefTitle            = 'Defender Exclusions'
        DefSubtitle         = 'Manage exclusion lists'
        DefAddPath          = 'Add Path'
        DefAddProcess       = 'Add Process'
        DefRemove           = 'Remove'
        DefType             = 'Type'
        DefValue            = 'Value'

        StatusBackup        = 'Auto-backup active'
        ShortcutInfo        = 'Keyboard shortcuts'
        ProcSearch          = 'Search processes'
        ProcThreads         = 'THREADS'
        ProcAuto            = 'Auto refresh'
        TipProcAuto         = 'Refresh the list every 2.5 seconds - selection and scroll stay put'
        ProcKill            = 'Kill Process'
        BenchTitle          = 'System Benchmark'
        BenchCPU            = 'CPU Test'
        BenchRAM            = 'RAM Test'
        BenchDisk           = 'Disk Test'
        Search              = 'Search'
        StartUser           = 'User'
        StartSystem         = 'System'

        TweakAnimations     = 'Disable Animations'
        TweakSysMain        = 'Disable Superfetch (SysMain)'
        TweakFastStart      = 'Enable Fast Startup'
        TweakThrottling     = 'Disable Network Throttling'
        TweakParking        = 'Disable Core Parking'
        TweakPriority       = 'Gaming Priority Boost'
        TweakDebloat        = 'System De-bloat (Telemetry off)'
        TweakSearchIdx      = 'Disable Search Indexing'
        TweakHibernate      = 'Disable Hibernate'
        TweakBgApps         = 'Disable Background Apps'
        TweakTips           = 'Disable Tips & Notifications'
        TweakTransparency   = 'Disable Transparency Effects'

        GameMouseAccel      = 'Disable Mouse Acceleration'
        GameMouseAccelDesc  = 'Raw mouse input for precision'
        GameFullscreen      = 'Fullscreen Optimizations Off'
        GameFullscreenDesc  = 'Less input lag in games'
        GameHPET            = 'Disable HPET'
        GameHPETDesc        = 'Lower timer latency (restart needed)'

        DiskWUCache         = 'Windows Update Cache'
        DiskWUCacheDesc     = 'Delete update download files'
        DiskThumbnails      = 'Thumbnail Cache'
        DiskThumbnailsDesc  = 'Clear thumbnail cache files'

        NetDNS              = 'DNS Optimization'
        NetDNSDesc          = 'Set fast DNS servers'
        NetNagle            = 'Nagle Algorithm Off'
        NetNagleDesc        = 'Less packet buffering delay'
        NetWinsock          = 'Winsock Reset'
        NetWinsockDesc      = 'Reset the network stack'
        NetPing             = 'Ping Test'
        NetPingDesc         = 'Measure latency to google.com'
        NetSpeed            = 'Speedtest'
        NetSpeedDesc        = 'Open speedtest.net in browser'

        PrivLocation        = 'Disable Location Tracking'
        PrivWiFiSense       = 'Disable WiFi Sense'
        PrivClipboard       = 'Disable Clipboard History'
        PrivDiagnostics     = 'Disable App Diagnostics'
        PrivTailored        = 'Disable Tailored Experiences'
        PrivTimeline        = 'Disable Timeline'

        RepairCHKDSK        = 'Disk Check'
        RepairCHKDSKDesc    = 'CHKDSK disk analysis'
        RepairComponent     = 'Component Cleanup'
        RepairComponentDesc = 'Clean up Windows component store'
        RepairNetwork       = 'Network Reset'
        RepairNetworkDesc   = 'Reset network adapters and stack'
        RepairExplorer      = 'Restart Explorer'
        RepairExplorerDesc  = 'Restart Windows Explorer'
        RepairWU            = 'Windows Update Reset'
        RepairWUDesc        = 'Reset update components'

        UpdPause            = 'Pause Updates'
        UpdPauseDesc        = 'Hold Windows Update for 7 days'
        UpdResume           = 'Resume Updates'
        UpdResumeDesc       = 'Remove the update pause'
        UpdRepair           = 'Repair Update Services'
        UpdRepairDesc       = 'Restart services & clear cache'

        ContextTitle        = 'Context Menu Manager'
        ContextSubtitle     = 'Shell extensions & legacy menus'
        MenuContext         = 'Context Menu'
        ClassicMenu         = 'Classic Menu'
        ClassicMenuDesc     = 'Win 10 style menu in Win 11'
        ModernMenu          = 'Modern Menu'
        ModernMenuDesc      = 'Standard Windows 11 menu'
        HideShare           = 'Hide Access'
        HideShareDesc       = 'Remove "Give access to"'

        MenuInput           = 'Input Tuning'
        InputTitle          = 'Input Optimization'
        InputSubtitle       = 'Latency & FilterKeys Tuning'
        FilterKeys          = 'FilterKeys Boost'
        FilterKeysDesc      = 'Optimize keyboard response time'
        RepairTitle         = 'Repair Center'
        RepairSubtitle      = 'System self-healing & scans'
        SysScan             = 'System Scan'
        SysScanDesc         = 'Run SFC & DISM repair engine'

        RegMui              = 'Clean MUI Cache'
        RegRecent           = 'Recent Documents'
        RegRunMRU           = 'Run History'
        RegTyped            = 'Typed Paths'
    }

    'TR' = @{
        Name                = 'Türkçe'
        Flag                = '{icon:flag}'
        Welcome             = 'Hoş geldiniz'
        Ready               = 'Sistem hazır'
        Loading             = 'Yükleniyor...'
        Success             = 'Başarılı'
        Error               = 'Hata'
        Warning             = 'Uyarı'
        Info                = 'Bilgi'
        Yes                 = 'Evet'
        No                  = 'Hayır'
        OK                  = 'Tamam'
        Cancel              = 'İptal'
        Close               = 'Kapat'
        Refresh             = 'Yenile'
        Export              = 'Dışa Aktar'
        Import              = 'İçe Aktar'
        Start               = 'Başlat'
        Stop                = 'Durdur'
        Enable              = 'Etkinleştir'
        Disable             = 'Devre Dışı'
        Delete              = 'Sil'
        Clean               = 'Temizle'
        Optimize            = 'Optimize Et'
        Apply               = 'Uygula'
        Confirm             = 'Onayla'
        Reset               = 'Sıfırla'
        Restart             = 'Yeniden Başlat'
        Restore             = 'Geri Yükle'
        Analyze             = 'Analiz Et'
        ServiceSearch       = 'Hizmet Ara'
        RestorePoint        = 'Geri Yükleme Noktası'
        RestorePointDesc    = 'Sistem geri yükleme noktası oluştur'
        RPCreating          = 'Geri yükleme noktası oluşturuluyor...'
        RPError             = 'Geri yükleme noktası oluşturulamadı'
        RPDisabled          = 'Sistem geri yükleme ilkeyle devre dışı bırakıldı'
        RPNotCreated        = 'Geri yükleme noktası oluşturulmadı - Windows 24 saatte yalnızca bir tanesine izin verir'
        RPRetry             = 'Zaman siniri geçici olarak kaldırıldı, ikinci deneme'
        RPVerified          = 'Geri yükleme noktası doğrulandı'
        Protected           = 'Korumalı öğe - işlem engellendi'

        MenuDashboard       = 'Gösterge Paneli'
        MenuHardware        = 'Donanım Bilgisi'
        MenuDisk            = 'Disk Temizleyici'
        MenuGaming          = 'Oyun Modu'
        MenuPrivacy         = 'Gizlilik'
        MenuDefender        = 'Defender Dışlamaları'
        MenuServices        = 'Hizmetler'
        MenuStartup         = 'Başlangıç'
        MenuUpdates         = 'Güncellemeler'
        MenuNetwork         = 'Ağ'
        MenuRepair          = 'Onarım'
        MenuProcesses       = 'İşlemler'
        MenuRegistry        = 'Kayıt Defteri'
        MenuBenchmark       = 'Kıyaslama'
        MenuTweaks          = 'İnce Ayarlar'
        MenuSettings        = 'Ayarlar'
        MenuTasks           = 'Zamanlanmış Görevler'

        ServicesSubtitle    = 'Windows hizmetlerini yönet'
        StartupSubtitle     = 'Başlangıç öğelerini yönet'
        TasksSubtitle       = 'Zamanlanmış görevleri yönet'
        UpdatesSubtitle     = 'Windows Update kontrolü'
        NetworkSubtitle     = 'Bağlantıyı optimize et ve onar'
        ProcSubtitle        = 'Çalışan işlemleri izle'
        RegistrySubtitle    = 'Kayıt defteri artıklarını temizle'
        TweaksSubtitle      = 'Sistem ince ayarı'
        SettingsSubtitle    = 'Dil ve uygulama bilgisi'

        CatMain             = 'ANA MENÜ'
        CatOptimize         = 'OPTİMİZASYON'
        CatSecurity         = 'GÜVENLİK'
        CatSystem           = 'SİSTEM'
        CatAdvanced         = 'GELİŞMİŞ'

        DashTitle           = 'Gösterge Paneli'
        DashSubtitle        = 'Gerçek zamanlı sistem izlemesi'
        BenchSubtitle       = 'Sistem performansını test et'
        DashCPU             = 'CPU KULLANIMI'
        DashRAM             = 'RAM KULLANIMI'
        DashHealth          = 'SISTEM DURUMU'
        DashHealthDesc      = "Performans verimlilik duzeyi.`n%100 hedefleyin."
        DashHealthOptimal   = 'En iyi'
        DashHealthTune      = 'Ayar gerekli'
        DashNetTitle        = 'AG TELEMETRISI'
        DashDisk            = 'DEPOLAMA'
        DashProcs           = 'İŞLEMLER'
        DashQuick           = 'HIZLI İŞLEMLER'

        QuickClean          = 'Hızlı Temizlik'
        QuickCleanDesc      = 'Geçici dosyaları ve önbelleği temizle'
        QuickRAM            = 'RAM Optimize'
        QuickRAMDesc        = 'Belleği boşalt'
        QuickDNS            = 'DNS Temizle'
        QuickDNSDesc        = 'DNS önbelleğini temizle'
        QuickExplorer       = 'Explorer Yenile'
        QuickExplorerDesc   = "Windows Gezgini'ni yeniden başlat"
        QuickAuto           = 'Oto-Optimize'
        QuickAutoDesc       = 'Tam sistem bakımı'

        HWTitle             = 'Donanım Bilgisi'
        HWSubtitle          = 'Sistem özellikleri'
        HWProcessor         = 'İŞLEMCİ'
        HWGraphics          = 'EKRAN KARTI'
        HWMemory            = 'BELLEK'
        HWStorage           = 'DEPOLAMA'
        HWOS                = 'İŞLETİM SİSTEMİ'

        DiskTitle           = 'Disk Temizleyici'
        DiskSubtitle        = 'Depolama alanı açın'
        DiskTemp            = 'Geçici Dosyalar'
        DiskTempDesc        = 'Geçici sistem dosyalarını sil'
        DiskBrowser         = 'Tarayıcı Önbelleği'
        DiskBrowserDesc     = 'Chrome ve Edge önbelleğini temizle'
        DiskLogs            = 'Windows Günlükleri'
        DiskLogsDesc        = 'Olay günlüklerini temizle'
        DiskRecycle         = 'Geri Dönüşüm Kutusu'
        DiskRecycleDesc     = 'Geri dönüşüm kutusunu boşalt'
        DiskDeep            = 'Derin Temizlik'
        DiskDeepDesc        = 'Güncelleme önbelleği ve prefetch temizliği'
        DiskTotal           = 'Toplam temizlenen'

        GameTitle           = 'Oyun Modu'
        GameSubtitle        = 'Oyunlar için maksimum performans'
        GamePower           = 'Güç Planı'
        GamePowerDesc       = 'Ultimate Performance etkinleştir'
        GameMode            = 'Oyun Modu'
        GameModeDesc        = 'Windows Oyun Modunu aç'
        GameTCP             = 'TCP Optimizasyonu'
        GameTCPDesc         = 'Ağ gecikmesini azalt'
        GameGPU             = 'GPU Zamanlama'
        GameGPUDesc         = 'Donanım hızlandırmalı GPU zamanlama'
        GameDVR             = 'GameDVR Kapat'
        GameDVRDesc         = 'Arka plan kaydını kapat'
        GameMega            = 'MEGA OYUN MODU'
        GameMegaDesc        = 'Tüm optimizasyonları etkinleştir'

        PrivTitle           = 'Gizlilik'
        PrivSubtitle        = 'Telemetri ve izlemeyi kontrol et'
        PrivApplyAll        = 'Tümünü Uygula'
        PrivTelemetry       = 'Telemetriyi Kapat'
        PrivAds             = 'Reklam Kimliğini Kapat'
        PrivCortana         = "Cortana'yı Kapat"
        PrivFeedback        = 'Geri Bildirimi Kapat'
        PrivBing            = 'Bing Aramasını Kapat'
        PrivActivity        = 'Etkinlik Akışını Kapat'

        DlgConfirm          = 'Onay'
        DlgWarning          = 'Uyarı'
        DlgRisk             = 'Riski anlıyorum'
        DlgContinue         = 'Devam Et'
        DlgCompleted        = 'Tamamlandı'
        DlgBackupCreated    = 'Yedek oluşturuldu'
        DlgRestartReq       = 'Yeniden başlatma gerekli'

        DefTitle            = 'Defender Dışlamaları'
        DefSubtitle         = 'Dışlama listelerini yönet'
        DefAddPath          = 'Yol Ekle'
        DefAddProcess       = 'İşlem Ekle'
        DefRemove           = 'Kaldır'
        DefType             = 'Tip'
        DefValue            = 'Değer'

        StatusBackup        = 'Oto-Yedekleme Aktif'
        ShortcutInfo        = 'Klavye kısayolları'
        ProcSearch          = 'İşlem ara'
        ProcThreads         = 'İŞ PARÇACIĞI'
        ProcAuto            = 'Otomatik'
        TipProcAuto         = 'Listeyi her 2,5 saniyede bir yenile - secim ve kaydirma korunur'
        ProcKill            = 'İşlemi Sonlandır'
        BenchTitle          = 'Sistem Kıyaslaması'
        BenchCPU            = 'CPU Testi'
        BenchRAM            = 'RAM Testi'
        BenchDisk           = 'Disk Testi'
        Search              = 'Ara'
        StartUser           = 'Kullanıcı'
        StartSystem         = 'Sistem'

        TweakAnimations     = 'Animasyonları Kapat'
        TweakSysMain        = 'Superfetch (SysMain) Kapat'
        TweakFastStart      = 'Hızlı Başlatmayı Aç'
        TweakThrottling     = 'Ağ Kısıtlamasını Kapat'
        TweakParking        = 'Çekirdek Park Etmeyi Kapat'
        TweakPriority       = 'Oyun Önceliği Artır'
        TweakDebloat        = 'Sistemi Sadeleştir (Telemetri Kapat)'
        TweakSearchIdx      = 'Arama Dizinini Kapat'
        TweakHibernate      = 'Hazırda Bekletmeyi Kapat'
        TweakBgApps         = 'Arka Plan Uygulamalarını Kapat'
        TweakTips           = 'İpucu ve Bildirimleri Kapat'
        TweakTransparency   = 'Saydamlık Efektlerini Kapat'

        GameMouseAccel      = 'Fare Hızlandırmayı Kapat'
        GameMouseAccelDesc  = 'Hassasiyet için ham fare verisi'
        GameFullscreen      = 'Tam Ekran Optimizasyonu Kapat'
        GameFullscreenDesc  = 'Oyunlarda daha az giriş gecikmesi'
        GameHPET            = "HPET'i Devre Dışı Bırak"
        GameHPETDesc        = 'Düşük zamanlayıcı gecikmesi (yeniden başlatma gerekli)'

        DiskWUCache         = 'Windows Güncelleme Önbelleği'
        DiskWUCacheDesc     = 'Güncelleme indirme dosyalarını sil'
        DiskThumbnails      = 'Küçük Resim Önbelleği'
        DiskThumbnailsDesc  = 'Küçük resim önbellek dosyalarını temizle'

        NetDNS              = 'DNS Optimizasyonu'
        NetDNSDesc          = 'Hızlı DNS sunucusu ayarla'
        NetNagle            = 'Nagle Algoritmasını Kapat'
        NetNagleDesc        = 'Daha az paket arabellekleme gecikmesi'
        NetWinsock          = 'Winsock Sıfırlama'
        NetWinsockDesc      = 'Ağ yığınını sıfırla'
        NetPing             = 'Ping Testi'
        NetPingDesc         = "google.com gecikmesini ölç"
        NetSpeed            = 'Hız Testi'
        NetSpeedDesc        = 'Tarayıcıda speedtest.net aç'

        PrivLocation        = 'Konum Takibini Kapat'
        PrivWiFiSense       = 'WiFi Sense Kapat'
        PrivClipboard       = 'Pano Geçmişini Kapat'
        PrivDiagnostics     = 'Uygulama Teşhisini Kapat'
        PrivTailored        = 'Kişisel Deneyimleri Kapat'
        PrivTimeline        = 'Zaman Çizelgesini Kapat'

        RepairCHKDSK        = 'Disk Kontrolü'
        RepairCHKDSKDesc    = 'CHKDSK disk analizi'
        RepairComponent     = 'Bileşen Temizliği'
        RepairComponentDesc = 'Windows bileşen deposunu temizle'
        RepairNetwork       = 'Ağ Sıfırlama'
        RepairNetworkDesc   = 'Ağ bağdaştırıcılarını sıfırla'
        RepairExplorer      = 'Explorer Yeniden Başlat'
        RepairExplorerDesc  = 'Windows Explorer yeniden başlat'
        RepairWU            = 'Windows Update Sıfırlama'
        RepairWUDesc        = 'Güncelleme bileşenlerini sıfırla'

        UpdPause            = 'Güncellemeleri Duraklat'
        UpdPauseDesc        = 'Windows Update 7 gün beklet'
        UpdResume           = 'Güncellemeleri Sürdür'
        UpdResumeDesc       = 'Duraklatmayı kaldır'
        UpdRepair           = 'Güncelleme Servislerini Onar'
        UpdRepairDesc       = 'Servisleri yeniden başlat ve önbelleği temizle'

        ContextTitle        = 'Bağlam Menüsü Yöneticisi'
        ContextSubtitle     = 'Kabuk uzantıları ve eski menüler'
        MenuContext         = 'Bağlam Menüsü'
        ClassicMenu         = 'Klasik Menü'
        ClassicMenuDesc     = 'Win 11 de Win 10 tarzı menü'
        ModernMenu          = 'Modern Menü'
        ModernMenuDesc      = 'Standart Windows 11 menüsü'
        HideShare           = 'Erişimi Gizle'
        HideShareDesc       = '"Erişim ver" seçeneğini kaldır'

        MenuInput           = 'Giriş Ayarı'
        InputTitle          = 'Giriş Optimizasyonu'
        InputSubtitle       = 'Gecikme & FilterKeys Ayarı'
        FilterKeys          = 'FilterKeys Hızlandırma'
        FilterKeysDesc      = 'Klavye tepki süresini optimize et'
        RepairTitle         = 'Onarım Merkezi'
        RepairSubtitle      = 'Sistem kendi kendini onarma & tarama'
        SysScan             = 'Sistem Taraması'
        SysScanDesc         = 'SFC & DISM onarım motorunu çalıştır'

        RegMui              = 'MUI Önbelleğini Temizle'
        RegRecent           = 'Son Belgeler'
        RegRunMRU           = 'Çalıştır Geçmişi'
        RegTyped            = 'Yazılan Yollar'
    }

    'AR' = @{
        Name                = 'العربية'
        Flag                = '{icon:flag}'
        Welcome             = 'مرحباً'
        Ready               = 'النظام جاهز'
        Loading             = 'جاري التحميل...'
        Success             = 'نجاح'
        Error               = 'خطأ'
        Warning             = 'تحذير'
        Info                = 'معلومات'
        Yes                 = 'نعم'
        No                  = 'لا'
        OK                  = 'موافق'
        Cancel              = 'إلغاء'
        Close               = 'إغلاق'
        Refresh             = 'تحديث'
        Export              = 'تصدير'
        Import              = 'استيراد'
        Start               = 'بدء'
        Stop                = 'إيقاف'
        Enable              = 'تفعيل'
        Disable             = 'تعطيل'
        Delete              = 'حذف'
        Clean               = 'تنظيف'
        Optimize            = 'تحسين'
        Apply               = 'تطبيق'
        Confirm             = 'تأكيد'
        Reset               = 'إعادة تعيين'
        Restart             = 'إعادة تشغيل'
        Restore             = 'استعادة'
        Analyze             = 'تحليل'
        ServiceSearch       = 'بحث عن الخدمات'
        RestorePoint        = 'نقطة استعادة'
        RestorePointDesc    = 'إنشاء نقطة استعادة للنظام'
        RPCreating          = 'جاري إنشاء نقطة الاستعادة...'
        RPError             = 'فشل في إنشاء نقطة الاستعادة'
        RPDisabled          = 'استعادة النظام معطلة بواسطة نهج المجموعة'
        RPNotCreated        = 'لم يتم إنشاء نقطة استعادة - يسمح Windows بواحدة فقط كل 24 ساعة'
        RPRetry             = 'تم رفع حد الوقت مؤقتا، محاولة ثانية'
        RPVerified          = 'تم التحقق من نقطة الاستعادة'
        Protected           = 'عنصر محمي - تم منع الإجراء'

        MenuDashboard       = 'لوحة التحكم'
        MenuHardware        = 'معلومات الجهاز'
        MenuDisk            = 'منظف القرص'
        MenuGaming          = 'وضع الألعاب'
        MenuPrivacy         = 'الخصوصية'
        MenuDefender        = 'استثناءات الحماية'
        MenuServices        = 'الخدمات'
        MenuStartup         = 'بدء التشغيل'
        MenuUpdates         = 'التحديثات'
        MenuNetwork         = 'الشبكة'
        MenuRepair          = 'الإصلاح'
        MenuProcesses       = 'العمليات'
        MenuRegistry        = 'السجل'
        MenuBenchmark       = 'اختبار الأداء'
        MenuTweaks          = 'تعديلات'
        MenuSettings        = 'الإعدادات'
        MenuTasks           = 'المهام المجدولة'

        ServicesSubtitle    = 'إدارة خدمات ويندوز'
        StartupSubtitle     = 'إدارة عناصر بدء التشغيل'
        TasksSubtitle       = 'إدارة المهام المجدولة'
        UpdatesSubtitle     = 'التحكم في تحديثات ويندوز'
        NetworkSubtitle     = 'تحسين وإصلاح الاتصال'
        ProcSubtitle        = 'مراقبة العمليات الجارية'
        RegistrySubtitle    = 'تنظيف بقايا السجل'
        TweaksSubtitle      = 'ضبط دقيق للنظام'
        SettingsSubtitle    = 'اللغة ومعلومات التطبيق'

        CatMain             = 'القائمة الرئيسية'
        CatOptimize         = 'التحسين'
        CatSecurity         = 'الأمان'
        CatSystem           = 'النظام'
        CatAdvanced         = 'متقدم'

        DashTitle           = 'لوحة التحكم'
        DashSubtitle        = 'مراقبة النظام في الوقت الحقيقي'
        BenchSubtitle       = 'اختبار أداء النظام'
        DashCPU             = 'استخدام المعالج'
        DashRAM             = 'استخدام الذاكرة'
        DashHealth          = 'حالة النظام'
        DashHealthDesc      = "مستوى كفاءة الأداء.`nحسن الأداء للوصول إلى 100%."
        DashHealthOptimal   = 'مثالي'
        DashHealthTune      = 'يلزم الضبط'
        DashNetTitle        = 'قياس الشبكة'
        DashDisk            = 'التخزين'
        DashProcs           = 'العمليات'
        DashQuick           = 'إجراءات سريعة'

        QuickClean          = 'تنظيف سريع'
        QuickCleanDesc      = 'تنظيف الملفات المؤقتة والذاكرة المخبأة'
        QuickRAM            = 'تحسين الذاكرة'
        QuickRAMDesc        = 'تحرير الذاكرة العشوائية'
        QuickDNS            = 'تنظيف DNS'
        QuickDNSDesc        = 'مسح ذاكرة التخزين المؤقت لـ DNS'
        QuickExplorer       = 'إعادة تشغيل المستكشف'
        QuickExplorerDesc   = 'إعادة تشغيل مستكشف الملفات'
        QuickAuto           = 'تحسين تلقائي'
        QuickAutoDesc       = 'صيانة شاملة للنظام'

        HWTitle             = 'معلومات الجهاز'
        HWSubtitle          = 'مواصفات النظام'
        HWProcessor         = 'المعالج'
        HWGraphics          = 'بطاقة الرسومات'
        HWMemory            = 'الذاكرة'
        HWStorage           = 'التخزين'
        HWOS                = 'نظام التشغيل'

        DiskTitle           = 'منظف القرص'
        DiskSubtitle        = 'تحرير مساحة التخزين'
        DiskTemp            = 'الملفات المؤقتة'
        DiskTempDesc        = 'حذف ملفات النظام المؤقتة'
        DiskBrowser         = 'ذاكرة المتصفح'
        DiskBrowserDesc     = 'مسح ذاكرة كروم وإيدج'
        DiskLogs            = 'سجلات ويندوز'
        DiskLogsDesc        = 'مسح سجلات الأحداث'
        DiskRecycle         = 'سلة المحذوفات'
        DiskRecycleDesc     = 'إفراغ سلة المحذوفات'
        DiskDeep            = 'تنظيف عميق'
        DiskDeepDesc        = 'مسح ذاكرة التحديث و Prefetch'
        DiskTotal           = 'إجمالي المساحة المحررة'

        GameTitle           = 'وضع الألعاب'
        GameSubtitle        = 'أقصى أداء للألعاب'
        GamePower           = 'خطة الطاقة'
        GamePowerDesc       = 'تفعيل الأداء الفائق'
        GameMode            = 'وضع اللعب'
        GameModeDesc        = 'تشغيل وضع ألعاب ويندوز'
        GameTCP             = 'تحسين TCP'
        GameTCPDesc         = 'تقليل زمن استجابة الشبكة'
        GameGPU             = 'جدولة GPU'
        GameGPUDesc         = 'جدولة GPU بتسريع عتادي'
        GameDVR             = 'إيقاف GameDVR'
        GameDVRDesc         = 'تعطيل التسجيل في الخلفية'
        GameMega            = 'وضع الألعاب الخارق'
        GameMegaDesc        = 'تفعيل جميع التحسينات'

        PrivTitle           = 'الخصوصية'
        PrivSubtitle        = 'التحكم في التتبع والقياس عن بعد'
        PrivApplyAll        = 'تطبيق الكل'
        PrivTelemetry       = 'تعطيل القياس عن بعد'
        PrivAds             = 'تعطيل معرّف الإعلانات'
        PrivCortana         = 'تعطيل كورتانا'
        PrivFeedback        = 'تعطيل الملاحظات'
        PrivBing            = 'تعطيل بحث بينغ'
        PrivActivity        = 'تعطيل سجل النشاط'

        DlgConfirm          = 'تأكيد'
        DlgWarning          = 'تحذير'
        DlgRisk             = 'أنا أتفهم المخاطر'
        DlgContinue         = 'متابعة'
        DlgCompleted        = 'اكتمل'
        DlgBackupCreated    = 'تم إنشاء النسخة الاحتياطية'
        DlgRestartReq       = 'يلزم إعادة التشغيل'

        DefTitle            = 'استثناءات الحماية'
        DefSubtitle         = 'إدارة قوائم الاستثناءات'
        DefAddPath          = 'إضافة مسار'
        DefAddProcess       = 'إضافة عملية'
        DefRemove           = 'إزالة'
        DefType             = 'النوع'
        DefValue            = 'القيمة'

        StatusBackup        = 'النسخ الاحتياطي نشط'
        ShortcutInfo        = 'اختصارات لوحة المفاتيح'
        ProcSearch          = 'البحث عن العمليات'
        ProcThreads         = 'خيوط المعالجة'
        ProcAuto            = 'تحديث تلقائي'
        TipProcAuto         = 'تحديث القائمة كل 2.5 ثانية - يبقى التحديد وموضع التمرير كما هما'
        ProcKill            = 'إنهاء العملية'
        BenchTitle          = 'اختبار الأداء'
        BenchCPU            = 'اختبار المعالج'
        BenchRAM            = 'اختبار الذاكرة'
        BenchDisk           = 'اختبار القرص'
        Search              = 'بحث'
        StartUser           = 'مستخدم'
        StartSystem         = 'نظام'

        TweakAnimations     = 'تعطيل الرسوم المتحركة'
        TweakSysMain        = 'تعطيل Superfetch (SysMain)'
        TweakFastStart      = 'تفعيل البدء السريع'
        TweakThrottling     = 'تعطيل خنق الشبكة'
        TweakParking        = 'تعطيل إيقاف الأنوية'
        TweakPriority       = 'تعزيز أولوية الألعاب'
        TweakDebloat        = 'إزالة البرامج غير الضرورية (تعطيل التتبع)'
        TweakSearchIdx      = 'تعطيل فهرسة البحث'
        TweakHibernate      = 'تعطيل الإسبات'
        TweakBgApps         = 'تعطيل تطبيقات الخلفية'
        TweakTips           = 'تعطيل النصائح والإشعارات'
        TweakTransparency   = 'تعطيل تأثيرات الشفافية'

        GameMouseAccel      = 'تعطيل تسريع الفأرة'
        GameMouseAccelDesc  = 'بيانات فأرة خام للدقة'
        GameFullscreen      = 'تعطيل تحسينات ملء الشاشة'
        GameFullscreenDesc  = 'تأخير إدخال أقل في الألعاب'
        GameHPET            = 'تعطيل HPET'
        GameHPETDesc        = 'زمن استجابة أقل (يلزم إعادة التشغيل)'

        DiskWUCache         = 'ذاكرة تحديث ويندوز'
        DiskWUCacheDesc     = 'حذف ملفات التحديث المحملة'
        DiskThumbnails      = 'ذاكرة الصور المصغرة'
        DiskThumbnailsDesc  = 'مسح ملفات ذاكرة الصور المصغرة'

        NetDNS              = 'تحسين DNS'
        NetDNSDesc          = 'ضبط خوادم DNS سريعة'
        NetNagle            = 'تعطيل خوارزمية Nagle'
        NetNagleDesc        = 'تأخير أقل في تخزين الحزم'
        NetWinsock          = 'إعادة تعيين Winsock'
        NetWinsockDesc      = 'إعادة تعيين حزمة الشبكة'
        NetPing             = 'اختبار Ping'
        NetPingDesc         = 'قياس زمن الوصول إلى google.com'
        NetSpeed            = 'اختبار السرعة'
        NetSpeedDesc        = 'فتح speedtest.net في المتصفح'

        PrivLocation        = 'تعطيل تتبع الموقع'
        PrivWiFiSense       = 'تعطيل WiFi Sense'
        PrivClipboard       = 'تعطيل سجل الحافظة'
        PrivDiagnostics     = 'تعطيل تشخيص التطبيقات'
        PrivTailored        = 'تعطيل التجارب المخصصة'
        PrivTimeline        = 'تعطيل الخط الزمني'

        RepairCHKDSK        = 'فحص القرص'
        RepairCHKDSKDesc    = 'تحليل CHKDSK للقرص'
        RepairComponent     = 'تنظيف المكونات'
        RepairComponentDesc = 'تنظيف مخزن مكونات ويندوز'
        RepairNetwork       = 'إعادة تعيين الشبكة'
        RepairNetworkDesc   = 'إعادة تعيين محولات الشبكة'
        RepairExplorer      = 'إعادة تشغيل المستكشف'
        RepairExplorerDesc  = 'إعادة تشغيل مستكشف ويندوز'
        RepairWU            = 'إعادة تعيين تحديث ويندوز'
        RepairWUDesc        = 'إعادة تعيين مكونات التحديث'

        UpdPause            = 'إيقاف التحديثات مؤقتاً'
        UpdPauseDesc        = 'إيقاف تحديث ويندوز لمدة 7 أيام'
        UpdResume           = 'استئناف التحديثات'
        UpdResumeDesc       = 'إلغاء الإيقاف المؤقت'
        UpdRepair           = 'إصلاح خدمات التحديث'
        UpdRepairDesc       = 'إعادة تشغيل الخدمات ومسح الذاكرة'

        ContextTitle        = 'مدير قائمة السياق'
        ContextSubtitle     = 'إضافات الشل والقوائم الكلاسيكية'
        MenuContext         = 'قائمة السياق'
        ClassicMenu         = 'القائمة الكلاسيكية'
        ClassicMenuDesc     = 'نمط ويندوز 10 في ويندوز 11'
        ModernMenu          = 'القائمة الحديثة'
        ModernMenuDesc      = 'قائمة ويندوز 11 الافتراضية'
        HideShare           = 'إخفاء المشاركة'
        HideShareDesc       = 'إزالة "منح حق الوصول"'

        MenuInput           = 'ضبط الإدخال'
        InputTitle          = 'تحسين الإدخال'
        InputSubtitle       = 'ضبط زمن الاستجابة ومفاتيح التصفية'
        FilterKeys          = 'تسريع مفاتيح التصفية'
        FilterKeysDesc      = 'تحسين زمن استجابة لوحة المفاتيح'
        RepairTitle         = 'مركز الإصلاح'
        RepairSubtitle      = 'الإصلاح الذاتي للنظام والفحص'
        SysScan             = 'فحص النظام'
        SysScanDesc         = 'تشغيل محرك إصلاح SFC و DISM'

        RegMui              = 'تنظيف ذاكرة MUI'
        RegRecent           = 'المستندات الأخيرة'
        RegRunMRU           = 'سجل تشغيل الأوامر'
        RegTyped            = 'المسارات المكتوبة'
    }
}

$script:CurrentLangDict = $script:Languages[$script:Config.CurrentLang]

# Additional keys for the settings persistence, merged into every language so
# the big tables above stay untouched.
$script:ExtraStrings = @{
    DE = @{
        ChgDefender    = 'Defender-Ausnahme'
        DiskBrowserOpen = 'Browser laeuft noch und haelt den Zwischenspeicher offen'
        DiskAllLocked   = 'Alle Dateien sind in Benutzung - nichts geloescht'
        CtWuLog   = 'Update-Protokolle'
        CtShader  = 'Shader-Zwischenspeicher der Grafikkarte'
        CtPanther = 'Setup-Protokolle - werden zur Fehlersuche nach einem Funktionsupdate gebraucht'
        CtDump    = 'Absturzabbilder - ohne sie laesst sich ein Blauer Bildschirm nicht mehr auswerten'
        CtRecycle = 'Papierkorb - die Dateien sind danach endgueltig weg'
        TskLastRun     = 'Letzter Lauf'
        TskResult      = 'Ergebnis'
        TskHidden      = 'Windows-Aufgaben ausgeblendet'
        TskShowWin     = 'Windows-Aufgaben'
        TskShowWinTip  = 'Aufgaben unter \Microsoft ein- oder ausblenden'
        TskRunDisabled = 'Aufgabe ist deaktiviert - erst aktivieren'
        TskRunning     = 'Laeuft bereits'
        TskResOk       = 'Erfolgreich'
        TskResError    = 'Fehler'
        TskResNotFound = 'Datei nicht gefunden'
        TskResReady    = 'Bereit'
        TskResRunning  = 'Laeuft'
        TskResDisabled = 'Deaktiviert'
        TskResNever    = 'Nie gelaufen'
        TskResStopped  = 'Abgebrochen'
        TskResUnknown  = 'Unbekannt'
        SvcAuto          = 'Automatisch'
        SvcAutoDelayed   = 'Automatisch (verzoegert)'
        SvcManual        = 'Manuell'
        SvcDisabled      = 'Deaktiviert'
        SvcBoot          = 'Systemstart'
        SvcSystem        = 'System'
        SvcStartDisabled = 'Dienst ist deaktiviert - erst aktivieren'
        SvcStillRunning  = 'Laeuft bis zum naechsten Neustart weiter'
        SvcDependents    = 'Wird mit angehalten'
        SvcDependentsAsk = 'Diese laufenden Dienste haengen davon ab und werden mit angehalten:'
        ProcHung        = 'Reagiert nicht'
        ProcOk          = 'Laeuft'
        ProcNoSelection = 'Kein Prozess ausgewaehlt'
        ProcKillAsk     = 'Diese Prozesse samt Kindprozessen beenden? Nicht gespeicherte Daten gehen verloren.'
        Start32        = 'System (32-Bit)'
        StartOnce      = 'Einmalig'
        StartCommon    = 'Alle Benutzer'
        StartFolder    = 'Ordner'
        StuEnabled     = 'Aktiv'
        StuDisabled    = 'Deaktiviert'
        StuMissing     = 'Ziel fehlt'
        StuNoToggle    = 'laesst sich nicht abschalten'
        StuNoChange    = 'bereits im gewuenschten Zustand'
        StuNoEntry     = 'kein gueltiger Eintrag'
        StuNoSelection = 'Nichts ausgewaehlt'
        HWBattery     = 'AKKU'
        HWSecurity    = 'SICHERHEIT'
        LblCharge     = 'Ladestand'
        LblWear       = 'Verschleiss'
        LblDesign     = 'Auslegung'
        LblFullCharge = 'Volladung'
        LblSlots      = 'Steckplaetze'
        LblConfigured = 'Takt aktiv'
        LblTpm        = 'TPM'
        LblSecureBoot = 'Secure Boot'
        HwUnknown     = 'nicht ermittelbar'
        HwXmpHint     = 'unter Nennwert, XMP/EXPO nicht aktiv'
        HwActive      = 'aktiv'
        HwInactive    = 'inaktiv'
        HwOnBattery   = 'Akkubetrieb'
        HwExportBusy  = 'Daten werden noch geladen - Ausfuhr erst danach moeglich'
        HealthDefRt   = 'Echtzeitschutz ausgeschaltet'
        HealthDefSig  = 'Virensignaturen veraltet'
        HealthRestore = 'Kein aktueller Wiederherstellungspunkt'
        HealthUptime  = 'Laufzeit ohne Neustart'
        HealthMore    = 'weitere Posten'
        HealthAction  = 'Handlungsbedarf'
        UpdPaused        = 'Updates pausiert bis'
        UpdNotPaused     = 'Updates sind nicht pausiert'
        UpdPauseDays     = 'Tage'
        UpdPauseUntil    = 'Pause bis'
        UpdPauseMax      = 'Windows nimmt hoechstens 35 Tage an - danach laufen die Updates von selbst wieder an'
        UpdPauseConfirm  = 'Windows-Updates jetzt pausieren?'
        UpdResumeConfirm = 'Updates wieder freigeben?'
        UpdResumed       = 'Updates wieder freigegeben'
        UpdExpired       = 'Die letzte Pause ist abgelaufen'
        UpdSvcStop       = 'Dienst laesst sich nicht beenden'
        UpdSvcStopping   = 'Dienste werden angehalten'
        UpdSvcStarting   = 'Dienste werden gestartet'
        UpdSvcRestart    = 'Dienste wieder gestartet'
        UpdRepairAbort   = 'Reparatur abgebrochen - es wurde nichts veraendert'
        UpdRepairWarn    = 'Der Update-Zwischenspeicher wird umbenannt. Der Updateverlauf verschwindet, die naechste Suche dauert einmalig laenger und mehrere hundert Megabyte werden erneut geladen. Die Ordner bleiben als .old liegen und lassen sich ueber Rueckgaengig zurueckholen.'
        UpdLeftovers     = 'Alte Reparaturordner'
        UpdCleanOld      = 'Jetzt entfernen?'
        BenchRunning    = 'Eine Messung laeuft bereits'
        BenchWarmup     = 'Aufwaermlauf'
        BenchSpread     = 'Streuung'
        BenchSingle     = 'Einzelkern'
        BenchUnstable   = 'Die Durchlaeufe weichen stark voneinander ab - der Rechner war waehrend der Messung beschaeftigt'
        BenchBusyWarn   = 'CPU-Last vor dem Start zu hoch - abwarten gibt vergleichbare Werte'
        BenchCached     = 'gepuffert gemessen - der Lesewert kommt aus dem Dateisystem-Cache, nicht vom Laufwerk'
        BenchUnbuffered = 'ohne Dateisystem-Cache gemessen'
        BenchNoSpace    = 'Zu wenig freier Speicher fuer den Laufwerkstest'
        BenchLast       = 'Letzte Messung'
        BenchBetter     = 'besser'
        BenchWorse      = 'schlechter'
        BenchSame       = 'unveraendert'
        BenchWrite      = 'Schreiben'
        BenchRead       = 'Lesen'
        BenchDrive      = 'Testdatei'
        ChgDns          = 'DNS-Server'
        NetDnsAction    = 'DNS-Umstellung'
        NetDnsAuto      = 'automatisch (DHCP)'
        NetDnsConfirm   = 'DNS dieser Adapter auf Cloudflare umstellen?'
        NetDnsReset     = 'DNS wieder auf automatisch (DHCP) stellen?'
        NetDnsDomain    = 'Dieser Rechner ist an einer Domaene angemeldet - ein fremder DNS-Server loest die Namen des Firmennetzes nicht mehr auf'
        NetDnsVpn       = 'Eine VPN-Verbindung ist aktiv - deren Namensaufloesung kann dadurch ausfallen'
        NetDnsNone      = 'Kein verbundener Netzwerkadapter gefunden'
        NetDnsGone      = 'Adapter ist nicht mehr vorhanden'
        NetDnsVerifyErr = 'DNS-Server wurde nicht uebernommen'
        NetDnsRestored  = 'DNS zurueckgesetzt'
        NetNagleConfirm = 'Nagle-Algorithmus auf diesen Schnittstellen abschalten?'
        NetNagleRevert  = 'Nagle-Einstellungen wieder entfernen (Windows-Standard)?'
        NetNagleCount   = 'Bereits gesetzt'
        NetNagleNone    = 'Keine Schnittstelle mit IPv4-Adresse gefunden'
        NetResetWarn    = 'Winsock und TCP/IP werden zurueckgesetzt. Statische IP-Adressen, Proxy-Einstellungen und Filtertreiber (VPN, Firewall) gehen dabei verloren, die Verbindung bricht kurz ab und ein Neustart ist noetig.'
        NetResetOk      = 'Zuruecksetzen abgeschlossen'
        NetResetPart    = 'Nur teilweise zurueckgesetzt'
        NetResetFail    = 'Zuruecksetzen fehlgeschlagen'
        NetPingOk       = 'kein Paketverlust'
        NetPingLoss     = 'Paketverlust'
        NetPingDead     = 'keine Antwort'
        DefAction      = 'Defender-Ausnahmen'
        DefBlocked     = 'Diese Ausnahme wird nicht gesetzt'
        DefRiskRoot    = 'Eine Laufwerkswurzel auszunehmen schaltet den Virenschutz faktisch ab'
        DefRiskSystem  = 'Windows- und Programmordner duerfen nicht ausgenommen werden - genau dort nistet sich Schadsoftware ein'
        DefRiskWild    = 'Platzhalter sind hier zu weitreichend'
        DefRiskProfile = 'Das ist dein halbes Benutzerprofil - darunter der Ordner, in dem Downloads landen'
        DefRiskTemp    = 'Temporaere Ordner sind der uebliche Ablageort frisch heruntergeladener Schadsoftware'
        DefConfirm     = 'Ausnahme wirklich setzen?'
        DefVerifyErr   = 'Ausnahme wurde nicht uebernommen - moeglicherweise verhindert das der Manipulationsschutz'
        DefBadName     = 'Kein gueltiger Prozessname'
        DefAddEntry    = 'Ausnahme hinzufuegen'
        DefSearch      = 'Ausnahmen durchsuchen'
        DefColNote     = 'Hinweis'
        DefBadEntry    = 'Weder Pfad noch Programm noch Dateiendung'
        DefRiskExt     = 'Dateiendung bleibt ueberall ungeprueft'
        DefRiskAnyPath = 'gilt fuer jede Datei dieses Namens'
        DefRiskCount   = 'riskant'
        DefReAdded     = 'Ausnahme wieder eingetragen'
        DefRemoved     = 'Ausnahme entfernt'

        CmdRedirect    = 'Eigene Umleitung erkannt - diese Ausgabe erscheint nicht im Protokoll, sondern in deiner Datei'
        CmdNoOut       = 'Der Befehl hat nichts ausgegeben'
        CmdTabHint     = 'Tab vervollstaendigt, Pfeiltasten holen frueheres zurueck, Esc leert'

        BakClean       = 'Sicherungen aufraeumen'
        BakCleanNone   = 'Nichts aufzuraeumen - der Ordner liegt im Rahmen'
        BakKept        = 'behalten'
        BakDropped     = 'entfernt'
        BakHeld        = 'durch offene Aenderungen gehalten'
        BakFolder      = 'Sicherungsordner'

        BakScopes      = 'Gesicherte Bereiche'
        BakKeys        = 'Schluessel'
        BakInvalid     = 'Keine gueltige Registrierungsdatei - Sicherung wird nicht eingespielt'
        BakEmpty       = 'Export blieb leer - keiner der Bereiche liess sich sichern'
        BakMergeHint   = 'Achtung: Eine Registrierungsdatei wird zurueckgeschrieben, nicht ersetzt. Werte, die seit der Sicherung neu hinzugekommen sind, bleiben bestehen.'
        BakSvcTitle    = 'Starttypen aus der Sicherung zuruecksetzen'
        BakSvcCount    = 'Dienste in der Sicherung'
        BakSvcGone     = 'Dienst existiert nicht mehr'

        ChgTask        = 'Aufgabe'
        ChgFile        = 'Datei'
        TskAction      = 'Aufgaben'
        TskProtected   = 'Systemaufgabe - bleibt unangetastet'
        StuMoved       = 'In die Sicherung verschoben statt geloescht'
        StuRestored    = 'Verknuepfung wiederhergestellt'
        FileGone       = 'Gesicherte Datei nicht mehr auffindbar'
        FileBack       = 'Zielordner nicht mehr vorhanden'

        ChgService     = 'Dienst'
        SvcNoChange    = 'steht bereits so'
        SvcVerifyErr   = 'Aenderung wurde nicht uebernommen'
        SvcFallback    = 'Kein frueherer Starttyp bekannt - auf Manuell gesetzt, nicht auf Automatisch'
        SvcRestored    = 'Starttyp wiederhergestellt'
        SvcAction      = 'Dienste'

        CleanTitle     = 'Was soll bereinigt werden?'
        CleanScan      = 'Groessen werden ermittelt'
        CleanPartial = 'Messung unvollstaendig - sehr viele Dateien, es wird nur der gefundene Teil gezeigt'
        CleanNothing   = 'Nichts zu bereinigen - alle Ablagen sind bereits leer'
        CleanTotal     = 'Auswahl'
        CleanFiles     = 'Dateien'
        CleanRiskyHint = 'Grau hinterlegte Eintraege sind bewusst abgewaehlt - lies den Hinweis'
        CleanFreed     = 'Freigegeben'
        CleanLocked    = 'gesperrt'
        CleanSvcStop   = 'Windows-Update-Dienste werden angehalten'
        CleanSvcStart  = 'Windows-Update-Dienste laufen wieder'
        CleanSvcFail   = 'Update-Dienst liess sich nicht anhalten - Ordner wird uebersprungen'
        CleanYoung     = 'zu neu, in Benutzung'
        CtTemp         = 'Temporaere Dateien (Benutzer)'
        CtTempLocal    = 'Temporaere Dateien (lokal)'
        CtTempWin      = 'Temporaere Dateien (Windows)'
        CtCbs          = 'Protokolle der Komponentenwartung'
        CtWer          = 'Fehlerberichte'
        CtDeliv        = 'Uebermittlungsoptimierung (Update-Zwischenspeicher)'
        CtPrefetch     = 'Prefetch - Windows baut die Dateien neu auf, die ersten Programmstarts danach dauern laenger'
        CtSoftDist     = 'Update-Zwischenspeicher - nur bei haengenden Updates leeren, ein bereits geladenes Update wird erneut heruntergeladen'
        SetCleanConfirm = 'Vor dem Bereinigen fragen, was geloescht wird'

        SetRememberWin = 'Fenstergroesse und -position merken'
        HealthCpu      = 'CPU-Last'
        HealthRam      = 'Arbeitsspeicher'
        HealthProc     = 'Prozesse'
        HealthDisk     = 'Systemlaufwerk'
        HealthStartup  = 'Autostart'
        HealthReboot   = 'Neustart ausstehend'
        RebCbs         = 'Systemdateien'
        RebUpdate      = 'Windows Update'
        RebRename      = 'Computername'
        RebFiles       = 'Dateiumbenennungen'
        RebTweak       = 'Angewendete Tweaks'
        RebootNeeded   = 'Ein Neustart steht aus - einige Aenderungen wirken erst danach'
        HealthAllGood  = 'Keine Auffaelligkeiten'
        HeadLogPath    = 'Protokolldatei'
        LogPanelTitle  = 'SKRIPT-AUSGABE  +  OPERATIONS-LOG'
        FilterAll      = 'Alle'
        FilterInfo     = 'Infos'
        FilterWarn     = 'Warnungen'
        FilterError    = 'Fehler'
        CmdPlaceholder = 'Befehl eingeben, Enter fuehrt aus'
        CmdRun         = 'Start'
        CmdRunning     = 'Befehl laeuft'
        CmdDone        = 'Befehl beendet'
        CmdBusy        = 'Es laeuft bereits eine Aktion'
        SearchStartup  = 'Autostart durchsuchen'
        SearchTasks    = 'Aufgaben durchsuchen'
        SearchChanges  = 'Aenderungen durchsuchen'
        LblLink        = 'Verbindung'
        HWBoard        = 'HAUPTPLATINE / BIOS'
        HWNetwork      = 'NETZWERKADAPTER'
        LblName        = 'Name'
        LblCores       = 'Kerne/Threads'
        LblClock       = 'Takt max.'
        LblArch        = 'Architektur'
        LblVram        = 'Grafikspeicher'
        LblRes         = 'Aufloesung'
        LblDriver      = 'Treiber'
        LblTotal       = 'Gesamt'
        LblUsed        = 'Belegt'
        ColDrive       = 'Laufwerk'
        RepOpen        = 'offen'
        LblFree        = 'Frei'
        LblModules     = 'Module'
        LblVersion     = 'Version'
        LblBuild       = 'Build'
        LblEdition     = 'Ausgabe'
        LblRelease     = 'Release'
        LblUptime      = 'Laufzeit'
        LblVendor      = 'Hersteller'
        LblModel       = 'Modell'
        LblDate        = 'Datum'
        LblSpeed       = 'Takt'
        LblType        = 'Typ'
        LblMedia       = 'Medium'
        LblMac         = 'MAC-Adresse'
        LblInstalled   = 'Installiert'
        ColName        = 'Name'
        ColDisplay     = 'Anzeigename'
        ColStartType   = 'Starttyp'
        ColCommand     = 'Befehl'
        ColScope       = 'Bereich'
        ColTask        = 'Aufgabe'
        ColPath        = 'Pfad'
        ColThreads     = 'Threads'
        SetLogging     = 'Protokollierung'
        SetNotify      = 'Benachrichtigungen'
        StartupFolder  = 'Autostart-Ordner'
        LogUltimate    = 'Hoechstleistungs-Energieplan wird aktiviert'
        LogUltimateOn  = 'Hoechstleistung aktiv'
        LogUltimateFallback = 'Hoechstleistung nicht verfuegbar - Hohe Leistung aktiviert'
        LogDnsCleared  = 'DNS-Zwischenspeicher geleert'
        LogHwCached    = 'Hardwaredaten zwischengespeichert'
        LogHwFailed    = 'Hardwareabfrage fehlgeschlagen'
        TwkAllOk       = 'vollstaendig angewendet'
        TwkDescAnimations   = 'Fensteranimationen aus - wirkt flotter, Menues erscheinen hart'
        TwkDescTransparency = 'Transparenz aus - entlastet schwache Grafikchips'
        TwkDescSysMain      = 'Vorladedienst aus - weniger Schreiblast, Programme starten evtl. langsamer'
        TwkDescSearchIdx    = 'Suchindex aus - spart Last, die Dateisuche wird deutlich langsamer'
        TwkDescFastStart    = 'Schnellstart aus - sauberes Herunterfahren, Hochfahren dauert laenger'
        TwkDescThrottling   = 'Leistungsdrosselung aus - volle Taktung, hoeherer Verbrauch'
        TwkDescPriority     = 'Vordergrundfenster bevorzugen - Hintergrunddienste bekommen weniger Rechenzeit'
        TwkDescBgApps       = 'Apps im Hintergrund aus - spart Last, Benachrichtigungen entfallen'
        TwkDescTips         = 'Windows-Tipps und Vorschlaege im Startmenue abschalten'
        TwkDescHibernate    = 'Ruhezustand aus - gibt mehrere GB frei, Schnellstart entfaellt'
        TwkDescParking      = 'Kernparken aus - alle Kerne bleiben wach, hoeherer Verbrauch'
        TwkDescDebloat      = 'Vorinstallierte Apps entfernen - wird einzeln bestaetigt'
        TwkAskRevert        = 'Diese Einstellung ist aktiv. Auf den Windows-Standard zuruecksetzen?'
        TwkRevertOk         = 'auf Windows-Standard zurueckgesetzt'
        TwkNoRevert         = 'laesst sich hier nicht zuruecknehmen'
        TwkPartial     = 'nur teilweise angewendet'
        TwkNone        = 'konnte nicht angewendet werden'
        TwkNoAdmin     = 'ohne Administratorrechte sind Systemschluessel gesperrt'
        TwkLocked      = 'gesperrt durch Gruppenrichtlinie oder Manipulationsschutz'
        LogLanguage    = 'Sprache'
        LogViewUnknown = 'Unbekannte Ansicht'
        LogMonitorStopped = 'Ueberwachung nach wiederholten Fehlern gestoppt'
        LogAppxMissing = 'Appx-Befehle auf diesem System nicht verfuegbar'
        LogNotPresent  = 'nicht vorhanden'
        LogTimeout     = 'Zeitlimit'
        LogExitCode    = 'Beendigungscode'
        SetTray        = 'Beim Minimieren in den Infobereich legen'
        TrayShow       = 'Fenster anzeigen'
        TrayExit       = 'Beenden'
        TrayHint       = 'EB_Optimizer laeuft weiter im Infobereich'
        SetRestoreView = 'Zuletzt geoeffnete Ansicht beim Start laden'
        SetReset       = 'Einstellungen zuruecksetzen'
        SetSaved       = 'Einstellungen gespeichert'
        SetFile        = 'Einstellungsdatei'
        MenuHelp       = 'Hilfe'
        HelpTitle      = 'Hilfe & Tastenkuerzel'
        HelpSubtitle   = 'Bedienung, Tastenkuerzel und Sicherheitshinweise'
        Report         = 'Systembericht'
        ReportDesc     = 'Hardware, Datentraeger, Dienste und Autostart als HTML-Datei exportieren'
        BusyTitle      = 'Vorgang laeuft'
        BusyHint       = 'Bitte warten - das Fenster bleibt bedienbar'
        RepairWindow   = 'Fortschritt laeuft im separaten Konsolenfenster'
        RepSfcClean    = 'Keine Integritaetsverletzungen gefunden'
        RepSfcFixed    = 'Beschaedigte Dateien gefunden und repariert - Neustart empfohlen'
        RepSfcBroken   = 'Beschaedigte Dateien gefunden, nicht alle reparierbar - jetzt DISM ausfuehren'
        RepDismOk      = 'Komponentenspeicher ist in Ordnung'
        RepDismReboot  = 'Reparatur erfolgreich - Neustart erforderlich'
        RepDismError   = 'DISM meldet einen Fehler'
        RepChkSched    = 'Pruefung wird beim naechsten Neustart ausgefuehrt'
        RepChkFixed    = 'Fehler gefunden und behoben'
        RepNoLog       = 'Ergebnisprotokoll nicht lesbar'
        SingleTitle    = 'Bereits geoeffnet'
        SingleMsg      = 'EB_Optimizer laeuft bereits. Das vorhandene Fenster wird in den Vordergrund geholt.'
        BackupsTitle   = 'Sicherungen'
        BackupsHint    = 'Vor jedem Registry-Eingriff wird automatisch eine .reg-Sicherung abgelegt'
        BackupRestore  = 'Wiederherstellen'
        BackupNone     = 'Keine Sicherungen vorhanden'
        BackupSelect   = 'Bitte zuerst eine Sicherung auswählen'
        BackupDone     = 'Sicherung wiederhergestellt - ein Neustart kann nötig sein'
        ColFile        = 'Datei'
        ColType        = 'Typ'
        ColDate        = 'Datum'
        ColSize        = 'Größe'
        MenuChanges    = 'Änderungen'
        ChangesTitle   = 'Änderungsprotokoll'
        ChangesSubtitle = 'Jede Registry-Änderung mit altem Wert - einzeln rücknehmbar'
        ChangeUndo     = 'Rückgängig'
        ChangeUndoAll  = 'Alle rückgängig'
        ChangeNone     = 'Keine Änderungen aufgezeichnet'
        ChangeUndone   = 'Rückgängig gemacht'
        ChangeNoUndo   = 'Nichts rückgängig zu machen'
        ChangeVerifyErr= 'Wert liess sich nicht zurueckschreiben'
        ChangeOpen     = 'Protokolldatei öffnen'
        ColKey         = 'Schlüssel'
        ColOld         = 'Vorher'
        ColNew         = 'Nachher'
        ColState       = 'Status'
        EmptyFilter    = 'Keine Treffer'
        CtxCopy        = 'Zeile kopieren'
        CtxCopyAll     = 'Alles kopieren'
        CtxExport      = 'Als CSV exportieren'
        ExportDone     = 'Exportiert'
        ExportEmpty    = 'Nichts zu exportieren'
        EmptyNoEntries = 'Keine Einträge vorhanden'
        BusyCancelled  = 'Vorgang abgebrochen'
        BusyTooLong = 'Vorgang dauert ungewoehnlich lange und wurde abgebrochen'
        LblFreeSpace   = 'frei'
        KeyCtrl        = 'Strg'
        DefTypePath    = 'Pfad'
        DefTypeProcess = 'Prozess'
        DefTypeExt     = 'Dateityp'
        LogTaskModule  = 'Modul ScheduledTasks nicht verfuegbar'
        UpdService     = 'Windows Update-Dienst'
        AdminMode      = 'Administrator'
        PrivClickToDo   = 'Click to Do / KI-Agenten aus'
        PrivWidgets     = 'Widgets und News abschalten'
        PrivWebSearch   = 'Websuche im Startmenue aus'
        PrivEdgeAI      = 'Edge-Copilot-Leiste aus'
        StateOn         = 'AKTIV'
        StatePart       = 'TEILS'
        PrivRecall      = 'Recall / Windows-KI abschalten'
        PrivCopilot     = 'Copilot abschalten'
        WmicGone        = 'wmic wurde ab Windows 11 26H2 aus Windows entfernt - WMI selbst bleibt erhalten'
        WmicHint        = 'Ersatz'
        TipLogCollapse  = 'Protokollleiste einklappen'
        TipLogExpand    = 'Protokollleiste ausklappen'
        TipMaximize     = 'Maximieren / Wiederherstellen  (F11)'
        TipMinimize     = 'Minimieren'
        TipCpu          = 'Prozessorauslastung'
        TipRam          = 'Arbeitsspeicher'
        TipDisk         = 'Belegung'
        TipNet          = 'Netzwerkdurchsatz (gesamt)'
        TipClock        = 'Uhrzeit'
        TipLogBox       = 'Aktionsprotokoll  -  Strg+L leert die Anzeige'
        TipLogClear     = 'Anzeige leeren  (Strg+L)'
        ChkdskScheduled = 'Die Pruefung wurde eingeplant und laeuft beim naechsten Neustart.'
        BusyStep       = 'Schritt'
        LogFile         = 'Protokolldatei'
        LogOpenTip      = 'Protokolldatei dieser Sitzung oeffnen'
        LogSearchHint   = 'Protokoll durchsuchen'
        TipLogSearch    = 'Mehrere Woerter = UND-Suche, Minus davor schliesst aus. Esc leert.'
        LogMatchCount   = 'Treffer'
        CrashTitle      = 'Unerwarteter Fehler'
        CrashMsg        = 'Es ist ein unerwarteter Fehler aufgetreten. Das Programm laeuft weiter. Details wurden gespeichert unter:'
    }
    EN = @{
        ChgDefender    = 'Defender exclusion'
        DiskBrowserOpen = 'Browser is still running and holds the cache open'
        DiskAllLocked   = 'Every file is in use - nothing was deleted'
        CtWuLog   = 'Windows Update logs'
        CtShader  = 'Graphics shader cache'
        CtPanther = 'Setup logs - needed to diagnose problems after a feature update'
        CtDump    = 'Crash dumps - without them a blue screen can no longer be analysed'
        CtRecycle = 'Recycle Bin - the files are gone for good afterwards'
        TskLastRun     = 'Last run'
        TskResult      = 'Result'
        TskHidden      = 'Windows tasks hidden'
        TskShowWin     = 'Windows tasks'
        TskShowWinTip  = 'Show or hide tasks under \Microsoft'
        TskRunDisabled = 'Task is disabled - enable it first'
        TskRunning     = 'Already running'
        TskResOk       = 'Succeeded'
        TskResError    = 'Error'
        TskResNotFound = 'File not found'
        TskResReady    = 'Ready'
        TskResRunning  = 'Running'
        TskResDisabled = 'Disabled'
        TskResNever    = 'Never run'
        TskResStopped  = 'Stopped'
        TskResUnknown  = 'Unknown'
        SvcAuto          = 'Automatic'
        SvcAutoDelayed   = 'Automatic (delayed)'
        SvcManual        = 'Manual'
        SvcDisabled      = 'Disabled'
        SvcBoot          = 'Boot'
        SvcSystem        = 'System'
        SvcStartDisabled = 'Service is disabled - enable it first'
        SvcStillRunning  = 'Keeps running until the next restart'
        SvcDependents    = 'Will be stopped as well'
        SvcDependentsAsk = 'These running services depend on it and will be stopped as well:'
        ProcHung        = 'Not responding'
        ProcOk          = 'Running'
        ProcNoSelection = 'No process selected'
        ProcKillAsk     = 'End these processes and their child processes? Unsaved data will be lost.'
        Start32        = 'System (32-bit)'
        StartOnce      = 'Run once'
        StartCommon    = 'All users'
        StartFolder    = 'Folder'
        StuEnabled     = 'Enabled'
        StuDisabled    = 'Disabled'
        StuMissing     = 'Target missing'
        StuNoToggle    = 'cannot be switched off'
        StuNoChange    = 'already in the requested state'
        StuNoEntry     = 'not a valid entry'
        StuNoSelection = 'Nothing selected'
        HWBattery     = 'BATTERY'
        HWSecurity    = 'SECURITY'
        LblCharge     = 'Charge'
        LblWear       = 'Wear'
        LblDesign     = 'Design capacity'
        LblFullCharge = 'Full charge'
        LblSlots      = 'Slots'
        LblConfigured = 'Clock active'
        LblTpm        = 'TPM'
        LblSecureBoot = 'Secure Boot'
        HwUnknown     = 'not available'
        HwXmpHint     = 'below rated speed, XMP/EXPO not enabled'
        HwActive      = 'enabled'
        HwInactive    = 'disabled'
        HwOnBattery   = 'on battery'
        HwExportBusy  = 'Data is still loading - export is possible afterwards'
        HealthDefRt   = 'Real-time protection is off'
        HealthDefSig  = 'Virus signatures are outdated'
        HealthRestore = 'No recent restore point'
        HealthUptime  = 'Uptime without a restart'
        HealthMore    = 'more items'
        HealthAction  = 'Needs attention'
        UpdPaused        = 'Updates paused until'
        UpdNotPaused     = 'Updates are not paused'
        UpdPauseDays     = 'days'
        UpdPauseUntil    = 'Paused until'
        UpdPauseMax      = 'Windows accepts at most 35 days - after that updates resume on their own'
        UpdPauseConfirm  = 'Pause Windows updates now?'
        UpdResumeConfirm = 'Release updates again?'
        UpdResumed       = 'Updates released again'
        UpdExpired       = 'The last pause has expired'
        UpdSvcStop       = 'Service cannot be stopped'
        UpdSvcStopping   = 'Stopping services'
        UpdSvcStarting   = 'Starting services'
        UpdSvcRestart    = 'Services restarted'
        UpdRepairAbort   = 'Repair aborted - nothing was changed'
        UpdRepairWarn    = 'The update cache will be renamed. The update history disappears, the next search takes longer once and several hundred megabytes are downloaded again. The folders stay behind as .old and can be brought back via Undo.'
        UpdLeftovers     = 'Old repair folders'
        UpdCleanOld      = 'Remove them now?'
        BenchRunning    = 'A measurement is already running'
        BenchWarmup     = 'Warm-up run'
        BenchSpread     = 'spread'
        BenchSingle     = 'single core'
        BenchUnstable   = 'The runs differ widely - the machine was busy during the measurement'
        BenchBusyWarn   = 'CPU load too high before the start - waiting gives comparable figures'
        BenchCached     = 'measured buffered - the read figure comes from the file system cache, not from the drive'
        BenchUnbuffered = 'measured without the file system cache'
        BenchNoSpace    = 'Not enough free space for the drive test'
        BenchLast       = 'Last measurement'
        BenchBetter     = 'better'
        BenchWorse      = 'worse'
        BenchSame       = 'unchanged'
        BenchWrite      = 'Write'
        BenchRead       = 'Read'
        BenchDrive      = 'Test file'
        ChgDns          = 'DNS server'
        NetDnsAction    = 'DNS change'
        NetDnsAuto      = 'automatic (DHCP)'
        NetDnsConfirm   = 'Switch the DNS of these adapters to Cloudflare?'
        NetDnsReset     = 'Set DNS back to automatic (DHCP)?'
        NetDnsDomain    = 'This machine is joined to a domain - an external DNS server no longer resolves company network names'
        NetDnsVpn       = 'A VPN connection is active - its name resolution may stop working'
        NetDnsNone      = 'No connected network adapter found'
        NetDnsGone      = 'Adapter is no longer present'
        NetDnsVerifyErr = 'DNS server was not applied'
        NetDnsRestored  = 'DNS restored'
        NetNagleConfirm = 'Disable the Nagle algorithm on these interfaces?'
        NetNagleRevert  = 'Remove the Nagle settings again (Windows default)?'
        NetNagleCount   = 'Already set'
        NetNagleNone    = 'No interface with an IPv4 address found'
        NetResetWarn    = 'Winsock and TCP/IP will be reset. Static IP addresses, proxy settings and filter drivers (VPN, firewall) are lost, the connection drops briefly and a restart is required.'
        NetResetOk      = 'Reset completed'
        NetResetPart    = 'Only partially reset'
        NetResetFail    = 'Reset failed'
        NetPingOk       = 'no packet loss'
        NetPingLoss     = 'packet loss'
        NetPingDead     = 'no reply'
        DefAction      = 'Defender exclusions'
        DefBlocked     = 'This exclusion will not be set'
        DefRiskRoot    = 'Excluding a drive root effectively switches off the virus scanner'
        DefRiskSystem  = 'Windows and program folders must not be excluded - that is exactly where malware settles'
        DefRiskWild    = 'Wildcards are too far-reaching here'
        DefRiskProfile = 'That is half your user profile - including the folder downloads land in'
        DefRiskTemp    = 'Temp folders are the usual landing place for freshly downloaded malware'
        DefConfirm     = 'Really set this exclusion?'
        DefVerifyErr   = 'Exclusion was not applied - tamper protection may be preventing it'
        DefBadName     = 'Not a valid process name'
        DefAddEntry    = 'Add exclusion'
        DefSearch      = 'Search exclusions'
        DefColNote     = 'Note'
        DefBadEntry    = 'Neither a path nor a program nor a file extension'
        DefRiskExt     = 'this extension stays unchecked everywhere'
        DefRiskAnyPath = 'applies to every file with this name'
        DefRiskCount   = 'risky'
        DefReAdded     = 'Exclusion added back'
        DefRemoved     = 'Exclusion removed'

        CmdRedirect    = 'Own redirection detected - that output goes to your file, not to the log'
        CmdNoOut       = 'The command produced no output'
        CmdTabHint     = 'Tab completes, arrow keys recall, Esc clears'

        BakClean       = 'Clean up backups'
        BakCleanNone   = 'Nothing to clean up - the folder is within its budget'
        BakKept        = 'kept'
        BakDropped     = 'removed'
        BakHeld        = 'held by open changes'
        BakFolder      = 'Backup folder'

        BakScopes      = 'Backed up areas'
        BakKeys        = 'keys'
        BakInvalid     = 'Not a valid registry file - backup will not be imported'
        BakEmpty       = 'Export stayed empty - none of the areas could be backed up'
        BakMergeHint   = 'Note: a registry file is merged back, not swapped in. Values added since the backup remain in place.'
        BakSvcTitle    = 'Restore start types from the backup'
        BakSvcCount    = 'services in the backup'
        BakSvcGone     = 'service no longer exists'

        ChgTask        = 'Task'
        ChgFile        = 'File'
        TskAction      = 'Tasks'
        TskProtected   = 'System task - left untouched'
        StuMoved       = 'Moved to the backup instead of deleted'
        StuRestored    = 'Shortcut restored'
        FileGone       = 'Backed up file no longer found'
        FileBack       = 'Target folder no longer exists'

        ChgService     = 'Service'
        SvcNoChange    = 'already in that state'
        SvcVerifyErr   = 'change was not applied'
        SvcFallback    = 'No earlier start type known - set to Manual, not Automatic'
        SvcRestored    = 'Start type restored'
        SvcAction      = 'Services'

        CleanTitle     = 'What should be cleaned?'
        CleanScan      = 'Measuring sizes'
        CleanPartial = 'Scan incomplete - a lot of files, only the part found so far is shown'
        CleanNothing   = 'Nothing to clean - all locations are already empty'
        CleanTotal     = 'Selected'
        CleanFiles     = 'files'
        CleanRiskyHint = 'Greyed entries are deselected on purpose - read the note'
        CleanFreed     = 'Freed'
        CleanLocked    = 'locked'
        CleanSvcStop   = 'Stopping Windows Update services'
        CleanSvcStart  = 'Windows Update services running again'
        CleanSvcFail   = 'Update service could not be stopped - folder skipped'
        CleanYoung     = 'too recent, in use'
        CtTemp         = 'Temporary files (user)'
        CtTempLocal    = 'Temporary files (local)'
        CtTempWin      = 'Temporary files (Windows)'
        CtCbs          = 'Component servicing logs'
        CtWer          = 'Error reports'
        CtDeliv        = 'Delivery Optimization (update cache)'
        CtPrefetch     = 'Prefetch - Windows rebuilds these files, the next few app starts will be slower'
        CtSoftDist     = 'Update cache - only clear this for stuck updates, an already downloaded update is fetched again'
        SetCleanConfirm = 'Ask what will be deleted before cleaning'

        SetRememberWin = 'Remember window size and position'
        HealthCpu      = 'CPU load'
        HealthRam      = 'Memory'
        HealthProc     = 'Processes'
        HealthDisk     = 'System drive'
        HealthStartup  = 'Startup'
        HealthReboot   = 'Restart pending'
        RebCbs         = 'System files'
        RebUpdate      = 'Windows Update'
        RebRename      = 'Computer name'
        RebFiles       = 'File renames'
        RebTweak       = 'Applied tweaks'
        RebootNeeded   = 'A restart is pending - some changes take effect only afterwards'
        HealthAllGood  = 'Nothing to report'
        HeadLogPath    = 'Log file'
        LogPanelTitle  = 'SCRIPT OUTPUT  +  OPERATIONS LOG'
        FilterAll      = 'All'
        FilterInfo     = 'Info'
        FilterWarn     = 'Warnings'
        FilterError    = 'Errors'
        CmdPlaceholder = 'Type a command, Enter runs it'
        CmdRun         = 'Run'
        CmdRunning     = 'Command running'
        CmdDone        = 'Command finished'
        CmdBusy        = 'Another action is already running'
        SearchStartup  = 'Search startup entries'
        SearchTasks    = 'Search tasks'
        SearchChanges  = 'Search changes'
        LblLink        = 'Link speed'
        HWBoard        = 'MAINBOARD / BIOS'
        HWNetwork      = 'NETWORK ADAPTERS'
        LblName        = 'Name'
        LblCores       = 'Cores/Threads'
        LblClock       = 'Max clock'
        LblArch        = 'Architecture'
        LblVram        = 'Video memory'
        LblRes         = 'Resolution'
        LblDriver      = 'Driver'
        LblTotal       = 'Total'
        LblUsed        = 'Used'
        ColDrive       = 'Drive'
        RepOpen        = 'open'
        LblFree        = 'Free'
        LblModules     = 'Modules'
        LblVersion     = 'Version'
        LblBuild       = 'Build'
        LblEdition     = 'Edition'
        LblRelease     = 'Release'
        LblUptime      = 'Uptime'
        LblVendor      = 'Vendor'
        LblModel       = 'Model'
        LblDate        = 'Date'
        LblSpeed       = 'Speed'
        LblType        = 'Type'
        LblMedia       = 'Media'
        LblMac         = 'MAC address'
        LblInstalled   = 'Installed'
        ColName        = 'Name'
        ColDisplay     = 'Display name'
        ColStartType   = 'Start type'
        ColCommand     = 'Command'
        ColScope       = 'Scope'
        ColTask        = 'Task'
        ColPath        = 'Path'
        ColThreads     = 'Threads'
        SetLogging     = 'Logging'
        SetNotify      = 'Notifications'
        StartupFolder  = 'Startup folder'
        LogUltimate    = 'Enabling Ultimate Performance power plan'
        LogUltimateOn  = 'Ultimate Performance active'
        LogUltimateFallback = 'Ultimate plan unavailable - High Performance activated'
        LogDnsCleared  = 'DNS cache cleared'
        LogHwCached    = 'Hardware info cached'
        LogHwFailed    = 'Hardware query failed'
        TwkAllOk       = 'fully applied'
        TwkDescAnimations   = 'Window animations off - feels snappier, menus appear abruptly'
        TwkDescTransparency = 'Transparency off - relieves weak graphics chips'
        TwkDescSysMain      = 'Preload service off - less write load, programs may start slower'
        TwkDescSearchIdx    = 'Search index off - saves load, file search gets much slower'
        TwkDescFastStart    = 'Fast startup off - clean shutdown, booting takes longer'
        TwkDescThrottling   = 'Power throttling off - full clock speed, higher consumption'
        TwkDescPriority     = 'Favour the foreground window - background services get less CPU time'
        TwkDescBgApps       = 'Background apps off - saves load, notifications stop'
        TwkDescTips         = 'Turn off Windows tips and suggestions in the Start menu'
        TwkDescHibernate    = 'Hibernation off - frees several GB, no fast startup'
        TwkDescParking      = 'Core parking off - all cores stay awake, higher consumption'
        TwkDescDebloat      = 'Remove preinstalled apps - confirmed one by one'
        TwkAskRevert        = 'This setting is active. Reset it to the Windows default?'
        TwkRevertOk         = 'reset to the Windows default'
        TwkNoRevert         = 'cannot be undone from here'
        TwkPartial     = 'only partly applied'
        TwkNone        = 'could not be applied'
        TwkNoAdmin     = 'without administrator rights system keys are locked'
        TwkLocked      = 'blocked by group policy or tamper protection'
        LogLanguage    = 'Language'
        LogViewUnknown = 'Unknown view'
        LogMonitorStopped = 'Monitoring stopped after repeated errors'
        LogAppxMissing = 'Appx cmdlets not available on this host'
        LogNotPresent  = 'not present'
        LogTimeout     = 'Timeout'
        LogExitCode    = 'Exit code'
        SetTray        = 'Minimize to the notification area'
        TrayShow       = 'Show window'
        TrayExit       = 'Exit'
        TrayHint       = 'EB_Optimizer keeps running in the notification area'
        SetRestoreView = 'Reopen the last view on startup'
        SetReset       = 'Reset settings'
        SetSaved       = 'Settings saved'
        SetFile        = 'Settings file'
        MenuHelp       = 'Help'
        HelpTitle      = 'Help & shortcuts'
        HelpSubtitle   = 'Usage, keyboard shortcuts and safety notes'
        Report         = 'System report'
        ReportDesc     = 'Export hardware, drives, services and startup items as an HTML file'
        BusyTitle      = 'Operation running'
        BusyHint       = 'Please wait - the window stays responsive'
        RepairWindow   = 'Progress is shown in the separate console window'
        RepSfcClean    = 'No integrity violations found'
        RepSfcFixed    = 'Corrupt files found and repaired - reboot recommended'
        RepSfcBroken   = 'Corrupt files found, not all repairable - run DISM now'
        RepDismOk      = 'The component store is healthy'
        RepDismReboot  = 'Repair successful - reboot required'
        RepDismError   = 'DISM reported an error'
        RepChkSched    = 'The check will run on the next restart'
        RepChkFixed    = 'Errors found and fixed'
        RepNoLog       = 'Result log could not be read'
        SingleTitle    = 'Already running'
        SingleMsg      = 'EB_Optimizer is already running. The existing window is brought to the front.'
        BackupsTitle   = 'Backups'
        BackupsHint    = 'Every registry change is exported to a .reg file first'
        BackupRestore  = 'Restore'
        BackupNone     = 'No backups yet'
        BackupSelect   = 'Please select a backup first'
        BackupDone     = 'Backup restored - a reboot may be required'
        ColFile        = 'File'
        ColType        = 'Type'
        ColDate        = 'Date'
        ColSize        = 'Size'
        MenuChanges    = 'Changes'
        ChangesTitle   = 'Change journal'
        ChangesSubtitle = 'Every registry change with its previous value - undo one by one'
        ChangeUndo     = 'Undo'
        ChangeUndoAll  = 'Undo all'
        ChangeNone     = 'No changes recorded'
        ChangeUndone   = 'Undone'
        ChangeNoUndo   = 'Nothing to undo'
        ChangeVerifyErr= 'Value could not be written back'
        ChangeOpen     = 'Open journal file'
        ColKey         = 'Key'
        ColOld         = 'Before'
        ColNew         = 'After'
        ColState       = 'State'
        EmptyFilter    = 'No matches'
        CtxCopy        = 'Copy row'
        CtxCopyAll     = 'Copy all'
        CtxExport      = 'Export as CSV'
        ExportDone     = 'Exported'
        ExportEmpty    = 'Nothing to export'
        EmptyNoEntries = 'No entries'
        BusyCancelled  = 'Operation cancelled'
        BusyTooLong = 'The operation took unusually long and was aborted'
        LblFreeSpace   = 'free'
        KeyCtrl        = 'Ctrl'
        DefTypePath    = 'Path'
        DefTypeProcess = 'Process'
        DefTypeExt     = 'Extension'
        LogTaskModule  = 'ScheduledTasks module not available'
        UpdService     = 'Windows Update service'
        AdminMode      = 'Administrator'
        PrivClickToDo   = 'Disable Click to Do / AI agents'
        PrivWidgets     = 'Disable widgets and news'
        PrivWebSearch   = 'No web results in Start'
        PrivEdgeAI      = 'Disable Edge Copilot sidebar'
        StateOn         = 'ACTIVE'
        StatePart       = 'PARTLY'
        PrivRecall      = 'Disable Recall / Windows AI'
        PrivCopilot     = 'Disable Copilot'
        WmicGone        = 'wmic has been removed from Windows as of Windows 11 26H2 - WMI itself remains'
        WmicHint        = 'Replacement'
        TipLogCollapse  = 'Collapse the log panel'
        TipLogExpand    = 'Expand the log panel'
        TipMaximize     = 'Maximise / restore  (F11)'
        TipMinimize     = 'Minimise'
        TipCpu          = 'Processor load'
        TipRam          = 'Memory usage'
        TipDisk         = 'Usage of'
        TipNet          = 'Network throughput (total)'
        TipClock        = 'Time'
        TipLogBox       = 'Action log  -  Ctrl+L clears the view'
        TipLogClear     = 'Clear the view  (Ctrl+L)'
        ChkdskScheduled = 'The check has been scheduled and will run at the next restart.'
        BusyStep       = 'Step'
        LogFile         = 'Log file'
        LogOpenTip      = 'Open the log file of this session'
        LogSearchHint   = 'Search the log'
        TipLogSearch    = 'Several words = AND search, a leading minus excludes. Esc clears.'
        LogMatchCount   = 'matches'
        CrashTitle      = 'Unexpected error'
        CrashMsg        = 'An unexpected error occurred. The program keeps running. Details were saved to:'
    }
    TR = @{
        ChgDefender    = 'Defender istisnasi'
        DiskBrowserOpen = 'Tarayici hala calisiyor ve onbellegi acik tutuyor'
        DiskAllLocked   = 'Tum dosyalar kullanimda - hicbir sey silinmedi'
        CtWuLog   = 'Windows Update gunlukleri'
        CtShader  = 'Ekran karti shader onbellegi'
        CtPanther = 'Kurulum gunlukleri - surum yukseltmesinden sonra sorun tespiti icin gerekir'
        CtDump    = 'Cokme dokumleri - onlarsiz mavi ekran incelenemez'
        CtRecycle = 'Geri donusum kutusu - dosyalar sonrasinda kalici olarak silinir'
        TskLastRun     = 'Son calisma'
        TskResult      = 'Sonuc'
        TskHidden      = 'Windows gorevleri gizli'
        TskShowWin     = 'Windows gorevleri'
        TskShowWinTip  = '\Microsoft altindaki gorevleri goster veya gizle'
        TskRunDisabled = 'Gorev devre disi - once etkinlestirin'
        TskRunning     = 'Zaten calisiyor'
        TskResOk       = 'Basarili'
        TskResError    = 'Hata'
        TskResNotFound = 'Dosya bulunamadi'
        TskResReady    = 'Hazir'
        TskResRunning  = 'Calisiyor'
        TskResDisabled = 'Devre disi'
        TskResNever    = 'Hic calismadi'
        TskResStopped  = 'Durduruldu'
        TskResUnknown  = 'Bilinmiyor'
        SvcAuto          = 'Otomatik'
        SvcAutoDelayed   = 'Otomatik (gecikmeli)'
        SvcManual        = 'El ile'
        SvcDisabled      = 'Devre disi'
        SvcBoot          = 'Sistem baslangici'
        SvcSystem        = 'Sistem'
        SvcStartDisabled = 'Hizmet devre disi - once etkinlestirin'
        SvcStillRunning  = 'Sonraki yeniden baslatmaya kadar calismaya devam eder'
        SvcDependents    = 'Birlikte durdurulacak'
        SvcDependentsAsk = 'Bu calisan hizmetler buna baglidir ve birlikte durdurulacak:'
        ProcHung        = 'Yanit vermiyor'
        ProcOk          = 'Calisiyor'
        ProcNoSelection = 'Islem secilmedi'
        ProcKillAsk     = 'Bu islemler ve alt islemleri sonlandirilsin mi? Kaydedilmemis veriler kaybolur.'
        Start32        = 'Sistem (32 bit)'
        StartOnce      = 'Tek seferlik'
        StartCommon    = 'Tum kullanicilar'
        StartFolder    = 'Klasor'
        StuEnabled     = 'Etkin'
        StuDisabled    = 'Devre disi'
        StuMissing     = 'Hedef yok'
        StuNoToggle    = 'kapatilamaz'
        StuNoChange    = 'zaten istenen durumda'
        StuNoEntry     = 'gecerli kayit degil'
        StuNoSelection = 'Secim yok'
        HWBattery     = 'PIL'
        HWSecurity    = 'GUVENLIK'
        LblCharge     = 'Sarj'
        LblWear       = 'Yipranma'
        LblDesign     = 'Tasarim kapasitesi'
        LblFullCharge = 'Tam sarj'
        LblSlots      = 'Yuvalar'
        LblConfigured = 'Etkin hiz'
        LblTpm        = 'TPM'
        LblSecureBoot = 'Secure Boot'
        HwUnknown     = 'belirlenemedi'
        HwXmpHint     = 'nominal altinda, XMP/EXPO etkin degil'
        HwActive      = 'etkin'
        HwInactive    = 'devre disi'
        HwOnBattery   = 'pil ile calisiyor'
        HwExportBusy  = 'Veriler hala yukleniyor - disa aktarma sonrasinda mumkun'
        HealthDefRt   = 'Gercek zamanli koruma kapali'
        HealthDefSig  = 'Virus imzalari guncel degil'
        HealthRestore = 'Guncel geri yukleme noktasi yok'
        HealthUptime  = 'Yeniden baslatmadan calisma suresi'
        HealthMore    = 'madde daha'
        HealthAction  = 'Mudahale gerekli'
        UpdPaused        = 'Guncellestirmeler su tarihe kadar duraklatildi'
        UpdNotPaused     = 'Guncellestirmeler duraklatilmadi'
        UpdPauseDays     = 'gun'
        UpdPauseUntil    = 'Duraklatma bitisi'
        UpdPauseMax      = 'Windows en fazla 35 gun kabul eder - sonrasinda guncellestirmeler kendiliginden devam eder'
        UpdPauseConfirm  = 'Windows guncellestirmeleri simdi duraklatilsin mi?'
        UpdResumeConfirm = 'Guncellestirmeler yeniden serbest birakilsin mi?'
        UpdResumed       = 'Guncellestirmeler yeniden serbest birakildi'
        UpdExpired       = 'Son duraklatma suresi doldu'
        UpdSvcStop       = 'Hizmet durdurulamiyor'
        UpdSvcStopping   = 'Hizmetler durduruluyor'
        UpdSvcStarting   = 'Hizmetler baslatiliyor'
        UpdSvcRestart    = 'Hizmetler yeniden baslatildi'
        UpdRepairAbort   = 'Onarim iptal edildi - hicbir sey degistirilmedi'
        UpdRepairWarn    = 'Guncellestirme onbellegi yeniden adlandirilacak. Guncellestirme gecmisi kaybolur, sonraki arama bir defaliga daha uzun surer ve yuzlerce megabayt yeniden indirilir. Klasorler .old olarak kalir ve Geri Al ile geri getirilebilir.'
        UpdLeftovers     = 'Eski onarim klasorleri'
        UpdCleanOld      = 'Simdi kaldirilsin mi?'
        BenchRunning    = 'Zaten bir olcum calisiyor'
        BenchWarmup     = 'Isinma turu'
        BenchSpread     = 'dagilim'
        BenchSingle     = 'tek cekirdek'
        BenchUnstable   = 'Turlar birbirinden cok farkli - olcum sirasinda bilgisayar mesguldu'
        BenchBusyWarn   = 'Baslamadan once islemci yuku cok yuksek - beklemek karsilastirilabilir degerler verir'
        BenchCached     = 'arabellekli olculdu - okuma degeri surucuden degil dosya sistemi onbelleginden geliyor'
        BenchUnbuffered = 'dosya sistemi onbellegi olmadan olculdu'
        BenchNoSpace    = 'Surucu testi icin yeterli bos alan yok'
        BenchLast       = 'Son olcum'
        BenchBetter     = 'daha iyi'
        BenchWorse      = 'daha kotu'
        BenchSame       = 'degismedi'
        BenchWrite      = 'Yazma'
        BenchRead       = 'Okuma'
        BenchDrive      = 'Test dosyasi'
        ChgDns          = 'DNS sunucusu'
        NetDnsAction    = 'DNS degisikligi'
        NetDnsAuto      = 'otomatik (DHCP)'
        NetDnsConfirm   = 'Bu baglantilarin DNS ayari Cloudflare olarak degistirilsin mi?'
        NetDnsReset     = 'DNS yeniden otomatige (DHCP) alinsin mi?'
        NetDnsDomain    = 'Bu bilgisayar bir etki alanina katilmis - harici bir DNS sunucusu sirket agindaki adlari cozemez'
        NetDnsVpn       = 'Etkin bir VPN baglantisi var - ad cozumlemesi calismayabilir'
        NetDnsNone      = 'Bagli ag baglantisi bulunamadi'
        NetDnsGone      = 'Baglanti artik mevcut degil'
        NetDnsVerifyErr = 'DNS sunucusu uygulanmadi'
        NetDnsRestored  = 'DNS geri alindi'
        NetNagleConfirm = 'Nagle algoritmasi bu arabirimlerde kapatilsin mi?'
        NetNagleRevert  = 'Nagle ayarlari kaldirilsin mi (Windows varsayilani)?'
        NetNagleCount   = 'Zaten ayarli'
        NetNagleNone    = 'IPv4 adresi olan arabirim bulunamadi'
        NetResetWarn    = 'Winsock ve TCP/IP sifirlanacak. Sabit IP adresleri, ara sunucu ayarlari ve filtre suruculeri (VPN, guvenlik duvari) kaybolur, baglanti kisa sure kesilir ve yeniden baslatma gerekir.'
        NetResetOk      = 'Sifirlama tamamlandi'
        NetResetPart    = 'Yalnizca kismen sifirlandi'
        NetResetFail    = 'Sifirlama basarisiz'
        NetPingOk       = 'paket kaybi yok'
        NetPingLoss     = 'paket kaybi'
        NetPingDead     = 'yanit yok'
        DefAction      = 'Defender istisnalari'
        DefBlocked     = 'Bu istisna ayarlanmayacak'
        DefRiskRoot    = 'Bir surucu kokunu haric tutmak virus korumasini fiilen kapatir'
        DefRiskSystem  = 'Windows ve program klasorleri haric tutulamaz - zararli yazilim tam oraya yerlesir'
        DefRiskWild    = 'Joker karakterler burada fazla genis'
        DefRiskProfile = 'Bu kullanici profilinizin yarisi - indirmelerin dustugu klasor dahil'
        DefRiskTemp    = 'Gecici klasorler yeni indirilen zararli yazilimin olagan yeridir'
        DefConfirm     = 'Istisna gercekten ayarlansin mi?'
        DefVerifyErr   = 'Istisna uygulanmadi - kurcalama korumasi engelliyor olabilir'
        DefBadName     = 'Gecerli bir islem adi degil'
        DefAddEntry    = 'Haric tutma ekle'
        DefSearch      = 'Haric tutulanlarda ara'
        DefColNote     = 'Not'
        DefBadEntry    = 'Ne yol ne program ne de dosya uzantisi'
        DefRiskExt     = 'bu uzanti her yerde denetlenmeden kalir'
        DefRiskAnyPath = 'bu addaki her dosya icin gecerlidir'
        DefRiskCount   = 'riskli'
        DefReAdded     = 'Istisna yeniden eklendi'
        DefRemoved     = 'Istisna kaldirildi'

        CmdRedirect    = 'Kendi yonlendirmeniz algilandi - o cikti gunluge degil dosyaniza gider'
        CmdNoOut       = 'Komut hicbir cikti uretmedi'
        CmdTabHint     = 'Tab tamamlar, ok tuslari gecmisi getirir, Esc temizler'

        BakClean       = 'Yedekleri temizle'
        BakCleanNone   = 'Temizlenecek bir sey yok - klasor sinirlar icinde'
        BakKept        = 'saklandi'
        BakDropped     = 'kaldirildi'
        BakHeld        = 'acik degisiklikler tarafindan tutuluyor'
        BakFolder      = 'Yedek klasoru'

        BakScopes      = 'Yedeklenen alanlar'
        BakKeys        = 'anahtar'
        BakInvalid     = 'Gecerli bir kayit dosyasi degil - yedek alinmayacak'
        BakEmpty       = 'Disa aktarim bos kaldi - hicbir alan yedeklenemedi'
        BakMergeHint   = 'Dikkat: kayit dosyasi geri yazilir, degistirilmez. Yedekten sonra eklenen degerler yerinde kalir.'
        BakSvcTitle    = 'Baslatma turlerini yedekten geri yukle'
        BakSvcCount    = 'yedekteki hizmet'
        BakSvcGone     = 'hizmet artik yok'

        ChgTask        = 'Gorev'
        ChgFile        = 'Dosya'
        TskAction      = 'Gorevler'
        TskProtected   = 'Sistem gorevi - dokunulmadi'
        StuMoved       = 'Silinmek yerine yedege tasindi'
        StuRestored    = 'Kisayol geri yuklendi'
        FileGone       = 'Yedeklenen dosya artik bulunamiyor'
        FileBack       = 'Hedef klasor artik yok'

        ChgService     = 'Hizmet'
        SvcNoChange    = 'zaten bu durumda'
        SvcVerifyErr   = 'degisiklik uygulanmadi'
        SvcFallback    = 'Onceki baslatma turu bilinmiyor - Otomatik degil, El ile olarak ayarlandi'
        SvcRestored    = 'Baslatma turu geri yuklendi'
        SvcAction      = 'Hizmetler'

        CleanTitle     = 'Neler temizlensin?'
        CleanScan      = 'Boyutlar olculuyor'
        CleanPartial = 'Tarama tamamlanmadi - cok fazla dosya var, yalnizca bulunan kisim gosteriliyor'
        CleanNothing   = 'Temizlenecek bir sey yok - tum konumlar zaten bos'
        CleanTotal     = 'Secim'
        CleanFiles     = 'dosya'
        CleanRiskyHint = 'Gri girdiler bilerek secilmedi - aciklamayi okuyun'
        CleanFreed     = 'Bosaltilan'
        CleanLocked    = 'kilitli'
        CleanSvcStop   = 'Windows Update hizmetleri durduruluyor'
        CleanSvcStart  = 'Windows Update hizmetleri yeniden calisiyor'
        CleanSvcFail   = 'Guncellestirme hizmeti durdurulamadi - klasor atlandi'
        CleanYoung     = 'cok yeni, kullanimda'
        CtTemp         = 'Gecici dosyalar (kullanici)'
        CtTempLocal    = 'Gecici dosyalar (yerel)'
        CtTempWin      = 'Gecici dosyalar (Windows)'
        CtCbs          = 'Bilesen bakim gunlukleri'
        CtWer          = 'Hata raporlari'
        CtDeliv        = 'Teslim Iyilestirme (guncellestirme onbellegi)'
        CtPrefetch     = 'Prefetch - Windows bu dosyalari yeniden olusturur, sonraki ilk program acilislari daha yavas olur'
        CtSoftDist     = 'Guncellestirme onbellegi - yalnizca takilan guncellestirmelerde bosaltin, indirilmis guncellestirme yeniden indirilir'
        SetCleanConfirm = 'Temizlemeden once nelerin silinecegini sor'

        SetRememberWin = 'Pencere boyutunu ve konumunu hatirla'
        HealthCpu      = 'CPU yuku'
        HealthRam      = 'Bellek'
        HealthProc     = 'Islemler'
        HealthDisk     = 'Sistem surucusu'
        HealthStartup  = 'Baslangic'
        HealthReboot   = 'Yeniden baslatma bekliyor'
        RebCbs         = 'Sistem dosyalari'
        RebUpdate      = 'Windows Update'
        RebRename      = 'Bilgisayar adi'
        RebFiles       = 'Dosya adi degisiklikleri'
        RebTweak       = 'Uygulanan ayarlar'
        RebootNeeded   = 'Yeniden baslatma bekliyor - bazi degisiklikler ancak sonra etkili olur'
        HealthAllGood  = 'Sorun yok'
        HeadLogPath    = 'Gunluk dosyasi'
        LogPanelTitle  = 'BETIK CIKTISI  +  ISLEM GUNLUGU'
        FilterAll      = 'Tumu'
        FilterInfo     = 'Bilgi'
        FilterWarn     = 'Uyarilar'
        FilterError    = 'Hatalar'
        CmdPlaceholder = 'Komut yazin, Enter calistirir'
        CmdRun         = 'Calistir'
        CmdRunning     = 'Komut calisiyor'
        CmdDone        = 'Komut bitti'
        CmdBusy        = 'Zaten bir islem calisiyor'
        SearchStartup  = 'Baslangicta ara'
        SearchTasks    = 'Gorevlerde ara'
        SearchChanges  = 'Degisikliklerde ara'
        LblLink        = 'Baglanti hizi'
        HWBoard        = 'ANAKART / BIOS'
        HWNetwork      = 'AG BAGDASTIRICILARI'
        LblName        = 'Ad'
        LblCores       = 'Cekirdek/Is parcacigi'
        LblClock       = 'Maks. hiz'
        LblArch        = 'Mimari'
        LblVram        = 'Ekran bellegi'
        LblRes         = 'Cozunurluk'
        LblDriver      = 'Surucu'
        LblTotal       = 'Toplam'
        LblUsed        = 'Kullanilan'
        ColDrive       = 'Surucu'
        RepOpen        = 'acik'
        LblFree        = 'Bos'
        LblModules     = 'Moduller'
        LblVersion     = 'Surum'
        LblBuild       = 'Yapi'
        LblEdition     = 'Surum turu'
        LblRelease     = 'Surum'
        LblUptime      = 'Calisma suresi'
        LblVendor      = 'Uretici'
        LblModel       = 'Model'
        LblDate        = 'Tarih'
        LblSpeed       = 'Hiz'
        LblType        = 'Tur'
        LblMedia       = 'Ortam'
        LblMac         = 'MAC adresi'
        LblInstalled   = 'Kurulum'
        ColName        = 'Ad'
        ColDisplay     = 'Goruenen ad'
        ColStartType   = 'Baslangic turu'
        ColCommand     = 'Komut'
        ColScope       = 'Kapsam'
        ColTask        = 'Gorev'
        ColPath        = 'Yol'
        ColThreads     = 'Is parcaciklari'
        SetLogging     = 'Gunlukleme'
        SetNotify      = 'Bildirimler'
        StartupFolder  = 'Baslangic klasoru'
        LogUltimate    = 'Ustun performans plani etkinlestiriliyor'
        LogUltimateOn  = 'Ustun performans etkin'
        LogUltimateFallback = 'Ustun plan yok - Yuksek performans etkinlestirildi'
        LogDnsCleared  = 'DNS onbellegi temizlendi'
        LogHwCached    = 'Donanim bilgisi onbellege alindi'
        LogHwFailed    = 'Donanim sorgusu basarisiz'
        TwkAllOk       = 'tamamen uygulandi'
        TwkDescAnimations   = 'Pencere animasyonlari kapali - daha hizli hissettirir, menuler sert acilir'
        TwkDescTransparency = 'Saydamlik kapali - zayif grafik yongalarini rahatlatir'
        TwkDescSysMain      = 'On yukleme hizmeti kapali - daha az yazma yuku, programlar gec acilabilir'
        TwkDescSearchIdx    = 'Arama dizini kapali - yuku azaltir, dosya aramasi cok yavaslar'
        TwkDescFastStart    = 'Hizli baslatma kapali - temiz kapanma, acilis daha uzun surer'
        TwkDescThrottling   = 'Guc kisitlamasi kapali - tam hiz, daha yuksek tuketim'
        TwkDescPriority     = 'On plandaki pencereye oncelik - arka plan hizmetleri daha az islemci alir'
        TwkDescBgApps       = 'Arka plan uygulamalari kapali - yuku azaltir, bildirimler gelmez'
        TwkDescTips         = 'Baslat menusundeki Windows ipuclarini ve onerilerini kapat'
        TwkDescHibernate    = 'Hazirda bekletme kapali - birkac GB bosaltir, hizli baslatma gider'
        TwkDescParking      = 'Cekirdek parklama kapali - tum cekirdekler uyanik kalir, tuketim artar'
        TwkDescDebloat      = 'Onceden yuklu uygulamalari kaldir - tek tek onaylanir'
        TwkAskRevert        = 'Bu ayar etkin. Windows varsayilanina sifirlansin mi?'
        TwkRevertOk         = 'Windows varsayilanina sifirlandi'
        TwkNoRevert         = 'buradan geri alinamaz'
        TwkPartial     = 'yalnizca kismen uygulandi'
        TwkNone        = 'uygulanamadi'
        TwkNoAdmin     = 'yonetici haklari olmadan sistem anahtarlari kilitlidir'
        TwkLocked      = 'grup ilkesi veya kurcalama korumasi tarafindan engellendi'
        LogLanguage    = 'Dil'
        LogViewUnknown = 'Bilinmeyen gorunum'
        LogMonitorStopped = 'Tekrarlanan hatalar sonrasi izleme durduruldu'
        LogAppxMissing = 'Appx komutlari bu sistemde yok'
        LogNotPresent  = 'mevcut degil'
        LogTimeout     = 'Zaman asimi'
        LogExitCode    = 'Cikis kodu'
        SetTray        = 'Simge durumunda bildirim alanina kucult'
        TrayShow       = 'Pencereyi goster'
        TrayExit       = 'Cikis'
        TrayHint       = 'EB_Optimizer bildirim alaninda calismaya devam ediyor'
        SetRestoreView = 'Baslangicta son gorunumu ac'
        SetReset       = 'Ayarlari sifirla'
        SetSaved       = 'Ayarlar kaydedildi'
        SetFile        = 'Ayar dosyasi'
        MenuHelp       = 'Yardim'
        HelpTitle      = 'Yardim ve kisayollar'
        HelpSubtitle   = 'Kullanim, klavye kisayollari ve guvenlik notlari'
        Report         = 'Sistem raporu'
        ReportDesc     = 'Donanim, diskler, hizmetler ve baslangici HTML olarak disa aktar'
        BusyTitle      = 'Islem suruyor'
        BusyHint       = 'Lutfen bekleyin - pencere yanit vermeye devam eder'
        RepairWindow   = 'Ilerleme ayri konsol penceresinde gosterilir'
        RepSfcClean    = 'Butunluk ihlali bulunamadi'
        RepSfcFixed    = 'Bozuk dosyalar bulundu ve onarildi - yeniden baslatma onerilir'
        RepSfcBroken   = 'Bozuk dosyalar bulundu, hepsi onarilamadi - simdi DISM calistirin'
        RepDismOk      = 'Bilesen deposu saglikli'
        RepDismReboot  = 'Onarim basarili - yeniden baslatma gerekli'
        RepDismError   = 'DISM bir hata bildirdi'
        RepChkSched    = 'Denetim bir sonraki yeniden baslatmada calisacak'
        RepChkFixed    = 'Hatalar bulundu ve giderildi'
        RepNoLog       = 'Sonuc gunlugu okunamadi'
        SingleTitle    = 'Zaten calisiyor'
        SingleMsg      = 'EB_Optimizer zaten calisiyor. Mevcut pencere one getiriliyor.'
        BackupsTitle   = 'Yedekler'
        BackupsHint    = 'Her kayit defteri degisikliginden once .reg yedegi alinir'
        BackupRestore  = 'Geri yukle'
        BackupNone     = 'Henuz yedek yok'
        BackupSelect   = 'Lutfen once bir yedek secin'
        BackupDone     = 'Yedek geri yuklendi - yeniden baslatma gerekebilir'
        ColFile        = 'Dosya'
        ColType        = 'Tur'
        ColDate        = 'Tarih'
        ColSize        = 'Boyut'
        MenuChanges    = 'Degisiklikler'
        ChangesTitle   = 'Degisiklik gunlugu'
        ChangesSubtitle = 'Her kayit defteri degisikligi eski degeriyle - tek tek geri alinabilir'
        ChangeUndo     = 'Geri al'
        ChangeUndoAll  = 'Tumunu geri al'
        ChangeNone     = 'Kayitli degisiklik yok'
        ChangeUndone   = 'Geri alindi'
        ChangeNoUndo   = 'Geri alinacak bir sey yok'
        ChangeVerifyErr= 'Deger geri yazilamadi'
        ChangeOpen     = 'Gunluk dosyasini ac'
        ColKey         = 'Anahtar'
        ColOld         = 'Onceki'
        ColNew         = 'Sonraki'
        ColState       = 'Durum'
        EmptyFilter    = 'Eslesme yok'
        CtxCopy        = 'Satiri kopyala'
        CtxCopyAll     = 'Tumunu kopyala'
        CtxExport      = 'CSV olarak disa aktar'
        ExportDone     = 'Disa aktarildi'
        ExportEmpty    = 'Disa aktarilacak sey yok'
        EmptyNoEntries = 'Kayit yok'
        BusyCancelled  = 'Islem iptal edildi'
        BusyTooLong = 'Islem alisilmadik sekilde uzun surdu ve durduruldu'
        LblFreeSpace   = 'bos'
        KeyCtrl        = 'Ctrl'
        DefTypePath    = 'Yol'
        DefTypeProcess = 'Islem'
        DefTypeExt     = 'Dosya turu'
        LogTaskModule  = 'ScheduledTasks modulu kullanilamiyor'
        UpdService     = 'Windows Update hizmeti'
        AdminMode      = 'Yonetici'
        PrivClickToDo   = 'Click to Do / yapay zeka kapat'
        PrivWidgets     = 'Widget ve haberleri kapat'
        PrivWebSearch   = 'Baslat menusunde web aramasi kapali'
        PrivEdgeAI      = 'Edge Copilot cubugunu kapat'
        StateOn         = 'ETKIN'
        StatePart       = 'KISMEN'
        PrivRecall      = 'Recall / Windows yapay zekasini kapat'
        PrivCopilot     = 'Copilot kapat'
        WmicGone        = 'wmic, Windows 11 26H2 ile Windows icinden kaldirildi - WMI kendisi kaliyor'
        WmicHint        = 'Yerine'
        TipLogCollapse  = 'Gunluk bolumunu daralt'
        TipLogExpand    = 'Gunluk bolumunu genislet'
        TipMaximize     = 'Buyut / geri yukle  (F11)'
        TipMinimize     = 'Simge durumuna kucult'
        TipCpu          = 'Islemci yuku'
        TipRam          = 'Bellek kullanimi'
        TipDisk         = 'Kullanim'
        TipNet          = 'Ag veri akisi (toplam)'
        TipClock        = 'Saat'
        TipLogBox       = 'Islem gunlugu  -  Ctrl+L gorunumu temizler'
        TipLogClear     = 'Gorunumu temizle  (Ctrl+L)'
        ChkdskScheduled = 'Kontrol planlandi ve bir sonraki yeniden baslatmada calisacak.'
        BusyStep       = 'Adim'
        LogFile         = 'Gunluk dosyasi'
        LogOpenTip      = 'Bu oturumun gunluk dosyasini ac'
        LogSearchHint   = 'Gunlukte ara'
        TipLogSearch    = 'Birden fazla kelime = VE aramasi, basindaki eksi haric tutar. Esc temizler.'
        LogMatchCount   = 'eslesme'
        CrashTitle      = 'Beklenmeyen hata'
        CrashMsg        = 'Beklenmeyen bir hata olustu. Program calismaya devam ediyor. Ayrintilar kaydedildi:'
    }
    AR = @{
        ChgDefender    = 'استثناء Defender'
        DiskBrowserOpen = 'المتصفح لا يزال يعمل ويبقي ذاكرة التخزين المؤقت مفتوحة'
        DiskAllLocked   = 'جميع الملفات قيد الاستخدام - لم يُحذف شيء'
        CtWuLog   = 'سجلات Windows Update'
        CtShader  = 'ذاكرة التظليل لبطاقة الرسوميات'
        CtPanther = 'سجلات الإعداد - تلزم لتشخيص المشكلات بعد تحديث الميزات'
        CtDump    = 'ملفات تفريغ الأعطال - بدونها لا يمكن تحليل الشاشة الزرقاء'
        CtRecycle = 'سلة المحذوفات - ستُحذف الملفات نهائياً بعد ذلك'
        TskLastRun     = 'آخر تشغيل'
        TskResult      = 'النتيجة'
        TskHidden      = 'مهام Windows مخفية'
        TskShowWin     = 'مهام Windows'
        TskShowWinTip  = 'إظهار أو إخفاء المهام ضمن \Microsoft'
        TskRunDisabled = 'المهمة معطلة - فعّلها أولاً'
        TskRunning     = 'قيد التشغيل بالفعل'
        TskResOk       = 'نجحت'
        TskResError    = 'خطأ'
        TskResNotFound = 'الملف غير موجود'
        TskResReady    = 'جاهزة'
        TskResRunning  = 'قيد التشغيل'
        TskResDisabled = 'معطلة'
        TskResNever    = 'لم تُشغَّل'
        TskResStopped  = 'أُوقفت'
        TskResUnknown  = 'غير معروف'
        SvcAuto          = 'تلقائي'
        SvcAutoDelayed   = 'تلقائي (مؤجل)'
        SvcManual        = 'يدوي'
        SvcDisabled      = 'معطل'
        SvcBoot          = 'بدء النظام'
        SvcSystem        = 'نظام'
        SvcStartDisabled = 'الخدمة معطلة - فعّلها أولاً'
        SvcStillRunning  = 'تستمر في العمل حتى إعادة التشغيل التالية'
        SvcDependents    = 'سيتم إيقافها أيضاً'
        SvcDependentsAsk = 'هذه الخدمات العاملة تعتمد عليها وسيتم إيقافها أيضاً:'
        ProcHung        = 'لا يستجيب'
        ProcOk          = 'قيد التشغيل'
        ProcNoSelection = 'لم يتم تحديد عملية'
        ProcKillAsk     = 'إنهاء هذه العمليات وعملياتها الفرعية؟ ستفقد البيانات غير المحفوظة.'
        Start32        = 'النظام (32 بت)'
        StartOnce      = 'لمرة واحدة'
        StartCommon    = 'جميع المستخدمين'
        StartFolder    = 'مجلد'
        StuEnabled     = 'مفعل'
        StuDisabled    = 'معطل'
        StuMissing     = 'الهدف مفقود'
        StuNoToggle    = 'لا يمكن تعطيله'
        StuNoChange    = 'بالفعل في الحالة المطلوبة'
        StuNoEntry     = 'إدخال غير صالح'
        StuNoSelection = 'لم يتم تحديد شيء'
        HWBattery     = 'البطارية'
        HWSecurity    = 'الأمان'
        LblCharge     = 'مستوى الشحن'
        LblWear       = 'التآكل'
        LblDesign     = 'السعة التصميمية'
        LblFullCharge = 'الشحن الكامل'
        LblSlots      = 'الفتحات'
        LblConfigured = 'التردد الفعلي'
        LblTpm        = 'TPM'
        LblSecureBoot = 'Secure Boot'
        HwUnknown     = 'غير متاح'
        HwXmpHint     = 'أقل من التردد المقنن، XMP/EXPO غير مفعل'
        HwActive      = 'مفعل'
        HwInactive    = 'غير مفعل'
        HwOnBattery   = 'يعمل على البطارية'
        HwExportBusy  = 'لا تزال البيانات قيد التحميل - التصدير ممكن بعد ذلك'
        HealthDefRt   = 'الحماية في الوقت الفعلي متوقفة'
        HealthDefSig  = 'تعريفات الفيروسات قديمة'
        HealthRestore = 'لا توجد نقطة استعادة حديثة'
        HealthUptime  = 'مدة التشغيل دون إعادة تشغيل'
        HealthMore    = 'بنود أخرى'
        HealthAction  = 'يتطلب إجراءً'
        UpdPaused        = 'التحديثات متوقفة مؤقتاً حتى'
        UpdNotPaused     = 'التحديثات ليست متوقفة مؤقتاً'
        UpdPauseDays     = 'يوم'
        UpdPauseUntil    = 'الإيقاف حتى'
        UpdPauseMax      = 'يقبل Windows 35 يوماً كحد أقصى - بعدها تستأنف التحديثات من تلقاء نفسها'
        UpdPauseConfirm  = 'هل تريد إيقاف تحديثات Windows مؤقتاً الآن؟'
        UpdResumeConfirm = 'هل تريد استئناف التحديثات؟'
        UpdResumed       = 'تم استئناف التحديثات'
        UpdExpired       = 'انتهت مدة الإيقاف المؤقت الأخيرة'
        UpdSvcStop       = 'تعذر إيقاف الخدمة'
        UpdSvcStopping   = 'جارٍ إيقاف الخدمات'
        UpdSvcStarting   = 'جارٍ تشغيل الخدمات'
        UpdSvcRestart    = 'تمت إعادة تشغيل الخدمات'
        UpdRepairAbort   = 'تم إلغاء الإصلاح - لم يتغير شيء'
        UpdRepairWarn    = 'ستتم إعادة تسمية ذاكرة التحديث المؤقتة. سيختفي سجل التحديثات، وسيستغرق البحث التالي وقتاً أطول مرة واحدة، وسيعاد تنزيل مئات الميغابايت. تبقى المجلدات باسم ‎.old ويمكن استعادتها عبر التراجع.'
        UpdLeftovers     = 'مجلدات إصلاح قديمة'
        UpdCleanOld      = 'هل تريد إزالتها الآن؟'
        BenchRunning    = 'هناك قياس قيد التشغيل بالفعل'
        BenchWarmup     = 'جولة إحماء'
        BenchSpread     = 'التشتت'
        BenchSingle     = 'نواة واحدة'
        BenchUnstable   = 'الجولات متباينة بشكل كبير - كان الجهاز مشغولاً أثناء القياس'
        BenchBusyWarn   = 'حمل المعالج مرتفع قبل البدء - الانتظار يعطي قيماً قابلة للمقارنة'
        BenchCached     = 'تم القياس مع التخزين المؤقت - قيمة القراءة تأتي من ذاكرة نظام الملفات وليس من القرص'
        BenchUnbuffered = 'تم القياس بدون ذاكرة نظام الملفات'
        BenchNoSpace    = 'المساحة الحرة غير كافية لاختبار القرص'
        BenchLast       = 'آخر قياس'
        BenchBetter     = 'أفضل'
        BenchWorse      = 'أسوأ'
        BenchSame       = 'دون تغيير'
        BenchWrite      = 'كتابة'
        BenchRead       = 'قراءة'
        BenchDrive      = 'ملف الاختبار'
        ChgDns          = 'خادم DNS'
        NetDnsAction    = 'تغيير DNS'
        NetDnsAuto      = 'تلقائي (DHCP)'
        NetDnsConfirm   = 'هل تريد تحويل DNS لهذه المحولات إلى Cloudflare؟'
        NetDnsReset     = 'هل تريد إعادة DNS إلى الوضع التلقائي (DHCP)؟'
        NetDnsDomain    = 'هذا الجهاز منضم إلى مجال - خادم DNS خارجي لن يحل أسماء شبكة الشركة'
        NetDnsVpn       = 'يوجد اتصال VPN نشط - قد يتوقف تحليل الأسماء الخاص به'
        NetDnsNone      = 'لم يتم العثور على محول شبكة متصل'
        NetDnsGone      = 'المحول لم يعد موجوداً'
        NetDnsVerifyErr = 'لم يتم تطبيق خادم DNS'
        NetDnsRestored  = 'تمت إعادة ضبط DNS'
        NetNagleConfirm = 'هل تريد تعطيل خوارزمية Nagle على هذه الواجهات؟'
        NetNagleRevert  = 'هل تريد إزالة إعدادات Nagle (الوضع الافتراضي لـ Windows)؟'
        NetNagleCount   = 'مضبوط بالفعل'
        NetNagleNone    = 'لم يتم العثور على واجهة بعنوان IPv4'
        NetResetWarn    = 'ستتم إعادة تعيين Winsock وTCP/IP. ستفقد عناوين IP الثابتة وإعدادات الوكيل وبرامج التصفية (VPN وجدار الحماية)، وينقطع الاتصال لفترة قصيرة ويلزم إعادة التشغيل.'
        NetResetOk      = 'اكتملت إعادة التعيين'
        NetResetPart    = 'تمت إعادة التعيين جزئياً فقط'
        NetResetFail    = 'فشلت إعادة التعيين'
        NetPingOk       = 'لا يوجد فقد للحزم'
        NetPingLoss     = 'فقد الحزم'
        NetPingDead     = 'لا يوجد رد'
        DefAction      = 'استثناءات Defender'
        DefBlocked     = 'لن يتم تعيين هذا الاستثناء'
        DefRiskRoot    = 'استثناء جذر محرك الأقراص يعطّل الحماية فعلياً'
        DefRiskSystem  = 'لا يجوز استثناء مجلدات Windows والبرامج - فهناك تحديداً تستقر البرمجيات الخبيثة'
        DefRiskWild    = 'أحرف البدل واسعة أكثر من اللازم هنا'
        DefRiskProfile = 'هذا نصف ملفك الشخصي - بما في ذلك مجلد التنزيلات'
        DefRiskTemp    = 'المجلدات المؤقتة هي المكان المعتاد للبرمجيات الخبيثة المنزّلة حديثاً'
        DefConfirm     = 'هل تريد فعلاً تعيين هذا الاستثناء؟'
        DefVerifyErr   = 'لم يتم تطبيق الاستثناء - قد تمنعه الحماية من العبث'
        DefBadName     = 'ليس اسم عملية صالحاً'
        DefAddEntry    = 'إضافة استثناء'
        DefSearch      = 'البحث في الاستثناءات'
        DefColNote     = 'ملاحظة'
        DefBadEntry    = 'ليس مساراً ولا برنامجاً ولا امتداد ملف'
        DefRiskExt     = 'يبقى هذا الامتداد دون فحص في كل مكان'
        DefRiskAnyPath = 'ينطبق على كل ملف بهذا الاسم'
        DefRiskCount   = 'خطر'
        DefReAdded     = 'تمت إعادة إضافة الاستثناء'
        DefRemoved     = 'تمت إزالة الاستثناء'

        CmdRedirect    = 'تم رصد إعادة توجيه خاصة بك - سيذهب هذا الإخراج إلى ملفك لا إلى السجل'
        CmdNoOut       = 'لم ينتج الأمر أي إخراج'
        CmdTabHint     = 'Tab يكمل، الأسهم تستعيد، Esc يمسح'

        BakClean       = 'تنظيف النسخ الاحتياطية'
        BakCleanNone   = 'لا شيء للتنظيف - المجلد ضمن الحد'
        BakKept        = 'محفوظ'
        BakDropped     = 'تمت إزالته'
        BakHeld        = 'محجوز بسبب تغييرات مفتوحة'
        BakFolder      = 'مجلد النسخ الاحتياطية'

        BakScopes      = 'المناطق المحفوظة'
        BakKeys        = 'مفاتيح'
        BakInvalid     = 'ليس ملف سجل صالحاً - لن يتم استيراد النسخة'
        BakEmpty       = 'بقي التصدير فارغاً - تعذر حفظ أي منطقة'
        BakMergeHint   = 'تنبيه: يتم دمج ملف السجل وليس استبداله. القيم المضافة بعد النسخ الاحتياطي تبقى كما هي.'
        BakSvcTitle    = 'استعادة أنواع البدء من النسخة الاحتياطية'
        BakSvcCount    = 'خدمات في النسخة'
        BakSvcGone     = 'لم تعد الخدمة موجودة'

        ChgTask        = 'مهمة'
        ChgFile        = 'ملف'
        TskAction      = 'المهام'
        TskProtected   = 'مهمة نظام - لم تُمس'
        StuMoved       = 'تم النقل إلى النسخة الاحتياطية بدل الحذف'
        StuRestored    = 'تمت استعادة الاختصار'
        FileGone       = 'لم يعد الملف المحفوظ موجوداً'
        FileBack       = 'لم يعد المجلد الهدف موجوداً'

        ChgService     = 'خدمة'
        SvcNoChange    = 'بهذه الحالة بالفعل'
        SvcVerifyErr   = 'لم يتم تطبيق التغيير'
        SvcFallback    = 'نوع البدء السابق غير معروف - تم الضبط على يدوي وليس تلقائي'
        SvcRestored    = 'تمت استعادة نوع البدء'
        SvcAction      = 'الخدمات'

        CleanTitle     = 'ما الذي تريد تنظيفه؟'
        CleanScan      = 'جارٍ قياس الأحجام'
        CleanPartial = 'الفحص غير مكتمل - عدد الملفات كبير جداً، يُعرض ما تم العثور عليه فقط'
        CleanNothing   = 'لا شيء للتنظيف - جميع المواقع فارغة بالفعل'
        CleanTotal     = 'المحدد'
        CleanFiles     = 'ملفات'
        CleanRiskyHint = 'العناصر الرمادية غير محددة عن قصد - اقرأ الملاحظة'
        CleanFreed     = 'تم تحرير'
        CleanLocked    = 'مقفل'
        CleanSvcStop   = 'جارٍ إيقاف خدمات Windows Update'
        CleanSvcStart  = 'خدمات Windows Update تعمل من جديد'
        CleanSvcFail   = 'تعذر إيقاف خدمة التحديث - تم تخطي المجلد'
        CleanYoung     = 'حديث جداً، قيد الاستخدام'
        CtTemp         = 'ملفات مؤقتة (المستخدم)'
        CtTempLocal    = 'ملفات مؤقتة (محلية)'
        CtTempWin      = 'ملفات مؤقتة (Windows)'
        CtCbs          = 'سجلات صيانة المكونات'
        CtWer          = 'تقارير الأخطاء'
        CtDeliv        = 'تحسين التسليم (ذاكرة التحديثات)'
        CtPrefetch     = 'Prefetch - يعيد Windows بناء هذه الملفات، وستكون عمليات التشغيل الأولى بعدها أبطأ'
        CtSoftDist     = 'ذاكرة التحديثات - أفرغها فقط عند تعطل التحديثات، سيُعاد تنزيل أي تحديث مكتمل'
        SetCleanConfirm = 'اسأل عما سيُحذف قبل التنظيف'

        SetRememberWin = 'تذكر حجم النافذة وموضعها'
        HealthCpu      = 'حمل المعالج'
        HealthRam      = 'الذاكرة'
        HealthProc     = 'العمليات'
        HealthDisk     = 'قرص النظام'
        HealthStartup  = 'بدء التشغيل'
        HealthReboot   = 'إعادة تشغيل معلقة'
        RebCbs         = 'ملفات النظام'
        RebUpdate      = 'Windows Update'
        RebRename      = 'اسم الكمبيوتر'
        RebFiles       = 'إعادة تسمية الملفات'
        RebTweak       = 'التعديلات المطبقة'
        RebootNeeded   = 'هناك إعادة تشغيل معلقة - بعض التغييرات لا تسري إلا بعدها'
        HealthAllGood  = 'لا توجد ملاحظات'
        HeadLogPath    = 'ملف السجل'
        LogPanelTitle  = 'مخرجات البرنامج  +  سجل العمليات'
        FilterAll      = 'الكل'
        FilterInfo     = 'معلومات'
        FilterWarn     = 'تحذيرات'
        FilterError    = 'أخطاء'
        CmdPlaceholder = 'اكتب أمرا ثم اضغط Enter'
        CmdRun         = 'تشغيل'
        CmdRunning     = 'الأمر قيد التنفيذ'
        CmdDone        = 'انتهى الأمر'
        CmdBusy        = 'هناك عملية قيد التنفيذ بالفعل'
        SearchStartup  = 'البحث في بدء التشغيل'
        SearchTasks    = 'البحث في المهام'
        SearchChanges  = 'البحث في التغييرات'
        LblLink        = 'سرعة الاتصال'
        HWBoard        = 'اللوحة الأم / BIOS'
        HWNetwork      = 'محولات الشبكة'
        LblName        = 'الاسم'
        LblCores       = 'الأنوية/الخيوط'
        LblClock       = 'أقصى تردد'
        LblArch        = 'المعمارية'
        LblVram        = 'ذاكرة الرسومات'
        LblRes         = 'الدقة'
        LblDriver      = 'التعريف'
        LblTotal       = 'الإجمالي'
        LblUsed        = 'المستخدم'
        ColDrive       = 'محرك الأقراص'
        RepOpen        = 'مفتوح'
        LblFree        = 'الحر'
        LblModules     = 'الوحدات'
        LblVersion     = 'الإصدار'
        LblBuild       = 'البناء'
        LblEdition     = 'النسخة'
        LblRelease     = 'الإصدار'
        LblUptime      = 'مدة التشغيل'
        LblVendor      = 'الشركة'
        LblModel       = 'الطراز'
        LblDate        = 'التاريخ'
        LblSpeed       = 'التردد'
        LblType        = 'النوع'
        LblMedia       = 'الوسيط'
        LblMac         = 'عنوان MAC'
        LblInstalled   = 'تاريخ التثبيت'
        ColName        = 'الاسم'
        ColDisplay     = 'الاسم المعروض'
        ColStartType   = 'نوع البدء'
        ColCommand     = 'الأمر'
        ColScope       = 'النطاق'
        ColTask        = 'المهمة'
        ColPath        = 'المسار'
        ColThreads     = 'المسارات'
        SetLogging     = 'السجل'
        SetNotify      = 'الإشعارات'
        StartupFolder  = 'مجلد بدء التشغيل'
        LogUltimate    = 'تفعيل خطة الأداء الفائق'
        LogUltimateOn  = 'الأداء الفائق مفعل'
        LogUltimateFallback = 'خطة الأداء الفائق غير متوفرة - تم تفعيل الأداء العالي'
        LogDnsCleared  = 'تم مسح ذاكرة DNS'
        LogHwCached    = 'تم تخزين بيانات العتاد مؤقتاً'
        LogHwFailed    = 'فشل استعلام العتاد'
        TwkAllOk       = 'تم التطبيق بالكامل'
        TwkDescAnimations   = 'إيقاف حركات النوافذ - يبدو أسرع، لكن القوائم تظهر فجأة'
        TwkDescTransparency = 'إيقاف الشفافية - يخفف الحمل عن بطاقات الرسوم الضعيفة'
        TwkDescSysMain      = 'إيقاف خدمة التحميل المسبق - كتابة أقل على القرص، وقد تبطؤ بداية البرامج'
        TwkDescSearchIdx    = 'إيقاف فهرس البحث - يقلل الحمل، لكن البحث عن الملفات يصبح أبطأ بكثير'
        TwkDescFastStart    = 'إيقاف البدء السريع - إيقاف تشغيل نظيف، لكن الإقلاع يستغرق وقتاً أطول'
        TwkDescThrottling   = 'إيقاف خفض الأداء - تردد كامل واستهلاك أعلى'
        TwkDescPriority     = 'تفضيل نافذة المقدمة - خدمات الخلفية تحصل على وقت معالجة أقل'
        TwkDescBgApps       = 'إيقاف تطبيقات الخلفية - يقلل الحمل، وتتوقف الإشعارات'
        TwkDescTips         = 'إيقاف تلميحات واقتراحات Windows في قائمة ابدأ'
        TwkDescHibernate    = 'إيقاف الإسبات - يحرر عدة غيغابايت، ويلغي البدء السريع'
        TwkDescParking      = 'إيقاف إيقاف الأنوية - تبقى كل الأنوية نشطة، والاستهلاك أعلى'
        TwkDescDebloat      = 'إزالة التطبيقات المثبتة مسبقاً - يتم التأكيد لكل منها'
        TwkAskRevert        = 'هذا الإعداد مفعل. هل تريد إعادته إلى الوضع الافتراضي لـ Windows؟'
        TwkRevertOk         = 'أُعيد إلى الوضع الافتراضي لـ Windows'
        TwkNoRevert         = 'لا يمكن التراجع عنه من هنا'
        TwkPartial     = 'تم التطبيق جزئيا فقط'
        TwkNone        = 'تعذر التطبيق'
        TwkNoAdmin     = 'بدون صلاحيات المسؤول تكون مفاتيح النظام مقفلة'
        TwkLocked      = 'محظور بواسطة نهج المجموعة أو الحماية من العبث'
        LogLanguage    = 'اللغة'
        LogViewUnknown = 'عرض غير معروف'
        LogMonitorStopped = 'تم إيقاف المراقبة بعد أخطاء متكررة'
        LogAppxMissing = 'أوامر Appx غير متوفرة على هذا النظام'
        LogNotPresent  = 'غير موجود'
        LogTimeout     = 'انتهت المهلة'
        LogExitCode    = 'رمز الخروج'
        SetTray        = 'التصغير إلى منطقة الإشعارات'
        TrayShow       = 'إظهار النافذة'
        TrayExit       = 'إنهاء'
        TrayHint       = 'يواصل EB_Optimizer العمل في منطقة الإشعارات'
        SetRestoreView = 'فتح آخر صفحة عند البدء'
        SetReset       = 'إعادة تعيين الإعدادات'
        SetSaved       = 'تم حفظ الإعدادات'
        SetFile        = 'ملف الإعدادات'
        MenuHelp       = 'مساعدة'
        HelpTitle      = 'المساعدة واختصارات لوحة المفاتيح'
        HelpSubtitle   = 'طريقة الاستخدام والاختصارات وملاحظات الأمان'
        Report         = 'تقرير النظام'
        ReportDesc     = 'تصدير العتاد والأقراص والخدمات وبرامج بدء التشغيل كملف HTML'
        BusyTitle      = 'العملية قيد التنفيذ'
        BusyHint       = 'يرجى الانتظار - تبقى النافذة قابلة للاستخدام'
        RepairWindow   = 'يظهر التقدم في نافذة وحدة التحكم المنفصلة'
        RepSfcClean    = 'لم يتم العثور على انتهاكات للسلامة'
        RepSfcFixed    = 'تم العثور على ملفات تالفة وإصلاحها - يوصى بإعادة التشغيل'
        RepSfcBroken   = 'تم العثور على ملفات تالفة وتعذر إصلاح بعضها - شغل DISM الآن'
        RepDismOk      = 'مخزن المكونات سليم'
        RepDismReboot  = 'تم الإصلاح بنجاح - يلزم إعادة التشغيل'
        RepDismError   = 'أبلغ DISM عن خطأ'
        RepChkSched    = 'سيتم إجراء الفحص عند إعادة التشغيل التالية'
        RepChkFixed    = 'تم العثور على أخطاء وإصلاحها'
        RepNoLog       = 'تعذرت قراءة سجل النتائج'
        SingleTitle    = 'قيد التشغيل بالفعل'
        SingleMsg      = 'EB_Optimizer قيد التشغيل بالفعل. سيتم إحضار النافذة الحالية إلى المقدمة.'
        BackupsTitle   = 'النسخ الاحتياطية'
        BackupsHint    = 'يتم حفظ نسخة reg. قبل كل تعديل في السجل'
        BackupRestore  = 'استعادة'
        BackupNone     = 'لا توجد نسخ احتياطية'
        BackupSelect   = 'يرجى اختيار نسخة احتياطية أولاً'
        BackupDone     = 'تمت استعادة النسخة - قد تتطلب إعادة التشغيل'
        ColFile        = 'الملف'
        ColType        = 'النوع'
        ColDate        = 'التاريخ'
        ColSize        = 'الحجم'
        MenuChanges    = 'التغييرات'
        ChangesTitle   = 'سجل التغييرات'
        ChangesSubtitle = 'كل تغيير في السجل مع قيمته السابقة - يمكن التراجع عنه'
        ChangeUndo     = 'تراجع'
        ChangeUndoAll  = 'تراجع عن الكل'
        ChangeNone     = 'لا توجد تغييرات مسجلة'
        ChangeUndone   = 'تم التراجع'
        ChangeNoUndo   = 'لا يوجد ما يمكن التراجع عنه'
        ChangeVerifyErr= 'تعذرت إعادة كتابة القيمة'
        ChangeOpen     = 'فتح ملف السجل'
        ColKey         = 'المفتاح'
        ColOld         = 'قبل'
        ColNew         = 'بعد'
        ColState       = 'الحالة'
        EmptyFilter    = 'لا توجد نتائج'
        CtxCopy        = 'نسخ الصف'
        CtxCopyAll     = 'نسخ الكل'
        CtxExport      = 'تصدير كملف CSV'
        ExportDone     = 'تم التصدير'
        ExportEmpty    = 'لا يوجد ما يصدر'
        EmptyNoEntries = 'لا توجد إدخالات'
        BusyCancelled  = 'تم إلغاء العملية'
        BusyTooLong = 'استغرقت العملية وقتاً غير معتاد فتم إيقافها'
        LblFreeSpace   = 'متاح'
        KeyCtrl        = 'Ctrl'
        DefTypePath    = 'مسار'
        DefTypeProcess = 'عملية'
        DefTypeExt     = 'نوع الملف'
        LogTaskModule  = 'وحدة ScheduledTasks غير متوفرة'
        UpdService     = 'خدمة Windows Update'
        AdminMode      = 'مسؤول'
        PrivClickToDo   = 'تعطيل Click to Do ووكلاء الذكاء'
        PrivWidgets     = 'تعطيل الأدوات والأخبار'
        PrivWebSearch   = 'إيقاف بحث الويب في قائمة ابدأ'
        PrivEdgeAI      = 'تعطيل شريط Copilot في Edge'
        StateOn         = 'مفعل'
        StatePart       = 'جزئي'
        PrivRecall      = 'تعطيل Recall / ذكاء Windows'
        PrivCopilot     = 'تعطيل Copilot'
        WmicGone        = 'تمت إزالة wmic من Windows بدءاً من الإصدار 26H2 - أما WMI نفسه فيبقى'
        WmicHint        = 'البديل'
        TipLogCollapse  = 'طي شريط السجل'
        TipLogExpand    = 'توسيع شريط السجل'
        TipMaximize     = 'تكبير / استعادة  (F11)'
        TipMinimize     = 'تصغير'
        TipCpu          = 'حمل المعالج'
        TipRam          = 'استخدام الذاكرة'
        TipDisk         = 'استخدام'
        TipNet          = 'معدل نقل الشبكة (الإجمالي)'
        TipClock        = 'الوقت'
        TipLogBox       = 'سجل الإجراءات  -  Ctrl+L يمسح العرض'
        TipLogClear     = 'مسح العرض  (Ctrl+L)'
        ChkdskScheduled = 'تمت جدولة الفحص وسيبدأ عند إعادة التشغيل التالية.'
        BusyStep       = 'خطوة'
        LogFile         = 'ملف السجل'
        LogOpenTip      = 'فتح ملف سجل هذه الجلسة'
        LogSearchHint   = 'ابحث في السجل'
        TipLogSearch    = 'عدة كلمات = بحث AND، وعلامة ناقص قبلها تستثني. Esc يمسح.'
        LogMatchCount   = 'نتائج'
        CrashTitle      = 'خطأ غير متوقع'
        CrashMsg        = 'حدث خطأ غير متوقع. البرنامج ما زال يعمل. تم حفظ التفاصيل في:'
    }
}
foreach ($langCode in $script:ExtraStrings.Keys) {
    if (-not $script:Languages.ContainsKey($langCode)) { continue }
    foreach ($entry in $script:ExtraStrings[$langCode].GetEnumerator()) {
        $script:Languages[$langCode][$entry.Key] = $entry.Value
    }
}

function Get-Text {
    param([string]$Key)

    if ([string]::IsNullOrWhiteSpace($Key)) { return '' }
    if ($script:CurrentLangDict -and $script:CurrentLangDict.ContainsKey($Key)) { return $script:CurrentLangDict[$Key] }
    if ($script:Languages['EN'].ContainsKey($Key)) { return $script:Languages['EN'][$Key] }
    return $Key
}

function Set-Language {
    param([string]$Code)
    if ($script:Languages.ContainsKey($Code)) {
        $script:Config.CurrentLang = $Code
        $script:CurrentLangDict = $script:Languages[$Code]

        # Arabic is right-to-left: mirror text alignment, reading order and
        # scrollbar side. RightToLeftLayout (full geometric mirroring) stays
        # OFF on purpose - every view here is laid out in absolute pixels and
        # mirroring would move the sidebar, the resize grip and the custom
        # painted panels to the wrong side.
        if ($script:MainForm -and -not $script:MainForm.IsDisposed) {
            try {
                $script:MainForm.RightToLeft =
                if ($Code -eq 'AR') { [System.Windows.Forms.RightToLeft]::Yes }
                else { [System.Windows.Forms.RightToLeft]::No }
            }
            catch { }
        }

        # Cached rows may carry translated text - they must not survive a
        # language switch.
        if (Get-Command Clear-DataCache -ErrorAction SilentlyContinue) { Clear-DataCache }
        # Die Kurzhinweise der Titelleiste und des Kopfbereichs entstehen nur
        # einmal - ohne diesen Aufruf blieben sie in der alten Sprache stehen.
        if (Get-Command Update-StaticTips -ErrorAction SilentlyContinue) { Update-StaticTips }
        return $true
    }
    return $false
}

#endregion 2. LOCALIZATION


#region 3. CORE HELPERS (LOG, BACKUP, FORMAT, SYSTEM)

# --- Session log file ---------------------------------------------------------
# The RichTextBox log is gone the moment the window closes. Everything is
# mirrored into a plain text file so a failed tweak can still be traced later.
$script:LogWriter = $null
$script:LogFilePath = $null
$script:LogPending = 0
$script:CrashCount = 0

function Get-LogDirectory {
    try {
        $dir = Join-Path $script:Config.BackupDir 'Logs'
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
        return $dir
    }
    catch { return $null }
}

function Initialize-LogFile {
    if ($script:LogWriter) { return $script:LogWriter }
    try {
        $dir = Get-LogDirectory
        if (-not $dir) { return $null }

        # Keep the 10 most recent sessions, drop the rest
        Get-ChildItem -LiteralPath $dir -Filter 'session_*.log' -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -Skip 10 |
            Remove-Item -Force -ErrorAction SilentlyContinue

        $script:LogFilePath = Join-Path $dir ('session_{0}.log' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
        $enc = New-Object System.Text.UTF8Encoding($false)
        $sw = New-Object System.IO.StreamWriter($script:LogFilePath, $true, $enc)
        $sw.AutoFlush = $false
        $sw.WriteLine("==== $($script:Config.AppName) v$($script:Config.Version) ====")
        $sw.WriteLine("Start    : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        $sw.WriteLine("Rechner  : $env:COMPUTERNAME \ $env:USERNAME")
        $sw.WriteLine("PowerShell: $($PSVersionTable.PSVersion) | OS: $([System.Environment]::OSVersion.Version)")
        $sw.WriteLine(('-' * 60))
        $sw.Flush()
        $script:LogWriter = $sw
        try { Update-LogPathLabel } catch { }
    }
    catch {
        $script:LogWriter = $null
        $script:LogFilePath = $null
    }
    return $script:LogWriter
}

function Write-LogFileLine {
    param([string]$Line, [string]$Type = 'INFO')
    try {
        $w = Initialize-LogFile
        if (-not $w) { return }
        $w.WriteLine($Line)
        $script:LogPending++
        # Flush immediately on problems - those are the lines that matter if
        # the process dies right afterwards.
        if ($script:LogPending -ge 20 -or $Type -in @('ERROR', 'WARNING')) {
            $w.Flush()
            $script:LogPending = 0
        }
    }
    catch { }
}

function Close-LogFile {
    try { if ($script:lblLogPath -and -not $script:lblLogPath.IsDisposed) { $script:lblLogPath.Text = '---' } } catch { }
    try {
        if ($script:LogWriter) {
            $script:LogWriter.WriteLine(('-' * 60))
            $script:LogWriter.WriteLine("Ende     : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
            $script:LogWriter.Flush()
            $script:LogWriter.Dispose()
        }
    }
    catch { }
    finally {
        $script:LogWriter = $null
        $script:LogPending = 0
    }
}

function Open-SessionLog {
    try {
        if ($script:LogWriter) { $script:LogWriter.Flush(); $script:LogPending = 0 }
        if ($script:LogFilePath -and (Test-Path -LiteralPath $script:LogFilePath)) {
            Start-Process $script:LogFilePath
            return
        }
        $dir = Get-LogDirectory
        if ($dir) { Start-Process $dir }
    }
    catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'WARNING' }
}

function Save-CrashReport {
    param($ErrorObject, [string]$Origin = 'ThreadException')

    try {
        $dir = Get-LogDirectory
        if (-not $dir) { return $null }
        $file = Join-Path $dir ('crash_{0}.txt' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine("==== $($script:Config.AppName) v$($script:Config.Version) - CRASH ====")
        [void]$sb.AppendLine("Zeit     : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        [void]$sb.AppendLine("Quelle   : $Origin")
        [void]$sb.AppendLine("Ansicht  : $($script:Config.CurrentView)")
        [void]$sb.AppendLine("PowerShell: $($PSVersionTable.PSVersion) | OS: $([System.Environment]::OSVersion.Version)")
        [void]$sb.AppendLine(('-' * 60))

        $ex = $ErrorObject
        if ($ex -is [System.Management.Automation.ErrorRecord]) { $ex = $ex.Exception }
        $depth = 0
        while ($ex -and $depth -lt 5) {
            [void]$sb.AppendLine("$($ex.GetType().FullName): $($ex.Message)")
            if ($ex.StackTrace) { [void]$sb.AppendLine($ex.StackTrace) }
            [void]$sb.AppendLine('')
            $ex = $ex.InnerException
            $depth++
        }

        if ($script:txtLog -and -not $script:txtLog.IsDisposed) {
            [void]$sb.AppendLine(('-' * 60))
            [void]$sb.AppendLine('Letzte Protokollzeilen:')
            foreach ($line in (@($script:txtLog.Lines) | Select-Object -Last 40)) {
                [void]$sb.AppendLine($line)
            }
        }

        [System.IO.File]::WriteAllText($file, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
        return $file
    }
    catch { return $null }
}

function Register-CrashHandlers {
    if (-not $script:Config.CrashRecovery) { return }
    try {
        # Must run before the first window exists, otherwise WinForms ignores it
        [System.Windows.Forms.Application]::SetUnhandledExceptionMode(
            [System.Windows.Forms.UnhandledExceptionMode]::CatchException)
    }
    catch { }

    try {
        [System.Windows.Forms.Application]::add_ThreadException({
                param($src, $e)
                $script:CrashCount++
                $file = Save-CrashReport -ErrorObject $e.Exception -Origin 'UI-Thread'
                try { Write-Log "$(Get-Text 'CrashTitle'): $($e.Exception.Message)" 'ERROR' } catch { }
                # Do not spam dialogs if something fails on every repaint
                if ($script:CrashCount -le 3) {
                    try {
                        [System.Windows.Forms.MessageBox]::Show(
                            "$(Get-Text 'CrashMsg')`n`n$file`n`n$($e.Exception.Message)",
                            (Get-Text 'CrashTitle'),
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
                    }
                    catch { }
                }
            })
    }
    catch { }

    try {
        [AppDomain]::CurrentDomain.add_UnhandledException({
                param($src, $e)
                [void](Save-CrashReport -ErrorObject $e.ExceptionObject -Origin 'AppDomain')
                Close-LogFile
            })
    }
    catch { }
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'CYAN', 'PURPLE', 'SYSTEM', 'TITLE')]
        [string]$Type = 'INFO'
    )

    if (-not $script:Config.EnableLogging) { return }

    $time = Get-Date -Format 'HH:mm:ss'
    $icon = switch ($Type) {
        # Consolas kennt keine Emoji - das Gehirn- und das Blitzsymbol wurden
        # als leeres Kaestchen gezeichnet. Nur Zeichen verwenden, die in der
        # Protokollschrift wirklich enthalten sind.
        'SUCCESS' { '✓' } 'ERROR' { '✗' } 'WARNING' { '!' } 'SYSTEM' { '≡' }
        'CYAN' { '◆' } 'PURPLE' { '◈' } 'TITLE' { '»' } default { '•' }
    }
    $color = switch ($Type) {
        'SUCCESS' { $script:Theme.Success }
        'ERROR' { $script:Theme.Error }
        'WARNING' { $script:Theme.Warning }
        'CYAN' { $script:Theme.Cyan }
        'PURPLE' { $script:Theme.Purple }
        'SYSTEM' { $script:Theme.Accent }
        'TITLE' { $script:Theme.Cyan }
        default { $script:Theme.Info }
    }

    Write-LogFileLine -Line ("[{0}] [{1,-7}] {2}" -f $time, $Type, $Message) -Type $Type

    Add-LogBufferEntry -Time $time -Type $Type -Icon $icon -Message $Message

    if ($script:txtLog -and -not $script:txtLog.IsDisposed) {
        # Bei aktivem Filter wandert die Zeile nur in den Puffer, nicht in die
        # Anzeige - sichtbar wird sie, sobald der passende Reiter gewaehlt ist.
        if (Test-LogVisible -Type $Type -Message $Message) {
            try {
                # Trim the log so the RichTextBox never grows without bounds.
                # Checking .Lines builds a full string array - only do it now and
                # then instead of on every single log line.
                $script:LogLineCount++
                if ($script:LogLineCount -ge 50 -and $script:txtLog.Lines.Count -gt $script:Config.MaxLogLines) {
                    $script:LogLineCount = 0
                    $keep = $script:txtLog.Lines | Select-Object -Last ([int]($script:Config.MaxLogLines / 2))
                    $script:txtLog.Clear()
                    $script:txtLog.SelectionColor = $script:Theme.TextMuted
                    $script:txtLog.AppendText(($keep -join "`r`n") + "`r`n")
                }
                elseif ($script:LogLineCount -ge 50) { $script:LogLineCount = 0 }

                $script:txtLog.SelectionStart = $script:txtLog.TextLength
                $script:txtLog.SelectionLength = 0
                $script:txtLog.SelectionColor = $script:Theme.TextMuted
                $script:txtLog.AppendText("[$time] ")
                $script:txtLog.SelectionColor = $color
                $script:txtLog.AppendText("$icon $Message`r`n")
                # Eingeklappt sieht niemand das Protokoll - ScrollToCaret
                # erzwingt aber trotzdem ein vollstaendiges Neuzeichnen.
                if ($script:txtLog.Visible) { $script:txtLog.ScrollToCaret() }
            }
            catch { }
        }

        # Mirror the newest entry in the header so feedback is visible even
        # when the log panel is scrolled away
        if ($script:lblStatus -and -not $script:lblStatus.IsDisposed) {
            try {
                # Vektorsymbol statt Schriftzeichen - kein Kaestchen mehr,
                # wenn der Schrift ein Zeichen fehlt. Gezeichnet wird es neben
                # dem Text (siehe Set-LabelIconPainter), nicht darueber.
                $iconName = switch ($Type) {
                    'SUCCESS' { 'check' }
                    'ERROR' { 'warning' }
                    'WARNING' { 'warning' }
                    'SYSTEM' { 'bolt' }
                    'CYAN' { 'dot' }
                    'PURPLE' { 'dot' }
                    'TITLE' { 'cpu' }
                    default { 'dot' }
                }
                $sImg = Get-IconBitmap -Name $iconName -Size 14 -Color $color
                if ($sImg) {
                    $sRtl = Test-RightToLeftUi
                    Set-LabelIconPainter -Control $script:lblStatus -Image $sImg -Rtl $sRtl
                    if ($sRtl) {
                        if ($script:lblStatus.Padding.Right -lt 20) {
                            $script:lblStatus.Padding = New-Object System.Windows.Forms.Padding(0, 0, 20, 0)
                        }
                    }
                    elseif ($script:lblStatus.Padding.Left -lt 20) {
                        $script:lblStatus.Padding = New-Object System.Windows.Forms.Padding(20, 0, 0, 0)
                    }
                }
                # No manual Substring: it can cut a UTF-16 surrogate pair in
                # half (emoji -> garbage). AutoEllipsis does it correctly.
                $script:lblStatus.Text = $Message
                $script:lblStatus.ForeColor = $color
                Set-Tip $script:lblStatus $Message
            }
            catch { }
        }

        if ($script:Config.EnableNotify -and @('SUCCESS', 'WARNING', 'ERROR') -contains $Type) {
            try {
                # Bisher zaehlte nur ein verstecktes Fenster. Ein zum Symbol
                # verkleinertes ist aber weiterhin 'Visible' - die Karte wurde
                # also ins Nichts gezeichnet und man bekam gar nichts mit.
                $unseen = $true
                if ($script:MainForm -and -not $script:MainForm.IsDisposed) {
                    $unseen = (-not $script:MainForm.Visible -or $script:MainForm.WindowState -eq 'Minimized')
                }
                if ($unseen) { Show-TrayBalloon -Text $Message -Type $Type }
                else { Show-Toast -Message $Message -Type $Type }
            }
            catch { }
        }
    }
    else {
        Write-Verbose "[$time] $icon $Message"
    }
}

function Import-AppSettings {
    # Restores language, options and window geometry from the last session.
    try {
        if (-not (Test-Path -LiteralPath $script:Config.SettingsPath)) { return }
        $raw = Get-Content -LiteralPath $script:Config.SettingsPath -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) { return }
        $cfg = $raw | ConvertFrom-Json -ErrorAction Stop

        if ($cfg.Language -and $script:Languages.ContainsKey($cfg.Language)) {
            $script:Config.CurrentLang = $cfg.Language
        }
        if ($null -ne $cfg.EnableLogging) { $script:Config.EnableLogging = [bool]$cfg.EnableLogging }
        if ($null -ne $cfg.EnableNotify) { $script:Config.EnableNotify = [bool]$cfg.EnableNotify }
        if ($null -ne $cfg.RememberWin) { $script:Config.RememberWin = [bool]$cfg.RememberWin }
        if ($null -ne $cfg.MinimizeToTray) { $script:Config.MinimizeToTray = [bool]$cfg.MinimizeToTray }
        if ($null -ne $cfg.LogCollapsed) { $script:Config.LogCollapsed = [bool]$cfg.LogCollapsed }
        if ($null -ne $cfg.ProcAutoRefresh) { $script:Config.ProcAutoRefresh = [bool]$cfg.ProcAutoRefresh }
        if ($null -ne $cfg.ShowWindowsTasks) { $script:Config.ShowWindowsTasks = [bool]$cfg.ShowWindowsTasks }
        if ($null -ne $cfg.CleanConfirm) { $script:Config.CleanConfirm = [bool]$cfg.CleanConfirm }
        # Zahlenwerte eingrenzen: eine von Hand verstellte settings.json darf
        # nicht dazu fuehren, dass die Aufraeumung alles oder nichts loescht.
        if ($null -ne $cfg.BackupKeepDays) { $script:Config.BackupKeepDays = [Math]::Max(1, [Math]::Min(3650, [int]$cfg.BackupKeepDays)) }
        if ($null -ne $cfg.BackupMaxMB) { $script:Config.BackupMaxMB = [Math]::Max(16, [Math]::Min(102400, [int]$cfg.BackupMaxMB)) }
        if ($null -ne $cfg.BackupMinKeep) { $script:Config.BackupMinKeep = [Math]::Max(1, [Math]::Min(500, [int]$cfg.BackupMinKeep)) }
        if ($null -ne $cfg.RestoreView) { $script:Config.RestoreView = [bool]$cfg.RestoreView }
        if ($cfg.LastView) { $script:Config.LastView = [string]$cfg.LastView }
        # Nur Zahlen uebernehmen - eine von Hand verstellte Datei darf keinen
        # Text in die Vergleichsspalte der Messung bringen.
        if ($cfg.LastBench -and $cfg.LastBench.Time) {
            $script:Config.LastBench = [pscustomobject]@{
                Cpu   = [double]$cfg.LastBench.Cpu
                Ram   = [double]$cfg.LastBench.Ram
                Write = [double]$cfg.LastBench.Write
                Read  = [double]$cfg.LastBench.Read
                Time  = [string]$cfg.LastBench.Time
            }
        }
        if ($null -ne $cfg.WinMaximized) { $script:Config.WinMaximized = [bool]$cfg.WinMaximized }

        if ($cfg.ListPrefs) {
            if (-not $script:ListPrefs) { $script:ListPrefs = @{} }
            foreach ($pp in $cfg.ListPrefs.PSObject.Properties) {
                try {
                    $v = $pp.Value
                    $w = New-Object 'System.Collections.Generic.List[int]'
                    if ($v.Widths) { foreach ($x in $v.Widths) { $w.Add([int]$x) } }
                    $script:ListPrefs[$pp.Name] = @{
                        Sort   = [int]$v.Sort
                        Asc    = [bool]$v.Asc
                        Widths = $w.ToArray()
                        Titles = $null
                    }
                }
                catch { }
            }
        }

        if ($cfg.WinBounds -and $cfg.WinBounds.Width -gt 400 -and $cfg.WinBounds.Height -gt 300) {
            $script:Config.WinBounds = @{
                X      = [int]$cfg.WinBounds.X
                Y      = [int]$cfg.WinBounds.Y
                Width  = [int]$cfg.WinBounds.Width
                Height = [int]$cfg.WinBounds.Height
            }
        }
    }
    catch {
        # A damaged settings file must never stop the program
        $script:Config.WinBounds = $null
    }
}

function Export-AppSettings {
    try {
        $dir = Split-Path -Parent $script:Config.SettingsPath
        if ($dir -and -not (Test-Path -LiteralPath $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }

        $bounds = $script:Config.WinBounds
        if ($script:MainForm -and -not $script:MainForm.IsDisposed) {
            $script:Config.WinMaximized = ($script:MainForm.WindowState -eq 'Maximized')
            # RestoreBounds holds the pre-maximize geometry
            $r = if ($script:MainForm.WindowState -eq 'Normal') { $script:MainForm.Bounds }
            else { $script:MainForm.RestoreBounds }
            if ($r.Width -gt 400 -and $r.Height -gt 300) {
                $bounds = @{ X = $r.X; Y = $r.Y; Width = $r.Width; Height = $r.Height }
            }
        }

        # Listeneinstellungen: nur Sortierung und Breiten, keine Laufzeitdaten
        $prefs = [ordered]@{}
        if ($script:ListPrefs) {
            foreach ($k in @($script:ListPrefs.Keys)) {
                $v = $script:ListPrefs[$k]
                $prefs[$k] = [pscustomobject]@{
                    Sort   = [int]$v.Sort
                    Asc    = [bool]$v.Asc
                    Widths = @($v.Widths)
                }
            }
        }

        [pscustomobject]@{
            Language      = $script:Config.CurrentLang
            EnableLogging = [bool]$script:Config.EnableLogging
            EnableNotify  = [bool]$script:Config.EnableNotify
            RememberWin   = [bool]$script:Config.RememberWin
            MinimizeToTray = [bool]$script:Config.MinimizeToTray
            LogCollapsed  = [bool]$script:Config.LogCollapsed
            ProcAutoRefresh = [bool]$script:Config.ProcAutoRefresh
            ShowWindowsTasks = [bool]$script:Config.ShowWindowsTasks
            CleanConfirm    = [bool]$script:Config.CleanConfirm
            BackupKeepDays  = [int]$script:Config.BackupKeepDays
            BackupMaxMB     = [int]$script:Config.BackupMaxMB
            BackupMinKeep   = [int]$script:Config.BackupMinKeep
            RestoreView   = [bool]$script:Config.RestoreView
            LastView      = [string]$script:Config.CurrentView
            WinMaximized  = [bool]$script:Config.WinMaximized
            LastBench     = $script:Config.LastBench
            WinBounds     = $bounds
            ListPrefs     = [pscustomobject]$prefs
            SavedAt       = (Get-Date).ToString('s')
            Version       = $script:Config.Version
        } | ConvertTo-Json -Depth 4 | Out-File -LiteralPath $script:Config.SettingsPath -Encoding UTF8 -Force
        return $true
    }
    catch { return $false }
}

function Reset-AppSettings {
    try {
        if (Test-Path -LiteralPath $script:Config.SettingsPath) {
            Remove-Item -LiteralPath $script:Config.SettingsPath -Force -ErrorAction Stop
        }
        $script:Config.RememberWin = $true
        $script:Config.RestoreView = $false
        $script:Config.WinBounds = $null
        $script:Config.WinMaximized = $false
        $script:ListPrefs = @{}
        Write-Log "$(Get-Text 'SetReset'): $(Get-Text 'Success')" 'SUCCESS'
        Set-View -ViewName 'Settings'
    }
    catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
}

function Get-ReportHtmlDirection {
    # Der Bericht wurde immer mit lang="de" und linksbuendig erzeugt - im
    # arabischen Betrieb stand er damit in der falschen Leserichtung.
    param([string]$Language = 'DE')
    $l = ("$Language").ToUpperInvariant()
    $map = @{ DE = 'de'; EN = 'en'; TR = 'tr'; AR = 'ar' }
    $code = if ($map.ContainsKey($l)) { $map[$l] } else { 'en' }
    if ($l -eq 'AR') { return @{ Lang = $code; Dir = 'rtl'; Align = 'right' } }
    return @{ Lang = $code; Dir = 'ltr'; Align = 'left' }
}

function Format-ReportValue {
    # Registrierungswerte koennen Byte-Felder oder mehrere Kilobyte lange
    # Zeichenketten sein - ungekuerzt sprengen sie jede Tabellenspalte.
    param($Value, [int]$Max = 60)
    if ($null -eq $Value) { return '-' }
    $t = if ($Value -is [array]) { (@($Value) -join ', ') } else { "$Value" }
    if ($t.Length -eq 0) { return '-' }
    if ($t.Length -gt $Max) { return $t.Substring(0, $Max) + '...' }
    return $t
}

function Export-SystemReport {
    # Collects the most relevant system facts into a single self-contained
    # HTML file (dark theme, no external resources) and opens it.
    Write-Log "$(Get-Text 'Report')..." 'SYSTEM'
    $saved = if ($script:MainForm) { $script:MainForm.Cursor } else { $null }
    Show-BusyOverlay -Title (Get-Text 'Report')
    try {
        if ($script:MainForm) { $script:MainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor }

        $enc = [System.Text.Encoding]::UTF8
        $sb = New-Object System.Text.StringBuilder
        $esc = { param($t) [System.Net.WebUtility]::HtmlEncode([string]$t) }

        $rtlInfo = Get-ReportHtmlDirection -Language $script:Config.CurrentLang
        [void]$sb.AppendLine('<!DOCTYPE html><html lang="' + $rtlInfo.Lang + '" dir="' + $rtlInfo.Dir + '"><head><meta charset="utf-8">')
        [void]$sb.AppendLine("<title>$($script:Config.AppName) System Report</title><style>")
        # Der Bericht trug als einziger Teil noch eine fremde Graupalette -
        # die Farben kommen jetzt aus demselben Theme wie das Fenster.
        $cBg = ConvertTo-HexColor $script:Theme.BgLog
        $cTxt = ConvertTo-HexColor $script:Theme.TextPrimary
        $cSub = ConvertTo-HexColor $script:Theme.TextSecondary
        $cAcc = ConvertTo-HexColor $script:Theme.Accent
        $cLine = ConvertTo-HexColor $script:Theme.Divider
        $cHead = ConvertTo-HexColor $script:Theme.BgSecondary
        $cRow = ConvertTo-HexColor $script:Theme.BgCard
        [void]$sb.AppendLine('body{background:' + $cBg + ';color:' + $cTxt + ';font-family:Segoe UI,Arial,sans-serif;margin:0;padding:32px}')
        [void]$sb.AppendLine('h1{font-size:24px;margin:0 0 4px}h2{font-size:16px;color:' + $cAcc + ';margin:28px 0 8px;border-bottom:1px solid ' + $cLine + ';padding-bottom:6px}')
        [void]$sb.AppendLine('.sub{color:' + $cSub + ';font-size:13px;margin-bottom:8px}')
        [void]$sb.AppendLine('table{border-collapse:collapse;width:100%;font-size:13px}')
        [void]$sb.AppendLine('th{background:' + $cHead + ';color:' + $cSub + ';text-align:' + $rtlInfo.Align + ';padding:7px 10px;font-weight:600}')
        [void]$sb.AppendLine('td{padding:6px 10px;border-top:1px solid ' + $cLine + '}tr:hover td{background:' + $cRow + '}')
        [void]$sb.AppendLine('.ok{color:' + (ConvertTo-HexColor $script:Theme.Success) + '}.warn{color:' + (ConvertTo-HexColor $script:Theme.Warning) + '}.bad{color:' + (ConvertTo-HexColor $script:Theme.Error) + '}')
        [void]$sb.AppendLine('</style></head><body>')
        [void]$sb.AppendLine("<h1>$($script:Config.AppName) - $(& $esc (Get-Text 'Report'))</h1>")
        [void]$sb.AppendLine("<div class='sub'>$env:COMPUTERNAME \ $env:USERNAME &middot; $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') &middot; v$($script:Config.Version)</div>")

        # --- System / hardware -------------------------------------------------
        $hw = Get-HardwareInfo
        Update-BusyOverlay -Status (Get-Text 'HWTitle') -Percent 10
        [void]$sb.AppendLine("<h2>$(& $esc (Get-Text 'HWTitle'))</h2><table>")
        if ($hw) {
            if ($hw.OS) {
                $bld = [string]$hw.OS.BuildNumber
                if ($hw.UBR) { $bld += '.' + $hw.UBR }
                $ed = ''
                if ($hw.DisplayVer) { $ed = ' ' + $hw.DisplayVer }
                [void]$sb.AppendLine("<tr><th>$(& $esc (Get-Text 'HWOS'))</th><td>$(& $esc $hw.OS.Caption)$(& $esc $ed) (Build $(& $esc $bld))</td></tr>")
            }
            if ($hw.CPU) {
                [void]$sb.AppendLine("<tr><th>$(& $esc (Get-Text 'HWProcessor'))</th><td>$(& $esc $hw.CPU.Name) - $($hw.CPU.NumberOfCores) Cores / $($hw.CPU.NumberOfLogicalProcessors) Threads</td></tr>")
            }
            foreach ($g in $hw.GPUs) {
                if (-not $g.Name) { continue }
                $vr = ''
                if ($hw.VramByName -and $hw.VramByName.ContainsKey([string]$g.Name)) {
                    $vb = [double]$hw.VramByName[[string]$g.Name]
                    if ($vb -gt 0) { $vr = ' - ' + [math]::Round($vb / 1GB, 1) + ' GB' }
                }
                $res = ''
                if ($g.CurrentHorizontalResolution -and $g.CurrentVerticalResolution) {
                    $res = ' - ' + $g.CurrentHorizontalResolution + 'x' + $g.CurrentVerticalResolution
                }
                [void]$sb.AppendLine("<tr><th>$(& $esc (Get-Text 'HWGraphics'))</th><td>$(& $esc $g.Name)$(& $esc $vr)$(& $esc $res)</td></tr>")
            }
            if ($hw.Board) {
                [void]$sb.AppendLine("<tr><th>$(& $esc (Get-Text 'HWBoard'))</th><td>$(& $esc $hw.Board.Manufacturer) $(& $esc $hw.Board.Product)</td></tr>")
            }
        }
        $mem = Get-MemorySnapshot
        if ($mem) {
            [void]$sb.AppendLine("<tr><th>$(& $esc (Get-Text 'HWMemory'))</th><td>$($mem.UsedGB) / $($mem.TotalGB) GB ($($mem.Percent)%)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')

        # --- Drives ------------------------------------------------------------
        Update-BusyOverlay -Status (Get-Text 'HWStorage') -Percent 30
        [void]$sb.AppendLine("<h2>$(& $esc (Get-Text 'HWStorage'))</h2><table><tr><th>$(& $esc (Get-Text 'ColDrive'))</th><th>$(& $esc (Get-Text 'LblTotal'))</th><th>$(& $esc (Get-Text 'LblFree'))</th><th>$(& $esc (Get-Text 'LblUsed'))</th></tr>")
        foreach ($d in (Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction SilentlyContinue)) {
            if (-not $d.Size) { continue }
            $pct = [int]((($d.Size - $d.FreeSpace) / $d.Size) * 100)
            $cls = if ($pct -gt 90) { 'bad' } elseif ($pct -gt 75) { 'warn' } else { 'ok' }
            [void]$sb.AppendLine("<tr><td>$($d.DeviceID)</td><td>$(Get-FormattedBytes $d.Size)</td><td>$(Get-FormattedBytes $d.FreeSpace)</td><td class='$cls'>$pct%</td></tr>")
        }
        [void]$sb.AppendLine('</table>')

        # --- Top processes -----------------------------------------------------
        Update-BusyOverlay -Status (Get-Text 'MenuProcesses') -Percent 50
        [void]$sb.AppendLine("<h2>$(& $esc (Get-Text 'MenuProcesses')) (Top 15)</h2><table><tr><th>$(& $esc (Get-Text 'ColName'))</th><th>PID</th><th>RAM</th></tr>")
        foreach ($pr in (Get-Process -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending | Select-Object -First 15)) {
            [void]$sb.AppendLine("<tr><td>$(& $esc $pr.ProcessName)</td><td>$($pr.Id)</td><td>$(Get-FormattedBytes $pr.WorkingSet64)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')

        # --- Autostart ---------------------------------------------------------
        Update-BusyOverlay -Status (Get-Text 'MenuStartup') -Percent 70
        # Dieselbe Quelle wie die Ansicht - der Bericht kannte bisher nur zwei
        # der sieben Orte und schrieb rohes "HKCU" in die Bereichsspalte.
        [void]$sb.AppendLine("<h2>$(& $esc (Get-Text 'MenuStartup'))</h2><table><tr><th>$(& $esc (Get-Text 'ColName'))</th><th>$(& $esc (Get-Text 'ColCommand'))</th><th>$(& $esc (Get-Text 'ColScope'))</th><th>$(& $esc (Get-Text 'ColState'))</th></tr>")
        foreach ($se in (Get-StartupEntryList)) {
            [void]$sb.AppendLine("<tr><td>$(& $esc $se.Name)</td><td>$(& $esc $se.Value)</td><td>$(& $esc (Get-Text $se.ScopeKey))</td><td>$(& $esc (Get-Text (Get-StartupStatusKey -Entry $se)))</td></tr>")
        }
        [void]$sb.AppendLine('</table>')

        # --- Running services --------------------------------------------------
        $running = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' } | Sort-Object DisplayName)
        Update-BusyOverlay -Status (Get-Text 'MenuServices') -Percent 85
        [void]$sb.AppendLine("<h2>$(& $esc (Get-Text 'MenuServices')) ($($running.Count))</h2><table><tr><th>$(& $esc (Get-Text 'ColName'))</th><th>$(& $esc (Get-Text 'ColDisplay'))</th></tr>")
        foreach ($svc in $running) {
            [void]$sb.AppendLine("<tr><td>$(& $esc $svc.Name)</td><td>$(& $esc $svc.DisplayName)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')

        # --- Aufgezeichnete Aenderungen ---------------------------------------
        # Der wichtigste Teil eines weitergereichten Berichts: was hat dieses
        # Programm am System tatsaechlich veraendert.
        Update-BusyOverlay -Status (Get-Text 'MenuChanges') -Percent 95
        $chg = @()
        try { $chg = @($script:ChangeLog) } catch { }
        [void]$sb.AppendLine("<h2>$(& $esc (Get-Text 'MenuChanges')) ($($chg.Count))</h2><table>")
        [void]$sb.AppendLine("<tr><th>$(& $esc (Get-Text 'ColDate'))</th><th>$(& $esc (Get-Text 'ColName'))</th><th>$(& $esc (Get-Text 'ColKey'))</th><th>$(& $esc (Get-Text 'ColOld'))</th><th>$(& $esc (Get-Text 'ColNew'))</th><th>$(& $esc (Get-Text 'ColState'))</th></tr>")
        foreach ($ce in $chg) {
            $undone = $false
            try { $undone = [bool]$ce.Undone } catch { }
            $st = if ($undone) { Get-Text 'ChangeUndone' } else { Get-Text 'RepOpen' }
            $cls = if ($undone) { 'ok' } else { 'warn' }
            $full = Get-ChangeTargetText -Entry $ce
            [void]$sb.AppendLine("<tr><td>$(& $esc $ce.Time)</td><td>$(& $esc $ce.Label)</td><td>$(& $esc $full)</td><td>$(& $esc (Format-ReportValue $ce.OldValue))</td><td>$(& $esc (Format-ReportValue $ce.NewValue))</td><td class='$cls'>$(& $esc $st)</td></tr>")
        }
        [void]$sb.AppendLine('</table>')

        [void]$sb.AppendLine("<p class='sub'>$($script:Config.AppName) v$($script:Config.Version) - $(& $esc (Get-Text 'Report'))</p>")
        [void]$sb.AppendLine('</body></html>')

        if (-not (Test-Path -LiteralPath $script:Config.BackupDir)) {
            New-Item -Path $script:Config.BackupDir -ItemType Directory -Force | Out-Null
        }
        $file = Join-Path $script:Config.BackupDir ("SystemReport_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.html')
        [System.IO.File]::WriteAllText($file, $sb.ToString(), $enc)

        Write-Log "$(Get-Text 'Report'): $file" 'SUCCESS'
        try { Start-Process $file } catch { }
        return $file
    }
    catch {
        Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR'
        return $null
    }
    finally {
        Hide-BusyOverlay
        if ($script:MainForm -and $saved) { $script:MainForm.Cursor = $saved }
    }
}

# --- Short lived data cache ---------------------------------------------------
# Enumerating services or scheduled tasks costs hundreds of milliseconds up to
# several seconds. Switching back to a view - or typing one more letter into a
# search box - must not pay that price again.
$script:DataCache = @{}

function Get-CachedData {
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][scriptblock]$Loader,
        [int]$TtlSeconds = 30,
        [switch]$Force
    )

    if (-not $Force -and $script:DataCache.ContainsKey($Key)) {
        $entry = $script:DataCache[$Key]
        if (((Get-Date) - $entry.Time).TotalSeconds -lt $TtlSeconds) {
            return , $entry.Data
        }
    }

    $data = @(& $Loader)
    $script:DataCache[$Key] = @{ Time = Get-Date; Data = $data }
    return , $data
}

function Clear-DataCache {
    param([string]$Key = '')
    if ($Key) { [void]$script:DataCache.Remove($Key) }
    else { $script:DataCache.Clear() }
}

# ---- Hintergrundladung -------------------------------------------------------
# Get-ScheduledTask, Get-HotFix und Get-Service brauchen auf vielen Rechnern
# mehrere Sekunden. Bisher liefen sie auf dem Oberflaechenstrang - das Fenster
# reagierte in dieser Zeit auf nichts. Die Abfrage wandert jetzt in einen
# eigenen Runspace; die Liste zeigt solange "Lade ..." und bleibt bedienbar.

function Stop-LoadJob {
    param($Job, [switch]$Kill)
    if (-not $Job) { return }
    try { if ($Kill -and $Job.PS) { $Job.PS.Stop() } } catch { }
    try { if ($Job.PS) { $Job.PS.Dispose() } } catch { }
    try { if ($Job.RS) { $Job.RS.Close(); $Job.RS.Dispose() } } catch { }
}

function Update-LoadJobs {
    # Laeuft im Oberflaechenstrang: der Rueckruf darf also Steuerelemente
    # anfassen, ohne dass es knallt.
    if (-not $script:LoadJobs -or $script:LoadJobs.Count -eq 0) {
        if ($script:LoadTimer) { try { $script:LoadTimer.Stop() } catch { } }
        return
    }
    foreach ($key in @($script:LoadJobs.Keys)) {
        $job = $script:LoadJobs[$key]
        if (-not $job) { [void]$script:LoadJobs.Remove($key); continue }

        $done = $true
        try { $done = [bool]$job.Handle.IsCompleted } catch { $done = $true }
        $late = (((Get-Date) - $job.Started).TotalSeconds -ge 120)
        if (-not $done -and -not $late) { continue }

        $data = @()
        if ($done) {
            try { $data = @($job.PS.EndInvoke($job.Handle)) }
            catch { Write-Log "$key : $($_.Exception.Message)" 'WARNING' }
        }
        else {
            Write-Log "$key : $(Get-Text 'LogTimeout')" 'WARNING'
        }

        $script:DataCache[$key] = @{ Time = Get-Date; Data = $data }
        [void]$script:LoadJobs.Remove($key)
        Stop-LoadJob -Job $job -Kill:(-not $done)

        if ($job.OnReady) { try { & $job.OnReady } catch { } }
    }
    if ($script:LoadJobs.Count -eq 0 -and $script:LoadTimer) {
        try { $script:LoadTimer.Stop() } catch { }
    }
}

function Request-CachedData {
    # Rueckgabe $true  = die Daten liegen frisch im Zwischenspeicher.
    # Rueckgabe $false = es laeuft eine Hintergrundladung; die Ansicht soll
    #                    einen Ladehinweis zeigen und spaeter neu zeichnen.
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][scriptblock]$Loader,
        [int]$TtlSeconds = 30,
        [switch]$Force,
        [scriptblock]$OnReady = $null
    )

    if (-not $Force -and $script:DataCache.ContainsKey($Key)) {
        $entry = $script:DataCache[$Key]
        if (((Get-Date) - $entry.Time).TotalSeconds -lt $TtlSeconds) { return $true }
    }

    if ($null -eq $script:LoadJobs) { $script:LoadJobs = @{} }
    # Laeuft die Abfrage schon, nicht ein zweites Mal anstossen.
    if ($script:LoadJobs.ContainsKey($Key)) { return $false }

    try {
        $rs = [runspacefactory]::CreateRunspace()
        $rs.ApartmentState = 'MTA'
        $rs.ThreadOptions = 'ReuseThread'
        $rs.Open()
        $ps = [powershell]::Create()
        $ps.Runspace = $rs
        # Als Text uebergeben: ein Skriptblock bliebe sonst an den alten
        # Runspace gebunden und liefe doch wieder im Oberflaechenstrang.
        [void]$ps.AddScript($Loader.ToString())
        $handle = $ps.BeginInvoke()
        $script:LoadJobs[$Key] = @{
            PS      = $ps
            RS      = $rs
            Handle  = $handle
            OnReady = $OnReady
            Started = Get-Date
        }
    }
    catch {
        # Kein Runspace moeglich: lieber kurz blockieren als gar keine Daten.
        try {
            $script:DataCache[$Key] = @{ Time = Get-Date; Data = @(& $Loader) }
            return $true
        }
        catch {
            Write-Log "$Key : $($_.Exception.Message)" 'ERROR'
            $script:DataCache[$Key] = @{ Time = Get-Date; Data = @() }
            return $true
        }
    }

    if (-not $script:LoadTimer) {
        $script:LoadTimer = New-Object System.Windows.Forms.Timer
        $script:LoadTimer.Interval = 120
        $script:LoadTimer.Add_Tick({ Update-LoadJobs })
    }
    try { $script:LoadTimer.Start() } catch { }
    return $false
}

function Get-CacheEntryData {
    # Bewusst OHNE das ',$x'-Muster: damit verhielte sich @(Get-CacheEntryData)
    # wie ein einelementiges Feld, das die ganze Liste enthaelt. Alle Aufrufer
    # verwenden foreach oder @(), beides vertraegt die normale Aufloesung.
    param([string]$Key)
    $out = @()
    if ($script:DataCache -and $script:DataCache.ContainsKey($Key)) {
        $out = @($script:DataCache[$Key].Data)
    }
    return $out
}

function Stop-LoadJobs {
    if (-not $script:LoadJobs) { return }
    foreach ($key in @($script:LoadJobs.Keys)) {
        Stop-LoadJob -Job $script:LoadJobs[$key] -Kill
    }
    $script:LoadJobs.Clear()
    if ($script:LoadTimer) { try { $script:LoadTimer.Stop() } catch { } }
}

function Invoke-Deferred {
    # Runs $Action AFTER the view has been painted. Everything that needs more
    # than a few milliseconds (CIM, Get-HotFix, Get-NetAdapter, Get-ScheduledTask)
    # used to run inside the view builder, so the window froze for the whole
    # query and only then appeared. Now the frame shows instantly and the data
    # drops in a moment later.
    param([scriptblock]$Action, [int]$DelayMs = 1)
    if (-not $Action) { return }

    $view = $script:Config.CurrentView
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = [math]::Max(1, $DelayMs)
    $timer.Add_Tick({
            $timer.Stop()
            $timer.Dispose()
            # The user may have switched views (or closed the app) in the
            # meantime - then the result is not wanted any more.
            if ($script:Shutdown) { return }
            if ($script:Config.CurrentView -ne $view) { return }
            if (-not $script:pnlContent -or $script:pnlContent.IsDisposed) { return }
            try { & $Action }
            catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
        }.GetNewClosure())
    $timer.Start()
}

function Set-SearchDebounce {
    # Filtering on every keystroke rebuilt the whole ListView per character -
    # typing in the search box felt sticky. The filter now runs once the user
    # stops typing for a moment.
    param(
        [System.Windows.Forms.TextBox]$TextBox,
        [scriptblock]$Action,
        [int]$DelayMs = 220
    )
    if (-not $TextBox -or -not $Action) { return }

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = [math]::Max(50, $DelayMs)
    $timer.Add_Tick({
            $timer.Stop()
            if ($script:Shutdown) { return }
            if (-not $TextBox -or $TextBox.IsDisposed) { return }
            try { & $Action $TextBox.Text } catch { }
        }.GetNewClosure())

    $TextBox.Add_TextChanged({ $timer.Stop(); $timer.Start() }.GetNewClosure())
    $TextBox.Add_Disposed({ try { $timer.Stop(); $timer.Dispose() } catch { } }.GetNewClosure())
}

# --- Protokollpuffer und -filter ----------------------------------------------
# Die RichTextBox allein kann nicht filtern: sie kennt nur fertigen Text. Jede
# Zeile wird deshalb zusaetzlich als Eintrag gemerkt, damit die Reiter oben
# rechts die Anzeige jederzeit neu aufbauen koennen.
$script:LogEntries = New-Object System.Collections.Generic.List[object]
$script:LogFilter = 'ALL'
$script:LogFilterButtons = @{}

function Add-LogBufferEntry {
    param([string]$Time, [string]$Type, [string]$Icon, [string]$Message)
    if (-not $script:LogEntries) { $script:LogEntries = New-Object System.Collections.Generic.List[object] }
    $script:LogEntries.Add([pscustomobject]@{ Time = $Time; Type = $Type; Icon = $Icon; Message = $Message })
    $max = [int]$script:Config.MaxLogLines
    if ($max -lt 50) { $max = 500 }
    while ($script:LogEntries.Count -gt $max) { $script:LogEntries.RemoveAt(0) }
}

function Test-LogSearchMatch {
    # Leere Suche laesst alles durch. Mehrere durch Leerzeichen getrennte
    # Woerter muessen ALLE vorkommen; ein vorangestelltes Minus schliesst aus.
    # Gross-/Kleinschreibung spielt keine Rolle.
    param([string]$Text = '', [string]$Query = '')
    if ([string]::IsNullOrWhiteSpace($Query)) { return $true }
    $hay = ("$Text").ToLowerInvariant()
    foreach ($raw in ($Query -split '\s+')) {
        if ([string]::IsNullOrWhiteSpace($raw)) { continue }
        $term = $raw.ToLowerInvariant()
        if ($term.StartsWith('-')) {
            $neg = $term.Substring(1)
            if ($neg.Length -eq 0) { continue }
            if ($hay.Contains($neg)) { return $false }
        }
        elseif (-not $hay.Contains($term)) { return $false }
    }
    return $true
}

function Test-LogVisible {
    param([string]$Type, [string]$Message = $null)
    $pass = switch ($script:LogFilter) {
        'WARN' { ($Type -eq 'WARNING') }
        'ERROR' { ($Type -eq 'ERROR') }
        'INFO' { ($Type -ne 'WARNING' -and $Type -ne 'ERROR') }
        default { $true }
    }
    if (-not $pass) { return $false }
    if ([string]::IsNullOrWhiteSpace($script:LogSearch)) { return $true }
    # Die Art wird mitdurchsucht, damit "error" auch ohne Reiter funktioniert.
    return (Test-LogSearchMatch -Text "$Type $Message" -Query $script:LogSearch)
}

function Set-LogSearch {
    param([string]$Query = '')
    $script:LogSearch = "$Query"
    Update-LogView
}

function Get-LogTypeColor {
    param([string]$Type)
    switch ($Type) {
        'SUCCESS' { $script:Theme.Success }
        'ERROR' { $script:Theme.Error }
        'WARNING' { $script:Theme.Warning }
        'CYAN' { $script:Theme.Cyan }
        'PURPLE' { $script:Theme.Purple }
        'SYSTEM' { $script:Theme.Accent }
        'TITLE' { $script:Theme.Cyan }
        default { $script:Theme.Info }
    }
}

function Update-LogView {
    # Anzeige komplett aus dem Puffer neu aufbauen (nach Filterwechsel).
    if (-not $script:txtLog -or $script:txtLog.IsDisposed) { return }
    $box = $script:txtLog
    try {
        $box.SuspendLayout()
        $box.Clear()
        $shown = 0
        $all = $script:LogEntries.ToArray()
        foreach ($e in $all) {
            if (-not (Test-LogVisible -Type $e.Type -Message $e.Message)) { continue }
            $shown++
            $box.SelectionStart = $box.TextLength
            $box.SelectionLength = 0
            $box.SelectionColor = $script:Theme.TextMuted
            $box.AppendText("[$($e.Time)] ")
            $box.SelectionColor = Get-LogTypeColor -Type $e.Type
            $box.AppendText("$($e.Icon) $($e.Message)`r`n")
        }
        $box.SelectionStart = $box.TextLength
        $box.ScrollToCaret()
        $script:LogMatchInfo = ''
        if (-not [string]::IsNullOrWhiteSpace($script:LogSearch)) {
            $script:LogMatchInfo = "$shown/$(@($all).Count) $(Get-Text 'LogMatchCount')"
        }
        Update-LogMatchLabel
    }
    catch { }
    finally { try { $box.ResumeLayout() } catch { } }
}

function Update-LogTitle {
    if (-not $script:lblLogTitle -or $script:lblLogTitle.IsDisposed) { return }
    try {
        $script:lblLogTitle.Text = "{icon:note} $(Get-Text 'LogPanelTitle')"
        [void](Set-ControlIcon -Control $script:lblLogTitle -Glyph '{icon:note}' -Size 16 -StripText)
    }
    catch { }
    Update-LogPanelHeader
}

function Update-LogMatchLabel {
    # Die Trefferzahl stand frueher IM Titel. Dadurch wuchs der Titel beim
    # Tippen und schob das Suchfeld unter dem Mauszeiger weg - deshalb ein
    # eigenes Etikett rechts neben dem Feld.
    if (-not $script:lblLogMatch -or $script:lblLogMatch.IsDisposed) { return }
    try {
        $old = [string]$script:lblLogMatch.Text
        $script:lblLogMatch.Text = [string]$script:LogMatchInfo
        $script:lblLogMatch.Visible = (-not [string]::IsNullOrWhiteSpace($script:LogMatchInfo)) -and
        ($script:txtLogSearch -and -not $script:txtLogSearch.IsDisposed -and $script:txtLogSearch.Visible)
        # Nur wenn sich die Beschriftung wirklich geaendert hat, sonst rechnet
        # jede Protokollzeile die ganze Kopfzeile neu.
        if ($old -ne [string]$script:LogMatchInfo) { Update-LogPanelHeader }
    }
    catch { }
}

function Get-LogHeaderPlan {
    # Reine Geometrie der oberen Zeile der Protokollleiste.
    # Reihenfolge: Titel - Suchfeld - Trefferzahl - (Luecke) - Reiter - Knoepfe.
    param(
        [int]$PanelWidth,
        [int]$TitleWidth,
        [int]$TabsWidth = 0,
        [int]$MatchWidth = 0,
        [int]$Left = 14,
        [int]$Gap = 12,
        [int]$ButtonsWidth = 196,
        [int]$SearchMin = 110,
        [int]$SearchMax = 220
    )
    $plan = @{ SearchVisible = $false; SearchX = 0; SearchWidth = 0
        MatchVisible = $false; MatchX = 0; MatchWidth = 0; TabsX = 0
    }
    if ($PanelWidth -le 0) { return $plan }

    $afterTitle = $Left + $TitleWidth + $Gap
    $tabsRight = $PanelWidth - $ButtonsWidth
    # Platz zwischen Titelende und dem Beginn der Reiter
    $free = $tabsRight - $afterTitle - $Gap - $TabsWidth

    if ($free -ge $SearchMin) {
        $sw = [int][math]::Min($SearchMax, $free)
        $plan.SearchVisible = $true
        $plan.SearchX = $afterTitle
        $plan.SearchWidth = $sw
        $rest = $free - $sw
        if ($MatchWidth -gt 0 -and $rest -ge ($MatchWidth + $Gap)) {
            $plan.MatchVisible = $true
            $plan.MatchX = $afterTitle + $sw + 8
            $plan.MatchWidth = $MatchWidth
        }
        $plan.TabsX = $afterTitle + $sw + $Gap
        if ($plan.MatchVisible) { $plan.TabsX = $plan.MatchX + $MatchWidth + $Gap }
    }
    else {
        # Zu schmal fuer eine Suche - dann bleibt die Zeile wenigstens lesbar.
        $plan.TabsX = $afterTitle
    }
    if ($plan.TabsX -lt $Left) { $plan.TabsX = $Left }
    return $plan
}

function Update-LogPanelHeader {
    # Das Suchfeld aus der Volltextsuche sass auf festen 180 px und lag damit
    # mitten auf dem Titel 'SKRIPT-AUSGABE - OPERATIONS-LOG'. Der Titel ist je
    # nach Sprache verschieden breit, also muss er gemessen werden.
    if (-not $script:LogPanel -or $script:LogPanel.IsDisposed) { return }
    if (-not $script:lblLogTitle -or $script:lblLogTitle.IsDisposed) { return }

    $tw = 180
    try {
        $tw = [int]$script:lblLogTitle.PreferredWidth
        if ($tw -le 0) { $tw = [int]$script:lblLogTitle.Width }
    }
    catch { }
    if ($tw -lt 60) { $tw = 60 }

    $mw = 0
    if ($script:lblLogMatch -and -not $script:lblLogMatch.IsDisposed -and
        -not [string]::IsNullOrWhiteSpace($script:LogMatchInfo)) {
        $mw = Get-TextPixelWidth -Text ([string]$script:LogMatchInfo) -Font $script:lblLogMatch.Font -Fallback 90
        $mw += 8
    }

    $plan = Get-LogHeaderPlan -PanelWidth $script:LogPanel.ClientSize.Width -TitleWidth $tw `
        -TabsWidth (Get-LogFilterTabsWidth) -MatchWidth $mw

    if ($script:txtLogSearch -and -not $script:txtLogSearch.IsDisposed) {
        $script:txtLogSearch.Visible = $plan.SearchVisible
        if ($plan.SearchVisible) { $script:txtLogSearch.SetBounds($plan.SearchX, 4, $plan.SearchWidth, 22) }
    }
    if ($script:lblLogMatch -and -not $script:lblLogMatch.IsDisposed) {
        $script:lblLogMatch.Visible = $plan.MatchVisible
        if ($plan.MatchVisible) { $script:lblLogMatch.SetBounds($plan.MatchX, 6, $plan.MatchWidth, 20) }
    }
    $script:LogTabsFloor = $plan.TabsX
    Update-LogFilterTabs
}

function Clear-LogView {
    if ($script:LogEntries) { $script:LogEntries.Clear() }
    if ($script:txtLog -and -not $script:txtLog.IsDisposed) {
        try { $script:txtLog.Clear() } catch { }
    }
}

function Get-LogFilterTabDefs {
    return @(
        @{ Mode = 'ALL'; Key = 'FilterAll' },
        @{ Mode = 'INFO'; Key = 'FilterInfo' },
        @{ Mode = 'WARN'; Key = 'FilterWarn' },
        @{ Mode = 'ERROR'; Key = 'FilterError' }
    )
}

function Get-LogFilterTabsWidth {
    # Gesamtbreite der vier Reiter - wird fuer die Platzrechnung der oberen
    # Zeile gebraucht, bevor sie gesetzt werden.
    $total = 0
    foreach ($t in (Get-LogFilterTabDefs)) {
        $b = $null
        if ($script:LogFilterButtons) { $b = $script:LogFilterButtons[$t.Mode] }
        if (-not $b -or $b.IsDisposed) { continue }
        $w = 62
        try {
            $m = [System.Windows.Forms.TextRenderer]::MeasureText((Get-Text $t.Key), $b.Font)
            $w = [int][math]::Max(52, [math]::Min(150, $m.Width + 22))
        }
        catch { }
        $total += ($w + 4)
    }
    return $total
}

function Update-LogFilterTabs {
    # Die Reiter hatten feste Breiten (62/66/92/72) - zugeschnitten auf die
    # deutschen Woerter. In EN/TR/AR wurde der Text abgeschnitten, und weil sie
    # nur beim Fensterbau beschriftet wurden, blieben sie beim Sprachwechsel
    # sogar ganz in der alten Sprache stehen. Jetzt wird gemessen und gesetzt.
    if (-not $script:LogFilterButtons -or $script:LogFilterButtons.Count -eq 0) { return }
    if (-not $script:LogPanel -or $script:LogPanel.IsDisposed) { return }

    $defs = Get-LogFilterTabDefs
    $widths = @{}
    $total = 0
    foreach ($t in $defs) {
        $b = $script:LogFilterButtons[$t.Mode]
        if (-not $b -or $b.IsDisposed) { continue }
        $b.Text = Get-Text $t.Key
        $w = 62
        try {
            $m = [System.Windows.Forms.TextRenderer]::MeasureText($b.Text, $b.Font)
            $w = [int][math]::Max(52, [math]::Min(150, $m.Width + 22))
        }
        catch { }
        $widths[$t.Mode] = $w
        $total += ($w + 4)
    }

    # Links davor sitzen Titel, Suchfeld und Trefferzahl - deren rechte Kante
    # hat Update-LogPanelHeader bereits ausgerechnet.
    $floor = [int]$script:LogTabsFloor
    if ($floor -lt 14) { $floor = 14 }
    $x = $script:LogPanel.ClientSize.Width - 196 - $total
    if ($x -lt $floor) { $x = $floor }
    foreach ($t in $defs) {
        $b = $script:LogFilterButtons[$t.Mode]
        if (-not $b -or $b.IsDisposed -or -not $widths.ContainsKey($t.Mode)) { continue }
        $w = [int]$widths[$t.Mode]
        $b.SetBounds($x, 4, $w, 22)
        Set-RoundedRegion -Control $b -Radius 5
        $x += ($w + 4)
    }
    # Nur einfaerben. Frueher stand hier Set-LogFilter - das baute bei JEDER
    # Groessenaenderung des Fensters das komplette Protokoll neu auf.
    try { Update-LogFilterColors } catch { }
}

function Update-LogFilterColors {
    # Nur die Einfaerbung der Laschen - ohne das Protokoll neu aufzubauen.
    if (-not $script:LogFilterButtons) { return }
    foreach ($k in @($script:LogFilterButtons.Keys)) {
        $b = $script:LogFilterButtons[$k]
        if (-not $b -or $b.IsDisposed) { continue }
        if ($k -eq $script:LogFilter) {
            $b.BackColor = $script:Theme.Accent
            $b.ForeColor = $script:Theme.TextWhite
        }
        else {
            $b.BackColor = $script:Theme.BgTertiary
            $b.ForeColor = $script:Theme.TextSecondary
        }
    }
}

function Set-LogFilter {
    param([string]$Mode = 'ALL')
    $script:LogFilter = $Mode
    foreach ($k in @($script:LogFilterButtons.Keys)) {
        $b = $script:LogFilterButtons[$k]
        if (-not $b -or $b.IsDisposed) { continue }
        if ($k -eq $Mode) {
            $b.BackColor = $script:Theme.Accent
            $b.ForeColor = $script:Theme.TextWhite
        }
        else {
            $b.BackColor = $script:Theme.BgTertiary
            $b.ForeColor = $script:Theme.TextSecondary
        }
    }
    Update-LogView
}

# --- Listenfilter -------------------------------------------------------------
# Jede Liste merkt sich ihren Suchtext unter ihrem Namen. Dadurch verliert ein
# Aktualisieren (Knopf, F5, Timer) den Filter nicht mehr und Strg+F findet in
# jeder Listenansicht ein Suchfeld.
$script:ListFilters = @{}
$script:ListFilterLabels = @{}

function Get-ListFilter {
    param([string]$Name)
    if (-not $script:ListFilters) { $script:ListFilters = @{} }
    if ($script:ListFilters.ContainsKey($Name)) { return [string]$script:ListFilters[$Name] }
    return ''
}

function Set-ListFilter {
    param([string]$Name, [string]$Value)
    if (-not $script:ListFilters) { $script:ListFilters = @{} }
    $script:ListFilters[$Name] = [string]$Value
}

function Test-ItemFilter {
    param($Item, [string]$Filter)
    if ([string]::IsNullOrWhiteSpace($Filter)) { return $true }
    $q = $Filter.Trim()
    if (-not $Item) { return $false }
    foreach ($sub in $Item.SubItems) {
        if ($sub.Text -and $sub.Text.IndexOf($q, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    }
    return $false
}

function Set-ListFilterCount {
    param([string]$Name, [int]$Shown, [int]$Total, [string]$Note = '')
    if (-not $script:ListFilterLabels -or -not $script:ListFilterLabels.ContainsKey($Name)) { return }
    $lbl = $script:ListFilterLabels[$Name]
    if (-not $lbl -or $lbl.IsDisposed) { return }
    try {
        if ($Total -le 0) { $lbl.Text = ''; return }
        if ([string]::IsNullOrWhiteSpace((Get-ListFilter $Name))) { $lbl.Text = [string]$Total }
        else { $lbl.Text = "$Shown / $Total" }
        if ($Note) { $lbl.Text = $lbl.Text + '  -  ' + $Note }
    }
    catch { }
}

function Add-ListSearchBox {
    param(
        [string]$Name,
        [string]$PlaceholderKey,
        [scriptblock]$Action,
        [int]$X = 25,
        [int]$Y = 100,
        [int]$Width = 400
    )
    if (-not $script:pnlContent -or -not $Name -or -not $Action) { return $null }
    if (-not $script:ListFilterLabels) { $script:ListFilterLabels = @{} }

    $box = New-Object System.Windows.Forms.TextBox
    $box.Location = New-Object System.Drawing.Point($X, $Y)
    $box.Size = New-Object System.Drawing.Size($Width, 30)
    $box.BackColor = $script:Theme.BgTertiary
    $box.ForeColor = $script:Theme.TextPrimary
    $box.BorderStyle = 'FixedSingle'
    $box.Font = (Get-AppFont -Size 10)
    $script:pnlContent.Controls.Add($box)
    Set-SearchDebounce -TextBox $box -Action $Action
    if ($PlaceholderKey) { Set-Placeholder -TextBox $box -Text "$(Get-Text $PlaceholderKey)  (Ctrl+F)" }

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Location = New-Object System.Drawing.Point(($X + $Width + 12), ($Y + 6))
    $lbl.Size = New-Object System.Drawing.Size(130, 20)
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    $lbl.ForeColor = $script:Theme.TextMuted
    $lbl.Font = (Get-AppFont -Size 9)
    $lbl.Text = ''
    $script:pnlContent.Controls.Add($lbl)
    $script:ListFilterLabels[$Name] = $lbl

    # Beim Zurueckkehren in die Ansicht den zuletzt genutzten Suchtext wieder
    # einsetzen - sonst zeigt die Liste gefiltert, das Feld aber leer.
    $prev = Get-ListFilter $Name
    if ($prev) { $box.Text = $prev }

    $script:SearchBox = $box
    return $box
}

function Get-FormattedBytes {
    param([double]$Bytes)
    if (-not $Bytes -or $Bytes -lt 0) { $Bytes = 0 }
    if ($Bytes -ge 1TB) { return ('{0:N2} TB' -f ($Bytes / 1TB)) }
    if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N2} MB' -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ('{0:N2} KB' -f ($Bytes / 1KB)) }
    return ('{0:N0} B' -f $Bytes)
}

# --- Protected lists ----------------------------------------------------------
$script:ProtectedServices = @(
    'wuauserv', 'WinDefend', 'MpsSvc', 'RpcSs', 'RpcEptMapper',
    'DcomLaunch', 'LSM', 'SamSs', 'LanmanServer', 'LanmanWorkstation',
    'Dhcp', 'Dnscache', 'nsi', 'W32Time', 'EventLog', 'Schedule',
    'ProfSvc', 'BrokerInfrastructure', 'Power', 'SystemEventsBroker',
    'TimeBrokerSvc', 'lsass', 'services', 'winlogon', 'csrss',
    'svchost', 'spoolsv', 'Winmgmt', 'PlugPlay', 'CryptSvc',
    'TrustedInstaller', 'WlanSvc', 'AudioSrv', 'Audiosrv',
    'CoreMessagingRegistrar', 'SecurityHealthService',
    'StorSvc', 'BFE', 'BITS', 'gpsvc', 'Netlogon',
    'SgrmBroker', 'WdNisSvc', 'wscsvc', 'UserManager', 'Themes'
)

$script:ProtectedProcesses = @(
    'System', 'svchost', 'csrss', 'wininit', 'winlogon',
    'services', 'lsass', 'smss', 'dwm', 'explorer',
    'conhost', 'RuntimeBroker', 'ShellExperienceHost',
    'SearchHost', 'StartMenuExperienceHost', 'sihost',
    'fontdrvhost', 'MsMpEng', 'NisSrv', 'SecurityHealthSystray',
    'SecurityHealthService', 'SgrmBroker', 'spoolsv',
    'SearchIndexer', 'WmiPrvSE', 'dllhost', 'taskhostw',
    'audiodg', 'ctfmon', 'Registry', 'Idle', 'Memory Compression',
    'dasHost', 'WUDFHost', 'LsaIso', 'CompPkgSrv', 'powershell', 'pwsh'
)

function ConvertTo-StartupTypeName {
    # Registrierungswert HKLM\SYSTEM\CurrentControlSet\Services\<x>\Start
    param($Start)
    switch ([string]$Start) {
        '0' { return 'Boot' }
        '1' { return 'System' }
        '2' { return 'Automatic' }
        '3' { return 'Manual' }
        '4' { return 'Disabled' }
        default { return 'Unknown' }
    }
}

function Get-ServiceStartupType {
    # Aus der Registrierung statt aus ServiceController.StartType: die
    # Eigenschaft gibt es erst ab .NET 4.6.1 und sie fehlt auf aelteren
    # Windows-10-Installationen, auf denen dieses Skript noch laufen soll.
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return 'Unknown' }
    # Der Registrierungs-Anbieter kostet pro Abfrage ein Vielfaches und wirft
    # bei fehlendem Wert eine Ausnahme. In der Dienste-Liste lief das einmal
    # je Zeile - bei dreihundert Diensten war das der sichtbare Haenger.
    $v = Get-RegistryValueFast -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$Name" -Name 'Start'
    if ($null -eq $v) { return 'Unknown' }
    try { return ConvertTo-StartupTypeName -Start $v } catch { return 'Unknown' }
}

function ConvertFrom-WmiStartMode {
    # Win32_Service sagt 'Auto', Set-Service verlangt 'Automatic', die
    # Registrierung liefert eine Zahl. In der Spalte stand deshalb ein Wort,
    # das mit dem verglichenen Wert nicht uebereinstimmte. Ab hier gilt
    # ueberall dieselbe Schreibweise.
    param([string]$Mode, $Delayed = $false)
    $d = $false
    try { $d = [bool]$Delayed } catch { }
    switch (([string]$Mode).Trim().ToLowerInvariant()) {
        'auto' { if ($d) { return 'AutomaticDelayed' } return 'Automatic' }
        'automatic' { if ($d) { return 'AutomaticDelayed' } return 'Automatic' }
        'manual' { return 'Manual' }
        'disabled' { return 'Disabled' }
        'boot' { return 'Boot' }
        'system' { return 'System' }
        default { return 'Unknown' }
    }
}

function Get-StartTypeKey {
    # Starttyp -> Textschluessel. Der verzoegerte Start war bisher gar nicht
    # sichtbar, obwohl er fuer die Startzeit des Rechners den Unterschied macht.
    param([string]$Type)
    switch ([string]$Type) {
        'Automatic' { return 'SvcAuto' }
        'AutomaticDelayed' { return 'SvcAutoDelayed' }
        'Manual' { return 'SvcManual' }
        'Disabled' { return 'SvcDisabled' }
        'Boot' { return 'SvcBoot' }
        'System' { return 'SvcSystem' }
        default { return 'HwUnknown' }
    }
}

function Get-ServiceDependentMap {
    # Windows fuehrt nur die Gegenrichtung: jeder Dienst weiss, wovon er
    # abhaengt. Wer von IHM abhaengt, ergibt sich erst durch Umdrehen - und
    # genau das muss man wissen, bevor man etwas anhaelt.
    param($Rows)
    $map = @{}
    foreach ($r in @($Rows)) {
        if (-not $r -or -not $r.Name) { continue }
        foreach ($dep in @($r.DependsOn)) {
            $key = ([string]$dep).Trim()
            if (-not $key) { continue }
            $k = $key.ToLowerInvariant()
            if (-not $map.ContainsKey($k)) { $map[$k] = New-Object System.Collections.Generic.List[string] }
            if (-not $map[$k].Contains([string]$r.Name)) { $map[$k].Add([string]$r.Name) }
        }
    }
    $out = @{}
    foreach ($k in @($map.Keys)) { $out[$k] = @($map[$k].ToArray() | Sort-Object) }
    return $out
}

function Get-RunningDependents {
    # Nur laufende Abhaengige sind ein Problem - sie werden mit angehalten.
    param($Map, [string]$Name, $StatusByName)
    $res = @()
    if (-not $Map -or -not $Name) { return $res }
    $k = ([string]$Name).ToLowerInvariant()
    if (-not $Map.ContainsKey($k)) { return $res }
    foreach ($d in @($Map[$k])) {
        $st = ''
        try { if ($StatusByName -and $StatusByName.ContainsKey([string]$d)) { $st = [string]$StatusByName[[string]$d] } } catch { }
        if ($st -eq 'Running') { $res += [string]$d }
    }
    return @($res | Sort-Object)
}

function Get-ServiceActionPlan {
    # Reine Entscheidung: darf die Aktion laufen, und was ist das Ziel?
    param(
        [string]$Action,
        [bool]$Protected = $false,
        [string]$CurrentStartup = 'Unknown',
        [string]$CurrentStatus = 'Unknown',
        [string]$PreviousStartup = '',
        [string[]]$Dependents = @()
    )
    $plan = @{ Allowed = $true; Kind = 'startup'; Target = ''; ReasonKey = ''; HintKey = ''; Dependents = @() }
    if ($Action -in @('Stop', 'Disable') -and $Protected) {
        $plan.Allowed = $false; $plan.ReasonKey = 'Protected'
        return $plan
    }
    # Laufende Abhaengige werden beim Anhalten mitgerissen - das muss vorher
    # auf den Tisch, frueher verschwanden sie kommentarlos.
    if ($Action -eq 'Stop') { $plan.Dependents = @($Dependents) }
    switch ($Action) {
        'Disable' {
            $plan.Target = 'Disabled'
            if ($CurrentStartup -eq 'Disabled') { $plan.Allowed = $false; $plan.ReasonKey = 'SvcNoChange' }
            # Abschalten heisst nur: beim naechsten Hochfahren nicht mehr.
            # Wer das nicht weiss, wundert sich ueber den weiter laufenden Dienst.
            elseif ($CurrentStatus -eq 'Running') { $plan.HintKey = 'SvcStillRunning' }
        }
        'Enable' {
            # Frueher stand hier fest 'Automatic'. Damit startete nach einem
            # Rueckgaengig jeder Dienst beim Hochfahren mit, der vorher auf
            # Manuell stand - der Rechner bootete danach langsamer als zuvor.
            if ($PreviousStartup -in @('Automatic', 'Manual', 'Boot', 'System')) {
                $plan.Target = $PreviousStartup
            }
            else {
                $plan.Target = 'Manual'
                $plan.ReasonKey = 'SvcFallback'
            }
            if ($CurrentStartup -eq $plan.Target) { $plan.Allowed = $false; $plan.ReasonKey = 'SvcNoChange' }
        }
        'Start' {
            $plan.Kind = 'status'; $plan.Target = 'Running'
            if ($CurrentStatus -eq 'Running') { $plan.Allowed = $false; $plan.ReasonKey = 'SvcNoChange' }
            # Windows meldet hier nur einen nichtssagenden Fehlercode.
            elseif ($CurrentStartup -eq 'Disabled') { $plan.Allowed = $false; $plan.ReasonKey = 'SvcStartDisabled' }
        }
        'Stop' {
            $plan.Kind = 'status'; $plan.Target = 'Stopped'
            if ($CurrentStatus -eq 'Stopped') { $plan.Allowed = $false; $plan.ReasonKey = 'SvcNoChange' }
        }
        default { $plan.Allowed = $false; $plan.ReasonKey = 'Error' }
    }
    return $plan
}

function Get-LastServiceStartup {
    # Letzter von uns aufgezeichneter Starttyp dieses Dienstes, damit
    # 'Aktivieren' den Zustand von vorher trifft statt pauschal Automatisch.
    param([string]$Name)
    if (-not $script:ChangeLog) { return '' }
    for ($i = $script:ChangeLog.Count - 1; $i -ge 0; $i--) {
        $e = $script:ChangeLog[$i]
        if (-not $e -or $e.Action -ne 'service') { continue }
        if ([string]$e.Name -ne [string]$Name) { continue }
        return [string]$e.OldValue
    }
    return ''
}

function Test-ServiceProtected {
    param([string]$ServiceName)
    if ([string]::IsNullOrWhiteSpace($ServiceName)) { return $true }
    return ($script:ProtectedServices -contains $ServiceName)
}

$script:ProtectedTasks = @(
    # Platzhalter gegen den vollstaendigen Aufgabenpfad. Diese Aufgaben
    # abzuschalten beschaedigt Windows auf eine Weise, die der Benutzer erst
    # Wochen spaeter bemerkt - SystemRestore etwa vernichtet still die
    # Wiederherstellungspunkte, auf die dieses Programm selbst baut.
    '\Microsoft\Windows\SystemRestore\*'
    '\Microsoft\Windows\Windows Defender\*'
    '\Microsoft\Windows\UpdateOrchestrator\*'
    '\Microsoft\Windows\WindowsUpdate\*'
    '\Microsoft\Windows\Servicing\*'
    '\Microsoft\Windows\Chkdsk\*'
    '\Microsoft\Windows\Defrag\*'
    '\Microsoft\Windows\DiskCleanup\*'
    '\Microsoft\Windows\BitLocker\*'
    '\Microsoft\Windows\Time Synchronization\*'
    '\Microsoft\Windows\TaskScheduler\*'
    '\Microsoft\Windows\Shell\CreateObjectTask'
    '\Microsoft\Windows\Data Integrity Scan\*'
    '\Microsoft\Windows\Storage Tiers Management\*'
)

function Get-TaskFullPath {
    # TaskPath endet laut Aufgabenplanung immer auf einem Backslash,
    # verlassen will ich mich darauf nicht.
    param([string]$TaskPath, [string]$TaskName)
    $base = [string]$TaskPath
    if (-not $base) { $base = '\' }
    if (-not $base.StartsWith('\')) { $base = '\' + $base }
    if (-not $base.EndsWith('\')) { $base += '\' }
    return $base + ([string]$TaskName).TrimStart('\')
}

function Test-TaskProtected {
    param([string]$TaskPath, [string]$TaskName)
    if ([string]::IsNullOrWhiteSpace($TaskName)) { return $true }
    $full = Get-TaskFullPath -TaskPath $TaskPath -TaskName $TaskName
    foreach ($pat in $script:ProtectedTasks) {
        if ($full -like $pat) { return $true }
    }
    return $false
}

function Get-TaskActionPlan {
    # Reine Entscheidung, genau wie bei den Diensten.
    param(
        [string]$Action,
        [bool]$Protected = $false,
        [string]$CurrentState = 'Unknown'
    )
    $plan = @{ Allowed = $true; Target = ''; Journal = $true; ReasonKey = '' }
    switch ($Action) {
        'Disable' {
            $plan.Target = 'Disabled'
            if ($Protected) { $plan.Allowed = $false; $plan.ReasonKey = 'TskProtected'; return $plan }
            if ($CurrentState -eq 'Disabled') { $plan.Allowed = $false; $plan.ReasonKey = 'SvcNoChange' }
        }
        'Enable' {
            $plan.Target = 'Ready'
            if ($CurrentState -in @('Ready', 'Running')) { $plan.Allowed = $false; $plan.ReasonKey = 'SvcNoChange' }
        }
        'Run' {
            # Einmal ausfuehren aendert keinen Zustand - nichts zu journalisieren.
            $plan.Target = ''; $plan.Journal = $false
            if ($CurrentState -eq 'Disabled') { $plan.Allowed = $false; $plan.ReasonKey = 'TskRunDisabled' }
            # Ein zweiter Start waehrend des Laufs erzeugt entweder eine
            # zweite Instanz oder einen Fehlercode - beides will niemand.
            elseif ($CurrentState -eq 'Running') { $plan.Allowed = $false; $plan.ReasonKey = 'TskRunning' }
        }
        default { $plan.Allowed = $false; $plan.ReasonKey = 'Error' }
    }
    return $plan
}

function Test-DefenderExclusionRisk {
    # Reine Bewertung eines Ausschlusspfades. 'block' wird gar nicht erst
    # gesetzt, 'warn' nur nach ausdruecklicher Bestaetigung. Eine Ausnahme
    # ist der einzige Griff in diesem Programm, mit dem man sich dauerhaft
    # und unbemerkt angreifbar macht.
    param([string]$Path)
    $res = @{ Level = 'ok'; ReasonKey = '' }
    $p = ([string]$Path).Trim().Trim('"')
    if ([string]::IsNullOrWhiteSpace($p)) { return @{ Level = 'block'; ReasonKey = 'DefBadName' } }

    $norm = $p.TrimEnd('\', '/')
    # Umgebungsvariablen aufloesen, sonst umgeht %SystemRoot% jede Pruefung
    try { $norm = [System.Environment]::ExpandEnvironmentVariables($norm) } catch { }
    $low = $norm.ToLowerInvariant()

    if ($low -match '[\*\?]') { return @{ Level = 'block'; ReasonKey = 'DefRiskWild' } }
    # Defender loest Umgebungsvariablen selbst auf. Bleibt nach der Aufloesung
    # noch ein %...% stehen, wissen wir nicht, worauf der Pfad zeigt - und was
    # sich nicht beurteilen laesst, wird nicht gesetzt. '%SystemRoot%' waere
    # sonst ein Weg, die Sperre fuer C:\Windows zu umgehen.
    if ($low -match '%[^%]+%') { return @{ Level = 'block'; ReasonKey = 'DefRiskSystem' } }
    # Laufwerkswurzel: 'C:', 'C:\', '\' oder eine blosse UNC-Freigabe
    if ($low -match '^[a-z]:$' -or $low -eq '' -or $low -eq '\' -or $low -match '^\\\\[^\\]+$') {
        return @{ Level = 'block'; ReasonKey = 'DefRiskRoot' }
    }
    foreach ($sys in @('c:\windows', 'c:\program files', 'c:\program files (x86)', 'c:\programdata', 'c:\users')) {
        if ($low -eq $sys) { return @{ Level = 'block'; ReasonKey = 'DefRiskSystem' } }
    }
    if ($low -like 'c:\windows\*') { return @{ Level = 'block'; ReasonKey = 'DefRiskSystem' } }

    $prof = ''
    try { $prof = ([string]$env:USERPROFILE).TrimEnd('\').ToLowerInvariant() } catch { }
    if ($prof -and $low -eq $prof) { return @{ Level = 'warn'; ReasonKey = 'DefRiskProfile' } }
    if ($low -match '\\(temp|tmp|downloads|desktop)$') { return @{ Level = 'warn'; ReasonKey = 'DefRiskTemp' } }
    if ($low -like 'c:\program files*' -or $low -like 'c:\programdata*') {
        return @{ Level = 'warn'; ReasonKey = 'DefRiskSystem' }
    }
    return $res
}

function Test-ExclusionProcessName {
    # -ExclusionProcess erwartet einen Prozessnamen oder einen vollen Pfad -
    # nicht irgendeinen Text aus einem Eingabefeld.
    param([string]$Name)
    $n = ([string]$Name).Trim().Trim('"')
    if ([string]::IsNullOrWhiteSpace($n)) { return $false }
    if ($n -match '[\*\?<>|]') { return $false }
    if ($n.Length -gt 260) { return $false }
    # Entweder blosser Dateiname mit Endung oder ein voller Pfad darauf
    if ($n -match '^[^\\/:]+\.(exe|com|scr|bat|cmd|ps1)$') { return $true }
    if ($n -match '^[a-zA-Z]:\\.+\.(exe|com|scr|bat|cmd|ps1)$') { return $true }
    return $false
}

function Test-ProcessProtected {
    param([string]$ProcessName)
    if ([string]::IsNullOrWhiteSpace($ProcessName)) { return $true }
    return ($script:ProtectedProcesses -contains $ProcessName)
}

# --- Backups ------------------------------------------------------------------
#region 4b. CHANGE JOURNAL (undo for registry tweaks)

# Every registry change now goes through Set-RegistryValue / Remove-RegistryValue.
# Both remember the previous value, so a single tweak can be taken back later -
# the .reg backups only ever covered whole keys and only for a few actions.

$script:ChangeLog = New-Object System.Collections.ArrayList

function Get-ChangeLogPath {
    try {
        $dir = $script:Config.BackupDir
        if (-not $dir) { return $null }
        if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -Path $dir -ItemType Directory -Force) }
        return (Join-Path $dir 'changes.jsonl')
    }
    catch { return $null }
}

function Import-ChangeLog {
    # One JSON object per line - appending a change costs a single write
    try {
        $script:ChangeLog.Clear()
        $file = Get-ChangeLogPath
        if (-not $file -or -not (Test-Path -LiteralPath $file)) { return }
        foreach ($line in (Get-Content -LiteralPath $file -Encoding UTF8 -ErrorAction Stop)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            try { [void]$script:ChangeLog.Add((ConvertFrom-Json $line)) } catch { }
        }
        # Keep the file from growing without bounds
        if ($script:ChangeLog.Count -gt 400) {
            $keep = @(Select-ChangeLogKeep -Entries @($script:ChangeLog) -Max 400 -Target 300)
            $script:ChangeLog.Clear()
            foreach ($k in $keep) { [void]$script:ChangeLog.Add($k) }
            Save-ChangeLog
        }
    }
    catch { }
}

function Save-ChangeLog {
    # Full rewrite - only used after an undo, normal changes just append
    try {
        $file = Get-ChangeLogPath
        if (-not $file) { return }
        $sb = New-Object System.Text.StringBuilder
        foreach ($e in $script:ChangeLog) {
            [void]$sb.AppendLine((ConvertTo-Json $e -Depth 4 -Compress))
        }
        [System.IO.File]::WriteAllText($file, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
    }
    catch { }
}

function Get-ChangeTargetText {
    # Eine Spalte, zwei Arten von Eintraegen: Registrierungswerte tragen
    # Pfad\Name, Diensteintraege nur ihren Dienstnamen. Liste und Bericht
    # benutzen beide diesen Helfer, damit sie nicht auseinanderlaufen.
    param($Entry)
    if (-not $Entry) { return '' }
    switch ([string]$Entry.Action) {
        'service' { return "$(Get-Text 'ChgService'): $($Entry.Name)" }
        'task' { return "$(Get-Text 'ChgTask'): $($Entry.Path)" }
        'file' { return "$(Get-Text 'ChgFile'): $($Entry.OldValue)" }
        'defender' { return "$(Get-Text 'ChgDefender'): $($Entry.Name)" }
        'dns' { return "$(Get-Text 'ChgDns'): $($Entry.Name)" }
    }
    return "$($Entry.Path)\$($Entry.Name)"
}

function Add-ChangeEntry {
    param(
        [string]$Action = 'set',
        [string]$Path,
        [string]$Name,
        [string]$Type = 'DWord',
        $OldValue,
        $NewValue,
        [bool]$Existed = $false,
        [bool]$KeyCreated = $false,
        [string]$Label = ''
    )
    $entry = [pscustomobject]@{
        Time       = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        Action     = $Action
        Label      = $Label
        Path       = $Path
        Name       = $Name
        Type       = $Type
        OldValue   = $OldValue
        NewValue   = $NewValue
        Existed    = $Existed
        KeyCreated = $KeyCreated
        Undone     = $false
    }
    [void]$script:ChangeLog.Add($entry)
    try {
        $file = Get-ChangeLogPath
        if ($file) {
            [System.IO.File]::AppendAllText($file, (ConvertTo-Json $entry -Depth 4 -Compress) + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
        }
    }
    catch { }
    return $entry
}

function Get-RegistryValueKind {
    param([string]$Path, [string]$Name)
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        return $item.GetValueKind($Name).ToString()
    }
    catch { return 'String' }
}

function Set-RegistryValue {
    # Writes a registry value and records the previous state for undo
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [string]$Type = 'DWord',
        [string]$Label = '',
        [switch]$Quiet
    )
    try {
        $keyExisted = Test-Path -LiteralPath $Path
        if (-not $keyExisted) { [void](New-Item -Path $Path -Force -ErrorAction Stop) }

        $old = $null
        $existed = $false
        $oldType = $Type
        try {
            $cur = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
            if ($null -ne $cur) {
                $old = $cur.$Name
                $existed = $true
                $oldType = Get-RegistryValueKind -Path $Path -Name $Name
            }
        }
        catch { }

        Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop

        # Writing the same value again is not a change worth remembering
        $same = $false
        try { $same = ($existed -and ("$old" -eq "$Value")) } catch { }
        if (-not $same) {
            [void](Add-ChangeEntry -Action 'set' -Path $Path -Name $Name -Type $oldType `
                    -OldValue $old -NewValue $Value -Existed $existed -KeyCreated (-not $keyExisted) -Label $Label)
        }
        return $true
    }
    catch {
        if (-not $Quiet) { Write-Log "$Name : $($_.Exception.Message)" 'WARNING' | Out-Null }
        return $false
    }
}

function Remove-RegistryValue {
    # Deletes a value and remembers it, so the deletion can be taken back
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [string]$Label = '',
        [switch]$Quiet
    )
    try {
        if (-not (Test-Path -LiteralPath $Path)) { return $false }
        $old = $null
        $existed = $false
        $oldType = 'String'
        try {
            $cur = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
            if ($null -ne $cur) {
                $old = $cur.$Name
                $existed = $true
                $oldType = Get-RegistryValueKind -Path $Path -Name $Name
            }
        }
        catch { }
        if (-not $existed) { return $false }

        Remove-ItemProperty -LiteralPath $Path -Name $Name -Force -ErrorAction Stop
        [void](Add-ChangeEntry -Action 'remove' -Path $Path -Name $Name -Type $oldType `
                -OldValue $old -NewValue $null -Existed $true -KeyCreated $false -Label $Label)
        return $true
    }
    catch {
        if (-not $Quiet) { Write-Log "$Name : $($_.Exception.Message)" 'WARNING' | Out-Null }
        return $false
    }
}

function ConvertTo-RegistryValue {
    # Nach der JSON-Rundreise ist aus einer DWORD-Zahl ein Int64 geworden.
    # 0xFFFFFFFF (NetworkThrottlingIndex) sprengt dabei [int] und warf eine
    # OverflowException - ausgerechnet beim Zurueckschreiben.
    param($Value, [string]$Type = 'String')
    switch ($Type) {
        'Binary' {
            if ($null -eq $Value) { return , ([byte[]]@()) }
            return , ([byte[]]@($Value | ForEach-Object { [byte]([int]$_ -band 0xFF) }))
        }
        'MultiString' {
            if ($null -eq $Value) { return , ([string[]]@()) }
            return , ([string[]]@($Value | ForEach-Object { "$_" }))
        }
        'DWord' {
            $n = 0L
            try { $n = [int64]$Value } catch { $n = 0L }
            $n = $n -band 0xFFFFFFFFL
            if ($n -gt 2147483647L) { $n = $n - 4294967296L }
            return [int]$n
        }
        'QWord' {
            try { return [int64]$Value } catch { return [int64]0 }
        }
        'ExpandString' { return "$Value" }
        'String' { return "$Value" }
        default { return $Value }
    }
}

function Test-RegistryValueEquals {
    # Gegenprobe nach dem Zurueckschreiben: Set-ItemProperty meldet keinen
    # Fehler, wenn ein Filtertreiber oder eine Richtlinie den Wert sofort
    # wieder ueberschreibt.
    param([string]$Path, [string]$Name, $Expected)
    try {
        $cur = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
        if ($null -eq $cur) { return $false }
        $now = $cur.$Name
        if ($Expected -is [array] -or $now -is [array]) {
            return ((@($now) -join '|') -eq (@($Expected) -join '|'))
        }
        return ("$now" -eq "$Expected")
    }
    catch { return $false }
}

function Select-ChangeLogKeep {
    # Begrenzt das Journal, ohne die Rueckgaengig-Faehigkeit zu verlieren:
    # noch offene Eintraege bleiben IMMER erhalten, weggeworfen werden nur
    # die aeltesten bereits zurueckgenommenen. Vorher schnitt die Rotation
    # stumpf die aeltesten 100 Zeilen ab - darunter auch offene.
    param([array]$Entries = @(), [int]$Max = 400, [int]$Target = 300)
    $all = @($Entries)
    if ($all.Count -le $Max) { return $all }
    $openIdx = @()
    $doneIdx = @()
    for ($i = 0; $i -lt $all.Count; $i++) {
        if ($all[$i].Undone) { $doneIdx += $i } else { $openIdx += $i }
    }
    $room = $Target - $openIdx.Count
    $keepDone = @()
    if ($room -gt 0 -and $doneIdx.Count -gt 0) {
        $take = [Math]::Min($room, $doneIdx.Count)
        $keepDone = @($doneIdx[($doneIdx.Count - $take)..($doneIdx.Count - 1)])
    }
    $keep = @($openIdx + $keepDone | Sort-Object)
    return @($keep | ForEach-Object { $all[$_] })
}

function Undo-ChangeEntry {
    # Puts one recorded change back the way it was
    param($Entry, [switch]$Quiet)
    if (-not $Entry) { return $false }
    if ($Entry.Undone) { return $false }
    # Diensteintraege gehen nicht ueber die Registrierung zurueck - der
    # Dienststeuerungs-Manager haelt den Starttyp zwischengespeichert und
    # wuerde ein direktes Schreiben auf 'Start' erst nach einem Neustart sehen.
    if ($Entry.Action -eq 'service') { return (Restore-ServiceStartup -Entry $Entry -Quiet:$Quiet) }
    if ($Entry.Action -eq 'task') { return (Restore-TaskState -Entry $Entry -Quiet:$Quiet) }
    if ($Entry.Action -eq 'file') { return (Restore-MovedFile -Entry $Entry -Quiet:$Quiet) }
    if ($Entry.Action -eq 'defender') { return (Restore-DefenderExclusion -Entry $Entry -Quiet:$Quiet) }
    if ($Entry.Action -eq 'dns') { return (Restore-AdapterDns -Entry $Entry -Quiet:$Quiet) }
    try {
        if ($Entry.Existed) {
            $val = ConvertTo-RegistryValue -Value $Entry.OldValue -Type $Entry.Type
            if (-not (Test-Path -LiteralPath $Entry.Path)) { [void](New-Item -Path $Entry.Path -Force -ErrorAction Stop) }
            Set-ItemProperty -LiteralPath $Entry.Path -Name $Entry.Name -Value $val -Type $Entry.Type -Force -ErrorAction Stop
            if (-not (Test-RegistryValueEquals -Path $Entry.Path -Name $Entry.Name -Expected $val)) {
                if (-not $Quiet) { Write-Log "$($Entry.Name): $(Get-Text 'ChangeVerifyErr')" 'ERROR' | Out-Null }
                return $false
            }
        }
        else {
            # The value did not exist before the tweak - remove it again
            if (Test-Path -LiteralPath $Entry.Path) {
                Remove-ItemProperty -LiteralPath $Entry.Path -Name $Entry.Name -Force -ErrorAction SilentlyContinue
            }
            if ($Entry.KeyCreated) {
                try {
                    $props = @(Get-Item -LiteralPath $Entry.Path -ErrorAction Stop).Property
                    $kids = @(Get-ChildItem -LiteralPath $Entry.Path -ErrorAction SilentlyContinue)
                    if ($props.Count -eq 0 -and $kids.Count -eq 0) {
                        Remove-Item -LiteralPath $Entry.Path -Force -ErrorAction SilentlyContinue
                    }
                }
                catch { }
            }
        }
        $Entry.Undone = $true
        if (-not $Quiet) { Write-Log "$(Get-Text 'ChangeUndone'): $($Entry.Name)" 'SUCCESS' | Out-Null }
        return $true
    }
    catch {
        if (-not $Quiet) { Write-Log "$($Entry.Name): $($_.Exception.Message)" 'ERROR' | Out-Null }
        return $false
    }
}

function Restore-ServiceStartup {
    param($Entry, [switch]$Quiet)
    $name = [string]$Entry.Name
    $old = [string]$Entry.OldValue
    if ($old -notin @('Automatic', 'Manual', 'Disabled', 'Boot', 'System')) {
        if (-not $Quiet) { Write-Log "$name : $(Get-Text 'SvcVerifyErr')" 'ERROR' | Out-Null }
        return $false
    }
    # Boot und System lassen sich mit Set-Service nicht setzen - diese
    # Treiberdienste koennen wir nur ueber die Registrierung zuruecksetzen.
    try {
        if ($old -in @('Boot', 'System')) {
            $v = if ($old -eq 'Boot') { 0 } else { 1 }
            Set-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Services\$name" `
                -Name 'Start' -Value $v -Type DWord -Force -ErrorAction Stop
        }
        else {
            Set-Service -Name $name -StartupType $old -ErrorAction Stop
        }
        if ((Get-ServiceStartupType -Name $name) -ne $old) {
            if (-not $Quiet) { Write-Log "$name : $(Get-Text 'SvcVerifyErr')" 'ERROR' | Out-Null }
            return $false
        }
        $Entry.Undone = $true
        if (-not $Quiet) { Write-Log "$(Get-Text 'SvcRestored'): $name -> $old" 'SUCCESS' | Out-Null }
        return $true
    }
    catch {
        if (-not $Quiet) { Write-Log "$name : $($_.Exception.Message)" 'ERROR' | Out-Null }
        return $false
    }
}

function Restore-TaskState {
    param($Entry, [switch]$Quiet)
    $full = [string]$Entry.Path
    $old = [string]$Entry.OldValue
    $leaf = Split-Path -Leaf $full
    $dir = Split-Path -Parent $full
    if (-not $dir.EndsWith('\')) { $dir += '\' }
    try {
        if ($old -eq 'Disabled') { Disable-ScheduledTask -TaskName $leaf -TaskPath $dir -ErrorAction Stop | Out-Null }
        else { Enable-ScheduledTask -TaskName $leaf -TaskPath $dir -ErrorAction Stop | Out-Null }
        $now = [string](Get-ScheduledTask -TaskName $leaf -TaskPath $dir -ErrorAction Stop).State
        # 'Ready' und 'Running' sind beide der eingeschaltete Zustand.
        $back = if ($old -eq 'Disabled') { $now -eq 'Disabled' } else { $now -ne 'Disabled' }
        if (-not $back) {
            if (-not $Quiet) { Write-Log "$leaf : $(Get-Text 'SvcVerifyErr')" 'ERROR' | Out-Null }
            return $false
        }
        $Entry.Undone = $true
        if (-not $Quiet) { Write-Log "$(Get-Text 'ChangeUndone'): $leaf -> $old" 'SUCCESS' | Out-Null }
        return $true
    }
    catch {
        if (-not $Quiet) { Write-Log "$leaf : $($_.Exception.Message)" 'ERROR' | Out-Null }
        return $false
    }
}

function ConvertTo-PsLiteral {
    # Ein Wert, der als Text in einen Hintergrundbefehl eingesetzt wird, muss
    # sauber eingefasst sein. Ein Pfad wie D:\Ehab's Spiele haette den Befehl
    # sonst mitten im Wort beendet - und im schlimmsten Fall etwas ganz
    # anderes ausgefuehrt.
    param([string]$Text)
    return "'" + ([string]$Text).Replace("'", "''") + "'"
}

function Get-DefenderExclusionParam {
    param([string]$Kind)
    switch ($Kind) {
        'Process' { return 'ExclusionProcess' }
        'Extension' { return 'ExclusionExtension' }
        default { return 'ExclusionPath' }
    }
}

function Get-DefenderExclusionScript {
    # Setzen und Nachlesen in EINEM Hintergrundlauf. Frueher waren das zwei
    # getrennte Aufrufe im Oberflaechenstrang: Add-MpPreference (Sekunden)
    # und danach Get-MpPreference (ein bis drei Sekunden). Bei zehn
    # markierten Eintraegen stand das Fenster so fast eine Minute still.
    param([string]$Kind, [string]$Value, [string]$Mode = 'add')
    $p = Get-DefenderExclusionParam -Kind $Kind
    $lit = ConvertTo-PsLiteral -Text $Value
    $verb = if ($Mode -eq 'remove') { 'Remove-MpPreference' } else { 'Add-MpPreference' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("$verb -$p $lit -ErrorAction Stop")
    [void]$sb.AppendLine("`$want = ($lit).TrimEnd('\')")
    [void]$sb.AppendLine("`$pref = Get-MpPreference -ErrorAction Stop")
    [void]$sb.AppendLine("`$hit = @(@(`$pref.$p) | Where-Object { `$_ -and ([string]`$_).TrimEnd('\') -eq `$want })")
    [void]$sb.AppendLine("if (`$hit.Count -gt 0) { 'da' } else { 'weg' }")
    return $sb.ToString()
}

function Set-DefenderExclusion {
    # Eine Stelle fuer Setzen und Entfernen, damit Pruefung, Nachlesen und
    # Journal nicht an drei Orten getrennt gepflegt werden muessen.
    param(
        [ValidateSet('Path', 'Process', 'Extension')][string]$Kind,
        [string]$Value,
        [ValidateSet('add', 'remove')][string]$Mode = 'add',
        [switch]$NoJournal
    )
    $want = ($Mode -eq 'add')
    $bg = Invoke-Background -TimeoutSec 120 -Status $Value `
        -Script (Get-DefenderExclusionScript -Kind $Kind -Value $Value -Mode $Mode)
    $vd = Get-BackgroundOutcome -Result $bg
    if (-not $vd.Ok) {
        $why = if ($vd.ReasonKey) { Get-Text $vd.ReasonKey } else { [string]$bg.Error }
        Write-Log "$Value : $why" $vd.Level
        return $false
    }
    # Nachlesen statt annehmen: Manipulationsschutz und Gruppenrichtlinien
    # verwerfen eine Ausnahme, ohne dass Add-MpPreference einen Fehler wirft.
    $there = (@($bg.Output) -contains 'da')
    if ($there -ne $want) {
        Write-Log "$Value : $(Get-Text 'DefVerifyErr')" 'ERROR'
        return $false
    }
    if (-not $NoJournal) {
        [void](Add-ChangeEntry -Action 'defender' -Path $Kind -Name $Value -Type $Kind `
                -OldValue $(if ($want) { 'none' } else { 'set' }) `
                -NewValue $(if ($want) { 'set' } else { 'none' }) `
                -Existed $true -Label (Get-Text 'DefAction'))
    }
    return $true
}

function Invoke-DefenderExclusionBatch {
    # Mehrere Eintraege am Stueck, mit Fortschritt und Abbruch. Die alte
    # Schleife lief ohne Warteflaeche - fuer den Nutzer war nicht zu
    # unterscheiden, ob das Programm arbeitet oder haengt.
    param($Items, [string]$Mode = 'remove', [string]$Label = '')
    $list = @($Items)
    if ($list.Count -eq 0) { return @{ Ok = 0; Total = 0; Failed = @() } }
    $ok = 0
    $failed = @()
    $i = 0
    Show-BusyOverlay -Title $Label -Cancellable
    try {
        foreach ($it in $list) {
            # Erst pruefen, dann zaehlen: sonst taucht der abgebrochene
            # Eintrag in der Bilanz als nicht erledigt auf, obwohl er gar
            # nicht mehr angefasst wurde.
            if (Test-BusyCancelled) { Write-Log (Get-Text 'BusyCancelled') 'WARNING'; break }
            $i++
            $kind = [string]$it.Kind
            if ($kind -notin @('Path', 'Process', 'Extension')) { $kind = 'Path' }
            Update-BusyOverlay -Status "$($it.Value)   ($i / $($list.Count))" `
                -Percent ([int](($i - 1) / [double]$list.Count * 100))
            if (Set-DefenderExclusion -Kind $kind -Value ([string]$it.Value) -Mode $Mode) { $ok++ }
            else { $failed += [string]$it.Value }
        }
    }
    finally { Hide-BusyOverlay }
    return @{ Ok = $ok; Total = $i; Failed = $failed }
}

function Restore-DefenderExclusion {
    # Rueckwaerts: war sie gesetzt, wird sie entfernt - und umgekehrt.
    param($Entry, [switch]$Quiet)
    $kind = [string]$Entry.Type
    if ($kind -notin @('Path', 'Process', 'Extension')) { $kind = 'Path' }
    $wasAdded = ([string]$Entry.NewValue -eq 'set')
    $mode = if ($wasAdded) { 'remove' } else { 'add' }
    if (Set-DefenderExclusion -Kind $kind -Value ([string]$Entry.Name) -Mode $mode -NoJournal) {
        $Entry.Undone = $true
        if (-not $Quiet) {
            $k = if ($wasAdded) { 'DefRemoved' } else { 'DefReAdded' }
            Write-Log "$(Get-Text $k): $($Entry.Name)" 'SUCCESS' | Out-Null
        }
        return $true
    }
    return $false
}

function Confirm-DefenderExclusion {
    # Rueckfrage nach Risikostufe. 'block' kommt gar nicht erst zur Frage.
    param([string]$Value)
    $risk = Test-DefenderExclusionRisk -Path $Value
    if ($risk.Level -eq 'block') {
        Write-Log "$(Get-Text 'DefBlocked'): $Value" 'ERROR'
        Write-Log (Get-Text $risk.ReasonKey) 'WARNING'
        return $false
    }
    if ($risk.Level -eq 'warn') {
        $res = Show-WarningDialog -Title (Get-Text 'DefConfirm') -Message "$Value`n`n$(Get-Text $risk.ReasonKey)"
        return ($res -eq [System.Windows.Forms.DialogResult]::OK)
    }
    return (Show-Confirm -Message "$(Get-Text 'DefConfirm')`n`n$Value")
}

# --- Netzwerk: DNS, Nagle, Zuruecksetzen -------------------------------------
# Die Netzwerkkarten haben frueher ohne Rueckfrage und ohne Journal in die
# Namensaufloesung eingegriffen. Hier gilt dieselbe Ordnung wie bei Diensten
# und Defender: messen, fragen, ausfuehren, nachlesen, eintragen.
$script:DnsTarget4 = @('1.1.1.1', '1.0.0.1')
$script:DnsTarget6 = @('2606:4700:4700::1111', '2606:4700:4700::1001')

function ConvertTo-DnsRecord {
    # Beide Adressfamilien in eine Journalzeile. '=' und '|' kommen in
    # IPv4- wie IPv6-Adressen nicht vor, ':' dagegen sehr wohl.
    param([string[]]$V4 = @(), [string[]]$V6 = @())
    $a = (@($V4 | Where-Object { $_ }) -join ',')
    $b = (@($V6 | Where-Object { $_ }) -join ',')
    return "4=$a|6=$b"
}

function ConvertFrom-DnsRecord {
    param([string]$Text)
    $res = @{ V4 = @(); V6 = @() }
    foreach ($part in ([string]$Text -split '\|')) {
        $p = ([string]$part).Trim()
        if ($p.StartsWith('4=')) { $res.V4 = @($p.Substring(2) -split ',' | Where-Object { $_ }) }
        elseif ($p.StartsWith('6=')) { $res.V6 = @($p.Substring(2) -split ',' | Where-Object { $_ }) }
    }
    return $res
}

function Format-DnsServerList {
    param([string[]]$Servers = @())
    $l = @($Servers | Where-Object { $_ })
    if ($l.Count -eq 0) { return (Get-Text 'NetDnsAuto') }
    return ($l -join ', ')
}

function Get-AdapterDnsServers {
    # Getrennt nach Familie: 2 = IPv4, 23 = IPv6
    param([int]$Index)
    $res = @{ V4 = @(); V6 = @() }
    try {
        foreach ($c in @(Get-DnsClientServerAddress -InterfaceIndex $Index -ErrorAction Stop)) {
            $srv = @($c.ServerAddresses | Where-Object { $_ })
            if ([int]$c.AddressFamily -eq 2) { $res.V4 = $srv }
            elseif ([int]$c.AddressFamily -eq 23) { $res.V6 = $srv }
        }
    }
    catch { }
    return $res
}

function Get-DnsAdapterTargets {
    # Nur verbundene physische Adapter. Hyper-V-, TAP- und Loopback-
    # Schnittstellen wuerden sonst eine Umstellung melden, die niemand sieht.
    $out = @()
    try {
        foreach ($a in @(Get-NetAdapter -Physical -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' })) {
            $dns = Get-AdapterDnsServers -Index ([int]$a.ifIndex)
            $out += [pscustomobject]@{
                Name  = [string]$a.Name
                Index = [int]$a.ifIndex
                Guid  = [string]$a.InterfaceGuid
                V4    = @($dns.V4)
                V6    = @($dns.V6)
            }
        }
    }
    catch { }
    return $out
}

function Test-DnsChangeRisk {
    # Ein fremder Resolver ist auf einem Firmenrechner kein Tuning, sondern
    # ein Ausfall: interne Namen loest Cloudflare nicht auf.
    param([bool]$DomainJoined = $false, [bool]$VpnActive = $false)
    if ($DomainJoined) { return @{ Level = 'warn'; ReasonKey = 'NetDnsDomain' } }
    if ($VpnActive) { return @{ Level = 'warn'; ReasonKey = 'NetDnsVpn' } }
    return @{ Level = 'ok'; ReasonKey = '' }
}

function Test-DomainJoined {
    try { return [bool](Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).PartOfDomain }
    catch { return $false }
}

function Test-VpnAdapterActive {
    try {
        $v = @(Get-NetAdapter -ErrorAction Stop | Where-Object {
                $_.Status -eq 'Up' -and (
                    "$($_.InterfaceDescription)" -match 'VPN|WireGuard|OpenVPN|TAP-|AnyConnect|Fortinet|Zscaler|Tailscale|SonicWall' -or
                    "$($_.Name)" -match 'VPN')
            })
        return ($v.Count -gt 0)
    }
    catch { return $false }
}

function Get-DnsActionPlan {
    # Dieselbe Karte schaltet hin und zurueck: steht ueberall schon das Ziel,
    # ist der naechste Klick das Zuruecksetzen auf DHCP.
    param($Adapters, [string[]]$Target = @())
    $all = @($Adapters | Where-Object { $_ })
    if ($all.Count -eq 0) { return @{ Mode = 'none'; Items = @() } }
    $tgt = @($Target | Where-Object { $_ })
    $items = @()
    foreach ($a in $all) {
        $cur = @($a.V4 | Where-Object { $_ })
        if (($cur -join ',') -ne ($tgt -join ',')) { $items += $a }
    }
    if ($items.Count -eq 0) { return @{ Mode = 'reset'; Items = $all } }
    return @{ Mode = 'set'; Items = $items }
}

function Test-DnsStaticEmpty {
    # Nach dem Zuruecksetzen liefert DHCP sofort wieder Server - ein Vergleich
    # der ausgelesenen Liste wuerde das Zuruecksetzen faelschlich als
    # fehlgeschlagen melden. Nur der statische Eintrag zaehlt.
    param([string]$Guid)
    if (-not $Guid) { return $true }
    $g = $Guid
    if (-not $g.StartsWith('{')) { $g = '{' + $g + '}' }
    foreach ($svc in @('Tcpip', 'Tcpip6')) {
        $p = "HKLM:\SYSTEM\CurrentControlSet\Services\$svc\Parameters\Interfaces\$g"
        try {
            $v = (Get-ItemProperty -LiteralPath $p -Name 'NameServer' -ErrorAction Stop).NameServer
            if ("$v".Trim() -ne '') { return $false }
        }
        catch { }
    }
    return $true
}

function Set-AdapterDnsServers {
    # Eine Stelle fuer Setzen und Zuruecksetzen - samt Nachlesen und Journal.
    param($Adapter, [string[]]$V4 = @(), [string[]]$V6 = @(), [switch]$NoJournal)
    $name = [string]$Adapter.Name
    $idx = [int]$Adapter.Index
    $want4 = @($V4 | Where-Object { $_ })
    $want6 = @($V6 | Where-Object { $_ })
    $oldRec = ConvertTo-DnsRecord -V4 @($Adapter.V4) -V6 @($Adapter.V6)
    try {
        $list = @($want4 + $want6)
        if ($list.Count -gt 0) {
            Set-DnsClientServerAddress -InterfaceIndex $idx -ServerAddresses $list -ErrorAction Stop
        }
        else {
            Set-DnsClientServerAddress -InterfaceIndex $idx -ResetServerAddresses -ErrorAction Stop
        }
        $after = Get-AdapterDnsServers -Index $idx
        $ok = $true
        if ($list.Count -gt 0) {
            foreach ($s in $want4) { if (@($after.V4) -notcontains $s) { $ok = $false } }
            foreach ($s in $want6) { if (@($after.V6) -notcontains $s) { $ok = $false } }
        }
        else {
            $ok = Test-DnsStaticEmpty -Guid ([string]$Adapter.Guid)
        }
        if (-not $ok) {
            Write-Log "$name : $(Get-Text 'NetDnsVerifyErr')" 'ERROR'
            return $false
        }
        if (-not $NoJournal) {
            [void](Add-ChangeEntry -Action 'dns' -Path ([string]$idx) -Name $name -Type 'dns' `
                    -OldValue $oldRec -NewValue (ConvertTo-DnsRecord -V4 $want4 -V6 $want6) `
                    -Existed $true -Label (Get-Text 'NetDnsAction'))
        }
        return $true
    }
    catch {
        Write-Log "$name : $($_.Exception.Message)" 'ERROR'
        return $false
    }
}

function Restore-AdapterDns {
    param($Entry, [switch]$Quiet)
    $rec = ConvertFrom-DnsRecord -Text ([string]$Entry.OldValue)
    $idx = 0
    [void][int]::TryParse([string]$Entry.Path, [ref]$idx)
    $ad = @(Get-DnsAdapterTargets | Where-Object { $_.Index -eq $idx -or $_.Name -eq [string]$Entry.Name })
    if ($ad.Count -eq 0) {
        if (-not $Quiet) { Write-Log "$($Entry.Name): $(Get-Text 'NetDnsGone')" 'ERROR' | Out-Null }
        return $false
    }
    if (Set-AdapterDnsServers -Adapter $ad[0] -V4 @($rec.V4) -V6 @($rec.V6) -NoJournal) {
        $Entry.Undone = $true
        if (-not $Quiet) { Write-Log "$(Get-Text 'NetDnsRestored'): $($Entry.Name)" 'SUCCESS' | Out-Null }
        return $true
    }
    return $false
}

function Test-RegistryValuePresent {
    param([string]$Path, [string]$Name)
    return ($null -ne (Get-RegistryValueFast -Path $Path -Name $Name))
}

function Get-NagleInterfaces {
    # Unter Interfaces liegen auch die GUIDs laengst entfernter Adapter.
    # Angefasst wird nur, was eine IPv4-Adresse hat.
    $out = @()
    $root = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
    try {
        foreach ($k in @(Get-ChildItem -LiteralPath $root -ErrorAction Stop)) {
            $p = $null
            try { $p = Get-ItemProperty -LiteralPath $k.PSPath -ErrorAction Stop } catch { continue }
            if (-not $p) { continue }
            $hasIp = $false
            foreach ($n in @('DhcpIPAddress', 'IPAddress')) {
                foreach ($v in @($p.$n)) {
                    if ("$v".Trim() -and "$v" -ne '0.0.0.0') { $hasIp = $true }
                }
            }
            if (-not $hasIp) { continue }
            $out += [pscustomobject]@{
                Path    = [string]$k.PSPath
                Name    = [string]$k.PSChildName
                Ack     = $(if ($null -ne $p.TcpAckFrequency) { [int]$p.TcpAckFrequency } else { -1 })
                NoDelay = $(if ($null -ne $p.TCPNoDelay) { [int]$p.TCPNoDelay } else { -1 })
            }
        }
    }
    catch { }
    return $out
}

function Get-NagleActionPlan {
    param($Interfaces)
    $all = @($Interfaces | Where-Object { $_ })
    if ($all.Count -eq 0) { return @{ Mode = 'none'; Items = @(); Applied = 0; Total = 0 } }
    $done = @($all | Where-Object { [int]$_.Ack -eq 1 -and [int]$_.NoDelay -eq 1 })
    if ($done.Count -eq $all.Count) {
        return @{ Mode = 'revert'; Items = $all; Applied = $done.Count; Total = $all.Count }
    }
    $todo = @($all | Where-Object { [int]$_.Ack -ne 1 -or [int]$_.NoDelay -ne 1 })
    return @{ Mode = 'apply'; Items = $todo; Applied = $done.Count; Total = $all.Count }
}

function Get-NetResetResult {
    # netsh meldet seinen Erfolg ueber den Rueckgabewert - der wurde bisher
    # verworfen und die Karte schrieb in jedem Fall 'Erfolgreich'.
    param($Codes = @())
    $c = @($Codes)
    if ($c.Count -eq 0) { return @{ Level = 'ERROR'; Key = 'NetResetFail'; Reboot = $false } }
    $ok = 0
    foreach ($x in $c) { if ($null -ne $x -and [int]$x -eq 0) { $ok++ } }
    if ($ok -eq $c.Count) { return @{ Level = 'SUCCESS'; Key = 'NetResetOk'; Reboot = $true } }
    if ($ok -eq 0) { return @{ Level = 'ERROR'; Key = 'NetResetFail'; Reboot = $false } }
    return @{ Level = 'WARNING'; Key = 'NetResetPart'; Reboot = $true }
}

function Get-PingSummary {
    # Ein Mittelwert allein verschweigt den Paketverlust - genau der ist aber
    # die Ursache, wenn ein Spiel ruckelt, obwohl der Ping gut aussieht.
    param([int]$Sent = 0, $Times = @())
    $t = @()
    foreach ($x in @($Times)) { if ($null -ne $x) { $t += [int]$x } }
    $recv = $t.Count
    $loss = 100
    if ($Sent -gt 0) { $loss = [int][math]::Round(((($Sent - $recv) / [double]$Sent) * 100), 0) }
    if ($loss -lt 0) { $loss = 0 }
    $res = @{ Sent = $Sent; Received = $recv; Loss = $loss; Min = 0; Avg = 0; Max = 0; Level = 'ERROR'; Key = 'NetPingDead' }
    if ($recv -gt 0) {
        $res.Min = [int]($t | Measure-Object -Minimum).Minimum
        $res.Max = [int]($t | Measure-Object -Maximum).Maximum
        $res.Avg = [int][math]::Round((($t | Measure-Object -Average).Average), 0)
        if ($loss -gt 0) { $res.Level = 'WARNING'; $res.Key = 'NetPingLoss' }
        else { $res.Level = 'INFO'; $res.Key = 'NetPingOk' }
    }
    return $res
}

function Restore-MovedFile {
    # Gegenstueck zum Verschieben in die Sicherung: die Datei wandert an
    # ihren urspruenglichen Platz zurueck.
    param($Entry, [switch]$Quiet)
    $origin = [string]$Entry.OldValue
    $stash = [string]$Entry.NewValue
    try {
        if (-not (Test-Path -LiteralPath $stash)) {
            if (-not $Quiet) { Write-Log "$origin : $(Get-Text 'FileGone')" 'ERROR' | Out-Null }
            return $false
        }
        $dir = Split-Path -Parent $origin
        if (-not (Test-Path -LiteralPath $dir)) {
            if (-not $Quiet) { Write-Log "$origin : $(Get-Text 'FileBack')" 'ERROR' | Out-Null }
            return $false
        }
        Move-Item -LiteralPath $stash -Destination $origin -Force -ErrorAction Stop
        if (-not (Test-Path -LiteralPath $origin)) {
            if (-not $Quiet) { Write-Log "$origin : $(Get-Text 'SvcVerifyErr')" 'ERROR' | Out-Null }
            return $false
        }
        $Entry.Undone = $true
        if (-not $Quiet) { Write-Log "$(Get-Text 'StuRestored'): $(Split-Path -Leaf $origin)" 'SUCCESS' | Out-Null }
        return $true
    }
    catch {
        if (-not $Quiet) { Write-Log "$origin : $($_.Exception.Message)" 'ERROR' | Out-Null }
        return $false
    }
}

function Move-ToStash {
    # Loeschen ohne Rueckweg hatte in diesem Programm nichts verloren: die
    # Verknuepfung wandert in die Sicherung und ins Journal, damit
    # 'Rueckgaengig' sie zurueckholen kann.
    param([string]$Path, [string]$Label = '')
    try {
        $stashDir = Join-Path $script:Config.BackupDir 'Entfernt'
        if (-not (Test-Path -LiteralPath $stashDir)) {
            [void](New-Item -Path $stashDir -ItemType Directory -Force -ErrorAction Stop)
        }
        $leaf = Split-Path -Leaf $Path
        $dest = Join-Path $stashDir ((Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + $leaf)
        $n = 1
        while (Test-Path -LiteralPath $dest) {
            $dest = Join-Path $stashDir ((Get-Date -Format 'yyyyMMdd_HHmmss') + "_$n" + '_' + $leaf)
            $n++
        }
        Move-Item -LiteralPath $Path -Destination $dest -Force -ErrorAction Stop
        [void](Add-ChangeEntry -Action 'file' -Path $Path -Name $leaf -Type 'File' `
                -OldValue $Path -NewValue $dest -Existed $true -Label $Label)
        return $true
    }
    catch {
        Write-Log "$Path : $($_.Exception.Message)" 'ERROR'
        return $false
    }
}

function Get-ChangeRows {
    # Reines Modell der Journal-Ansicht: aus den Eintraegen werden Zeilen,
    # ohne dass dabei ein Steuerelement im Spiel ist. So laesst sich die
    # Darstellung pruefen, ohne das Fenster zu bauen.
    param($Entries, [switch]$OldestFirst)
    $all = @($Entries)
    $rows = New-Object System.Collections.ArrayList
    $idx = if ($OldestFirst) { 0..([Math]::Max(0, $all.Count - 1)) } else { ([Math]::Max(0, $all.Count - 1))..0 }
    if ($all.Count -eq 0) { return @() }
    foreach ($i in $idx) {
        $e = $all[$i]
        if (-not $e) { continue }
        $undone = [bool]$e.Undone
        [void]$rows.Add([pscustomobject]@{
                Time   = [string]$e.Time
                Label  = [string]$e.Label
                Target = (Get-ChangeTargetText -Entry $e)
                Old    = $(if ($e.Existed) { "$($e.OldValue)" } else { '-' })
                New    = $(if ([string]$e.Action -eq 'remove') { Get-Text 'Delete' } else { "$($e.NewValue)" })
                State  = $(if ($undone) { Get-Text 'ChangeUndone' } else { '' })
                Undone = $undone
                Entry  = $e
            })
    }
    return @($rows.ToArray())
}

function Get-UndoableEntries {
    # Schon zurueckgenommene Eintraege und leere Zeilen fliegen raus. Ohne
    # diese Vorauswahl meldete die Bilanz "0 von 3", obwohl zwei davon gar
    # nichts mehr zu tun hatten.
    param($Entries)
    $out = New-Object System.Collections.ArrayList
    foreach ($e in @($Entries)) {
        if (-not $e) { continue }
        if ($e.Undone) { continue }
        [void]$out.Add($e)
    }
    return @($out.ToArray())
}

function Invoke-ChangeUndoBatch {
    # Eine Stelle fuer "Rueckgaengig" und "Alle rueckgaengig". Ein einzelner
    # Eintrag kann einen Dienst umstellen oder eine Defender-Ausnahme
    # zuruecknehmen - beides laeuft im Hintergrund und braucht deshalb
    # zwingend eine Warteflaeche, sonst wird gar nichts durchgereicht.
    param($Entries, [string]$Label = '')
    $list = @(Get-UndoableEntries -Entries $Entries)
    if ($list.Count -eq 0) {
        Write-Log (Get-Text 'ChangeNoUndo') 'INFO'
        return @{ Ok = 0; Total = 0; Failed = @(); Cancelled = $false }
    }
    $done = 0
    $failed = @()
    $cancelled = $false
    $i = 0
    Show-BusyOverlay -Title $Label -Cancellable
    try {
        foreach ($e in $list) {
            if (Test-BusyCancelled) { $cancelled = $true; break }
            $i++
            Update-BusyOverlay -Status "$(Get-ChangeTargetText -Entry $e)   ($i / $($list.Count))" `
                -Percent ([int](($i - 1) / [double]$list.Count * 100))
            if (Undo-ChangeEntry -Entry $e -Quiet) { $done++ }
            else { $failed += "$($e.Name)" }
        }
    }
    finally { Hide-BusyOverlay }
    Save-ChangeLog
    if ($cancelled) {
        Write-Log "$Label : $done / $($list.Count) - $(Get-Text 'BusyCancelled')" 'WARNING'
    }
    else {
        Write-TweakOutcome -Label $Label -Ok $done -Total $i -Failed $failed
    }
    return @{ Ok = $done; Total = $i; Failed = $failed; Cancelled = $cancelled }
}

function Undo-AllChanges {
    # Neueste zuerst, damit ein zweimal angefasster Wert am Ende wieder auf
    # seinem Ursprung steht.
    if (-not (Show-Confirm -Message (Get-Text 'DlgConfirm'))) { return }
    $open = @(Get-UndoableEntries -Entries @($script:ChangeLog))
    if ($open.Count -eq 0) {
        Write-Log (Get-Text 'ChangeNone') 'INFO'
        return
    }
    [System.Array]::Reverse($open)
    [void](Invoke-ChangeUndoBatch -Entries $open -Label (Get-Text 'ChangeUndoAll'))
    Update-ChangeList
}
#endregion 4b. CHANGE JOURNAL

function Get-WmicReplacement {
    # wmic.exe ist seit dem Windows-11-Update vom August/September 2026
    # (26H2 und die zurueckportierten 24H2/25H2-Builds) vollstaendig entfernt
    # und auch nicht mehr als Feature on Demand nachinstallierbar. WMI selbst
    # bleibt unveraendert - nur das Kommandozeilen-Werkzeug ist weg.
    param([string]$Command)
    $map = [ordered]@{
        'bios'           = 'Get-CimInstance Win32_BIOS'
        'cpu'            = 'Get-CimInstance Win32_Processor'
        'os'             = 'Get-CimInstance Win32_OperatingSystem'
        'process'        = 'Get-CimInstance Win32_Process'
        'service'        = 'Get-CimInstance Win32_Service'
        'logicaldisk'    = 'Get-CimInstance Win32_LogicalDisk'
        'diskdrive'      = 'Get-CimInstance Win32_DiskDrive'
        'computersystem' = 'Get-CimInstance Win32_ComputerSystem'
        'memorychip'     = 'Get-CimInstance Win32_PhysicalMemory'
        'baseboard'      = 'Get-CimInstance Win32_BaseBoard'
        'qfe'            = 'Get-HotFix'
        'product'        = "Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'"
        'useraccount'    = 'Get-CimInstance Win32_UserAccount'
        'startup'        = 'Get-CimInstance Win32_StartupCommand'
        'nic'            = 'Get-CimInstance Win32_NetworkAdapter'
    }
    $rest = ($Command -replace '(?i)^\s*wmic(\.exe)?\s*', '').Trim()
    foreach ($k in $map.Keys) {
        if ($rest -match "(?i)^$k\b") { return "powershell -c `"$($map[$k])`"" }
    }
    return 'powershell -c "Get-CimInstance <Win32_Klasse>"'
}

$script:CmdBuiltins = @(
    'arp', 'assoc', 'attrib', 'bcdedit', 'cd', 'chkdsk', 'cleanmgr', 'cls', 'copy',
    'defrag', 'del', 'dir', 'dism', 'driverquery', 'echo', 'find', 'findstr',
    'fsutil', 'getmac', 'gpresult', 'gpupdate', 'hostname', 'icacls', 'ipconfig',
    'md', 'mklink', 'mode', 'more', 'msinfo32', 'nbtstat', 'net', 'netsh',
    'netstat', 'nslookup', 'openfiles', 'path', 'pathping', 'ping', 'powercfg',
    'powershell', 'query', 'reg', 'robocopy', 'route', 'sc', 'schtasks', 'set',
    'sfc', 'shutdown', 'systeminfo', 'takeown', 'taskkill', 'tasklist', 'timeout',
    'tracert', 'tree', 'type', 'tzutil', 'ver', 'vol', 'wevtutil', 'where',
    'whoami', 'winget', 'xcopy'
)

function Get-CommandToken {
    # Zerlegt die Eingabe an der Schreibmarke in das Wort, das gerade
    # vervollstaendigt werden soll. Anfuehrungszeichen halten zusammen, was
    # zusammengehoert - 'C:\Program Files\' ist ein Wort, nicht zwei.
    param([string]$Text, [int]$Caret = -1)
    $t = [string]$Text
    if ($Caret -lt 0 -or $Caret -gt $t.Length) { $Caret = $t.Length }
    $head = $t.Substring(0, $Caret)

    # Rueckwaerts bis zum Trenner, dabei Anfuehrungszeichen beachten
    $start = $Caret
    $inQuote = (([regex]::Matches($head, '"')).Count % 2) -eq 1
    if ($inQuote) {
        $start = $head.LastIndexOf('"')
        if ($start -lt 0) { $start = 0 }
    }
    else {
        while ($start -gt 0 -and $head[$start - 1] -notin @(' ', "`t", '&', '|', '<', '>')) { $start-- }
    }
    $value = $head.Substring($start)
    $before = $head.Substring(0, $start).Trim()
    return @{
        Start   = $start
        Length  = $Caret - $start
        Value   = $value
        Quoted  = $inQuote
        # Erstes Wort der Zeile oder direkt hinter & bzw. | - dort steht ein
        # Befehlsname, sonst ein Pfad.
        IsFirst = ($before -eq '' -or $before -match '[&|]$')
    }
}

function Select-CompletionMatches {
    # Reine Auswahl: welche Kandidaten passen zum angefangenen Wort?
    param([string]$Prefix, [string[]]$Candidates)
    $pre = [string]$Prefix
    $pre = $pre.Trim('"')
    $out = @($Candidates | Where-Object { $_ -and ([string]$_).StartsWith($pre, [System.StringComparison]::OrdinalIgnoreCase) })
    return @($out | Sort-Object -Unique)
}

function Format-CompletionValue {
    # Enthaelt der Treffer ein Leerzeichen, muss er in Anfuehrungszeichen -
    # sonst bricht cmd.exe den Pfad am Leerzeichen auf.
    param([string]$Value)
    $v = [string]$Value
    if ($v -match '\s') { return '"' + $v.Trim('"') + '"' }
    return $v
}

function Build-CompletedText {
    # Reine Ersetzung: Wort an Start/Laenge gegen den Treffer tauschen und
    # sagen, wohin die Schreibmarke danach gehoert.
    param([string]$Text, [int]$Start, [int]$Length, [string]$Value)
    $t = [string]$Text
    if ($Start -lt 0) { $Start = 0 }
    if ($Start -gt $t.Length) { $Start = $t.Length }
    if ($Length -lt 0) { $Length = 0 }
    if (($Start + $Length) -gt $t.Length) { $Length = $t.Length - $Start }
    $ins = Format-CompletionValue -Value $Value
    $new = $t.Substring(0, $Start) + $ins + $t.Substring($Start + $Length)
    return @{ Text = $new; Caret = $Start + $ins.Length }
}

function Get-PathCandidates {
    # Dateien und Ordner zum angefangenen Pfad. Ordner bekommen einen
    # Backslash, damit sich direkt weitertippen laesst.
    param([string]$Prefix)
    $pre = ([string]$Prefix).Trim('"')
    try {
        $dir = Split-Path -Parent $pre
        $leaf = Split-Path -Leaf $pre
        if ([string]::IsNullOrEmpty($dir)) { $dir = '.' ; $leaf = $pre }
        if (-not (Test-Path -LiteralPath $dir)) { return @() }
        $items = @(Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name.StartsWith($leaf, [System.StringComparison]::OrdinalIgnoreCase) })
        $base = if ($dir -eq '.') { '' } else { $dir.TrimEnd('\') + '\' }
        return @($items | ForEach-Object { $base + $_.Name + $(if ($_.PSIsContainer) { '\' } else { '' }) })
    }
    catch { return @() }
}

function Invoke-CommandCompletion {
    # Tab in der Befehlszeile. Mehrfaches Tab blaettert durch die Treffer.
    if (-not $script:txtCmd -or $script:txtCmd.IsDisposed) { return }
    $text = [string]$script:txtCmd.Text
    $caret = [int]$script:txtCmd.SelectionStart
    $tok = Get-CommandToken -Text $text -Caret $caret

    $sameRun = ($script:CmdComplete -and
        [string]$script:CmdComplete.Text -eq $text -and
        [int]$script:CmdComplete.Caret -eq $caret)

    if ($sameRun) {
        $script:CmdComplete.Index = ($script:CmdComplete.Index + 1) % @($script:CmdComplete.Items).Count
    }
    else {
        $cand = @()
        if ($tok.IsFirst -and $tok.Value -notmatch '[\\/:]') { $cand += $script:CmdBuiltins }
        $cand += (Get-PathCandidates -Prefix $tok.Value)
        $hits = Select-CompletionMatches -Prefix $tok.Value -Candidates $cand
        if (@($hits).Count -eq 0) { $script:CmdComplete = $null; return }
        $script:CmdComplete = @{ Items = $hits; Index = 0; Start = $tok.Start; Length = $tok.Length }
    }

    $c = $script:CmdComplete
    $res = Build-CompletedText -Text $text -Start $c.Start -Length $c.Length -Value $c.Items[$c.Index]
    $script:txtCmd.Text = $res.Text
    $script:txtCmd.SelectionStart = $res.Caret
    $script:txtCmd.SelectionLength = 0
    # Zustand fuer das naechste Tab festhalten: nur wenn Text und Marke
    # unveraendert sind, wird weitergeblaettert statt neu gesucht.
    $c.Text = $res.Text
    $c.Caret = $res.Caret
    $c.Length = ($res.Caret - $c.Start)
    if (@($c.Items).Count -gt 1) {
        Write-Log ("$($c.Index + 1)/$(@($c.Items).Count)  " + (@($c.Items) -join '   ')) 'INFO'
    }
}

function Test-CommandRedirect {
    # Hat der Benutzer selbst umgeleitet? Dann landet die Ausgabe in seiner
    # Datei und nicht bei uns - das muss das Protokoll sagen, statt eine
    # leere Ausgabe als 'nichts passiert' hinzustellen.
    param([string]$Command)
    $c = [string]$Command
    if (-not $c) { return $false }
    # Was in Anfuehrungszeichen steht, zaehlt nicht
    $bare = [regex]::Replace($c, '"[^"]*"', '')
    return ($bare -match '(?<![0-9])>{1,2}')
}

function Get-OemEncoding {
    # cmd.exe schreibt in der OEM-Codepage (in Deutschland 850), nicht in
    # UTF-8. Ohne diese Zeile wurde aus 'Volumeinformationen fuer Laufwerk'
    # ein Haufen Fragezeichen und aus Umlauten Kaestchen.
    try {
        return [System.Text.Encoding]::GetEncoding([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage)
    }
    catch {
        try { return [System.Text.Encoding]::GetEncoding(850) } catch { return [System.Text.Encoding]::Default }
    }
}

function Submit-ConsoleCommand {
    if (-not $script:txtCmd -or $script:txtCmd.IsDisposed) { return }
    $cmd = $script:txtCmd.Text.Trim()
    if (-not $cmd) { return }
    if (-not $script:CmdHistory) { $script:CmdHistory = New-Object System.Collections.Generic.List[string] }
    if ($script:CmdHistory.Count -eq 0 -or $script:CmdHistory[$script:CmdHistory.Count - 1] -ne $cmd) {
        $script:CmdHistory.Add($cmd)
        while ($script:CmdHistory.Count -gt 50) { $script:CmdHistory.RemoveAt(0) }
    }
    $script:CmdHistoryPos = -1
    $script:txtCmd.Clear()

    # 'wmic' gibt es ab Windows 11 26H2 nicht mehr - die cmd.exe wuerde nur
    # 'Befehl nicht gefunden' melden. Stattdessen gleich den Ersatz nennen.
    if ($cmd -match '(?i)^\s*wmic(\.exe)?\b') {
        $rel = $null
        try { $rel = Get-WindowsRelease } catch { }
        if (-not $rel -or -not $rel.HasWmic) {
            Write-Log (Get-Text 'WmicGone') 'WARNING'
            Write-Log "$(Get-Text 'WmicHint'): $(Get-WmicReplacement -Command $cmd)" 'INFO'
            return
        }
    }

    Invoke-ConsoleCommand -Command $cmd
}

function Invoke-ConsoleCommand {
    # Freie Befehlszeile unter dem Protokoll. Die Ausgabe wird in eine
    # temporaere Datei umgeleitet und danach zeilenweise ins Protokoll
    # geschrieben - so bleibt die Oberflaeche bedienbar und die Ausgabe
    # landet auch in der Protokolldatei.
    param([string]$Command)

    $cmd = [string]$Command
    if ([string]::IsNullOrWhiteSpace($cmd)) { return }
    if ($script:BusyDepth -gt 0) { Write-Log (Get-Text 'CmdBusy') 'WARNING'; return }

    Write-Log "cmd > $cmd" 'TITLE'
    $out = Join-Path $env:TEMP ("eb_cmd_{0}.txt" -f ([guid]::NewGuid().ToString('N')))
    Show-BusyOverlay -Title (Get-Text 'CmdRunning') -Status $cmd
    try {
        $ownRedirect = Test-CommandRedirect -Command $cmd
        if ($ownRedirect) { Write-Log (Get-Text 'CmdRedirect') 'WARNING' }

        $arg = '/c ' + $cmd + ' > "' + $out + '" 2>&1'
        $code = Invoke-SystemCommand -File 'cmd.exe' -Arguments $arg -TimeoutSec 120 -Label 'cmd'
        $shown = 0
        if (Test-Path -LiteralPath $out) {
            # Mit der OEM-Codepage lesen statt mit der Vorgabe von
            # Get-Content: sonst wird aus jedem Umlaut ein Kaestchen und aus
            # den Rahmenzeichen von tree oder netstat Buchstabensalat.
            $lines = @()
            try { $lines = @([System.IO.File]::ReadAllLines($out, (Get-OemEncoding))) }
            catch { $lines = @(Get-Content -LiteralPath $out -ErrorAction SilentlyContinue) }

            # 200 Zeilen einzeln anzuhaengen hiess 200-mal neu zeichnen und
            # 200-mal zum Ende scrollen - die Oberflaeche stand dabei.
            Suspend-Redraw -Control $script:txtLog
            try {
                foreach ($line in $lines) {
                    if ([string]::IsNullOrWhiteSpace($line)) { continue }
                    if ($shown -ge 200) {
                        Write-Log ('... +' + ($lines.Count - $shown)) 'INFO'
                        break
                    }
                    Write-Log $line 'INFO'
                    $shown++
                }
            }
            finally { Resume-Redraw -Control $script:txtLog }
        }
        if ($shown -eq 0 -and -not $ownRedirect) { Write-Log (Get-Text 'CmdNoOut') 'INFO' }
        if ($null -eq $code) { Write-Log (Get-Text 'CmdDone') 'WARNING' }
        elseif ([int]$code -eq 0) { Write-Log (Get-Text 'CmdDone') 'SUCCESS' }
        else { Write-Log "$(Get-Text 'CmdDone') - $(Get-Text 'LogExitCode') $code" 'WARNING' }
    }
    catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    finally {
        Hide-BusyOverlay
        try { if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue } } catch { }
    }
}

function Stop-ProcessTree {
    # $p.Kill() beendet nur den direkt gestarteten Prozess. Bei
    # "cmd.exe /c chkdsk ..." oder DISM laeuft die eigentliche Arbeit in einem
    # Kindprozess weiter - der Abbruch waere also nur scheinbar. taskkill /T
    # nimmt den ganzen Baum mit; schlaegt das fehl, bleibt Kill() als Notnagel.
    param($Process)
    if (-not $Process) { return }
    $id = 0
    try { $id = [int]$Process.Id } catch { $id = 0 }
    if ($id -gt 0) {
        try {
            $tk = Start-Process -FilePath 'taskkill.exe' -ArgumentList @('/PID', "$id", '/T', '/F') `
                -WindowStyle Hidden -PassThru -ErrorAction Stop
            [void]$tk.WaitForExit(4000)
            try { $tk.Dispose() } catch { }
        }
        catch { }
    }
    try { if (-not $Process.HasExited) { $Process.Kill() } } catch { }
}

function Invoke-SystemCommand {
    # Start-Process -Wait blocks the WinForms message loop: while netsh,
    # bcdedit or reg.exe were running the window stopped repainting and
    # Windows marked it as "not responding". This starts the process, waits
    # in small slices and pumps the message queue while a busy overlay is up
    # (the overlay swallows clicks, so pumping cannot start a second action).
    # The timeout makes sure a hanging command can never freeze the app.
    param(
        [Parameter(Mandatory)][string]$File,
        $Arguments = $null,
        [int]$TimeoutSec = 90,
        [string]$Label
    )

    $p = $null
    try {
        if ($null -ne $Arguments -and @($Arguments).Count -gt 0) {
            $p = Start-Process -FilePath $File -ArgumentList $Arguments -WindowStyle Hidden -PassThru -ErrorAction Stop
        }
        else {
            $p = Start-Process -FilePath $File -WindowStyle Hidden -PassThru -ErrorAction Stop
        }
    }
    catch {
        if ($Label) { Write-Log "$Label : $($_.Exception.Message)" 'WARNING' | Out-Null }
        return $null
    }
    if (-not $p) { return $null }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $limit = [double]$TimeoutSec * 1000.0
    while (-not $p.HasExited) {
        [void]$p.WaitForExit(50)
        if ($script:BusyDepth -gt 0) { [System.Windows.Forms.Application]::DoEvents() }
        # Abbruch durch den Nutzer: Der Knopf ist nur sichtbar, wenn die
        # aufrufende Aktion ihn angefordert hat - sonst ist das Flag nie gesetzt.
        if (Test-BusyCancelled) {
            Stop-ProcessTree -Process $p
            if ($Label) { Write-Log "$Label : $(Get-Text 'BusyCancelled')" 'WARNING' | Out-Null }
            $sw.Stop()
            try { $p.Dispose() } catch { }
            return $null
        }
        if ($sw.Elapsed.TotalMilliseconds -gt $limit) {
            Stop-ProcessTree -Process $p
            if ($Label) { Write-Log "$Label : $(Get-Text 'LogTimeout') $TimeoutSec s" 'WARNING' | Out-Null }
            $sw.Stop()
            try { $p.Dispose() } catch { }
            return $null
        }
    }
    $sw.Stop()

    $code = $null
    try { $p.Refresh(); $code = $p.ExitCode } catch { }
    try { $p.Dispose() } catch { }
    return $code
}

function Wait-AppDelay {
    # Start-Sleep freezes the window - this waits and keeps it painting
    param([int]$Ms = 500)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalMilliseconds -lt $Ms) {
        Start-Sleep -Milliseconds 25
        [System.Windows.Forms.Application]::DoEvents()
    }
    $sw.Stop()
}

function Get-HeldBackupPaths {
    # Dateien, die eine noch offene Journalzeile braucht. Eine verschobene
    # Autostart-Verknuepfung wegzuraeumen wuerde 'Rueckgaengig' ins Leere
    # laufen lassen - derselbe Gedanke wie in Select-ChangeLogKeep.
    $out = @{}
    try {
        foreach ($e in @($script:ChangeLog)) {
            if (-not $e -or $e.Undone) { continue }
            if ([string]$e.Action -ne 'file') { continue }
            $v = [string]$e.NewValue
            if ($v) { $out[$v.ToLowerInvariant()] = $true }
        }
    }
    catch { }
    return $out
}

function Select-BackupKeep {
    # Reine Entscheidung, welche Sicherungsdateien bleiben. Reihenfolge der
    # Regeln ist Absicht: Gehaltene und die juengsten MinKeep sind
    # unantastbar, erst danach greifen Alter und Gesamtgroesse.
    param(
        $Files,
        $Held = @{},
        [int]$MaxAgeDays = 60,
        [int]$MinKeep = 10,
        [double]$MaxTotalBytes = 536870912,
        [datetime]$Now = (Get-Date)
    )
    $keep = New-Object System.Collections.Generic.List[object]
    $drop = New-Object System.Collections.Generic.List[object]
    $all = @($Files | Where-Object { $_ } | Sort-Object -Property LastWriteTime -Descending)
    $used = 0.0
    $i = 0
    foreach ($f in $all) {
        $i++
        $path = [string]$f.FullName
        $isHeld = $false
        if ($Held -and $path) { $isHeld = [bool]$Held[$path.ToLowerInvariant()] }
        $size = [double]$f.Length

        if ($isHeld -or $i -le $MinKeep) {
            $keep.Add($f); $used += $size; continue
        }
        if (([double]($Now - $f.LastWriteTime).TotalDays) -gt $MaxAgeDays) { $drop.Add($f); continue }
        if (($used + $size) -gt $MaxTotalBytes) { $drop.Add($f); continue }
        $keep.Add($f); $used += $size
    }
    return @{
        Keep      = $keep.ToArray()
        Drop      = $drop.ToArray()
        KeptBytes = $used
        # Klammern: [double](...).Sum wuerde das Measure-Objekt umwandeln
        # und nicht dessen Summe - das wirft 'Argument types do not match'.
        DropBytes = [double](@($drop | Measure-Object -Property Length -Sum).Sum)
    }
}

function Invoke-BackupCleanup {
    param([switch]$Quiet)
    try {
        $dir = $script:Config.BackupDir
        if (-not $dir -or -not (Test-Path -LiteralPath $dir)) { return 0 }
        $files = @(Get-ChildItem -LiteralPath $dir -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -in @('.reg', '.json', '.txt', '.html', '.lnk') })
        if ($files.Count -eq 0) { return 0 }

        $held = Get-HeldBackupPaths
        $plan = Select-BackupKeep -Files $files -Held $held `
            -MaxAgeDays ([int]$script:Config.BackupKeepDays) `
            -MinKeep ([int]$script:Config.BackupMinKeep) `
            -MaxTotalBytes ([double]$script:Config.BackupMaxMB * 1MB)

        if (@($plan.Drop).Count -eq 0) {
            if (-not $Quiet) { Write-Log (Get-Text 'BakCleanNone') 'INFO' }
            return 0
        }
        $freed = 0.0
        foreach ($f in $plan.Drop) {
            try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop; $freed += [double]$f.Length }
            catch { }
        }
        $msg = "$(Get-Text 'BakClean'): $(@($plan.Drop).Count) $(Get-Text 'BakDropped')" +
        " / $(@($plan.Keep).Count) $(Get-Text 'BakKept')  -  $(Get-FormattedBytes $freed)"
        Write-Log $msg $(if ($Quiet) { 'INFO' } else { 'SUCCESS' })
        if ($held.Count -gt 0 -and -not $Quiet) {
            Write-Log "$($held.Count) $(Get-Text 'BakHeld')" 'INFO'
        }
        Clear-DataCache -Key 'BackupFiles'
        return $freed
    }
    catch {
        if (-not $Quiet) { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'WARNING' }
        return 0
    }
}

function Get-RegistryBackupScopes {
    # Genau die Aeste, in die dieses Programm ueberhaupt schreibt - in der
    # Schreibweise von reg.exe. Frueher sicherte 'Registry' nur HKCU; die
    # Datenschutz- und Leistungs-Tweaks liegen aber fast alle unter HKLM.
    # Die Sicherung versprach also einen Schutz, den sie nicht gab.
    return @(
        'HKCU\Control Panel'
        'HKCU\Software\Microsoft\Windows\CurrentVersion'
        'HKCU\Software\Microsoft\GameBar'
        'HKCU\Software\Microsoft\Siuf'
        'HKCU\Software\Policies'
        'HKCU\System\GameConfigStore'
        'HKLM\SOFTWARE\Policies\Microsoft'
        'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies'
        'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager'
        'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
        'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia'
        'HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi'
        'HKLM\SYSTEM\CurrentControlSet\Control\Power'
        'HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
        'HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl'
        'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power'
    )
}

function Get-RegContentStats {
    # Reine Pruefung des Inhalts einer .reg-Datei.
    param([string]$Text)
    $res = @{ Ok = $false; Keys = 0; HasHeader = $false }
    if ([string]::IsNullOrWhiteSpace($Text)) { return $res }
    $res.HasHeader = ($Text -match '(?im)^\s*Windows Registry Editor Version 5\.00\s*$')
    $res.Keys = ([regex]::Matches($Text, '(?m)^\[-?HK[A-Z_]+\\')).Count
    $res.Ok = ($res.HasHeader -and $res.Keys -gt 0)
    return $res
}

function Test-RegFileValid {
    param([string]$Path)
    try {
        if (-not (Test-Path -LiteralPath $Path)) { return @{ Ok = $false; Keys = 0; HasHeader = $false } }
        # reg.exe schreibt UTF-16LE mit Signatur; ReadAllText erkennt sie.
        return Get-RegContentStats -Text ([System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::Unicode))
    }
    catch { return @{ Ok = $false; Keys = 0; HasHeader = $false } }
}

function Merge-RegExports {
    # Mehrere Einzelexporte zu einer Datei zusammenfassen: Kopfzeile einmal,
    # danach nur noch die Schluesselbloecke.
    param([string[]]$Files, [string]$Destination)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('Windows Registry Editor Version 5.00')
    [void]$sb.AppendLine()
    $keys = 0
    foreach ($f in @($Files)) {
        try {
            if (-not (Test-Path -LiteralPath $f)) { continue }
            $txt = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::Unicode)
            $st = Get-RegContentStats -Text $txt
            if (-not $st.Ok) { continue }
            $keys += $st.Keys
            $body = $txt -replace '(?im)^\s*Windows Registry Editor Version 5\.00\s*\r?\n', ''
            [void]$sb.AppendLine($body.Trim())
            [void]$sb.AppendLine()
        }
        catch { }
    }
    if ($keys -le 0) { return 0 }
    [System.IO.File]::WriteAllText($Destination, $sb.ToString(), (New-Object System.Text.UnicodeEncoding($false, $true)))
    return $keys
}

function New-Backup {
    param(
        [ValidateSet('Registry', 'Services')]
        [string]$Type
    )

    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $base = Join-Path $script:Config.BackupDir ("{0}_{1}" -f $Type, $stamp)

    try {
        switch ($Type) {
            'Registry' {
                $file = "$base.reg"
                $scopes = @(Get-RegistryBackupScopes)
                $parts = New-Object System.Collections.Generic.List[string]
                $done = 0
                $tmpDir = Join-Path $env:TEMP ('EB_Bak_' + $stamp)
                [void](New-Item -Path $tmpDir -ItemType Directory -Force -ErrorAction SilentlyContinue)
                # 16 Aufrufe von reg.exe dauern spuerbar - ohne Anzeige haelt
                # der Benutzer das Fenster fuer eingefroren.
                Show-BusyOverlay -Title (Get-Text 'BackupsTitle')
                try {
                    $i = 0
                    foreach ($scope in $scopes) {
                        $i++
                        Update-BusyOverlay -Status "$(Get-Text 'BusyStep') $i / $($scopes.Count):  $scope" `
                            -Percent ([int]($i / [double]$scopes.Count * 100))
                        $part = Join-Path $tmpDir ("p{0:d2}.reg" -f $i)
                        $code = Invoke-SystemCommand -File 'reg.exe' `
                            -Arguments @('export', "`"$scope`"", "`"$part`"", '/y') -TimeoutSec 120 -Label 'reg.exe export'
                        # Ein nicht vorhandener Ast ist kein Fehler - manche
                        # Richtlinienschluessel gibt es auf dem Rechner gar nicht.
                        if ($code -eq 0 -and (Test-Path -LiteralPath $part)) {
                            $parts.Add($part); $done++
                        }
                    }
                    $keys = Merge-RegExports -Files $parts.ToArray() -Destination $file
                    if ($keys -le 0) {
                        Write-Log (Get-Text 'BakEmpty') 'ERROR'
                        return $null
                    }
                    Write-Log "$(Get-Text 'DlgBackupCreated'): $file" 'SUCCESS'
                    Write-Log "$(Get-Text 'BakScopes'): $done / $($scopes.Count)  -  $keys $(Get-Text 'BakKeys')" 'INFO'
                    # Eine Vollsicherung ist jetzt deutlich groesser als
                    # frueher - ohne Aufraeumen waechst der Ordner endlos.
                    [void](Invoke-BackupCleanup -Quiet)
                    return $file
                }
                finally {
                    Hide-BusyOverlay
                    try { Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue } catch { }
                }
            }
            'Services' {
                $file = "$base.json"
                # StartType gibt es auf ServiceController erst ab .NET 4.6.1 -
                # und ohne Starttyp waere die Sicherung wertlos, weil sich
                # daraus nichts zurueckstellen laesst. Also aus der
                # Registrierung lesen, wie ueberall sonst im Programm.
                Get-Service | ForEach-Object {
                    [pscustomobject]@{
                        Name        = $_.Name
                        DisplayName = $_.DisplayName
                        Status      = [string]$_.Status
                        StartType   = (Get-ServiceStartupType -Name $_.Name)
                    }
                } | ConvertTo-Json -Depth 3 | Out-File -LiteralPath $file -Encoding UTF8
                Write-Log "$(Get-Text 'DlgBackupCreated'): $file" 'SUCCESS'
                return $file
            }
        }
    }
    catch {
        Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR'
        return $null
    }
}

function Backup-RegistryKey {
    # Exports a single registry key before it is modified.
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Name = 'Key'
    )

    try {
        $native = $Path -replace '^HKLM:\\', 'HKLM\' -replace '^HKCU:\\', 'HKCU\' `
            -replace '^HKCR:\\', 'HKCR\' -replace '^HKU:\\', 'HKU\'
        if (-not (Test-Path -LiteralPath $Path)) { return $null }
        # Ohne Zielordner schreibt reg.exe nichts und meldet nur einen
        # Fehlercode - das sah bisher wie ein kaputter Schluessel aus.
        if (-not (Test-Path -LiteralPath $script:Config.BackupDir)) {
            [void](New-Item -Path $script:Config.BackupDir -ItemType Directory -Force -ErrorAction SilentlyContinue)
        }
        $file = Join-Path $script:Config.BackupDir ("{0}_{1}.reg" -f ($Name -replace '[^\w\-]', '_'), (Get-Date -Format 'yyyyMMdd_HHmmss'))
        $code = Invoke-SystemCommand -File 'reg.exe' -Arguments @('export', "`"$native`"", "`"$file`"", '/y') -TimeoutSec 60 -Label 'reg.exe export'
        if ($code -eq 0) {
            Write-Log "$(Get-Text 'DlgBackupCreated'): $file" 'SUCCESS'
            [void](Invoke-BackupCleanup -Quiet)
            return $file
        }
        return $null
    }
    catch {
        Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'WARNING'
        return $null
    }
}

function Get-RestorePointSequences {
    # Nur die laufenden Nummern - daran laesst sich hinterher zweifelsfrei
    # erkennen, ob tatsaechlich ein neuer Punkt dazugekommen ist.
    $out = @()
    try {
        $out = @(Get-ComputerRestorePoint -ErrorAction Stop |
            ForEach-Object { [int]$_.SequenceNumber })
    }
    catch { }
    return $out
}

function Test-SystemRestoreDisabled {
    try {
        $k = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore'
        $v = Get-ItemProperty -Path $k -Name 'DisableSR' -ErrorAction SilentlyContinue
        if ($v -and [int]$v.DisableSR -eq 1) { return $true }
    }
    catch { }
    return $false
}

function Test-NewRestorePoint {
    # Reiner Vergleich zweier Nummernlisten.
    param([int[]]$Before = @(), [int[]]$After = @())
    $a = @($After)
    if ($a.Count -eq 0) { return $false }
    $b = @($Before)
    if ($b.Count -eq 0) { return $true }
    $maxA = ($a | Measure-Object -Maximum).Maximum
    $maxB = ($b | Measure-Object -Maximum).Maximum
    if ([int]$maxA -gt [int]$maxB) { return $true }
    return ($a.Count -gt $b.Count)
}

function Set-RestoreFrequencyBypass {
    # Windows legt hoechstens alle 1440 Minuten einen Punkt an. Wird die
    # Sperre verletzt, tut Checkpoint-Computer einfach NICHTS und wirft dabei
    # keinen Fehler. Der Wert wird nur fuer den zweiten Versuch genullt und
    # danach exakt in den alten Zustand zurueckversetzt.
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    $prev = $null
    try {
        if (-not (Test-Path -LiteralPath $key)) { [void](New-Item -Path $key -Force -ErrorAction Stop) }
        $cur = Get-ItemProperty -Path $key -Name 'SystemRestorePointCreationFrequency' -ErrorAction SilentlyContinue
        if ($cur -and $null -ne $cur.SystemRestorePointCreationFrequency) {
            $prev = [int]$cur.SystemRestorePointCreationFrequency
        }
        Set-ItemProperty -Path $key -Name 'SystemRestorePointCreationFrequency' -Value 0 -Type DWord -ErrorAction Stop
        return @{ Ok = $true; Previous = $prev }
    }
    catch { return @{ Ok = $false; Previous = $prev } }
}

function Restore-RestoreFrequency {
    param($State)
    if (-not $State -or -not $State.Ok) { return }
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    try {
        if ($null -eq $State.Previous) {
            Remove-ItemProperty -Path $key -Name 'SystemRestorePointCreationFrequency' -ErrorAction SilentlyContinue
        }
        else {
            Set-ItemProperty -Path $key -Name 'SystemRestorePointCreationFrequency' -Value ([int]$State.Previous) -Type DWord -ErrorAction SilentlyContinue
        }
    }
    catch { }
}

function Invoke-Background {
    # Fuehrt einen langen Befehl in einem eigenen Runspace aus und bedient
    # waehrenddessen die Nachrichtenschleife. Ein einzelner blockierender
    # Aufruf wie Checkpoint-Computer laesst sich NICHT von innen heraus
    # unterbrechen: solange er laeuft, kehrt der Oberflaechenstrang nicht
    # zurueck, das Fenster zeichnet nicht mehr und Windows meldet "Die
    # Anwendung reagiert nicht" - obwohl alles seine Ordnung hat.
    #
    # Der Befehl wird als TEXT uebergeben: ein Skriptblock bliebe an den
    # alten Runspace gebunden und liefe doch wieder im Oberflaechenstrang.
    # Zurueck kommen nur einfache Werte, niemals CIM- oder Dienstobjekte -
    # die waeren nach dem Schliessen des Runspace tot.
    param(
        [Parameter(Mandatory)][string]$Script,
        [int]$TimeoutSec = 300,
        [string]$Status = ''
    )
    $res = @{ Completed = $false; TimedOut = $false; Cancelled = $false; Output = @(); Error = '' }
    $rs = $null
    $ps = $null
    try {
        $rs = [runspacefactory]::CreateRunspace()
        $rs.ApartmentState = 'MTA'
        $rs.ThreadOptions = 'ReuseThread'
        $rs.Open()
        $ps = [powershell]::Create()
        $ps.Runspace = $rs
        [void]$ps.AddScript($Script)
        $handle = $ps.BeginInvoke()
    }
    catch {
        # Kein Runspace moeglich: lieber blockierend ausfuehren als gar nicht.
        try {
            $res.Output = @(Invoke-Expression $Script)
            $res.Completed = $true
        }
        catch { $res.Error = $_.Exception.Message }
        finally {
            if ($ps) { try { $ps.Dispose() } catch { } }
            if ($rs) { try { $rs.Dispose() } catch { } }
        }
        return $res
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    if ($Status) { Update-BusyOverlay -Status $Status -KeepPercent }
    try {
        while (-not $handle.IsCompleted) {
            [void]$handle.AsyncWaitHandle.WaitOne(60)
            # Nur bei sichtbarer Wartefläche pumpen: sie schluckt Klicks,
            # sonst koennte der Nutzer mitten im Lauf eine zweite Aktion
            # starten.
            if ($script:BusyDepth -gt 0) { [System.Windows.Forms.Application]::DoEvents() }
            if (Test-BusyCancelled) {
                $res.Cancelled = $true
                try { $ps.Stop() } catch { }
                break
            }
            if ($sw.Elapsed.TotalSeconds -ge $TimeoutSec) {
                $res.TimedOut = $true
                try { $ps.Stop() } catch { }
                break
            }
        }
        if (-not $res.Cancelled -and -not $res.TimedOut) {
            try { $res.Output = @($ps.EndInvoke($handle)) } catch { $res.Error = $_.Exception.Message }
            $res.Completed = ($res.Error -eq '')
        }
        if ($ps.Streams -and $ps.Streams.Error -and $ps.Streams.Error.Count -gt 0 -and -not $res.Error) {
            $res.Error = [string]$ps.Streams.Error[0]
            $res.Completed = $false
        }
    }
    finally {
        $sw.Stop()
        try { $ps.Dispose() } catch { }
        try { $rs.Close(); $rs.Dispose() } catch { }
    }
    return $res
}

function Get-BackgroundOutcome {
    # Reine Auswertung: was ist passiert und wie ist es zu melden?
    param($Result)
    if (-not $Result) { return @{ Ok = $false; Level = 'ERROR'; ReasonKey = 'Error' } }
    if ($Result.Cancelled) { return @{ Ok = $false; Level = 'WARNING'; ReasonKey = 'BusyCancelled' } }
    if ($Result.TimedOut) { return @{ Ok = $false; Level = 'ERROR'; ReasonKey = 'BusyTooLong' } }
    if ($Result.Error) { return @{ Ok = $false; Level = 'ERROR'; ReasonKey = '' } }
    if ($Result.Completed) { return @{ Ok = $true; Level = 'SUCCESS'; ReasonKey = '' } }
    return @{ Ok = $false; Level = 'ERROR'; ReasonKey = 'Error' }
}

function New-RestorePoint {
    Write-Log "$(Get-Text 'RPCreating')" 'SYSTEM'
    if (Test-SystemRestoreDisabled) {
        Write-Log "$(Get-Text 'RPError'): $(Get-Text 'RPDisabled')" 'ERROR'
        return $false
    }
    Show-BusyOverlay -Title (Get-Text 'RestorePoint') -Status (Get-Text 'RPCreating')
    $desc = "EB_Optimizer_$(Get-Date -Format 'yyyyMMdd_HHmm')"
    $before = @(Get-RestorePointSequences)
    # Checkpoint-Computer braucht je nach Rechner eine halbe bis mehrere
    # Minuten und laesst sich waehrenddessen nicht unterbrechen. Im
    # Oberflaechenstrang hiess das: Fenster weiss, keine Reaktion, und
    # Windows bot an, das Programm zu beenden.
    $drive = "$env:SystemDrive\"
    $cmd = "try { Enable-ComputerRestore -Drive '$drive' -ErrorAction SilentlyContinue } catch { }; " +
    "Checkpoint-Computer -Description '$desc' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop"
    $bg = Invoke-Background -Script $cmd -TimeoutSec 240 -Status (Get-Text 'RPCreating')
    $vd = Get-BackgroundOutcome -Result $bg
    if (-not $vd.Ok -and -not $bg.Cancelled) {
        $why = if ($vd.ReasonKey) { Get-Text $vd.ReasonKey } else { [string]$bg.Error }
        Write-Log "$(Get-Text 'RPError'): $why" 'ERROR'
        Hide-BusyOverlay
        return $false
    }
    if ($bg.Cancelled) {
        Write-Log (Get-Text 'BusyCancelled') 'WARNING'
        Hide-BusyOverlay
        return $false
    }

    # Erfolgsmeldung erst nach Gegenprobe - Checkpoint-Computer schweigt,
    # wenn die 24-Stunden-Sperre greift.
    if (Test-NewRestorePoint -Before $before -After (Get-RestorePointSequences)) {
        Write-Log "$(Get-Text 'RestorePoint'): $desc - $(Get-Text 'RPVerified')" 'SUCCESS'
        Hide-BusyOverlay
        return $true
    }

    Write-Log "$(Get-Text 'RPRetry')" 'WARNING'
    Update-BusyOverlay -Status (Get-Text 'RPRetry') -Percent -1
    $state = Set-RestoreFrequencyBypass
    try {
        [void](Invoke-Background -Script "Checkpoint-Computer -Description '$desc' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop" -TimeoutSec 240 -Status (Get-Text 'RPRetry'))
        if (Test-NewRestorePoint -Before $before -After (Get-RestorePointSequences)) {
            Write-Log "$(Get-Text 'RestorePoint'): $desc - $(Get-Text 'RPVerified')" 'SUCCESS'
            return $true
        }
        Write-Log "$(Get-Text 'RPError'): $(Get-Text 'RPNotCreated')" 'WARNING'
        return $false
    }
    finally {
        Restore-RestoreFrequency -State $state
        Hide-BusyOverlay
    }
}

# --- System operations --------------------------------------------------------
function Optimize-Memory {
    Write-Log "$(Get-Text 'QuickRAM')..." 'PURPLE'
    try {
        if (-not ('MemoryOptimizer' -as [type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class MemoryOptimizer {
    [DllImport("psapi.dll")]
    public static extern int EmptyWorkingSet(IntPtr hwProc);
    public static int Optimize() {
        int count = 0;
        foreach (System.Diagnostics.Process p in System.Diagnostics.Process.GetProcesses()) {
            try { if (EmptyWorkingSet(p.Handle) != 0) count++; } catch {}
        }
        return count;
    }
}
"@ -ErrorAction Stop
        }
        $trimmed = [MemoryOptimizer]::Optimize()

        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()

        Write-Log "$(Get-Text 'Success') - working sets trimmed: $trimmed" 'SUCCESS'
    }
    catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
}

function Set-UltimatePerformance {
    Write-Log "$(Get-Text 'LogUltimate')..." 'CYAN'
    try {
        $guid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
        $plans = (powercfg /list) -join "`n"
        if ($plans -notmatch $guid) {
            powercfg -duplicatescheme $guid 2>&1 | Out-Null
        }
        powercfg /setactive $guid 2>&1 | Out-Null

        $active = (powercfg /getactivescheme) -join ' '
        if ($active -match $guid) {
            Write-Log (Get-Text 'LogUltimateOn') 'SUCCESS'
        }
        else {
            # Fall back to High Performance when the ultimate plan is unavailable
            powercfg /setactive SCHEME_MIN 2>&1 | Out-Null
            Write-Log (Get-Text 'LogUltimateFallback') 'WARNING'
        }
    }
    catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
}

function Get-CleanTargetDefs {
    # Eine Zeile je Ablage. Default = $false heisst: im Dialog NICHT
    # vorausgewaehlt. Risky = $true blendet den Hinweistext ein.
    # MinAgeHours schuetzt Dateien, die gerade erst geschrieben wurden -
    # in %TEMP% liegen waehrend einer laufenden Installation die
    # Entpackverzeichnisse des Installationsprogramms.
    $win = [string]$env:SystemRoot
    $loc = [string]$env:LOCALAPPDATA
    # Bewusst zusammengesetzt statt Join-Path: Join-Path loest das Laufwerk
    # auf und wirft, sobald es das Laufwerk nicht kennt. Hier geht es nur um
    # eine Zeichenkette - ob der Ordner existiert, prueft Measure-CleanTargets.
    $j = {
        param([string]$Base, [string]$Rest)
        if ([string]::IsNullOrWhiteSpace($Base)) { return '' }
        return ($Base.TrimEnd('\', '/') + '\' + $Rest)
    }
    $list = @(
        @{ Key = 'Temp'; LabelKey = 'CtTemp'; Path = [string]$env:TEMP
            MinAgeHours = 1; Default = $true; Risky = $false; Services = @() }
        @{ Key = 'TempLocal'; LabelKey = 'CtTempLocal'; Path = (& $j $loc 'Temp')
            MinAgeHours = 1; Default = $true; Risky = $false; Services = @() }
        @{ Key = 'TempWin'; LabelKey = 'CtTempWin'; Path = (& $j $win 'Temp')
            MinAgeHours = 1; Default = $true; Risky = $false; Services = @() }
        @{ Key = 'Cbs'; LabelKey = 'CtCbs'; Path = (& $j $win 'Logs\CBS')
            MinAgeHours = 0; Default = $true; Risky = $false; Services = @() }
        @{ Key = 'Wer'; LabelKey = 'CtWer'; Path = (& $j $loc 'Microsoft\Windows\WER')
            MinAgeHours = 0; Default = $true; Risky = $false; Services = @() }
        @{ Key = 'Deliv'; LabelKey = 'CtDeliv'
            Path        = (& $j $win 'ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization')
            MinAgeHours = 0; Default = $true; Risky = $false; Services = @() }
        @{ Key = 'Prefetch'; LabelKey = 'CtPrefetch'; Path = (& $j $win 'Prefetch')
            MinAgeHours = 0; Default = $false; Risky = $true; Services = @() }
        @{ Key = 'SoftDist'; LabelKey = 'CtSoftDist'; Path = (& $j $win 'SoftwareDistribution\Download')
            MinAgeHours = 0; Default = $false; Risky = $true; Services = @('wuauserv', 'bits') }
        @{ Key = 'WuLog'; LabelKey = 'CtWuLog'; Path = (& $j $win 'Logs\WindowsUpdate')
            MinAgeHours = 0; Default = $true; Risky = $false; Services = @() }
        @{ Key = 'Shader'; LabelKey = 'CtShader'; Path = (& $j $loc 'D3DSCache')
            MinAgeHours = 0; Default = $true; Risky = $false; Services = @() }
        @{ Key = 'Panther'; LabelKey = 'CtPanther'; Path = (& $j $win 'Panther')
            MinAgeHours = 0; Default = $false; Risky = $true; Services = @() }
        @{ Key = 'Dump'; LabelKey = 'CtDump'; Path = (& $j $win 'Minidump')
            MinAgeHours = 0; Default = $false; Risky = $true; Services = @() }
        @{ Key = 'Recycle'; LabelKey = 'CtRecycle'; Kind = 'recycle'
            Paths = (Get-RecycleBinPaths -Drives (Get-FixedDriveRoots))
            Path = ((Get-RecycleBinPaths -Drives (Get-FixedDriveRoots)) | Select-Object -First 1)
            MinAgeHours = 0; Default = $false; Risky = $true; Services = @() }
    )
    # Doppelte Pfade (TEMP zeigt fast immer auf LOCALAPPDATA\Temp) nur einmal
    $seen = @{}
    $out = New-Object System.Collections.Generic.List[object]
    foreach ($t in $list) {
        if ([string]::IsNullOrWhiteSpace($t.Path)) { continue }
        $norm = ([string]$t.Path).TrimEnd('\', '/').ToLowerInvariant()
        if ($seen.ContainsKey($norm)) { continue }
        $seen[$norm] = $true
        $out.Add([pscustomobject]$t)
    }
    $out.ToArray()
}

function Test-CleanSkipEntry {
    # Reine Pruefung: darf dieser Eintrag geloescht werden?
    param(
        [string]$Name,
        [datetime]$LastWrite,
        [datetime]$Now,
        [int]$MinAgeHours = 0
    )
    if ([string]::IsNullOrWhiteSpace($Name)) { return $true }
    # Das eigene Protokoll und die eigene Sitzung nie wegloeschen
    if ($Name -like 'EB_EHAB*' -or $Name -like 'EB_Optimizer*' -or $Name -like 'EB_Bak_*' -or
        $Name -like 'EB_Logo*') { return $true }
    if ($MinAgeHours -le 0) { return $false }
    return (($Now - $LastWrite).TotalHours -lt $MinAgeHours)
}

function Get-CleanTopSegment {
    # Zu welchem obersten Eintrag unterhalb der Ablage gehoert diese Datei?
    # Der Schutz greift am obersten Ordnernamen - sonst umgeht man ihn, indem
    # man eine Ebene tiefer schaut.
    param([string]$Root, [string]$FullName)
    # Beide Trennzeichen zulassen: ein Pfad aus einer Umgebungsvariablen oder
    # aus den Einstellungen kann '/' enthalten, und dann griffe der Schutz
    # stillschweigend nicht mehr.
    $r = ([string]$Root).Replace('/', '\').TrimEnd('\')
    $f = ([string]$FullName).Replace('/', '\')
    if (-not $r -or -not $f) { return '' }
    if ($f.Length -le ($r.Length + 1)) { return '' }
    if (-not $f.ToLowerInvariant().StartsWith(($r + '\').ToLowerInvariant())) { return '' }
    $rest = $f.Substring($r.Length + 1)
    $i = $rest.IndexOf('\')
    if ($i -lt 0) { return $rest }
    return $rest.Substring(0, $i)
}

function Select-CleanDeletable {
    # Messen und Loeschen trafen bisher unterschiedliche Entscheidungen: das
    # Messen sah jede Datei einzeln an, das Loeschen nur den obersten Eintrag.
    # Ein Ordner mit altem Datum wurde deshalb samt der Datei geloescht, die
    # das laufende Installationsprogramm eine Minute zuvor hineingeschrieben
    # hatte. Beide Seiten benutzen ab jetzt diese eine Entscheidung.
    param($Entries, [datetime]$Now = (Get-Date), [int]$MinAgeHours = 0, [string]$Root = '')
    $files = New-Object System.Collections.Generic.List[string]
    $bytes = 0.0
    $kept = 0
    foreach ($e in @($Entries)) {
        if (-not $e) { continue }
        $full = [string]$e.FullName
        $name = [string]$e.Name
        $lw = [datetime]::MinValue
        try { $lw = [datetime]$e.LastWrite } catch { }
        $top = Get-CleanTopSegment -Root $Root -FullName $full
        # Geschuetzt ist sowohl die Datei selbst als auch alles unterhalb
        # eines geschuetzten obersten Ordners.
        $skip = (Test-CleanSkipEntry -Name $name -LastWrite $lw -Now $Now -MinAgeHours $MinAgeHours)
        if (-not $skip -and $top) {
            $skip = (Test-CleanSkipEntry -Name $top -LastWrite $lw -Now $Now -MinAgeHours 0)
        }
        if ($skip) { $kept++; continue }
        $files.Add($full)
        try { $bytes += [double]$e.Length } catch { }
    }
    return @{ Files = $files.ToArray(); Bytes = $bytes; Count = $files.Count; Kept = $kept }
}

function Get-RecycleBinPaths {
    # Der Papierkorb liegt je Laufwerk in einem versteckten Systemordner.
    param($Drives)
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($d in @($Drives)) {
        $root = ([string]$d).Trim()
        if (-not $root) { continue }
        $out.Add(($root.TrimEnd('\', '/') + '\$Recycle.Bin'))
    }
    return $out.ToArray()
}

function Get-FixedDriveRoots {
    $out = New-Object System.Collections.Generic.List[string]
    try {
        foreach ($di in [System.IO.DriveInfo]::GetDrives()) {
            if ($di.DriveType -ne [System.IO.DriveType]::Fixed) { continue }
            if (-not $di.IsReady) { continue }
            $out.Add([string]$di.Name)
        }
    }
    catch { }
    if ($out.Count -eq 0) { $out.Add(([string]$env:SystemDrive) + '\') }
    return $out.ToArray()
}

function Invoke-BusyTick {
    # Eine einzige Stelle, an der ein langer Durchlauf die Nachrichten-
    # schleife bedient. Ohne das friert das Fenster ein und Windows blendet
    # nach fuenf Sekunden "Die Anwendung reagiert nicht" ein - obwohl das
    # Programm in Wahrheit nur zaehlt.
    param([string]$Status = '', [int]$Percent = -1)
    if ($Status) { Update-BusyOverlay -Status $Status -Percent $Percent }
    else { Update-BusyOverlay -KeepPercent }
    return (Test-BusyCancelled)
}

function Get-FileEntriesFast {
    # Dateien unterhalb eines Ordners aufzaehlen, ohne das Fenster zu
    # blockieren. Drei Unterschiede zum frueheren Get-ChildItem -Recurse:
    #   1. .NET-Aufzaehlung statt Anbieter - um ein Vielfaches schneller und
    #      ohne ein PowerShell-Objekt je Datei.
    #   2. Verbindungspunkte (Junctions, symbolische Verknuepfungen) werden
    #      NICHT verfolgt. '%LOCALAPPDATA%\Application Data' zeigt auf sich
    #      selbst - Get-ChildItem lief dort im Kreis, bis nichts mehr ging.
    #   3. Obergrenze fuer Dateien und Zeit, dazu regelmaessiges Luftholen
    #      fuer Oberflaeche und Abbruchknopf.
    param(
        [string]$Root,
        [int]$MaxFiles = 120000,
        [int]$TimeoutSec = 20,
        [int]$TickEvery = 500,
        [switch]$Quiet
    )
    $res = @{ Files = @(); Count = 0; Partial = $false; Cancelled = $false }
    if ([string]::IsNullOrWhiteSpace($Root)) { return $res }
    $list = New-Object System.Collections.Generic.List[object]
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $stack = New-Object System.Collections.Generic.Stack[string]
    $stack.Push($Root)
    $seen = 0
    $reparse = [System.IO.FileAttributes]::ReparsePoint

    while ($stack.Count -gt 0) {
        $dir = $stack.Pop()
        $di = $null
        try { $di = New-Object System.IO.DirectoryInfo -ArgumentList $dir } catch { continue }
        if (-not $di.Exists) { continue }
        try {
            foreach ($sub in $di.EnumerateDirectories()) {
                if (($sub.Attributes -band $reparse) -eq $reparse) { continue }
                $stack.Push($sub.FullName)
            }
        }
        catch { }
        try {
            foreach ($f in $di.EnumerateFiles()) {
                if (($f.Attributes -band $reparse) -eq $reparse) { continue }
                $list.Add([pscustomobject]@{
                        FullName  = $f.FullName
                        Name      = $f.Name
                        LastWrite = $f.LastWriteTime
                        Length    = [double]$f.Length
                        Root      = $Root
                    })
                $seen++
                if (($seen % $TickEvery) -eq 0) {
                    if (-not $Quiet) {
                        if (Invoke-BusyTick -Status ("$(Get-Text 'CleanScan')  $seen") ) {
                            $res.Cancelled = $true
                            break
                        }
                    }
                    elseif (Test-BusyCancelled) { $res.Cancelled = $true; break }
                    if ($sw.Elapsed.TotalSeconds -ge $TimeoutSec) { $res.Partial = $true; break }
                }
                if ($seen -ge $MaxFiles) { $res.Partial = $true; break }
            }
        }
        catch { }
        if ($res.Cancelled -or $res.Partial) { break }
        if ($sw.Elapsed.TotalSeconds -ge $TimeoutSec) { $res.Partial = $true; break }
    }
    $sw.Stop()
    $res.Files = $list.ToArray()
    $res.Count = $list.Count
    return $res
}

function Get-EmptyFolderList {
    # Leere Ordner von innen nach aussen, ohne Verbindungspunkte zu verfolgen.
    param([string]$Root, [int]$MaxDirs = 20000)
    $out = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($Root)) { return @() }
    $all = New-Object System.Collections.Generic.List[string]
    $stack = New-Object System.Collections.Generic.Stack[string]
    $stack.Push($Root)
    $reparse = [System.IO.FileAttributes]::ReparsePoint
    while ($stack.Count -gt 0 -and $all.Count -lt $MaxDirs) {
        $dir = $stack.Pop()
        $di = $null
        try { $di = New-Object System.IO.DirectoryInfo -ArgumentList $dir } catch { continue }
        if (-not $di.Exists) { continue }
        try {
            foreach ($sub in $di.EnumerateDirectories()) {
                if (($sub.Attributes -band $reparse) -eq $reparse) { continue }
                $all.Add($sub.FullName)
                $stack.Push($sub.FullName)
            }
        }
        catch { }
    }
    # Tiefste zuerst - sonst bleibt der Elternordner stehen, weil das Kind
    # beim Pruefen noch existierte.
    foreach ($d in ($all | Sort-Object -Property { ([string]$_).Length } -Descending)) { $out.Add($d) }
    return @($out.ToArray())
}

function Get-CleanFileEntries {
    # Flache Liste aller Dateien unterhalb der angegebenen Ablagen - die
    # gemeinsame Grundlage von Messung und Loeschung.
    param($Paths, [switch]$Quiet)
    $out = New-Object System.Collections.Generic.List[object]
    $script:CleanScanPartial = $false
    foreach ($p in @($Paths)) {
        if (-not $p) { continue }
        if (-not (Test-Path -LiteralPath $p)) { continue }
        # Mit Luftholen, Abbruch und Obergrenze - ein einziges
        # Get-ChildItem -Recurse ueber %TEMP% oder SoftwareDistribution
        # blockierte das Fenster so lange, bis Windows es fuer abgestuerzt hielt.
        $scan = Get-FileEntriesFast -Root ([string]$p) -Quiet:$Quiet
        foreach ($e in @($scan.Files)) { $out.Add($e) }
        if ($scan.Partial) { $script:CleanScanPartial = $true }
        if ($scan.Cancelled) { break }
    }
    return $out.ToArray()
}

function Remove-EmptyCleanFolders {
    # Nach dem Loeschen bleiben leere Geruste stehen. Von innen nach aussen
    # abraeumen, die Ablage selbst bleibt stehen.
    param([string]$Root)
    if (-not $Root -or -not (Test-Path -LiteralPath $Root)) { return 0 }
    $n = 0
    $i = 0
    try {
        foreach ($d in (Get-EmptyFolderList -Root $Root)) {
            $i++
            if (($i % 200) -eq 0) { if (Invoke-BusyTick) { break } }
            try {
                if (-not [System.IO.Directory]::EnumerateFileSystemEntries($d).GetEnumerator().MoveNext()) {
                    [System.IO.Directory]::Delete($d, $false)
                    $n++
                }
            }
            catch { }
        }
    }
    catch { }
    return $n
}

function Get-CleanTotals {
    # Summe ueber die angehakten Zeilen - fuer die Fusszeile des Dialogs.
    param($Rows)
    $bytes = 0.0; $files = 0; $n = 0
    foreach ($r in @($Rows)) {
        if (-not $r -or -not $r.Selected) { continue }
        $bytes += [double]$r.Bytes
        $files += [int]$r.Files
        $n++
    }
    return @{ Bytes = $bytes; Files = $files; Targets = $n }
}

function Split-CleanLabel {
    # Die Beschriftungen der heiklen Ablagen tragen ihre Begruendung hinter
    # einem ' - '. Im Dialog steht der erste Teil am Haken, der zweite klein
    # darunter. Alle vier Sprachtabellen benutzen dasselbe Trennzeichen.
    param([string]$Text)
    $i = ([string]$Text).IndexOf(' - ')
    if ($i -lt 1) { return @{ Head = [string]$Text; Hint = '' } }
    return @{
        Head = ([string]$Text).Substring(0, $i).Trim()
        Hint = ([string]$Text).Substring($i + 3).Trim()
    }
}

function Measure-CleanTargets {
    param($Targets)
    $now = Get-Date
    $all = @($Targets)
    $out = New-Object System.Collections.Generic.List[object]
    $i = 0
    foreach ($t in $all) {
        $i++
        if (Test-BusyCancelled) { break }
        Update-BusyOverlay -Status "$(Get-Text 'CleanScan')  $i / $($all.Count)" `
            -Percent ([int](($i - 1) / [double]$all.Count * 100))
        $paths = @($t.Paths)
        if ($paths.Count -eq 0 -and $t.Path) { $paths = @([string]$t.Path) }
        $entries = Get-CleanFileEntries -Paths $paths
        # Genau dieselbe Entscheidung wie beim Loeschen - frueher konnten
        # angezeigte und freigegebene Menge weit auseinanderliegen.
        $sel = Select-CleanDeletable -Entries $entries -Now $now -MinAgeHours ([int]$t.MinAgeHours) -Root ''
        $out.Add([pscustomobject]@{
                Key         = $t.Key
                Label       = (Get-Text $t.LabelKey)
                Path        = [string]$t.Path
                Paths       = $paths
                Kind        = $(if ($t.Kind) { [string]$t.Kind } else { 'dir' })
                Bytes       = [double]$sel.Bytes
                Files       = [int]$sel.Count
                Selected    = ([bool]$t.Default -and [int]$sel.Count -gt 0)
                Risky       = [bool]$t.Risky
                Services    = @($t.Services)
                MinAgeHours = [int]$t.MinAgeHours
            })
    }
    $out.ToArray()
}


function Show-CleanPreview {
    # Zeigt vor dem Loeschen, WAS geloescht wird und wie viel das bringt.
    # Rueckgabe: die Zeilen mit aktualisiertem Selected, oder $null bei Abbruch.
    param($Rows)

    $rows = @($Rows)
    if ($rows.Count -eq 0) { return $null }

    $dlg = New-Object System.Windows.Forms.Form
    $boxes = New-Object System.Collections.Generic.List[object]
    try {
        $rowH = @{}
        $listH = 0
        foreach ($r in $rows) {
            $h = if ($r.Risky) { 50 } else { 30 }
            $rowH[$r.Key] = $h
            $listH += $h
        }
        $maxList = 330
        $scroll = ($listH -gt $maxList)
        if ($scroll) { $listH = $maxList }

        $w = 660
        $h = 96 + $listH + 86
        $dlg.Size = New-Object System.Drawing.Size($w, $h)
        $dlg.StartPosition = 'CenterParent'
        $dlg.FormBorderStyle = 'None'
        $dlg.BackColor = $script:Theme.Accent
        $dlg.ShowInTaskbar = $false

        $inner = New-Object System.Windows.Forms.Panel
        $inner.Location = New-Object System.Drawing.Point(2, 2)
        $inner.Size = New-Object System.Drawing.Size(($w - 4), ($h - 4))
        $inner.BackColor = $script:Theme.BgSecondary
        $dlg.Controls.Add($inner)

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text = "{icon:broom} $(Get-Text 'CleanTitle')"
        $lblTitle.Font = (Get-AppFont -Size 13 -Style 'Bold')
        $lblTitle.ForeColor = $script:Theme.AccentLight
        $lblTitle.Location = New-Object System.Drawing.Point(22, 18)
        $lblTitle.AutoSize = $true
        $inner.Controls.Add($lblTitle)

        $pnlList = New-Object System.Windows.Forms.Panel
        $pnlList.Location = New-Object System.Drawing.Point(18, 56)
        $pnlList.Size = New-Object System.Drawing.Size(($w - 40), $listH)
        $pnlList.BackColor = $script:Theme.BgPrimary
        $pnlList.AutoScroll = $scroll
        $inner.Controls.Add($pnlList)

        $lblSum = New-Object System.Windows.Forms.Label
        $lblSum.Font = (Get-AppFont -Size 11 -Style 'Bold')
        $lblSum.ForeColor = $script:Theme.Success
        $lblSum.Location = New-Object System.Drawing.Point(22, (62 + $listH))
        $lblSum.Size = New-Object System.Drawing.Size(380, 26)
        $inner.Controls.Add($lblSum)

        $sizeW = 150
        $y = 6
        foreach ($r in $rows) {
            $parts = Split-CleanLabel -Text $r.Label

            $chk = New-Object System.Windows.Forms.CheckBox
            $chk.Text = '  ' + $parts.Head
            $chk.Font = (Get-AppFont -Size 10)
            $chk.ForeColor = if ($r.Risky) { $script:Theme.Warning } else { $script:Theme.TextPrimary }
            $chk.BackColor = [System.Drawing.Color]::Transparent
            $chk.Location = New-Object System.Drawing.Point(12, $y)
            $chk.Size = New-Object System.Drawing.Size(($pnlList.Width - $sizeW - 40), 24)
            $chk.Checked = [bool]$r.Selected
            $chk.Tag = $r.Key
            $pnlList.Controls.Add($chk)
            $boxes.Add($chk)

            $lblSize = New-Object System.Windows.Forms.Label
            $lblSize.Text = "$(Get-FormattedBytes $r.Bytes)   $($r.Files) $(Get-Text 'CleanFiles')"
            $lblSize.Font = (Get-AppFont -Size 9)
            $lblSize.ForeColor = $script:Theme.TextSecondary
            $lblSize.TextAlign = 'MiddleRight'
            $lblSize.Location = New-Object System.Drawing.Point(($pnlList.Width - $sizeW - 20), ($y + 2))
            $lblSize.Size = New-Object System.Drawing.Size($sizeW, 20)
            $pnlList.Controls.Add($lblSize)

            if ($parts.Hint) {
                $lblHint = New-Object System.Windows.Forms.Label
                $lblHint.Text = $parts.Hint
                $lblHint.Font = (Get-AppFont -Size 8)
                $lblHint.ForeColor = $script:Theme.TextSecondary
                $lblHint.Location = New-Object System.Drawing.Point(34, ($y + 24))
                $lblHint.Size = New-Object System.Drawing.Size(($pnlList.Width - 60), 22)
                $pnlList.Controls.Add($lblHint)
            }
            $y += [int]$rowH[$r.Key]
        }

        # Fusszeile fortschreiben. Die Schliessvariable haelt die Kaestchen,
        # damit der Haken-Ereignisbehandler sie nach dem Aufbau noch sieht.
        $rowMap = @{}
        foreach ($r in $rows) { $rowMap[$r.Key] = $r }
        $refresh = {
            foreach ($b in $boxes) {
                if ($rowMap.ContainsKey([string]$b.Tag)) { $rowMap[[string]$b.Tag].Selected = $b.Checked }
            }
            $t = Get-CleanTotals -Rows $rows
            $lblSum.Text = "$(Get-Text 'CleanTotal'): $(Get-FormattedBytes $t.Bytes)   ($($t.Files) $(Get-Text 'CleanFiles'))"
        }.GetNewClosure()
        foreach ($b in $boxes) { $b.Add_CheckedChanged($refresh) }
        & $refresh

        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Text = Get-Text 'DlgContinue'
        $btnOK.Size = New-Object System.Drawing.Size(140, 36)
        $btnOK.Location = New-Object System.Drawing.Point(($w - 310), (60 + $listH))
        $btnOK.BackColor = $script:Theme.Accent
        $btnOK.ForeColor = $script:Theme.TextWhite
        $btnOK.FlatStyle = 'Flat'
        $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $inner.Controls.Add($btnOK)

        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = Get-Text 'Cancel'
        $btnCancel.Size = New-Object System.Drawing.Size(130, 36)
        $btnCancel.Location = New-Object System.Drawing.Point(($w - 160), (60 + $listH))
        $btnCancel.BackColor = $script:Theme.BgTertiary
        $btnCancel.ForeColor = $script:Theme.TextPrimary
        $btnCancel.FlatStyle = 'Flat'
        $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $inner.Controls.Add($btnCancel)

        $dlg.AcceptButton = $btnOK
        $dlg.CancelButton = $btnCancel
        Update-ControlIcons -Root $dlg -Size 16
        try { Set-DarkInputs -Control $dlg -Recurse } catch { }

        $res = if ($script:MainForm -and -not $script:MainForm.IsDisposed) { $dlg.ShowDialog($script:MainForm) }
        else { $dlg.ShowDialog() }
        if ($res -ne [System.Windows.Forms.DialogResult]::OK) { return $null }
        & $refresh
        return $rows
    }
    finally { $dlg.Dispose() }
}

function Suspend-CleanServices {
    # SoftwareDistribution\Download bei laufendem Update-Dienst zu leeren ist
    # die klassische Ursache fuer haengende Updates: wuauserv haelt die
    # Dateien offen und seine Datenbank zeigt danach auf nichts mehr.
    param([string[]]$Names)
    $res = @{ Ok = $true; Resume = @() }
    foreach ($n in @($Names)) {
        try {
            $svc = Get-Service -Name $n -ErrorAction Stop
            if ($svc.Status -eq 'Running') {
                Stop-Service -Name $n -Force -ErrorAction Stop
                $svc.WaitForStatus('Stopped', [timespan]::FromSeconds(20))
                $res.Resume = @($res.Resume) + $n
            }
        }
        catch { $res.Ok = $false }
    }
    return $res
}

function Resume-CleanServices {
    param([string[]]$Names)
    foreach ($n in @($Names)) {
        try { Start-Service -Name $n -ErrorAction Stop } catch { }
    }
}

function Format-CleanLine {
    param([string]$Label, [double]$Bytes, [int]$Files, [int]$Locked = 0)
    $parts = Split-CleanLabel -Text $Label
    $s = "   $($parts.Head):  $(Get-FormattedBytes $Bytes)  /  $Files $(Get-Text 'CleanFiles')"
    if ($Locked -gt 0) { $s += "   ($Locked $(Get-Text 'CleanLocked'))" }
    return $s
}

function Clear-CleanTarget {
    # Loescht dateiweise. Ein einziges rekursives Remove-Item blockiert
    # minutenlang - weder Abbruch noch Fortschritt reagieren dann. Und es
    # nahm junge Dateien in alten Ordnern mit.
    param($Row, [int]$Index, [int]$Count)

    $freed = 0.0; $locked = 0
    $now = Get-Date
    $head = (Split-CleanLabel -Text $Row.Label).Head
    $paths = @($Row.Paths)
    if ($paths.Count -eq 0 -and $Row.Path) { $paths = @([string]$Row.Path) }

    if ([string]$Row.Kind -eq 'recycle') {
        # Der Papierkorb wird ueber Windows selbst geleert - Dateien dort
        # von Hand zu loeschen hinterlaesst einen beschaedigten Index.
        foreach ($p in $paths) {
            $drive = ([string]$p).Substring(0, 1)
            try { Clear-RecycleBin -DriveLetter $drive -Force -ErrorAction Stop -Confirm:$false }
            catch { $locked++ }
        }
        return @{ Freed = [double]$Row.Bytes; Locked = $locked }
    }

    $entries = Get-CleanFileEntries -Paths $paths
    # Manche Ablagen wollen nur bestimmte Dateien los (thumbcache_*.db).
    if ($Row.PSObject.Properties['Filter'] -and $Row.Filter) {
        $entries = @($entries | Where-Object { $_.Name -like $Row.Filter })
    }
    $plan = Select-CleanDeletable -Entries $entries -Now $now -MinAgeHours ([int]$Row.MinAgeHours) -Root ''
    $files = @($plan.Files)
    $sizes = @{}
    foreach ($e in $entries) { $sizes[[string]$e.FullName] = [double]$e.Length }
    $n = $files.Count
    $j = 0
    foreach ($f in $files) {
        $j++
        if (Test-BusyCancelled) { break }
        try {
            Remove-Item -LiteralPath $f -Force -ErrorAction Stop
            $freed += [double]$sizes[[string]$f]
        }
        catch { $locked++ }   # in Benutzung oder geschuetzt - stillschweigend weiter

        if ($n -gt 0 -and ($j % 25 -eq 0 -or $j -eq $n)) {
            $done = ($Index - 1) + ($j / [double]$n)
            Update-BusyOverlay -Status "$head   ($j / $n)" -Percent ([int]($done / [double]$Count * 100))
        }
    }
    foreach ($p in $paths) { [void](Remove-EmptyCleanFolders -Root $p) }
    return @{ Freed = $freed; Locked = $locked }
}

function Invoke-QuickClean {
    [CmdletBinding()]
    param([switch]$Silent)

    Write-Log "$(Get-Text 'QuickClean')..." 'INFO'

    # Schritt 1: messen. Frueher loeschte die Funktion sofort los - der
    # Benutzer erfuhr weder vorher was verschwindet noch hinterher wo es
    # herkam, und Prefetch/SoftwareDistribution gingen ungefragt mit.
    $scan = @()
    Show-BusyOverlay -Title (Get-Text 'QuickClean') -Cancellable
    try { $scan = @(Measure-CleanTargets -Targets (Get-CleanTargetDefs)) }
    finally { Hide-BusyOverlay }

    if (Test-BusyCancelled) { Write-Log (Get-Text 'BusyCancelled') 'WARNING'; return 0 }
    # Eine abgebrochene Messung darf nicht als vollstaendige Zahl erscheinen.
    if ($script:CleanScanPartial) { Write-Log (Get-Text 'CleanPartial') 'WARNING' }

    $scan = @($scan | Where-Object { $_.Files -gt 0 })
    if ($scan.Count -eq 0) {
        Write-Log (Get-Text 'CleanNothing') 'INFO'
        return 0
    }

    # Schritt 2: fragen (ausser bei der Rundum-Optimierung)
    if (-not $Silent -and $script:Config.CleanConfirm) {
        $scan = Show-CleanPreview -Rows $scan
        if ($null -eq $scan) { Write-Log (Get-Text 'BusyCancelled') 'WARNING'; return 0 }
    }
    $sel = @(@($scan) | Where-Object { $_.Selected })
    if ($sel.Count -eq 0) {
        Write-Log (Get-Text 'CleanNothing') 'INFO'
        return 0
    }

    # Schritt 3: loeschen
    $total = 0.0
    $report = New-Object System.Collections.Generic.List[string]
    Show-BusyOverlay -Title (Get-Text 'QuickClean') -Cancellable
    try {
        $i = 0
        foreach ($row in $sel) {
            $i++
            if (Test-BusyCancelled) { Write-Log (Get-Text 'BusyCancelled') 'WARNING'; break }
            if (-not $row.Path -or -not (Test-Path -LiteralPath $row.Path)) { continue }
            Update-BusyOverlay -Status (Split-CleanLabel -Text $row.Label).Head `
                -Percent ([int](($i - 1) / [double]$sel.Count * 100))

            $svc = $null
            if (@($row.Services).Count -gt 0) {
                Write-Log (Get-Text 'CleanSvcStop') 'INFO'
                $svc = Suspend-CleanServices -Names $row.Services
                if (-not $svc.Ok) {
                    Write-Log (Get-Text 'CleanSvcFail') 'WARNING'
                    Resume-CleanServices -Names $svc.Resume
                    continue
                }
            }
            try {
                $r = Clear-CleanTarget -Row $row -Index $i -Count $sel.Count
                $total += [double]$r.Freed
                $report.Add((Format-CleanLine -Label $row.Label -Bytes $r.Freed -Files $row.Files -Locked $r.Locked))
            }
            finally {
                if ($svc -and @($svc.Resume).Count -gt 0) {
                    Resume-CleanServices -Names $svc.Resume
                    Write-Log (Get-Text 'CleanSvcStart') 'INFO'
                }
            }
            Update-BusyOverlay -Percent ([int]($i / [double]$sel.Count * 100))
        }
    }
    finally { Hide-BusyOverlay }

    # Schritt 4: aufschluesseln statt nur eine Gesamtzahl zu nennen
    foreach ($line in $report) { Write-Log $line 'INFO' }
    Write-Log "$(Get-Text 'CleanFreed'): $(Get-FormattedBytes $total)" 'SUCCESS'
    return $total
}

function Invoke-AutoOptimize {
    Write-Log "=== $(Get-Text 'QuickAuto') ===" 'TITLE'
    Show-BusyOverlay -Title (Get-Text 'QuickAuto')
    try {
        Update-BusyOverlay -Status "$(Get-Text 'BusyStep') 1 / 4:  $(Get-Text 'QuickClean')" -Percent 5
        [void](Invoke-QuickClean -Silent)

        if (Test-BusyCancelled) { Write-Log (Get-Text 'BusyCancelled') 'WARNING'; return }

        Update-BusyOverlay -Status "$(Get-Text 'BusyStep') 2 / 4:  $(Get-Text 'QuickRAM')" -Percent 45
        Optimize-Memory

        Update-BusyOverlay -Status "$(Get-Text 'BusyStep') 3 / 4:  DNS" -Percent 70
        try { Clear-DnsClientCache -ErrorAction Stop } catch { ipconfig /flushdns | Out-Null }
        Write-Log (Get-Text 'LogDnsCleared') 'SUCCESS'

        Update-BusyOverlay -Status "$(Get-Text 'BusyStep') 4 / 4:  Ultimate Performance" -Percent 90
        Set-UltimatePerformance
        Update-BusyOverlay -Percent 100
    }
    finally { Hide-BusyOverlay }
    Write-Log "$(Get-Text 'DlgCompleted')" 'SUCCESS'
}

function Get-StartupEntryCount {
    # Billig genug fuer die Bewertung, weil das Ergebnis fuenf Minuten haelt.
    # Gezaehlt werden nur aktive Eintraege: etwas, das der Nutzer bereits
    # abgeschaltet hat, darf keine Punkte mehr kosten. Die Liste kommt aus
    # derselben Quelle wie die Autostart-Ansicht - vorher zaehlte die
    # Bewertung weniger Orte als die Ansicht anzeigte.
    if ($script:StartupCountTime -and ((Get-Date) - $script:StartupCountTime).TotalSeconds -lt 300) {
        return [int]$script:StartupCountCache
    }
    $n = 0
    try {
        foreach ($e in (Get-StartupEntryList)) {
            $on = $true
            try { $on = [bool]$e.Enabled } catch { }
            if ($on) { $n++ }
        }
    }
    catch { $n = 0 }
    $script:StartupCountCache = $n
    $script:StartupCountTime = Get-Date
    return $n
}

function Read-PendingRebootState {
    # Windows fuehrt kein einzelnes Kennzeichen - jede Komponente hinterlaesst
    # ihre eigene Spur. Alle fuenf zusammen ergeben erst ein verlaessliches
    # Bild. Zwischengespeichert, weil die Dashboard-Karte im Sekundentakt
    # nachfragt.
    param([switch]$ForceRefresh)
    if (-not $ForceRefresh -and $script:RebootState -and $script:RebootStateTime -and
        ((Get-Date) - $script:RebootStateTime).TotalSeconds -lt 60) {
        return $script:RebootState
    }
    $st = @{ Cbs = $false; Update = $false; Rename = $false; Files = $false; Tweak = [bool]$script:RebootHint }
    try {
        $st.Cbs = (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
        (Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending')
    }
    catch { }
    try {
        $st.Update = Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    }
    catch { }
    try {
        $a = (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -Name 'ComputerName' -ErrorAction Stop).ComputerName
        $b = (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -Name 'ComputerName' -ErrorAction Stop).ComputerName
        $st.Rename = ("$a" -ne "$b")
    }
    catch { }
    try {
        $sm = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction Stop
        $st.Files = (@($sm.PendingFileRenameOperations).Count -gt 0)
    }
    catch { }
    $script:RebootState = $st
    $script:RebootStateTime = Get-Date
    return $st
}

function Get-PendingRebootReasons {
    # Reine Auswertung - macht aus den Kennzeichen eine Liste von Textschluesseln.
    param($State)
    $out = @()
    if (-not $State) { return $out }
    foreach ($pair in @(@('Cbs', 'RebCbs'), @('Update', 'RebUpdate'), @('Rename', 'RebRename'),
            @('Files', 'RebFiles'), @('Tweak', 'RebTweak'))) {
        $v = $false
        try { $v = [bool]$State[$pair[0]] } catch { }
        if ($v) { $out += $pair[1] }
    }
    return $out
}

function Set-RebootHint {
    # Von Tweaks aufgerufen, die erst nach einem Neustart greifen.
    $script:RebootHint = $true
    $script:RebootStateTime = $null
}

function Get-SmoothedStat {
    # Ein einzelner Messpunkt im Sekundentakt macht die Bewertung zittrig:
    # ein kurzer Ausschlag beim Oeffnen eines Programms kostete sofort Punkte.
    # Gewertet wird deshalb der Mittelwert der letzten Sekunden.
    param([string]$Key = 'CPU', [int]$Samples = 15, [double]$Fallback = 0)
    try {
        $list = $script:SparklineHistory[$Key]
        if (-not $list -or $list.Count -eq 0) { return $Fallback }
        $take = [math]::Min($Samples, $list.Count)
        $sum = 0.0
        for ($i = $list.Count - $take; $i -lt $list.Count; $i++) { $sum += [double]$list[$i] }
        return ($sum / $take)
    }
    catch { return $Fallback }
}

function Get-DefenderHealth {
    # Nur was sich wirklich auslesen laesst, darf in die Bewertung einfliessen.
    # Auf Rechnern mit fremdem Virenschutz gibt es Get-MpComputerStatus nicht -
    # dann wird nichts abgezogen statt blind Punkte zu nehmen.
    param([switch]$ForceRefresh)
    if (-not $ForceRefresh -and $script:DefenderHealth -and $script:DefenderHealthTime -and
        ((Get-Date) - $script:DefenderHealthTime).TotalSeconds -lt 120) {
        return $script:DefenderHealth
    }
    $res = @{ Known = $false; RealTime = $true; SignatureAgeDays = 0 }
    # Get-MpComputerStatus braucht je nach Zustand des Virenschutzes mehrere
    # Sekunden. Die Bewertung laeuft aus dem Zeitgeber heraus - dort hiess das
    # alle zwei Minuten ein Ruckler bis hin zu "reagiert nicht". Die Abfrage
    # laeuft jetzt im Hintergrund; bis sie da ist, gilt "nicht messbar" und es
    # wird nichts abgezogen.
    if (-not (Request-CachedData -Key 'DefenderStatus' -TtlSeconds 120 -Loader {
                $s = Get-MpComputerStatus -ErrorAction SilentlyContinue
                if (-not $s) { return @() }
                # Als Zahl zurueckgeben: ein Datum als Text haengt an der
                # Landeseinstellung und laesst sich spaeter falsch oder gar
                # nicht zurueckwandeln.
                $ticks = [int64]0
                try { if ($s.AntivirusSignatureLastUpdated) { $ticks = [int64]$s.AntivirusSignatureLastUpdated.Ticks } } catch { }
                , ([pscustomobject]@{
                        RealTimeProtectionEnabled = [bool]$s.RealTimeProtectionEnabled
                        SignatureTicks            = $ticks
                    })
            })) {
        return $res
    }
    try {
        $st = @(Get-CacheEntryData -Key 'DefenderStatus')[0]
        if ($st) {
            $res.Known = $true
            $res.RealTime = [bool]$st.RealTimeProtectionEnabled
            if ([int64]$st.SignatureTicks -gt 0) {
                $res.SignatureAgeDays = [int][math]::Floor(((Get-Date) - (New-Object DateTime ([int64]$st.SignatureTicks))).TotalDays)
            }
        }
    }
    catch { }
    $script:DefenderHealth = $res
    $script:DefenderHealthTime = Get-Date
    return $res
}

function Get-RestorePointAge {
    # -1 bedeutet: nicht feststellbar oder abgeschaltet. Beides ist kein
    # Grund fuer einen Abzug - der Nutzer kann Systemwiederherstellung
    # bewusst ausgeschaltet haben.
    param([switch]$ForceRefresh)
    if (-not $ForceRefresh -and $null -ne $script:RestoreAge -and $script:RestoreAgeTime -and
        ((Get-Date) - $script:RestoreAgeTime).TotalSeconds -lt 600) {
        return $script:RestoreAge
    }
    $age = -1
    try {
        if (-not (Test-SystemRestoreDisabled)) {
            $last = @(Get-ComputerRestorePoint -ErrorAction Stop |
                Sort-Object -Property SequenceNumber -Descending | Select-Object -First 1)
            if ($last.Count -gt 0 -and $last[0].CreationTime) {
                $dt = [System.Management.ManagementDateTimeConverter]::ToDateTime([string]$last[0].CreationTime)
                $age = [int][math]::Floor(((Get-Date) - $dt).TotalDays)
            }
            else { $age = 9999 }
        }
    }
    catch { $age = -1 }
    $script:RestoreAge = $age
    $script:RestoreAgeTime = Get-Date
    return $age
}

function Get-SystemDriveSpace {
    $res = @{ FreePct = 0.0; FreeGB = 0.0; Known = $false }
    try {
        $root = [string]$env:SystemDrive
        if (-not $root) { $root = 'C:' }
        $d = New-Object System.IO.DriveInfo($root)
        if ($d.IsReady -and $d.TotalSize -gt 0) {
            $res.Known = $true
            $res.FreeGB = [double]$d.AvailableFreeSpace / 1GB
            $res.FreePct = ([double]$d.AvailableFreeSpace / [double]$d.TotalSize) * 100.0
        }
    }
    catch { }
    return $res
}

function Get-HealthDeductions {
    # Das ganze Bewertungsmodell an einer Stelle und ohne Zugriff auf das
    # System - dadurch laesst sich jede Regel einzeln nachrechnen.
    # Hoechstabzug je Gruppe in Klammern:
    #   CPU (20) RAM (20) Prozesse (10) Laufwerk (20) Autostart (8)
    #   Neustart (8) Echtzeitschutz (15) Signaturen (5) Sicherungspunkt (5)
    #   Laufzeit (4)
    param($Metrics)
    $items = New-Object System.Collections.Generic.List[object]
    $add = {
        param($Key, $Detail, $Points)
        $p = [int][math]::Round($Points)
        # Jeder Abzug kommt in die Liste. Frueher fielen kleine Posten unter
        # den Tisch, wurden aber abgezogen - die Liste erklaerte die Zahl nicht.
        if ($p -le 0) { return }
        $items.Add([pscustomobject]@{ Key = $Key; Detail = [string]$Detail; Points = $p })
    }
    if (-not $Metrics) { $Metrics = @{} }
    $get = {
        param($Name, $Default)
        if ($null -ne $Metrics[$Name]) { return $Metrics[$Name] }
        return $Default
    }

    $cpu = [double](& $get 'Cpu' 0)
    if ($cpu -gt 50) { & $add 'HealthCpu' ("{0} %" -f [int]$cpu) ([math]::Min(20, ($cpu - 50) / 2.5)) }

    $ram = [double](& $get 'Ram' 0)
    if ($ram -gt 80) { & $add 'HealthRam' ("{0} %" -f [int]$ram) ([math]::Min(20, $ram - 80)) }

    $procs = [int](& $get 'Procs' 0)
    $dp = 0
    if ($procs -gt 250) { $dp += 5 }
    if ($procs -gt 350) { $dp += 5 }
    if ($dp -gt 0) { & $add 'HealthProc' ([string]$procs) $dp }

    if ([bool](& $get 'DiskKnown' $false)) {
        $pct = [double](& $get 'DiskFreePct' 100)
        $gb = [double](& $get 'DiskFreeGB' 1000)
        $dd = 0
        if ($pct -lt 15) { $dd += 8 }
        if ($pct -lt 8) { $dd += 7 }
        # Prozent allein genuegt nicht: 10 Prozent sind auf einer 2-TB-Platte
        # reichlich und auf einer 128-GB-SSD zu wenig fuer ein Update.
        if ($gb -lt 25) { $dd += 5 }
        if ($gb -lt 10) { $dd += 5 }
        if ($dd -gt 0) {
            & $add 'HealthDisk' ("{0} % / {1:N0} GB" -f [int]$pct, $gb) ([math]::Min(20, $dd))
        }
    }

    $start = [int](& $get 'Startup' 0)
    $ds = 0
    if ($start -gt 10) { $ds += 4 }
    if ($start -gt 18) { $ds += 4 }
    if ($ds -gt 0) { & $add 'HealthStartup' ([string]$start) $ds }

    $reasons = @(& $get 'RebootReasons' @())
    if ($reasons.Count -gt 0) {
        & $add 'HealthReboot' ((@($reasons | ForEach-Object { Get-Text $_ })) -join ', ') 8
    }

    if ([bool](& $get 'DefenderKnown' $false)) {
        if (-not [bool](& $get 'DefenderRealTime' $true)) { & $add 'HealthDefRt' '' 15 }
        $sigAge = [int](& $get 'SignatureAgeDays' 0)
        if ($sigAge -gt 7) { & $add 'HealthDefSig' ("{0} {1}" -f $sigAge, (Get-Text 'UpdPauseDays')) 5 }
    }

    $rpAge = [int](& $get 'RestoreAgeDays' -1)
    if ($rpAge -ge 30) { & $add 'HealthRestore' $(if ($rpAge -ge 9999) { '' } else { "{0} {1}" -f $rpAge, (Get-Text 'UpdPauseDays') }) 5 }

    $up = [double](& $get 'UptimeDays' 0)
    if ($up -gt 14) { & $add 'HealthUptime' ("{0} {1}" -f [int]$up, (Get-Text 'UpdPauseDays')) 4 }

    $sorted = @($items.ToArray() | Sort-Object -Property Points -Descending)
    $total = 0
    foreach ($i in $sorted) { $total += [int]$i.Points }
    $score = [int][math]::Max(0, [math]::Min(100, 100 - $total))
    return @{ Score = $score; Items = $sorted; Deducted = $total }
}

function Get-HealthMetrics {
    # Sammelt die Messwerte. Alles Teure haengt an einem eigenen
    # Zwischenspeicher, denn die Bewertung laeuft alle paar Sekunden.
    $disk = Get-SystemDriveSpace
    $def = Get-DefenderHealth
    $upDays = 0.0
    try {
        $ms = [double]([Environment]::TickCount64)
        $upDays = $ms / 86400000.0
    }
    catch { }
    $pCount = if ($script:ProcCountCache -gt 0) { [int]$script:ProcCountCache }
    else { @(Get-Process -ErrorAction SilentlyContinue).Count }

    return @{
        Cpu              = (Get-SmoothedStat -Key 'CPU' -Samples 15 -Fallback ([double]$script:CurrentStats.CPU))
        Ram              = (Get-SmoothedStat -Key 'RAM' -Samples 15 -Fallback ([double]$script:CurrentStats.RAM))
        Procs            = $pCount
        DiskKnown        = $disk.Known
        DiskFreePct      = $disk.FreePct
        DiskFreeGB       = $disk.FreeGB
        Startup          = (Get-StartupEntryCount)
        RebootReasons    = @(Get-PendingRebootReasons -State (Read-PendingRebootState))
        DefenderKnown    = $def.Known
        DefenderRealTime = $def.RealTime
        SignatureAgeDays = $def.SignatureAgeDays
        RestoreAgeDays   = (Get-RestorePointAge)
        UptimeDays       = $upDays
    }
}

function Get-SystemHealthScore {
    # Die Zahl sagt nur etwas aus, wenn man sieht, woher der Abzug kommt -
    # die Liste der Posten entsteht deshalb zusammen mit dem Wert.
    param([switch]$ForceRefresh)

    if (-not $ForceRefresh -and $script:LastHealthCheck -and
        ((Get-Date) - $script:LastHealthCheck).TotalSeconds -lt 3) {
        return $script:CachedHealthScore
    }

    $res = Get-HealthDeductions -Metrics (Get-HealthMetrics)
    $script:HealthFactors = @($res.Items | ForEach-Object {
            [pscustomobject]@{
                Text   = $(if ($_.Detail) { "$(Get-Text $_.Key): $($_.Detail)" } else { (Get-Text $_.Key) })
                Points = [int]$_.Points
            }
        })
    $script:CachedHealthScore = [int]$res.Score
    $script:LastHealthCheck = Get-Date
    return $script:CachedHealthScore
}

function Get-WindowsRelease {
    # Build-Nummer -> Marketingname. 26H2 (Build 26300) kam am 29.09.2026 als
    # Enablement-Paket fuer 24H2/25H2 heraus; alle drei teilen sich denselben
    # Servicing-Zweig, deshalb unterscheidet nur die fuenfstellige Build-Zahl
    # die Versionen. 26H1 (28000) ist eine reine Werksversion fuer neue Geraete.
    # Zwischengespeichert - die Werte aendern sich zur Laufzeit nicht.
    if ($script:WindowsRelease) { return $script:WindowsRelease }
    $build = 0; $ubr = 0; $display = ''; $product = ''
    try {
        $cv = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        if ($cv.CurrentBuildNumber) { $build = [int]$cv.CurrentBuildNumber }
        if ($null -ne $cv.UBR) { $ubr = [int]$cv.UBR }
        if ($cv.DisplayVersion) { $display = [string]$cv.DisplayVersion }
        elseif ($cv.ReleaseId) { $display = [string]$cv.ReleaseId }
        if ($cv.ProductName) { $product = [string]$cv.ProductName }
    }
    catch { }
    if ($build -le 0) {
        try { $build = [int][Environment]::OSVersion.Version.Build } catch { $build = 0 }
    }

    $map = [ordered]@{
        '28000' = '26H1'; '26300' = '26H2'; '26200' = '25H2'; '26100' = '24H2'
        '22631' = '23H2'; '22621' = '22H2'; '22000' = '21H2'
    }
    $name = ''
    $bk = [string]$build
    if ($map.Contains($bk)) { $name = [string]$map[$bk] }
    if (-not $name) { $name = $display }

    # ProductName meldet auf Windows 11 weiterhin 'Windows 10' - nur die
    # Build-Nummer unterscheidet die beiden verlaesslich.
    $family = $product
    if ($build -ge 22000) { $family = 'Windows 11' }
    elseif ($build -ge 10240) { $family = 'Windows 10' }

    $full = [string]$build
    if ($ubr -gt 0) { $full = "$build.$ubr" }
    $parts = @($family, $name) | Where-Object { $_ }
    $text = (($parts -join ' ') + " (Build $full)").Trim()

    $script:WindowsRelease = [pscustomobject]@{
        Build      = $build
        UBR        = $ubr
        Display    = $display
        Name       = $name
        Family     = $family
        FullBuild  = $full
        Text       = $text
        IsWin11    = ($build -ge 22000)
        Is26H2Plus = ($build -ge 26300)
        HasWmic    = (Test-Path -LiteralPath (Join-Path $env:SystemRoot 'System32\wbem\wmic.exe'))
    }
    return $script:WindowsRelease
}

function Get-MemoryTypeName {
    # SMBIOSMemoryType -> lesbarer Name
    param($Code)
    switch ([int]$Code) {
        20 { 'DDR' }
        21 { 'DDR2' }
        24 { 'DDR3' }
        26 { 'DDR4' }
        34 { 'DDR5' }
        35 { 'LPDDR4' }
        default { '' }
    }
}

# Die gesamte Hardware-Abfrage als eigenstaendiger Skriptblock: sie laeuft
# wahlweise hier oder in einem Hintergrund-Runspace. Deshalb darf sie NICHTS
# aus dem Programm benutzen - die Grafikspeicher-Suche steht als lokale
# Funktion mit drin.
$script:HardwareQuery = {
    function Get-VramBytesLocal {
        param([string]$Name)
        try {
            $base = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
            foreach ($k in (Get-ChildItem -LiteralPath $base -ErrorAction Stop)) {
                if ($k.PSChildName -notmatch '^\d{4}$') { continue }
                $pr = Get-ItemProperty -LiteralPath $k.PSPath -ErrorAction SilentlyContinue
                if (-not $pr) { continue }
                $desc = [string]$pr.DriverDesc
                if (-not $desc) { continue }
                if ($Name -and ($desc -eq $Name -or $desc -like "*$Name*" -or $Name -like "*$desc*")) {
                    $v = $pr.'HardwareInformation.qwMemorySize'
                    if ($v) { return [double]$v }
                    $v2 = $pr.'HardwareInformation.MemorySize'
                    if ($v2) {
                        if ($v2 -is [byte[]]) { return [double][System.BitConverter]::ToUInt32($v2, 0) }
                        return [double]$v2
                    }
                }
            }
        }
        catch { }
        return 0.0
    }

    # WICHTIG: 'Select-Object -Property *' kopiert die Werte in einfache
    # Objekte. Laeuft diese Abfrage in einem Hintergrund-Runspace, wird der
    # unmittelbar danach geschlossen - rohe CIM-Objekte waeren dann an eine
    # abgeraeumte Sitzung gebunden und haetten nur noch leere Eigenschaften.
    # Genau daran ist die Hardware-Ansicht gescheitert.
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue |
        Select-Object -First 1 -Property *
    $gpus = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -Property *)
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue |
        Select-Object -First 1 -Property *
    $disks = @(Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue | Select-Object -Property *)
    $board = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue |
        Select-Object -First 1 -Property *
    $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue |
        Select-Object -First 1 -Property *
    $mods = @(Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue | Select-Object -Property *)

    # Datentraegerart (SSD/HDD) kommt aus dem Speicher-Namensraum; er fehlt
    # auf aelteren Systemen, daher nur als Zusatz.
    $media = @{}
    try {
        foreach ($pd in (Get-CimInstance -Namespace 'root/Microsoft/Windows/Storage' -ClassName MSFT_PhysicalDisk -ErrorAction Stop)) {
            $name = switch ([int]$pd.MediaType) { 3 { 'HDD' } 4 { 'SSD' } 5 { 'SCM' } default { '' } }
            if ($name) { $media[[string]$pd.DeviceId] = $name }
        }
    }
    catch { }

    # Grafikspeicher aus der Registrierung nachschlagen
    $vram = @{}
    foreach ($g in $gpus) {
        if (-not $g.Name) { continue }
        $b = Get-VramBytesLocal -Name ([string]$g.Name)
        if ($b -le 0 -and $g.AdapterRAM -and [double]$g.AdapterRAM -gt 0) { $b = [double]$g.AdapterRAM }
        $vram[[string]$g.Name] = $b
    }

    # Windows-Anzeigeversion (22H2 / 23H2) und vollstaendige Buildnummer
    $display = ''
    $ubr = ''
    try {
        $cv = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        if ($cv.DisplayVersion) { $display = [string]$cv.DisplayVersion }
        elseif ($cv.ReleaseId) { $display = [string]$cv.ReleaseId }
        if ($null -ne $cv.UBR) { $ubr = [string]$cv.UBR }
    }
    catch { }

    # Akku: der Ladestand steht in Win32_Battery, die beiden Kapazitaeten
    # dagegen im WMI-Namensraum root/wmi. Nur zusammen ergeben sie den
    # Verschleiss. Fehlt eines davon, bleibt das Feld leer.
    $battery = $null
    try {
        $b = Get-CimInstance Win32_Battery -ErrorAction Stop | Select-Object -First 1 -Property *
        if ($b) {
            $design = 0.0; $full = 0.0
            try {
                $sd = Get-CimInstance -Namespace 'root/wmi' -ClassName BatteryStaticData -ErrorAction Stop |
                    Select-Object -First 1 -Property *
                if ($sd) { $design = [double]$sd.DesignedCapacity }
            }
            catch { }
            try {
                $fc = Get-CimInstance -Namespace 'root/wmi' -ClassName BatteryFullChargedCapacity -ErrorAction Stop |
                    Select-Object -First 1 -Property *
                if ($fc) { $full = [double]$fc.FullChargedCapacity }
            }
            catch { }
            $battery = @{
                Percent            = [int]$b.EstimatedChargeRemaining
                OnBattery          = ([int]$b.BatteryStatus -eq 1)
                DesignedCapacity   = $design
                FullChargedCapacity = $full
            }
        }
    }
    catch { }

    # TPM und Secure Boot - beides entscheidet ueber die Windows-11-Tauglichkeit
    # und fehlte in der Uebersicht komplett.
    $tpmVer = ''
    $tpmOn = $null
    try {
        $t = Get-CimInstance -Namespace 'root/cimv2/security/microsofttpm' -ClassName Win32_Tpm -ErrorAction Stop |
            Select-Object -First 1 -Property *
        if ($t) {
            $tpmVer = (([string]$t.SpecVersion) -split ',')[0].Trim()
            $tpmOn = [bool]$t.IsEnabled_InitialValue
        }
    }
    catch { }
    $secureBoot = $null
    try { $secureBoot = [bool](Confirm-SecureBootUEFI -ErrorAction Stop) } catch { }

    # Wie viele Speicherbaenke hat das Board ueberhaupt?
    $slots = 0
    try {
        foreach ($a in (Get-CimInstance Win32_PhysicalMemoryArray -ErrorAction Stop)) {
            $slots += [int]$a.MemoryDevices
        }
    }
    catch { }
    $nics = @()
    try {
        $nics = @(Get-CimInstance Win32_NetworkAdapter -Filter 'PhysicalAdapter=TRUE AND NetEnabled=TRUE' -ErrorAction Stop |
                Select-Object -Property *)
    }
    catch { }

    return @{
        CPU         = $cpu
        GPUs        = $gpus
        OS          = $os
        Disks       = $disks
        Board       = $board
        BIOS        = $bios
        Modules     = $mods
        MediaByDisk = $media
        VramByName  = $vram
        DisplayVer  = $display
        UBR         = $ubr
        Nics        = $nics
        Battery     = $battery
        TpmVersion  = $tpmVer
        TpmEnabled  = $tpmOn
        SecureBoot  = $secureBoot
        MemorySlots = $slots
    }
}

function Set-HardwareCacheFromRaw {
    # Macht aus dem Rohergebnis der Abfrage den fertigen Zwischenspeicher.
    $raw = @(Get-CacheEntryData -Key 'HardwareRaw')
    if ($raw.Count -eq 0 -or -not ($raw[0] -is [hashtable])) {
        Write-Log (Get-Text 'LogHwFailed') 'WARNING'
        return $null
    }
    $info = $raw[0]
    # Lebendprobe: ein Lesezugriff muss echten Inhalt liefern. Eine leere
    # Hashtabelle waere zwar formal richtig, aber unbrauchbar.
    $alive = $false
    try { $alive = [bool]($info.Contains('CPU') -and ($info.CPU -or $info.OS -or @($info.GPUs).Count -gt 0)) } catch { $alive = $false }
    if (-not $alive) {
        Write-Log (Get-Text 'LogHwFailed') 'WARNING'
        return $null
    }
    $info['Timestamp'] = Get-Date
    $info['Expiry'] = (Get-Date).AddMinutes(10)
    $script:Config.HardwareCache = $info
    Write-Log (Get-Text 'LogHwCached') 'SYSTEM'
    return $info
}

function Set-HardwareFailedCache {
    # Geht weder im Hintergrund noch synchron etwas, wird ein Fehleintrag mit
    # zwei Minuten Haltbarkeit abgelegt. Ohne ihn waere Request-HardwareInfo
    # dauerhaft 'nicht bereit' und die Ansicht wuerde sich ueber ihren eigenen
    # Rueckruf endlos neu aufbauen.
    $script:Config.HardwareCache = @{
        Failed    = $true
        Timestamp = Get-Date
        Expiry    = (Get-Date).AddMinutes(2)
    }
}

function Request-HardwareInfo {
    # $true  = die Daten stehen bereit (Get-HardwareInfo liefert sofort).
    # $false = die Abfrage laeuft im Hintergrund; $OnReady wird danach gerufen.
    param([scriptblock]$OnReady = $null, [switch]$ForceRefresh)

    if (-not $ForceRefresh -and $null -ne $script:Config.HardwareCache -and
        (Get-Date) -lt $script:Config.HardwareCache.Expiry) {
        return $true
    }

    $cb = $OnReady
    $after = {
        $ok = Set-HardwareCacheFromRaw
        # Hat der Hintergrund nichts Brauchbares geliefert, wird einmal
        # synchron nachgemessen - lieber eine kurze Pause als eine leere
        # Hardware-Seite.
        if (-not $ok) {
            Clear-DataCache -Key 'HardwareRaw'
            if (-not (Get-HardwareInfo -ForceRefresh)) { Set-HardwareFailedCache }
        }
        if ($cb) { & $cb }
    }.GetNewClosure()

    $ready = Request-CachedData -Key 'HardwareRaw' -TtlSeconds 600 -Force:$ForceRefresh `
        -Loader $script:HardwareQuery -OnReady $after
    if ($ready) {
        if (-not (Set-HardwareCacheFromRaw)) {
            Clear-DataCache -Key 'HardwareRaw'
            if (-not (Get-HardwareInfo -ForceRefresh)) { Set-HardwareFailedCache }
        }
    }
    return $ready
}

function Get-HardwareInfo {
    # Synchrone Fassung - fuer Aufrufer, die das Ergebnis sofort brauchen
    # (Bericht, Export). Die Ansicht benutzt Request-HardwareInfo.
    param([switch]$ForceRefresh)

    if (-not $ForceRefresh -and $null -ne $script:Config.HardwareCache -and
        (Get-Date) -lt $script:Config.HardwareCache.Expiry) {
        return $script:Config.HardwareCache
    }

    try {
        $info = @(& $script:HardwareQuery) | Where-Object { $_ -is [hashtable] } | Select-Object -First 1
        if (-not $info) { throw 'CIM query failed' }
        $info['Timestamp'] = Get-Date
        $info['Expiry'] = (Get-Date).AddMinutes(10)
        $script:Config.HardwareCache = $info
        $script:DataCache['HardwareRaw'] = @{ Time = Get-Date; Data = @($info) }
        Write-Log (Get-Text 'LogHwCached') 'SYSTEM'
    }
    catch {
        Write-Log "$(Get-Text 'LogHwFailed'): $($_.Exception.Message)" 'WARNING'
        return $null
    }
    return $script:Config.HardwareCache
}

# Live memory snapshot - never served from the hardware cache
function Get-CpuUsageFast {
    # GetSystemTimes deltas: ~0.05 ms instead of ~80 ms for Win32_Processor.
    try {
        $idle = 0L; $kernel = 0L; $user = 0L
        if (-not [EBHost.Perf]::GetSystemTimes([ref]$idle, [ref]$kernel, [ref]$user)) {
            return [int]$script:CurrentStats.CPU
        }
        if ($null -eq $script:CpuLastIdle) {
            $script:CpuLastIdle = $idle; $script:CpuLastKernel = $kernel; $script:CpuLastUser = $user
            return [int]$script:CurrentStats.CPU
        }
        $dIdle = $idle - $script:CpuLastIdle
        $dKernel = $kernel - $script:CpuLastKernel
        $dUser = $user - $script:CpuLastUser
        $script:CpuLastIdle = $idle; $script:CpuLastKernel = $kernel; $script:CpuLastUser = $user

        $total = $dKernel + $dUser          # kernel time already contains idle
        if ($total -le 0) { return [int]$script:CurrentStats.CPU }
        $usage = (1.0 - ([double]$dIdle / [double]$total)) * 100.0
        return [int][math]::Round([math]::Max(0, [math]::Min(100, $usage)))
    }
    catch { return [int]$script:CurrentStats.CPU }
}

function Get-MemoryFast {
    # GlobalMemoryStatusEx instead of Win32_OperatingSystem (~0.02 ms vs ~70 ms)
    try {
        $m = New-Object EBHost.MEMORYSTATUSEX
        if (-not [EBHost.Perf]::GlobalMemoryStatusEx($m)) { return $null }
        $total = [double]$m.ullTotalPhys
        $free = [double]$m.ullAvailPhys
        if ($total -le 0) { return $null }
        return @{
            TotalGB = [math]::Round($total / 1GB, 2)
            FreeGB  = [math]::Round($free / 1GB, 2)
            UsedGB  = [math]::Round(($total - $free) / 1GB, 2)
            Percent = [int]$m.dwMemoryLoad
        }
    }
    catch { return $null }
}

function Get-MemorySnapshot {
    $fast = Get-MemoryFast
    if ($fast) { return $fast }
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        if (-not $os -or -not $os.TotalVisibleMemorySize) { return $null }
        $totalKb = [double]$os.TotalVisibleMemorySize
        $freeKb = [double]$os.FreePhysicalMemory
        return @{
            TotalGB = [math]::Round($totalKb / 1MB, 2)
            FreeGB  = [math]::Round($freeKb / 1MB, 2)
            UsedGB  = [math]::Round(($totalKb - $freeKb) / 1MB, 2)
            Percent = [int][math]::Round((($totalKb - $freeKb) / $totalKb) * 100)
        }
    }
    catch { return $null }
}

function Get-PhysicalNetworkInterface {
    # Hyper-V / Docker / VPN / TAP adapters mirror the traffic of the physical
    # NIC - counting them inflates the readout two- or threefold.
    $list = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($ni in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
            if ($ni.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback) { continue }
            if ($ni.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Tunnel) { continue }
            if ($ni.Description -match 'Virtual|VMware|VirtualBox|Hyper-V|VPN|TAP-|TAP Windows|WAN Miniport|Npcap|Loopback|Bluetooth|Docker') { continue }
            if ($ni.Name -match 'vEthernet|VirtualBox|VMware|Docker') { continue }
            $list.Add($ni)
        }
        if ($list.Count -eq 0) {
            # Der Filter hat alles verworfen (z. B. NIC hinter einem
            # Hyper-V-Switch oder eine Beschreibung mit 'Virtual' darin).
            # Lieber etwas zu viel messen als dauerhaft 0,00 anzeigen.
            foreach ($ni in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
                if ($ni.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback) { continue }
                if ($ni.OperationalStatus -ne [System.Net.NetworkInformation.OperationalStatus]::Up) { continue }
                $list.Add($ni)
            }
        }
    }
    catch { }
    return , $list.ToArray()
}

function Get-NetworkBytesPerf {
    # Rueckfallquelle: der rohe Leistungsindikator zaehlt auch dann, wenn
    # GetIPv4Statistics bei manchen Treibern bei 0 stehen bleibt.
    try {
        $sum = 0.0
        $inst = Get-CimInstance -ClassName Win32_PerfRawData_Tcpip_NetworkInterface -ErrorAction Stop
        foreach ($i in $inst) {
            if ($i.Name -match 'Loopback|isatap|Teredo|Pseudo|QoS') { continue }
            $sum += [double]$i.BytesTotalPersec
        }
        return $sum
    }
    catch { return 0.0 }
}

function Get-NetworkTotalBytes {
    # Liefert den Gesamtzaehler in Byte. Reihenfolge: verwaltete Statistik
    # (billig), sonst Leistungsindikator. Die funktionierende Quelle wird
    # gemerkt, damit nicht jede Sekunde beides versucht wird.
    $total = 0.0
    if ($script:NetSource -ne 'Perf') {
        try {
            $now0 = Get-Date
            if ($null -eq $script:NetNicCache -or $null -eq $script:NetNicScan -or
                ($now0 - $script:NetNicScan).TotalSeconds -ge 30) {
                $script:NetNicCache = @(Get-PhysicalNetworkInterface)
                $script:NetNicScan = $now0
            }
            foreach ($ni in $script:NetNicCache) {
                if ($ni.OperationalStatus -ne [System.Net.NetworkInformation.OperationalStatus]::Up) { continue }
                $b = 0.0
                try {
                    # GetIPStatistics zaehlt IPv4 UND IPv6 - die alte Variante
                    # sah reinen IPv6-Verkehr ueberhaupt nicht.
                    $st = $ni.GetIPStatistics()
                    $b = [double]$st.BytesReceived + [double]$st.BytesSent
                }
                catch { $b = 0.0 }
                if ($b -le 0) {
                    try {
                        $st4 = $ni.GetIPv4Statistics()
                        $b = [double]$st4.BytesReceived + [double]$st4.BytesSent
                    }
                    catch { $b = 0.0 }
                }
                $total += $b
            }
        }
        catch { $total = 0.0 }
        if ($total -gt 0) {
            $script:NetSource = 'Managed'
            return $total
        }
    }
    if ($script:NetSource -ne 'Managed') {
        $perf = Get-NetworkBytesPerf
        if ($perf -gt 0) {
            $script:NetSource = 'Perf'
            return $perf
        }
    }
    return 0.0
}

function Format-NetRate {
    # Unter 1 MB/s in KB/s anzeigen - sonst steht bei normalem Hintergrund-
    # verkehr dauerhaft '0,00 MB/s' im Kopf, obwohl Daten fliessen.
    param([double]$MBs)
    # 10-Gbit- und Loopback-Spitzen sonst als vierstellige MB/s-Zahl - die
    # passt nicht in das 150 px breite Kopfelement.
    if ($MBs -ge 1024) { return ('{0:F2} GB/s' -f ($MBs / 1024)) }
    if ($MBs -ge 1) { return ('{0:F2} MB/s' -f $MBs) }
    $kb = $MBs * 1024
    if ($kb -ge 10) { return ('{0:F0} KB/s' -f $kb) }
    if ($kb -ge 0.1) { return ('{0:F1} KB/s' -f $kb) }
    return '0 KB/s'
}

function Get-NetworkThroughputMBs {
    # Managed statistics / Leistungsindikator - kein WMI-Aufruf pro Takt,
    # solange die verwaltete Quelle liefert.
    try {
        $now = Get-Date
        # Der Leistungsindikator ist teurer: hoechstens alle 2 s abfragen.
        if ($script:NetSource -eq 'Perf' -and $script:NetLastTime -and
            ($now - $script:NetLastTime).TotalSeconds -lt 1.8) {
            return [double]$script:CurrentStats.Net
        }

        $totalBytes = Get-NetworkTotalBytes
        if ($totalBytes -le 0) { return 0.0 }

        if ($null -eq $script:NetLastBytes -or $null -eq $script:NetLastTime) {
            $script:NetLastBytes = $totalBytes
            $script:NetLastTime = $now
            return 0.0
        }

        $seconds = ($now - $script:NetLastTime).TotalSeconds
        if ($seconds -le 0.05) { return [double]$script:CurrentStats.Net }

        $delta = $totalBytes - $script:NetLastBytes
        $script:NetLastBytes = $totalBytes
        $script:NetLastTime = $now

        if ($delta -lt 0) { return 0.0 }   # counter wrapped / adapter reset
        # Drei Nachkommastellen: 2 KB/s waren vorher auf 0,00 gerundet.
        return [math]::Round(($delta / 1MB) / $seconds, 3)
    }
    catch { return 0.0 }
}

#endregion 3. CORE HELPERS


#region 4. DRAWING ENGINE

function Invoke-SparklineDraw {
    param($e, $History, [System.Drawing.Color]$Color, [System.Drawing.Rectangle]$Rect)

    if (-not $e -or -not $History -or $History.Count -lt 2) { return }
    if ($Rect.Width -le 0 -or $Rect.Height -le 0) { return }

    $path = $null; $brush = $null; $pen = $null
    try {
        $g = $e.Graphics
        $g.SmoothingMode = 'AntiAlias'

        $divisor = [math]::Max(1, ($script:SparklineHistory.BufferSize - 1))
        $step = $Rect.Width / $divisor

        $pts = New-Object 'System.Drawing.PointF[]' $History.Count
        for ($i = 0; $i -lt $History.Count; $i++) {
            $value = [math]::Max(0, [math]::Min(100, [double]$History[$i]))
            $x = $Rect.X + ($i * $step)
            $y = $Rect.Y + $Rect.Height - ($value / 100 * $Rect.Height)
            $pts[$i] = New-Object System.Drawing.PointF([single]$x, [single]$y)
        }

        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddLines($pts)
        $path.AddLine($pts[$History.Count - 1].X, [single]($Rect.Y + $Rect.Height), $pts[0].X, [single]($Rect.Y + $Rect.Height))
        $path.CloseFigure()

        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $Rect,
            [System.Drawing.Color]::FromArgb(60, $Color),
            [System.Drawing.Color]::Transparent,
            90)
        $g.FillPath($brush, $path)

        $pen = New-Object System.Drawing.Pen($Color, 2)
        $g.DrawLines($pen, $pts)
    }
    catch { }
    finally {
        if ($pen) { $pen.Dispose() }
        if ($brush) { $brush.Dispose() }
        if ($path) { $path.Dispose() }
    }
}

function Invoke-GlassSheen {
    # WinForms kann hinter einem Bedienelement nichts weichzeichnen - einen
    # echten Glaseffekt gibt es also nicht. Der Eindruck entsteht aus drei
    # duennen Lagen: ein Helligkeitsverlauf von oben nach unten, eine hellere
    # Oberkante und optional die feine Aussenkontur.
    param(
        [System.Drawing.Graphics]$Graphics,
        [int]$Width,
        [int]$Height,
        [int]$Radius = 12,
        [int]$Alpha = 18,
        [switch]$Border,
        $BorderColor = $null
    )
    if (-not $Graphics -or $Width -le 8 -or $Height -le 8) { return }

    $path = $null; $brush = $null; $penTop = $null; $penEdge = $null
    try {
        $Graphics.SmoothingMode = 'AntiAlias'
        $d = [int][math]::Max(6, $Radius * 2)
        if ($d -gt ($Width - 2)) { $d = $Width - 2 }
        if ($d -gt ($Height - 2)) { $d = $Height - 2 }
        $w = $Width - 1
        $h = $Height - 1

        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $d, $d, 180, 90)
        $path.AddArc(($w - $d), 0, $d, $d, 270, 90)
        $path.AddArc(($w - $d), ($h - $d), $d, $d, 0, 90)
        $path.AddArc(0, ($h - $d), $d, $d, 90, 90)
        $path.CloseFigure()

        # Verlauf nur ueber die obere Haelfte, danach vollstaendig klar
        $gh = [int][math]::Max(4, [math]::Round($Height * 0.6))
        $rect = New-Object System.Drawing.Rectangle(0, 0, $Width, $gh)
        $c1 = [System.Drawing.Color]::FromArgb($Alpha, 255, 255, 255)
        $c2 = [System.Drawing.Color]::FromArgb(0, 255, 255, 255)
        $brush = New-Object -TypeName 'System.Drawing.Drawing2D.LinearGradientBrush' `
            -ArgumentList $rect, $c1, $c2, 90.0
        $state = $Graphics.Save()
        $Graphics.SetClip($path, [System.Drawing.Drawing2D.CombineMode]::Intersect)
        $Graphics.FillRectangle($brush, 0, 0, $Width, $gh)
        $Graphics.Restore($state)

        # Lichtkante oben - macht aus der Flaeche eine Scheibe
        $penTop = New-Object -TypeName 'System.Drawing.Pen' `
            -ArgumentList ([System.Drawing.Color]::FromArgb(($Alpha + 24), 255, 255, 255)), 1.0
        $Graphics.DrawLine($penTop, ($Radius - 2), 1, ($Width - $Radius + 1), 1)

        if ($Border) {
            $bc = $BorderColor
            if (-not $bc) { $bc = $script:Theme.Border }
            $penEdge = New-Object -TypeName 'System.Drawing.Pen' -ArgumentList $bc, 1.0
            $Graphics.DrawPath($penEdge, $path)
        }
    }
    catch { }
    finally {
        foreach ($o in @($path, $brush, $penTop, $penEdge)) { if ($o) { $o.Dispose() } }
    }
}

function Invoke-GaugeDraw {
    param(
        [System.Windows.Forms.PaintEventArgs]$e,
        [int]$Value,
        [System.Drawing.Color]$Color,
        [System.Drawing.Rectangle]$Rect,
        [string]$Label
    )

    $penBg = $null; $penVal = $null; $fValue = $null; $fLabel = $null
    $sf = $null; $brushValue = $null; $brushLabel = $null
    try {
        $g = $e.Graphics
        $g.SmoothingMode = 'AntiAlias'
        $Value = [math]::Max(0, [math]::Min(100, $Value))

        $penBg = New-Object System.Drawing.Pen($script:Theme.BgTertiary, 10)
        $g.DrawArc($penBg, $Rect, 135, 270)

        $activeColor = $Color
        if ($Value -ge 90) { $activeColor = $script:Theme.Error }
        elseif ($Value -ge 70) { $activeColor = $script:Theme.Warning }

        $angle = ($Value / 100) * 270
        if ($angle -gt 0) {
            $penVal = New-Object System.Drawing.Pen($activeColor, 10)
            $penVal.StartCap = 'Round'
            $penVal.EndCap = 'Round'
            $g.DrawArc($penVal, $Rect, 135, $angle)
        }

        $fValue = (Get-AppFont -Size 18 -Style 'Bold')
        $fLabel = (Get-AppFont -Size 8)
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = 'Center'
        $sf.LineAlignment = 'Center'

        $brushValue = New-Object System.Drawing.SolidBrush($activeColor)
        $brushLabel = New-Object System.Drawing.SolidBrush($script:Theme.TextMuted)

        $textRect = [System.Drawing.RectangleF]$Rect
        $g.DrawString("$Value%", $fValue, $brushValue, $textRect, $sf)

        $rectLabel = [System.Drawing.RectangleF]$Rect
        $rectLabel.Y += 35
        $g.DrawString($Label, $fLabel, $brushLabel, $rectLabel, $sf)
    }
    catch { }
    finally {
        # $fValue / $fLabel come from the shared font cache - disposing them
        # here would hand every later caller a dead Font ("Invalid parameter").
        if ($penBg) { $penBg.Dispose() }
        if ($penVal) { $penVal.Dispose() }
        if ($sf) { $sf.Dispose() }
        if ($brushValue) { $brushValue.Dispose() }
        if ($brushLabel) { $brushLabel.Dispose() }
    }
}

#endregion 4. DRAWING ENGINE


#region 5. UI HELPERS, DIALOGS, BUILDERS

# --- Dialogs ------------------------------------------------------------------
function Show-WarningDialog {
    param(
        [string]$Title,
        [string]$Message
    )

    $dlg = New-Object System.Windows.Forms.Form
    try {
        $dlg.Size = New-Object System.Drawing.Size(460, 240)
        $dlg.StartPosition = 'CenterParent'
        $dlg.FormBorderStyle = 'None'
        $dlg.BackColor = $script:Theme.Warning
        $dlg.ShowInTaskbar = $false

        $inner = New-Object System.Windows.Forms.Panel
        $inner.Location = New-Object System.Drawing.Point(3, 3)
        $inner.Size = New-Object System.Drawing.Size(454, 234)
        $inner.BackColor = $script:Theme.BgSecondary
        $dlg.Controls.Add($inner)

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text = "{icon:warning} $Title"
        $lblTitle.Font = (Get-AppFont -Size 13 -Style 'Bold')
        $lblTitle.ForeColor = $script:Theme.Warning
        $lblTitle.Location = New-Object System.Drawing.Point(20, 20)
        $lblTitle.AutoSize = $true
        $inner.Controls.Add($lblTitle)

        $lblMsg = New-Object System.Windows.Forms.Label
        $lblMsg.Text = $Message
        $lblMsg.Font = (Get-AppFont -Size 10)
        $lblMsg.ForeColor = $script:Theme.TextSecondary
        $lblMsg.Location = New-Object System.Drawing.Point(20, 55)
        $lblMsg.Size = New-Object System.Drawing.Size(410, 75)
        $inner.Controls.Add($lblMsg)

        $chk = New-Object System.Windows.Forms.CheckBox
        $chk.Text = "  $(Get-Text 'DlgRisk')"
        $chk.Font = (Get-AppFont -Size 9 -Style 'Bold')
        $chk.ForeColor = $script:Theme.Warning
        $chk.Location = New-Object System.Drawing.Point(20, 140)
        $chk.AutoSize = $true
        $inner.Controls.Add($chk)

        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Text = Get-Text 'DlgContinue'
        $btnOK.Size = New-Object System.Drawing.Size(120, 36)
        $btnOK.Location = New-Object System.Drawing.Point(180, 180)
        $btnOK.BackColor = $script:Theme.Warning
        $btnOK.ForeColor = [System.Drawing.Color]::Black
        $btnOK.FlatStyle = 'Flat'
        $btnOK.Enabled = $false
        $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $inner.Controls.Add($btnOK)

        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = Get-Text 'Cancel'
        $btnCancel.Size = New-Object System.Drawing.Size(120, 36)
        $btnCancel.Location = New-Object System.Drawing.Point(310, 180)
        $btnCancel.BackColor = $script:Theme.BgTertiary
        $btnCancel.ForeColor = $script:Theme.TextPrimary
        $btnCancel.FlatStyle = 'Flat'
        $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $inner.Controls.Add($btnCancel)

        $chk.Add_CheckedChanged({ $btnOK.Enabled = $chk.Checked }.GetNewClosure())

        $dlg.AcceptButton = $btnOK
        $dlg.CancelButton = $btnCancel

        # Der Symbollauf stand bisher HINTER der ersten Rueckgabe und lief
        # deshalb nie - im Titel stand woertlich '{icon:warning}'.
        Update-ControlIcons -Root $dlg -Size 16
        if ($script:MainForm -and -not $script:MainForm.IsDisposed) {
            return $dlg.ShowDialog($script:MainForm)
        }
        return $dlg.ShowDialog()
    }
    finally {
        $dlg.Dispose()
    }
}

function Show-AppDialog {
    # Eigenes Fenster im Dunkeldesign. MessageBox brachte ein helles
    # Systemfenster mitten in eine dunkle Oberflaeche - bei 18 Rueckfragen
    # faellt das jedes Mal auf.
    param(
        [string]$Title,
        [string]$Message,
        [string]$Icon = 'help',
        $Accent = $null,
        [switch]$Question
    )
    if (-not $Accent) { $Accent = $script:Theme.Accent }

    $dlg = New-Object System.Windows.Forms.Form
    try {
        $dlg.Size = New-Object System.Drawing.Size(470, 220)
        $dlg.StartPosition = 'CenterParent'
        $dlg.FormBorderStyle = 'None'
        $dlg.BackColor = $Accent
        $dlg.ShowInTaskbar = $false
        $dlg.KeyPreview = $true

        $inner = New-Object System.Windows.Forms.Panel
        $inner.Location = New-Object System.Drawing.Point(3, 3)
        $inner.Size = New-Object System.Drawing.Size(464, 214)
        $inner.BackColor = $script:Theme.BgSecondary
        $dlg.Controls.Add($inner)

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text = "{icon:$Icon} $Title"
        $lblTitle.Font = (Get-AppFont -Size 13 -Style 'Bold')
        $lblTitle.ForeColor = $Accent
        $lblTitle.Location = New-Object System.Drawing.Point(20, 20)
        $lblTitle.AutoSize = $true
        $lblTitle.BackColor = [System.Drawing.Color]::Transparent
        $inner.Controls.Add($lblTitle)

        $lblMsg = New-Object System.Windows.Forms.Label
        $lblMsg.Text = $Message
        $lblMsg.Font = (Get-AppFont -Size 10)
        $lblMsg.ForeColor = $script:Theme.TextSecondary
        $lblMsg.Location = New-Object System.Drawing.Point(20, 58)
        $lblMsg.Size = New-Object System.Drawing.Size(420, 86)
        $lblMsg.BackColor = [System.Drawing.Color]::Transparent
        $inner.Controls.Add($lblMsg)

        $mkDlgBtn = {
            param($text, $x, $back, $fore, $result)
            $b = New-Object System.Windows.Forms.Button
            $b.Text = $text
            $b.Size = New-Object System.Drawing.Size(120, 36)
            $b.Location = New-Object System.Drawing.Point($x, 158)
            $b.BackColor = $back
            $b.ForeColor = $fore
            $b.FlatStyle = 'Flat'
            $b.FlatAppearance.BorderSize = 0
            $b.Font = (Get-AppFont -Size 10 -Style 'Bold')
            $b.Cursor = 'Hand'
            $b.DialogResult = $result
            $inner.Controls.Add($b)
            Set-RoundedRegion -Control $b -Radius 6
            return $b
        }

        if ($Question) {
            $btnYes = & $mkDlgBtn (Get-Text 'Yes') 190 $Accent $script:Theme.TextWhite ([System.Windows.Forms.DialogResult]::OK)
            $btnNo = & $mkDlgBtn (Get-Text 'No') 320 $script:Theme.BgTertiary $script:Theme.TextPrimary ([System.Windows.Forms.DialogResult]::Cancel)
            $dlg.AcceptButton = $btnYes
            $dlg.CancelButton = $btnNo
        }
        else {
            $btnOk = & $mkDlgBtn 'OK' 320 $Accent $script:Theme.TextWhite ([System.Windows.Forms.DialogResult]::OK)
            $dlg.AcceptButton = $btnOk
            $dlg.CancelButton = $btnOk
        }

        Update-ControlIcons -Root $dlg -Size 16
        $res = if ($script:MainForm -and -not $script:MainForm.IsDisposed) {
            $dlg.ShowDialog($script:MainForm)
        }
        else { $dlg.ShowDialog() }
        return ($res -eq [System.Windows.Forms.DialogResult]::OK)
    }
    catch {
        # Geht hier etwas schief, lieber das Systemfenster als gar keine Frage
        if ($Question) {
            return ([System.Windows.Forms.MessageBox]::Show($Message, $Title,
                    [System.Windows.Forms.MessageBoxButtons]::YesNo) -eq [System.Windows.Forms.DialogResult]::Yes)
        }
        [void][System.Windows.Forms.MessageBox]::Show($Message, $Title)
        return $true
    }
    finally { $dlg.Dispose() }
}

function Show-Confirm {
    param([string]$Message, [string]$Title = '')
    if (-not $Title) { $Title = Get-Text 'DlgConfirm' }
    return (Show-AppDialog -Title $Title -Message $Message -Icon 'help' `
            -Accent $script:Theme.Warning -Question)
}

function Show-Info {
    param([string]$Message, [string]$Title = '')
    if (-not $Title) { $Title = Get-Text 'Info' }
    [void](Show-AppDialog -Title $Title -Message $Message -Icon 'info')
}

# --- Busy overlay -------------------------------------------------------------
# Long operations keep running on the UI thread (a runspace would not be able to
# touch the controls anyway), so instead of letting the window look frozen we put
# a modal-looking overlay over the content area, pump DoEvents from the worker
# loops and let the user cancel where cancelling is safe.
$script:BusyOverlay = $null
$script:BusyCard = $null
$script:BusyTitleLbl = $null
$script:BusyStatusLbl = $null
$script:BusyBar = $null
$script:BusyCancelBtn = $null
$script:BusyDepth = 0
$script:BusyCancel = $false
$script:BusyPhase = 0
$script:BusyPercent = -1
$script:BusyTimer = $null
$script:BusyStack = New-Object System.Collections.Generic.List[object]

function Set-BusyCardCenter {
    if (-not $script:BusyOverlay -or -not $script:BusyCard) { return }
    if ($script:BusyOverlay.IsDisposed -or $script:BusyCard.IsDisposed) { return }
    $x = [math]::Max(10, [int](($script:BusyOverlay.Width - $script:BusyCard.Width) / 2))
    $y = [math]::Max(10, [int](($script:BusyOverlay.Height - $script:BusyCard.Height) / 2) - 20)
    $script:BusyCard.Location = New-Object System.Drawing.Point($x, $y)
}

function Initialize-BusyOverlay {
    if ($script:BusyOverlay -and -not $script:BusyOverlay.IsDisposed) { return }
    if (-not $script:MainForm -or $script:MainForm.IsDisposed) { return }
    if (-not $script:pnlContent -or $script:pnlContent.IsDisposed) { return }

    $ov = New-Object System.Windows.Forms.Panel
    $ov.Location = $script:pnlContent.Location
    $ov.Size = $script:pnlContent.Size
    $ov.Anchor = 'Top,Bottom,Left,Right'
    $ov.BackColor = Get-PaletteColor -Name 'Base' -Toward 'Black' -Ratio 0.30
    $ov.Cursor = [System.Windows.Forms.Cursors]::AppStarting
    $ov.Visible = $false
    Set-DoubleBuffered -Control $ov
    $script:MainForm.Controls.Add($ov)
    $script:BusyOverlay = $ov

    $card = New-Object System.Windows.Forms.Panel
    $card.Size = New-Object System.Drawing.Size(520, 196)
    $card.BackColor = $script:Theme.BgSecondary
    Set-DoubleBuffered -Control $card
    $card.Add_Paint({
            param($s, $e)
            $pen = $null
            try {
                $e.Graphics.SmoothingMode = 'AntiAlias'
                $pen = New-Object System.Drawing.Pen($script:Theme.Accent, 1.5)
                $r = New-Object System.Drawing.Rectangle(1, 1, $s.Width - 3, $s.Height - 3)
                $e.Graphics.DrawRectangle($pen, $r)
            }
            catch { }
            finally { if ($pen) { $pen.Dispose() } }
        })
    $ov.Controls.Add($card)
    $script:BusyCard = $card
    Set-RoundedRegion -Control $card -Radius 12

    $lblT = New-Object System.Windows.Forms.Label
    $lblT.Location = New-Object System.Drawing.Point(28, 24)
    $lblT.Size = New-Object System.Drawing.Size(464, 30)
    $lblT.Font = Get-AppFont -Size 14 -Style 'Bold'
    $lblT.ForeColor = $script:Theme.TextPrimary
    $lblT.BackColor = [System.Drawing.Color]::Transparent
    $lblT.Text = (Get-Text 'BusyTitle')
    [void](Set-ControlIcon -Control $lblT -Glyph 'hourglass' -Size 20 -Color $script:Theme.Cyan)
    $card.Controls.Add($lblT)
    $script:BusyTitleLbl = $lblT

    $lblS = New-Object System.Windows.Forms.Label
    $lblS.Location = New-Object System.Drawing.Point(28, 58)
    $lblS.Size = New-Object System.Drawing.Size(464, 40)
    $lblS.Font = Get-AppFont -Size 9.5
    $lblS.ForeColor = $script:Theme.TextSecondary
    $lblS.BackColor = [System.Drawing.Color]::Transparent
    $card.Controls.Add($lblS)
    $script:BusyStatusLbl = $lblS

    $bar = New-Object System.Windows.Forms.Panel
    $bar.Location = New-Object System.Drawing.Point(28, 104)
    $bar.Size = New-Object System.Drawing.Size(464, 12)
    $bar.BackColor = $script:Theme.BgTertiary
    Set-DoubleBuffered -Control $bar
    $bar.Add_Paint({
            param($s, $e)
            $br = $null
            try {
                $w = [math]::Max(1, $s.Width)
                $e.Graphics.SmoothingMode = 'AntiAlias'
                if ($script:BusyPercent -ge 0) {
                    $fw = [int]([math]::Min(100, $script:BusyPercent) / 100.0 * $w)
                    $x = 0
                }
                else {
                    # Indeterminate: a 150 px chunk sliding across the track
                    $fw = 150
                    $x = (($script:BusyPhase * 16) % ($w + $fw)) - $fw
                }
                if ($fw -lt 1) { return }
                $rect = New-Object System.Drawing.Rectangle($x, 0, $fw, $s.Height)
                $br = New-BrandGradientBrush -Rect $rect
                if ($br) { $e.Graphics.FillRectangle($br, $rect) }
            }
            catch { }
            finally { if ($br) { $br.Dispose() } }
        })
    $card.Controls.Add($bar)
    $script:BusyBar = $bar

    $lblH = New-Object System.Windows.Forms.Label
    $lblH.Location = New-Object System.Drawing.Point(28, 126)
    $lblH.Size = New-Object System.Drawing.Size(320, 22)
    $lblH.Font = Get-AppFont -Size 8.5
    $lblH.ForeColor = $script:Theme.TextMuted
    $lblH.BackColor = [System.Drawing.Color]::Transparent
    $lblH.Text = Get-Text 'BusyHint'
    $card.Controls.Add($lblH)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Size = New-Object System.Drawing.Size(130, 32)
    $btn.Location = New-Object System.Drawing.Point(362, 150)
    $btn.Text = (Get-Text 'Cancel')
    $btn.Font = Get-AppFont -Size 9 -Style 'Bold'
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $script:Theme.BgTertiary
    $btn.ForeColor = $script:Theme.TextPrimary
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    [void](Set-ControlIcon -Control $btn -Glyph 'close' -Size 14)
    $btn.Add_Click({
            $script:BusyCancel = $true
            $script:BusyCancelBtn.Enabled = $false
            Update-BusyOverlay -Status (Get-Text 'BusyCancelled')
        })
    $card.Controls.Add($btn)
    Set-RoundedRegion -Control $btn -Radius 8
    $script:BusyCancelBtn = $btn

    $ov.Add_SizeChanged({ Set-BusyCardCenter })
    Set-BusyCardCenter

    # 25 fps animation for the indeterminate bar. Without it the bar only moved
    # when a worker loop happened to call Update-BusyOverlay - which looks like
    # a freeze during long single steps.
    $t = New-Object System.Windows.Forms.Timer
    $t.Interval = 40
    $t.Add_Tick({
            if (-not $script:BusyOverlay -or $script:BusyOverlay.IsDisposed) { return }
            if (-not $script:BusyOverlay.Visible) { return }
            $script:BusyPhase++
            if ($script:BusyPercent -lt 0 -and $script:BusyBar -and -not $script:BusyBar.IsDisposed) {
                $script:BusyBar.Invalidate()
            }
        })
    $script:BusyTimer = $t
}

function Show-BusyOverlay {
    param([string]$Title = '', [string]$Status = '', [switch]$Cancellable)

    Initialize-BusyOverlay
    if (-not $script:BusyOverlay -or $script:BusyOverlay.IsDisposed) { return }

    $script:BusyDepth++
    if ($script:BusyDepth -eq 1) { $script:BusyCancel = $false }
    # Nested calls (Auto-Optimize -> Quick Clean) must not steal the caption of
    # the outer operation: remember it and restore it when the inner one ends.
    $script:BusyStack.Add([pscustomobject]@{
            Title      = $script:BusyTitleLbl.Text
            Status     = $script:BusyStatusLbl.Text
            Cancelable = $script:BusyCancelBtn.Visible
        })
    $script:BusyPercent = -1
    $script:BusyPhase = 0

    if (-not $Title) { $Title = Get-Text 'BusyTitle' }
    $script:BusyTitleLbl.Text = $Title
    $script:BusyStatusLbl.Text = $Status
    $script:BusyCancelBtn.Enabled = $true
    $script:BusyCancelBtn.Visible = [bool]$Cancellable

    Set-BusyCardCenter
    $script:BusyOverlay.Visible = $true
    $script:BusyOverlay.BringToFront()
    if ($script:BusyTimer) { $script:BusyTimer.Start() }
    $script:BusyOverlay.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Update-BusyOverlay {
    param([string]$Status, [int]$Percent = -1, [switch]$KeepPercent)

    if (-not $script:BusyOverlay -or $script:BusyOverlay.IsDisposed) { return }
    if (-not $script:BusyOverlay.Visible) { return }

    if (-not $script:BusyTimer -or -not $script:BusyTimer.Enabled) { $script:BusyPhase++ }
    if (-not $KeepPercent) { $script:BusyPercent = $Percent }
    if ($PSBoundParameters.ContainsKey('Status')) { $script:BusyStatusLbl.Text = $Status }
    $script:BusyBar.Invalidate()
    [System.Windows.Forms.Application]::DoEvents()
}

function Hide-BusyOverlay {
    if ($script:BusyDepth -gt 0) { $script:BusyDepth-- }

    $prev = $null
    if ($script:BusyStack.Count -gt 0) {
        $prev = $script:BusyStack[$script:BusyStack.Count - 1]
        $script:BusyStack.RemoveAt($script:BusyStack.Count - 1)
    }
    if ($script:BusyDepth -gt 0) {
        if ($prev -and $script:BusyTitleLbl -and -not $script:BusyTitleLbl.IsDisposed) {
            $script:BusyTitleLbl.Text = $prev.Title
            $script:BusyStatusLbl.Text = $prev.Status
            $script:BusyCancelBtn.Visible = $prev.Cancelable
            $script:BusyPercent = -1
        }
        return
    }
    $script:BusyPercent = -1
    if ($script:BusyTimer) { $script:BusyTimer.Stop() }
    if ($script:BusyOverlay -and -not $script:BusyOverlay.IsDisposed) {
        $script:BusyOverlay.Visible = $false
    }
    [System.Windows.Forms.Application]::DoEvents()
}

function Test-BusyCancelled {
    return [bool]$script:BusyCancel
}

# --- Content area -------------------------------------------------------------
function Clear-ContentArea {
    if (-not $script:pnlContent -or $script:pnlContent.IsDisposed) { return }

    $script:pnlContent.SuspendLayout()
    # Snapshot first: disposing a control removes it from the collection we iterate
    $controls = @($script:pnlContent.Controls)
    $script:pnlContent.Controls.Clear()
    foreach ($c in $controls) {
        try { $c.Dispose() } catch { }
    }
    $script:pnlContent.ResumeLayout($false)
    $script:pnlContent.AutoScrollPosition = New-Object System.Drawing.Point(0, 0)

    # Reset view-scoped references so the timer never touches disposed controls
    $script:StatDisk = $null
    $script:StatProc = $null
    $script:GaugeCPU = $null
    $script:GaugeRAM = $null
    $script:GaugeNet = $null
    $script:pnlHealth = $null
    $script:txtHardware = $null
    $script:lstDefender = $null
    $script:txtDefPath = $null
    $script:lstServices = $null
    $script:lstStartup = $null
    $script:lstTasks = $null
    $script:lstProcesses = $null
    $script:lstBackups = $null
    $script:lblBackupSize = $null
    $script:lstChanges = $null
    $script:txtBench = $null
    $script:txtUpdates = $null
    $script:txtNetwork = $null
    $script:SearchBox = $null
    $script:ListFilterLabels = @{}
    $script:GridCards = New-Object System.Collections.Generic.List[object]
    $script:GridOrdered = $null
    $script:GridOrderCount = -1
    $script:GridLastKey = ''
}

# --- Builders -----------------------------------------------------------------
function Add-ViewHeader {
    param(
        [string]$TitleKey,
        [string]$SubtitleKey,
        [string]$Icon
    )

    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Location = New-Object System.Drawing.Point(0, 0)
    # Feste 1200 px waren breiter als der Inhaltsbereich - genau daher kam der
    # waagerechte Scrollbalken am unteren Rand.
    $headW = 1200
    try {
        $avail = $script:pnlContent.ClientSize.Width
        if ($avail -gt 320) { $headW = $avail - 24 }
    }
    catch { }
    $pnl.Size = New-Object System.Drawing.Size($headW, 85)
    $pnl.Anchor = 'Top,Left,Right'
    $pnl.BackColor = [System.Drawing.Color]::Transparent
    $script:pnlContent.Controls.Add($pnl)

    $logoLoaded = $false
    # Eine gemeinsame Textkante - Titel und Untertitel standen 2 px versetzt,
    # und mit Logo klebte der Text fast am Bild.
    $textX = $script:Spacing.lg + 60
    if ($script:Config.LogoPath -and (Test-Path -LiteralPath $script:Config.LogoPath)) {
        try {
            $pic = New-Object System.Windows.Forms.PictureBox
            # Load through a stream copy so the file is not locked
            $bytes = [System.IO.File]::ReadAllBytes($script:Config.LogoPath)
            $ms = New-Object System.IO.MemoryStream(, $bytes)
            $pic.Image = [System.Drawing.Image]::FromStream($ms)
            $pic.SizeMode = 'Zoom'
            $pic.Size = New-Object System.Drawing.Size(64, 64)
            $pic.Location = New-Object System.Drawing.Point($script:Spacing.lg, $script:Spacing.sm)
            $pic.BackColor = [System.Drawing.Color]::Transparent
            $pnl.Controls.Add($pic)
            $textX = $script:Spacing.lg + 80
            $logoLoaded = $true
        }
        catch { $logoLoaded = $false }
    }

    if (-not $logoLoaded) {
        $lblIcon = New-Object System.Windows.Forms.Label
        $lblIcon.Location = New-Object System.Drawing.Point($script:Spacing.lg, 15)
        $lblIcon.Size = New-Object System.Drawing.Size(42, 42)
        $lblIcon.BackColor = [System.Drawing.Color]::Transparent
        if (-not (Set-ControlIcon -Control $lblIcon -Glyph $Icon -Size 38 -Color $script:Theme.Accent -IconOnly)) {
            # Kein Zeichensatz-Rueckfall mehr: Namen wie 'broom' wuerden als Text erscheinen
        $lblIcon.Text = $(if ($Icon -match '^[A-Za-z0-9_:{}]+$') { '' } else { $Icon })
            $lblIcon.Font = (Get-AppFont -Family 'Segoe UI Emoji' -Size 28)
            $lblIcon.AutoSize = $true
        }
        $pnl.Controls.Add($lblIcon)
    }

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = Get-Text $TitleKey
    $lblTitle.Font = (Get-AppFont -Size 22 -Style 'Bold')
    $lblTitle.ForeColor = $script:Theme.TextPrimary
    $lblTitle.Location = New-Object System.Drawing.Point($textX, 6)
    $lblTitle.AutoSize = $true
    $lblTitle.BackColor = [System.Drawing.Color]::Transparent
    $pnl.Controls.Add($lblTitle)

    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Text = Get-Text $SubtitleKey
    $lblSub.Font = (Get-AppFont -Size 11)
    $lblSub.ForeColor = $script:Theme.TextSecondary
    $lblSub.Location = New-Object System.Drawing.Point($textX, 46)
    $lblSub.AutoSize = $true
    $lblSub.BackColor = [System.Drawing.Color]::Transparent
    $pnl.Controls.Add($lblSub)

    $line = New-Object System.Windows.Forms.Panel
    $line.Location = New-Object System.Drawing.Point($script:Spacing.lg, 78)
    $line.Size = New-Object System.Drawing.Size(([math]::Max(300, $pnl.Width - 24)), 3)
    $line.BackColor = [System.Drawing.Color]::Transparent
    $line.Anchor = 'Top,Left,Right'
    $line.Add_Paint({
            param($s, $e)
            $br = $null
            try {
                $rect = New-Object System.Drawing.Rectangle(0, 0, [math]::Max(1, $s.Width), $s.Height)
                $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                    $rect, $script:Theme.Accent, $script:Theme.BgPrimary, 0.0)
                $e.Graphics.FillRectangle($br, $rect)
            }
            catch { }
            finally { if ($br) { $br.Dispose() } }
        })
    $pnl.Controls.Add($line)
}

function Test-TweakApplied {
    # Liest die Zielwerte zurueck und meldet, ob eine Karte bereits greift.
    # 'na' bedeutet: nicht pruefbar (z. B. ein powercfg-Aufruf).
    param(
        $Entries,
        [string]$Service,
        [string]$PathPresent,
        [string]$PathAbsent
    )

    if ($PathPresent) {
        try { if (Test-Path -LiteralPath $PathPresent) { return 'on' } else { return 'off' } }
        catch { return 'na' }
    }
    if ($PathAbsent) {
        try { if (Test-Path -LiteralPath $PathAbsent) { return 'off' } else { return 'on' } }
        catch { return 'na' }
    }
    if ($Service) {
        # Starttyp aus der Registrierung - kein ServiceController, keine
        # Ausnahme, nur ein Wert.
        $st = Get-ServiceStartupType -Name $Service
        if ($st -eq 'Unknown') { return 'na' }
        if ($st -eq 'Disabled') { return 'on' }
        return 'off'
    }
    if (-not $Entries) { return 'na' }

    $hit = 0
    $total = 0
    foreach ($e in @($Entries)) {
        $total++
        if (Test-RegistryMatch -Current (Get-RegistryValueFast -Path $e.Path -Name $e.Name) -Expected $e.Value) { $hit++ }
    }
    return (Get-TweakStateFromHits -Hit $hit -Total $total)
}

function Split-RegistryPath {
    # Zerlegt 'HKLM:\SOFTWARE\...' in Wurzel und Unterschluessel. Der
    # Registrierungs-Anbieter von PowerShell ist bequem, aber langsam: jeder
    # Zugriff laeuft durch das Anbietermodell, und ein fehlender Wert kostet
    # eine .NET-Ausnahme. Mit der Wurzel koennen wir direkt lesen.
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $p = $Path.Trim().Replace('/', '\')
    $map = @{
        'HKLM' = 'LocalMachine'; 'HKEY_LOCAL_MACHINE' = 'LocalMachine'
        'HKCU' = 'CurrentUser'; 'HKEY_CURRENT_USER' = 'CurrentUser'
        'HKCR' = 'ClassesRoot'; 'HKEY_CLASSES_ROOT' = 'ClassesRoot'
        'HKU' = 'Users'; 'HKEY_USERS' = 'Users'
        'HKCC' = 'CurrentConfig'; 'HKEY_CURRENT_CONFIG' = 'CurrentConfig'
    }
    if ($p -match '^(?i)(Registry|Microsoft\.PowerShell\.Core\\Registry)::') { $p = $p -replace '^(?i)[^:]*::', '' }
    $idx = $p.IndexOf('\')
    $head = if ($idx -ge 0) { $p.Substring(0, $idx) } else { $p }
    $rest = if ($idx -ge 0) { $p.Substring($idx + 1) } else { '' }
    $head = $head.TrimEnd(':').ToUpperInvariant()
    if (-not $map.ContainsKey($head)) { return $null }
    return @{ Hive = $map[$head]; Sub = $rest.Trim('\') }
}

function Get-RegistryValueFast {
    # Liest einen einzelnen Wert ohne Anbieter und ohne Ausnahme, wenn er
    # fehlt - genau das war der teure Fall: jede Karte pruefte mehrere Werte,
    # und jeder nicht vorhandene kostete eine geworfene Ausnahme.
    param([string]$Path, [string]$Name)
    $parts = Split-RegistryPath -Path $Path
    if (-not $parts) { return $null }
    $base = $null
    $key = $null
    try {
        $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey($parts.Hive, [Microsoft.Win32.RegistryView]::Default)
        if (-not $base) { return $null }
        $key = if ($parts.Sub) { $base.OpenSubKey($parts.Sub, $false) } else { $base }
        if (-not $key) { return $null }
        return $key.GetValue($Name, $null)
    }
    catch { return $null }
    finally {
        if ($key -and -not [object]::ReferenceEquals($key, $base)) { try { $key.Dispose() } catch { } }
        if ($base) { try { $base.Dispose() } catch { } }
    }
}

function Test-RegistryMatch {
    # Vergleich wie bisher: Zeichenkette gegen Zeichenkette, Listen ueber
    # ihre Glieder. Ein fehlender Wert ist nie eine Uebereinstimmung.
    param($Current, $Expected)
    if ($null -eq $Current) { return $false }
    if ($Current -is [array] -or $Expected -is [array]) {
        return ((@($Current) -join '|') -eq (@($Expected) -join '|'))
    }
    return ("$Current" -eq "$Expected")
}

function Get-TweakStateFromHits {
    param([int]$Hit = 0, [int]$Total = 0)
    if ($Total -le 0) { return 'na' }
    if ($Hit -ge $Total) { return 'on' }
    if ($Hit -gt 0) { return 'part' }
    return 'off'
}

function Request-CardStates {
    # Die Abzeichen werden erst gesetzt, NACHDEM die Ansicht steht. Vorher
    # pruefte jede Karte waehrend des Aufbaus ihren Zustand - bei zwoelf
    # Karten mit Registrierungs-, Dienst- und powercfg-Abfragen hing das
    # Fenster genau so lange, wie alle Pruefungen zusammen brauchten.
    param([int]$DelayMs = 30)
    Invoke-Deferred -DelayMs $DelayMs -Action { Update-CardStates }
}

function Update-ControlIconOne {
    param([System.Windows.Forms.Control]$Control, [int]$Size = 16)
    $c = $Control
    if (-not $c -or $c.IsDisposed) { return }
    try {
        if ($script:lblStatus -and $c -eq $script:lblStatus) { return }
        if ($c -is [System.Windows.Forms.TextBoxBase]) { return }
        if ($c.Tag -is [hashtable] -and $c.Tag['IsCategory']) { return }
        if ($c -is [System.Windows.Forms.CheckBox] -or $c -is [System.Windows.Forms.RadioButton]) {
            $g = Get-LeadingGlyph $c.Text
            if ($g) {
                $c.Text = $c.Text.TrimStart().Substring($g.Length).TrimStart()
                $nm = Get-IconName $g
                if ($nm) {
                    $img = Get-IconBitmap -Name $nm -Size $Size -Color $c.ForeColor
                    if ($img) {
                        if ($c.Padding.Left -lt ($Size + 6)) {
                            $c.Padding = New-Object System.Windows.Forms.Padding(($Size + 6), 0, 0, 0)
                        }
                        Set-LabelIconPainter -Control $c -Image $img -Rtl (Test-RightToLeftUi)
                    }
                }
            }
        }
        elseif (($c -is [System.Windows.Forms.Button] -or $c -is [System.Windows.Forms.Label]) -and $null -eq $c.Image) {
            $g = Get-LeadingGlyph $c.Text
            if ($g) { [void](Set-ControlIcon -Control $c -Glyph $g -Size $Size -StripText) }
        }
        if ($c -is [System.Windows.Forms.Button]) { Set-ButtonPolish -Button $c }
    }
    catch { }
}

function Invoke-ViewPolish {
    # EIN Durchlauf durch den Steuerelementbaum statt fuenf. Nach jedem
    # Ansichtswechsel liefen Doppelpufferung, Symbole, dunkle Rollbalken,
    # dunkle Eingabefelder und die Links-nach-rechts-Korrektur nacheinander
    # jeweils rekursiv ueber dieselben hundert Steuerelemente.
    param([System.Windows.Forms.Control]$Root, [int]$Size = 16)
    if (-not $Root -or $Root.IsDisposed) { return }
    foreach ($c in @($Root.Controls)) {
        if (-not $c -or $c.IsDisposed) { continue }
        if ($c -is [System.Windows.Forms.ListView] -or $c -is [System.Windows.Forms.Panel] -or
            $c -is [System.Windows.Forms.RichTextBox]) {
            Set-DoubleBuffered -Control $c
        }
        Update-ControlIconOne -Control $c -Size $Size
        Set-DarkScrollbarOne -Control $c
        Set-DarkInputOne -Control $c
        if ($c -is [System.Windows.Forms.RichTextBox]) {
            try { $c.RightToLeft = [System.Windows.Forms.RightToLeft]::No } catch { }
        }
        if ($c.HasChildren) { Invoke-ViewPolish -Root $c -Size $Size }
    }
}

function Update-CardState {
    # Faerbt und beschriftet das Abzeichen einer einzelnen Karte neu.
    param($Card)
    if (-not $Card -or $Card.IsDisposed) { return }
    if (-not ($Card.Tag -is [hashtable])) { return }
    $lbl = $Card.Tag.StateLabel
    $chk = $Card.Tag.StateCheck
    if (-not $lbl -or $lbl.IsDisposed -or -not $chk) { return }
    $state = 'na'
    try { $state = [string](& $chk) } catch { $state = 'na' }
    switch ($state) {
        'on' {
            $lbl.Text = Get-Text 'StateOn'
            $lbl.ForeColor = $script:Theme.Success
        }
        'part' {
            $lbl.Text = Get-Text 'StatePart'
            $lbl.ForeColor = $script:Theme.Warning
        }
        default {
            $lbl.Text = ''
        }
    }
}

function Update-CardStates {
    # Nach einer Aktion alle sichtbaren Karten neu bewerten. Laeuft nur ueber
    # Karten mit hinterlegter Pruefung - die uebrigen kosten nichts.
    if (-not $script:pnlContent -or $script:pnlContent.IsDisposed) { return }
    foreach ($c in @($script:pnlContent.Controls)) {
        if ($c -is [System.Windows.Forms.Panel] -and $c.Tag -is [hashtable] -and $c.Tag.StateCheck) {
            try { Update-CardState -Card $c } catch { }
        }
    }
}

function Add-Card {
    param(
        [string]$TitleKey,
        [string]$DescKey,
        [string]$BtnKey,
        [string]$Icon,
        [scriptblock]$Action,
        [int]$X,
        [int]$Y,
        [System.Drawing.Color]$Color,
        [int]$W = 270,
        [int]$H = 150,
        [scriptblock]$StateCheck = $null
    )

    $card = New-Object System.Windows.Forms.Panel
    $card.Location = New-Object System.Drawing.Point($X, $Y)
    $card.Size = New-Object System.Drawing.Size($W, $H)
    $card.BackColor = $script:Theme.BgCard
    $card.Tag = @{ Hover = $false; Color = $Color; StateCheck = $StateCheck; StateLabel = $null }

    $card.Add_MouseEnter({
            if ($this.Tag) { $this.Tag.Hover = $true }
            $this.BackColor = $script:Theme.BgCardHover
            $this.Invalidate()
        })
    $card.Add_MouseLeave({
            if ($this.Tag) { $this.Tag.Hover = $false }
            $this.BackColor = $script:Theme.BgCard
            $this.Invalidate()
        })

    # Die Karte bekommt immer eine feine Kontur - erst dadurch sieht man ueber-
    # haupt eine Karte. Beim Ueberfahren wechselt sie auf die Akzentfarbe.
    $card.Add_Paint({
            param($s, $e)
            $pen = $null
            $path = $null
            $br = $null
            try {
                $e.Graphics.SmoothingMode = 'AntiAlias'
                $sheen = 18
                if ($s.Tag -and $s.Tag.Hover) { $sheen = 24 }
                Invoke-GlassSheen -Graphics $e.Graphics -Width $s.Width -Height $s.Height -Radius 12 -Alpha $sheen
                $d = 24
                $w = $s.Width - 1
                $h = $s.Height - 1
                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                $path.AddArc(0, 0, $d, $d, 180, 90)
                $path.AddArc(($w - $d), 0, $d, $d, 270, 90)
                $path.AddArc(($w - $d), ($h - $d), $d, $d, 0, 90)
                $path.AddArc(0, ($h - $d), $d, $d, 90, 90)
                $path.CloseFigure()
                if ($s.Tag -and $s.Tag.Hover) {
                    $pen = New-Object -TypeName 'System.Drawing.Pen' -ArgumentList ($s.Tag.Color, 1.6)
                }
                else {
                    $pen = New-Object -TypeName 'System.Drawing.Pen' -ArgumentList ($script:Theme.Border, 1.0)
                }
                $e.Graphics.DrawPath($pen, $path)

                # Kurzer Akzentstrich unter dem Titel - die Karte ist dadurch
                # auch ohne Mauszeiger als Karte lesbar.
                if ($s.Tag -and $s.Tag.Color) {
                    $acc = $s.Tag.Color
                    $alpha = 140
                    if ($s.Tag.Hover) { $alpha = 255 }
                    $br = New-Object -TypeName 'System.Drawing.SolidBrush' -ArgumentList ([System.Drawing.Color]::FromArgb($alpha, $acc))
                    $lw = [math]::Max(24, [math]::Min(80, $s.Width - 80))
                    $e.Graphics.FillRectangle($br, 50, 40, $lw, 2)
                }
            }
            catch { }
            finally {
                if ($pen) { $pen.Dispose() }
                if ($path) { $path.Dispose() }
                if ($br) { $br.Dispose() }
            }
        })

    $lblIcon = New-Object System.Windows.Forms.Label
    $lblIcon.Location = New-Object System.Drawing.Point(16, 12)
    $lblIcon.Size = New-Object System.Drawing.Size(26, 26)
    $lblIcon.BackColor = [System.Drawing.Color]::Transparent
    if (-not (Set-ControlIcon -Control $lblIcon -Glyph $Icon -Size 22 -Color $Color -IconOnly)) {
        # Kein Zeichensatz-Rueckfall mehr: Namen wie 'broom' wuerden als Text erscheinen
        $lblIcon.Text = $(if ($Icon -match '^[A-Za-z0-9_:{}]+$') { '' } else { $Icon })
        $lblIcon.Font = (Get-AppFont -Family 'Segoe UI Emoji' -Size 18)
        $lblIcon.AutoSize = $true
    }
    $card.Controls.Add($lblIcon)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = Get-Text $TitleKey
    $lblTitle.Font = (Get-AppFont -Size 11 -Style 'Bold')
    $lblTitle.ForeColor = $Color
    $lblTitle.Location = New-Object System.Drawing.Point(50, 13)
    # Mit Zustandsabzeichen rechts oben bleibt weniger Platz fuer den Titel.
    $titleW = $W - 66
    if ($StateCheck) { $titleW = $W - 66 - 58 }
    $lblTitle.Size = New-Object System.Drawing.Size($titleW, 24)
    $lblTitle.AutoEllipsis = $true
    $lblTitle.Anchor = 'Top,Left,Right'
    $lblTitle.BackColor = [System.Drawing.Color]::Transparent
    $card.Controls.Add($lblTitle)

    if ($StateCheck) {
        # Kleines Abzeichen rechts oben: Bisher war an keiner Karte zu sehen,
        # ob die Einstellung schon gesetzt ist - man konnte nur erneut klicken.
        $lblState = New-Object System.Windows.Forms.Label
        $lblState.Location = New-Object System.Drawing.Point(($W - 72), 16)
        $lblState.Size = New-Object System.Drawing.Size(56, 18)
        $lblState.Anchor = 'Top,Right'
        $lblState.TextAlign = 'MiddleRight'
        $lblState.Font = (Get-AppFont -Size 8 -Style 'Bold')
        $lblState.BackColor = [System.Drawing.Color]::Transparent
        $lblState.AutoEllipsis = $true
        $card.Controls.Add($lblState)
        $card.Tag.StateLabel = $lblState
        # NICHT hier pruefen: das Abzeichen wird nachtraeglich gefuellt,
        # sobald die Ansicht steht (Request-CardStates).
    }

    $lblDesc = New-Object System.Windows.Forms.Label
    $lblDesc.Text = Get-Text $DescKey
    $lblDesc.Font = (Get-AppFont -Size 9)
    $lblDesc.ForeColor = $script:Theme.TextMuted
    $lblDesc.Location = New-Object System.Drawing.Point(16, 48)
    $lblDesc.Size = New-Object System.Drawing.Size(($W - 32), 42)
    $lblDesc.Anchor = 'Top,Left,Right'
    $lblDesc.BackColor = [System.Drawing.Color]::Transparent
    $card.Controls.Add($lblDesc)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = Get-Text $BtnKey
    $btn.Location = New-Object System.Drawing.Point(16, ($H - 46))
    $btn.Size = New-Object System.Drawing.Size(($W - 32), 34)
    $btn.Anchor = 'Bottom,Left,Right'
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = (Get-TintColor -Color $Color -Base $script:Theme.BgCard -Amount 0.16)
    $btn.ForeColor = $Color
    $btn.Font = (Get-AppFont -Size 9 -Style 'Bold')
    $btn.Cursor = 'Hand'
    $btn.Tag = @{ Color = $Color; Action = $Action }

    $btn.Add_Click({
            $savedCursor = $script:MainForm.Cursor
            try {
                $script:MainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
                & $this.Tag.Action
            }
            catch {
                Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR'

                # The log is at the bottom of the window - flash the button
                # itself so a failed action cannot be missed.
                $failBtn = $this
                try {
                    $failBtn.BackColor = $script:Theme.Error
                    $failBtn.ForeColor = [System.Drawing.Color]::White
                    $flash = New-Object System.Windows.Forms.Timer
                    $flash.Interval = 1500
                    $flash.Add_Tick({
                            $flash.Stop()
                            $flash.Dispose()
                            if ($failBtn -and -not $failBtn.IsDisposed -and $failBtn.Tag) {
                                $c = $failBtn.Tag.Color
                                $failBtn.BackColor = (Get-TintColor -Color $c -Base $script:Theme.BgCard -Amount 0.16)
                                $failBtn.ForeColor = $c
                            }
                        }.GetNewClosure())
                    $flash.Start()
                }
                catch { }
            }
            finally {
                $script:MainForm.Cursor = $savedCursor
                # Zentral statt in jeder einzelnen Aktion: nach jedem Klick
                # zeigen alle Karten der Ansicht wieder den echten Zustand.
                try { Request-CardStates -DelayMs 40 } catch { }
            }
        })
    $btn.Add_MouseEnter({
            $this.BackColor = $this.Tag.Color
            $this.ForeColor = [System.Drawing.Color]::White
        })
    $btn.Add_MouseLeave({
            $c = $this.Tag.Color
            $this.BackColor = (Get-TintColor -Color $c -Base $script:Theme.BgCard -Amount 0.16)
            $this.ForeColor = $c
        })
    $card.Controls.Add($btn)
    # Bei schmalen Spalten wird die Beschreibung gekuerzt - als Kurzinfo
    # bleibt der ganze Text erreichbar.
    $descText = Get-Text $DescKey
    Set-Tip $card $descText
    Set-Tip $lblTitle (Get-Text $TitleKey)
    Set-Tip $lblDesc $descText

    Set-RoundedRegion -Control $card -Radius 12
    Set-RoundedRegion -Control $btn -Radius 8

    $script:pnlContent.Controls.Add($card)

    # Register for the responsive grid (see Update-CardGrid)
    if ($null -eq $script:GridCards) {
        $script:GridCards = New-Object System.Collections.Generic.List[object]
    }
    $script:GridCards.Add([pscustomobject]@{
            Control = $card
            Span    = [int][math]::Max(1, [math]::Ceiling(($W + 20) / 290))
            OrigX   = $X
            OrigY   = $Y
        })

    return $card
}

function Add-StatCard {
    param(
        [string]$LabelKey,
        [string]$Value,
        [string]$Icon,
        [int]$X,
        [int]$Y,
        [System.Drawing.Color]$Color
    )

    $card = New-Object System.Windows.Forms.Panel
    $card.Location = New-Object System.Drawing.Point($X, $Y)
    $card.Size = New-Object System.Drawing.Size(230, 110)
    $card.BackColor = $script:Theme.BgCard

    # Der 4 px Farbbalken am linken Rand ist einem Farbchip hinter dem Icon
    # gewichen - dieselbe Information, deutlich ruhiger.
    $card.Add_Paint({
            param($s, $e)
            $pen = $null
            $path = $null
            try {
                $e.Graphics.SmoothingMode = 'AntiAlias'
                Invoke-GlassSheen -Graphics $e.Graphics -Width $s.Width -Height $s.Height -Radius 12 -Alpha 16
                $d = 24
                $w = $s.Width - 1
                $h = $s.Height - 1
                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                $path.AddArc(0, 0, $d, $d, 180, 90)
                $path.AddArc(($w - $d), 0, $d, $d, 270, 90)
                $path.AddArc(($w - $d), ($h - $d), $d, $d, 0, 90)
                $path.AddArc(0, ($h - $d), $d, $d, 90, 90)
                $path.CloseFigure()
                $pen = New-Object -TypeName 'System.Drawing.Pen' -ArgumentList ($script:Theme.Border, 1.0)
                $e.Graphics.DrawPath($pen, $path)
            }
            catch { }
            finally {
                if ($pen) { $pen.Dispose() }
                if ($path) { $path.Dispose() }
            }
        })

    $chip = New-Object System.Windows.Forms.Panel
    $chip.Location = New-Object System.Drawing.Point(16, 16)
    $chip.Size = New-Object System.Drawing.Size(38, 38)
    $chip.BackColor = (Get-TintColor -Color $Color -Base $script:Theme.BgCard -Amount 0.20)
    Set-RoundedRegion -Control $chip -Radius 10
    $card.Controls.Add($chip)

    $lblIcon = New-Object System.Windows.Forms.Label
    $lblIcon.Location = New-Object System.Drawing.Point(8, 8)
    $lblIcon.Size = New-Object System.Drawing.Size(22, 22)
    $lblIcon.BackColor = [System.Drawing.Color]::Transparent
    if (-not (Set-ControlIcon -Control $lblIcon -Glyph $Icon -Size 22 -Color $Color -IconOnly)) {
        # Kein Zeichensatz-Rueckfall mehr: Namen wie 'broom' wuerden als Text erscheinen
        $lblIcon.Text = $(if ($Icon -match '^[A-Za-z0-9_:{}]+$') { '' } else { $Icon })
        $lblIcon.Font = (Get-AppFont -Family 'Segoe UI Emoji' -Size 14)
        $lblIcon.AutoSize = $true
    }
    $chip.Controls.Add($lblIcon)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = (Get-Text $LabelKey).ToUpper()
    $lblTitle.Font = (Get-AppFont -Size 8 -Style 'Bold')
    $lblTitle.ForeColor = $script:Theme.TextMuted
    $lblTitle.Location = New-Object System.Drawing.Point(64, 24)
    # Fixed width + ellipsis: Turkish titles like 'ISLEMCI KULLANIMI' used to
    # wrap into the value line below.
    $lblTitle.AutoSize = $false
    $lblTitle.Size = New-Object System.Drawing.Size(($card.Width - 80), 20)
    $lblTitle.AutoEllipsis = $true
    $lblTitle.TextAlign = 'MiddleLeft'
    $lblTitle.BackColor = [System.Drawing.Color]::Transparent
    Set-Tip $lblTitle $lblTitle.Text
    $card.Controls.Add($lblTitle)

    $lblVal = New-Object System.Windows.Forms.Label
    $lblVal.Text = $Value
    $lblVal.Font = (Get-AppFont -Size 20 -Style 'Bold')
    $lblVal.ForeColor = $script:Theme.TextPrimary
    $lblVal.Location = New-Object System.Drawing.Point(16, 62)
    $lblVal.AutoSize = $true
    $lblVal.BackColor = [System.Drawing.Color]::Transparent
    $card.Controls.Add($lblVal)

    $card.Tag = @{ ValueLabel = $lblVal }
    Set-RoundedRegion -Control $card -Radius 12
    $script:pnlContent.Controls.Add($card)
    return $card
}

function New-SidebarButton {
    param(
        [string]$TextKey,
        [string]$Icon,
        [string]$ViewTag,
        [int]$Top,
        [bool]$IsCategory = $false
    )

    if ($IsCategory) {
        $lbl = New-Object System.Windows.Forms.Label
        # Strichketten (── Text ──) wirken wie ein Terminal von 1998. Heute
        # ueblich: kleine, gesperrte Grossbuchstaben in gedaempfter Farbe.
        $lbl.Text = (Get-Text $TextKey).ToUpper()
        $lbl.Font = (Get-AppFont -Size 8 -Style 'Bold')
        $lbl.ForeColor = $script:Theme.TextMuted
        $lbl.Location = New-Object System.Drawing.Point(14, $Top)
        # 250 px sidebar - 17 px scrollbar: anything wider triggered a second,
        # horizontal scrollbar and cut the entries off on the right.
        $lbl.Size = New-Object System.Drawing.Size(205, 20)
        $lbl.Tag = @{ TextKey = $TextKey; IsCategory = $true }
        $script:pnlSidebarScroll.Controls.Add($lbl)
        return ($Top + 22)
    }

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = " $(Get-Text $TextKey)"
    $btn.Tag = @{ View = $ViewTag; TextKey = $TextKey; Icon = $Icon; IsCategory = $false }
    $btn.Location = New-Object System.Drawing.Point($script:Spacing.xs, $Top)
    $btn.Size = New-Object System.Drawing.Size(229, 30)
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $script:Theme.BgSidebar
    $btn.ForeColor = $script:Theme.TextSecondary
    $btn.Font = (Get-AppFont -Size 10)
    $btn.TextAlign = 'MiddleLeft'
    $btn.Cursor = 'Hand'
    # No focus rectangle wandering through the menu - the sidebar is reached
    # with Ctrl+1...9, like the window buttons it stays out of the tab order.
    $btn.TabStop = $false

    # Frueher markierte ein 4 px Balken links den aktiven Eintrag. Statt dessen
    # bekommt der aktive Eintrag jetzt eine abgerundete Flaeche ("Pille") -
    # das ist der heute uebliche und ruhigere Weg.
    Set-RoundedRegion -Control $btn -Radius 8
    # Die Region gilt pro Groesse - nach jeder Breitenaenderung neu setzen
    $btn.Add_Resize({
            try { Set-RoundedRegion -Control $this -Radius 8 } catch { }
        })

    # Schmaler Akzentstreifen fuer den aktiven Eintrag, innerhalb der Rundung
    $accentBar = New-Object System.Windows.Forms.Panel
    $accentBar.Size = New-Object System.Drawing.Size(3, 16)
    $accentBar.Location = New-Object System.Drawing.Point(4, 7)
    $accentBar.BackColor = $script:Theme.AccentLight
    $accentBar.Visible = $false
    $accentBar.Name = 'AccentBar'
    $btn.Controls.Add($accentBar)

    $btn.Add_Click({ Set-View -ViewName $this.Tag.View })

    $btn.Add_MouseEnter({
            if ($this.Tag.View -ne $script:Config.CurrentView) {
                $this.BackColor = $script:Theme.SidebarHover
                $this.ForeColor = $script:Theme.TextPrimary
                # Das Icon muss mitwandern, sonst bleibt es grau im hellen Text
                if ($this.Tag.Icon) {
                    $img = Get-IconBitmap -Name $this.Tag.Icon -Size 18 -Color $script:Theme.TextPrimary
                    if ($img) { $this.Image = $img }
                }
            }
        })
    $btn.Add_MouseLeave({
            if ($this.Tag.View -ne $script:Config.CurrentView) {
                $this.BackColor = $script:Theme.BgSidebar
                $this.ForeColor = $script:Theme.TextSecondary
                if ($this.Tag.Icon) {
                    $img = Get-IconBitmap -Name $this.Tag.Icon -Size 18 -Color $script:Theme.TextSecondary
                    if ($img) { $this.Image = $img }
                }
            }
        })

    [void](Set-ControlIcon -Control $btn -Glyph $Icon -Size 18 -Color $script:Theme.TextMuted)
    $btn.ImageAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $btn.TextImageRelation = [System.Windows.Forms.TextImageRelation]::ImageBeforeText
    $btn.Padding = New-Object System.Windows.Forms.Padding(14, 0, 0, 0)

    Set-Tip $btn (Get-Text $TextKey)
    $script:pnlSidebarScroll.Controls.Add($btn)
    # 21 Eintraege + 5 Ueberschriften ergeben so 792 px und passen damit auch
    # im kleinsten Fenster ohne Scrollbalken in die Leiste.
    return ($Top + 32)
}

function Update-SidebarLanguage {
    foreach ($c in $script:pnlSidebarScroll.Controls) {
        if ($null -eq $c.Tag) { continue }
        if ($c -is [System.Windows.Forms.Button]) {
            $c.Text = " $(Get-Text $c.Tag.TextKey)"
        }
        elseif ($c -is [System.Windows.Forms.Label]) {
            $c.Text = (Get-Text $c.Tag.TextKey).ToUpper()
        }
    }
}

# --- Splash -------------------------------------------------------------------
function Show-Splash {
    $form = New-Object System.Windows.Forms.Form
    try {
        $form.Size = New-Object System.Drawing.Size(520, 300)
        $form.StartPosition = 'CenterScreen'
        $form.FormBorderStyle = 'None'
        $form.BackColor = $script:Theme.Accent
        $form.TopMost = $true
        $form.ShowInTaskbar = $false

        $inner = New-Object System.Windows.Forms.Panel
        $inner.Location = New-Object System.Drawing.Point(2, 2)
        $inner.Size = New-Object System.Drawing.Size(516, 296)
        $inner.BackColor = $script:Theme.BgPrimary
        $form.Controls.Add($inner)

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text = 'EB_Optimizer'
        $lblTitle.Font = (Get-AppFont -Size 24 -Style 'Bold')
        $lblTitle.ForeColor = $script:Theme.TextPrimary
        $lblTitle.AutoSize = $false
        $lblTitle.TextAlign = 'MiddleCenter'
        $lblTitle.Size = New-Object System.Drawing.Size(514, 44)
        $lblTitle.Location = New-Object System.Drawing.Point(0, 110)

        if ($script:Config.LogoPath -and (Test-Path -LiteralPath $script:Config.LogoPath)) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($script:Config.LogoPath)
                $ms = New-Object System.IO.MemoryStream(, $bytes)
                $picLogo = New-Object System.Windows.Forms.PictureBox
                $picLogo.Image = [System.Drawing.Image]::FromStream($ms)
                $picLogo.SizeMode = 'Zoom'
                $picLogo.Size = New-Object System.Drawing.Size(96, 96)
                $picLogo.Location = New-Object System.Drawing.Point(209, 18)
                $picLogo.BackColor = [System.Drawing.Color]::Transparent
                $inner.Controls.Add($picLogo)
            }
            catch { }
        }
        $inner.Controls.Add($lblTitle)


        $lblLang = New-Object System.Windows.Forms.Label
        $lblLang.Text = 'DE | EN | TR | AR'
        $lblLang.Font = (Get-AppFont -Size 9)
        $lblLang.ForeColor = $script:Theme.TextMuted
        $lblLang.AutoSize = $false
        $lblLang.TextAlign = 'MiddleCenter'
        $lblLang.Size = New-Object System.Drawing.Size(514, 20)
        $lblLang.Location = New-Object System.Drawing.Point(0, 182)
        $inner.Controls.Add($lblLang)

        $barBg = New-Object System.Windows.Forms.Panel
        $barBg.Location = New-Object System.Drawing.Point(82, 220)
        $barBg.Size = New-Object System.Drawing.Size(350, 6)
        $barBg.BackColor = $script:Theme.BgTertiary
        $inner.Controls.Add($barBg)

        $bar = New-Object System.Windows.Forms.Panel
        $bar.Location = New-Object System.Drawing.Point(0, 0)
        $bar.Size = New-Object System.Drawing.Size(0, 6)
        $bar.BackColor = $script:Theme.Accent
        $barBg.Controls.Add($bar)

        $form.Show()
        # Runde Ecken auch fuer das Startbild - der Akzentrahmen folgt
        try { Set-RoundedRegion -Control $form -Radius 14 } catch { }
        $form.Refresh()

        for ($i = 0; $i -le 100; $i += 5) {
            $bar.Width = [int]($i * 3.5)
            $form.Refresh()
            Start-Sleep -Milliseconds 8
        }
        Start-Sleep -Milliseconds 120
        $form.Close()
    }
    finally {
        $form.Dispose()
    }
}

#endregion 5. UI HELPERS


#region 6. VIEWS

# ---------------------------------------------------------------- DASHBOARD --
function Get-DashboardLayout {
    # Spaltengeometrie fuer die aktuelle Inhaltsbreite. Das alte Raster
    # 25/325/625/925 setzte 1225 px voraus - darunter fiel die vierte Spalte
    # heraus, darueber blieb rechts ein toter Streifen.
    $pad = 25
    $gap = 20
    $w = 1200
    try {
        if ($script:pnlContent -and -not $script:pnlContent.IsDisposed -and $script:pnlContent.ClientSize.Width -gt 400) {
            $w = $script:pnlContent.ClientSize.Width
        }
    }
    catch { }
    if ($w -lt 900) { $w = 900 }

    $avail = $w - ($pad * 2)
    $cols = 2
    if ($avail -ge (4 * 270 + 3 * $gap)) { $cols = 4 }
    elseif ($avail -ge (3 * 270 + 2 * $gap)) { $cols = 3 }

    $pitch = [int][math]::Floor(($avail + $gap) / $cols)
    $colW = $pitch - $gap

    $xs = New-Object 'System.Collections.Generic.List[int]'
    for ($i = 0; $i -lt $cols; $i++) { $xs.Add([int]($pad + $i * $pitch)) }

    return [pscustomobject]@{
        Pad   = $pad
        Gap   = $gap
        Cols  = $cols
        Pitch = $pitch
        ColW  = $colW
        X     = $xs
        Right = [int]($pad + $avail)
    }
}

function Show-Dashboard {
    Add-ViewHeader -TitleKey 'DashTitle' -SubtitleKey 'DashSubtitle' -Icon 'home'

    # Gerechnete Spalten statt der festen 1225-px-Aufteilung: das
    # Netzwerkpanel lief frueher mit 475 + 700 = 1175 px ueber den Rand.
    $L = Get-DashboardLayout
    $gx1 = $L.X[0]
    # Die vier Aktionskarten sind im Kartenraster registriert: Update-CardGrid
    # setzt ihre endgueltige Spalte. Hier nur die Startwerte des 4er-Rasters,
    # damit beim Aufbau nichts uebereinanderliegt.
    $cardPitch = [int][math]::Max(215, [math]::Min(290, ($L.ColW + $L.Gap)))
    $gx3 = $gx1 + 2 * $cardPitch
    $gx4 = $gx1 + 3 * $cardPitch
    $gx2 = $gx1 + $cardPitch
    $gy1 = 95; $gy2 = 310; $gy3 = 500

    $rightEdge = $L.Right
    $healthW = [int][math]::Max(340, [math]::Min(430, ($rightEdge - $gx1 - $L.Gap - 340)))
    $netX = $gx1 + $healthW + $L.Gap
    $netW = [int][math]::Max(320, ($rightEdge - $netX))

    # Messuhren folgen der Spaltenbreite, bleiben aber bei 250-300 px: eine
    # 930 px breite Messuhr auf 4K saehe laecherlich aus.
    $gaugeW = [int][math]::Max(250, [math]::Min(300, $L.ColW))
    $gxRam = $gx1 + $gaugeW + $L.Gap

    # Die Statuskacheln bekommen eine eigene Rechnung: sie sind nur 230 px
    # breit und passen dadurch oft noch neben die Messuhren, auch wenn das
    # Kartenraster nur drei Spalten hergibt.
    $sx1 = $gxRam + $gaugeW + $L.Gap
    $sx2 = $sx1 + 250
    $fitStats = (($sx2 + 230) -le $rightEdge)
    if (-not $fitStats) { $gy3 = 630 }

    # System health hub
    $pnlHealth = New-Object System.Windows.Forms.Panel
    $pnlHealth.Location = New-Object System.Drawing.Point($gx1, $gy1)
    $pnlHealth.Size = New-Object System.Drawing.Size($healthW, 200)
    $pnlHealth.BackColor = $script:Theme.BgCard
    $pnlHealth.Add_Paint({
            param($s, $e)
            $penBg = $null; $penVal = $null; $sf = $null
            $brText = $null; $brMuted = $null; $brColor = $null; $brSec = $null
            $brSmall = $null
            try {
                $g = $e.Graphics
                $g.SmoothingMode = 'AntiAlias'
                $g.TextRenderingHint = 'ClearTypeGridFit'
                Invoke-GlassSheen -Graphics $g -Width $s.Width -Height $s.Height -Radius 10 -Alpha 16 -Border
                $score = [int]$script:CurrentStats.Health
                $color = if ($score -gt 80) { $script:Theme.Success }
                elseif ($score -gt 50) { $script:Theme.Warning }
                else { $script:Theme.Error }

                # Dominanter Ring: 150 px statt 120, dickere Linie, Wert gross
                $rect = New-Object System.Drawing.Rectangle(20, 25, 150, 150)
                $penBg = New-Object System.Drawing.Pen($script:Theme.BgTertiary, 14)
                $g.DrawArc($penBg, $rect, 135, 270)
                if ($score -gt 0) {
                    $penVal = New-Object System.Drawing.Pen($color, 14)
                    $penVal.StartCap = 'Round'; $penVal.EndCap = 'Round'
                    $g.DrawArc($penVal, $rect, 135, ($score / 100 * 270))
                }

                $sf = New-Object System.Drawing.StringFormat
                $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'
                $brText = New-Object System.Drawing.SolidBrush($script:Theme.TextPrimary)
                $brMuted = New-Object System.Drawing.SolidBrush($script:Theme.TextMuted)

                $numRect = New-Object System.Drawing.RectangleF(20, 58, 150, 56)
                $g.DrawString([string]$score, (Get-AppFont -Size 34 -Style 'Bold'), $brText, $numRect, $sf)
                $ofRect = New-Object System.Drawing.RectangleF(20, 112, 150, 22)
                $g.DrawString('/ 100', (Get-AppFont -Size 10), $brMuted, $ofRect, $sf)

                $tx = 190
                $g.DrawString((Get-Text 'DashHealth'), (Get-AppFont -Size 13 -Style 'Bold'), $brText, $tx, 32)

                $brColor = New-Object System.Drawing.SolidBrush($color)
                $g.FillEllipse($brColor, $tx, 64, 10, 10)
                $status = if ($score -gt 80) { Get-Text 'DashHealthOptimal' }
                elseif ($score -gt 50) { Get-Text 'DashHealthTune' }
                else { Get-Text 'HealthAction' }
                $brSec = New-Object System.Drawing.SolidBrush($script:Theme.TextSecondary)
                $g.DrawString($status, (Get-AppFont -Size 9 -Style 'Bold'), $brSec, ($tx + 16), 60)

                # Die drei groessten Abzuege - sonst ist die Zahl nur Dekoration
                $fSmall = (Get-AppFont -Size 9)
                $brSmall = New-Object System.Drawing.SolidBrush($script:Theme.TextMuted)
                $y = 92
                $shown = 0
                foreach ($f in @($script:HealthFactors)) {
                    if ($shown -ge 3) { break }
                    $g.DrawString(('-' + $f.Points + '  ' + $f.Text), $fSmall, $brSmall, $tx, $y)
                    $y += 22
                    $shown++
                }
                if ($shown -eq 0) {
                    $g.DrawString((Get-Text 'HealthAllGood'), $fSmall, $brSmall, $tx, $y)
                }
                # Sonst sieht die Karte nach drei Posten aus, obwohl mehr
                # Punkte vom Wert abgezogen wurden.
                $rest = @($script:HealthFactors).Count - $shown
                if ($rest -gt 0) {
                    $g.DrawString(('+ ' + $rest + '  ' + (Get-Text 'HealthMore')), $fSmall, $brSmall, $tx, $y)
                }
            }
            catch { }
            finally {
                # Schriften kommen aus dem Zwischenspeicher und werden geteilt -
                # nur die hier erzeugten GDI-Objekte freigeben.
                foreach ($d in @($penBg, $penVal, $sf, $brText, $brMuted, $brColor, $brSec, $brSmall)) {
                    if ($d) { $d.Dispose() }
                }
            }
        })
    Set-RoundedRegion -Control $pnlHealth -Radius 10
    $script:pnlContent.Controls.Add($pnlHealth)
    $script:pnlHealth = $pnlHealth

    # Network telemetry
    $pnlNet = New-Object System.Windows.Forms.Panel
    $pnlNet.Location = New-Object System.Drawing.Point($netX, $gy1)
    $pnlNet.Size = New-Object System.Drawing.Size($netW, 200)
    $pnlNet.Anchor = 'Top,Left,Right'
    $pnlNet.BackColor = $script:Theme.BgCard
    $pnlNet.Add_Paint({
            param($s, $e)
            $fTitle = $null; $fVal = $null; $brText = $null; $brCyan = $null
            try {
                $g = $e.Graphics
                $g.SmoothingMode = 'AntiAlias'
                Invoke-GlassSheen -Graphics $g -Width $s.Width -Height $s.Height -Radius 10 -Alpha 16 -Border
                $val = [double]$script:CurrentStats.Net

                $fTitle = (Get-AppFont -Size 12 -Style 'Bold')
                $brText = New-Object System.Drawing.SolidBrush($script:Theme.TextPrimary)
                $g.DrawString((Get-Text 'DashNetTitle'), $fTitle, $brText, 20, 20)

                $fVal = (Get-AppFont -Size 18 -Style 'Bold')
                $brCyan = New-Object System.Drawing.SolidBrush($script:Theme.Cyan)
                $g.DrawString((Format-NetRate $val), $fVal, $brCyan, 20, 50)

                # Breite und Hoehe aus dem Panel statt fester 660 x 85
                $spW = [int][math]::Max(120, ($s.ClientSize.Width - 40))
                $spH = [int][math]::Max(40, ($s.ClientSize.Height - 115))
                Invoke-SparklineDraw -e $e -History $script:SparklineHistory.NET -Color $script:Theme.Cyan `
                    -Rect (New-Object System.Drawing.Rectangle(20, 95, $spW, $spH))
            }
            catch { }
            finally {
                foreach ($d in @($brText, $brCyan)) { if ($d) { $d.Dispose() } }   # fonts stay cached
            }
        })
    Set-RoundedRegion -Control $pnlNet -Radius 10
    $script:pnlContent.Controls.Add($pnlNet)
    $script:GaugeNet = $pnlNet

    # CPU gauge
    $pnlCPU = New-Object System.Windows.Forms.Panel
    $pnlCPU.Location = New-Object System.Drawing.Point($gx1, $gy2)
    $pnlCPU.Size = New-Object System.Drawing.Size($gaugeW, 175)
    $pnlCPU.BackColor = $script:Theme.BgCard
    $pnlCPU.Tag = @{ Color = $script:Theme.Cyan; Label = (Get-Text 'DashCPU') }
    $pnlCPU.Add_Paint({
            param($s, $e)
            Invoke-GlassSheen -Graphics $e.Graphics -Width $s.Width -Height $s.Height -Radius 10 -Alpha 16 -Border
            Invoke-GaugeDraw -e $e -Value ([int]$script:CurrentStats.CPU) -Color $s.Tag.Color `
                -Rect (New-Object System.Drawing.Rectangle(70, 10, 140, 140)) -Label $s.Tag.Label
            Invoke-SparklineDraw -e $e -History $script:SparklineHistory.CPU -Color $s.Tag.Color `
                -Rect (New-Object System.Drawing.Rectangle(20, 140, 240, 28))
        })
    Set-RoundedRegion -Control $pnlCPU -Radius 10
    $script:pnlContent.Controls.Add($pnlCPU)
    $script:GaugeCPU = $pnlCPU

    # RAM gauge
    $pnlRAM = New-Object System.Windows.Forms.Panel
    $pnlRAM.Location = New-Object System.Drawing.Point($gxRam, $gy2)
    $pnlRAM.Size = New-Object System.Drawing.Size($gaugeW, 175)
    $pnlRAM.BackColor = $script:Theme.BgCard
    $pnlRAM.Tag = @{ Color = $script:Theme.Purple; Label = (Get-Text 'DashRAM') }
    $pnlRAM.Add_Paint({
            param($s, $e)
            Invoke-GlassSheen -Graphics $e.Graphics -Width $s.Width -Height $s.Height -Radius 10 -Alpha 16 -Border
            Invoke-GaugeDraw -e $e -Value ([int]$script:CurrentStats.RAM) -Color $s.Tag.Color `
                -Rect (New-Object System.Drawing.Rectangle(70, 10, 140, 140)) -Label $s.Tag.Label
            Invoke-SparklineDraw -e $e -History $script:SparklineHistory.RAM -Color $s.Tag.Color `
                -Rect (New-Object System.Drawing.Rectangle(20, 140, 240, 28))
        })
    Set-RoundedRegion -Control $pnlRAM -Radius 10
    $script:pnlContent.Controls.Add($pnlRAM)
    $script:GaugeRAM = $pnlRAM

    # Passen sie nicht mehr neben die Messuhren, ruecken sie in eine eigene
    # Reihe darunter - abgeschnitten wird nichts mehr.
    $sy = $gy2
    if (-not $fitStats) { $sx1 = $gx1; $sx2 = ($gx1 + 250); $sy = ($gy2 + 190) }
    $script:StatDisk = Add-StatCard -LabelKey 'DashDisk' -Value "$([int]$script:CurrentStats.Disk)%" -Icon 'disc' -X $sx1 -Y $sy -Color $script:Theme.Warning
    $script:StatProc = Add-StatCard -LabelKey 'DashProcs' -Value '0' -Icon 'bars' -X $sx2 -Y $sy -Color $script:Theme.Success

    Add-Card -TitleKey 'QuickClean' -DescKey 'QuickCleanDesc' -BtnKey 'Clean' -Icon 'broom' `
        -Action { [void](Invoke-QuickClean) } -X $gx1 -Y $gy3 -Color $script:Theme.Success | Out-Null

    Add-Card -TitleKey 'QuickRAM' -DescKey 'QuickRAMDesc' -BtnKey 'Optimize' -Icon 'cpu' `
        -Action { Optimize-Memory } -X $gx2 -Y $gy3 -Color $script:Theme.Purple | Out-Null

    Add-Card -TitleKey 'QuickAuto' -DescKey 'QuickAutoDesc' -BtnKey 'Start' -Icon 'rocket' `
        -Action { Invoke-AutoOptimize } -X $gx3 -Y $gy3 -Color $script:Theme.Cyan | Out-Null

    Add-Card -TitleKey 'RestorePoint' -DescKey 'RestorePointDesc' -BtnKey 'Start' -Icon 'camera' `
        -Action { [void](New-RestorePoint) } -X $gx4 -Y $gy3 -Color $script:Theme.Accent | Out-Null
}

# ----------------------------------------------------------------- HARDWARE --
function Format-StorageSize {
    # Unter 1000 GB in Gigabyte, darueber in Terabyte - "931 GB" ist bei einer
    # 1-TB-Platte richtig, aber "1863 GB" liest niemand gern.
    param([double]$Bytes)
    if ($Bytes -le 0) { return '' }
    $gb = $Bytes / 1GB
    if ($gb -lt 1000) { return ('{0:N0} GB' -f $gb) }
    return ('{0:N1} TB' -f ($gb / 1024))
}

function ConvertTo-HardwareDate {
    # CIM liefert je nach Weg ein DateTime oder die rohe WMI-Zeichenkette
    # (20230815000000.000000-000). Beides muss hier ankommen duerfen.
    param($Value)
    if ($null -eq $Value) { return '' }
    if ($Value -is [datetime]) { return $Value.ToString('yyyy-MM-dd') }
    $s = [string]$Value
    if (-not $s) { return '' }
    if ($s -match '^(\d{4})(\d{2})(\d{2})') {
        try { return (Get-Date -Year ([int]$Matches[1]) -Month ([int]$Matches[2]) -Day ([int]$Matches[3])).ToString('yyyy-MM-dd') }
        catch { return '' }
    }
    try { return ([datetime]$s).ToString('yyyy-MM-dd') } catch { return '' }
}

function Get-MemoryModuleSummary {
    # Frueher wurde der Mittelwert ausgegeben: zwei Riegel mit 8 und 16 GB
    # erschienen als "2 x 12 GB" - eine Bestueckung, die es nicht gibt.
    # Jetzt werden gleich grosse Riegel gruppiert.
    param($Modules, [int]$Slots = 0)
    $res = @{ Count = 0; Text = ''; TotalGB = 0.0; TypeName = ''; RatedMhz = 0; ConfiguredMhz = 0; Slots = [int]$Slots }
    $mods = @($Modules | Where-Object { $_ })
    if ($mods.Count -eq 0) { return $res }
    $res.Count = $mods.Count
    $sizes = @{}
    foreach ($m in $mods) {
        $cap = 0.0
        try { $cap = [double]$m.Capacity } catch { }
        if ($cap -gt 0) {
            $res.TotalGB += $cap / 1GB
            $gb = [int][math]::Round($cap / 1GB)
            if (-not $sizes.ContainsKey($gb)) { $sizes[$gb] = 0 }
            $sizes[$gb] = [int]$sizes[$gb] + 1
        }
        # Nicht jeder Riegel meldet seinen Typ - der erste brauchbare zaehlt.
        if (-not $res.TypeName) {
            $tn = Get-MemoryTypeName ($m.SMBIOSMemoryType)
            if ($tn) { $res.TypeName = $tn }
        }
        try { if ([int]$m.Speed -gt $res.RatedMhz) { $res.RatedMhz = [int]$m.Speed } } catch { }
        try { if ([int]$m.ConfiguredClockSpeed -gt $res.ConfiguredMhz) { $res.ConfiguredMhz = [int]$m.ConfiguredClockSpeed } } catch { }
    }
    $parts = @()
    foreach ($gb in ($sizes.Keys | Sort-Object -Descending)) {
        $parts += ('{0} x {1} GB' -f $sizes[$gb], $gb)
    }
    if ($parts.Count -gt 0) { $res.Text = $parts -join ' + ' }
    return $res
}

function Get-BatteryHealth {
    # Verschleiss = wie viel der urspruenglichen Ladung der Akku heute noch
    # aufnimmt. Ohne beide Kapazitaetswerte gibt es keine Aussage - dann wird
    # auch keine erfunden.
    param($Battery)
    $res = @{ Present = $false; Percent = -1; DesignWh = 0.0; FullWh = 0.0; WearPct = -1; OnBattery = $false }
    if (-not $Battery) { return $res }
    $res.Present = $true
    try { if ($null -ne $Battery.Percent) { $res.Percent = [int]$Battery.Percent } } catch { }
    try { $res.OnBattery = [bool]$Battery.OnBattery } catch { }
    $design = 0.0; $full = 0.0
    try { $design = [double]$Battery.DesignedCapacity } catch { }
    try { $full = [double]$Battery.FullChargedCapacity } catch { }
    if ($design -gt 0) { $res.DesignWh = [math]::Round($design / 1000.0, 1) }
    if ($full -gt 0) { $res.FullWh = [math]::Round($full / 1000.0, 1) }
    if ($design -gt 0 -and $full -gt 0) {
        $wear = (1.0 - ($full / $design)) * 100.0
        $res.WearPct = [int][math]::Round([math]::Max(0, [math]::Min(100, $wear)))
    }
    return $res
}

function Get-SystemUptimeText {
    # Nicht aus dem zehn Minuten alten Zwischenspeicher rechnen - die Laufzeit
    # waere sonst sichtbar falsch. TickCount64 ist immer aktuell.
    param($LastBoot)
    $span = $null
    try {
        $ms = [double][Environment]::TickCount64
        if ($ms -gt 0) { $span = [timespan]::FromMilliseconds($ms) }
    }
    catch { }
    if (-not $span -and $LastBoot) {
        try { $span = (Get-Date) - [datetime]$LastBoot } catch { }
    }
    if (-not $span) { return '' }
    return ('{0}d {1}h {2}min' -f [int]$span.Days, [int]$span.Hours, [int]$span.Minutes)
}

function Get-HardwareReportModel {
    # Baut die komplette Ausgabe als Liste von Zeilen auf, ohne eine einzige
    # Abfrage und ohne Oberflaeche. Ansicht und Textausfuhr zeichnen danach
    # dasselbe Modell - frueher las der Export den fertigen Textkasten aus und
    # konnte dabei den Ladehinweis mitnehmen.
    param($Info, $Memory, $Release)
    $out = New-Object System.Collections.Generic.List[object]
    $sec = { param($Key, $Color) $out.Add([pscustomobject]@{ Kind = 'section'; Key = $Key; Value = ''; Color = $Color }) }
    $row = {
        param($Key, $Value)
        if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return }
        $out.Add([pscustomobject]@{ Kind = 'row'; Key = $Key; Value = [string]$Value; Color = '' })
    }
    $txt = { param($Value) $out.Add([pscustomobject]@{ Kind = 'text'; Key = ''; Value = [string]$Value; Color = '' }) }
    $gap = { $out.Add([pscustomobject]@{ Kind = 'blank'; Key = ''; Value = ''; Color = '' }) }
    if (-not $Info) { return @($out.ToArray()) }

    # --- Prozessor
    & $sec 'HWProcessor' 'Accent'
    $cpu = $Info.CPU
    if ($cpu) {
        & $row 'LblName' (([string]$cpu.Name).Trim())
        if ($cpu.NumberOfCores) { & $row 'LblCores' ("$($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)") }
        if ($cpu.MaxClockSpeed) { & $row 'LblClock' ("$([math]::Round([double]$cpu.MaxClockSpeed / 1000, 2)) GHz") }
        $arch = switch ([int]$cpu.Architecture) { 0 { 'x86' } 5 { 'ARM' } 9 { 'x64' } 12 { 'ARM64' } default { '' } }
        & $row 'LblArch' $arch
    }
    else { & $txt (Get-Text 'HwUnknown') }
    & $gap

    # --- Grafik
    & $sec 'HWGraphics' 'Purple'
    $gpus = @($Info.GPUs | Where-Object { $_ -and $_.Name })
    if ($gpus.Count -eq 0) { & $txt (Get-Text 'HwUnknown') }
    foreach ($gpu in $gpus) {
        & $row 'LblName' $gpu.Name
        $bytes = 0.0
        try {
            if ($Info.VramByName -and $Info.VramByName.ContainsKey([string]$gpu.Name)) {
                $bytes = [double]$Info.VramByName[[string]$gpu.Name]
            }
        }
        catch { }
        if ($bytes -gt 0) { & $row 'LblVram' ("$([math]::Round($bytes / 1GB, 1)) GB") }
        else { & $row 'LblVram' (Get-Text 'HwUnknown') }
        if ($gpu.CurrentHorizontalResolution -and $gpu.CurrentVerticalResolution) {
            $hz = ''
            if ($gpu.CurrentRefreshRate) { $hz = " @ $($gpu.CurrentRefreshRate) Hz" }
            & $row 'LblRes' ("$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)$hz")
        }
        if ($gpu.DriverVersion) {
            $dv = [string]$gpu.DriverVersion
            $dd = ConvertTo-HardwareDate $gpu.DriverDate
            if ($dd) { $dv += '  (' + $dd + ')' }
            & $row 'LblDriver' $dv
        }
        & $gap
    }

    # --- Arbeitsspeicher
    & $sec 'HWMemory' 'Success'
    if ($Memory) {
        & $row 'LblTotal' ("$($Memory.TotalGB) GB")
        & $row 'LblUsed' ("$($Memory.UsedGB) GB ($($Memory.Percent)%)")
        & $row 'LblFree' ("$($Memory.FreeGB) GB")
    }
    $sum = Get-MemoryModuleSummary -Modules $Info.Modules -Slots ([int]$Info.MemorySlots)
    if ($sum.Count -gt 0) {
        $modText = [string]$sum.Count
        if ($sum.Text) { $modText += ' (' + $sum.Text + ')' }
        & $row 'LblModules' $modText
        if ($sum.Slots -gt 0) { & $row 'LblSlots' ("$($sum.Count) / $($sum.Slots)") }
        & $row 'LblType' $sum.TypeName
        if ($sum.RatedMhz -gt 0) { & $row 'LblSpeed' ("$($sum.RatedMhz) MHz") }
        # Laeuft der Speicher unter seinem Nennwert, fehlt in aller Regel nur
        # das XMP/EXPO-Profil im BIOS - ein haeufiger, leicht behebbarer
        # Leistungsverlust, den die Ansicht bisher verschwieg.
        if ($sum.ConfiguredMhz -gt 0) {
            $cfg = "$($sum.ConfiguredMhz) MHz"
            if ($sum.RatedMhz -gt 0 -and $sum.ConfiguredMhz -lt ($sum.RatedMhz - 50)) {
                $cfg += '  <- ' + (Get-Text 'HwXmpHint')
            }
            & $row 'LblConfigured' $cfg
        }
    }
    & $gap

    # --- Datentraeger
    & $sec 'HWStorage' 'Warning'
    $disks = @($Info.Disks | Where-Object { $_ -and $_.Size })
    if ($disks.Count -eq 0) { & $txt (Get-Text 'HwUnknown') }
    foreach ($d in $disks) {
        $kind = ''
        try {
            if ($Info.MediaByDisk -and $Info.MediaByDisk.ContainsKey([string]$d.Index)) {
                $kind = '  [' + $Info.MediaByDisk[[string]$d.Index] + ']'
            }
        }
        catch { }
        & $txt ('  ' + [string]$d.Model + $kind + '  -  ' + (Format-StorageSize ([double]$d.Size)))
    }
    & $gap

    # --- Akku (nur wenn einer da ist)
    $bat = Get-BatteryHealth -Battery $Info.Battery
    if ($bat.Present) {
        & $sec 'HWBattery' 'Teal'
        if ($bat.Percent -ge 0) {
            $chg = "$($bat.Percent) %"
            if ($bat.OnBattery) { $chg += '  (' + (Get-Text 'HwOnBattery') + ')' }
            & $row 'LblCharge' $chg
        }
        if ($bat.DesignWh -gt 0) { & $row 'LblDesign' ("$($bat.DesignWh) Wh") }
        if ($bat.FullWh -gt 0) { & $row 'LblFullCharge' ("$($bat.FullWh) Wh") }
        if ($bat.WearPct -ge 0) { & $row 'LblWear' ("$($bat.WearPct) %") }
        & $gap
    }

    # --- Hauptplatine
    if ($Info.Board -or $Info.BIOS) {
        & $sec 'HWBoard' 'Accent'
        if ($Info.Board) {
            & $row 'LblVendor' $Info.Board.Manufacturer
            & $row 'LblModel' $Info.Board.Product
        }
        if ($Info.BIOS) {
            & $row 'LblVersion' ($Info.BIOS.SMBIOSBIOSVersion)
            & $row 'LblDate' (ConvertTo-HardwareDate $Info.BIOS.ReleaseDate)
        }
        & $gap
    }

    # --- Sicherheitsmerkmale
    $tpm = [string]$Info.TpmVersion
    $sb = $Info.SecureBoot
    if ($tpm -or $null -ne $sb) {
        & $sec 'HWSecurity' 'Pink'
        if ($tpm) {
            $tv = $tpm
            if ($null -ne $Info.TpmEnabled) {
                $tv += '  (' + $(if ([bool]$Info.TpmEnabled) { Get-Text 'HwActive' } else { Get-Text 'HwInactive' }) + ')'
            }
            & $row 'LblTpm' $tv
        }
        if ($null -ne $sb) {
            & $row 'LblSecureBoot' $(if ([bool]$sb) { Get-Text 'HwActive' } else { Get-Text 'HwInactive' })
        }
        & $gap
    }

    # --- Netzwerkadapter
    $nics = @($Info.Nics | Where-Object { $_ })
    if ($nics.Count -gt 0) {
        & $sec 'HWNetwork' 'Cyan'
        foreach ($n in $nics) {
            & $row 'LblName' $n.Name
            & $row 'LblMac' $n.MACAddress
            $sp = 0.0
            try { $sp = [double]$n.Speed } catch { }
            if ($sp -gt 0) { & $row 'LblLink' ("$([math]::Round($sp / 1000000, 0)) Mbit/s") }
            & $gap
        }
    }

    # --- Betriebssystem
    & $sec 'HWOS' 'Cyan'
    if ($Info.OS) {
        & $row 'LblName' $Info.OS.Caption
        if ($Release -and $Release.Name) { & $row 'LblRelease' $Release.Name }
        & $row 'LblEdition' $Info.DisplayVer
        & $row 'LblVersion' $Info.OS.Version
        $build = [string]$Info.OS.BuildNumber
        if ($Info.UBR) { $build += '.' + $Info.UBR }
        & $row 'LblBuild' $build
        & $row 'LblInstalled' (ConvertTo-HardwareDate $Info.OS.InstallDate)
        & $row 'LblUptime' (Get-SystemUptimeText -LastBoot $Info.OS.LastBootUpTime)
    }
    return @($out.ToArray())
}

function Get-HardwareLabelPad {
    # Die Spaltenbreite ergibt sich aus den Beschriftungen, die wirklich
    # vorkommen. Die frueher fest eingetragene Liste vergass neue Schluessel,
    # und in anderen Sprachen stand die Spalte dann schief.
    param($Model)
    $pad = 10
    foreach ($e in @($Model)) {
        if ($e.Kind -ne 'row') { continue }
        $len = ([string](Get-Text $e.Key)).Length
        if ($len -gt $pad) { $pad = $len }
    }
    return ($pad + 2)
}

function ConvertTo-HardwareText {
    # Dieselben Zeilen als reiner Text fuer die Datei.
    param($Model, [string]$Title = '')
    $pad = Get-HardwareLabelPad -Model $Model
    $sb = New-Object System.Text.StringBuilder
    if ($Title) {
        [void]$sb.AppendLine($Title)
        [void]$sb.AppendLine(('=' * 63))
        [void]$sb.AppendLine('')
    }
    foreach ($e in @($Model)) {
        switch ([string]$e.Kind) {
            'section' { [void]$sb.AppendLine('>> ' + (Get-Text $e.Key)); [void]$sb.AppendLine('') }
            'row' { [void]$sb.AppendLine('    ' + ((Get-Text $e.Key) + ':').PadRight($pad) + $e.Value) }
            'text' { [void]$sb.AppendLine('    ' + $e.Value) }
            default { [void]$sb.AppendLine('') }
        }
    }
    return $sb.ToString()
}

function Write-HardwareModel {
    # Zeichnet das Modell in den Textkasten.
    param($Box, $Model)
    if (-not $Box -or $Box.IsDisposed) { return }
    $pad = Get-HardwareLabelPad -Model $Model
    foreach ($e in @($Model)) {
        switch ([string]$e.Kind) {
            'section' {
                $col = $null
                if ($e.Color) { $col = $script:Theme[[string]$e.Color] }
                if (-not $col) { $col = $script:Theme.Accent }
                $Box.SelectionColor = $col
                $Box.AppendText("  >> $(Get-Text $e.Key)`n`n")
                $Box.SelectionColor = $script:Theme.TextPrimary
            }
            'row' { $Box.AppendText(('    {0}{1}' -f ((Get-Text $e.Key) + ':').PadRight($pad), $e.Value) + "`n") }
            'text' { $Box.AppendText('    ' + $e.Value + "`n") }
            default { $Box.AppendText("`n") }
        }
    }
}

function Show-Hardware {
    Add-ViewHeader -TitleKey 'HWTitle' -SubtitleKey 'HWSubtitle' -Icon 'monitor'

    $txt = New-Object System.Windows.Forms.RichTextBox
    $txt.Location = New-Object System.Drawing.Point(25, 95)
    $txt.Size = New-Object System.Drawing.Size(900, 520)
    $txt.BackColor = $script:Theme.BgSecondary
    $txt.ForeColor = $script:Theme.TextPrimary
    $txt.ReadOnly = $true
    $txt.BorderStyle = 'None'
    $txt.Anchor = 'Top,Bottom,Left,Right'
    $txt.Font = (Get-AppFont -Family $script:MonoFont -Size 10)
    $script:pnlContent.Controls.Add($txt)
    $script:txtHardware = $txt

    $txt.SelectionColor = $script:Theme.Cyan
    $txt.AppendText("`n  ===============================================================`n")
    $txt.AppendText("   $(Get-Text 'HWTitle')`n")
    $txt.AppendText("  ===============================================================`n`n")

    Invoke-Deferred -Action {
        if (-not $script:txtHardware -or $script:txtHardware.IsDisposed) { return }
        $txt = $script:txtHardware
        try {
            # Die CIM-Abfragen brauchen auf vielen Rechnern mehrere Sekunden.
            # Sie laufen im Hintergrund; sobald sie fertig sind, wird die
            # Ansicht neu gezeichnet - sofern der Nutzer noch hier ist.
            if (-not (Request-HardwareInfo -OnReady {
                        if ($script:Config.CurrentView -eq 'Hardware') { Set-View -ViewName 'Hardware' }
                    })) {
                $script:HardwareModel = $null
                $txt.SelectionColor = $script:Theme.TextMuted
                $txt.AppendText("    $(Get-Text 'Loading')`n")
                return
            }
            $info = $script:Config.HardwareCache
            if ($null -eq $info -or $info.Failed) { throw (Get-Text 'LogHwFailed') }

            $model = Get-HardwareReportModel -Info $info -Memory (Get-MemorySnapshot) -Release (Get-WindowsRelease)
            Write-HardwareModel -Box $txt -Model $model
            # Erst jetzt steht ein vollstaendiges Modell fuer die Ausfuhr bereit.
            $script:HardwareModel = $model
        }
        catch {
            $script:HardwareModel = $null
            $txt.SelectionColor = $script:Theme.Error
            $txt.AppendText("  $(Get-Text 'Error'): $($_.Exception.Message)`n")
        }
    }

    $btnExport = New-Object System.Windows.Forms.Button
    $btnExport.Text = "{icon:file} $(Get-Text 'Export')"
    $btnExport.Location = New-Object System.Drawing.Point(945, 95)
    $btnExport.Anchor = 'Top,Right'
    $btnExport.Size = New-Object System.Drawing.Size(200, 45)
    $btnExport.BackColor = $script:Theme.Accent
    $btnExport.ForeColor = $script:Theme.TextWhite
    $btnExport.FlatStyle = 'Flat'
    $btnExport.FlatAppearance.BorderSize = 0
    $btnExport.Font = (Get-AppFont -Size 10 -Style 'Bold')
    $btnExport.Cursor = 'Hand'
    $btnExport.Add_Click({
            # Solange die Abfrage laeuft, stuende im Textkasten nur der
            # Ladehinweis - der landete frueher wortwoertlich in der Datei.
            if (-not $script:HardwareModel -or @($script:HardwareModel).Count -eq 0) {
                Write-Log (Get-Text 'HwExportBusy') 'WARNING'
                return
            }
            try {
                $dir = $script:Config.BackupDir
                if (-not (Test-Path -LiteralPath $dir)) {
                    [void](New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop)
                }
                $file = Join-Path $dir ("Hardware_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.txt')
                $head = "$(Get-Text 'HWTitle')  -  $env:COMPUTERNAME  -  $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
                $body = ConvertTo-HardwareText -Model $script:HardwareModel -Title $head
                [System.IO.File]::WriteAllText($file, $body, (New-Object System.Text.UTF8Encoding($false)))
                Write-Log "$(Get-Text 'Export'): $file" 'SUCCESS'
                Show-Info -Title (Get-Text 'Export') -Message $file
            }
            catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
        })
    $script:pnlContent.Controls.Add($btnExport)

    $btnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh.Text = "{icon:refresh} $(Get-Text 'Refresh')"
    $btnRefresh.Location = New-Object System.Drawing.Point(945, 150)
    $btnRefresh.Anchor = 'Top,Right'
    $btnRefresh.Size = New-Object System.Drawing.Size(200, 45)
    $btnRefresh.BackColor = $script:Theme.BgTertiary
    $btnRefresh.ForeColor = $script:Theme.TextPrimary
    $btnRefresh.FlatStyle = 'Flat'
    $btnRefresh.FlatAppearance.BorderSize = 0
    $btnRefresh.Font = (Get-AppFont -Size 10 -Style 'Bold')
    $btnRefresh.Cursor = 'Hand'
    $btnRefresh.Add_Click({
            $script:Config.HardwareCache = $null
            $script:HardwareModel = $null
            Clear-DataCache -Key 'HardwareRaw'
            Set-View -ViewName 'Hardware'
        })
    $script:pnlContent.Controls.Add($btnRefresh)

    $btnReport = New-Object System.Windows.Forms.Button
    $btnReport.Text = "{icon:file} $(Get-Text 'Report')"
    $btnReport.Location = New-Object System.Drawing.Point(945, 205)
    $btnReport.Size = New-Object System.Drawing.Size(200, 45)
    $btnReport.Anchor = 'Top,Right'
    $btnReport.BackColor = $script:Theme.Cyan
    $btnReport.ForeColor = $script:Theme.TextWhite
    $btnReport.FlatStyle = 'Flat'
    $btnReport.FlatAppearance.BorderSize = 0
    $btnReport.Font = (Get-AppFont -Size 10 -Style 'Bold')
    $btnReport.Cursor = 'Hand'
    $btnReport.Add_Click({ [void](Export-SystemReport) })
    Set-Tip $btnReport (Get-Text 'ReportDesc')
    $script:pnlContent.Controls.Add($btnReport)
}

# --------------------------------------------------------------------- DISK --
function Get-BrowserCacheTargets {
    # Nur die Zwischenspeicher-Ordner, niemals das Profil selbst. Die alte
    # Fassung nahm bei Firefox den gesamten Profilordner rekursiv - darin
    # liegen Lesezeichen, Chronik und gespeicherte Passwoerter. Das war kein
    # Aufraeumen mehr, das war Datenverlust.
    param([string]$Local, [string]$Roaming)
    $out = New-Object System.Collections.Generic.List[object]
    $add = {
        param($Proc, $Path)
        if (-not $Path) { return }
        $out.Add([pscustomobject]@{ Process = [string]$Proc; Path = [string]$Path })
    }
    $j = {
        param([string]$Base, [string]$Rest)
        if ([string]::IsNullOrWhiteSpace($Base)) { return '' }
        return ($Base.TrimEnd('\', '/') + '\' + $Rest)
    }
    foreach ($c in @(
            @{ P = 'chrome'; R = 'Google\Chrome\User Data' },
            @{ P = 'msedge'; R = 'Microsoft\Edge\User Data' },
            @{ P = 'brave'; R = 'BraveSoftware\Brave-Browser\User Data' },
            @{ P = 'opera'; R = 'Opera Software\Opera Stable' },
            @{ P = 'vivaldi'; R = 'Vivaldi\User Data' })) {
        $base = & $j $Local $c.R
        if (-not $base) { continue }
        # Chromium legt je Profil einen eigenen Zwischenspeicher an.
        foreach ($sub in @('Default\Cache', 'Default\Code Cache', 'Default\GPUCache',
                'Profile 1\Cache', 'Profile 2\Cache', 'ShaderCache')) {
            & $add $c.P (& $j $base $sub)
        }
    }
    # Firefox: der Zwischenspeicher liegt unter LOCALAPPDATA, das Profil mit
    # den Nutzerdaten unter APPDATA - genau diese beiden wurden verwechselt.
    $ff = & $j $Local 'Mozilla\Firefox\Profiles'
    if ($ff) { & $add 'firefox' $ff }
    return $out.ToArray()
}

function Get-BlockingBrowsers {
    # Ein laufender Browser haelt seinen Zwischenspeicher offen: geloescht
    # wird dann nichts, gemeldet wurde bisher trotzdem Erfolg.
    param($Targets, $ProcessNames)
    $running = @{}
    foreach ($p in @($ProcessNames)) {
        $n = ([string]$p).Trim().ToLowerInvariant()
        if ($n) { $running[$n] = $true }
    }
    $hit = New-Object System.Collections.Generic.List[string]
    foreach ($t in @($Targets)) {
        if (-not $t) { continue }
        $n = ([string]$t.Process).ToLowerInvariant()
        if ($running.ContainsKey($n) -and -not $hit.Contains([string]$t.Process)) {
            $hit.Add([string]$t.Process)
        }
    }
    return @($hit.ToArray() | Sort-Object)
}

function Get-DiskCleanTarget {
    # Jede Karte der Datentraeger-Ansicht beschreibt ihre Ablage genauso wie
    # die Schnellbereinigung. Dadurch gelten ueberall dieselben Schutzregeln:
    # Mindestalter, eigener Ordner, Nachmessen statt Behaupten.
    param([string]$Key)
    $win = [string]$env:SystemRoot
    $loc = [string]$env:LOCALAPPDATA
    $j = {
        param([string]$Base, [string]$Rest)
        if ([string]::IsNullOrWhiteSpace($Base)) { return '' }
        return ($Base.TrimEnd('\', '/') + '\' + $Rest)
    }
    switch ($Key) {
        'Temp' {
            return [pscustomobject]@{
                Key = 'DiskTemp'; LabelKey = 'DiskTemp'; Kind = 'dir'
                Paths = @([string]$env:TEMP, (& $j $loc 'Temp'), (& $j $win 'Temp'))
                MinAgeHours = 1; Services = @(); Confirm = $false
            }
        }
        'Browser' {
            return [pscustomobject]@{
                Key = 'DiskBrowser'; LabelKey = 'DiskBrowser'; Kind = 'dir'
                Paths = @((Get-BrowserCacheTargets -Local $loc -Roaming ([string]$env:APPDATA)) | ForEach-Object { $_.Path })
                MinAgeHours = 0; Services = @(); Confirm = $false
            }
        }
        'Logs' {
            return [pscustomobject]@{
                Key = 'DiskLogs'; LabelKey = 'DiskLogs'; Kind = 'dir'
                Paths = @((& $j $win 'Logs'))
                # Das laufende Komponentenprotokoll wird staendig beschrieben -
                # 24 Stunden Mindestalter laesst es in Ruhe.
                MinAgeHours = 24; Services = @(); Confirm = $false
            }
        }
        'WUCache' {
            return [pscustomobject]@{
                Key = 'DiskWUCache'; LabelKey = 'DiskWUCache'; Kind = 'dir'
                Paths = @((& $j $win 'SoftwareDistribution\Download'))
                MinAgeHours = 0; Services = @('wuauserv', 'bits'); Confirm = $true
            }
        }
        'WUReset' {
            return [pscustomobject]@{
                Key = 'RepairWU'; LabelKey = 'RepairWU'; Kind = 'dir'
                Paths = @((& $j $win 'SoftwareDistribution'))
                MinAgeHours = 0; Services = @('wuauserv', 'bits', 'cryptSvc'); Confirm = $true
            }
        }
        'Thumbnails' {
            return [pscustomobject]@{
                Key = 'DiskThumbnails'; LabelKey = 'DiskThumbnails'; Kind = 'dir'
                Paths = @((& $j $loc 'Microsoft\Windows\Explorer'))
                MinAgeHours = 0; Services = @(); Confirm = $false; Filter = 'thumbcache_*.db'
            }
        }
        'Recycle' {
            return [pscustomobject]@{
                Key = 'DiskRecycle'; LabelKey = 'CtRecycle'; Kind = 'recycle'
                Paths = @(Get-RecycleBinPaths -Drives (Get-FixedDriveRoots))
                MinAgeHours = 0; Services = @(); Confirm = $true
            }
        }
        default { return $null }
    }
}

function Measure-DiskTarget {
    # Dieselbe Entscheidung wie beim Loeschen - die angezeigte Zahl ist also
    # genau das, was hinterher frei wird.
    param($Target)
    $entries = @(Get-CleanFileEntries -Paths @($Target.Paths))
    if ($Target.PSObject.Properties['Filter'] -and $Target.Filter) {
        $entries = @($entries | Where-Object { $_.Name -like $Target.Filter })
    }
    return (Select-CleanDeletable -Entries $entries -Now (Get-Date) -MinAgeHours ([int]$Target.MinAgeHours) -Root '')
}

function Invoke-DiskClean {
    # Ein Weg fuer alle Karten: messen, fragen, loeschen, nachlesen, berichten.
    # Vorher loeschte jede Karte sofort los und meldete in jedem Fall Erfolg.
    param([string]$Key)
    $t = Get-DiskCleanTarget -Key $Key
    if (-not $t) { return }
    $label = Get-Text $t.LabelKey

    if ($t.Key -eq 'DiskBrowser') {
        $names = @()
        try {
            $procs = @(Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $_.ProcessName })
            $names = Get-BlockingBrowsers -Targets (Get-BrowserCacheTargets -Local ([string]$env:LOCALAPPDATA) -Roaming ([string]$env:APPDATA)) -ProcessNames $procs
        }
        catch { }
        if (@($names).Count -gt 0) {
            Write-Log "$label : $(Get-Text 'DiskBrowserOpen') - $((@($names)) -join ', ')" 'WARNING'
            return
        }
    }

    $measured = $null
    if ([string]$t.Kind -eq 'recycle') {
        $entries = @(Get-CleanFileEntries -Paths @($t.Paths))
        $bytes = 0.0
        foreach ($e in $entries) { $bytes += [double]$e.Length }
        $measured = @{ Bytes = $bytes; Count = @($entries).Count }
    }
    else {
        Show-BusyOverlay -Title $label -Cancellable
        try { $measured = Measure-DiskTarget -Target $t }
        finally { Hide-BusyOverlay }
        if (Test-BusyCancelled) { Write-Log (Get-Text 'BusyCancelled') 'WARNING'; return }
    }

    if ([int]$measured.Count -le 0) { Write-Log "$label : $(Get-Text 'CleanNothing')" 'INFO'; return }

    $ask = [bool]$t.Confirm -or [bool]$script:Config.CleanConfirm
    if ($ask) {
        $msg = '{0}{1}{1}{2}  /  {3} {4}' -f $label, "`n", (Get-FormattedBytes $measured.Bytes),
        $measured.Count, (Get-Text 'CleanFiles')
        if (-not (Show-Confirm -Message $msg)) { Write-Log (Get-Text 'BusyCancelled') 'WARNING'; return }
    }

    $row = [pscustomobject]@{
        Label = $label; Path = (@($t.Paths) | Select-Object -First 1); Paths = @($t.Paths)
        Kind = [string]$t.Kind; MinAgeHours = [int]$t.MinAgeHours; Bytes = [double]$measured.Bytes
        Files = [int]$measured.Count; Filter = $(if ($t.PSObject.Properties['Filter']) { $t.Filter } else { '' })
    }

    $svc = $null
    Show-BusyOverlay -Title $label -Cancellable
    try {
        if (@($t.Services).Count -gt 0) {
            Write-Log (Get-Text 'CleanSvcStop') 'INFO'
            $svc = Suspend-CleanServices -Names @($t.Services)
            # Haelt ein Dienst die Dateien weiter offen, wird nicht
            # weitergemacht - halb geleerte Update-Ablagen sind genau die
            # Ursache fuer die haengenden Updates, die man damit beheben wollte.
            if (-not $svc.Ok) {
                Write-Log "$label : $(Get-Text 'CleanSvcFail')" 'ERROR'
                Resume-CleanServices -Names @($svc.Resume)
                return
            }
        }
        $res = Clear-CleanTarget -Row $row -Index 1 -Count 1
        Write-Log (Format-CleanLine -Label $label -Bytes $res.Freed -Files $row.Files -Locked $res.Locked) 'INFO'
        if ([double]$res.Freed -le 0 -and [int]$res.Locked -gt 0) {
            Write-Log "$label : $(Get-Text 'DiskAllLocked')" 'WARNING'
        }
        else {
            Write-Log "$label : $(Get-Text 'CleanFreed') $(Get-FormattedBytes $res.Freed)" 'SUCCESS'
        }
    }
    finally {
        if ($svc -and @($svc.Resume).Count -gt 0) {
            Resume-CleanServices -Names @($svc.Resume)
            Write-Log (Get-Text 'CleanSvcStart') 'INFO'
        }
        Hide-BusyOverlay
    }
}

function Measure-DiskAnalysis {
    # Was waere insgesamt zu holen? Mit denselben Regeln gerechnet wie das
    # spaetere Loeschen, sonst verspricht die Zahl mehr als sie haelt.
    $lines = New-Object System.Collections.Generic.List[string]
    $sum = 0.0
    foreach ($key in @('Temp', 'Browser', 'Logs', 'WUCache', 'Thumbnails', 'Recycle')) {
        $t = Get-DiskCleanTarget -Key $key
        if (-not $t) { continue }
        $m = $null
        if ([string]$t.Kind -eq 'recycle') {
            $entries = @(Get-CleanFileEntries -Paths @($t.Paths))
            $b = 0.0
            foreach ($e in $entries) { $b += [double]$e.Length }
            $m = @{ Bytes = $b; Count = @($entries).Count }
        }
        else { $m = Measure-DiskTarget -Target $t }
        if ([int]$m.Count -le 0) { continue }
        $sum += [double]$m.Bytes
        $lines.Add((Format-CleanLine -Label (Get-Text $t.LabelKey) -Bytes $m.Bytes -Files $m.Count))
    }
    return @{ Total = $sum; Lines = $lines.ToArray() }
}

function Show-Disk {
    Add-ViewHeader -TitleKey 'DiskTitle' -SubtitleKey 'DiskSubtitle' -Icon 'save'

    $y = 95
    $x = 25
    # Umbruch nach der tatsaechlich verfuegbaren Breite statt fester 950 px
    $diskAvail = 1150
    try {
        if ($script:pnlContent -and $script:pnlContent.ClientSize.Width -gt 400) {
            $diskAvail = $script:pnlContent.ClientSize.Width - 50
        }
    }
    catch { }
    try {
        # Cached: switching back and forth between views re-ran this query
        $drives = Get-CachedData -Key 'LogicalDisks' -TtlSeconds 20 -Loader {
            # DriveInfo liefert dasselbe in Mikrosekunden statt per CIM-Abfrage.
            # Die Felder heissen bewusst wie bei Win32_LogicalDisk, damit alle
            # Verbraucher (Ansicht und Bericht) unveraendert bleiben.
            $out = New-Object System.Collections.Generic.List[object]
            try {
                foreach ($di in [System.IO.DriveInfo]::GetDrives()) {
                    if ($di.DriveType -ne [System.IO.DriveType]::Fixed) { continue }
                    if (-not $di.IsReady) { continue }
                    $out.Add([pscustomobject]@{
                            DeviceID   = $di.Name.TrimEnd('\')
                            VolumeName = [string]$di.VolumeLabel
                            Size       = [double]$di.TotalSize
                            FreeSpace  = [double]$di.TotalFreeSpace
                        })
                }
            }
            catch { }
            if ($out.Count -eq 0) {
                foreach ($d in (Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction SilentlyContinue)) {
                    $out.Add($d)
                }
            }
            return $out.ToArray()
        }
        foreach ($d in $drives) {
            if (-not $d.Size -or $d.Size -eq 0) { continue }
            $usedPct = [math]::Round((($d.Size - $d.FreeSpace) / $d.Size) * 100, 0)
            $color = if ($usedPct -gt 90) { $script:Theme.Error }
            elseif ($usedPct -gt 75) { $script:Theme.Warning }
            else { $script:Theme.Success }

            $card = New-Object System.Windows.Forms.Panel
            $card.Location = New-Object System.Drawing.Point($x, $y)
            $card.Size = New-Object System.Drawing.Size(270, 105)
            $card.BackColor = $script:Theme.BgCard

            $lbl = New-Object System.Windows.Forms.Label
            $lbl.Text = "{icon:disc} $($d.DeviceID)  $(Get-FormattedBytes ($d.Size - $d.FreeSpace)) / $(Get-FormattedBytes $d.Size)"
            $lbl.Font = (Get-AppFont -Size 10 -Style 'Bold')
            $lbl.ForeColor = $script:Theme.TextPrimary
            $lbl.Location = New-Object System.Drawing.Point(15, 15)
            $lbl.AutoSize = $true
            $lbl.BackColor = [System.Drawing.Color]::Transparent
            $card.Controls.Add($lbl)

            $bar = New-Object System.Windows.Forms.Panel
            $bar.Location = New-Object System.Drawing.Point(15, 50)
            $bar.Size = New-Object System.Drawing.Size(240, 14)
            $bar.BackColor = $script:Theme.BgTertiary
            $card.Controls.Add($bar)

            $fill = New-Object System.Windows.Forms.Panel
            $fill.Location = New-Object System.Drawing.Point(0, 0)
            $fillW = [int]([math]::Max(2, (240 * $usedPct / 100)))
            $fill.Size = New-Object System.Drawing.Size($fillW, 14)
            $fill.BackColor = $color
            $bar.Controls.Add($fill)

            $lblPct = New-Object System.Windows.Forms.Label
            $lblPct.Text = "$usedPct% $(Get-Text 'DiskTotal') - $(Get-FormattedBytes $d.FreeSpace) $(Get-Text 'LblFreeSpace')"
            $lblPct.Font = (Get-AppFont -Size 8)
            $lblPct.ForeColor = $script:Theme.TextMuted
            $lblPct.Location = New-Object System.Drawing.Point(15, 72)
            $lblPct.AutoSize = $true
            $lblPct.BackColor = [System.Drawing.Color]::Transparent
            $card.Controls.Add($lblPct)

            $script:pnlContent.Controls.Add($card)
            $x += 290
            if (($x + 270) -gt ($diskAvail + 25)) { $x = 25; $y += 120 }
        }
        if ($x -gt 25) { $y += 120 }
    }
    catch {
        Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR'
        $y += 20
    }

    $row1 = $y
    $row2 = $y + 170

    Add-Card -TitleKey 'DiskTemp' -DescKey 'DiskTempDesc' -BtnKey 'Clean' -Icon 'trash' -X 25 -Y $row1 -Color $script:Theme.Success -Action {
        Invoke-DiskClean -Key 'Temp'
    } | Out-Null

    Add-Card -TitleKey 'DiskBrowser' -DescKey 'DiskBrowserDesc' -BtnKey 'Clean' -Icon 'globe' -X 315 -Y $row1 -Color $script:Theme.Cyan -Action {
        Invoke-DiskClean -Key 'Browser'
    } | Out-Null

    Add-Card -TitleKey 'DiskLogs' -DescKey 'DiskLogsDesc' -BtnKey 'Clean' -Icon 'clipboard' -X 605 -Y $row1 -Color $script:Theme.Warning -Action {
        Invoke-DiskClean -Key 'Logs'
    } | Out-Null

    Add-Card -TitleKey 'DiskRecycle' -DescKey 'DiskRecycleDesc' -BtnKey 'Clean' -Icon 'refresh' -X 895 -Y $row1 -Color $script:Theme.Purple -Action {
        Invoke-DiskClean -Key 'Recycle'
    } | Out-Null

    Add-Card -TitleKey 'DiskWUCache' -DescKey 'DiskWUCacheDesc' -BtnKey 'Clean' -Icon 'package' -X 25 -Y $row2 -Color $script:Theme.Accent -Action {
        Invoke-DiskClean -Key 'WUCache'
    } | Out-Null

    Add-Card -TitleKey 'DiskThumbnails' -DescKey 'DiskThumbnailsDesc' -BtnKey 'Clean' -Icon 'image' -X 315 -Y $row2 -Color $script:Theme.Cyan -Action {
        Invoke-DiskClean -Key 'Thumbnails'
    } | Out-Null

    Add-Card -TitleKey 'DiskDeep' -DescKey 'DiskDeepDesc' -BtnKey 'Start' -Icon 'broom' -X 605 -Y $row2 -Color $script:Theme.Error -Action {
        $saved = Invoke-QuickClean
        Write-Log "$(Get-Text 'DiskDeep') - $(Get-Text 'DlgCompleted'): $(Get-FormattedBytes $saved)" 'SUCCESS'
    } | Out-Null

    Add-Card -TitleKey 'Analyze' -DescKey 'DiskSubtitle' -BtnKey 'Analyze' -Icon 'search' -X 895 -Y $row2 -Color $script:Theme.Purple -Action {
        Show-BusyOverlay -Title (Get-Text 'Analyze') -Cancellable
        $res = $null
        try { $res = Measure-DiskAnalysis }
        finally { Hide-BusyOverlay }
        if (-not $res) { return }
        foreach ($line in @($res.Lines)) { Write-Log $line 'INFO' }
        Write-Log "$(Get-Text 'Analyze'): $(Get-FormattedBytes $res.Total)" 'INFO'
    } | Out-Null
}

# ------------------------------------------------------------------- GAMING --
function Set-TcpOptimization {
    Write-Log "$(Get-Text 'GameTCP')..." 'INFO'
    $cmds = @(
        'int tcp set global autotuninglevel=normal',
        'int tcp set global ecncapability=enabled',
        'int tcp set global timestamps=disabled',
        'int tcp set global rss=enabled',
        'int tcp set global nonsackrttresiliency=disabled',
        'int tcp set global initialRto=2000',
        'int tcp set supplemental internet congestionprovider=ctcp'
    )
    $okCount = 0
    $step = 0
    Show-BusyOverlay -Title (Get-Text 'GameTCP') -Status 'netsh ...'
    foreach ($c in $cmds) {
        $step++
        Update-BusyOverlay -Status "netsh $c" -Percent ([int](($step / [double]$cmds.Count) * 100))
        try {
            $code = Invoke-SystemCommand -File 'netsh.exe' -Arguments $c -TimeoutSec 30 -Label "netsh $c"
            if ($code -eq 0) { $okCount++ }
            else {
                # nonsackrttresiliency / initialRto / ctcp do not exist on every
                # Windows build - say so instead of failing silently.
                Write-Log "netsh $c -> exit $code" 'WARNING'
            }
        }
        catch { Write-Log "netsh $c : $($_.Exception.Message)" 'WARNING' }
    }
    Write-Log "netsh TCP: $okCount / $($cmds.Count) $(Get-Text 'Success')" 'INFO'
    # Deprecated on modern builds - failures are expected and ignored
    foreach ($c in @('int tcp set global chimney=disabled', 'int tcp set global netdma=disabled')) {
        [void](Invoke-SystemCommand -File 'netsh.exe' -Arguments $c -TimeoutSec 30)
    }
    try {
        $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
        Backup-RegistryKey -Path $k -Name 'TcpGaming' | Out-Null
        [void](Set-RegistryValue -Path $k -Name 'NetworkThrottlingIndex' -Value 0xFFFFFFFF -Type DWord -Label 'Gaming/TCP' -Quiet)
        [void](Set-RegistryValue -Path $k -Name 'SystemResponsiveness' -Value 0 -Type DWord -Label 'Gaming/TCP' -Quiet)
    }
    catch { }
    Hide-BusyOverlay
    Write-Log "$(Get-Text 'GameTCP'): $(Get-Text 'DlgCompleted')" 'SUCCESS'
}

function Invoke-MegaGamingMode {
    if (-not (Show-Confirm -Message (Get-Text 'DlgRisk'))) { return }
    Write-Log "=== $(Get-Text 'GameMega') ===" 'TITLE'
    [void](New-RestorePoint)
    Set-UltimatePerformance
    Set-TcpOptimization

    $tweaks = @(
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Value = 0 },
        @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_FSEBehaviorMode'; Value = 2 },
        @{ Path = 'HKCU:\Software\Microsoft\GameBar'; Name = 'AllowAutoGameMode'; Value = 1 },
        @{ Path = 'HKCU:\Software\Microsoft\GameBar'; Name = 'AutoGameModeEnabled'; Value = 1 },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'GPU Priority'; Value = 8 },
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name = 'Priority'; Value = 6 },
        @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; Name = 'HwSchMode'; Value = 2 }
    )
    foreach ($t in $tweaks) {
        try {
            if (-not (Set-RegistryValue -Path $t.Path -Name $t.Name -Value $t.Value -Type DWord -Label 'Mega-Gaming')) {
                Write-Log "$($t.Name): $(Get-Text 'Error')" 'WARNING'
            }
        }
        catch { Write-Log "$($t.Name): $($_.Exception.Message)" 'WARNING' }
    }

    Optimize-Memory
    Write-Log "$(Get-Text 'GameMega'): $(Get-Text 'DlgCompleted') - $(Get-Text 'DlgRestartReq')" 'SUCCESS'
    Show-WarningDialog -Title (Get-Text 'GameMega') -Message (Get-Text 'DlgRestartReq') | Out-Null
}

function Show-Gaming {
    Add-ViewHeader -TitleKey 'GameTitle' -SubtitleKey 'GameSubtitle' -Icon 'gamepad'

    $r1 = 95; $r2 = 265; $r3 = 435

    Add-Card -TitleKey 'GamePower' -DescKey 'GamePowerDesc' -BtnKey 'Enable' -Icon 'bolt' -X 25 -Y $r1 -Color $script:Theme.Warning -Action {
        Set-UltimatePerformance
    } -StateCheck {
        Test-TweakApplied -Entries @(
            @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes'; Name = 'ActivePowerScheme'; Value = 'e9a42b02-d5df-448d-aa00-03f14749eb61' }
        )
    } | Out-Null

    Add-Card -TitleKey 'GameMode' -DescKey 'GameModeDesc' -BtnKey 'Enable' -Icon 'target' -X 315 -Y $r1 -Color $script:Theme.Success -Action {
        try {
            [void](Set-RegistryValue -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value 1 -Type DWord -Label (Get-Text 'GameMode'))
            [void](Set-RegistryValue -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AllowAutoGameMode' -Value 1 -Type DWord -Label (Get-Text 'GameMode'))
            Write-Log "$(Get-Text 'GameMode'): $(Get-Text 'Success')" 'SUCCESS'
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    } -StateCheck {
        Test-TweakApplied -Entries @(
            @{ Path = 'HKCU:\Software\Microsoft\GameBar'; Name = 'AutoGameModeEnabled'; Value = 1 },
            @{ Path = 'HKCU:\Software\Microsoft\GameBar'; Name = 'AllowAutoGameMode'; Value = 1 }
        )
    } | Out-Null

    Add-Card -TitleKey 'GameTCP' -DescKey 'GameTCPDesc' -BtnKey 'Optimize' -Icon 'globe' -X 605 -Y $r1 -Color $script:Theme.Cyan -Action {
        Set-TcpOptimization
    } -StateCheck {
        Test-TweakApplied -Entries @(
            @{ Path = 'HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile'; Name = 'SystemResponsiveness'; Value = 0 },
            @{ Path = 'HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile'; Name = 'NetworkThrottlingIndex'; Value = -1 }
        )
    } | Out-Null

    Add-Card -TitleKey 'GameGPU' -DescKey 'GameGPUDesc' -BtnKey 'Enable' -Icon 'monitor' -X 895 -Y $r1 -Color $script:Theme.Purple -Action {
        try {
            $k = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
            Backup-RegistryKey -Path $k -Name 'GraphicsDrivers' | Out-Null
            [void](Set-RegistryValue -Path $k -Name 'HwSchMode' -Value 2 -Type DWord -Label (Get-Text 'GameGPU'))
            Set-RebootHint
            Write-Log "$(Get-Text 'GameGPU'): $(Get-Text 'DlgRestartReq')" 'SUCCESS'
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    } -StateCheck {
        Test-TweakApplied -Entries @(
            @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; Name = 'HwSchMode'; Value = 2 }
        )
    } | Out-Null

    Add-Card -TitleKey 'GameDVR' -DescKey 'GameDVRDesc' -BtnKey 'Disable' -Icon 'camera' -X 25 -Y $r2 -Color $script:Theme.Error -Action {
        try {
            [void](Set-RegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0 -Type DWord -Label (Get-Text 'GameDVR'))
            [void](Set-RegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Value 0 -Type DWord -Label (Get-Text 'GameDVR'))
            Write-Log "$(Get-Text 'GameDVR'): $(Get-Text 'Success')" 'SUCCESS'
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    } -StateCheck {
        Test-TweakApplied -Entries @(
            @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_Enabled'; Value = 0 },
            @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name = 'AllowGameDVR'; Value = 0 }
        )
    } | Out-Null

    Add-Card -TitleKey 'GameMouseAccel' -DescKey 'GameMouseAccelDesc' -BtnKey 'Disable' -Icon 'mouse' -X 315 -Y $r2 -Color $script:Theme.Accent -Action {
        try {
            Backup-RegistryKey -Path 'HKCU:\Control Panel\Mouse' -Name 'Mouse' | Out-Null
            foreach ($mv in @('MouseSpeed', 'MouseThreshold1', 'MouseThreshold2')) {
                [void](Set-RegistryValue -Path 'HKCU:\Control Panel\Mouse' -Name $mv -Value '0' -Type String -Label (Get-Text 'GameMouseAccel'))
            }
            Write-Log "$(Get-Text 'GameMouseAccel'): $(Get-Text 'Success')" 'SUCCESS'
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    } -StateCheck {
        Test-TweakApplied -Entries @(
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseSpeed'; Value = '0' },
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold1'; Value = '0' },
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold2'; Value = '0' }
        )
    } | Out-Null

    Add-Card -TitleKey 'GameFullscreen' -DescKey 'GameFullscreenDesc' -BtnKey 'Enable' -Icon 'image' -X 605 -Y $r2 -Color $script:Theme.Success -Action {
        try {
            [void](Set-RegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_FSEBehaviorMode' -Value 2 -Type DWord -Label (Get-Text 'GameFullscreen'))
            [void](Set-RegistryValue -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_DXGIHonorFSEWindowsCompatible' -Value 1 -Type DWord -Label (Get-Text 'GameFullscreen'))
            Write-Log "$(Get-Text 'GameFullscreen'): $(Get-Text 'Success')" 'SUCCESS'
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    } -StateCheck {
        Test-TweakApplied -Entries @(
            @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_FSEBehaviorMode'; Value = 2 },
            @{ Path = 'HKCU:\System\GameConfigStore'; Name = 'GameDVR_DXGIHonorFSEWindowsCompatible'; Value = 1 }
        )
    } | Out-Null

    Add-Card -TitleKey 'GameHPET' -DescKey 'GameHPETDesc' -BtnKey 'Disable' -Icon 'clock' -X 895 -Y $r2 -Color $script:Theme.Warning -Action {
        if (-not (Show-Confirm -Message (Get-Text 'DlgRisk'))) { return }
        Show-BusyOverlay -Title (Get-Text 'GameHPET') -Status 'bcdedit ...'
        try {
            [void](Invoke-SystemCommand -File 'bcdedit.exe' -Arguments '/deletevalue useplatformclock' -TimeoutSec 60 -Label 'bcdedit')
            Set-RebootHint
            Update-BusyOverlay -Status 'bcdedit /set disabledynamictick yes' -Percent 50
            [void](Invoke-SystemCommand -File 'bcdedit.exe' -Arguments '/set disabledynamictick yes' -TimeoutSec 60 -Label 'bcdedit')
            Write-Log "$(Get-Text 'GameHPET'): $(Get-Text 'DlgRestartReq')" 'SUCCESS'
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
        finally { Hide-BusyOverlay }
    } | Out-Null

    Add-Card -TitleKey 'GameMega' -DescKey 'GameMegaDesc' -BtnKey 'Start' -Icon 'rocket' -X 25 -Y $r3 -Color $script:Theme.Error -Action {
        Invoke-MegaGamingMode
    } -W 560 | Out-Null
}

# ------------------------------------------------------------------ PRIVACY --
function Set-PrivacyTweak {
    param(
        [Parameter(Mandatory)][array]$Entries,
        [string]$Label = 'Privacy'
    )

    $ok = 0
    $failed = @()
    foreach ($e in $Entries) {
        $type = if ($e.ContainsKey('Type')) { $e.Type } else { 'DWord' }
        if (Set-RegistryValue -Path $e.Path -Name $e.Name -Value $e.Value -Type $type -Label $Label) { $ok++ }
        else { $failed += "$($e.Name)" }
    }
    $total = @($Entries).Count
    Write-TweakOutcome -Label $Label -Ok $ok -Total $total -Failed $failed
    return $ok
}

function Get-TweakOutcome {
    # Entscheidet ueber Protokollstufe und Begruendung. Frueher meldete
    # Set-PrivacyTweak selbst dann 'SUCCESS', wenn KEIN einziger Wert
    # geschrieben werden konnte - "0/5 Erfolgreich" stand gruen im Protokoll.
    param(
        [int]$Ok = 0,
        [int]$Total = 0,
        [bool]$IsAdmin = $true
    )
    if ($Total -le 0) { return @{ Level = 'WARNING'; Key = 'TwkNone'; ReasonKey = '' } }
    if ($Ok -ge $Total) { return @{ Level = 'SUCCESS'; Key = 'TwkAllOk'; ReasonKey = '' } }
    $reason = if ($IsAdmin) { 'TwkLocked' } else { 'TwkNoAdmin' }
    if ($Ok -le 0) { return @{ Level = 'ERROR'; Key = 'TwkNone'; ReasonKey = $reason } }
    return @{ Level = 'WARNING'; Key = 'TwkPartial'; ReasonKey = $reason }
}

function Write-TweakOutcome {
    param([string]$Label = '', [int]$Ok = 0, [int]$Total = 0, [string[]]$Failed = @())
    $isAdm = $true
    try { $isAdm = [bool]$script:IsAdmin } catch { }
    $r = Get-TweakOutcome -Ok $Ok -Total $Total -IsAdmin $isAdm
    $msg = "$Label : $Ok/$Total $(Get-Text $r.Key)"
    if ($r.ReasonKey) { $msg = "$msg - $(Get-Text $r.ReasonKey)" }
    Write-Log $msg $r.Level
    # Fehlgeschlagene Werte benennen, sonst sucht man sie im Protokoll nicht.
    if (@($Failed).Count -gt 0) {
        $list = (@($Failed) | Select-Object -First 6) -join ', '
        if (@($Failed).Count -gt 6) { $list = "$list ..." }
        Write-Log "$Label : $list" 'WARNING'
    }
    # Keine eigene Kurzmeldung: Write-Log loest bei WARNING und ERROR bereits
    # einen Toast bzw. eine Sprechblase aus - sonst erschiene sie doppelt.
}

function Show-Privacy {
    Add-ViewHeader -TitleKey 'PrivTitle' -SubtitleKey 'PrivSubtitle' -Icon 'lock'

    $defs = @(
        @{ Key = 'PrivTelemetry'; Icon = 'signal'; Color = $script:Theme.Error; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'AllowTelemetry'; Value = 0 },
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; Name = 'AllowTelemetry'; Value = 0 }
            )
        },
        @{ Key = 'PrivRecall'; Icon = 'camera'; Color = $script:Theme.Error; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableAIDataAnalysis'; Value = 1 },
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'AllowRecallEnablement'; Value = 0 },
                @{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableAIDataAnalysis'; Value = 1 }
            )
        },
        @{ Key = 'PrivCopilot'; Icon = 'chat'; Color = $script:Theme.Purple; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'; Name = 'TurnOffWindowsCopilot'; Value = 1 },
                @{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'; Name = 'TurnOffWindowsCopilot'; Value = 1 },
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowCopilotButton'; Value = 0 }
            )
        },
        @{ Key = 'PrivAds'; Icon = 'megaphone'; Color = $script:Theme.Warning; Entries = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name = 'Enabled'; Value = 0 },
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'; Name = 'DisabledByGroupPolicy'; Value = 1 }
            )
        },
        # Cortana, WiFi Sense und Timeline gibt es unter Windows 11 nicht mehr -
        # die Richtlinien liefen dort ins Leere und meldeten trotzdem Erfolg.
        # Sie erscheinen jetzt nur noch auf Windows 10 (Build < 22000).
        @{ Key = 'PrivCortana'; MaxBuild = 21999; Icon = 'mic'; Color = $script:Theme.Purple; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'AllowCortana'; Value = 0 }
            )
        },
        @{ Key = 'PrivFeedback'; Icon = 'chat'; Color = $script:Theme.Cyan; Entries = @(
                @{ Path = 'HKCU:\Software\Microsoft\Siuf\Rules'; Name = 'NumberOfSIUFInPeriod'; Value = 0 },
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'DoNotShowFeedbackNotifications'; Value = 1 }
            )
        },
        @{ Key = 'PrivBing'; Icon = 'search'; Color = $script:Theme.Accent; Entries = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'BingSearchEnabled'; Value = 0 },
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'CortanaConsent'; Value = 0 }
            )
        },
        @{ Key = 'PrivActivity'; Icon = 'clipboard'; Color = $script:Theme.Success; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'EnableActivityFeed'; Value = 0 },
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'PublishUserActivities'; Value = 0 }
            )
        },
        @{ Key = 'PrivLocation'; Icon = 'pin'; Color = $script:Theme.Warning; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'; Name = 'Value'; Value = 'Deny'; Type = 'String' }
            )
        },
        @{ Key = 'PrivWiFiSense'; MaxBuild = 21999; Icon = 'signal'; Color = $script:Theme.Cyan; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting'; Name = 'Value'; Value = 0 },
                @{ Path = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots'; Name = 'Value'; Value = 0 }
            )
        },
        @{ Key = 'PrivClipboard'; Icon = 'file'; Color = $script:Theme.Purple; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'AllowClipboardHistory'; Value = 0 },
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'AllowCrossDeviceClipboard'; Value = 0 }
            )
        },
        @{ Key = 'PrivDiagnostics'; Icon = 'pulse'; Color = $script:Theme.Error; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'LimitDiagnosticLogCollection'; Value = 1 },
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'DisableOneSettingsDownloads'; Value = 1 }
            )
        },
        @{ Key = 'PrivTailored'; Icon = 'target'; Color = $script:Theme.Accent; Entries = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'; Name = 'TailoredExperiencesWithDiagnosticDataEnabled'; Value = 0 },
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SilentInstalledAppsEnabled'; Value = 0 }
            )
        },
        @{ Key = 'PrivTimeline'; MaxBuild = 21999; Icon = 'clock'; Color = $script:Theme.Success; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name = 'UploadUserActivities'; Value = 0 }
            )
        },

        # --- Nur Windows 11: Oberflaechen, die es unter Windows 10 nicht gibt --
        @{ Key = 'PrivClickToDo'; MinBuild = 22000; Icon = 'target'; Color = $script:Theme.Error; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableClickToDo'; Value = 1 },
                @{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableClickToDo'; Value = 1 },
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'; Name = 'DisableSettingsAgent'; Value = 1 }
            )
        },
        @{ Key = 'PrivWidgets'; MinBuild = 22000; Icon = 'window'; Color = $script:Theme.Warning; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'AllowNewsAndInterests'; Value = 0 },
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarDa'; Value = 0 }
            )
        },
        @{ Key = 'PrivWebSearch'; MinBuild = 22000; Icon = 'search'; Color = $script:Theme.Cyan; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Value = 1 },
                @{ Path = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'; Name = 'DisableSearchBoxSuggestions'; Value = 1 }
            )
        },
        @{ Key = 'PrivEdgeAI'; MinBuild = 22000; Icon = 'globe'; Color = $script:Theme.Purple; Entries = @(
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'HubsSidebarEnabled'; Value = 0 },
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'EdgeEntraCopilotPageContext'; Value = 0 }
            )
        }
    )

    # Nur anzeigen, was auf dieser Windows-Version ueberhaupt etwas bewirkt.
    $rel = $null
    try { $rel = Get-WindowsRelease } catch { }
    if ($rel -and $rel.Build -gt 0) {
        $defs = @($defs | Where-Object {
                $okMin = (-not $_.ContainsKey('MinBuild')) -or ($rel.Build -ge [int]$_.MinBuild)
                $okMax = (-not $_.ContainsKey('MaxBuild')) -or ($rel.Build -le [int]$_.MaxBuild)
                $okMin -and $okMax
            })
    }

    $x = 25; $y = 95; $col = 0
    foreach ($d in $defs) {
        # Copy per iteration and bake into the closure: without this every card
        # would apply the entries of the LAST loop item.
        $entries = $d.Entries
        $label = Get-Text $d.Key
        $action = {
            Set-PrivacyTweak -Entries $entries -Label $label | Out-Null
            Update-CardStates
        }.GetNewClosure()
        $check = { Test-TweakApplied -Entries $entries }.GetNewClosure()

        Add-Card -TitleKey $d.Key -DescKey 'PrivSubtitle' -BtnKey 'Apply' -Icon $d.Icon `
            -Action $action -X $x -Y $y -Color $d.Color -StateCheck $check | Out-Null

        $col++
        if ($col -ge 4) { $col = 0; $x = 25; $y += 170 } else { $x += 290 }
    }

    if ($col -ne 0) { $y += 170 }

    $btnAll = New-Object System.Windows.Forms.Button
    $btnAll.Text = "{icon:shield} $(Get-Text 'PrivApplyAll')"
    $btnAll.Location = New-Object System.Drawing.Point(25, $y)
    $btnAll.Size = New-Object System.Drawing.Size(560, 55)
    $btnAll.BackColor = $script:Theme.Error
    $btnAll.ForeColor = $script:Theme.TextWhite
    $btnAll.FlatStyle = 'Flat'
    $btnAll.FlatAppearance.BorderSize = 0
    $btnAll.Font = (Get-AppFont -Size 12 -Style 'Bold')
    $btnAll.Cursor = 'Hand'
    $btnAll.Tag = $defs
    $btnAll.Add_Click({
            if (-not (Show-Confirm -Message (Get-Text 'DlgConfirm'))) { return }
            $saved = $script:MainForm.Cursor
            try {
                $script:MainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
                Write-Log "=== $(Get-Text 'PrivApplyAll') ===" 'TITLE'
                foreach ($d in $this.Tag) {
                    Set-PrivacyTweak -Entries $d.Entries -Label (Get-Text $d.Key) | Out-Null
                    [System.Windows.Forms.Application]::DoEvents()
                }
                Update-CardStates
                Write-Log "$(Get-Text 'DlgCompleted')" 'SUCCESS'
            }
            catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
            finally { $script:MainForm.Cursor = $saved }
        })
    $script:pnlContent.Controls.Add($btnAll)
}

# ----------------------------------------------------------------- DEFENDER --
function Test-ExclusionExtension {
    # -ExclusionExtension erwartet eine Dateiendung, nicht einen Pfad.
    param([string]$Name)
    $n = ([string]$Name).Trim().Trim('"').TrimStart('.')
    if ([string]::IsNullOrWhiteSpace($n)) { return $false }
    return ($n -match '^[A-Za-z0-9]{1,10}$')
}

function Get-ExclusionKindFromInput {
    # Ein Feld fuer alles: Pfad, Prozess oder Dateiendung. Vorher konnte man
    # ueber die Oberflaeche nur Pfade und Prozesse anlegen - Dateiendungen
    # liessen sich entfernen, aber nie hinzufuegen.
    param([string]$Text)
    $t = ([string]$Text).Trim().Trim('"')
    if ([string]::IsNullOrWhiteSpace($t)) { return @{ Kind = ''; Value = ''; ReasonKey = 'DefBadName' } }
    if ($t.StartsWith('.')) {
        if (Test-ExclusionExtension -Name $t) { return @{ Kind = 'Extension'; Value = $t.TrimStart('.').ToLowerInvariant(); ReasonKey = '' } }
        return @{ Kind = ''; Value = $t; ReasonKey = 'DefBadEntry' }
    }
    # Ein voller Pfad auf eine Programmdatei ist bei Defender ein Prozess-
    # ausschluss, kein Pfadausschluss - sonst waere der ganze Ordner frei.
    if (Test-ExclusionProcessName -Name $t) { return @{ Kind = 'Process'; Value = $t; ReasonKey = '' } }
    if ($t -match '^[A-Za-z]:\\' -or $t.StartsWith('\\')) { return @{ Kind = 'Path'; Value = $t.TrimEnd('\'); ReasonKey = '' } }
    return @{ Kind = ''; Value = $t; ReasonKey = 'DefBadEntry' }
}

function Get-ExclusionExtensionRisk {
    # Eine ausgenommene Dateiendung gilt ueberall auf dem Rechner. Bei
    # ausfuehrbaren Formaten heisst das: Schadsoftware muss sich nur so
    # nennen. Das gehoert in der Liste sichtbar gemacht.
    param([string]$Extension)
    $e = ([string]$Extension).Trim().TrimStart('.').ToLowerInvariant()
    if (-not $e) { return @{ Level = 'ok'; ReasonKey = '' } }
    $exec = @('exe', 'com', 'scr', 'bat', 'cmd', 'ps1', 'vbs', 'js', 'jse', 'wsf', 'hta', 'dll', 'msi', 'lnk', 'reg')
    if ($exec -contains $e) { return @{ Level = 'warn'; ReasonKey = 'DefRiskExt' } }
    return @{ Level = 'ok'; ReasonKey = '' }
}

function Get-DefenderExclusionRows {
    # Reines Zeilenmodell: aus den drei Listen von Get-MpPreference werden
    # bewertete Zeilen. Die Ansicht baute sie frueher in drei Schleifen
    # zusammen und zeigte dabei nirgends an, ob ein Eintrag gefaehrlich ist -
    # gerade geerbte Ausnahmen wie ein ganzer Benutzerordner blieben unsichtbar.
    param($Paths, $Processes, $Extensions)
    $rows = New-Object System.Collections.Generic.List[object]
    $seen = @{}
    $add = {
        param([string]$Kind, [string]$Value, [string]$TypeKey, [string]$Icon, [string]$ColorName, $Risk)
        $v = ([string]$Value).Trim()
        if (-not $v) { return }
        $k = "$Kind|$($v.ToLowerInvariant())"
        if ($seen.ContainsKey($k)) { return }
        $seen[$k] = $true
        $level = if ($Risk) { [string]$Risk.Level } else { 'ok' }
        $rows.Add([pscustomobject]@{
                Kind      = $Kind
                Key       = $k
                Value     = $v
                TypeKey   = $TypeKey
                Icon      = $Icon
                ColorName = $ColorName
                Level     = $level
                ReasonKey = $(if ($Risk) { [string]$Risk.ReasonKey } else { '' })
                Risky     = ($level -ne 'ok')
            })
    }
    foreach ($p in @($Paths)) { & $add 'Path' $p 'DefTypePath' 'folder' 'Success' (Test-DefenderExclusionRisk -Path $p) }
    foreach ($p in @($Processes)) {
        # Ein Prozessausschluss mit vollem Pfad wird wie ein Pfad bewertet,
        # ein blosser Dateiname ist immer heikel: er gilt fuer jede Datei
        # dieses Namens, egal wo sie liegt.
        $risk = if ($p -match '^[A-Za-z]:\\') { Test-DefenderExclusionRisk -Path $p } else { @{ Level = 'warn'; ReasonKey = 'DefRiskAnyPath' } }
        & $add 'Process' $p 'DefTypeProcess' 'gear' 'Cyan' $risk
    }
    foreach ($p in @($Extensions)) { & $add 'Extension' $p 'DefTypeExt' 'file' 'Warning' (Get-ExclusionExtensionRisk -Extension $p) }
    return @($rows.ToArray())
}

function Get-DefenderRowSummary {
    param($Rows)
    $risky = 0
    foreach ($r in @($Rows)) { if ($r -and $r.Risky) { $risky++ } }
    return @{ Total = @($Rows).Count; Risky = $risky }
}

function Show-Defender {
    Add-ViewHeader -TitleKey 'DefTitle' -SubtitleKey 'DefSubtitle' -Icon 'shield'

    [void](Add-ListSearchBox -Name 'Defender' -PlaceholderKey 'DefSearch' -Y 155 -Action {
            param($q) Update-DefenderList -Filter $q
        })

    $lst = New-Object System.Windows.Forms.ListView
    $lst.Location = New-Object System.Drawing.Point(25, 200)
    $lst.Size = New-Object System.Drawing.Size(840, 415)
    $lst.View = 'Details'
    $lst.FullRowSelect = $true
    $lst.GridLines = $false
    $lst.BackColor = $script:Theme.BgSecondary
    $lst.ForeColor = $script:Theme.TextPrimary
    $lst.BorderStyle = 'None'
    $lst.Anchor = 'Top,Bottom,Left,Right'
    $lst.Font = (Get-AppFont -Size 9)
    [void]$lst.Columns.Add((Get-Text 'DefType'), 140)
    [void]$lst.Columns.Add((Get-Text 'DefValue'), 440)
    [void]$lst.Columns.Add((Get-Text 'DefColNote'), 260)
    $script:pnlContent.Controls.Add($lst)
    Set-ListViewColumnFit -ListView $lst -Weights @(1, 4, 2) -Name 'Defender'
    Set-ListViewSortable -ListView $lst -Name 'Defender'
    Add-ListContextMenu -ListView $lst -Name 'Defender'
    $script:lstDefender = $lst

    $txtPath = New-Object System.Windows.Forms.TextBox
    $txtPath.Location = New-Object System.Drawing.Point(25, 110)
    $txtPath.Size = New-Object System.Drawing.Size(600, 30)
    $txtPath.BackColor = $script:Theme.BgTertiary
    $txtPath.ForeColor = $script:Theme.TextPrimary
    $txtPath.BorderStyle = 'FixedSingle'
    $txtPath.Anchor = 'Top,Left,Right'
    $txtPath.Font = (Get-AppFont -Size 10)
    $script:pnlContent.Controls.Add($txtPath)
    Set-Placeholder -TextBox $txtPath -Text "$(Get-Text 'DefAddEntry')  (game.exe  /  D:\Spiele  /  .iso)"
    $script:txtDefPath = $txtPath

    $mkBtn = {
        param($text, $x, $y, $w, $color)
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $text
        $b.Location = New-Object System.Drawing.Point($x, $y)
        $b.Size = New-Object System.Drawing.Size($w, 32)
        $b.BackColor = $color
        $b.ForeColor = $script:Theme.TextWhite
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderSize = 0
        $b.Font = (Get-AppFont -Size 9 -Style 'Bold')
        $b.Cursor = 'Hand'
        return $b
    }

    $btnAddPath = & $mkBtn "{icon:folder} $(Get-Text 'DefAddPath')" 640 110 150 $script:Theme.Success
    $btnAddPath.Add_Click({
            try {
                $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
                try {
                    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                        $sel = $dlg.SelectedPath
                        if (Confirm-DefenderExclusion -Value $sel) {
                            $res = Invoke-DefenderExclusionBatch -Mode 'add' -Label (Get-Text 'DefAddPath') `
                                -Items @([pscustomobject]@{ Kind = 'Path'; Value = $sel })
                            if ($res.Ok -gt 0) {
                                Write-Log "$(Get-Text 'DefAddPath'): $sel" 'SUCCESS'
                                Update-ChangeList
                            }
                            Update-DefenderList -Force
                        }
                    }
                }
                finally { $dlg.Dispose() }
            }
            catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
        })
    $script:pnlContent.Controls.Add($btnAddPath)

    $btnAddProc = & $mkBtn "{icon:plus} $(Get-Text 'DefAddEntry')" 800 110 150 $script:Theme.Cyan
    $btnAddProc.Add_Click({
            try {
                $text = $script:txtDefPath.Text.Trim()
                if (-not $text) { return }
                # Ein Feld, drei Arten: die Eingabe entscheidet selbst, ob sie
                # Pfad, Prozess oder Dateiendung ist. '*' und Unsinn fallen
                # dabei heraus, bevor irgendetwas ausgenommen wird.
                $parsed = Get-ExclusionKindFromInput -Text $text
                if (-not $parsed.Kind) {
                    Write-Log "$(Get-Text $parsed.ReasonKey): $text" 'ERROR'
                    return
                }
                if ($parsed.Kind -eq 'Extension') {
                    $risk = Get-ExclusionExtensionRisk -Extension $parsed.Value
                    $msg = ".$($parsed.Value)"
                    if ($risk.ReasonKey) { $msg = "$msg`n`n$(Get-Text $risk.ReasonKey)" }
                    if (-not (Show-Confirm -Message "$(Get-Text 'DefConfirm')`n`n$msg")) { return }
                }
                elseif (-not (Confirm-DefenderExclusion -Value $parsed.Value)) { return }
                $res = Invoke-DefenderExclusionBatch -Mode 'add' -Label (Get-Text 'DefAddEntry') `
                    -Items @([pscustomobject]@{ Kind = $parsed.Kind; Value = $parsed.Value })
                if ($res.Ok -gt 0) {
                    Write-Log "$(Get-Text 'DefAddEntry'): $($parsed.Value)" 'SUCCESS'
                    $script:txtDefPath.Clear()
                    Update-ChangeList
                }
                Update-DefenderList -Force
            }
            catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
        })
    $script:pnlContent.Controls.Add($btnAddProc)

    $btnRemove = & $mkBtn "{icon:trash} $(Get-Text 'DefRemove')" 885 200 160 $script:Theme.Error
    $btnRemove.Add_Click({
            try {
                if (-not $script:lstDefender -or $script:lstDefender.SelectedItems.Count -eq 0) { return }
                $items = @()
                foreach ($item in @($script:lstDefender.SelectedItems)) {
                    $val = $item.SubItems[1].Text
                    if (-not $val) { continue }
                    $items += [pscustomobject]@{ Kind = [string]$item.Tag; Value = $val }
                }
                # Jeder Eintrag kostet Defender Sekunden - deshalb mit
                # Warteflaeche, Fortschritt und Abbruch statt stumm zu warten.
                $res = Invoke-DefenderExclusionBatch -Items $items -Mode 'remove' -Label (Get-Text 'DefRemove')
                if ($res.Total -gt 0) {
                    Write-TweakOutcome -Label (Get-Text 'DefRemove') -Ok $res.Ok -Total $res.Total -Failed $res.Failed
                }
                if ($res.Ok -gt 0) { Update-ChangeList }
                Update-DefenderList -Force
            }
            catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
        })
    $script:pnlContent.Controls.Add($btnRemove)

    $btnRefresh = & $mkBtn "{icon:refresh} $(Get-Text 'Refresh')" 885 242 160 $script:Theme.BgTertiary
    $btnRefresh.Add_Click({ Update-DefenderList -Force })
    $script:pnlContent.Controls.Add($btnRefresh)

    Invoke-Deferred -Action { Update-DefenderList -Force }   # frame first, data right after
}

function Update-DefenderList {
    param([string]$Filter, [switch]$Force)

    if ($PSBoundParameters.ContainsKey('Filter')) { Set-ListFilter -Name 'Defender' -Value $Filter }
    else { $Filter = Get-ListFilter 'Defender' }

    $lv = $script:lstDefender
    if (-not $lv -or $lv.IsDisposed) { return }
    $lv.BeginUpdate()
    try {
        $lv.Items.Clear()
        # Get-MpPreference braucht auf vielen Rechnern ein bis drei Sekunden.
        if (-not (Request-CachedData -Key 'Defender' -TtlSeconds 30 -Force:$Force -OnReady { Update-DefenderList } -Loader {
                    Get-MpPreference -ErrorAction SilentlyContinue |
                        Select-Object -First 1 -Property @{ N = 'ExclusionPath'; E = { @($_.ExclusionPath) } },
                        @{ N = 'ExclusionProcess'; E = { @($_.ExclusionProcess) } },
                        @{ N = 'ExclusionExtension'; E = { @($_.ExclusionExtension) } }
                })) {
            Add-EmptyState -ListView $lv -Text (Get-Text 'Loading')
            return
        }
        $pref = @(Get-CacheEntryData -Key 'Defender')[0]
        if (-not $pref) {
            Add-EmptyState -ListView $lv -Text (Get-Text 'EmptyNoEntries')
            return
        }

        $rows = @(Get-DefenderExclusionRows -Paths $pref.ExclusionPath -Processes $pref.ExclusionProcess -Extensions $pref.ExclusionExtension)
        $sum = Get-DefenderRowSummary -Rows $rows
        $shown = 0
        foreach ($r in $rows) {
            $item = New-Object System.Windows.Forms.ListViewItem((Get-Text $r.TypeKey))
            # Die Kennung bleibt unuebersetzt im Tag - die Schaltflaeche
            # 'Entfernen' hat bisher den sichtbaren Text verglichen und waere
            # mit uebersetzten Arten stillschweigend falsch abgebogen.
            $item.Tag = $r.Kind
            $item.ImageKey = Add-ListIcon -ListView $lv -Name $r.Icon -Color $script:Theme.($r.ColorName)
            [void]$item.SubItems.Add($r.Value)
            [void]$item.SubItems.Add($(if ($r.ReasonKey) { Get-Text $r.ReasonKey } else { '' }))
            if ($r.Risky) {
                $item.ForeColor = $script:Theme.Warning
                $item.ToolTipText = Get-Text $r.ReasonKey
            }
            if (-not (Test-ItemFilter -Item $item -Filter $Filter)) { continue }
            $shown++
            [void]$lv.Items.Add($item)
        }
        # Riskante Ausnahmen gehoeren nicht nur eingefaerbt, sondern gezaehlt.
        $note = ''
        if ($sum.Risky -gt 0) { $note = ('{0} {1}' -f $sum.Risky, (Get-Text 'DefRiskCount')) }
        Set-ListFilterCount -Name 'Defender' -Shown $shown -Total $sum.Total -Note $note
        Add-EmptyState -ListView $lv -Text $(if ($Filter) { Get-Text 'EmptyFilter' } else { Get-Text 'EmptyNoEntries' }) -SubText $(if ($Filter) { "'$Filter'" } else { '' })
        Restore-ListViewSort -ListView $lv -Name 'Defender'
    }
    catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    finally { $lv.EndUpdate() }
}

# ----------------------------------------------------------------- SERVICES --
function Show-Services {
    Add-ViewHeader -TitleKey 'MenuServices' -SubtitleKey 'ServicesSubtitle' -Icon 'gear'

    [void](Add-ListSearchBox -Name 'Dienste' -PlaceholderKey 'ServiceSearch' -Action {
            param($q) Update-ServiceList -Filter $q
        })

    $lst = New-Object System.Windows.Forms.ListView
    $lst.Location = New-Object System.Drawing.Point(25, 145)
    $lst.Size = New-Object System.Drawing.Size(900, 470)
    $lst.View = 'Details'
    $lst.FullRowSelect = $true
    $lst.BackColor = $script:Theme.BgSecondary
    $lst.ForeColor = $script:Theme.TextPrimary
    $lst.BorderStyle = 'None'
    $lst.Anchor = 'Top,Bottom,Left,Right'
    $lst.Font = (Get-AppFont -Size 9)
    [void]$lst.Columns.Add((Get-Text 'ColName'), 200)
    [void]$lst.Columns.Add((Get-Text 'ColDisplay'), 380)
    [void]$lst.Columns.Add((Get-Text 'ColState'), 120)
    [void]$lst.Columns.Add((Get-Text 'ColStartType'), 180)
    $script:pnlContent.Controls.Add($lst)
    Set-ListViewColumnFit -ListView $lst -Weights @(1, 3, 1, 1) -Name 'Dienste'
    Set-ListViewSortable -ListView $lst -Name 'Dienste'
    Add-ListContextMenu -ListView $lst -Name 'Dienste'
    $script:lstServices = $lst

    $y = 145
    foreach ($def in @(
            @{ T = "{icon:play} $(Get-Text 'Start')"; C = $script:Theme.Success; A = 'Start' },
            @{ T = "{icon:stop} $(Get-Text 'Stop')"; C = $script:Theme.Error; A = 'Stop' },
            @{ T = "{icon:ban} $(Get-Text 'Disable')"; C = $script:Theme.Warning; A = 'Disable' },
            @{ T = "{icon:check} $(Get-Text 'Enable')"; C = $script:Theme.Cyan; A = 'Enable' },
            @{ T = "{icon:save} $(Get-Text 'Export')"; C = $script:Theme.Purple; A = 'Backup' },
            @{ T = "{icon:refresh} $(Get-Text 'Refresh')"; C = $script:Theme.BgTertiary; A = 'Refresh' }
        )) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $def.T
        $b.Location = New-Object System.Drawing.Point(945, $y)
        $b.Size = New-Object System.Drawing.Size(200, 38)
        $b.BackColor = $def.C
        $b.ForeColor = $script:Theme.TextWhite
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderSize = 0
        $b.Font = (Get-AppFont -Size 9 -Style 'Bold')
        $b.Cursor = 'Hand'
        $b.Tag = $def.A
        $b.Add_Click({ Invoke-ServiceAction -Action $this.Tag })
        $script:pnlContent.Controls.Add($b)
        $y += 46
    }

    Invoke-Deferred -Action { Update-ServiceList -Force }   # frame first, data right after
}

function Update-CardGrid {
    # Cards were hard-coded to a 4 column / 1250 px layout. Now that the window
    # can be resized they flow into as many columns as actually fit - never
    # fewer than the original four, so nothing can ever overlap controls that
    # sit below the grid.
    if (-not $script:GridCards -or $script:GridCards.Count -eq 0) { return }
    if (-not $script:pnlContent -or $script:pnlContent.IsDisposed) { return }

    $cards = @($script:GridCards | Where-Object { $_.Control -and -not $_.Control.IsDisposed })
    if ($cards.Count -eq 0) { return }

    $avail = $script:pnlContent.ClientSize.Width - 50
    if ($avail -lt 200) { return }
    $cols = [int][math]::Max(4, [math]::Floor(($avail + 20) / 290))

    # Four 270 px cards need 1160 px. On a narrow window that forced a
    # horizontal scrollbar across the whole content area - the columns now
    # simply get narrower (down to 215 px) instead.
    $pitch = 290
    if ($cols -eq 4 -and $avail -lt 1140) {
        $pitch = [int][math]::Max(215, [math]::Floor(($avail + 20) / 4))
    }

    # Die Reihenfolge haengt ausschliesslich an den Ursprungspositionen und
    # aendert sich waehrend einer Groessenaenderung nie. Sort-Object mit
    # Skriptblock bei jedem WM_SIZE war einer der teuersten Posten ueberhaupt.
    if ($script:GridOrderCount -ne $cards.Count -or -not $script:GridOrdered) {
        $script:GridOrdered = @($cards | Sort-Object { $_.OrigY * 10000 + $_.OrigX })
        $script:GridOrderCount = $cards.Count
        $script:GridLastKey = ''
    }
    $ordered = $script:GridOrdered
    if (-not $ordered -or $ordered.Count -eq 0) { return }
    $startY = ($ordered | Measure-Object -Property OrigY -Minimum).Minimum

    # Nichts veraendert sich? Dann auch nichts anfassen - sonst laeuft bei
    # jedem Mausruckeln ein kompletter Layoutdurchgang ins Leere.
    $key = "$cols|$pitch|$($ordered.Count)|$startY"
    if ($script:GridLastKey -eq $key) { return }
    $script:GridLastKey = $key

    $suspended = $false
    try {
        Suspend-Redraw -Control $script:pnlContent
        $suspended = $true
    }
    catch { }

    $col = 0
    $row = 0
    foreach ($entry in $ordered) {
        if (-not $entry.Control -or $entry.Control.IsDisposed) { continue }
        if ($col + $entry.Span -gt $cols) { $col = 0; $row++ }
        $x = 25 + ($col * $pitch)
        $y = $startY + ($row * 170)
        if ($entry.Control.Location.X -ne $x -or $entry.Control.Location.Y -ne $y) {
            $entry.Control.Location = New-Object System.Drawing.Point($x, $y)
        }

        $targetW = ($entry.Span * $pitch) - 20
        if ($entry.Control.Width -ne $targetW) {
            $entry.Control.Width = $targetW
            # The rounded region is baked for one size - rebuild it (cheap,
            # the regions come from the cache) for the card and its button.
            Set-RoundedRegion -Control $entry.Control -Radius 10
            foreach ($ch in $entry.Control.Controls) {
                if ($ch -is [System.Windows.Forms.Button]) { Set-RoundedRegion -Control $ch -Radius 8 }
            }
        }
        $col += $entry.Span
    }

    if ($suspended) { Resume-Redraw -Control $script:pnlContent }
}

function Invoke-ContentReflow {
    # Ein Durchgang: Kinder begrenzen, dann das Kartenraster neu setzen.
    if (-not $script:pnlContent -or $script:pnlContent.IsDisposed) { return }
    try { Resize-ContentChildren } catch { }
    try { Update-CardGrid } catch { }
}

function Request-ContentReflow {
    # Beim Ziehen am Fensterrand feuert ClientSizeChanged dutzende Male pro
    # Sekunde, und jedes Mal lief frueher der volle Umbruch. Jetzt sammelt ein
    # Zeitgeber die Ereignisse ein und rechnet einmal, sobald der Nutzer kurz
    # innehaelt. Das Fenster folgt der Maus dadurch fluessig.
    param([switch]$Immediate)

    if ($Immediate) {
        if ($script:ReflowTimer) { try { $script:ReflowTimer.Stop() } catch { } }
        Invoke-ContentReflow
        return
    }
    if (-not $script:ReflowTimer) {
        $script:ReflowTimer = New-Object System.Windows.Forms.Timer
        $script:ReflowTimer.Interval = 90
        $script:ReflowTimer.Add_Tick({
                try { $script:ReflowTimer.Stop() } catch { }
                Invoke-ContentReflow
            })
    }
    try {
        $script:ReflowTimer.Stop()
        $script:ReflowTimer.Start()
    }
    catch { Invoke-ContentReflow }
}

function Add-EmptyState {
    # A blank list looks broken - say what is going on instead
    param(
        [System.Windows.Forms.ListView]$ListView,
        [string]$Text,
        [string]$SubText = ''
    )
    if (-not $ListView -or $ListView.IsDisposed -or $ListView.Items.Count -gt 0) { return }
    $line = $Text
    if ($SubText) { $line = "$Text  -  $SubText" }
    $i = New-Object System.Windows.Forms.ListViewItem($line)
    $i.ForeColor = $script:Theme.TextMuted
    [void]$ListView.Items.Add($i)
}

function Update-ServiceList {
    param([string]$Filter, [switch]$Force)

    # Ohne ausdruecklichen Filter gilt der zuletzt eingegebene Suchtext -
    # sonst wirft jedes Aktualisieren den Filter weg, waehrend im Suchfeld
    # noch der Text steht.
    if ($PSBoundParameters.ContainsKey('Filter')) { Set-ListFilter -Name 'Dienste' -Value $Filter }
    else { $Filter = Get-ListFilter 'Dienste' }

    $lv = $script:lstServices
    if (-not $lv -or $lv.IsDisposed) { return }
    try {
        # Beide Abfragen laufen im Hintergrund. Solange sie laufen, steht in
        # der Liste ein Ladehinweis - das Fenster bleibt bedienbar.
        $ready = Request-CachedData -Key 'Services' -TtlSeconds 10 -Force:$Force -OnReady { Update-ServiceList } -Loader {
            # Nur einfache Werte zurueckgeben - der Runspace wird gleich danach
            # geschlossen, ein ServiceController haengt an dessen Lebensdauer.
            Get-Service -ErrorAction SilentlyContinue | Sort-Object DisplayName |
                Select-Object -Property @{ N = 'Name'; E = { [string]$_.Name } },
                @{ N = 'DisplayName'; E = { [string]$_.DisplayName } },
                @{ N = 'Status'; E = { [string]$_.Status } }
        }
        $ready2 = Request-CachedData -Key 'StartModes' -TtlSeconds 20 -Force:$Force -OnReady { Update-ServiceList } -Loader {
            # Starttyp, verzoegerter Start und Beschreibung in EINER Abfrage.
            $info = @(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue |
                    Select-Object -Property Name, StartMode, DelayedAutoStart, Description, ProcessId)
            # Abhaengigkeiten stehen nur in der Registrierung - ein Durchgang
            # ueber alle Dienste statt hunderter Einzelabfragen.
            $deps = @{}
            try {
                foreach ($k in (Get-ChildItem -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction Stop)) {
                    $v = $null
                    try { $v = (Get-ItemProperty -LiteralPath $k.PSPath -Name 'DependOnService' -ErrorAction Stop).DependOnService }
                    catch { continue }
                    if ($v) { $deps[[string]$k.PSChildName] = @($v | ForEach-Object { [string]$_ }) }
                }
            }
            catch { }
            foreach ($i in $info) {
                $d = @()
                if ($i.Name -and $deps.ContainsKey([string]$i.Name)) { $d = @($deps[[string]$i.Name]) }
                Add-Member -InputObject $i -NotePropertyName 'DependsOn' -NotePropertyValue $d -Force
            }
            return $info
        }
        if (-not $ready -or -not $ready2) {
            $lv.BeginUpdate()
            try {
                $lv.Items.Clear()
                Add-EmptyState -ListView $lv -Text (Get-Text 'Loading')
            }
            finally { $lv.EndUpdate() }
            return
        }

        $info = @(Get-CacheEntryData -Key 'StartModes')
        $script:StartModeCache = @{}
        $script:ServiceInfoCache = @{}
        foreach ($svc in $info) {
            if (-not $svc -or -not $svc.Name) { continue }
            $script:StartModeCache[[string]$svc.Name] = ConvertFrom-WmiStartMode -Mode ([string]$svc.StartMode) -Delayed $svc.DelayedAutoStart
            $script:ServiceInfoCache[[string]$svc.Name] = $svc
        }
        $script:ServiceDependents = Get-ServiceDependentMap -Rows $info

        $services = @(Get-CacheEntryData -Key 'Services')
        $script:ServiceStatus = @{}
        foreach ($s in $services) { if ($s -and $s.Name) { $script:ServiceStatus[[string]$s.Name] = [string]$s.Status } }

        $rows = New-Object System.Collections.Generic.List[object]
        $total = 0
        foreach ($s in $services) {
            $total++
            $startType = [string]$script:StartModeCache[[string]$s.Name]
            $rows.Add([pscustomobject]@{
                    Key   = [string]$s.Name
                    Cells = @([string]$s.Name, [string]$s.DisplayName, [string]$s.Status,
                        (Get-Text (Get-StartTypeKey -Type $startType)))
                    Protected = [bool](Test-ServiceProtected -ServiceName ([string]$s.Name))
                    Running   = ([string]$s.Status -eq 'Running')
                    Tip       = [string]$script:ServiceInfoCache[[string]$s.Name].Description
                })
        }

        # Filtern ueber alle angezeigten Spalten - der alte Vergleich mit
        # -like brach bei eckigen Klammern im Suchtext und sah die Spalten
        # Status und Starttyp gar nicht.
        $shown = New-Object System.Collections.Generic.List[object]
        foreach ($r in $rows) {
            if ($Filter) {
                $hit = $false
                foreach ($c in $r.Cells) {
                    if ([string]$c -and ([string]$c).IndexOf($Filter.Trim(), [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { $hit = $true; break }
                }
                if (-not $hit) { continue }
            }
            $shown.Add($r)
        }
        $keys = @($shown | ForEach-Object { $_.Key })

        # Gleiche Dienstmenge -> nur die Zellen nachziehen. Ein Neuaufbau nach
        # jeder Aktion warf die Auswahl weg, und genau danach will man meist
        # noch etwas mit demselben Dienst tun.
        if ($lv.Items.Count -gt 0 -and (Test-ListKeysEqual -A $script:SvcRowKeys -B $keys)) {
            $byKey = @{}
            foreach ($r in $shown) { $byKey[$r.Key] = $r }
            foreach ($it in $lv.Items) {
                $r = $byKey["$($it.Tag)"]
                if (-not $r) { continue }
                for ($c = 0; $c -lt $r.Cells.Count -and $c -lt $it.SubItems.Count; $c++) {
                    if ($it.SubItems[$c].Text -ne $r.Cells[$c]) { $it.SubItems[$c].Text = $r.Cells[$c] }
                }
                $col = if ($r.Protected) { $script:Theme.Warning }
                elseif ($r.Running) { $script:Theme.Success }
                else { $script:Theme.TextPrimary }
                if ($it.ForeColor -ne $col) { $it.ForeColor = $col }
            }
            Set-ListFilterCount -Name 'Dienste' -Shown $shown.Count -Total $total
            return
        }

        $lv.BeginUpdate()
        try {
            $lv.Items.Clear()
            $items = New-Object System.Collections.Generic.List[System.Windows.Forms.ListViewItem]
            foreach ($r in $shown) {
                $item = New-Object System.Windows.Forms.ListViewItem($r.Cells[0])
                for ($c = 1; $c -lt $r.Cells.Count; $c++) { [void]$item.SubItems.Add($r.Cells[$c]) }
                $item.Tag = $r.Key
                if ($r.Protected) {
                    $item.ForeColor = $script:Theme.Warning
                    $item.ToolTipText = Get-Text 'Protected'
                }
                elseif ($r.Running) { $item.ForeColor = $script:Theme.Success }
                # Die Beschreibung sagt, wofuer der Dienst ueberhaupt da ist.
                if (-not $item.ToolTipText -and $r.Tip) { $item.ToolTipText = $r.Tip }
                $items.Add($item)
            }
            $lv.Items.AddRange($items.ToArray())
            Set-ListFilterCount -Name 'Dienste' -Shown $items.Count -Total $total
            Add-EmptyState -ListView $lv -Text (Get-Text 'EmptyFilter') -SubText $(if ($Filter) { "'$Filter'" } else { '' })
            Restore-ListViewSort -ListView $lv -Name 'Dienste'
        }
        finally { $lv.EndUpdate() }
        $script:SvcRowKeys = $keys
    }
    catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
}

function Invoke-ServiceAction {
    param([string]$Action)

    if ($Action -eq 'Refresh') { Update-ServiceList -Force; return }
    if ($Action -eq 'Backup') { New-Backup -Type Services | Out-Null; return }
    if (-not $script:lstServices -or $script:lstServices.SelectedItems.Count -eq 0) { return }

    $items = @($script:lstServices.SelectedItems)
    $ok = 0; $total = 0; $failed = @()

    # Vor dem Anhalten einmal sammeln, wer mitgerissen wuerde, und EINMAL
    # fragen - nicht pro Dienst.
    if ($Action -eq 'Stop') {
        $allDeps = @()
        foreach ($item in $items) {
            $n = [string]$item.SubItems[0].Text
            $allDeps += @(Get-RunningDependents -Map $script:ServiceDependents -Name $n -StatusByName $script:ServiceStatus)
        }
        $allDeps = @($allDeps | Sort-Object -Unique)
        if ($allDeps.Count -gt 0) {
            $names = (@($allDeps) | Select-Object -First 8) -join ', '
            if ($allDeps.Count -gt 8) { $names = "$names ..." }
            Write-Log "$(Get-Text 'SvcDependents'): $names" 'WARNING'
            if (-not (Show-Confirm -Message "$(Get-Text 'SvcDependentsAsk')`n`n$names")) { return }
        }
    }

    foreach ($item in $items) {
        $name = $item.SubItems[0].Text
        if ([string]::IsNullOrWhiteSpace($name)) { continue }

        $svc = $null
        try { $svc = Get-Service -Name $name -ErrorAction Stop } catch { }
        $status = if ($svc) { [string]$svc.Status } else { 'Unknown' }
        $startup = Get-ServiceStartupType -Name $name

        $plan = Get-ServiceActionPlan -Action $Action `
            -Protected (Test-ServiceProtected -ServiceName $name) `
            -CurrentStartup $startup -CurrentStatus $status `
            -PreviousStartup (Get-LastServiceStartup -Name $name) `
            -Dependents @(Get-RunningDependents -Map $script:ServiceDependents -Name $name -StatusByName $script:ServiceStatus)

        if (-not $plan.Allowed) {
            # 'steht schon so' ist kein Fehler und zaehlt deshalb nicht mit.
            if ($plan.ReasonKey -eq 'SvcNoChange') {
                Write-Log "$name : $(Get-Text 'SvcNoChange')" 'INFO'
            }
            else {
                $total++
                $failed += $name
                Write-Log "$(Get-Text $plan.ReasonKey): $name" 'WARNING'
            }
            continue
        }
        $total++
        if ($plan.ReasonKey -eq 'SvcFallback') { Write-Log "$name : $(Get-Text 'SvcFallback')" 'WARNING' }
        if ($plan.HintKey) { Write-Log "$name : $(Get-Text $plan.HintKey)" 'INFO' }

        try {
            if ($plan.Kind -eq 'startup') {
                Set-Service -Name $name -StartupType $plan.Target -ErrorAction Stop
                # Nachlesen statt annehmen: Set-Service meldet auch dann
                # Erfolg, wenn eine Richtlinie den Starttyp sofort zurueckdreht.
                $now = Get-ServiceStartupType -Name $name
                if ($now -ne $plan.Target) {
                    $failed += $name
                    Write-Log "$name : $(Get-Text 'SvcVerifyErr') ($now)" 'ERROR'
                    continue
                }
                # Erst jetzt ins Journal - ein nicht angekommener Wert darf
                # nicht als rueckgaengig machbare Aenderung erscheinen.
                [void](Add-ChangeEntry -Action 'service' -Path 'Service' -Name $name `
                        -Type 'StartupType' -OldValue $startup -NewValue $plan.Target `
                        -Existed $true -Label (Get-Text 'SvcAction'))
            }
            else {
                if ($plan.Target -eq 'Running') { Start-Service -Name $name -ErrorAction Stop }
                else { Stop-Service -Name $name -Force -ErrorAction Stop }
                try { (Get-Service -Name $name).WaitForStatus($plan.Target, [timespan]::FromSeconds(15)) } catch { }
                $now = [string](Get-Service -Name $name -ErrorAction SilentlyContinue).Status
                if ($now -ne $plan.Target) {
                    $failed += $name
                    Write-Log "$name : $(Get-Text 'SvcVerifyErr') ($now)" 'ERROR'
                    continue
                }
            }
            $ok++
        }
        catch {
            $failed += $name
            Write-Log "$name : $($_.Exception.Message)" 'ERROR'
        }
    }

    if ($total -gt 0) {
        Write-TweakOutcome -Label "$(Get-Text 'SvcAction') - $Action" -Ok $ok -Total $total -Failed $failed
    }
    if ($ok -gt 0) { Update-ChangeList }
    Clear-DataCache -Key 'StartModes'   # start types just changed
    Clear-DataCache -Key 'Services'
    Update-ServiceList -Force
}

# ------------------------------------------------------------------ STARTUP --
function Get-StartupSourceList {
    # Alle Orte, an denen Windows Autostarts fuehrt. Bisher las die Ansicht
    # nur die beiden Run-Schluessel und den Benutzerordner - die 32-Bit-Seite,
    # RunOnce und der Ordner fuer alle Benutzer fehlten komplett.
    $cu = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion'
    $lm = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion'
    $apprCu = "$cu\Explorer\StartupApproved"
    $apprLm = "$lm\Explorer\StartupApproved"
    return @(
        @{ Key = 'StartUser'; Kind = 'reg'; Path = "$cu\Run"; Approved = "$apprCu\Run" },
        @{ Key = 'StartSystem'; Kind = 'reg'; Path = "$lm\Run"; Approved = "$apprLm\Run" },
        @{ Key = 'Start32'; Kind = 'reg'; Path = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; Approved = "$apprLm\Run32" },
        @{ Key = 'StartOnce'; Kind = 'reg'; Path = "$cu\RunOnce"; Approved = '' },
        @{ Key = 'StartOnce'; Kind = 'reg'; Path = "$lm\RunOnce"; Approved = '' },
        @{ Key = 'StartFolder'; Kind = 'folder'; Path = ''; Approved = "$apprCu\StartupFolder" },
        @{ Key = 'StartCommon'; Kind = 'common'; Path = ''; Approved = "$apprLm\StartupFolder" }
    )
}

function ConvertTo-StartupTargetPath {
    # Aus der Befehlszeile das Programm herausloesen - nur so laesst sich
    # pruefen, ob der Eintrag ueberhaupt noch auf etwas zeigt.
    param([string]$Command)
    $c = [string]$Command
    if (-not $c) { return '' }
    $c = $c.Trim()
    $path = ''
    if ($c.StartsWith('"')) {
        $end = $c.IndexOf('"', 1)
        if ($end -gt 1) { $path = $c.Substring(1, $end - 1) }
        else { $path = $c.Trim('"') }
    }
    elseif ($c -match '^(?<p>.*?\.(exe|com|bat|cmd|scr|pif))(\s|$)') { $path = $Matches['p'] }
    else { $path = ($c -split '\s+')[0] }
    try { $path = [Environment]::ExpandEnvironmentVariables($path) } catch { }
    return $path.Trim()
}

function Test-StartupApprovedEnabled {
    # Task-Manager und Einstellungen merken sich den Zustand in zwoelf Bytes.
    # Das erste entscheidet: gerade Zahl = aktiv, ungerade = deaktiviert.
    # Fehlt der Wert, war der Eintrag nie abgeschaltet.
    param($Bytes)
    if ($null -eq $Bytes) { return $true }
    $arr = @($Bytes)
    if ($arr.Count -eq 0) { return $true }
    try { return ((([int]$arr[0]) -band 1) -eq 0) } catch { return $true }
}

function Get-StartupApprovedBytes {
    # Genau das Format schreibt auch der Task-Manager: Kennzeichen, drei
    # Nullbytes, dann der Zeitpunkt der Abschaltung als FILETIME.
    param([bool]$Enabled, $Now)
    $b = New-Object byte[] 12
    if ($Enabled) {
        $b[0] = 2
        return , $b
    }
    $b[0] = 3
    try {
        if (-not $Now) { $Now = Get-Date }
        $ft = ([datetime]$Now).ToFileTime()
        $raw = [System.BitConverter]::GetBytes([int64]$ft)
        for ($i = 0; $i -lt 8; $i++) { $b[$i + 4] = $raw[$i] }
    }
    catch { }
    return , $b
}

function Get-StartupActionPlan {
    # Entscheidet vor jedem Eingriff, ob er ueberhaupt etwas bewirkt.
    param($Entry, [string]$Action = 'Disable')
    $plan = @{ Allowed = $true; ReasonKey = ''; Enable = ($Action -eq 'Enable') }
    if (-not $Entry) { $plan.Allowed = $false; $plan.ReasonKey = 'StuNoEntry'; return $plan }
    if ($Action -eq 'Delete') {
        if ($Entry.Kind -eq 'reg' -and -not $Entry.RegPath) { $plan.Allowed = $false; $plan.ReasonKey = 'StuNoEntry' }
        return $plan
    }
    # RunOnce-Eintraege kennt die Abschaltliste nicht - sie verschwinden nach
    # dem naechsten Start ohnehin von selbst.
    if (-not $Entry.ApprovedPath) { $plan.Allowed = $false; $plan.ReasonKey = 'StuNoToggle'; return $plan }
    $isOn = $true
    try { $isOn = [bool]$Entry.Enabled } catch { }
    if ($isOn -eq $plan.Enable) { $plan.Allowed = $false; $plan.ReasonKey = 'StuNoChange' }
    return $plan
}

function Get-StartupStatusKey {
    # Ein Eintrag kann aktiv, abgeschaltet oder ins Leere zeigend sein.
    param($Entry)
    if (-not $Entry) { return 'StuEnabled' }
    $on = $true
    try { $on = [bool]$Entry.Enabled } catch { }
    if (-not $on) { return 'StuDisabled' }
    $missing = $false
    try { $missing = [bool]$Entry.TargetMissing } catch { }
    if ($missing) { return 'StuMissing' }
    return 'StuEnabled'
}

function Read-StartupApprovedMap {
    # Liest eine Abschaltliste in eine Tabelle Name -> aktiv.
    param([string]$Path)
    $map = @{}
    if (-not $Path) { return $map }
    try {
        if (-not (Test-Path -LiteralPath $Path)) { return $map }
        $pr = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
        foreach ($p in $pr.PSObject.Properties) {
            if ($p.Name -like 'PS*') { continue }
            $map[$p.Name] = (Test-StartupApprovedEnabled -Bytes $p.Value)
        }
    }
    catch { }
    return $map
}

function Get-StartupEntryList {
    # Sammelt alle Eintraege samt Zustand. Jeder Eintrag traegt seinen eigenen
    # Registrierungspfad bei sich - frueher nahm das Loeschen pauschal den
    # 64-Bit-Run-Schluessel an und griff bei allem anderen ins Leere.
    $list = New-Object System.Collections.Generic.List[object]
    foreach ($src in (Get-StartupSourceList)) {
        $appr = Read-StartupApprovedMap -Path $src.Approved
        if ($src.Kind -eq 'reg') {
            try {
                if (-not (Test-Path -LiteralPath $src.Path)) { continue }
                $props = Get-ItemProperty -LiteralPath $src.Path -ErrorAction Stop
                foreach ($p in $props.PSObject.Properties) {
                    if ($p.Name -like 'PS*') { continue }
                    $cmd = [string]$p.Value
                    $target = ConvertTo-StartupTargetPath -Command $cmd
                    $miss = $false
                    if ($target) { try { $miss = -not (Test-Path -LiteralPath $target) } catch { $miss = $false } }
                    $on = $true
                    if ($appr.ContainsKey($p.Name)) { $on = [bool]$appr[$p.Name] }
                    $list.Add([pscustomobject]@{
                            Name = $p.Name; Value = $cmd; ScopeKey = $src.Key; Kind = 'reg'
                            RegPath = $src.Path; ApprovedPath = $src.Approved; ApprovedName = $p.Name
                            Enabled = $on; TargetPath = $target; TargetMissing = $miss
                        })
                }
            }
            catch { }
            continue
        }
        $folder = ''
        try {
            if ($src.Kind -eq 'folder') { $folder = [Environment]::GetFolderPath('Startup') }
            else { $folder = Join-Path ([Environment]::GetFolderPath('CommonStartup')) '' }
        }
        catch { }
        if (-not $folder) { continue }
        $folder = $folder.TrimEnd('\')
        try {
            if (-not (Test-Path -LiteralPath $folder)) { continue }
            foreach ($f in (Get-ChildItem -LiteralPath $folder -File -ErrorAction SilentlyContinue)) {
                if ($f.Name -eq 'desktop.ini') { continue }
                $on = $true
                if ($appr.ContainsKey($f.Name)) { $on = [bool]$appr[$f.Name] }
                $list.Add([pscustomobject]@{
                        Name = $f.BaseName; Value = $f.FullName; ScopeKey = $src.Key; Kind = 'file'
                        RegPath = ''; ApprovedPath = $src.Approved; ApprovedName = $f.Name
                        Enabled = $on; TargetPath = $f.FullName; TargetMissing = $false
                    })
            }
        }
        catch { }
    }
    return $list
}

function Set-StartupEntryState {
    # Schreibt den Zustand so, wie der Task-Manager es tut - danach wird
    # zurueckgelesen. Erst eine bestaetigte Aenderung gilt als Erfolg.
    param($Entry, [bool]$Enable)
    if (-not $Entry -or -not $Entry.ApprovedPath) { return $false }
    $bytes = Get-StartupApprovedBytes -Enabled $Enable
    $ok = Set-RegistryValue -Path $Entry.ApprovedPath -Name ([string]$Entry.ApprovedName) `
        -Value $bytes -Type 'Binary' -Label (Get-Text 'MenuStartup') -Quiet
    if (-not $ok) { return $false }
    $after = $null
    try {
        $cur = Get-ItemProperty -LiteralPath $Entry.ApprovedPath -Name ([string]$Entry.ApprovedName) -ErrorAction Stop
        $after = $cur.($Entry.ApprovedName)
    }
    catch { return $false }
    return ((Test-StartupApprovedEnabled -Bytes $after) -eq $Enable)
}

function Invoke-StartupAction {
    # Ein Weg fuer alle drei Eingriffe: planen, ausfuehren, pruefen, ein
    # einziges Urteil ins Protokoll.
    param([string]$Action = 'Disable')
    if (-not $script:lstStartup -or $script:lstStartup.IsDisposed) { return }
    $items = @($script:lstStartup.SelectedItems)
    if ($items.Count -eq 0) { Write-Log (Get-Text 'StuNoSelection') 'INFO'; return }
    if ($Action -eq 'Delete' -and -not (Show-Confirm -Message (Get-Text 'DlgConfirm'))) { return }

    $label = Get-Text $(switch ($Action) { 'Enable' { 'Enable' } 'Delete' { 'Delete' } default { 'Disable' } })
    $ok = 0; $total = 0; $failed = @(); $skipped = 0
    foreach ($item in $items) {
        $entry = $item.Tag
        $plan = Get-StartupActionPlan -Entry $entry -Action $Action
        if (-not $plan.Allowed) {
            # Kein Fehler - der Eintrag ist schon im Zielzustand oder kennt
            # ihn gar nicht. Das als Misserfolg zu zaehlen waere unehrlich.
            $skipped++
            Write-Log "$($item.SubItems[0].Text): $(Get-Text $plan.ReasonKey)" 'INFO'
            continue
        }
        $total++
        if ($Action -eq 'Delete') {
            if ($entry.Kind -eq 'file') {
                if (Move-ToStash -Path ([string]$entry.Value) -Label (Get-Text 'MenuStartup')) {
                    $ok++; Write-Log "$(Get-Text 'StuMoved'): $($entry.Name)" 'SUCCESS'
                }
                else { $failed += [string]$entry.Name }
                continue
            }
            if (Remove-RegistryValue -Path ([string]$entry.RegPath) -Name ([string]$entry.Name) -Label (Get-Text 'MenuStartup')) { $ok++ }
            else { $failed += [string]$entry.Name }
            continue
        }
        if (Set-StartupEntryState -Entry $entry -Enable ([bool]$plan.Enable)) { $ok++ }
        else { $failed += [string]$entry.Name }
    }
    if ($total -gt 0) { Write-TweakOutcome -Label $label -Ok $ok -Total $total -Failed $failed }
    elseif ($skipped -gt 0) { Write-Log "$label : $(Get-Text 'TwkNone')" 'INFO' }
    Update-ChangeList
    Update-StartupList -Force
}

function Show-Startup {
    Add-ViewHeader -TitleKey 'MenuStartup' -SubtitleKey 'StartupSubtitle' -Icon 'rocket'

    [void](Add-ListSearchBox -Name 'Autostart' -PlaceholderKey 'SearchStartup' -Action {
            param($q) Set-ListFilter -Name 'Autostart' -Value $q; Update-StartupList
        })

    $lst = New-Object System.Windows.Forms.ListView
    $lst.Location = New-Object System.Drawing.Point(25, 145)
    $lst.Size = New-Object System.Drawing.Size(900, 470)
    $lst.View = 'Details'
    $lst.FullRowSelect = $true
    $lst.BackColor = $script:Theme.BgSecondary
    $lst.ForeColor = $script:Theme.TextPrimary
    $lst.BorderStyle = 'None'
    $lst.Anchor = 'Top,Bottom,Left,Right'
    $lst.Font = (Get-AppFont -Size 9)
    [void]$lst.Columns.Add((Get-Text 'ColName'), 200)
    [void]$lst.Columns.Add((Get-Text 'ColCommand'), 430)
    [void]$lst.Columns.Add((Get-Text 'ColScope'), 130)
    [void]$lst.Columns.Add((Get-Text 'ColState'), 120)
    $script:pnlContent.Controls.Add($lst)
    Set-ListViewColumnFit -ListView $lst -Weights @(2, 5, 2, 2) -Name 'Autostart'
    Set-ListViewSortable -ListView $lst -Name 'Autostart'
    Add-ListContextMenu -ListView $lst -Name 'Autostart'
    $script:lstStartup = $lst

    # Windows kennt zu jedem Autostart einen Schalter - bisher bot die
    # Ansicht nur das endgueltige Loeschen an.
    $buttons = @(
        @{ Text = "{icon:ban} $(Get-Text 'Disable')"; Color = $script:Theme.Warning; Tag = 'Disable' },
        @{ Text = "{icon:check} $(Get-Text 'Enable')"; Color = $script:Theme.Success; Tag = 'Enable' },
        @{ Text = "{icon:trash} $(Get-Text 'Delete')"; Color = $script:Theme.Error; Tag = 'Delete' },
        @{ Text = "{icon:refresh} $(Get-Text 'Refresh')"; Color = $script:Theme.BgTertiary; Tag = 'Refresh' }
    )
    $y = 100
    foreach ($cfg in $buttons) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $cfg.Text
        $b.Location = New-Object System.Drawing.Point(945, $y)
        $b.Anchor = 'Top,Right'
        $b.Size = New-Object System.Drawing.Size(200, 40)
        $b.BackColor = $cfg.Color
        $b.ForeColor = $script:Theme.TextWhite
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderSize = 0
        $b.Font = (Get-AppFont -Size 9 -Style 'Bold')
        $b.Cursor = 'Hand'
        $b.Tag = $cfg.Tag
        $b.Add_Click({
                if ($this.Tag -eq 'Refresh') { Update-StartupList -Force; return }
                Invoke-StartupAction -Action $this.Tag
            })
        $script:pnlContent.Controls.Add($b)
        $y += 48
    }

    $btnFolder = New-Object System.Windows.Forms.Button
    $btnFolder.Text = "{icon:folderopen} $(Get-Text 'StartupFolder')"
    $btnFolder.Location = New-Object System.Drawing.Point(945, $y)
    $btnFolder.Anchor = 'Top,Right'
    $btnFolder.Size = New-Object System.Drawing.Size(200, 40)
    $btnFolder.BackColor = $script:Theme.Accent
    $btnFolder.ForeColor = $script:Theme.TextWhite
    $btnFolder.FlatStyle = 'Flat'
    $btnFolder.FlatAppearance.BorderSize = 0
    $btnFolder.Font = (Get-AppFont -Size 9 -Style 'Bold')
    $btnFolder.Cursor = 'Hand'
    $btnFolder.Add_Click({
            try { Start-Process explorer.exe -ArgumentList ([Environment]::GetFolderPath('Startup')) }
            catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
        })
    $script:pnlContent.Controls.Add($btnFolder)

    Invoke-Deferred -Action { Update-StartupList -Force }   # frame first, data right after
}

function Update-StartupList {
    param([string]$Filter, [switch]$Force)

    if ($PSBoundParameters.ContainsKey('Filter')) { Set-ListFilter -Name 'Autostart' -Value $Filter }
    else { $Filter = Get-ListFilter 'Autostart' }

    if (-not $script:lstStartup -or $script:lstStartup.IsDisposed) { return }
    $script:lstStartup.BeginUpdate()
    try {
        $script:lstStartup.Items.Clear()
        $entries = Get-CachedData -Key 'Startup' -TtlSeconds 30 -Force:$Force -Loader { Get-StartupEntryList }

        $total = 0
        $shown = 0
        foreach ($e in $entries) {
            $total++
            $item = New-Object System.Windows.Forms.ListViewItem($e.Name)
            [void]$item.SubItems.Add([string]$e.Value)
            # Uebersetzen erst beim Anzeigen - im Zwischenspeicher stehen nur
            # Schluessel. Der Ordner stand hier frueher hart auf Englisch.
            [void]$item.SubItems.Add((Get-Text $e.ScopeKey))
            $statusKey = Get-StartupStatusKey -Entry $e
            [void]$item.SubItems.Add((Get-Text $statusKey))
            $item.Tag = $e
            if ($statusKey -eq 'StuDisabled') { $item.ForeColor = $script:Theme.TextMuted }
            elseif ($statusKey -eq 'StuMissing') { $item.ForeColor = $script:Theme.Warning }
            if (-not (Test-ItemFilter -Item $item -Filter $Filter)) { continue }
            $shown++
            [void]$script:lstStartup.Items.Add($item)
        }
        Set-ListFilterCount -Name 'Autostart' -Shown $shown -Total $total
        Add-EmptyState -ListView $script:lstStartup -Text $(if ($Filter) { Get-Text 'EmptyFilter' } else { Get-Text 'EmptyNoEntries' }) -SubText $(if ($Filter) { "'$Filter'" } else { '' })
        Restore-ListViewSort -ListView $script:lstStartup -Name 'Autostart'
    }
    catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    finally { $script:lstStartup.EndUpdate() }
}

# ---------------------------------------------------------- SCHEDULED TASKS --
function Show-ScheduledTasks {
    Add-ViewHeader -TitleKey 'MenuTasks' -SubtitleKey 'TasksSubtitle' -Icon 'calendar'

    [void](Add-ListSearchBox -Name 'Aufgaben' -PlaceholderKey 'SearchTasks' -Action {
            param($q) Set-ListFilter -Name 'Aufgaben' -Value $q; Update-TaskList
        })

    $lst = New-Object System.Windows.Forms.ListView
    $lst.Location = New-Object System.Drawing.Point(25, 145)
    $lst.Size = New-Object System.Drawing.Size(900, 470)
    $lst.View = 'Details'
    $lst.FullRowSelect = $true
    $lst.BackColor = $script:Theme.BgSecondary
    $lst.ForeColor = $script:Theme.TextPrimary
    $lst.BorderStyle = 'None'
    $lst.Anchor = 'Top,Bottom,Left,Right'
    $lst.Font = (Get-AppFont -Size 9)
    [void]$lst.Columns.Add((Get-Text 'ColTask'), 240)
    [void]$lst.Columns.Add((Get-Text 'ColPath'), 260)
    [void]$lst.Columns.Add((Get-Text 'ColState'), 110)
    [void]$lst.Columns.Add((Get-Text 'TskLastRun'), 150)
    [void]$lst.Columns.Add((Get-Text 'TskResult'), 140)
    $script:pnlContent.Controls.Add($lst)
    Set-ListViewColumnFit -ListView $lst -Weights @(3, 3, 1, 2, 2) -Name 'Aufgaben'
    Set-ListViewSortable -ListView $lst -Name 'Aufgaben'
    Add-ListContextMenu -ListView $lst -Name 'Aufgaben'
    $script:lstTasks = $lst

    # Each button carries its action tag in .Tag; the click handler passes it to
    # the scriptblock as a parameter, because the scriptblock cannot see the
    # handler's local variables.
    $buttons = @(
        @{ Text = "{icon:ban} $(Get-Text 'Disable')"; Color = $script:Theme.Error; Tag = 'Disable' },
        @{ Text = "{icon:check} $(Get-Text 'Enable')"; Color = $script:Theme.Success; Tag = 'Enable' },
        @{ Text = "{icon:play} $(Get-Text 'Start')"; Color = $script:Theme.Cyan; Tag = 'Run' },
        @{ Text = "{icon:refresh} $(Get-Text 'Refresh')"; Color = $script:Theme.BgTertiary; Tag = 'Refresh' },
        @{ Text = "{icon:eye} $(Get-Text 'TskShowWin')"; Color = $script:Theme.BgTertiary; Tag = 'ToggleWin' }
    )

    $y = 100
    foreach ($cfg in $buttons) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $cfg.Text
        $b.Location = New-Object System.Drawing.Point(945, $y)
        $b.Size = New-Object System.Drawing.Size(200, 40)
        $b.BackColor = $cfg.Color
        $b.ForeColor = $script:Theme.TextWhite
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderSize = 0
        $b.Font = (Get-AppFont -Size 9 -Style 'Bold')
        $b.Cursor = 'Hand'
        $b.Tag = $cfg.Tag
        $b.Add_Click({ Invoke-TaskAction -Action $this.Tag })
        $script:pnlContent.Controls.Add($b)
        if ($cfg.Tag -eq 'ToggleWin') {
            $script:btnTaskWin = $b
            Set-Tip $b (Get-Text 'TskShowWinTip')
            Update-TaskToggleLook
        }
        $y += 48
    }

    Invoke-Deferred -Action { Update-TaskList -Force }   # frame first, data right after
}

function Test-MicrosoftTask {
    # Die Ansicht blendete alles unter \Microsoft\Windows aus - bis auf
    # Telemetrie. Hunderte Aufgaben fehlten also wortlos. Jetzt entscheidet
    # ein Schalter, und die Herkunft ist wenigstens benennbar.
    param([string]$TaskPath)
    $p = ([string]$TaskPath)
    if (-not $p) { return $false }
    return ($p -like '\Microsoft\*')
}

function Get-TaskResultKey {
    # Der letzte Rueckgabewert ist die einzige Stelle, an der man sieht, ob
    # eine Aufgabe ihre Arbeit tut. Als nackte Zahl (0x41303) sagt er nichts.
    param($Code)
    # Keine Angabe ist nicht dasselbe wie Rueckgabewert 0 - genau das haette
    # eine Aufgabe ohne Lauf-Information als "Erfolgreich" ausgewiesen.
    if ($null -eq $Code -or ("$Code").Trim() -eq '') { return 'TskResUnknown' }
    $c = $null
    try { $c = [int64]$Code } catch { return 'TskResUnknown' }
    # Negative Werte sind 32-Bit-Codes mit gesetztem Vorzeichenbit.
    if ($c -lt 0) { $c = $c + 4294967296 }
    switch ($c) {
        0 { return 'TskResOk' }
        1 { return 'TskResError' }
        2 { return 'TskResNotFound' }
        10 { return 'TskResError' }
        267008 { return 'TskResReady' }
        267009 { return 'TskResRunning' }
        267010 { return 'TskResDisabled' }
        267011 { return 'TskResNever' }
        267014 { return 'TskResStopped' }
        2147750687 { return 'TskResRunning' }
        default { return 'TskResError' }
    }
}

function Format-TaskResult {
    # Bei allem, was kein bekannter Zustand ist, bleibt der Zahlenwert
    # sichtbar - sonst laesst sich nichts nachschlagen.
    param($Code)
    $key = Get-TaskResultKey -Code $Code
    $txt = Get-Text $key
    if ($key -eq 'TskResError') {
        $c = 0
        try { $c = [int64]$Code } catch { }
        if ($c -lt 0) { $c = $c + 4294967296 }
        return ('{0} (0x{1:X})' -f $txt, $c)
    }
    return $txt
}

function Format-TaskTime {
    # Aufgaben ohne Lauf tragen ein Datum aus dem Jahr 1899 - das als
    # "30.12.1899" anzuzeigen, verwirrt mehr als ein Strich.
    param($Value)
    if ($null -eq $Value) { return '-' }
    $dt = [datetime]::MinValue
    if ($Value -is [datetime]) { $dt = $Value }
    else {
        $s = [string]$Value
        if (-not $s) { return '-' }
        if (-not [datetime]::TryParse($s, [ref]$dt)) { return '-' }
    }
    if ($dt.Year -lt 1980) { return '-' }
    if ($dt.Year -gt 2900) { return '-' }
    return $dt.ToString('yyyy-MM-dd HH:mm')
}

function Get-TaskRows {
    # Reine Zeilendaten samt Filterung nach Herkunft.
    param($Tasks = @(), [bool]$ShowMicrosoft = $false)
    $rows = New-Object System.Collections.Generic.List[object]
    $total = 0
    $hidden = 0
    foreach ($t in @($Tasks)) {
        if (-not $t) { continue }
        $total++
        $ms = Test-MicrosoftTask -TaskPath ([string]$t.TaskPath)
        if ($ms -and -not $ShowMicrosoft) { $hidden++; continue }
        $state = [string]$t.State
        $rows.Add([pscustomobject]@{
                Key   = (Get-TaskFullPath -TaskPath ([string]$t.TaskPath) -TaskName ([string]$t.TaskName))
                Name  = [string]$t.TaskName
                Path  = [string]$t.TaskPath
                Cells = @([string]$t.TaskName, [string]$t.TaskPath, $state,
                    (Format-TaskTime $t.LastRunTime), (Format-TaskResult $t.LastTaskResult))
                Microsoft = $ms
                Disabled  = ($state -eq 'Disabled')
                Running   = ($state -eq 'Running')
                Failed    = ((Get-TaskResultKey -Code $t.LastTaskResult) -in @('TskResError', 'TskResNotFound'))
            })
    }
    return [pscustomobject]@{ Rows = $rows.ToArray(); Total = $total; Hidden = $hidden }
}

function Update-TaskList {
    param([string]$Filter, [switch]$Force)

    if ($PSBoundParameters.ContainsKey('Filter')) { Set-ListFilter -Name 'Aufgaben' -Value $Filter }
    else { $Filter = Get-ListFilter 'Aufgaben' }

    $lv = $script:lstTasks
    if (-not $lv -or $lv.IsDisposed) { return }
    $lv.BeginUpdate()
    try {
        $lv.Items.Clear()
        if (-not (Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue)) {
            $i = New-Object System.Windows.Forms.ListViewItem((Get-Text 'Error'))
            [void]$i.SubItems.Add((Get-Text 'LogTaskModule'))
            [void]$lv.Items.Add($i)
            return
        }
        # Get-ScheduledTask allein braucht auf den meisten Rechnern Sekunden -
        # in den Hintergrund damit, sonst steht das Fenster so lange still.
        if (-not (Request-CachedData -Key 'Tasks' -TtlSeconds 60 -Force:$Force -OnReady { Update-TaskList } -Loader {
                    # Letzter Lauf und Ergebnis kommen aus einer zweiten
                    # Abfrage; sie sind der einzige Hinweis darauf, ob eine
                    # Aufgabe ueberhaupt noch tut, wofuer sie da ist.
                    $info = @{}
                    try {
                        foreach ($ti in (Get-ScheduledTaskInfo -ErrorAction SilentlyContinue)) {
                            if (-not $ti) { continue }
                            $k = ([string]$ti.TaskPath) + ([string]$ti.TaskName)
                            $info[$k] = @{
                                Last   = $ti.LastRunTime
                                Next   = $ti.NextRunTime
                                Result = $ti.LastTaskResult
                            }
                        }
                    }
                    catch { }
                    Get-ScheduledTask -ErrorAction SilentlyContinue | Sort-Object TaskName |
                        ForEach-Object {
                            $k = ([string]$_.TaskPath) + ([string]$_.TaskName)
                            $i = $info[$k]
                            [pscustomobject]@{
                                TaskName      = [string]$_.TaskName
                                TaskPath      = [string]$_.TaskPath
                                State         = [string]$_.State
                                LastRunTime   = $(if ($i) { $i.Last } else { $null })
                                NextRunTime   = $(if ($i) { $i.Next } else { $null })
                                LastTaskResult = $(if ($i) { $i.Result } else { $null })
                            }
                        }
                })) {
            Add-EmptyState -ListView $lv -Text (Get-Text 'Loading')
            return
        }
        $data = Get-TaskRows -Tasks (Get-CacheEntryData -Key 'Tasks') -ShowMicrosoft ([bool]$script:Config.ShowWindowsTasks)
        $shown = 0
        foreach ($r in @($data.Rows)) {
            $item = New-Object System.Windows.Forms.ListViewItem($r.Cells[0])
            for ($c = 1; $c -lt $r.Cells.Count; $c++) { [void]$item.SubItems.Add($r.Cells[$c]) }
            $item.Tag = $r.Key
            if ($r.Disabled) { $item.ForeColor = $script:Theme.TextMuted }
            elseif ($r.Failed) { $item.ForeColor = $script:Theme.Warning }
            elseif ($r.Running) { $item.ForeColor = $script:Theme.Success }
            if (Test-TaskProtected -TaskPath $r.Path -TaskName $r.Name) { $item.ToolTipText = Get-Text 'Protected' }
            if (-not (Test-ItemFilter -Item $item -Filter $Filter)) { continue }
            $shown++
            [void]$lv.Items.Add($item)
        }
        # Ausgeblendete Aufgaben benennen, statt sie verschwinden zu lassen.
        $note = ''
        if ($data.Hidden -gt 0) { $note = ('{0} {1}' -f $data.Hidden, (Get-Text 'TskHidden')) }
        Set-ListFilterCount -Name 'Aufgaben' -Shown $shown -Total $data.Total -Note $note
        Add-EmptyState -ListView $lv -Text (Get-Text 'EmptyFilter') -SubText $(if ($Filter) { "'$Filter'" } else { '' })
        Restore-ListViewSort -ListView $lv -Name 'Aufgaben'
    }
    catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    finally { $lv.EndUpdate() }
}

function Update-TaskToggleLook {
    if (-not $script:btnTaskWin -or $script:btnTaskWin.IsDisposed) { return }
    $on = [bool]$script:Config.ShowWindowsTasks
    $script:btnTaskWin.BackColor = if ($on) { $script:Theme.Success } else { $script:Theme.BgTertiary }
    $script:btnTaskWin.ForeColor = if ($on) { $script:Theme.TextWhite } else { $script:Theme.TextPrimary }
}

function Invoke-TaskAction {
    param([string]$Action)

    if ($Action -eq 'Refresh') { Update-TaskList -Force; return }
    if ($Action -eq 'ToggleWin') {
        $script:Config.ShowWindowsTasks = (-not [bool]$script:Config.ShowWindowsTasks)
        Update-TaskToggleLook
        Update-TaskList
        return
    }
    if (-not $script:lstTasks -or $script:lstTasks.SelectedItems.Count -eq 0) { return }

    $ok = 0; $total = 0; $failed = @()
    foreach ($item in @($script:lstTasks.SelectedItems)) {
        $name = $item.SubItems[0].Text
        $path = $item.SubItems[1].Text
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        $full = Get-TaskFullPath -TaskPath $path -TaskName $name

        $state = 'Unknown'
        try { $state = [string](Get-ScheduledTask -TaskName $name -TaskPath $path -ErrorAction Stop).State } catch { }

        $plan = Get-TaskActionPlan -Action $Action -CurrentState $state `
            -Protected (Test-TaskProtected -TaskPath $path -TaskName $name)

        if (-not $plan.Allowed) {
            if ($plan.ReasonKey -eq 'SvcNoChange') {
                Write-Log "$name : $(Get-Text 'SvcNoChange')" 'INFO'
            }
            else {
                $total++
                $failed += $name
                Write-Log "$(Get-Text $plan.ReasonKey): $full" 'WARNING'
            }
            continue
        }
        $total++
        try {
            switch ($Action) {
                'Disable' { Disable-ScheduledTask -TaskName $name -TaskPath $path -ErrorAction Stop | Out-Null }
                'Enable' { Enable-ScheduledTask -TaskName $name -TaskPath $path -ErrorAction Stop | Out-Null }
                'Run' { Start-ScheduledTask -TaskName $name -TaskPath $path -ErrorAction Stop }
            }
            if ($plan.Journal) {
                # Nachlesen statt annehmen - und erst dann journalisieren.
                $now = [string](Get-ScheduledTask -TaskName $name -TaskPath $path -ErrorAction Stop).State
                $hit = if ($plan.Target -eq 'Disabled') { $now -eq 'Disabled' } else { $now -ne 'Disabled' }
                if (-not $hit) {
                    $failed += $name
                    Write-Log "$name : $(Get-Text 'SvcVerifyErr') ($now)" 'ERROR'
                    continue
                }
                [void](Add-ChangeEntry -Action 'task' -Path $full -Name $name -Type 'TaskState' `
                        -OldValue $state -NewValue $now -Existed $true -Label (Get-Text 'TskAction'))
            }
            $ok++
        }
        catch {
            $failed += $name
            Write-Log "$name : $($_.Exception.Message)" 'ERROR'
        }
    }
    if ($total -gt 0) {
        Write-TweakOutcome -Label "$(Get-Text 'TskAction') - $Action" -Ok $ok -Total $total -Failed $failed
    }
    if ($ok -gt 0) { Update-ChangeList }
    Update-TaskList -Force
}

# ------------------------------------------------------------------ UPDATES --
# --- Windows Update: Pause, Freigabe, Reparatur -------------------------------
# Die Karten haben frueher drei von sechs Pausenwerten geschrieben, den Dienst
# lahmgelegt und in jedem Fall Erfolg gemeldet. Hier gilt dieselbe Ordnung wie
# ueberall sonst: messen, fragen, ausfuehren, nachlesen, eintragen.
$script:WuUxKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
$script:WuPolicyKey = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings'
$script:WuPauseValues = @(
    'PauseUpdatesStartTime', 'PauseUpdatesExpiryTime',
    'PauseFeatureUpdatesStartTime', 'PauseFeatureUpdatesEndTime',
    'PauseQualityUpdatesStartTime', 'PauseQualityUpdatesEndTime'
)
$script:WuRepairServices = @('wuauserv', 'bits', 'cryptSvc', 'msiserver')

function ConvertFrom-WuTime {
    # Windows legt die Pausenzeiten als Text in UTC ab.
    param([string]$Text)
    $t = ([string]$Text).Trim()
    if (-not $t) { return $null }
    $dt = [datetime]::MinValue
    $styles = [System.Globalization.DateTimeStyles]::AdjustToUniversal -bor [System.Globalization.DateTimeStyles]::AssumeUniversal
    if ([datetime]::TryParse($t, [System.Globalization.CultureInfo]::InvariantCulture, $styles, [ref]$dt)) { return $dt }
    return $null
}

function Get-UpdatePausePlan {
    # Windows nimmt hoechstens 35 Tage an - alles darueber wird stillschweigend
    # ignoriert, der Nutzer haelt die Updates aber fuer dauerhaft gestoppt.
    param([int]$Days = 35, [int]$MaxDays = 35, [datetime]$Now = (Get-Date))
    $d = $Days
    $clamped = $false
    if ($d -lt 1) { $d = 1; $clamped = $true }
    if ($d -gt $MaxDays) { $d = $MaxDays; $clamped = $true }
    $start = $Now.ToUniversalTime()
    $end = $start.AddDays($d)
    return @{
        Days      = $d
        Clamped   = $clamped
        StartText = $start.ToString('yyyy-MM-ddTHH:mm:ssZ')
        EndText   = $end.ToString('yyyy-MM-ddTHH:mm:ssZ')
        End       = $end
    }
}

function Get-UpdatePauseState {
    # Reine Auswertung der gelesenen Werte - so laesst sie sich pruefen,
    # ohne an einer echten Registrierung zu haengen.
    param($Values, [datetime]$Now = (Get-Date))
    $res = @{ Paused = $false; Expired = $false; UntilText = ''; DaysLeft = 0; Found = 0 }
    if (-not $Values) { return $res }
    $nowUtc = $Now.ToUniversalTime()
    $max = $null
    foreach ($k in @($Values.Keys)) {
        $name = [string]$k
        if ($name -notmatch 'EndTime$|ExpiryTime$') { continue }
        $t = ConvertFrom-WuTime -Text ([string]$Values[$k])
        if (-not $t) { continue }
        $res.Found++
        if (-not $max -or $t -gt $max) { $max = $t }
    }
    if ($max) {
        $res.UntilText = ([datetime]$max).ToLocalTime().ToString('yyyy-MM-dd HH:mm')
        if ($max -gt $nowUtc) {
            $res.Paused = $true
            $res.DaysLeft = [int][math]::Ceiling(([datetime]$max - $nowUtc).TotalDays)
        }
        else { $res.Expired = $true }
    }
    return $res
}

function Read-UpdatePauseValues {
    $h = @{}
    foreach ($n in $script:WuPauseValues) {
        try {
            $v = (Get-ItemProperty -LiteralPath $script:WuUxKey -Name $n -ErrorAction Stop).$n
            if ($null -ne $v) { $h[$n] = [string]$v }
        }
        catch { }
    }
    return $h
}

function Set-UpdatePause {
    # Alle sechs Werte - die drei Startzeiten fehlten bisher, und ohne sie
    # zeigt die Einstellungen-App die Pause gar nicht erst an.
    param([int]$Days = 35)
    $plan = Get-UpdatePausePlan -Days $Days
    $pairs = @(
        @{ N = 'PauseUpdatesStartTime'; V = $plan.StartText },
        @{ N = 'PauseUpdatesExpiryTime'; V = $plan.EndText },
        @{ N = 'PauseFeatureUpdatesStartTime'; V = $plan.StartText },
        @{ N = 'PauseFeatureUpdatesEndTime'; V = $plan.EndText },
        @{ N = 'PauseQualityUpdatesStartTime'; V = $plan.StartText },
        @{ N = 'PauseQualityUpdatesEndTime'; V = $plan.EndText }
    )
    $ok = 0
    $failed = @()
    foreach ($p in $pairs) {
        if (Set-RegistryValue -Path $script:WuUxKey -Name $p.N -Value $p.V -Type String -Label (Get-Text 'UpdPause') -Quiet) { $ok++ }
        else { $failed += $p.N }
    }
    foreach ($n in @('PausedFeatureStatus', 'PausedQualityStatus')) {
        [void](Set-RegistryValue -Path $script:WuPolicyKey -Name $n -Value 1 -Type DWord -Label (Get-Text 'UpdPause') -Quiet)
    }
    Write-TweakOutcome -Label (Get-Text 'UpdPause') -Ok $ok -Total $pairs.Count -Failed $failed
    return (Get-UpdatePauseState -Values (Read-UpdatePauseValues))
}

function Resume-WindowsUpdate {
    $removed = 0
    foreach ($n in $script:WuPauseValues) {
        if (Remove-RegistryValue -Path $script:WuUxKey -Name $n -Label (Get-Text 'UpdResume') -Quiet) { $removed++ }
    }
    foreach ($n in @('PausedFeatureStatus', 'PausedQualityStatus')) {
        [void](Set-RegistryValue -Path $script:WuPolicyKey -Name $n -Value 0 -Type DWord -Label (Get-Text 'UpdResume') -Quiet)
    }
    $state = Get-UpdatePauseState -Values (Read-UpdatePauseValues)
    if ($state.Paused) {
        Write-Log "$(Get-Text 'UpdResume'): $(Get-Text 'ChangeVerifyErr')" 'ERROR'
        return $false
    }
    Write-Log ("{0} ({1})" -f (Get-Text 'UpdResumed'), $removed) 'SUCCESS'
    return $true
}

function Stop-ServiceAndWait {
    # Stop-Service kehrt zurueck, bevor der Dienst wirklich steht. Wer gleich
    # danach den Ordner umbenennt, scheitert an der offenen Datei.
    param([string]$Name, [int]$TimeoutSec = 20)
    try {
        $s = Get-Service -Name $Name -ErrorAction Stop
        if ($s.Status -eq 'Stopped') { return $true }
        Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
            Start-Sleep -Milliseconds 250
            [System.Windows.Forms.Application]::DoEvents()
            try { $s.Refresh() } catch { return $false }
            if ($s.Status -eq 'Stopped') { return $true }
        }
        return $false
    }
    catch { return $false }
}

function Start-ServiceChecked {
    param([string]$Name)
    try {
        Start-Service -Name $Name -ErrorAction Stop
        $s = Get-Service -Name $Name -ErrorAction Stop
        return ($s.Status -in @('Running', 'StartPending'))
    }
    catch { return $false }
}

function Get-UpdateRepairFolders {
    $out = @()
    foreach ($rel in @('SoftwareDistribution', 'System32\catroot2')) {
        $p = Join-Path $env:SystemRoot $rel
        if (Test-Path -LiteralPath $p) { $out += $p }
    }
    return $out
}

function Rename-UpdateFolder {
    # Umbenennen statt loeschen, und zwar ins Journal - damit 'Rueckgaengig'
    # den alten Zustand zurueckholen kann.
    param([string]$Path, [string]$Label = '')
    $leaf = Split-Path -Leaf $Path
    $newLeaf = "{0}.old_{1}" -f $leaf, (Get-Date -Format 'yyyyMMdd_HHmmss')
    $newPath = Join-Path (Split-Path -Parent $Path) $newLeaf
    try {
        Rename-Item -LiteralPath $Path -NewName $newLeaf -Force -ErrorAction Stop
        if ((Test-Path -LiteralPath $Path) -or -not (Test-Path -LiteralPath $newPath)) {
            Write-Log "$Path : $(Get-Text 'ChangeVerifyErr')" 'ERROR'
            return $false
        }
        [void](Add-ChangeEntry -Action 'file' -Path $Path -Name $leaf -Type 'File' `
                -OldValue $Path -NewValue $newPath -Existed $true -Label $Label)
        return $true
    }
    catch {
        Write-Log "$Path : $($_.Exception.Message)" 'ERROR'
        return $false
    }
}

function Get-UpdateLeftovers {
    # Jede Reparatur liess bisher einen vollstaendigen Ordner liegen - auf
    # einem oft reparierten Rechner summiert sich das auf mehrere Gigabyte.
    $out = @()
    $defs = @(
        @{ Dir = $env:SystemRoot; Mask = 'SoftwareDistribution.old_*' },
        @{ Dir = (Join-Path $env:SystemRoot 'System32'); Mask = 'catroot2.old_*' }
    )
    foreach ($d in $defs) {
        try {
            foreach ($f in @(Get-ChildItem -LiteralPath $d.Dir -Directory -Filter $d.Mask -ErrorAction SilentlyContinue)) {
                # Diese Ordner sind oft mehrere Gigabyte gross. Mit
                # Get-ChildItem -Recurse stand die Oberflaeche still, bis die
                # Summe fertig war - jetzt mit Zeitgrenze und Luftholen.
                $bytes = 0.0
                try {
                    $scan = Get-FileEntriesFast -Root ([string]$f.FullName) -TimeoutSec 8
                    foreach ($e in @($scan.Files)) { $bytes += [double]$e.Length }
                }
                catch { }
                $out += [pscustomobject]@{
                    Path    = [string]$f.FullName
                    Bytes   = $bytes
                    AgeDays = [int][math]::Floor(((Get-Date) - $f.CreationTime).TotalDays)
                }
            }
        }
        catch { }
    }
    return $out
}

function Get-UpdateLeftoverPlan {
    # Was alt genug ist, darf weg - der juengste Ordner bleibt als Rueckweg.
    param($Items, [int]$KeepDays = 7)
    $all = @($Items | Where-Object { $_ })
    $res = @{ Remove = @(); Keep = @(); Bytes = 0.0; TotalBytes = 0.0 }
    if ($all.Count -eq 0) { return $res }
    foreach ($i in $all) { $res.TotalBytes += [double]$i.Bytes }
    $sorted = @($all | Sort-Object -Property AgeDays)
    for ($n = 0; $n -lt $sorted.Count; $n++) {
        $i = $sorted[$n]
        if ($n -eq 0 -or [int]$i.AgeDays -lt $KeepDays) { $res.Keep += $i }
        else {
            $res.Remove += $i
            $res.Bytes += [double]$i.Bytes
        }
    }
    return $res
}

function Remove-UpdateLeftovers {
    param($Items)
    $freed = 0.0
    $n = 0
    foreach ($i in @($Items)) {
        try {
            Remove-Item -LiteralPath $i.Path -Recurse -Force -ErrorAction Stop
            $freed += [double]$i.Bytes
            $n++
        }
        catch { Write-Log "$($i.Path): $($_.Exception.Message)" 'WARNING' }
    }
    return @{ Count = $n; Bytes = $freed }
}

function Invoke-UpdateRepair {
    # Reihenfolge: aufraeumen, Dienste wirklich anhalten, erst dann umbenennen.
    $plan = Get-UpdateLeftoverPlan -Items (Get-UpdateLeftovers)
    if (@($plan.Remove).Count -gt 0) {
        $msg = "{0}: {1} ({2})`n`n{3}" -f (Get-Text 'UpdLeftovers'), @($plan.Remove).Count,
        (Get-FormattedBytes $plan.Bytes), (Get-Text 'UpdCleanOld')
        if (Show-Confirm -Message $msg) {
            $r = Remove-UpdateLeftovers -Items $plan.Remove
            Write-Log ("{0}: {1} - {2}" -f (Get-Text 'UpdLeftovers'), $r.Count, (Get-FormattedBytes $r.Bytes)) 'SUCCESS'
        }
    }

    $res = Show-WarningDialog -Title (Get-Text 'UpdRepair') -Message (Get-Text 'UpdRepairWarn')
    if ($res -ne [System.Windows.Forms.DialogResult]::OK) { return }

    Show-BusyOverlay -Title (Get-Text 'UpdRepair') -Status (Get-Text 'UpdSvcStopping')
    $stopped = @()
    $stuck = @()
    try {
        $step = 0
        foreach ($s in $script:WuRepairServices) {
            $step++
            Update-BusyOverlay -Status "$s" -Percent ([int](($step / [double]($script:WuRepairServices.Count + 2)) * 100))
            if (Stop-ServiceAndWait -Name $s -TimeoutSec 20) { $stopped += $s } else { $stuck += $s }
        }
        # Ein noch laufender Dienst haelt die Dateien offen - dann scheitert
        # das Umbenennen und der halbreparierte Zustand ist schlechter als vorher.
        if (@($stuck).Count -gt 0) {
            Write-Log ("{0}: {1}" -f (Get-Text 'UpdSvcStop'), ($stuck -join ', ')) 'ERROR'
            Write-Log (Get-Text 'UpdRepairAbort') 'WARNING'
            return
        }

        $folders = @(Get-UpdateRepairFolders)
        $ok = 0
        $failed = @()
        foreach ($f in $folders) {
            Update-BusyOverlay -Status (Split-Path -Leaf $f) -Percent 80
            if (Rename-UpdateFolder -Path $f -Label (Get-Text 'UpdRepair')) { $ok++ }
            else { $failed += (Split-Path -Leaf $f) }
        }
        Write-TweakOutcome -Label (Get-Text 'UpdRepair') -Ok $ok -Total @($folders).Count -Failed $failed
    }
    finally {
        Update-BusyOverlay -Status (Get-Text 'UpdSvcStarting') -Percent 95
        $back = 0
        foreach ($s in $stopped) { if (Start-ServiceChecked -Name $s) { $back++ } }
        Write-Log ("{0}: {1}/{2}" -f (Get-Text 'UpdSvcRestart'), $back, @($stopped).Count) `
            $(if ($back -ge @($stopped).Count) { 'SUCCESS' } else { 'WARNING' })
        Hide-BusyOverlay
    }
}

function Show-Updates {
    Add-ViewHeader -TitleKey 'MenuUpdates' -SubtitleKey 'UpdatesSubtitle' -Icon 'refresh'

    Add-Card -TitleKey 'UpdPause' -DescKey 'UpdPauseDesc' -BtnKey 'Stop' -Icon 'pause' -X 25 -Y 95 -Color $script:Theme.Warning -Action {
        $state = Get-UpdatePauseState -Values (Read-UpdatePauseValues)
        if ($state.Paused) {
            Write-Log ("{0} {1} ({2} {3})" -f (Get-Text 'UpdPaused'), $state.UntilText, $state.DaysLeft, (Get-Text 'UpdPauseDays')) 'INFO'
            return
        }
        $plan = Get-UpdatePausePlan -Days 35
        $until = ([datetime]$plan.End).ToLocalTime().ToString('yyyy-MM-dd HH:mm')
        $msg = "{0}`n`n{1}: {2}`n`n{3}" -f (Get-Text 'UpdPauseConfirm'), (Get-Text 'UpdPauseUntil'), $until, (Get-Text 'UpdPauseMax')
        if (-not (Show-Confirm -Message $msg)) { return }
        # Der Dienst wird bewusst nicht mehr angehalten: Windows startet
        # wuauserv ueber einen Ausloeser ohnehin neu - das sah nach Wirkung
        # aus, war aber keine.
        $after = Set-UpdatePause -Days $plan.Days
        if ($after.Paused) { Write-Log ("{0} {1}" -f (Get-Text 'UpdPaused'), $after.UntilText) 'SUCCESS' }
        else { Write-Log "$(Get-Text 'UpdPause'): $(Get-Text 'ChangeVerifyErr')" 'ERROR' }
        Update-UpdatesPanel
    } | Out-Null

    Add-Card -TitleKey 'UpdResume' -DescKey 'UpdResumeDesc' -BtnKey 'Start' -Icon 'play' -X 315 -Y 95 -Color $script:Theme.Success -Action {
        $state = Get-UpdatePauseState -Values (Read-UpdatePauseValues)
        if (-not $state.Paused -and $state.Found -eq 0) {
            Write-Log (Get-Text 'UpdNotPaused') 'INFO'
            return
        }
        if ($state.Expired) { Write-Log (Get-Text 'UpdExpired') 'INFO' }
        if (-not (Show-Confirm -Message (Get-Text 'UpdResumeConfirm'))) { return }
        [void](Resume-WindowsUpdate)
        try {
            # Ein von frueheren Fassungen lahmgelegter Dienst wird wieder auf
            # seinen urspruenglichen Starttyp gesetzt - nicht pauschal auf
            # Automatisch, der Auslieferungszustand ist Manuell mit Ausloeser.
            $svcPlan = Get-ServiceActionPlan -Action 'Enable' `
                -CurrentStartup (Get-ServiceStartupType -Name 'wuauserv') `
                -PreviousStartup (Get-LastServiceStartup -Name 'wuauserv')
            if ($svcPlan.Allowed) { Set-Service wuauserv -StartupType $svcPlan.Target -ErrorAction SilentlyContinue }
            [void](Start-ServiceChecked -Name 'wuauserv')
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'WARNING' }
        Update-UpdatesPanel
    } | Out-Null

    Add-Card -TitleKey 'UpdRepair' -DescKey 'UpdRepairDesc' -BtnKey 'Start' -Icon 'wrench' -X 605 -Y 95 -Color $script:Theme.Error -Action {
        Invoke-UpdateRepair
        Update-UpdatesPanel
    } | Out-Null

    Add-Card -TitleKey 'Analyze' -DescKey 'UpdatesSubtitle' -BtnKey 'Analyze' -Icon 'search' -X 895 -Y 95 -Color $script:Theme.Cyan -Action {
        Write-HotfixLog
    } | Out-Null

    $txt = New-Object System.Windows.Forms.RichTextBox
    $txt.Location = New-Object System.Drawing.Point(25, 265)
    $txt.Size = New-Object System.Drawing.Size(1120, 350)
    $txt.BackColor = $script:Theme.BgSecondary
    $txt.ForeColor = $script:Theme.TextPrimary
    $txt.ReadOnly = $true
    $txt.BorderStyle = 'None'
    $txt.Anchor = 'Top,Bottom,Left,Right'
    $txt.Font = (Get-AppFont -Family $script:MonoFont -Size 9)
    $script:pnlContent.Controls.Add($txt)

    $script:txtUpdates = $txt

    $txt.AppendText("  $(Get-Text 'MenuUpdates')`n`n")
    $txt.AppendText("  $(Get-Text 'Loading')`n")

    # Get-HotFix needs 1-4 seconds on most machines - never on the UI path
    Invoke-Deferred -Action { Update-UpdatesPanel }
}

$script:HotfixLoader = {
    Get-HotFix -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending |
        Select-Object -Property @{ N = 'HotFixID'; E = { [string]$_.HotFixID } },
        @{ N = 'Description'; E = { [string]$_.Description } },
        @{ N = 'InstalledOn'; E = { if ($_.InstalledOn) { (Get-Date $_.InstalledOn -Format 'yyyy-MM-dd') } else { '' } } }
}

function Write-HotfixLog {
    # Lader und Ausgabe standen frueher zweimal wortgleich in der Ansicht -
    # eine Aenderung an der einen Stelle ging an der anderen vorbei.
    $ready = Request-CachedData -Key 'HotFix' -TtlSeconds 300 -OnReady { Write-HotfixLog } -Loader $script:HotfixLoader
    if (-not $ready) { Write-Log (Get-Text 'Loading') 'SYSTEM'; return }
    Write-Log "=== $(Get-Text 'MenuUpdates') ===" 'TITLE'
    foreach ($h in (@(Get-CacheEntryData -Key 'HotFix') | Select-Object -First 10)) {
        Write-Log "$($h.HotFixID) - $($h.InstalledOn)" 'INFO'
    }
}

function Update-UpdatesPanel {
    # Zeichnet Pausenzustand, Altlasten und die Hotfix-Uebersicht. Liegen die
    # Daten noch nicht vor, startet Request-CachedData die Abfrage im
    # Hintergrund und ruft diese Funktion danach erneut auf.
    $txt = $script:txtUpdates
    if (-not $txt -or $txt.IsDisposed) { return }

    $ready = Request-CachedData -Key 'HotFix' -TtlSeconds 300 -OnReady { Update-UpdatesPanel } -Loader $script:HotfixLoader
    if (-not $ready) { return }

    try {
        $txt.Clear()
        $txt.AppendText("  $(Get-Text 'MenuUpdates')`n`n")

        # Der Zustand der Pause stand nirgends - man klickte auf Pausieren und
        # hatte danach keinen Anhaltspunkt, ob sie ueberhaupt greift.
        $state = Get-UpdatePauseState -Values (Read-UpdatePauseValues)
        if ($state.Paused) {
            $txt.AppendText(("  {0} {1}  ({2} {3})`n" -f (Get-Text 'UpdPaused'), $state.UntilText, $state.DaysLeft, (Get-Text 'UpdPauseDays')))
        }
        elseif ($state.Expired) { $txt.AppendText("  $(Get-Text 'UpdExpired')`n") }
        else { $txt.AppendText("  $(Get-Text 'UpdNotPaused')`n") }

        $svc = Get-Service wuauserv -ErrorAction SilentlyContinue
        if ($svc) { $txt.AppendText("  $(Get-Text 'UpdService') : $($svc.Status)`n") }

        $left = @(Get-UpdateLeftovers)
        if ($left.Count -gt 0) {
            $sum = 0.0
            foreach ($l in $left) { $sum += [double]$l.Bytes }
            $txt.AppendText(("  {0}: {1} ({2})`n" -f (Get-Text 'UpdLeftovers'), $left.Count, (Get-FormattedBytes $sum)))
        }
        $txt.AppendText("`n")

        $list = @(Get-CacheEntryData -Key 'HotFix') | Select-Object -First 15
        if ($list.Count -eq 0) { $txt.AppendText("  $(Get-Text 'EmptyNoEntries')`n") }
        foreach ($h in $list) {
            $txt.AppendText(("  {0,-12} {1,-22} {2}`n" -f $h.HotFixID, $h.Description, $h.InstalledOn))
        }
    }
    catch { $txt.AppendText("  $(Get-Text 'Error'): $($_.Exception.Message)`n") }
}

# ------------------------------------------------------------------ NETWORK --
function Show-Network {
    Add-ViewHeader -TitleKey 'MenuNetwork' -SubtitleKey 'NetworkSubtitle' -Icon 'globe'

    Add-Card -TitleKey 'NetDNS' -DescKey 'NetDNSDesc' -BtnKey 'Apply' -Icon 'globe' -X 25 -Y 95 -Color $script:Theme.Cyan -Action {
        # Erst messen: welche Adapter weichen ueberhaupt ab? Stehen alle schon
        # auf dem Ziel, ist der naechste Klick der Weg zurueck auf DHCP.
        $ad = @(Get-DnsAdapterTargets)
        $plan = Get-DnsActionPlan -Adapters $ad -Target $script:DnsTarget4
        if ($plan.Mode -eq 'none') { Write-Log (Get-Text 'NetDnsNone') 'WARNING'; return }

        $lines = @()
        foreach ($a in $plan.Items) { $lines += ("  {0}: {1}" -f $a.Name, (Format-DnsServerList -Servers $a.V4)) }
        $list = ($lines -join "`n")

        if ($plan.Mode -eq 'reset') {
            if (-not (Show-Confirm -Message "$(Get-Text 'NetDnsReset')`n`n$list")) { return }
        }
        else {
            $msg = "$(Get-Text 'NetDnsConfirm')`n`n$list`n`n-> $($script:DnsTarget4 -join ', ')"
            $risk = Test-DnsChangeRisk -DomainJoined (Test-DomainJoined) -VpnActive (Test-VpnAdapterActive)
            if ($risk.Level -eq 'warn') {
                $res = Show-WarningDialog -Title (Get-Text 'NetDNS') -Message "$msg`n`n$(Get-Text $risk.ReasonKey)"
                if ($res -ne [System.Windows.Forms.DialogResult]::OK) { return }
            }
            elseif (-not (Show-Confirm -Message $msg)) { return }
        }

        $ok = 0
        $failed = @()
        foreach ($a in $plan.Items) {
            $v4 = @()
            $v6 = @()
            if ($plan.Mode -eq 'set') {
                $v4 = @($script:DnsTarget4)
                # Ohne IPv6 bliebe der vom Router gelieferte v6-Resolver stehen
                # und Windows wuerde ihn bevorzugen - die Umstellung waere wirkungslos.
                if (@($a.V6).Count -gt 0) { $v6 = @($script:DnsTarget6) }
            }
            if (Set-AdapterDnsServers -Adapter $a -V4 $v4 -V6 $v6) { $ok++ } else { $failed += $a.Name }
        }
        if ($ok -gt 0) {
            try { Clear-DnsClientCache -ErrorAction Stop } catch { [void](Invoke-SystemCommand -File 'ipconfig.exe' -Arguments '/flushdns' -TimeoutSec 30) }
        }
        Write-TweakOutcome -Label (Get-Text 'NetDNS') -Ok $ok -Total @($plan.Items).Count -Failed $failed
    } | Out-Null

    Add-Card -TitleKey 'NetNagle' -DescKey 'NetNagleDesc' -BtnKey 'Disable' -Icon 'bolt' -X 315 -Y 95 -Color $script:Theme.Warning -Action {
        $ifs = @(Get-NagleInterfaces)
        $plan = Get-NagleActionPlan -Interfaces $ifs
        if ($plan.Mode -eq 'none') { Write-Log (Get-Text 'NetNagleNone') 'WARNING'; return }

        $head = if ($plan.Mode -eq 'revert') { Get-Text 'NetNagleRevert' } else { Get-Text 'NetNagleConfirm' }
        $info = "{0}: {1}/{2}" -f (Get-Text 'NetNagleCount'), $plan.Applied, $plan.Total
        if (-not (Show-Confirm -Message "$head`n`n$info")) { return }

        # Gesichert wird der Schluessel, in den auch geschrieben wird - bisher
        # ging eine Sicherung des Multimedia-Profils heraus, das hier gar nicht vorkommt.
        [void](Backup-RegistryKey -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -Name 'TcpipInterfaces')

        $ok = 0
        $failed = @()
        foreach ($i in $plan.Items) {
            $good = $true
            foreach ($n in @('TcpAckFrequency', 'TCPNoDelay')) {
                if ($plan.Mode -eq 'revert') {
                    [void](Remove-RegistryValue -Path $i.Path -Name $n -Label (Get-Text 'NetNagle') -Quiet)
                    if (Test-RegistryValuePresent -Path $i.Path -Name $n) { $good = $false }
                }
                elseif (-not (Set-RegistryValue -Path $i.Path -Name $n -Value 1 -Type DWord -Label (Get-Text 'NetNagle') -Quiet)) {
                    $good = $false
                }
            }
            if ($good) { $ok++ } else { $failed += ([string]$i.Name).Trim('{', '}') }
        }
        Write-TweakOutcome -Label (Get-Text 'NetNagle') -Ok $ok -Total @($plan.Items).Count -Failed $failed
    } | Out-Null

    Add-Card -TitleKey 'NetWinsock' -DescKey 'NetWinsockDesc' -BtnKey 'Reset' -Icon 'plug' -X 605 -Y 95 -Color $script:Theme.Error -Action {
        # Das hier wirft Proxy-Einstellungen, statische Adressen und
        # Filtertreiber weg - dafuer reicht die allgemeine Ja/Nein-Frage nicht.
        $res = Show-WarningDialog -Title (Get-Text 'NetWinsock') -Message (Get-Text 'NetResetWarn')
        if ($res -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $codes = @()
        Show-BusyOverlay -Title (Get-Text 'NetWinsock') -Status 'netsh winsock reset'
        try {
            $codes += Invoke-SystemCommand -File 'netsh.exe' -Arguments 'winsock reset' -TimeoutSec 120 -Label 'netsh winsock reset'
            Update-BusyOverlay -Status 'netsh int ip reset' -Percent 50
            $codes += Invoke-SystemCommand -File 'netsh.exe' -Arguments 'int ip reset' -TimeoutSec 120 -Label 'netsh int ip reset'
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
        finally { Hide-BusyOverlay }
        $r = Get-NetResetResult -Codes $codes
        Write-Log "$(Get-Text 'NetWinsock'): $(Get-Text $r.Key)" $r.Level
        if ($r.Reboot) {
            Set-RebootHint
            Write-Log "$(Get-Text 'NetWinsock'): $(Get-Text 'DlgRestartReq')" 'WARNING'
        }
    } | Out-Null

    Add-Card -TitleKey 'NetPing' -DescKey 'NetPingDesc' -BtnKey 'Start' -Icon 'signal' -X 895 -Y 95 -Color $script:Theme.Success -Action {
        # Mehrere Ziele brauchen einige Sekunden - ohne Overlay sah das Fenster
        # die ganze Zeit eingefroren aus; abbrechen laesst es sich gefahrlos.
        Show-BusyOverlay -Title (Get-Text 'NetPing') -Status '1.1.1.1' -Cancellable
        try {
            Write-Log "=== $(Get-Text 'NetPing') ===" 'TITLE'
            $targets = @('1.1.1.1', '8.8.8.8', 'google.com')
            $count = 4
            $n = 0
            foreach ($target in $targets) {
                if (Test-BusyCancelled) { Write-Log (Get-Text 'BusyCancelled') 'WARNING'; break }
                $n++
                Update-BusyOverlay -Status "ping $target" -Percent ([int](($n - 1) / [double]$targets.Count * 100))
                $times = @()
                try {
                    foreach ($r in @(Test-Connection -ComputerName $target -Count $count -ErrorAction SilentlyContinue)) {
                        if ($null -ne $r -and $null -ne $r.ResponseTime) { $times += [int]$r.ResponseTime }
                    }
                }
                catch { }
                $s = Get-PingSummary -Sent $count -Times $times
                if ($s.Received -gt 0) {
                    Write-Log ("{0} : {1} ms ({2}/{3}, {4} % {5}; min {6} / max {7})" -f `
                            $target, $s.Avg, $s.Received, $s.Sent, $s.Loss, (Get-Text $s.Key), $s.Min, $s.Max) $s.Level
                }
                else { Write-Log "$target : $(Get-Text 'NetPingDead')" 'ERROR' }
                Update-BusyOverlay -Percent ([int]($n / [double]$targets.Count * 100))
            }
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
        finally { Hide-BusyOverlay }
    } | Out-Null

    Add-Card -TitleKey 'NetSpeed' -DescKey 'NetSpeedDesc' -BtnKey 'Optimize' -Icon 'rocket' -X 25 -Y 265 -Color $script:Theme.Purple -Action {
        Set-TcpOptimization
    } | Out-Null

    Add-Card -TitleKey 'QuickDNS' -DescKey 'QuickDNSDesc' -BtnKey 'Clean' -Icon 'broom' -X 315 -Y 265 -Color $script:Theme.Accent -Action {
        try { Clear-DnsClientCache -ErrorAction Stop } catch { ipconfig /flushdns | Out-Null }
        Write-Log "$(Get-Text 'QuickDNS'): $(Get-Text 'Success')" 'SUCCESS'
    } | Out-Null

    $txt = New-Object System.Windows.Forms.RichTextBox
    $txt.Location = New-Object System.Drawing.Point(25, 435)
    $txt.Size = New-Object System.Drawing.Size(1120, 180)
    $txt.BackColor = $script:Theme.BgSecondary
    $txt.ForeColor = $script:Theme.TextPrimary
    $txt.ReadOnly = $true
    $txt.BorderStyle = 'None'
    $txt.Anchor = 'Top,Bottom,Left,Right'
    $txt.Font = (Get-AppFont -Family $script:MonoFont -Size 9)
    $script:pnlContent.Controls.Add($txt)

    $txt.AppendText("  $(Get-Text 'Loading')`n")

    $script:txtNetwork = $txt
    Invoke-Deferred -Action { Update-NetworkPanel }
}

function Update-NetworkPanel {
    # Get-NetAdapter und Get-NetIPAddress je Adapter summieren sich auf ein bis
    # zwei Sekunden. Die fertigen Zeilen entstehen deshalb im Hintergrund.
    $txt = $script:txtNetwork
    if (-not $txt -or $txt.IsDisposed) { return }

    $ready = Request-CachedData -Key 'NetLines' -TtlSeconds 30 -OnReady { Update-NetworkPanel } -Loader {
        $out = New-Object System.Collections.Generic.List[string]
        try {
            foreach ($a in (Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' })) {
                $out.Add(("  {0,-28} {1,-14} {2}" -f $a.Name, $a.MacAddress, $a.LinkSpeed))
                $ips = Get-NetIPAddress -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue |
                    Where-Object { $_.AddressFamily -eq 'IPv4' }
                foreach ($ip in $ips) { $out.Add("      IPv4: $($ip.IPAddress)/$($ip.PrefixLength)") }
            }
        }
        catch { $out.Add("  $($_.Exception.Message)") }
        return $out.ToArray()
    }
    if (-not $ready) { return }

    try {
        $txt.Clear()
        $lines = @(Get-CacheEntryData -Key 'NetLines')
        if ($lines.Count -eq 0) { $txt.AppendText("  $(Get-Text 'EmptyNoEntries')`n") }
        foreach ($l in $lines) { $txt.AppendText("$l`n") }
    }
    catch { $txt.AppendText("  $(Get-Text 'Error'): $($_.Exception.Message)`n") }
}

# ---------------------------------------------------------------- PROCESSES --
function Show-Processes {
    Add-ViewHeader -TitleKey 'MenuProcesses' -SubtitleKey 'ProcSubtitle' -Icon 'bars'

    [void](Add-ListSearchBox -Name 'Prozesse' -PlaceholderKey 'ProcSearch' -Action {
            param($q) Update-ProcessList -Filter $q
        })

    $lst = New-Object System.Windows.Forms.ListView
    $lst.Location = New-Object System.Drawing.Point(25, 145)
    $lst.Size = New-Object System.Drawing.Size(900, 470)
    $lst.View = 'Details'
    $lst.FullRowSelect = $true
    $lst.BackColor = $script:Theme.BgSecondary
    $lst.ForeColor = $script:Theme.TextPrimary
    $lst.BorderStyle = 'None'
    $lst.Anchor = 'Top,Bottom,Left,Right'
    $lst.Font = (Get-AppFont -Size 9)
    [void]$lst.Columns.Add((Get-Text 'ColName'), 230)
    [void]$lst.Columns.Add('PID', 80)
    [void]$lst.Columns.Add('RAM', 120)
    [void]$lst.Columns.Add('CPU %', 100)
    [void]$lst.Columns.Add((Get-Text 'ProcThreads'), 100)
    [void]$lst.Columns.Add((Get-Text 'ColState'), 130)
    $script:pnlContent.Controls.Add($lst)
    Set-ListViewColumnFit -ListView $lst -Weights @(3, 1, 2, 1, 1, 2) -Name 'Prozesse'
    Set-ListViewSortable -ListView $lst -Name 'Prozesse'
    Add-ListContextMenu -ListView $lst -Name 'Prozesse'
    $script:lstProcesses = $lst

    $btnKill = New-Object System.Windows.Forms.Button
    $btnKill.Text = "{icon:ban} $(Get-Text 'ProcKill')"
    $btnKill.Location = New-Object System.Drawing.Point(945, 145)
    $btnKill.Anchor = 'Top,Right'
    $btnKill.Size = New-Object System.Drawing.Size(200, 40)
    $btnKill.BackColor = $script:Theme.Error
    $btnKill.ForeColor = $script:Theme.TextWhite
    $btnKill.FlatStyle = 'Flat'
    $btnKill.FlatAppearance.BorderSize = 0
    $btnKill.Font = (Get-AppFont -Size 9 -Style 'Bold')
    $btnKill.Cursor = 'Hand'
    $btnKill.Add_Click({ Invoke-ProcessKill })
    $script:pnlContent.Controls.Add($btnKill)

    $btnRef = New-Object System.Windows.Forms.Button
    $btnRef.Text = "{icon:refresh} $(Get-Text 'Refresh')"
    $btnRef.Location = New-Object System.Drawing.Point(945, 193)
    $btnRef.Anchor = 'Top,Right'
    $btnRef.Size = New-Object System.Drawing.Size(200, 40)
    $btnRef.BackColor = $script:Theme.BgTertiary
    $btnRef.ForeColor = $script:Theme.TextPrimary
    $btnRef.FlatStyle = 'Flat'
    $btnRef.FlatAppearance.BorderSize = 0
    $btnRef.Font = (Get-AppFont -Size 9 -Style 'Bold')
    $btnRef.Cursor = 'Hand'
    $btnRef.Add_Click({ Update-ProcessList -Force })
    $script:pnlContent.Controls.Add($btnRef)

    $btnAuto = New-Object System.Windows.Forms.Button
    $btnAuto.Text = "{icon:clock} $(Get-Text 'ProcAuto')"
    $btnAuto.Location = New-Object System.Drawing.Point(945, 241)
    $btnAuto.Anchor = 'Top,Right'
    $btnAuto.Size = New-Object System.Drawing.Size(200, 40)
    $btnAuto.BackColor = $script:Theme.BgTertiary
    $btnAuto.ForeColor = $script:Theme.TextPrimary
    $btnAuto.FlatStyle = 'Flat'
    $btnAuto.FlatAppearance.BorderSize = 0
    $btnAuto.Font = (Get-AppFont -Size 9 -Style 'Bold')
    $btnAuto.Cursor = 'Hand'
    $btnAuto.Add_Click({ Set-ProcessAutoRefresh -Enabled (-not $script:Config.ProcAutoRefresh) })
    Set-Tip $btnAuto (Get-Text 'TipProcAuto')
    $script:pnlContent.Controls.Add($btnAuto)
    $script:btnProcAuto = $btnAuto

    $script:ProcRowKeys = @()
    Invoke-Deferred -Action {
        Update-ProcessList -Force
        Set-ProcessAutoRefresh -Enabled ([bool]$script:Config.ProcAutoRefresh)
    }
}

function Get-ProcessCpuMap {
    # Die Spalte zeigte bisher die seit dem Start verbrauchte Rechenzeit.
    # Ein seit acht Stunden offener Browser stand damit oben, waehrend der
    # Prozess, der gerade wirklich die Lueftung hochdreht, mit zwoelf
    # Sekunden unten lag. Gebraucht wird die Last SEIT DER LETZTEN MESSUNG:
    # verbrauchte Zeit geteilt durch vergangene Zeit, geteilt durch die Zahl
    # der Kerne.
    param($Current, $Previous, [double]$ElapsedSeconds = 0, [int]$Cores = 1, $PreviousMap = $null)
    $map = @{}
    $cur = @($Current)
    if ($Cores -lt 1) { $Cores = 1 }
    $prev = @{}
    if ($Previous) { foreach ($k in @($Previous.Keys)) { $prev[[string]$k] = $Previous[$k] } }

    # Zu kurz gemessen: ein Fenster von Millisekunden macht aus jedem
    # Rundungsfehler eine Spitze. Dann lieber die vorige Anzeige behalten und
    # die Vergleichsmarke stehen lassen.
    if ($prev.Count -gt 0 -and $ElapsedSeconds -lt 0.4) {
        $keep = @{}
        if ($PreviousMap) { foreach ($k in @($PreviousMap.Keys)) { $keep[[string]$k] = $PreviousMap[$k] } }
        foreach ($c in $cur) { if (-not $keep.ContainsKey([string]$c.Id)) { $keep[[string]$c.Id] = -1.0 } }
        return @{ Map = $keep; Samples = $prev; Kept = $true }
    }

    $next = @{}
    foreach ($c in $cur) {
        if (-not $c) { continue }
        $id = [string]$c.Id
        $cpu = 0.0
        try { $cpu = [double]$c.Cpu } catch { $cpu = 0.0 }
        $next[$id] = @{ Id = $c.Id; Cpu = $cpu; Start = $c.Start }
        $pct = -1.0
        if ($prev.ContainsKey($id) -and $ElapsedSeconds -gt 0) {
            $p = $prev[$id]
            # Kennungen werden wiederverwendet: nur wenn auch der Startzeit-
            # punkt uebereinstimmt, ist es derselbe Prozess.
            $same = $true
            try { $same = ("$($p.Start)" -eq "$($c.Start)") } catch { $same = $true }
            if ($same) {
                $delta = $cpu - [double]$p.Cpu
                if ($delta -lt 0) { $delta = 0 }
                $pct = ($delta / $ElapsedSeconds / $Cores) * 100.0
                if ($pct -lt 0) { $pct = 0 }
                if ($pct -gt 100) { $pct = 100 }
                $pct = [math]::Round($pct, 1)
            }
        }
        $map[$id] = $pct
    }
    return @{ Map = $map; Samples = $next; Kept = $false }
}

function Format-ProcessCpu {
    # Unbekannt ist nicht null - beim ersten Durchgang gibt es noch keinen
    # Vergleichswert, und das muss man sehen koennen.
    param([double]$Percent)
    if ($Percent -lt 0) { return '-' }
    return ('{0:N1} %' -f $Percent)
}

function Get-ProcessStatusKey {
    # Ein haengendes Fenster ist der haeufigste Grund, diese Ansicht
    # ueberhaupt zu oeffnen - sie verriet es bisher nicht.
    param([bool]$Responding = $true, [bool]$Protected = $false)
    if (-not $Responding) { return 'ProcHung' }
    if ($Protected) { return 'Protected' }
    return 'ProcOk'
}

function Get-ProcessKillPlan {
    # Was darf beendet werden, was nicht - und was bleibt dann uebrig.
    param($Rows)
    $plan = @{ Kill = @(); Skipped = @(); Names = @() }
    foreach ($r in @($Rows)) {
        if (-not $r) { continue }
        $prot = $false
        try { $prot = [bool]$r.Protected } catch { }
        if ($prot) { $plan.Skipped += [string]$r.Name; continue }
        $plan.Kill += $r
        $plan.Names += [string]$r.Name
    }
    return $plan
}

function Test-ProcessRowMatch {
    # Gesucht wird in Name UND Kennung - frueher fand die Eingabe einer PID
    # nichts, obwohl die Spalte direkt daneben steht.
    param([string]$Name = '', $ProcessId = 0, [string]$Filter = '')
    if ([string]::IsNullOrWhiteSpace($Filter)) { return $true }
    $f = $Filter.ToLowerInvariant()
    if (("$Name").ToLowerInvariant().Contains($f)) { return $true }
    return ("$ProcessId").Contains($f)
}

function Get-ProcessRows {
    # Baut die reinen Zeilendaten. Ohne Oberflaechenbezug, damit sich die
    # Filterung und die Formatierung einzeln pruefen lassen.
    param($Processes = @(), [string]$Filter = '', $CpuMap = $null)
    $rows = New-Object System.Collections.Generic.List[object]
    $total = 0
    foreach ($p in @($Processes)) {
        if (-not $p) { continue }
        $total++
        if (-not (Test-ProcessRowMatch -Name $p.ProcessName -ProcessId $p.Id -Filter $Filter)) { continue }
        $threads = ''
        try { $threads = [string]$p.Threads.Count } catch { $threads = '' }
        $ws = 0
        try { $ws = [int64]$p.WorkingSet64 } catch { $ws = 0 }
        $pct = -1.0
        if ($CpuMap -and $CpuMap.ContainsKey([string]$p.Id)) { $pct = [double]$CpuMap[[string]$p.Id] }
        $resp = $true
        try { if ($null -ne $p.Responding) { $resp = [bool]$p.Responding } } catch { $resp = $true }
        $prot = [bool](Test-ProcessProtected -ProcessName $p.ProcessName)
        $statusKey = Get-ProcessStatusKey -Responding $resp -Protected $prot
        $rows.Add([pscustomobject]@{
                Key       = "$($p.Id)"
                Name      = "$($p.ProcessName)"
                Cells     = @("$($p.ProcessName)", "$($p.Id)", (Get-FormattedBytes $ws),
                    (Format-ProcessCpu -Percent $pct), $threads, (Get-Text $statusKey))
                Protected = $prot
                Hung      = (-not $resp)
                Heavy     = ($ws -gt 500MB -or $pct -ge 25)
                StatusKey = $statusKey
            })
    }
    return [pscustomobject]@{ Rows = $rows.ToArray(); Total = $total }
}

function Test-ListKeysEqual {
    # Mengengleichheit, Reihenfolge egal: solange dieselben Prozesse laufen,
    # genuegt ein Aktualisieren der Werte an Ort und Stelle.
    param([string[]]$A = @(), [string[]]$B = @())
    $x = @($A)
    $y = @($B)
    if ($x.Count -ne $y.Count) { return $false }
    if ($x.Count -eq 0) { return $true }
    $seen = @{}
    foreach ($k in $x) { $seen["$k"] = ([int]$seen["$k"]) + 1 }
    foreach ($k in $y) {
        $c = [int]$seen["$k"]
        if ($c -le 0) { return $false }
        $seen["$k"] = $c - 1
    }
    return $true
}

function Update-ProcessList {
    param([string]$Filter, [switch]$Force, [switch]$Quiet)

    if ($PSBoundParameters.ContainsKey('Filter')) { Set-ListFilter -Name 'Prozesse' -Value $Filter }
    else { $Filter = Get-ListFilter 'Prozesse' }

    $lv = $script:lstProcesses
    if (-not $lv -or $lv.IsDisposed) { return }
    try {
        $procs = Get-CachedData -Key 'Processes' -TtlSeconds 3 -Force:$Force -Loader {
            Get-Process -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending
        }

        # Messpunkt fuer die Auslastung seit dem letzten Durchgang
        $samples = New-Object System.Collections.Generic.List[object]
        foreach ($p in @($procs)) {
            if (-not $p) { continue }
            $cpu = 0.0
            try { $cpu = [double]$p.CPU } catch { $cpu = 0.0 }
            $st = ''
            try { if ($p.StartTime) { $st = ([datetime]$p.StartTime).Ticks } } catch { $st = '' }
            $samples.Add(@{ Id = $p.Id; Cpu = $cpu; Start = $st })
        }
        $now = Get-Date
        $elapsed = 0.0
        if ($script:ProcCpuTime) { $elapsed = ($now - $script:ProcCpuTime).TotalSeconds }
        $cores = 1
        try { $cores = [int][Environment]::ProcessorCount } catch { }
        $cpuRes = Get-ProcessCpuMap -Current $samples -Previous $script:ProcCpuPrev `
            -ElapsedSeconds $elapsed -Cores $cores -PreviousMap $script:ProcCpuMap
        $script:ProcCpuMap = $cpuRes.Map
        $script:ProcCpuPrev = $cpuRes.Samples
        if (-not $cpuRes.Kept) { $script:ProcCpuTime = $now }

        $data = Get-ProcessRows -Processes $procs -Filter $Filter -CpuMap $script:ProcCpuMap
        $rows = @($data.Rows)
        $keys = @($rows | ForEach-Object { $_.Key })

        # Gleiche Prozessmenge -> nur die Zahlen nachziehen. Ein vollstaendiger
        # Neuaufbau wuerde alle 2,5 Sekunden Auswahl, Bildlauf und Fokus
        # wegwerfen und die Liste sichtbar flackern lassen.
        if ($lv.Items.Count -gt 0 -and (Test-ListKeysEqual -A $script:ProcRowKeys -B $keys)) {
            $byKey = @{}
            foreach ($row in $rows) { $byKey[$row.Key] = $row }
            foreach ($it in $lv.Items) {
                $row = $byKey["$($it.Tag)"]
                if (-not $row) { continue }
                for ($c = 0; $c -lt $row.Cells.Count -and $c -lt $it.SubItems.Count; $c++) {
                    if ($it.SubItems[$c].Text -ne $row.Cells[$c]) { $it.SubItems[$c].Text = $row.Cells[$c] }
                }
                $col = if ($row.Hung) { $script:Theme.Error }
                elseif ($row.Protected) { $script:Theme.Warning }
                elseif ($row.Heavy) { $script:Theme.Pink }
                else { $script:Theme.TextPrimary }
                if ($it.ForeColor -ne $col) { $it.ForeColor = $col }
            }
            Set-ListFilterCount -Name 'Prozesse' -Shown $rows.Count -Total $data.Total
            return
        }

        $lv.BeginUpdate()
        try {
            $lv.Items.Clear()
            $items = New-Object System.Collections.Generic.List[System.Windows.Forms.ListViewItem]
            foreach ($row in $rows) {
                $item = New-Object System.Windows.Forms.ListViewItem($row.Cells[0])
                for ($c = 1; $c -lt $row.Cells.Count; $c++) { [void]$item.SubItems.Add($row.Cells[$c]) }
                $item.Tag = $row.Key
                if ($row.Hung) {
                    $item.ForeColor = $script:Theme.Error
                    $item.ToolTipText = Get-Text 'ProcHung'
                }
                elseif ($row.Protected) {
                    $item.ForeColor = $script:Theme.Warning
                    $item.ToolTipText = Get-Text 'Protected'
                }
                elseif ($row.Heavy) { $item.ForeColor = $script:Theme.Pink }
                $items.Add($item)
            }
            $lv.Items.AddRange($items.ToArray())
            Set-ListFilterCount -Name 'Prozesse' -Shown $items.Count -Total $data.Total
            Add-EmptyState -ListView $lv -Text (Get-Text 'EmptyFilter') -SubText $(if ($Filter) { "'$Filter'" } else { '' })
            Restore-ListViewSort -ListView $lv -Name 'Prozesse'
        }
        finally { $lv.EndUpdate() }
        $script:ProcRowKeys = $keys
    }
    catch {
        if (-not $Quiet) { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    }
}

function Invoke-ProcessKill {
    # Beenden ist nicht rueckgaengig zu machen und kostet ungespeicherte
    # Daten - deshalb erst fragen, dann den ganzen Prozessbaum nehmen und am
    # Ende ein einziges, ehrliches Urteil schreiben.
    if (-not $script:lstProcesses -or $script:lstProcesses.IsDisposed) { return }
    $sel = @($script:lstProcesses.SelectedItems)
    if ($sel.Count -eq 0) { Write-Log (Get-Text 'ProcNoSelection') 'INFO'; return }

    $rows = @()
    foreach ($item in $sel) {
        $procId = 0
        try { $procId = [int]$item.SubItems[1].Text } catch { continue }
        $rows += [pscustomobject]@{
            Name = [string]$item.SubItems[0].Text
            Id = $procId
            Protected = [bool](Test-ProcessProtected -ProcessName ([string]$item.SubItems[0].Text))
        }
    }
    $plan = Get-ProcessKillPlan -Rows $rows
    foreach ($skip in @($plan.Skipped)) { Write-Log "$(Get-Text 'Protected'): $skip" 'INFO' }
    $kill = @($plan.Kill)
    if ($kill.Count -eq 0) { Write-Log "$(Get-Text 'ProcKill') : $(Get-Text 'TwkNone')" 'INFO'; return }

    $names = (@($plan.Names) | Select-Object -First 8) -join ', '
    if (@($plan.Names).Count -gt 8) { $names = "$names ..." }
    if (-not (Show-Confirm -Message "$(Get-Text 'ProcKillAsk')`n`n$names")) { return }

    $ok = 0
    $failed = @()
    foreach ($r in $kill) {
        $proc = $null
        try { $proc = Get-Process -Id $r.Id -ErrorAction Stop } catch { $proc = $null }
        if (-not $proc) {
            # Zwischen Auswahl und Klick beendet - kein Fehlschlag.
            $ok++
            continue
        }
        # Stop-Process liess Kindprozesse laufen; taskkill /T nimmt den Baum mit.
        Stop-ProcessTree -Process $proc
        Start-Sleep -Milliseconds 120
        $still = $null
        try { $still = Get-Process -Id $r.Id -ErrorAction Stop } catch { $still = $null }
        if ($still) { $failed += "$($r.Name) ($($r.Id))" } else { $ok++ }
    }
    Write-TweakOutcome -Label (Get-Text 'ProcKill') -Ok $ok -Total $kill.Count -Failed $failed
    Clear-DataCache -Key 'Processes'
    Update-ProcessList -Force
}

function Stop-ProcessAutoRefresh {
    if (-not $script:ProcTimer) { return }
    try { $script:ProcTimer.Stop() } catch { }
    try { $script:ProcTimer.Dispose() } catch { }
    $script:ProcTimer = $null
}

function Set-ProcessAutoRefresh {
    param([bool]$Enabled)
    $script:Config.ProcAutoRefresh = $Enabled
    Stop-ProcessAutoRefresh
    if ($Enabled) {
        $script:ProcTimer = New-Object System.Windows.Forms.Timer
        $script:ProcTimer.Interval = 2500
        $script:ProcTimer.Add_Tick({
                # Nur auf der Prozessansicht und nur bei sichtbarem Fenster -
                # im Hintergrund weiterzuzaehlen kostet nur Strom.
                if ($script:Config.CurrentView -ne 'Processes' -or
                    -not $script:lstProcesses -or $script:lstProcesses.IsDisposed) {
                    Stop-ProcessAutoRefresh
                    return
                }
                if ($script:BusyDepth -gt 0) { return }
                if ($script:MainForm -and -not $script:MainForm.IsDisposed -and
                    ($script:MainForm.WindowState -eq 'Minimized' -or -not $script:MainForm.Visible)) { return }
                Update-ProcessList -Force -Quiet
            })
        $script:ProcTimer.Start()
    }
    if ($script:btnProcAuto -and -not $script:btnProcAuto.IsDisposed) {
        $script:btnProcAuto.BackColor = if ($Enabled) { $script:Theme.Success } else { $script:Theme.BgTertiary }
        $script:btnProcAuto.ForeColor = if ($Enabled) { $script:Theme.TextWhite } else { $script:Theme.TextPrimary }
    }
}

# ----------------------------------------------------------------- REGISTRY --
function Show-Registry {
    Add-ViewHeader -TitleKey 'MenuRegistry' -SubtitleKey 'RegistrySubtitle' -Icon 'folders'

    $defs = @(
        @{ Key = 'RegMui'; Icon = 'file'; Color = $script:Theme.Cyan
            Path  = 'HKCU:\Software\Microsoft\Windows\ShellNoRoam\MUICache'
        },
        @{ Key = 'RegRecent'; Icon = 'clock'; Color = $script:Theme.Purple
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs'
        },
        @{ Key = 'RegRunMRU'; Icon = 'keyboard'; Color = $script:Theme.Warning
            Path  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU'
        },
        @{ Key = 'RegTyped'; Icon = 'globe'; Color = $script:Theme.Success
            Path  = 'HKCU:\Software\Microsoft\Internet Explorer\TypedURLs'
        }
    )

    $x = 25; $y = 95
    foreach ($d in $defs) {
        # Per-iteration copies baked into the closure: otherwise every card would
        # clean the path of the LAST entry in the loop.
        $path = $d.Path
        $label = Get-Text $d.Key
        $action = {
            [void](Invoke-RegistryCardClean -Path $path -Label $label)
        }.GetNewClosure()

        Add-Card -TitleKey $d.Key -DescKey 'RegistrySubtitle' -BtnKey 'Clean' -Icon $d.Icon `
            -Action $action -X $x -Y $y -Color $d.Color | Out-Null
        $x += 290
    }

    $btnScan = New-Object System.Windows.Forms.Button
    $btnScan.Text = "{icon:search} $(Get-Text 'Analyze')"
    $btnScan.Location = New-Object System.Drawing.Point(25, 265)
    $btnScan.Size = New-Object System.Drawing.Size(270, 45)
    $btnScan.BackColor = $script:Theme.Accent
    $btnScan.ForeColor = $script:Theme.TextWhite
    $btnScan.FlatStyle = 'Flat'
    $btnScan.FlatAppearance.BorderSize = 0
    $btnScan.Font = (Get-AppFont -Size 10 -Style 'Bold')
    $btnScan.Cursor = 'Hand'
    $btnScan.Tag = $defs
    $btnScan.Add_Click({
            Write-Log "=== $(Get-Text 'MenuRegistry') ===" 'TITLE'
            foreach ($d in $this.Tag) {
                $exists = Test-Path -LiteralPath $d.Path
                $count = 0
                if ($exists) {
                    try { $count = @((Get-Item -LiteralPath $d.Path -ErrorAction Stop).Property).Count } catch { }
                }
                Write-Log ("{0}: {1} ({2} values)" -f (Get-Text $d.Key), $(if ($exists) { 'found' } else { 'empty' }), $count) 'INFO'
            }
        })
    # The scan button must actually be added to the content panel
    $script:pnlContent.Controls.Add($btnScan)

    $btnBackup = New-Object System.Windows.Forms.Button
    $btnBackup.Text = "{icon:save} $(Get-Text 'Export')"
    $btnBackup.Location = New-Object System.Drawing.Point(315, 265)
    $btnBackup.Size = New-Object System.Drawing.Size(270, 45)
    $btnBackup.BackColor = $script:Theme.Success
    $btnBackup.ForeColor = $script:Theme.TextWhite
    $btnBackup.FlatStyle = 'Flat'
    $btnBackup.FlatAppearance.BorderSize = 0
    $btnBackup.Font = (Get-AppFont -Size 10 -Style 'Bold')
    $btnBackup.Cursor = 'Hand'
    $btnBackup.Add_Click({ New-Backup -Type Registry | Out-Null })
    $script:pnlContent.Controls.Add($btnBackup)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "{icon:warning} $(Get-Text 'DlgWarning'): $(Get-Text 'DlgRisk')"
    $lbl.ForeColor = $script:Theme.Warning
    $lbl.Font = (Get-AppFont -Size 10)
    $lbl.Location = New-Object System.Drawing.Point(25, 330)
    $lbl.Size = New-Object System.Drawing.Size(1120, 60)
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    $script:pnlContent.Controls.Add($lbl)
}

# ---------------------------------------------------------------- BENCHMARK --
# --- Messwerkzeug -------------------------------------------------------------
# Eine Messung, die nicht wiederholt und nicht eingeordnet wird, ist eine Zahl
# ohne Aussage. Diese Helfer liefern Median, Streuung und den Vergleich mit dem
# letzten Lauf - erst damit laesst sich erkennen, ob eine Optimierung half.
$script:BenchRunning = $false

function Get-BenchMedian {
    param($Values)
    $v = @()
    foreach ($x in @($Values)) { if ($null -ne $x) { $v += [double]$x } }
    if ($v.Count -eq 0) { return 0.0 }
    $s = @($v | Sort-Object)
    $m = [int][math]::Floor($s.Count / 2)
    if ($s.Count % 2 -eq 1) { return [double]$s[$m] }
    return (([double]$s[$m - 1] + [double]$s[$m]) / 2.0)
}

function Get-BenchSpread {
    # Abstand zwischen bestem und schlechtestem Durchlauf, bezogen auf den
    # Median. Ueber 25 Prozent ist der Rechner waehrend der Messung zu
    # beschaeftigt gewesen - dann sagt der Wert wenig aus.
    param($Values)
    $v = @()
    foreach ($x in @($Values)) { if ($null -ne $x) { $v += [double]$x } }
    if ($v.Count -lt 2) { return 0 }
    $med = Get-BenchMedian -Values $v
    if ($med -le 0) { return 0 }
    $min = ($v | Measure-Object -Minimum).Minimum
    $max = ($v | Measure-Object -Maximum).Maximum
    return [int][math]::Round(((($max - $min) / $med) * 100), 0)
}

function Format-BenchRate {
    param([double]$Value, [string]$Unit = '')
    $txt = [string]::Format([System.Globalization.CultureInfo]::CurrentCulture, '{0:N0}', [math]::Round($Value, 0))
    if ($Unit) { return "$txt $Unit" }
    return $txt
}

function Get-BenchDelta {
    # Unter fuenf Prozent Unterschied ist Messrauschen und keine Verbesserung.
    param([double]$Old = 0, [double]$New = 0)
    if ($Old -le 0 -or $New -le 0) { return @{ Percent = 0; Level = 'INFO'; Key = ''; Text = '' } }
    $p = [int][math]::Round(((($New - $Old) / $Old) * 100), 0)
    if ($p -ge 5) { return @{ Percent = $p; Level = 'SUCCESS'; Key = 'BenchBetter'; Text = "+$p %" } }
    if ($p -le -5) { return @{ Percent = $p; Level = 'WARNING'; Key = 'BenchWorse'; Text = "$p %" } }
    return @{ Percent = $p; Level = 'INFO'; Key = 'BenchSame'; Text = "$p %" }
}

function Test-BenchDiskSpace {
    # Der Test schreibt eine echte Datei - ohne Platz dafuer bricht er
    # mitten im Lauf ab und laesst die halbe Datei liegen.
    param([string]$Path, [int]$NeedMB = 64)
    try {
        $root = [System.IO.Path]::GetPathRoot($Path)
        if (-not $root) { return $false }
        $d = New-Object System.IO.DriveInfo($root)
        return ($d.AvailableFreeSpace -gt ([long]$NeedMB * 1MB * 2))
    }
    catch { return $false }
}

function Get-BenchFilePath {
    # Gemessen wird das Systemlaufwerk. TEMP kann auf einer ganz anderen
    # Platte liegen - dann misst man etwas, das niemand gemeint hat.
    # Join-Path schlaegt die PowerShell-Laufwerke nach und wirft, wenn es das
    # Laufwerk nicht gibt - hier wird deshalb nur mit Zeichenketten gearbeitet.
    $root = [string]$env:SystemDrive
    if (-not $root) { $root = 'C:' }
    $dir = ''
    foreach ($cand in @([System.IO.Path]::Combine("$root\", 'Windows\Temp'), [string]$env:TEMP, "$root\")) {
        if ($cand -and (Test-Path -LiteralPath $cand)) { $dir = $cand; break }
    }
    if (-not $dir) { $dir = [System.IO.Path]::GetTempPath() }
    return [System.IO.Path]::Combine($dir, 'EB_Optimizer_bench.tmp')
}

function Invoke-CpuBench {
    # Erster Durchlauf wird verworfen: er enthaelt das Kompilieren der
    # Schleife und faellt dadurch regelmaessig um ein Drittel schlechter aus.
    param([int]$Rounds = 5, [int]$Iterations = 400000)
    $rates = @()
    for ($r = 0; $r -le $Rounds; $r++) {
        if (Test-BusyCancelled) { break }
        Update-BusyOverlay -Status ("{0} {1}/{2}" -f (Get-Text 'BenchCPU'), [math]::Max($r, 1), $Rounds) `
            -Percent ([int](($r / [double]($Rounds + 1)) * 100))
        $acc = 0.0
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        for ($i = 1; $i -le $Iterations; $i++) { $acc += [math]::Sqrt($i) }
        $sw.Stop()
        [System.Windows.Forms.Application]::DoEvents()
        if ($acc -le 0) { continue }
        if ($r -eq 0) { continue }
        $sec = [math]::Max($sw.Elapsed.TotalSeconds, 0.000001)
        $rates += (($Iterations / $sec) / 1000.0)
    }
    return @{
        Value  = (Get-BenchMedian -Values $rates)
        Spread = (Get-BenchSpread -Values $rates)
        Runs   = @($rates).Count
        Unit   = 'kOps/s'
    }
}

function Invoke-RamBench {
    # Gemessen wird nur das Kopieren. Frueher lagen Belegen und erstes
    # Beschreiben der Puffer mit in der Zeit - das halbierte den Wert.
    param([int]$Rounds = 5, [int]$SizeMB = 32)
    $bytes = [long]$SizeMB * 1MB
    $src = New-Object byte[] $bytes
    $dst = New-Object byte[] $bytes
    try {
        # Seiten vorher anfassen, sonst misst der erste Lauf Seitenfehler.
        for ($i = 0; $i -lt $src.Length; $i += 4096) { $src[$i] = 1; $dst[$i] = 2 }
        $rates = @()
        for ($r = 0; $r -lt $Rounds; $r++) {
            if (Test-BusyCancelled) { break }
            Update-BusyOverlay -Status ("{0} {1}/{2}" -f (Get-Text 'BenchRAM'), ($r + 1), $Rounds) `
                -Percent ([int](($r / [double]$Rounds) * 100))
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            [System.Array]::Copy($src, $dst, $bytes)
            $sw.Stop()
            [System.Windows.Forms.Application]::DoEvents()
            $sec = [math]::Max($sw.Elapsed.TotalSeconds, 0.000001)
            # Kopieren bewegt die Daten zweimal: einmal gelesen, einmal geschrieben.
            $rates += ((($SizeMB * 2) / $sec))
        }
        return @{
            Value  = (Get-BenchMedian -Values $rates)
            Spread = (Get-BenchSpread -Values $rates)
            Runs   = @($rates).Count
            Unit   = 'MB/s'
        }
    }
    finally {
        $src = $null
        $dst = $null
        [System.GC]::Collect()
    }
}

function Invoke-DiskBench {
    # FILE_FLAG_NO_BUFFERING (0x20000000) umgeht den Dateisystem-Cache.
    # Ohne ihn las der Test die eben geschriebenen Daten aus dem
    # Arbeitsspeicher zurueck und meldete auf jeder Platte Gigabytewerte.
    param([int]$SizeMB = 64)
    $file = Get-BenchFilePath
    $res = @{ Write = 0.0; Read = 0.0; Cached = $false; Path = $file; Unit = 'MB/s'; Space = $true }
    if (-not (Test-BenchDiskSpace -Path $file -NeedMB $SizeMB)) {
        $res.Space = $false
        return $res
    }
    $chunk = 1MB
    $buf = New-Object byte[] $chunk
    (New-Object Random).NextBytes($buf)
    $noBuf = 0x20000000
    try {
        foreach ($pass in @('nobuffer', 'buffered')) {
            $opts = if ($pass -eq 'nobuffer') {
                [System.IO.FileOptions]($noBuf -bor [int][System.IO.FileOptions]::WriteThrough)
            }
            else { [System.IO.FileOptions]::WriteThrough }
            try {
                Update-BusyOverlay -Status (Get-Text 'BenchWrite') -Percent 30
                $fs = New-Object System.IO.FileStream($file, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, $chunk, $opts)
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                for ($i = 0; $i -lt $SizeMB; $i++) { $fs.Write($buf, 0, $chunk) }
                $fs.Flush($true)
                $fs.Dispose()
                $sw.Stop()
                $res.Write = $SizeMB / [math]::Max($sw.Elapsed.TotalSeconds, 0.000001)

                Update-BusyOverlay -Status (Get-Text 'BenchRead') -Percent 70
                $ropts = if ($pass -eq 'nobuffer') { [System.IO.FileOptions]$noBuf } else { [System.IO.FileOptions]::SequentialScan }
                $fr = New-Object System.IO.FileStream($file, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None, $chunk, $ropts)
                $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
                while ($fr.Read($buf, 0, $chunk) -gt 0) { }
                $fr.Dispose()
                $sw2.Stop()
                $res.Read = $SizeMB / [math]::Max($sw2.Elapsed.TotalSeconds, 0.000001)
                $res.Cached = ($pass -ne 'nobuffer')
                break
            }
            catch {
                # Manche Dateisysteme und Netzlaufwerke lehnen den Flag ab -
                # dann wird gepuffert gemessen und das auch so gesagt.
                $res.Cached = $true
            }
        }
    }
    finally {
        try { if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue } } catch { }
    }
    return $res
}

function Get-LastBenchResult {
    if (-not $script:Config.LastBench) { return $null }
    return $script:Config.LastBench
}

function Save-BenchResult {
    param($Result)
    if (-not $Result) { return }
    $script:Config.LastBench = [pscustomobject]@{
        Cpu   = [double]$Result.Cpu
        Ram   = [double]$Result.Ram
        Write = [double]$Result.Write
        Read  = [double]$Result.Read
        Time  = (Get-Date -Format 'yyyy-MM-dd HH:mm')
    }
    [void](Export-AppSettings)
}

function Write-BenchMetric {
    # Eine Zeile je Messwert: Zahl, Streuung und der Vergleich mit dem
    # letzten gespeicherten Lauf.
    param([string]$Label, [double]$Value, [string]$Unit, [int]$Spread = 0, [double]$Previous = 0, [System.Drawing.Color]$Color)
    $line = "{0,-22} {1,14}" -f $Label, (Format-BenchRate -Value $Value -Unit $Unit)
    if ($Spread -gt 0) { $line = "$line   {0} {1} %" -f (Get-Text 'BenchSpread'), $Spread }
    Write-BenchLine $line $Color
    if ($Previous -gt 0) {
        $d = Get-BenchDelta -Old $Previous -New $Value
        $c = switch ($d.Level) {
            'SUCCESS' { $script:Theme.Success }
            'WARNING' { $script:Theme.Error }
            default { $script:Theme.TextMuted }
        }
        Write-BenchLine ("{0,-22} {1,14}   {2}" -f '', $d.Text, (Get-Text $d.Key)) $c
    }
}

function Show-Benchmark {
    Add-ViewHeader -TitleKey 'BenchTitle' -SubtitleKey 'BenchSubtitle' -Icon 'chart'

    $txt = New-Object System.Windows.Forms.RichTextBox
    $txt.Location = New-Object System.Drawing.Point(25, 175)
    $txt.Size = New-Object System.Drawing.Size(1120, 440)
    $txt.BackColor = $script:Theme.BgSecondary
    $txt.ForeColor = $script:Theme.TextPrimary
    $txt.ReadOnly = $true
    $txt.BorderStyle = 'None'
    $txt.Anchor = 'Top,Bottom,Left,Right'
    $txt.Font = (Get-AppFont -Family $script:MonoFont -Size 10)
    $script:pnlContent.Controls.Add($txt)
    $script:txtBench = $txt

    $defs = @(
        @{ Key = 'BenchCPU'; Icon = 'cpu'; Color = $script:Theme.Cyan; Mode = 'CPU' },
        @{ Key = 'BenchRAM'; Icon = 'cpu'; Color = $script:Theme.Purple; Mode = 'RAM' },
        @{ Key = 'BenchDisk'; Icon = 'save'; Color = $script:Theme.Warning; Mode = 'DISK' },
        @{ Key = 'Start'; Icon = 'rocket'; Color = $script:Theme.Success; Mode = 'ALL' }
    )

    $x = 25
    foreach ($d in $defs) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = "{icon:$($d.Icon)} $(Get-Text $d.Key)"
        $b.Location = New-Object System.Drawing.Point($x, 100)
        $b.Size = New-Object System.Drawing.Size(270, 50)
        $b.BackColor = $d.Color
        $b.ForeColor = $script:Theme.TextWhite
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderSize = 0
        $b.Font = (Get-AppFont -Size 10 -Style 'Bold')
        $b.Cursor = 'Hand'
        $b.Tag = $d.Mode
        $b.Add_Click({ Invoke-Benchmark -Mode $this.Tag })
        $script:pnlContent.Controls.Add($b)
        $x += 290
    }
}

function Write-BenchLine {
    param([string]$Text, [System.Drawing.Color]$Color)
    if (-not $script:txtBench -or $script:txtBench.IsDisposed) { return }
    if (-not $Color.IsEmpty) { $script:txtBench.SelectionColor = $Color }
    $script:txtBench.AppendText("  $Text`n")
    $script:txtBench.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Invoke-Benchmark {
    param([ValidateSet('CPU', 'RAM', 'DISK', 'ALL')][string]$Mode = 'ALL')

    if (-not $script:txtBench -or $script:txtBench.IsDisposed) { return }
    # Write-BenchLine pumpt die Nachrichtenschlange - ohne Sperre liessen sich
    # waehrend eines Laufs weitere Messungen starten, die sich gegenseitig
    # verfaelschen.
    if ($script:BenchRunning) { Write-Log (Get-Text 'BenchRunning') 'WARNING'; return }
    $script:BenchRunning = $true

    $script:txtBench.Clear()
    Write-BenchLine "$(Get-Text 'BenchTitle') - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" $script:Theme.Accent
    Write-BenchLine ('=' * 64) $script:Theme.TextMuted

    $load = 0.0
    try { $load = [double]$script:CurrentStats.CPU } catch { }
    if ($load -gt 40) {
        Write-BenchLine ("{0} ({1} %)" -f (Get-Text 'BenchBusyWarn'), [int]$load) $script:Theme.Warning
    }
    $last = Get-LastBenchResult
    if ($last) {
        Write-BenchLine ("{0}: {1}" -f (Get-Text 'BenchLast'), $last.Time) $script:Theme.TextMuted
    }
    Write-BenchLine '' $script:Theme.TextMuted

    $res = @{ Cpu = 0.0; Ram = 0.0; Write = 0.0; Read = 0.0 }
    $saved = $script:MainForm.Cursor
    $script:MainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    Show-BusyOverlay -Title (Get-Text 'BenchTitle') -Status (Get-Text 'BenchWarmup') -Cancellable
    try {
        if ($Mode -in @('CPU', 'ALL') -and -not (Test-BusyCancelled)) {
            $c = Invoke-CpuBench
            $res.Cpu = [double]$c.Value
            Write-BenchMetric -Label ("{0} ({1})" -f (Get-Text 'BenchCPU'), (Get-Text 'BenchSingle')) `
                -Value $c.Value -Unit $c.Unit -Spread $c.Spread `
                -Previous $(if ($last) { [double]$last.Cpu } else { 0 }) -Color $script:Theme.Cyan
            if ($c.Spread -gt 25) { Write-BenchLine (Get-Text 'BenchUnstable') $script:Theme.Warning }
        }

        if ($Mode -in @('RAM', 'ALL') -and -not (Test-BusyCancelled)) {
            $m = Invoke-RamBench
            $res.Ram = [double]$m.Value
            Write-BenchMetric -Label (Get-Text 'BenchRAM') -Value $m.Value -Unit $m.Unit -Spread $m.Spread `
                -Previous $(if ($last) { [double]$last.Ram } else { 0 }) -Color $script:Theme.Purple
            if ($m.Spread -gt 25) { Write-BenchLine (Get-Text 'BenchUnstable') $script:Theme.Warning }
        }

        if ($Mode -in @('DISK', 'ALL') -and -not (Test-BusyCancelled)) {
            $d = Invoke-DiskBench
            if (-not $d.Space) {
                Write-BenchLine (Get-Text 'BenchNoSpace') $script:Theme.Error
            }
            else {
                $res.Write = [double]$d.Write
                $res.Read = [double]$d.Read
                Write-BenchLine ("{0}: {1}" -f (Get-Text 'BenchDrive'), $d.Path) $script:Theme.TextMuted
                Write-BenchMetric -Label (Get-Text 'BenchWrite') -Value $d.Write -Unit $d.Unit `
                    -Previous $(if ($last) { [double]$last.Write } else { 0 }) -Color $script:Theme.Warning
                Write-BenchMetric -Label (Get-Text 'BenchRead') -Value $d.Read -Unit $d.Unit `
                    -Previous $(if ($last) { [double]$last.Read } else { 0 }) -Color $script:Theme.Warning
                $hint = if ($d.Cached) { Get-Text 'BenchCached' } else { Get-Text 'BenchUnbuffered' }
                Write-BenchLine $hint $(if ($d.Cached) { $script:Theme.Warning } else { $script:Theme.TextMuted })
            }
        }

        Write-BenchLine ('=' * 64) $script:Theme.TextMuted
        if (Test-BusyCancelled) {
            Write-BenchLine (Get-Text 'BusyCancelled') $script:Theme.Warning
            Write-Log "$(Get-Text 'BenchTitle'): $(Get-Text 'BusyCancelled')" 'WARNING'
        }
        else {
            # Nicht gemessene Werte behalten ihren alten Stand, sonst stuende
            # beim naechsten Vergleich eine Null in der Spalte.
            if ($last) {
                foreach ($k in @('Cpu', 'Ram', 'Write', 'Read')) {
                    if ($res[$k] -le 0) { $res[$k] = [double]$last.$k }
                }
            }
            Save-BenchResult -Result $res
            Write-BenchLine "$(Get-Text 'DlgCompleted')" $script:Theme.Success
            Write-Log "$(Get-Text 'BenchTitle'): $(Get-Text 'DlgCompleted')" 'SUCCESS'
        }
    }
    catch {
        Write-BenchLine "$(Get-Text 'Error'): $($_.Exception.Message)" $script:Theme.Error
        Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR'
    }
    finally {
        Hide-BusyOverlay
        $script:MainForm.Cursor = $saved
        $script:BenchRunning = $false
    }
}

# ------------------------------------------------------------------- TWEAKS --
function Get-TweakDefinitions {
    # Die Liste stand frueher mitten im Aufbau der Ansicht und war damit weder
    # pruefbar noch umkehrbar. Jeder Eintrag beschreibt jetzt zusaetzlich,
    # WAS er kostet (DescKey) und WIE er zurueckgenommen wird (Revert).
    return @(
        @{ Key = 'TweakAnimations'; DescKey = 'TwkDescAnimations'; Icon = 'bulb'; ColorName = 'Cyan'
            Entries = @(
                @{ Path = 'HKCU:\Control Panel\Desktop\WindowMetrics'; Name = 'MinAnimate'; Value = '0'; Type = 'String' },
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'; Name = 'VisualFXSetting'; Value = 2 })
            Revert = @(
                @{ Path = 'HKCU:\Control Panel\Desktop\WindowMetrics'; Name = 'MinAnimate'; Value = '1'; Type = 'String' },
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'; Name = 'VisualFXSetting'; Value = 0 })
        },
        @{ Key = 'TweakTransparency'; DescKey = 'TwkDescTransparency'; Icon = 'window'; ColorName = 'Purple'
            Entries = @(@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name = 'EnableTransparency'; Value = 0 })
            Revert = @(@{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name = 'EnableTransparency'; Value = 1 })
        },
        @{ Key = 'TweakSysMain'; DescKey = 'TwkDescSysMain'; Icon = 'puzzle'; ColorName = 'Warning'
            Service = 'SysMain'; ServiceDefault = 'Automatic'
        },
        @{ Key = 'TweakSearchIdx'; DescKey = 'TwkDescSearchIdx'; Icon = 'search'; ColorName = 'Accent'
            Service = 'WSearch'; ServiceDefault = 'Automatic'
        },
        @{ Key = 'TweakFastStart'; DescKey = 'TwkDescFastStart'; Icon = 'bolt'; ColorName = 'Success'
            Entries = @(@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name = 'HiberbootEnabled'; Value = 0 })
            Revert = @(@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name = 'HiberbootEnabled'; Value = 1 })
        },
        @{ Key = 'TweakThrottling'; DescKey = 'TwkDescThrottling'; Icon = 'clock'; ColorName = 'Error'
            Entries = @(@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name = 'PowerThrottlingOff'; Value = 1 })
            Revert = @(@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name = 'PowerThrottlingOff'; Value = 0 })
        },
        @{ Key = 'TweakPriority'; DescKey = 'TwkDescPriority'; Icon = 'slider'; ColorName = 'Cyan'
            Entries = @(@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name = 'Win32PrioritySeparation'; Value = 38 })
            Revert = @(@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name = 'Win32PrioritySeparation'; Value = 2 })
        },
        @{ Key = 'TweakBgApps'; DescKey = 'TwkDescBgApps'; Icon = 'ban'; ColorName = 'Purple'
            Entries = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Name = 'GlobalUserDisabled'; Value = 1 },
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'; Name = 'LetAppsRunInBackground'; Value = 2 })
            Revert = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Name = 'GlobalUserDisabled'; Value = 0 },
                @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'; Name = 'LetAppsRunInBackground'; Value = 0 })
        },
        @{ Key = 'TweakTips'; DescKey = 'TwkDescTips'; Icon = 'bulb'; ColorName = 'Warning'
            Entries = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338389Enabled'; Value = 0 },
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SoftLandingEnabled'; Value = 0 })
            Revert = @(
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338389Enabled'; Value = 1 },
                @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SoftLandingEnabled'; Value = 1 })
        },
        @{ Key = 'TweakHibernate'; DescKey = 'TwkDescHibernate'; Icon = 'moon'; ColorName = 'Error'
            Command = @{ File = 'powercfg.exe'; Args = @('/hibernate off') }
            RevertCommand = @{ File = 'powercfg.exe'; Args = @('/hibernate on') }
            Check = @(@{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power'; Name = 'HibernateEnabled'; Value = 0 })
        },
        @{ Key = 'TweakParking'; DescKey = 'TwkDescParking'; Icon = 'pause'; ColorName = 'Success'
            # Ohne /setactive bleibt der geschriebene Wert folgenlos - die alte
            # Fassung meldete Erfolg, geaendert hat sich nichts. Netzbetrieb und
            # Akku muessen beide gesetzt werden.
            Command = @{ File = 'powercfg.exe'; Args = @(
                    '/setacvalueindex scheme_current sub_processor CPMINCORES 100',
                    '/setdcvalueindex scheme_current sub_processor CPMINCORES 100',
                    '/setactive scheme_current') }
            RevertCommand = @{ File = 'powercfg.exe'; Args = @(
                    '/setacvalueindex scheme_current sub_processor CPMINCORES 0',
                    '/setdcvalueindex scheme_current sub_processor CPMINCORES 0',
                    '/setactive scheme_current') }
            Parking = $true
        },
        @{ Key = 'TweakDebloat'; DescKey = 'TwkDescDebloat'; Icon = 'broom'; ColorName = 'Accent'; Debloat = $true }
    )
}

function Get-CoreParkingPercent {
    # Liest aus der powercfg-Ausgabe den aktuellen Wert fuer CPMINCORES.
    # powercfg schreibt ihn hexadezimal, die Zeilenbeschriftung ist
    # sprachabhaengig - deshalb wird nur auf den Index geschaut.
    param([string]$Text, [string]$Scope = 'AC')
    if ([string]::IsNullOrWhiteSpace($Text)) { return -1 }
    # Auf Deutsch heisst die Zeile 'Wechselstrom'/'Gleichstrom', auf Tuerkisch
    # wieder anders - nach 'AC' zu suchen findet auf den meisten Rechnern
    # nichts. Verlaesslich ist die Reihenfolge: powercfg gibt erst die
    # moeglichen Werte aus, zuletzt immer Netzbetrieb und dann Akku.
    $vals = New-Object System.Collections.Generic.List[int]
    foreach ($line in ($Text -split "`r?`n")) {
        $m = [regex]::Match($line, '(?i):\s*0x([0-9a-f]+)\s*$')
        if (-not $m.Success) { continue }
        try { $vals.Add([convert]::ToInt32($m.Groups[1].Value, 16)) } catch { }
    }
    if ($vals.Count -lt 2) { return -1 }
    if ($Scope -eq 'DC') { return $vals[$vals.Count - 1] }
    return $vals[$vals.Count - 2]
}

function Get-TweakPlan {
    # Eine Karte, zwei Richtungen. Frueher war jeder Knopf eine Einbahnstrasse:
    # angewandt blieb angewandt, auch wenn der Tweak stoerte.
    param(
        [string]$State = 'na',
        [bool]$HasRevert = $false,
        [bool]$IsDebloat = $false
    )
    if ($IsDebloat) { return @{ Mode = 'apply'; Ask = $true; ReasonKey = '' } }
    if ($State -eq 'on') {
        if (-not $HasRevert) { return @{ Mode = 'none'; Ask = $false; ReasonKey = 'TwkNoRevert' } }
        return @{ Mode = 'revert'; Ask = $true; ReasonKey = '' }
    }
    # 'off', 'part' und 'na' werden angewandt - bei 'part' fehlt genau das,
    # was jetzt nachgezogen wird.
    return @{ Mode = 'apply'; Ask = $false; ReasonKey = '' }
}

function Invoke-TweakCommandSet {
    # powercfg gibt pro Aufruf einen Rueckgabewert - der wurde nie angesehen.
    param($Command, [string]$Label)
    $cmdArgs = @($Command.Args)
    $ok = 0
    $failed = @()
    foreach ($a in $cmdArgs) {
        $code = -1
        try { $code = Invoke-SystemCommand -File $Command.File -Arguments $a -TimeoutSec 120 -Label $Label }
        catch { $code = -1 }
        if ($code -eq 0) { $ok++ } else { $failed += ([string]$a).Split(' ')[0] }
    }
    return @{ Ok = $ok; Total = @($cmdArgs).Count; Failed = $failed }
}

function Set-TweakService {
    # Derselbe Weg wie in der Dienste-Ansicht: nachlesen statt annehmen und
    # ins Journal eintragen. Vorher liess sich ein hier abgeschalteter Dienst
    # ueber die Aenderungsliste nicht zurueckholen.
    #
    # Anhalten und Starten laufen im Hintergrund: Stop-Service kehrt erst
    # zurueck, wenn der Dienst wirklich steht - WSearch braucht dafuer gern
    # eine halbe Minute, und genau so lange stand die Oberflaeche still.
    param([string]$Name, [string]$Target, [string]$Label)
    $before = Get-ServiceStartupType -Name $Name
    if ([string]$before -eq [string]$Target) {
        Write-Log "$Label ($Name): $(Get-Text 'SvcNoChange')" 'INFO'
        return $true
    }
    $script = if ($Target -eq 'Disabled') {
        "Stop-Service -Name '$Name' -Force -ErrorAction SilentlyContinue; " +
        "Set-Service -Name '$Name' -StartupType Disabled -ErrorAction Stop"
    }
    else {
        "Set-Service -Name '$Name' -StartupType $Target -ErrorAction Stop; " +
        "Start-Service -Name '$Name' -ErrorAction SilentlyContinue"
    }
    $bg = Invoke-Background -Script $script -TimeoutSec 90 -Status "$Label ($Name)"
    $vd = Get-BackgroundOutcome -Result $bg
    if (-not $vd.Ok) {
        $why = if ($vd.ReasonKey) { Get-Text $vd.ReasonKey } else { [string]$bg.Error }
        Write-Log "$Label ($Name): $why" $vd.Level
        return $false
    }
    $after = Get-ServiceStartupType -Name $Name
    if ([string]$after -ne [string]$Target) {
        Write-Log "$Label ($Name): $(Get-Text 'SvcVerifyErr') ($after)" 'ERROR'
        return $false
    }
    [void](Add-ChangeEntry -Action 'service' -Path 'Service' -Name $Name -Type 'StartupType' `
            -OldValue $before -NewValue $Target -Existed $true -Label $Label)
    return $true
}
function Invoke-TweakCard {
    # Ein Weg fuer alle Karten: Zustand lesen, Richtung bestimmen, bei
    # Rueckname fragen, ausfuehren, nachlesen, ehrlich berichten.
    param($Def)
    $label = Get-Text $Def.Key
    $state = Get-TweakCardState -Def $Def
    $hasRevert = [bool]($Def.ContainsKey('Revert') -or $Def.ContainsKey('RevertCommand') -or $Def.ContainsKey('Service'))
    $plan = Get-TweakPlan -State $state -HasRevert $hasRevert -IsDebloat ([bool]$Def.ContainsKey('Debloat'))

    if ($plan.Mode -eq 'none') {
        Write-Log "$label : $(Get-Text $plan.ReasonKey)" 'INFO'
        return
    }
    # Erst fragen, dann die Warteflaeche zeigen - eine Rueckfrage hinter
    # einer Warteflaeche sieht aus, als haenge das Programm.
    if ($plan.Mode -eq 'revert' -and -not (Show-Confirm -Message "$label`n`n$(Get-Text 'TwkAskRevert')")) { return }
    if ($Def.ContainsKey('Debloat')) { Invoke-Debloat; return }

    # Alles Weitere kann dauern (Dienste anhalten, powercfg). Nur mit
    # sichtbarer Warteflaeche darf die Nachrichtenschleife bedient werden.
    Show-BusyOverlay -Title $label -Cancellable
    try { Invoke-TweakCardCore -Def $Def -Plan $plan -Label $label }
    finally { Hide-BusyOverlay }
}

function Invoke-TweakCardCore {
    param($Def, $Plan, [string]$Label)
    $label = $Label
    $plan = $Plan

    if ($Def.ContainsKey('Service')) {
        $target = if ($plan.Mode -eq 'revert') { [string]$Def.ServiceDefault } else { 'Disabled' }
        if (Set-TweakService -Name $Def.Service -Target $target -Label $label) {
            $key = if ($plan.Mode -eq 'revert') { 'TwkRevertOk' } else { 'TwkAllOk' }
            Write-Log "$label : $(Get-Text $key)" 'SUCCESS'
        }
        return
    }

    if ($Def.ContainsKey('Entries')) {
        $entries = if ($plan.Mode -eq 'revert') { @($Def.Revert) } else { @($Def.Entries) }
        [void](Set-PrivacyTweak -Entries $entries -Label $label)
        if ($plan.Mode -eq 'revert') { Write-Log "$label : $(Get-Text 'TwkRevertOk')" 'INFO' }
        return
    }

    if ($Def.ContainsKey('Command')) {
        $cmd = if ($plan.Mode -eq 'revert') { $Def.RevertCommand } else { $Def.Command }
        $res = Invoke-TweakCommandSet -Command $cmd -Label $label
        # Der gemerkte Stand ist jetzt veraltet - sonst zeigt das Abzeichen
        # bis zu einer Minute lang den alten Wert.
        Clear-DataCache -Key 'CoreParking'
        Write-TweakOutcome -Label $label -Ok $res.Ok -Total $res.Total -Failed $res.Failed
        # Nachlesen: der Rueckgabewert 0 heisst bei powercfg nur, dass der
        # Aufruf verstanden wurde - nicht, dass der Wert jetzt gilt.
        if ($res.Ok -ge $res.Total) {
            $now = Get-TweakCardState -Def $Def
            $want = if ($plan.Mode -eq 'revert') { 'off' } else { 'on' }
            if ($now -ne 'na' -and $now -ne $want) { Write-Log "$label : $(Get-Text 'SvcVerifyErr')" 'WARNING' }
            elseif ($plan.Mode -eq 'revert') { Write-Log "$label : $(Get-Text 'TwkRevertOk')" 'INFO' }
        }
    }
}

function Get-TweakCardState {
    param($Def)
    if ($Def.ContainsKey('Parking')) {
        try {
            # Fuer den Zustand dieser einen Karte muss ein Prozess gestartet
            # werden. Das gehoert nicht in den Oberflaechenstrang: die Abfrage
            # laeuft im Hintergrund, die Karte bleibt bis dahin ohne Abzeichen
            # und wird nachtraeglich gefuellt.
            if (-not (Request-CachedData -Key 'CoreParking' -TtlSeconds 60 -OnReady { Update-CardStates } -Loader {
                        , ((powercfg.exe /q scheme_current sub_processor CPMINCORES 2>$null) | Out-String)
                    })) {
                return 'na'
            }
            $out = @(Get-CacheEntryData -Key 'CoreParking')[0]
            $v = Get-CoreParkingPercent -Text $out -Scope 'AC'
            if ($v -lt 0) { return 'na' }
            if ($v -ge 100) { return 'on' }
            return 'off'
        }
        catch { return 'na' }
    }
    if ($Def.ContainsKey('Check')) { return (Test-TweakApplied -Entries $Def.Check) }
    if ($Def.ContainsKey('Entries')) { return (Test-TweakApplied -Entries $Def.Entries) }
    if ($Def.ContainsKey('Service')) { return (Test-TweakApplied -Service $Def.Service) }
    return 'na'
}

function Show-Tweaks {
    Add-ViewHeader -TitleKey 'MenuTweaks' -SubtitleKey 'TweaksSubtitle' -Icon 'wrench'

    # Breite der Inhaltsflaeche statt fester vier Spalten - bei schmalem
    # Fenster standen die Karten sonst halb ausserhalb.
    $avail = 1150
    try {
        if ($script:pnlContent -and $script:pnlContent.ClientSize.Width -gt 400) {
            $avail = $script:pnlContent.ClientSize.Width - 50
        }
    }
    catch { }
    $perRow = [math]::Max(1, [int][math]::Floor(($avail + 20) / 290))

    $x = 25; $y = 95; $col = 0
    foreach ($d in (Get-TweakDefinitions)) {
        $item = $d          # eigene Kopie je Durchlauf fuer die Closure
        $check = { Get-TweakCardState -Def $item }.GetNewClosure()
        $action = { Invoke-TweakCard -Def $item }.GetNewClosure()
        $color = $script:Theme.($d.ColorName)
        if (-not $color) { $color = $script:Theme.Accent }

        Add-Card -TitleKey $d.Key -DescKey $d.DescKey -BtnKey 'Apply' -Icon $d.Icon `
            -Action $action -X $x -Y $y -Color $color -StateCheck $check | Out-Null

        $col++
        if ($col -ge $perRow) { $col = 0; $x = 25; $y += 170 } else { $x += 290 }
    }
}

function Invoke-Debloat {
    if (-not (Show-Confirm -Message (Get-Text 'DlgRisk'))) { return }
    Write-Log "=== $(Get-Text 'TweakDebloat') ===" 'TITLE'

    $apps = @(
        'Microsoft.3DBuilder', 'Microsoft.BingWeather', 'Microsoft.GetHelp',
        'Microsoft.Getstarted', 'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MixedReality.Portal', 'Microsoft.People',
        'Microsoft.SkypeApp', 'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps', 'Microsoft.ZuneVideo', 'Microsoft.XboxApp'
    )

    if (-not (Get-Command Get-AppxPackage -ErrorAction SilentlyContinue)) {
        Write-Log (Get-Text 'LogAppxMissing') 'WARNING'
        return
    }

    $removed = 0
    Show-BusyOverlay -Title (Get-Text 'TweakDebloat') -Cancellable
    try {
        $i = 0
        foreach ($a in $apps) {
            $i++
            if (Test-BusyCancelled) {
                Write-Log (Get-Text 'BusyCancelled') 'WARNING'
                break
            }
            Update-BusyOverlay -Status "$i / $($apps.Count):  $a" `
                -Percent ([int](($i - 1) / [double]$apps.Count * 100))
            # Remove-AppxPackage blockiert je Paket mehrere Sekunden. Im
            # Oberflaechenstrang summierte sich das ueber zwoelf Pakete zu
            # einer halben Minute ohne Lebenszeichen.
            $bg = Invoke-Background -TimeoutSec 90 -Status $a -Script (
                "`$p = Get-AppxPackage -Name '$a' -ErrorAction SilentlyContinue; " +
                "if (`$p) { `$p | Remove-AppxPackage -ErrorAction Stop; 'weg' }")
            if ($bg.Cancelled) { Write-Log (Get-Text 'BusyCancelled') 'WARNING'; break }
            if ($bg.TimedOut) { Write-Log "$a : $(Get-Text 'BusyTooLong')" 'WARNING' }
            elseif ($bg.Error) { Write-Log "$a : $($bg.Error)" 'WARNING' }
            elseif (@($bg.Output) -contains 'weg') {
                Write-Log "$(Get-Text 'Delete'): $a" 'SUCCESS'
                $removed++
            }
            Update-BusyOverlay -Percent ([int]($i / [double]$apps.Count * 100))
        }
    }
    finally { Hide-BusyOverlay }
    Write-Log "$(Get-Text 'TweakDebloat'): $removed / $($apps.Count)" 'SUCCESS'
}

# -------------------------------------------------------------- INPUT TUNING --
function Show-InputTuning {
    Add-ViewHeader -TitleKey 'InputTitle' -SubtitleKey 'InputSubtitle' -Icon 'mouse'

    Add-Card -TitleKey 'GameMouseAccel' -DescKey 'GameMouseAccelDesc' -BtnKey 'Disable' -Icon 'mouse' -X 25 -Y 95 -Color $script:Theme.Cyan -Action {
        Set-PrivacyTweak -Label (Get-Text 'GameMouseAccel') -Entries @(
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseSpeed'; Value = '0'; Type = 'String' },
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold1'; Value = '0'; Type = 'String' },
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold2'; Value = '0'; Type = 'String' }
        ) | Out-Null
    } -StateCheck {
        Test-TweakApplied -Entries @(
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseSpeed'; Value = '0' },
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold1'; Value = '0' },
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold2'; Value = '0' }
        )
    } | Out-Null

    Add-Card -TitleKey 'FilterKeys' -DescKey 'FilterKeysDesc' -BtnKey 'Disable' -Icon 'keyboard' -X 315 -Y 95 -Color $script:Theme.Purple -Action {
        Set-PrivacyTweak -Label (Get-Text 'FilterKeys') -Entries @(
            @{ Path = 'HKCU:\Control Panel\Accessibility\StickyKeys'; Name = 'Flags'; Value = '506'; Type = 'String' },
            @{ Path = 'HKCU:\Control Panel\Accessibility\Keyboard Response'; Name = 'Flags'; Value = '122'; Type = 'String' },
            @{ Path = 'HKCU:\Control Panel\Accessibility\ToggleKeys'; Name = 'Flags'; Value = '58'; Type = 'String' }
        ) | Out-Null
    } -StateCheck {
        Test-TweakApplied -Entries @(
            @{ Path = 'HKCU:\Control Panel\Accessibility\StickyKeys'; Name = 'Flags'; Value = '506' },
            @{ Path = 'HKCU:\Control Panel\Accessibility\Keyboard Response'; Name = 'Flags'; Value = '122' },
            @{ Path = 'HKCU:\Control Panel\Accessibility\ToggleKeys'; Name = 'Flags'; Value = '58' }
        )
    } | Out-Null

    Add-Card -TitleKey 'TweakPriority' -DescKey 'InputSubtitle' -BtnKey 'Apply' -Icon 'slider' -X 605 -Y 95 -Color $script:Theme.Warning -Action {
        Set-PrivacyTweak -Label (Get-Text 'TweakPriority') -Entries @(
            @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'MenuShowDelay'; Value = '0'; Type = 'String' },
            @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'AutoEndTasks'; Value = '1'; Type = 'String' },
            @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'HungAppTimeout'; Value = '2000'; Type = 'String' }
        ) | Out-Null
    } -StateCheck {
        Test-TweakApplied -Entries @(
            @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'MenuShowDelay'; Value = '0' },
            @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'AutoEndTasks'; Value = '1' },
            @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'HungAppTimeout'; Value = '2000' }
        )
    } | Out-Null

    Add-Card -TitleKey 'Reset' -DescKey 'InputSubtitle' -BtnKey 'Reset' -Icon 'undo' -X 895 -Y 95 -Color $script:Theme.Error -Action {
        Set-PrivacyTweak -Label (Get-Text 'Reset') -Entries @(
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseSpeed'; Value = '1'; Type = 'String' },
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold1'; Value = '6'; Type = 'String' },
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold2'; Value = '10'; Type = 'String' }
        ) | Out-Null
    } -StateCheck {
        Test-TweakApplied -Entries @(
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseSpeed'; Value = '1' },
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold1'; Value = '6' },
            @{ Path = 'HKCU:\Control Panel\Mouse'; Name = 'MouseThreshold2'; Value = '10' }
        )
    } | Out-Null

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "{icon:help} $(Get-Text 'DlgRestartReq')"
    $lbl.ForeColor = $script:Theme.TextMuted
    $lbl.Font = (Get-AppFont -Size 10)
    $lbl.Location = New-Object System.Drawing.Point(25, 270)
    $lbl.Size = New-Object System.Drawing.Size(1120, 40)
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    $script:pnlContent.Controls.Add($lbl)
}

# ------------------------------------------------------------ REPAIR CENTER --
function Get-FileTail {
    # Liest nur das Ende einer Datei. CBS.log wird auf vielen Rechnern
    # dreistellig megabytegross - Get-Content laedt sie vollstaendig und haette
    # das Fenster sekundenlang blockiert. Ausserdem haelt TrustedInstaller die
    # Datei offen, deshalb ReadWrite-Freigabe.
    param(
        [Parameter(Mandatory)][string]$Path,
        [int]$Bytes = 262144
    )
    $out = @()
    $fs = $null
    $sr = $null
    try {
        if (-not (Test-Path -LiteralPath $Path)) { return $out }
        $fs = New-Object -TypeName 'System.IO.FileStream' -ArgumentList $Path,
        ([System.IO.FileMode]::Open), ([System.IO.FileAccess]::Read),
        ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete)
        if ($fs.Length -gt $Bytes) { [void]$fs.Seek(-([long]$Bytes), [System.IO.SeekOrigin]::End) }
        $sr = New-Object -TypeName 'System.IO.StreamReader' -ArgumentList $fs, ([System.Text.Encoding]::UTF8), $true
        $text = $sr.ReadToEnd()
        if ($text) { $out = @($text -split "`r?`n") }
        # Die erste Zeile ist nach dem Sprung mitten im Text abgeschnitten
        if ($out.Count -gt 1 -and $fs.Length -gt $Bytes) { $out = @($out[1..($out.Count - 1)]) }
    }
    catch { }
    finally {
        if ($sr) { try { $sr.Dispose() } catch { } }
        elseif ($fs) { try { $fs.Dispose() } catch { } }
    }
    return $out
}

function Get-RepairResult {
    # Macht aus dem Protokoll des Werkzeugs eine Klartext-Aussage. Der
    # Beendigungscode allein taugt dafuer nicht: sfc.exe liefert auch dann 0,
    # wenn es beschaedigte Dateien gefunden und NICHT reparieren konnte.
    param(
        [ValidateSet('SFC', 'DISM', 'CHKDSK')][string]$Kind,
        $ExitCode = $null,
        [string[]]$Lines = @()
    )
    $joined = ''
    if ($Lines -and $Lines.Count -gt 0) { $joined = ($Lines -join "`n") }

    switch ($Kind) {
        'SFC' {
            if (-not $joined) { return @{ Level = 'WARNING'; Key = 'RepNoLog' } }
            if ($joined -match '(?i)cannot repair member file|unable to (repair|fix)') {
                return @{ Level = 'ERROR'; Key = 'RepSfcBroken' }
            }
            if ($joined -match '(?i)repairing corrupted file|repaired file|successfully repaired') {
                return @{ Level = 'WARNING'; Key = 'RepSfcFixed' }
            }
            return @{ Level = 'SUCCESS'; Key = 'RepSfcClean' }
        }
        'DISM' {
            if ($null -ne $ExitCode -and [int]$ExitCode -eq 3010) {
                return @{ Level = 'SUCCESS'; Key = 'RepDismReboot' }
            }
            if ($joined -match '(?i)\berror:?\s*0x[0-9a-f]{8}') {
                $m = [regex]::Match($joined, '(?i)0x[0-9a-f]{8}')
                return @{ Level = 'ERROR'; Key = 'RepDismError'; Detail = $m.Value }
            }
            if ($null -ne $ExitCode -and [int]$ExitCode -ne 0) {
                return @{ Level = 'ERROR'; Key = 'RepDismError'; Detail = "$ExitCode" }
            }
            return @{ Level = 'SUCCESS'; Key = 'RepDismOk' }
        }
        default {
            # chkdsk: 0 sauber, 1 Fehler behoben, 2/3 Pruefung steht aus
            $c = if ($null -eq $ExitCode) { 0 } else { [int]$ExitCode }
            if ($c -eq 1) { return @{ Level = 'WARNING'; Key = 'RepChkFixed' } }
            if ($c -ge 2) { return @{ Level = 'WARNING'; Key = 'RepChkSched' } }
            if ($joined -match '(?i)will be checked the next time|beim naechsten|schedule') {
                return @{ Level = 'WARNING'; Key = 'RepChkSched' }
            }
            return @{ Level = 'SUCCESS'; Key = 'RepSfcClean' }
        }
    }
}

function Write-RepairResult {
    # Liest das passende Windows-Protokoll und schreibt das Ergebnis ins
    # Programmprotokoll - zusaetzlich zum bisherigen Beendigungscode.
    param([string]$Kind, $ExitCode = $null, [string]$Label = '')
    if (-not $Kind) { return }
    try {
        $lines = @()
        if ($Kind -eq 'SFC') {
            $cbs = Join-Path $env:SystemRoot 'Logs\CBS\CBS.log'
            $lines = @(Get-FileTail -Path $cbs -Bytes 524288 | Where-Object { $_ -match '\[SR\]' })
        }
        elseif ($Kind -eq 'DISM') {
            $dl = Join-Path $env:SystemRoot 'Logs\DISM\dism.log'
            $lines = @(Get-FileTail -Path $dl -Bytes 131072)
        }
        # SFC und DISM hinterlassen regelmaessig einen ausstehenden Neustart.
        $script:RebootStateTime = $null
        $res = Get-RepairResult -Kind $Kind -ExitCode $ExitCode -Lines $lines
        if (-not $res) { return }
        $txt = Get-Text $res.Key
        if ($res.Detail) { $txt = "$txt ($($res.Detail))" }
        if ($Label) { $txt = "$Label : $txt" }
        Write-Log $txt $res.Level
    }
    catch { }
}

function Invoke-RepairCommand {
    param(
        [Parameter(Mandatory)][string]$File,
        [Parameter(Mandatory)][string]$Arguments,
        [string]$Label,
        [ValidateSet('', 'SFC', 'DISM', 'CHKDSK')][string]$ResultKind = ''
    )

    Write-Log "$Label ..." 'SYSTEM'
    # Abbrechbar: SFC und DISM laufen regelmaessig zehn Minuten und laenger.
    # Ohne Abbruch war die gesamte Oberflaeche so lange gesperrt.
    Show-BusyOverlay -Title $Label -Status (Get-Text 'RepairWindow') -Cancellable
    $ok = $false
    try {
        # The console window stays VISIBLE: sfc and DISM print their own
        # percentage, and hiding it was the reason a five minute scan looked
        # like a freeze. No -Verb RunAs needed - this process is already
        # elevated, and a second UAC prompt per repair would be worse.
        # -Wait would block the message loop, so we poll and pump events.
        $p = Start-Process $File -ArgumentList $Arguments -WindowStyle Normal -PassThru -ErrorAction Stop
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $cancelled = $false
        while (-not $p.HasExited) {
            [void]$p.WaitForExit(120)
            if (Test-BusyCancelled) {
                # sfc/DISM/chkdsk arbeiten in Kindprozessen - nur der ganze
                # Baum beendet den Durchlauf wirklich.
                Stop-ProcessTree -Process $p
                $cancelled = $true
                break
            }
            $el = $sw.Elapsed
            Update-BusyOverlay -Status ("$Label  ·  {0:00}:{1:00}" -f [int]$el.TotalMinutes, $el.Seconds) -Percent -1
        }
        $sw.Stop()
        if ($cancelled) {
            Write-Log "$Label : $(Get-Text 'BusyCancelled')" 'WARNING'
        }
        else {
            $p.Refresh()
            $rc = $p.ExitCode
            if ($rc -eq 0) { $ok = $true; Write-Log "$Label : $(Get-Text 'DlgCompleted')" 'SUCCESS' }
            else { Write-Log "$Label : $(Get-Text 'LogExitCode') $rc" 'WARNING' }
            # 'Abgeschlossen' sagt bei sfc und DISM nichts aus - das eigentliche
            # Ergebnis steht im Protokoll des Werkzeugs.
            if ($ResultKind) { Write-RepairResult -Kind $ResultKind -ExitCode $rc -Label $Label }
        }
        try { $p.Dispose() } catch { }
    }
    catch { Write-Log "$Label : $($_.Exception.Message)" 'ERROR' }
    finally { Hide-BusyOverlay }
    return $ok
}

function Show-RepairCenter {
    Add-ViewHeader -TitleKey 'RepairTitle' -SubtitleKey 'RepairSubtitle' -Icon 'wrench'

    Add-Card -TitleKey 'SysScan' -DescKey 'SysScanDesc' -BtnKey 'Start' -Icon 'pulse' -X 25 -Y 95 -Color $script:Theme.Cyan -Action {
        [void](Invoke-RepairCommand -File 'sfc.exe' -Arguments '/scannow' -Label 'SFC /scannow' -ResultKind 'SFC')
    } | Out-Null

    Add-Card -TitleKey 'RepairComponent' -DescKey 'RepairComponentDesc' -BtnKey 'Start' -Icon 'package' -X 315 -Y 95 -Color $script:Theme.Purple -Action {
        [void](Invoke-RepairCommand -File 'DISM.exe' -Arguments '/Online /Cleanup-Image /RestoreHealth' -Label 'DISM RestoreHealth' -ResultKind 'DISM')
    } | Out-Null

    Add-Card -TitleKey 'RepairCHKDSK' -DescKey 'RepairCHKDSKDesc' -BtnKey 'Start' -Icon 'disc' -X 605 -Y 95 -Color $script:Theme.Warning -Action {
        if (-not (Show-Confirm -Message (Get-Text 'DlgConfirm'))) { return }
        if (Invoke-RepairCommand -File 'cmd.exe' -Arguments "/c echo Y| chkdsk $env:SystemDrive /f /r" -Label 'CHKDSK' -ResultKind 'CHKDSK') {
            Write-Log "$(Get-Text 'DlgRestartReq')" 'WARNING'
            [void](Show-Info -Title (Get-Text 'RepairCHKDSK') -Message (Get-Text 'ChkdskScheduled'))
        }
    } | Out-Null

    Add-Card -TitleKey 'RepairNetwork' -DescKey 'RepairNetworkDesc' -BtnKey 'Reset' -Icon 'globe' -X 895 -Y 95 -Color $script:Theme.Error -Action {
        if (-not (Show-Confirm -Message (Get-Text 'DlgConfirm'))) { return }
        # Drei Laeufe hintereinander: Nach einem Abbruch darf der naechste
        # nicht trotzdem starten.
        if (-not (Invoke-RepairCommand -File 'netsh.exe' -Arguments 'winsock reset' -Label 'Winsock reset')) { return }
        if (-not (Invoke-RepairCommand -File 'netsh.exe' -Arguments 'int ip reset' -Label 'IP reset')) { return }
        Set-RebootHint
        [void](Invoke-RepairCommand -File 'ipconfig.exe' -Arguments '/flushdns' -Label 'DNS flush')
    } | Out-Null

    Add-Card -TitleKey 'RepairExplorer' -DescKey 'RepairExplorerDesc' -BtnKey 'Restart' -Icon 'folders' -X 25 -Y 265 -Color $script:Theme.Success -Action {
        Show-BusyOverlay -Title (Get-Text 'RepairExplorer') -Status 'explorer.exe'
        try {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Wait-AppDelay -Ms 800
            if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
                Start-Process explorer.exe
            }
            Write-Log "$(Get-Text 'RepairExplorer'): $(Get-Text 'Success')" 'SUCCESS'
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
        finally { Hide-BusyOverlay }
    } | Out-Null

    Add-Card -TitleKey 'RepairWU' -DescKey 'RepairWUDesc' -BtnKey 'Reset' -Icon 'refresh' -X 315 -Y 265 -Color $script:Theme.Accent -Action {
        # Frueher ohne Wartehinweis und ohne Fortschritt: ein rekursives
        # Remove-Item ueber mehrere Gigabyte, waehrend das Fenster einfror.
        Invoke-DiskClean -Key 'WUReset'
    } | Out-Null

    Add-Card -TitleKey 'RestorePoint' -DescKey 'RestorePointDesc' -BtnKey 'Start' -Icon 'camera' -X 605 -Y 265 -Color $script:Theme.Cyan -Action {
        [void](New-RestorePoint)
    } | Out-Null

    Add-Card -TitleKey 'Restore' -DescKey 'RepairSubtitle' -BtnKey 'Restore' -Icon 'skipback' -X 895 -Y 265 -Color $script:Theme.Purple -Action {
        try { Start-Process 'rstrui.exe' }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    } | Out-Null
}

# ------------------------------------------------------------- CONTEXT MENU --
function Show-ContextMenu {
    Add-ViewHeader -TitleKey 'ContextTitle' -SubtitleKey 'ContextSubtitle' -Icon 'note'

    Add-Card -TitleKey 'ClassicMenu' -DescKey 'ClassicMenuDesc' -BtnKey 'Enable' -Icon 'note' -X 25 -Y 95 -Color $script:Theme.Cyan -Action {
        try {
            $k = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
            [void](Set-RegistryValue -Path $k -Name '(Default)' -Value '' -Type String -Label (Get-Text 'ClassicMenu'))
            Write-Log "$(Get-Text 'ClassicMenu'): $(Get-Text 'Success') - $(Get-Text 'RepairExplorer')" 'SUCCESS'
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    } -StateCheck {
        Test-TweakApplied -PathPresent 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
    } | Out-Null

    Add-Card -TitleKey 'ModernMenu' -DescKey 'ModernMenuDesc' -BtnKey 'Restore' -Icon 'window' -X 315 -Y 95 -Color $script:Theme.Purple -Action {
        try {
            $k = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
            if (Test-Path -LiteralPath $k) { Remove-Item -LiteralPath $k -Recurse -Force -ErrorAction Stop }
            Write-Log "$(Get-Text 'ModernMenu'): $(Get-Text 'Success')" 'SUCCESS'
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    } -StateCheck {
        Test-TweakApplied -PathAbsent 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
    } | Out-Null

    Add-Card -TitleKey 'HideShare' -DescKey 'HideShareDesc' -BtnKey 'Disable' -Icon 'ban' -X 605 -Y 95 -Color $script:Theme.Warning -Action {
        try {
            $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            [void](Set-RegistryValue -Path $k -Name 'SharingWizardOn' -Value 0 -Type DWord -Label (Get-Text 'HideShare'))
            Write-Log "$(Get-Text 'HideShare'): $(Get-Text 'Success')" 'SUCCESS'
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    } -StateCheck {
        Test-TweakApplied -Entries @(
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'SharingWizardOn'; Value = 0 }
        )
    } | Out-Null

    Add-Card -TitleKey 'RepairExplorer' -DescKey 'RepairExplorerDesc' -BtnKey 'Restart' -Icon 'refresh' -X 895 -Y 95 -Color $script:Theme.Success -Action {
        Show-BusyOverlay -Title (Get-Text 'RepairExplorer') -Status 'explorer.exe'
        try {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Wait-AppDelay -Ms 800
            if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
            Write-Log "$(Get-Text 'RepairExplorer'): $(Get-Text 'Success')" 'SUCCESS'
        }
        catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
        finally { Hide-BusyOverlay }
    } | Out-Null
}

# ----------------------------------------------------------------- SETTINGS --
function Get-RegistryKeyStats {
    # Vor dem Loeschen wissen, was ueberhaupt drinsteht. Ohne diese Messung
    # fragte die Ansicht nicht nach und meldete auch bei einem leeren
    # Schluessel stolz "Erfolg".
    param([string]$Path)
    $res = @{ Exists = $false; Values = 0; Keys = 0 }
    if ([string]::IsNullOrWhiteSpace($Path)) { return $res }
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        $res.Exists = $true
        $res.Values = @($item.Property).Count
        $res.Keys = @(Get-ChildItem -LiteralPath $Path -ErrorAction SilentlyContinue).Count
    }
    catch { }
    return $res
}

function Get-RegistryCleanPlan {
    # Reine Entscheidung: loeschen, nichts zu tun oder gar nicht vorhanden.
    param($Stats)
    if (-not $Stats -or -not $Stats.Exists) { return @{ Do = 'none'; ReasonKey = 'LogNotPresent'; Count = 0 } }
    $n = [int]$Stats.Values + [int]$Stats.Keys
    if ($n -le 0) { return @{ Do = 'none'; ReasonKey = 'SvcNoChange'; Count = 0 } }
    return @{ Do = 'clean'; ReasonKey = ''; Count = $n }
}

function Invoke-RegistryCardClean {
    # Messen, fragen, sichern, loeschen, nachsehen. Vorher loeschte ein Klick
    # sofort und ungefragt - und die Sicherung mit reg.exe lief ohne
    # Warteflaeche, wodurch das Fenster bis zu einer Minute stehen blieb.
    param([string]$Path, [string]$Label)
    $plan = Get-RegistryCleanPlan -Stats (Get-RegistryKeyStats -Path $Path)
    if ($plan.Do -ne 'clean') {
        Write-Log "$Label : $(Get-Text $plan.ReasonKey)" 'INFO'
        return $false
    }
    if (-not (Show-Confirm -Message "$Label`n`n$Path`n$($plan.Count) $(Get-Text 'BakKeys')`n`n$(Get-Text 'DlgRisk')")) { return $false }

    $ok = $false
    Show-BusyOverlay -Title $Label -Status $Path
    try {
        # Erst die Sicherung, dann der Eingriff - und nur weiter, wenn die
        # Sicherung wirklich auf der Platte liegt.
        $bak = Backup-RegistryKey -Path $Path -Name $Label
        if (-not $bak) {
            Write-Log "$Label : $(Get-Text 'BakInvalid')" 'ERROR'
            return $false
        }
        Update-BusyOverlay -Status $Path -Percent 60
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            $after = Get-RegistryKeyStats -Path $Path
            # Nachsehen statt annehmen: Explorer legt manche dieser Schluessel
            # sofort wieder an - leer ist dann genauso richtig wie weg.
            if ($after.Exists -and (([int]$after.Values + [int]$after.Keys) -ge $plan.Count)) {
                Write-Log "$Label : $(Get-Text 'ChangeVerifyErr')" 'ERROR'
            }
            else {
                $ok = $true
                Write-Log "$Label : $(Get-Text 'Success') ($($plan.Count))" 'SUCCESS'
            }
        }
        catch { Write-Log "$Label : $($_.Exception.Message)" 'ERROR' }
    }
    finally { Hide-BusyOverlay }
    return $ok
}

function Get-BackupRows {
    # Reines Modell der Sicherungsliste. Gezaehlt und gewogen wird alles,
    # angezeigt werden die juengsten - sonst verbirgt die Liste genau das
    # Wachstum, um das es in dieser Ansicht geht.
    param($Files, [int]$Max = 200)
    $all = @($Files | Where-Object { $_ })
    $bytes = 0.0
    foreach ($f in $all) { $bytes += [double]$f.Length }
    $rows = New-Object System.Collections.ArrayList
    foreach ($f in @($all | Select-Object -First $Max)) {
        $ext = ([string]$f.Extension).ToLowerInvariant()
        [void]$rows.Add([pscustomobject]@{
                Name  = [string]$f.Name
                Type  = $(switch ($ext) { '.reg' { 'Registry' } '.json' { 'Services' } default { 'Text' } })
                Date  = [string]$f.Date
                Bytes = [double]$f.Length
                Path  = [string]$f.FullName
                IsReg = ($ext -eq '.reg')
            })
    }
    return @{ Rows = @($rows.ToArray()); Count = $all.Count; Bytes = $bytes }
}

function Remove-SelectedBackups {
    # Mehrere Sicherungen auf einmal: wer aufraeumt, loescht selten genau eine.
    if (-not $script:lstBackups -or $script:lstBackups.IsDisposed) { return }
    $paths = @()
    foreach ($it in @($script:lstBackups.SelectedItems)) {
        if ($it.Tag) { $paths += [string]$it.Tag }
    }
    if ($paths.Count -eq 0) { Write-Log (Get-Text 'BackupSelect') 'WARNING'; return }
    $what = if ($paths.Count -eq 1) { $paths[0] } else { "$($paths.Count)" }
    if (-not (Show-Confirm -Message "$(Get-Text 'Delete')?`n`n$what")) { return }
    $ok = 0
    $failed = @()
    foreach ($p in $paths) {
        try {
            Remove-Item -LiteralPath $p -Force -ErrorAction Stop
            $ok++
        }
        catch { $failed += [System.IO.Path]::GetFileName($p) }
    }
    Write-TweakOutcome -Label (Get-Text 'Delete') -Ok $ok -Total $paths.Count -Failed $failed
    Clear-DataCache -Key 'BackupFiles'
    Update-BackupList -Force
}

function Update-BackupList {
    # Zeigt alles, was das Programm in den Sicherungsordner geschrieben hat.
    param([switch]$Force)
    if (-not $script:lstBackups -or $script:lstBackups.IsDisposed) { return }

    # Das Auflisten eines gewachsenen Ordners - und auf einem Netzlaufwerk
    # erst recht - gehoert nicht in den Oberflaechenstrang. Bis die Daten da
    # sind, bleibt die bisherige Liste stehen und die Ansicht bedienbar.
    $ready = Request-CachedData -Key 'BackupFiles' -TtlSeconds 15 -Force:$Force `
        -OnReady { Update-BackupList } -Loader {
        $dir = $env:EB_BACKUP_DIR
        if (-not $dir -or -not (Test-Path -LiteralPath $dir)) { return @() }
        Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in @('.reg', '.json', '.txt', '.html') } |
            Sort-Object LastWriteTime -Descending |
            ForEach-Object {
                [pscustomobject]@{
                    Name      = $_.Name
                    FullName  = $_.FullName
                    Extension = $_.Extension
                    Length    = [double]$_.Length
                    Date      = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
                }
            }
    }
    if (-not $ready) {
        Add-EmptyState -ListView $script:lstBackups -Text (Get-Text 'Loading')
        return
    }

    $script:lstBackups.BeginUpdate()
    try {
        $script:lstBackups.Items.Clear()
        $model = Get-BackupRows -Files @(Get-CacheEntryData -Key 'BackupFiles') -Max 200
        $items = New-Object System.Collections.Generic.List[System.Windows.Forms.ListViewItem]
        foreach ($row in $model.Rows) {
            $item = New-Object System.Windows.Forms.ListViewItem($row.Name)
            [void]$item.SubItems.Add($row.Type)
            [void]$item.SubItems.Add($row.Date)
            [void]$item.SubItems.Add((Get-FormattedBytes $row.Bytes))
            $item.Tag = $row.Path
            $item.ToolTipText = $row.Path
            if ($row.IsReg) { $item.ForeColor = $script:Theme.Cyan }
            $items.Add($item)
        }
        if ($items.Count -gt 0) { $script:lstBackups.Items.AddRange($items.ToArray()) }
        Add-EmptyState -ListView $script:lstBackups -Text (Get-Text 'BackupNone')
        Restore-ListViewSort -ListView $script:lstBackups -Name 'Sicherungen'
        Set-ListFilterCount -Name 'Sicherungen' -Shown $items.Count -Total $model.Count
        if ($script:lblBackupSize -and -not $script:lblBackupSize.IsDisposed) {
            $script:lblBackupSize.Text = "$(Get-Text 'BakFolder'): $(Get-FormattedBytes $model.Bytes)  /  $($model.Count)"
        }
    }
    catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    finally { $script:lstBackups.EndUpdate() }
}
function Get-SelectedBackupPath {
    if (-not $script:lstBackups -or $script:lstBackups.IsDisposed) { return $null }
    $sel = @($script:lstBackups.SelectedItems)
    if ($sel.Count -eq 0 -or -not $sel[0].Tag) {
        Write-Log (Get-Text 'BackupSelect') 'WARNING'
        return $null
    }
    $path = [string]$sel[0].Tag
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Log "$(Get-Text 'Error'): $path" 'ERROR'
        Clear-DataCache -Key 'BackupFiles'
        Update-BackupList -Force
        return $null
    }
    return $path
}

function Restore-ServiceBackup {
    # Die Dienst-Sicherung war bisher reine Zierde: sie liess sich nur im
    # Editor oeffnen. Jetzt stellt sie die Starttypen tatsaechlich wieder her.
    param([string]$Path)

    $rows = @()
    try { $rows = @(Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json) }
    catch {
        Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR'
        return
    }
    $rows = @($rows | Where-Object { $_ -and $_.Name -and $_.StartType -in @('Automatic', 'Manual', 'Disabled') })
    if ($rows.Count -eq 0) { Write-Log (Get-Text 'BackupNone') 'WARNING'; return }
    if (-not (Show-Confirm -Message "$(Get-Text 'BakSvcTitle')?`n`n$($rows.Count) $(Get-Text 'BakSvcCount')")) { return }

    $ok = 0; $total = 0; $failed = @()
    Show-BusyOverlay -Title (Get-Text 'BakSvcTitle') -Cancellable
    try {
        $i = 0
        foreach ($r in $rows) {
            $i++
            if (Test-BusyCancelled) { Write-Log (Get-Text 'BusyCancelled') 'WARNING'; break }
            if ($i % 10 -eq 0) {
                Update-BusyOverlay -Status "$($r.Name)  ($i / $($rows.Count))" -Percent ([int]($i / [double]$rows.Count * 100))
            }
            $cur = Get-ServiceStartupType -Name $r.Name
            if ($cur -eq 'Unknown') { continue }           # Dienst ist weg
            if ($cur -eq [string]$r.StartType) { continue } # steht schon so
            # Klammern noetig: ohne sie bindet PowerShell '-and ...' noch an
            # den Parameter -ServiceName und prueft etwas voellig anderes.
            if ((Test-ServiceProtected -ServiceName $r.Name) -and ([string]$r.StartType -eq 'Disabled')) { continue }
            $total++
            try {
                Set-Service -Name $r.Name -StartupType ([string]$r.StartType) -ErrorAction Stop
                $now = Get-ServiceStartupType -Name $r.Name
                if ($now -ne [string]$r.StartType) {
                    $failed += $r.Name
                    continue
                }
                [void](Add-ChangeEntry -Action 'service' -Path 'Service' -Name $r.Name `
                        -Type 'StartupType' -OldValue $cur -NewValue ([string]$r.StartType) `
                        -Existed $true -Label (Get-Text 'BakSvcTitle'))
                $ok++
            }
            catch { $failed += $r.Name }
        }
    }
    finally { Hide-BusyOverlay }

    if ($total -le 0) { Write-Log "$(Get-Text 'BakSvcTitle'): $(Get-Text 'SvcNoChange')" 'INFO' }
    else { Write-TweakOutcome -Label (Get-Text 'BakSvcTitle') -Ok $ok -Total $total -Failed $failed }
    if ($ok -gt 0) { Update-ChangeList }
    Clear-DataCache -Key 'StartModes'
}

function Restore-RegistryBackup {
    $path = Get-SelectedBackupPath
    if (-not $path) { return }

    $ext = [System.IO.Path]::GetExtension($path)
    if ($ext -eq '.json') {
        Restore-ServiceBackup -Path $path
        return
    }
    if ($ext -ne '.reg') {
        # Berichte und sonstige Beilagen sind zum Nachlesen da
        try { Start-Process notepad.exe -ArgumentList ('"' + $path + '"') } catch { }
        return
    }

    # Erst pruefen, dann fragen: eine abgebrochene oder leere Ausgabe von
    # reg.exe liegt genauso im Ordner wie eine gute Sicherung.
    $stat = Test-RegFileValid -Path $path
    if (-not $stat.Ok) {
        Write-Log "$(Get-Text 'BakInvalid'): $path" 'ERROR'
        return
    }
    # Ehrlich sagen, was 'Wiederherstellen' bei einer .reg-Datei bedeutet.
    $msg = "$(Get-Text 'BackupRestore')?`n`n$path`n$($stat.Keys) $(Get-Text 'BakKeys')`n`n$(Get-Text 'BakMergeHint')"
    if (-not (Show-Confirm -Message $msg)) { return }

    # Frueher lief hier eine eigene Warteschleife ohne Zeitlimit und ohne
    # Warteflaeche: ein haengendes reg.exe haette das Fenster fuer immer
    # beschaeftigt, und Klicks gingen waehrenddessen an andere Schaltflaechen.
    Show-BusyOverlay -Title (Get-Text 'BackupRestore') -Status $path -Cancellable
    try {
        $code = Invoke-SystemCommand -File 'reg.exe' -TimeoutSec 300 -Label 'reg.exe import' `
            -Arguments @('import', ('"' + $path + '"'))
        if ($code -eq 0) { Write-Log "$(Get-Text 'BackupDone'): $path" 'SUCCESS' }
        elseif ($null -eq $code) { Write-Log "$(Get-Text 'Error'): reg.exe" 'ERROR' }
        else { Write-Log "$(Get-Text 'Error'): reg.exe exit code $code" 'ERROR' }
    }
    catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
    finally { Hide-BusyOverlay }
}

function Show-Settings {
    Add-ViewHeader -TitleKey 'MenuSettings' -SubtitleKey 'SettingsSubtitle' -Icon 'gear'

    $lblLang = New-Object System.Windows.Forms.Label
    $lblLang.Text = '{icon:globe} Language / Sprache / Dil / اللغة'
    $lblLang.Font = (Get-AppFont -Size 12 -Style 'Bold')
    $lblLang.ForeColor = $script:Theme.TextPrimary
    $lblLang.Location = New-Object System.Drawing.Point(25, 100)
    $lblLang.AutoSize = $true
    $lblLang.BackColor = [System.Drawing.Color]::Transparent
    $script:pnlContent.Controls.Add($lblLang)

    $x = 25
    foreach ($code in @('DE', 'EN', 'TR', 'AR')) {
        $lang = $script:Languages[$code]
        $b = New-Object System.Windows.Forms.Button
        # Alle vier Sprachen trugen dasselbe '{icon:flag}' - vier identische
        # graue Faehnchen ohne Aussage. Das Sprachkuerzel unterscheidet sie.
        # Das Feld 'Flag' bleibt fuer eine spaetere echte Flaggenschrift.
        $b.Text = "$code  -  $($lang.Name)"
        $b.TextAlign = 'MiddleCenter'
        $b.Location = New-Object System.Drawing.Point($x, 140)
        $b.Size = New-Object System.Drawing.Size(200, 50)
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderSize = if ($code -eq $script:Config.CurrentLang) { 2 } else { 0 }
        $b.FlatAppearance.BorderColor = $script:Theme.Accent
        $b.BackColor = if ($code -eq $script:Config.CurrentLang) { $script:Theme.Accent } else { $script:Theme.BgTertiary }
        $b.ForeColor = $script:Theme.TextWhite
        $b.Font = (Get-AppFont -Size 11 -Style 'Bold')
        $b.Cursor = 'Hand'
        $b.Tag = $code
        $b.Add_Click({
                if (Set-Language -Code $this.Tag) {
                    Write-Log "$(Get-Text 'LogLanguage'): $($this.Tag)" 'INFO'
                    Update-SidebarLanguage
                    Set-View -ViewName 'Settings'
                }
            })
        $script:pnlContent.Controls.Add($b)
        $x += 215
    }

    # --- Options ---------------------------------------------------------------
    $y = 230
    $chkLog = New-Object System.Windows.Forms.CheckBox
    $chkLog.Text = "{icon:note} $(Get-Text 'SetLogging')"
    $chkLog.Location = New-Object System.Drawing.Point(25, $y)
    $chkLog.Size = New-Object System.Drawing.Size(300, 30)
    $chkLog.ForeColor = $script:Theme.TextPrimary
    $chkLog.Font = (Get-AppFont -Size 10)
    $chkLog.BackColor = [System.Drawing.Color]::Transparent
    $chkLog.Checked = [bool]$script:Config.EnableLogging
    $chkLog.Add_CheckedChanged({ $script:Config.EnableLogging = $this.Checked })
    $script:pnlContent.Controls.Add($chkLog)

    $chkNotify = New-Object System.Windows.Forms.CheckBox
    $chkNotify.Text = "{icon:bell} $(Get-Text 'SetNotify')"
    $chkNotify.Location = New-Object System.Drawing.Point(325, $y)
    $chkNotify.Size = New-Object System.Drawing.Size(300, 30)
    $chkNotify.ForeColor = $script:Theme.TextPrimary
    $chkNotify.Font = (Get-AppFont -Size 10)
    $chkNotify.BackColor = [System.Drawing.Color]::Transparent
    $chkNotify.Checked = [bool]$script:Config.EnableNotify
    $chkNotify.Add_CheckedChanged({
            $script:Config.EnableNotify = $this.Checked
            # Beim Abschalten die noch stehenden Karten sofort wegraeumen
            if (-not $this.Checked) { try { Clear-Toasts } catch { } }
        })
    $script:pnlContent.Controls.Add($chkNotify)

    $chkWin = New-Object System.Windows.Forms.CheckBox
    $chkWin.Text = "{icon:window} $(Get-Text 'SetRememberWin')"
    $chkWin.Location = New-Object System.Drawing.Point(625, $y)
    $chkWin.Size = New-Object System.Drawing.Size(330, 30)
    $chkWin.ForeColor = $script:Theme.TextPrimary
    $chkWin.Font = (Get-AppFont -Size 10)
    $chkWin.BackColor = [System.Drawing.Color]::Transparent
    $chkWin.Checked = [bool]$script:Config.RememberWin
    $chkWin.Add_CheckedChanged({ $script:Config.RememberWin = $this.Checked })
    $script:pnlContent.Controls.Add($chkWin)

    $chkView = New-Object System.Windows.Forms.CheckBox
    $chkView.Text = "{icon:undo} $(Get-Text 'SetRestoreView')"
    $chkView.Location = New-Object System.Drawing.Point(955, $y)
    $chkView.Size = New-Object System.Drawing.Size(330, 30)
    $chkView.ForeColor = $script:Theme.TextPrimary
    $chkView.Font = (Get-AppFont -Size 10)
    $chkView.BackColor = [System.Drawing.Color]::Transparent
    $chkView.Checked = [bool]$script:Config.RestoreView
    $chkView.Add_CheckedChanged({ $script:Config.RestoreView = $this.Checked })
    $script:pnlContent.Controls.Add($chkView)

    $chkTray = New-Object System.Windows.Forms.CheckBox
    $chkTray.Text = "{icon:tray} $(Get-Text 'SetTray')"
    $chkTray.Location = New-Object System.Drawing.Point(25, 262)
    $chkTray.Size = New-Object System.Drawing.Size(600, 28)
    $chkTray.ForeColor = $script:Theme.TextPrimary
    $chkTray.Font = (Get-AppFont -Size 10)
    $chkTray.BackColor = [System.Drawing.Color]::Transparent
    $chkTray.Checked = [bool]$script:Config.MinimizeToTray
    $chkTray.Add_CheckedChanged({
            $script:Config.MinimizeToTray = $this.Checked
            # Abschalten entfernte das Symbol bisher nicht - es blieb im
            # Infobereich stehen und zeigte weiter Sprechblasen.
            if ($this.Checked) { Initialize-TrayIcon } else { Stop-TrayIcon }
        })
    $script:pnlContent.Controls.Add($chkTray)

    $chkClean = New-Object System.Windows.Forms.CheckBox
    $chkClean.Text = "{icon:broom} $(Get-Text 'SetCleanConfirm')"
    $chkClean.Location = New-Object System.Drawing.Point(640, 262)
    $chkClean.Size = New-Object System.Drawing.Size(560, 28)
    $chkClean.ForeColor = $script:Theme.TextPrimary
    $chkClean.Font = (Get-AppFont -Size 10)
    $chkClean.BackColor = [System.Drawing.Color]::Transparent
    $chkClean.Checked = [bool]$script:Config.CleanConfirm
    $chkClean.Add_CheckedChanged({ $script:Config.CleanConfirm = $this.Checked })
    $script:pnlContent.Controls.Add($chkClean)

    # --- Maintenance buttons ---------------------------------------------------
    $y = 300
    $buttons = @(
        @{ Text = "{icon:folder} $(Get-Text 'Export') (Backups)"; Color = $script:Theme.Cyan; Act = {
                try {
                    if (-not (Test-Path -LiteralPath $script:Config.BackupDir)) {
                        New-Item -Path $script:Config.BackupDir -ItemType Directory -Force | Out-Null
                    }
                    Start-Process explorer.exe -ArgumentList $script:Config.BackupDir
                }
                catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
            }
        },
        @{ Text = "{icon:save} $(Get-Text 'Export') (Log)"; Color = $script:Theme.Success; Act = {
                try {
                    if (-not $script:txtLog) { return }
                    $file = Join-Path $script:Config.BackupDir ("Log_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.txt')
                    $all = foreach ($e in $script:LogEntries.ToArray()) { "[$($e.Time)] [$($e.Type)] $($e.Message)" }
                    $all | Out-File -LiteralPath $file -Encoding UTF8
                    Write-Log "$(Get-Text 'Export'): $file" 'SUCCESS'
                }
                catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
            }
        },
        @{ Text = "{icon:broom} $(Get-Text 'Clean') (Log)"; Color = $script:Theme.Warning; Act = {
                Clear-LogView
            }
        },
        @{ Text = "{icon:camera} $(Get-Text 'RestorePoint')"; Color = $script:Theme.Purple; Act = { [void](New-RestorePoint) } },
        @{ Text = "{icon:save} $(Get-Text 'Apply')"; Color = $script:Theme.Accent; Act = {
                if (Export-AppSettings) { Write-Log "$(Get-Text 'SetSaved')" 'SUCCESS' }
                else { Write-Log "$(Get-Text 'Error'): $(Get-Text 'SetFile')" 'ERROR' }
            }
        },
        @{ Text = "{icon:refresh} $(Get-Text 'SetReset')"; Color = $script:Theme.Error; Act = {
                if (Show-Confirm -Message (Get-Text 'DlgConfirm')) { Reset-AppSettings }
            }
        }
    )

    $x = 25
    foreach ($def in $buttons) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $def.Text
        $b.Location = New-Object System.Drawing.Point($x, $y)
        $b.Size = New-Object System.Drawing.Size(270, 45)
        $b.BackColor = $def.Color
        $b.ForeColor = $script:Theme.TextWhite
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderSize = 0
        $b.Font = (Get-AppFont -Size 10 -Style 'Bold')
        $b.Cursor = 'Hand'
        $b.Tag = $def.Act
        $b.Add_Click({
                try { & $this.Tag }
                catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
            })
        $script:pnlContent.Controls.Add($b)
        $x += 290
    }

    # --- Backups ---------------------------------------------------------------
    $lblBkTitle = New-Object System.Windows.Forms.Label
    $lblBkTitle.Text = "{icon:folders} $(Get-Text 'BackupsTitle')"
    $lblBkTitle.Font = (Get-AppFont -Size 12 -Style 'Bold')
    $lblBkTitle.ForeColor = $script:Theme.TextPrimary
    $lblBkTitle.Location = New-Object System.Drawing.Point(25, 355)
    $lblBkTitle.AutoSize = $true
    $lblBkTitle.BackColor = [System.Drawing.Color]::Transparent
    $script:pnlContent.Controls.Add($lblBkTitle)

    $lblBkHint = New-Object System.Windows.Forms.Label
    $lblBkHint.Text = Get-Text 'BackupsHint'
    $lblBkHint.Font = (Get-AppFont -Size 9)
    $lblBkHint.ForeColor = $script:Theme.TextMuted
    $lblBkHint.Location = New-Object System.Drawing.Point(25, 382)
    $lblBkHint.Size = New-Object System.Drawing.Size(480, 20)
    $lblBkHint.AutoEllipsis = $true
    $lblBkHint.BackColor = [System.Drawing.Color]::Transparent
    $script:pnlContent.Controls.Add($lblBkHint)

    $lstBk = New-Object System.Windows.Forms.ListView
    $lstBk.Location = New-Object System.Drawing.Point(25, 408)
    $lstBk.Size = New-Object System.Drawing.Size(820, 210)
    $lstBk.View = 'Details'
    $lstBk.FullRowSelect = $true
    $lstBk.ShowItemToolTips = $true
    $lstBk.MultiSelect = $true
    $lstBk.BackColor = $script:Theme.BgSecondary
    $lstBk.ForeColor = $script:Theme.TextPrimary
    $lstBk.BorderStyle = 'None'
    $lstBk.Anchor = 'Top,Bottom,Left,Right'
    $lstBk.Font = (Get-AppFont -Size 9)
    [void]$lstBk.Columns.Add((Get-Text 'ColFile'), 420)
    [void]$lstBk.Columns.Add((Get-Text 'ColType'), 100)
    [void]$lstBk.Columns.Add((Get-Text 'ColDate'), 160)
    [void]$lstBk.Columns.Add((Get-Text 'ColSize'), 100)
    $lstBk.Add_DoubleClick({ Restore-RegistryBackup })
    $script:pnlContent.Controls.Add($lstBk)
    Set-ListViewColumnFit -ListView $lstBk -Weights @(4, 1, 2, 1) -Name 'Sicherungen'
    Set-ListViewSortable -ListView $lstBk -Name 'Sicherungen'
    Add-ListContextMenu -ListView $lstBk -Name 'Sicherungen'
    $script:lstBackups = $lstBk

    # Ohne diese Zeile sieht niemand, dass der Ordner waechst - die Liste
    # zeigt nur die 200 juengsten Dateien.
    $lblBkSize = New-Object System.Windows.Forms.Label
    $lblBkSize.Font = (Get-AppFont -Size 9 -Style 'Bold')
    $lblBkSize.ForeColor = $script:Theme.TextSecondary
    $lblBkSize.Location = New-Object System.Drawing.Point(525, 382)
    $lblBkSize.Size = New-Object System.Drawing.Size(320, 20)
    $lblBkSize.TextAlign = 'MiddleRight'
    $lblBkSize.Anchor = 'Top,Right'
    $lblBkSize.BackColor = [System.Drawing.Color]::Transparent
    $script:pnlContent.Controls.Add($lblBkSize)
    $lblBkSize.BringToFront()
    $script:lblBackupSize = $lblBkSize

    $bkButtons = @(
        @{ Text = "{icon:undo} $(Get-Text 'BackupRestore')"; Color = $script:Theme.Success; Act = { Restore-RegistryBackup } },
        @{ Text = "{icon:trash} $(Get-Text 'Delete')"; Color = $script:Theme.Error; Act = { Remove-SelectedBackups } },
        @{ Text = "{icon:broom} $(Get-Text 'BakClean')"; Color = $script:Theme.Warning; Act = {
                [void](Invoke-BackupCleanup)
                Clear-DataCache -Key 'BackupFiles'
                Update-BackupList -Force
            }
        },
        @{ Text = "{icon:refresh} $(Get-Text 'Refresh')"; Color = $script:Theme.BgTertiary; Act = {
                Clear-DataCache -Key 'BackupFiles'
                Update-BackupList -Force
            }
        }
    )
    $by = 408
    foreach ($def in $bkButtons) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $def.Text
        $b.Location = New-Object System.Drawing.Point(865, $by)
        $b.Size = New-Object System.Drawing.Size(280, 45)
        $b.Anchor = 'Top,Right'
        $b.BackColor = $def.Color
        $b.ForeColor = $script:Theme.TextWhite
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderSize = 0
        $b.Font = (Get-AppFont -Size 10 -Style 'Bold')
        $b.Cursor = 'Hand'
        $b.Tag = $def.Act
        $b.Add_Click({
                try { & $this.Tag }
                catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
            })
        $script:pnlContent.Controls.Add($b)
        $by += 55
    }

    # Reading the folder can take a moment on a slow disk - after painting
    Invoke-Deferred -Action { Update-BackupList -Force }

    # --- About -----------------------------------------------------------------
    $txt = New-Object System.Windows.Forms.RichTextBox
    $txt.Location = New-Object System.Drawing.Point(25, 640)
    $txt.Size = New-Object System.Drawing.Size(1120, 240)
    $txt.BackColor = $script:Theme.BgSecondary
    $txt.ForeColor = $script:Theme.TextSecondary
    $txt.ReadOnly = $true
    $txt.BorderStyle = 'None'
    # Not anchored to the bottom: the backup list above owns the free height
    $txt.Anchor = 'Top,Left,Right'
    $txt.Font = (Get-AppFont -Family $script:MonoFont -Size 10)
    $script:pnlContent.Controls.Add($txt)

    $txt.AppendText("`n  $($script:Config.AppName)  v$($script:Config.Version)`n`n")
    $txt.AppendText("  PowerShell      : $($PSVersionTable.PSVersion)`n")
    $txt.AppendText("  Host            : $($Host.Name)`n")
    $txt.AppendText("  OS              : $([Environment]::OSVersion.VersionString)`n")
    $txt.AppendText("  User            : $env:USERNAME@$env:COMPUTERNAME`n")
    $txt.AppendText("  Script root     : $script:AppRoot`n")
    $txt.AppendText("  Backup folder   : $($script:Config.BackupDir)`n")
    $txt.AppendText("  $(Get-Text 'SetFile')     : $($script:Config.SettingsPath)`n`n")
    $txt.AppendText("  $(Get-Text 'ShortcutInfo')`n")
}

# --------------------------------------------------------------------- HELP --
function Get-HelpContent {
    # The help page is the only long-form text in the program. Keeping it as one
    # table per language is far more readable than 30 extra dictionary keys -
    # and it was the last place that still showed German text in EN/TR/AR mode.
    # The %...% tokens are replaced with the real paths in Show-Help.
    $data = @{
        DE = @(
            @{ H = 'TASTENKUERZEL' }
            @{ K = 'F1'; V = 'Diese Hilfe' }
            @{ K = 'F5'; V = 'Aktuelle Ansicht neu laden' }
            @{ K = 'F11'; V = 'Maximieren / Wiederherstellen' }
            @{ K = 'Strg + 1 ... 9'; V = 'Dashboard, Hardware, Disk, Gaming, Privacy, Dienste, Prozesse, Reparatur, Einstellungen' }
            @{ K = 'Strg + R'; V = 'Aktuelle Ansicht neu laden' }
            @{ K = 'Strg + F'; V = 'In Dienste-/Prozessliste suchen' }
            @{ K = 'Strg + L'; V = 'Log-Anzeige leeren' }
            @{ K = 'Strg + H'; V = 'Hilfe oeffnen' }
            @{ K = 'Strg + W'; V = 'Fenster schliessen' }
            @{ K = 'Strg + Q'; V = 'Programm beenden' }
            @{ K = 'Esc'; V = 'Suchfeld leeren' }
            @{ K = 'Doppelklick Titel'; V = 'Maximieren / Wiederherstellen' }
            @{ H = 'BEDIENUNG' }
            @{ K = 'Fenster'; V = 'Groesse ueber rechten/unteren Rand oder den Griff unten rechts' }
            @{ K = 'Snap'; V = 'Titelleiste nach oben ziehen = maximieren, an die Seite = halbe Breite' }
            @{ K = 'Mausrad'; V = 'Scrollt immer den Bereich unter dem Mauszeiger' }
            @{ K = 'Status'; V = 'Die letzte Meldung steht oben rechts, das vollstaendige Protokoll unten' }
            @{ K = 'Nur eine Instanz'; V = 'Ein zweiter Start holt nur das bereits geoeffnete Fenster nach vorn' }
            @{ H = 'SICHERHEIT' }
            @{ K = 'Wiederherstellung'; V = 'Vor groesseren Eingriffen einen Wiederherstellungspunkt anlegen (Dashboard)' }
            @{ K = 'Registry'; V = 'Jede Aenderung wird vorher als .reg-Datei gesichert' }
            @{ K = 'Geschuetzt'; V = 'Kritische Dienste und Prozesse sind gesperrt und orange markiert' }
            @{ K = 'Neustart'; V = 'Einige Tweaks (HPET, GPU-Scheduling, Winsock) wirken erst nach einem Neustart' }
            @{ H = 'DATEIEN' }
            @{ K = 'Sicherungen'; V = '%BACKUP%' }
            @{ K = 'Einstellungen'; V = '%SETTINGS%' }
            @{ K = 'Protokoll'; V = '%LOG%' }
            @{ K = 'Absturzberichte'; V = '%CRASH%' }
        )
        EN = @(
            @{ H = 'SHORTCUTS' }
            @{ K = 'F1'; V = 'This help' }
            @{ K = 'F5'; V = 'Reload the current view' }
            @{ K = 'F11'; V = 'Maximize / restore' }
            @{ K = 'Ctrl + 1 ... 9'; V = 'Dashboard, Hardware, Disk, Gaming, Privacy, Services, Processes, Repair, Settings' }
            @{ K = 'Ctrl + R'; V = 'Reload the current view' }
            @{ K = 'Ctrl + F'; V = 'Search the service / process list' }
            @{ K = 'Ctrl + L'; V = 'Clear the log view' }
            @{ K = 'Ctrl + H'; V = 'Open help' }
            @{ K = 'Ctrl + W'; V = 'Close the window' }
            @{ K = 'Ctrl + Q'; V = 'Quit the program' }
            @{ K = 'Esc'; V = 'Clear the search box' }
            @{ K = 'Double click title'; V = 'Maximize / restore' }
            @{ H = 'USAGE' }
            @{ K = 'Window'; V = 'Resize via the right / bottom edge or the grip in the bottom right corner' }
            @{ K = 'Snap'; V = 'Drag the title bar to the top = maximize, to a side = half width' }
            @{ K = 'Mouse wheel'; V = 'Always scrolls the area under the mouse pointer' }
            @{ K = 'Status'; V = 'The last message is shown top right, the full log at the bottom' }
            @{ K = 'Single instance'; V = 'A second start only brings the already open window to the front' }
            @{ H = 'SAFETY' }
            @{ K = 'Restore point'; V = 'Create a restore point before bigger changes (Dashboard)' }
            @{ K = 'Registry'; V = 'Every change is exported to a .reg file first' }
            @{ K = 'Protected'; V = 'Critical services and processes are locked and marked orange' }
            @{ K = 'Reboot'; V = 'Some tweaks (HPET, GPU scheduling, Winsock) only take effect after a reboot' }
            @{ H = 'FILES' }
            @{ K = 'Backups'; V = '%BACKUP%' }
            @{ K = 'Settings'; V = '%SETTINGS%' }
            @{ K = 'Log'; V = '%LOG%' }
            @{ K = 'Crash reports'; V = '%CRASH%' }
        )
        TR = @(
            @{ H = 'KISAYOLLAR' }
            @{ K = 'F1'; V = 'Bu yardim' }
            @{ K = 'F5'; V = 'Gecerli gorunumu yenile' }
            @{ K = 'F11'; V = 'Buyut / geri yukle' }
            @{ K = 'Ctrl + 1 ... 9'; V = 'Panel, Donanim, Disk, Oyun, Gizlilik, Hizmetler, Islemler, Onarim, Ayarlar' }
            @{ K = 'Ctrl + R'; V = 'Gecerli gorunumu yenile' }
            @{ K = 'Ctrl + F'; V = 'Hizmet / islem listesinde ara' }
            @{ K = 'Ctrl + L'; V = 'Gunluk gorunumunu temizle' }
            @{ K = 'Ctrl + H'; V = 'Yardimi ac' }
            @{ K = 'Ctrl + W'; V = 'Pencereyi kapat' }
            @{ K = 'Ctrl + Q'; V = 'Programdan cik' }
            @{ K = 'Esc'; V = 'Arama kutusunu temizle' }
            @{ K = 'Baslikta cift tiklama'; V = 'Buyut / geri yukle' }
            @{ H = 'KULLANIM' }
            @{ K = 'Pencere'; V = 'Sag / alt kenardan veya sag alttaki tutamactan boyutlandirin' }
            @{ K = 'Snap'; V = 'Baslik cubugunu yukari surukleyin = buyut, kenara = yarim genislik' }
            @{ K = 'Fare tekerlegi'; V = 'Her zaman imlecin altindaki alani kaydirir' }
            @{ K = 'Durum'; V = 'Son mesaj sag ustte, tam gunluk altta gosterilir' }
            @{ K = 'Tek ornek'; V = 'Ikinci baslatma yalnizca acik olan pencereyi one getirir' }
            @{ H = 'GUVENLIK' }
            @{ K = 'Geri yukleme'; V = 'Buyuk degisikliklerden once bir geri yukleme noktasi olusturun (Panel)' }
            @{ K = 'Kayit defteri'; V = 'Her degisiklik once .reg dosyasi olarak yedeklenir' }
            @{ K = 'Korumali'; V = 'Kritik hizmet ve islemler kilitlidir ve turuncu isaretlidir' }
            @{ K = 'Yeniden baslatma'; V = 'Bazi ayarlar (HPET, GPU zamanlama, Winsock) yeniden baslatmadan sonra etkinlesir' }
            @{ H = 'DOSYALAR' }
            @{ K = 'Yedekler'; V = '%BACKUP%' }
            @{ K = 'Ayarlar'; V = '%SETTINGS%' }
            @{ K = 'Gunluk'; V = '%LOG%' }
            @{ K = 'Cokme raporlari'; V = '%CRASH%' }
        )
        AR = @(
            @{ H = 'اختصارات لوحة المفاتيح' }
            @{ K = 'F1'; V = 'هذه المساعدة' }
            @{ K = 'F5'; V = 'تحديث العرض الحالي' }
            @{ K = 'F11'; V = 'تكبير / استعادة' }
            @{ K = 'Ctrl + 1 ... 9'; V = 'لوحة المعلومات، العتاد، القرص، الألعاب، الخصوصية، الخدمات، العمليات، الإصلاح، الإعدادات' }
            @{ K = 'Ctrl + R'; V = 'تحديث العرض الحالي' }
            @{ K = 'Ctrl + F'; V = 'البحث في قائمة الخدمات والعمليات' }
            @{ K = 'Ctrl + L'; V = 'مسح عرض السجل' }
            @{ K = 'Ctrl + H'; V = 'فتح المساعدة' }
            @{ K = 'Ctrl + W'; V = 'إغلاق النافذة' }
            @{ K = 'Ctrl + Q'; V = 'إنهاء البرنامج' }
            @{ K = 'Esc'; V = 'مسح حقل البحث' }
            @{ K = 'نقر مزدوج على العنوان'; V = 'تكبير / استعادة' }
            @{ H = 'الاستخدام' }
            @{ K = 'النافذة'; V = 'غيّر الحجم من الحافة اليمنى أو السفلية أو من المقبض أسفل اليمين' }
            @{ K = 'الالتصاق'; V = 'اسحب شريط العنوان إلى الأعلى للتكبير، وإلى الجانب لنصف العرض' }
            @{ K = 'عجلة الفأرة'; V = 'تمرّر دائماً المنطقة الموجودة تحت المؤشر' }
            @{ K = 'الحالة'; V = 'آخر رسالة تظهر أعلى اليمين، والسجل الكامل في الأسفل' }
            @{ K = 'نسخة واحدة'; V = 'التشغيل الثاني يعيد النافذة المفتوحة إلى المقدمة فقط' }
            @{ H = 'الأمان' }
            @{ K = 'نقطة استعادة'; V = 'أنشئ نقطة استعادة قبل التغييرات الكبيرة (لوحة المعلومات)' }
            @{ K = 'السجل'; V = 'يتم حفظ كل تغيير كملف reg. قبل التطبيق' }
            @{ K = 'محمي'; V = 'الخدمات والعمليات الحرجة مقفلة ومعلّمة باللون البرتقالي' }
            @{ K = 'إعادة التشغيل'; V = 'بعض التعديلات (HPET، جدولة GPU، Winsock) تعمل بعد إعادة التشغيل' }
            @{ H = 'الملفات' }
            @{ K = 'النسخ الاحتياطية'; V = '%BACKUP%' }
            @{ K = 'الإعدادات'; V = '%SETTINGS%' }
            @{ K = 'السجل الكامل'; V = '%LOG%' }
            @{ K = 'تقارير الأعطال'; V = '%CRASH%' }
        )
    }
    $lang = $script:Config.CurrentLang
    if ($data.ContainsKey($lang)) { return , $data[$lang] }
    return , $data['EN']
}

function Show-Help {
    Add-ViewHeader -TitleKey 'HelpTitle' -SubtitleKey 'HelpSubtitle' -Icon 'help'

    $txt = New-Object System.Windows.Forms.RichTextBox
    $txt.Location = New-Object System.Drawing.Point(25, 95)
    $txt.Size = New-Object System.Drawing.Size(1120, 430)
    $txt.BackColor = $script:Theme.BgSecondary
    $txt.ForeColor = $script:Theme.TextSecondary
    $txt.ReadOnly = $true
    $txt.BorderStyle = 'None'
    $txt.Anchor = 'Top,Bottom,Left,Right'
    $txt.Font = (Get-AppFont -Family $script:MonoFont -Size 10)
    $script:pnlContent.Controls.Add($txt)

    $head = {
        param($t)
        $txt.SelectionColor = $script:Theme.Accent
        $txt.AppendText("`n  $t`n")
        $txt.SelectionColor = $script:Theme.TextMuted
        $txt.AppendText('  ' + ('-' * 72) + "`n")
    }
    $row = {
        param($k, $v)
        $txt.SelectionColor = $script:Theme.Cyan
        $txt.AppendText(("  {0,-22}" -f $k))
        $txt.SelectionColor = $script:Theme.TextSecondary
        $txt.AppendText("$v`n")
    }

    $logPathShown = if ($script:LogFilePath) { $script:LogFilePath } else { Join-Path $script:Config.BackupDir 'Logs' }
    $crashShown = (Join-Path $script:Config.BackupDir 'Logs') + '\crash_*.txt'

    foreach ($line in (Get-HelpContent)) {
        if ($line.H) { & $head $line.H; continue }
        $v = [string]$line.V
        $v = $v.Replace('%BACKUP%', $script:Config.BackupDir)
        $v = $v.Replace('%SETTINGS%', $script:Config.SettingsPath)
        $v = $v.Replace('%LOG%', $logPathShown)
        $v = $v.Replace('%CRASH%', $crashShown)
        & $row $line.K $v
    }

    $txt.SelectionStart = 0
    $txt.ScrollToCaret()

    Add-Card -TitleKey 'Report' -DescKey 'ReportDesc' -BtnKey 'Export' -Icon 'file' -X 25 -Y 540 `
        -Color $script:Theme.Cyan -Action { [void](Export-SystemReport) } | Out-Null

    Add-Card -TitleKey 'RestorePoint' -DescKey 'RestorePointDesc' -BtnKey 'Start' -Icon 'camera' -X 315 -Y 540 `
        -Color $script:Theme.Purple -Action { [void](New-RestorePoint) } | Out-Null

    Add-Card -TitleKey 'MenuSettings' -DescKey 'SettingsSubtitle' -BtnKey 'Start' -Icon 'gear' -X 605 -Y 540 `
        -Color $script:Theme.Accent -Action { Set-View -ViewName 'Settings' } | Out-Null
}

#endregion 6. VIEWS


#region 7. MAIN WINDOW

# ------------------------------------------------------------- CHANGES --
function Update-ChangeList {
    param([string]$Filter, [switch]$Force)

    if ($PSBoundParameters.ContainsKey('Filter')) { Set-ListFilter -Name 'Aenderungen' -Value $Filter }
    else { $Filter = Get-ListFilter 'Aenderungen' }

    if (-not $script:lstChanges -or $script:lstChanges.IsDisposed) { return }

    $script:lstChanges.BeginUpdate()
    try {
        $script:lstChanges.Items.Clear()
        $items = New-Object System.Collections.ArrayList
        # Newest first - that is the one people want to take back
        foreach ($row in @(Get-ChangeRows -Entries @($script:ChangeLog))) {
            $it = New-Object System.Windows.Forms.ListViewItem($row.Time)
            [void]$it.SubItems.Add($row.Label)
            [void]$it.SubItems.Add($row.Target)
            [void]$it.SubItems.Add($row.Old)
            [void]$it.SubItems.Add($row.New)
            [void]$it.SubItems.Add($row.State)
            $it.Tag = $row.Entry
            if ($row.Undone) { $it.ForeColor = $script:Theme.TextMuted }
            if (-not (Test-ItemFilter -Item $it -Filter $Filter)) { continue }
            [void]$items.Add($it)
        }
        if ($items.Count -gt 0) { $script:lstChanges.Items.AddRange($items.ToArray()) }
        Set-ListFilterCount -Name 'Aenderungen' -Shown $items.Count -Total $script:ChangeLog.Count
        Add-EmptyState -ListView $script:lstChanges -Text $(if ($Filter) { Get-Text 'EmptyFilter' } else { Get-Text 'ChangeNone' }) -SubText $(if ($Filter) { "'$Filter'" } else { '' })
        Restore-ListViewSort -ListView $script:lstChanges -Name 'Aenderungen'
    }
    catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'WARNING' }
    finally { $script:lstChanges.EndUpdate() }
}

function Undo-SelectedChange {
    if (-not $script:lstChanges -or $script:lstChanges.IsDisposed) { return }
    $sel = @($script:lstChanges.SelectedItems)
    if ($sel.Count -eq 0) { return }
    $entries = @(Get-UndoableEntries -Entries @($sel | ForEach-Object { $_.Tag }))
    if ($entries.Count -eq 0) {
        Write-Log (Get-Text 'ChangeNoUndo') 'INFO'
        return
    }
    # Erst fragen, dann die Warteflaeche - eine Nachfrage hinter der
    # Warteflaeche sieht aus wie ein haengendes Programm.
    $what = if ($entries.Count -eq 1) { Get-ChangeTargetText -Entry $entries[0] } else { "$($entries.Count)" }
    if (-not (Show-Confirm -Message "$(Get-Text 'ChangeUndo')?`n`n$what")) { return }
    [void](Invoke-ChangeUndoBatch -Entries $entries -Label (Get-Text 'ChangeUndo'))
    Update-ChangeList
}
function Show-Changes {
    Add-ViewHeader -TitleKey 'ChangesTitle' -SubtitleKey 'ChangesSubtitle' -Icon 'undo'

    [void](Add-ListSearchBox -Name 'Aenderungen' -PlaceholderKey 'SearchChanges' -Width 350 -Action {
            param($q) Set-ListFilter -Name 'Aenderungen' -Value $q; Update-ChangeList
        })

    $lst = New-Object System.Windows.Forms.ListView
    $lst.Location = New-Object System.Drawing.Point(25, 150)
    $lst.Size = New-Object System.Drawing.Size(820, 480)
    $lst.View = 'Details'
    $lst.FullRowSelect = $true
    $lst.MultiSelect = $true
    $lst.ShowItemToolTips = $true
    $lst.BackColor = $script:Theme.BgSecondary
    $lst.ForeColor = $script:Theme.TextPrimary
    $lst.BorderStyle = 'None'
    $lst.Anchor = 'Top,Bottom,Left,Right'
    $lst.Font = (Get-AppFont -Size 9)
    [void]$lst.Columns.Add((Get-Text 'ColDate'), 140)
    [void]$lst.Columns.Add((Get-Text 'ColType'), 120)
    [void]$lst.Columns.Add((Get-Text 'ColKey'), 330)
    [void]$lst.Columns.Add((Get-Text 'ColOld'), 90)
    [void]$lst.Columns.Add((Get-Text 'ColNew'), 90)
    [void]$lst.Columns.Add((Get-Text 'ColState'), 110)
    $lst.Add_DoubleClick({ Undo-SelectedChange })
    $script:pnlContent.Controls.Add($lst)
    Set-ListViewColumnFit -ListView $lst -Weights @(1, 1, 4, 1, 1, 1) -Name 'Aenderungen'
    Set-ListViewSortable -ListView $lst -Name 'Aenderungen'
    Add-ListContextMenu -ListView $lst -Name 'Aenderungen'
    $script:lstChanges = $lst

    $buttons = @(
        @{ Text = "{icon:undo} $(Get-Text 'ChangeUndo')"; Color = $script:Theme.Success; Act = { Undo-SelectedChange } },
        @{ Text = "{icon:skipback} $(Get-Text 'ChangeUndoAll')"; Color = $script:Theme.Error; Act = { Undo-AllChanges } },
        @{ Text = "{icon:refresh} $(Get-Text 'Refresh')"; Color = $script:Theme.BgTertiary; Act = { Update-ChangeList -Force } },
        @{ Text = "{icon:folderopen} $(Get-Text 'ChangeOpen')"; Color = $script:Theme.BgTertiary; Act = {
                $f = Get-ChangeLogPath
                if ($f -and (Test-Path -LiteralPath $f)) { Start-Process notepad.exe -ArgumentList $f }
                else { Write-Log (Get-Text 'ChangeNone') 'INFO' }
            }
        }
    )
    $by = 110
    foreach ($def in $buttons) {
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $def.Text
        $b.Location = New-Object System.Drawing.Point(865, $by)
        $b.Size = New-Object System.Drawing.Size(280, 45)
        $b.Anchor = 'Top,Right'
        $b.BackColor = $def.Color
        $b.ForeColor = $script:Theme.TextWhite
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderSize = 0
        $b.Font = (Get-AppFont -Size 10 -Style 'Bold')
        $b.Cursor = 'Hand'
        $b.Tag = $def.Act
        $b.Add_Click({
                try { & $this.Tag }
                catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
            })
        Set-RoundedRegion -Control $b -Radius 8
        $script:pnlContent.Controls.Add($b)
        $by += 55
    }

    Invoke-Deferred -Action { Update-ChangeList -Force }
}

$script:ViewMap = [ordered]@{
    'Dashboard'      = { Show-Dashboard }
    'Hardware'       = { Show-Hardware }
    'Disk'           = { Show-Disk }
    'Gaming'         = { Show-Gaming }
    'Privacy'        = { Show-Privacy }
    'Defender'       = { Show-Defender }
    'Services'       = { Show-Services }
    'Startup'        = { Show-Startup }
    'ScheduledTasks' = { Show-ScheduledTasks }
    'Updates'        = { Show-Updates }
    'Network'        = { Show-Network }
    'Processes'      = { Show-Processes }
    'Registry'       = { Show-Registry }
    'Benchmark'      = { Show-Benchmark }
    'Tweaks'         = { Show-Tweaks }
    'InputTuning'    = { Show-InputTuning }
    'Repair'         = { Show-RepairCenter }
    'ContextMenu'    = { Show-ContextMenu }
    'Changes'        = { Show-Changes }
    'Settings'       = { Show-Settings }
    'Help'           = { Show-Help }
}

function Set-View {
    param([string]$ViewName)

    # Switching views while a job is running would rebuild the panel under the
    # overlay - ignore it instead of greying out the whole sidebar.
    if ($script:BusyDepth -gt 0) { return }

    if (-not $script:ViewMap.Contains($ViewName)) {
        Write-Log "$(Get-Text 'LogViewUnknown'): $ViewName" 'WARNING'
        return
    }

    # Der Auffrischzeitgeber gehoert zur Prozessansicht - beim Wechsel weg.
    if ($ViewName -ne 'Processes') { Stop-ProcessAutoRefresh }
    $script:Config.CurrentView = $ViewName
    Clear-ContentArea

    $saved = $script:MainForm.Cursor
    # Build the whole view with layout + painting suspended: without this the
    # content panel re-flows and repaints after every single Controls.Add.
    $script:pnlContent.SuspendLayout()
    Suspend-Redraw -Control $script:pnlContent
    try {
        $script:MainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        & $script:ViewMap[$ViewName]
    }
    catch {
        Write-Log "$(Get-Text 'Error') ($ViewName): $($_.Exception.Message)" 'ERROR'
    }
    finally {
        $script:MainForm.Cursor = $saved
        # Any button or label that still starts with an emoji gets its vector
        # icon here - keeps the 54 card definitions free of icon plumbing.
        # Ein Durchgang erledigt Doppelpufferung, Symbole, dunkle Rollbalken,
        # dunkle Eingabefelder und die Laufrichtung technischer Flaechen.
        try { Invoke-ViewPolish -Root $script:pnlContent -Size 16 } catch { }
        Request-ContentReflow -Immediate
        $script:pnlContent.ResumeLayout($true)
        Resume-Redraw -Control $script:pnlContent
        # Noch einmal nach oben: Clear-ContentArea setzt den Bildlauf zwar
        # zurueck, aber WinForms scrollt eine Flaeche automatisch zu dem Kind,
        # das beim Aufbau den Fokus bekommt. Dadurch stand die Ansicht oft um
        # die Hoehe der Ueberschrift verschoben da - der Titel lag unsichtbar
        # hinter der Kopfzeile.
        try { $script:pnlContent.AutoScrollPosition = New-Object System.Drawing.Point(0, 0) } catch { }
    }

    # Erst zeichnen, dann messen.
    Request-CardStates

    # Sidebar highlight
    foreach ($c in $script:pnlSidebarScroll.Controls) {
        if ($c -isnot [System.Windows.Forms.Button] -or $null -eq $c.Tag) { continue }
        $isActive = ($c.Tag.View -eq $ViewName)
        # Inactive buttons must use the sidebar colour, not Transparent:
        # WinForms buttons do not support real transparency.
        # Kraeftigere Pille: 0.28 Akzent hebt sich deutlich von der Leiste ab
        # Jede Zuweisung loest ein Neuzeichnen aus. Bei zwanzig Schaltflaechen
        # waren das bisher achtzig ueberfluessige Zeichenvorgaenge pro Wechsel -
        # deshalb nur noch schreiben, wenn sich der Wert unterscheidet.
        $wasActive = ($c.Tag.Active -eq $true)
        if ($wasActive -eq $isActive -and $c.Tag.Painted -eq $true) { 
            if ($isActive) { try { $script:pnlSidebarScroll.ScrollControlIntoView($c) } catch { } }
            continue
        }
        $c.Tag.Active = $isActive
        $c.Tag.Painted = $true

        $bg = if ($isActive) {
            Get-TintColor -Color $script:Theme.Accent -Base $script:Theme.BgSidebar -Amount 0.28
        }
        else { $script:Theme.BgSidebar }
        if ($c.BackColor -ne $bg) { $c.BackColor = $bg }
        $fg = if ($isActive) { $script:Theme.AccentLight } else { $script:Theme.TextSecondary }
        if ($c.ForeColor -ne $fg) { $c.ForeColor = $fg }
        $c.Font = if ($isActive) { Get-AppFont -Size 10 -Style Bold } else { Get-AppFont -Size 10 }
        $abar = $c.Controls['AccentBar']
        if ($abar -and $abar.Visible -ne $isActive) { $abar.Visible = $isActive }
        if ($c.Tag.Icon) {
            $ic = if ($isActive) { $script:Theme.AccentLight } else { $script:Theme.TextSecondary }
            $img = Get-IconBitmap -Name $c.Tag.Icon -Size 18 -Color $ic
            if ($img -and -not [object]::ReferenceEquals($c.Image, $img)) { $c.Image = $img }
        }
        # Views reached by shortcut can sit below the fold - scroll them in
        if ($isActive) {
            try { $script:pnlSidebarScroll.ScrollControlIntoView($c) } catch { }
        }
    }

    # NOTE: the slide/fade animation used to move the whole content panel at
    # 60 fps - with 30+ child controls that was the main source of stutter when
    # switching views. The view now appears instantly.
}

function Suspend-Redraw {
    # WM_SETREDRAW = 0x000B - stops the control painting while it is rebuilt
    param([System.Windows.Forms.Control]$Control)
    if (-not $Control -or -not $Control.IsHandleCreated) { return }
    try { [void][EBHost.Native]::SendMessage($Control.Handle, 0x000B, [IntPtr]::Zero, [IntPtr]::Zero) } catch { }
}

function Resume-Redraw {
    param([System.Windows.Forms.Control]$Control)
    if (-not $Control -or -not $Control.IsHandleCreated) { return }
    try {
        [void][EBHost.Native]::SendMessage($Control.Handle, 0x000B, [IntPtr]1, [IntPtr]::Zero)
        $Control.Invalidate($true)
    }
    catch { }
}

function Set-DoubleBufferedTree {
    # ListViews and panels flicker badly without double buffering
    param([System.Windows.Forms.Control]$Control)
    if (-not $Control) { return }
    foreach ($c in $Control.Controls) {
        if ($c -is [System.Windows.Forms.ListView] -or $c -is [System.Windows.Forms.Panel] -or
            $c -is [System.Windows.Forms.RichTextBox]) {
            Set-DoubleBuffered -Control $c
        }
        if ($c.Controls.Count -gt 0) { Set-DoubleBufferedTree -Control $c }
    }
}

function Set-Placeholder {
    # EM_SETCUEBANNER - greyed hint inside the box instead of a label beside it
    param([System.Windows.Forms.TextBox]$TextBox, [string]$Text)
    if (-not $TextBox) { return }
    $apply = {
        try { [void][EBHost.Native]::SendMessage($TextBox.Handle, 0x1501, [IntPtr]1, $Text) } catch { }
    }.GetNewClosure()
    if ($TextBox.IsHandleCreated) { & $apply } else { $TextBox.Add_HandleCreated($apply) }
    try { Set-FocusRing -Control $TextBox } catch { }
}

function Remove-Toast {
    param($Toast)
    if (-not $Toast) { return }
    try {
        if ($Toast.Tag -is [hashtable] -and $Toast.Tag.Timer) {
            $Toast.Tag.Timer.Stop()
            $Toast.Tag.Timer.Dispose()
            $Toast.Tag.Timer = $null
        }
    }
    catch { }
    try {
        if ($script:Toasts -and $script:Toasts.Contains($Toast)) { [void]$script:Toasts.Remove($Toast) }
        if ($Toast.Parent) { $Toast.Parent.Controls.Remove($Toast) }
        $Toast.Dispose()
    }
    catch { }
    try { Update-ToastStack } catch { }
}

function Update-ToastStack {
    if (-not $script:Toasts -or -not $script:MainForm -or $script:MainForm.IsDisposed) { return }
    $y = 108
    foreach ($t in @($script:Toasts)) {
        if (-not $t -or $t.IsDisposed) { continue }
        $t.Location = New-Object System.Drawing.Point(($script:MainForm.ClientSize.Width - $t.Width - 26), $y)
        $y += $t.Height + 10
        $t.BringToFront()
    }
}

function Reset-ToastTimer {
    # Setzt die Standzeit einer Karte neu - wird beim Zusammenfassen gebraucht.
    param($Toast, [int]$DurationMs = 3200)
    if (-not $Toast -or $Toast.IsDisposed -or -not ($Toast.Tag -is [hashtable])) { return }
    try {
        if ($Toast.Tag.Timer) {
            $Toast.Tag.Timer.Stop()
            $Toast.Tag.Timer.Interval = [int][math]::Max(1200, $DurationMs)
            $Toast.Tag.Timer.Start()
        }
    }
    catch { }
}

function Clear-Toasts {
    # Alle Karten samt Zeitgebern wegraeumen (Sprachwechsel, Programmende).
    if (-not $script:Toasts) { return }
    $guard = 0
    while ($script:Toasts.Count -gt 0 -and $guard -lt 20) {
        $guard++
        $t = $script:Toasts[0]
        Remove-Toast $t
        if ($script:Toasts.Count -gt 0 -and [object]::ReferenceEquals($script:Toasts[0], $t)) {
            try { [void]$script:Toasts.RemoveAt(0) } catch { break }
        }
    }
}

function Show-Toast {
    # Kurzmeldung oben rechts. Hoechstens drei gleichzeitig - sonst wuerde ein
    # Durchlauf der Auto-Optimierung den halben Bildschirm zustellen. Gleiche
    # oder schnell aufeinander folgende Meldungen werden zu einer Karte mit
    # Zaehler zusammengefasst, statt sich gegenseitig wegzudruecken.
    param(
        [string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR')]
        [string]$Type = 'INFO',
        [int]$DurationMs = 0
    )
    if (-not $script:MainForm -or $script:MainForm.IsDisposed -or -not $Message) { return }
    # Versteckt oder zum Symbol verkleinert: die Karte saehe niemand, und sie
    # wuerde beim Zurueckholen als Altlast im Bild stehen.
    try {
        if (-not $script:MainForm.Visible -or $script:MainForm.WindowState -eq 'Minimized') { return }
    }
    catch { return }
    if (-not $script:Toasts) { $script:Toasts = New-Object 'System.Collections.ArrayList' }

    # Standzeit nach Gewicht: eine Fehlermeldung in 3,2 Sekunden zu lesen und
    # einzuordnen schafft niemand.
    if ($DurationMs -le 0) {
        $DurationMs = switch ($Type) { 'ERROR' { 7000 } 'WARNING' { 5000 } default { 3200 } }
    }

    $now = Get-Date
    if ($script:ToastLast -and (($now - $script:ToastLast).TotalMilliseconds -lt 1500)) {
        $script:ToastBurst = [int]$script:ToastBurst + 1
    }
    else { $script:ToastBurst = 1 }
    $script:ToastLast = $now

    try {
        # ---- Zusammenfassen statt zustellen ---------------------------------
        $top = $null
        if ($script:Toasts.Count -gt 0) { $top = $script:Toasts[$script:Toasts.Count - 1] }
        if ($top -and -not $top.IsDisposed -and ($top.Tag -is [hashtable]) -and $top.Tag.Type -eq $Type) {
            if ($top.Tag.Message -eq $Message -or $script:ToastBurst -ge 3) {
                $top.Tag.Count = [int]$top.Tag.Count + 1
                $top.Tag.Message = $Message
                Reset-ToastTimer -Toast $top -DurationMs $DurationMs
                try { Set-Tip $top $Message } catch { }
                $top.Invalidate()
                return
            }
        }

        # ---- Platz schaffen (mit Notbremse gegen eine Endlosschleife) -------
        $guard = 0
        while ($script:Toasts.Count -ge 3 -and $guard -lt 10) {
            $guard++
            $oldest = $script:Toasts[0]
            Remove-Toast $oldest
            if ($script:Toasts.Count -gt 0 -and [object]::ReferenceEquals($script:Toasts[0], $oldest)) {
                try { [void]$script:Toasts.RemoveAt(0) } catch { break }
            }
        }

        $accent = switch ($Type) {
            'SUCCESS' { $script:Theme.Success }
            'WARNING' { $script:Theme.Warning }
            'ERROR' { $script:Theme.Error }
            default { $script:Theme.Accent }
        }
        $iconName = switch ($Type) {
            'SUCCESS' { 'check' }
            'WARNING' { 'warning' }
            'ERROR' { 'warning' }
            default { 'dot' }
        }

        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(330, 68)
        $card.BackColor = $script:Theme.BgCardHover
        $card.Cursor = [System.Windows.Forms.Cursors]::Hand
        # Ohne Verankerung bliebe die Karte beim Vergroessern des Fensters in
        # der Mitte stehen oder rutschte aus dem Bild.
        $card.Anchor = 'Top,Right'

        $ico = $null
        try { $ico = Get-IconBitmap -Name $iconName -Size 20 -Color $accent } catch { }
        $card.Tag = @{
            Timer   = $null
            Type    = $Type
            Message = $Message
            Count   = 1
            Accent  = $accent
            Icon    = $ico
        }

        $card.Add_Paint({
                param($s, $e)
                try {
                    $tag = $s.Tag
                    if (-not ($tag -is [hashtable])) { return }
                    $g = $e.Graphics
                    $g.SmoothingMode = 'AntiAlias'
                    $g.TextRenderingHint = 'ClearTypeGridFit'
                    $r = $s.ClientRectangle
                    $pen = New-Object -TypeName 'System.Drawing.Pen' -ArgumentList $script:Theme.Border, 1
                    $g.DrawRectangle($pen, 0, 0, ($r.Width - 1), ($r.Height - 1))
                    $pen.Dispose()
                    $br = New-Object -TypeName 'System.Drawing.SolidBrush' -ArgumentList $tag.Accent
                    $g.FillRectangle($br, 0, 0, 4, $r.Height)
                    $br.Dispose()
                    if ($tag.Icon) { $g.DrawImage($tag.Icon, 16, (($r.Height - 20) / 2), 20, 20) }

                    # Zaehler rechts oben, wenn mehrere Meldungen zusammengefasst wurden
                    $textRight = 14
                    if ([int]$tag.Count -gt 1) {
                        $badge = 'x' + [string]$tag.Count
                        $bf = Get-AppFont -Size 8 -Style 'Bold'
                        $bw = [int]$g.MeasureString($badge, $bf).Width + 2
                        $cb = New-Object -TypeName 'System.Drawing.SolidBrush' -ArgumentList $tag.Accent
                        $g.DrawString($badge, $bf, $cb, ($r.Width - $bw - 10), 6)
                        $cb.Dispose()
                        $textRight = 14 + $bw
                    }

                    $sf = New-Object System.Drawing.StringFormat
                    $sf.Trimming = 'EllipsisCharacter'
                    $sf.LineAlignment = 'Center'
                    $tb = New-Object -TypeName 'System.Drawing.SolidBrush' -ArgumentList $script:Theme.TextPrimary
                    $tr = New-Object System.Drawing.RectangleF(46, 6, ($r.Width - 46 - $textRight), ($r.Height - 12))
                    $g.DrawString([string]$tag.Message, (Get-AppFont -Size 9.5), $tb, $tr, $sf)
                    $tb.Dispose()
                    $sf.Dispose()
                }
                catch { }
            })

        $card.Add_Click({ Remove-Toast $this })
        $script:MainForm.Controls.Add($card)
        [void]$script:Toasts.Add($card)
        try { Set-RoundedRegion -Control $card -Radius 10 } catch { }
        try { Set-Tip $card $Message } catch { }
        Update-ToastStack

        $t = New-Object System.Windows.Forms.Timer
        $t.Interval = [int][math]::Max(1200, $DurationMs)
        $card.Tag.Timer = $t
        $t.Add_Tick(({
                    try { $t.Stop() } catch { }
                    Remove-Toast $card
                }).GetNewClosure())
        $t.Start()
    }
    catch { }
}

function Set-FocusRing {
    # Sichtbarer Fokusrahmen: WinForms zeichnet bei TextBoxen von sich aus
    # nichts, der Rahmen wird daher vom Elternelement gemalt.
    param([System.Windows.Forms.Control]$Control)
    if (-not $Control) { return }
    $redraw = ({
            try {
                if ($Control.Parent) {
                    $r = $Control.Bounds
                    $r.Inflate(3, 3)
                    $Control.Parent.Invalidate($r, $false)
                }
            }
            catch { }
        }).GetNewClosure()
    $Control.Add_GotFocus({ & $redraw }.GetNewClosure())
    $Control.Add_LostFocus({ & $redraw }.GetNewClosure())

    $parent = $Control.Parent
    if (-not $parent) { return }
    $parent.Add_Paint(({
                param($s, $e)
                try {
                    if (-not $Control -or $Control.IsDisposed -or -not $Control.Focused) { return }
                    $e.Graphics.SmoothingMode = 'AntiAlias'
                    $b = $Control.Bounds
                    $pen = New-Object System.Drawing.Pen($script:Theme.Accent, 1)
                    $e.Graphics.DrawRectangle($pen, ($b.X - 2), ($b.Y - 2), ($b.Width + 3), ($b.Height + 3))
                    $pen.Dispose()
                }
                catch { }
            }).GetNewClosure())
}

function Set-Tip {
    param([System.Windows.Forms.Control]$Control, [string]$Text)
    if (-not $Control -or -not $Text) { return }
    if (-not $script:ToolTip) {
        $script:ToolTip = New-Object System.Windows.Forms.ToolTip
        $script:ToolTip.InitialDelay = 450
        $script:ToolTip.ReshowDelay = 120
        $script:ToolTip.AutoPopDelay = 12000
        $script:ToolTip.UseAnimation = $true
        $script:ToolTip.UseFading = $true
    }
    $script:ToolTip.SetToolTip($Control, $Text)
}

function Set-LogCollapsed {
    # Klappt die Protokollleiste auf die Kopfzeile zusammen und gibt die
    # gewonnene Hoehe an den Inhaltsbereich weiter. Beide Flaechen haengen an
    # 'Bottom' - nach dem einmaligen Setzen fuehrt die Verankerung jede
    # weitere Groessenaenderung von allein richtig aus.
    param([bool]$Collapsed)
    if (-not $script:LogPanel -or $script:LogPanel.IsDisposed) { return }
    if (-not $script:MainForm -or $script:MainForm.IsDisposed) { return }
    try {
        $script:MainForm.SuspendLayout()
        try {
            foreach ($c in @($script:txtLog, $script:lblPrompt, $script:txtCmd, $script:btnRun)) {
                if ($c -and -not $c.IsDisposed) { $c.Visible = (-not $Collapsed) }
            }
            $h = if ($Collapsed) { 32 } else { [int]$script:LogPanelHeight }
            $top = $script:MainForm.ClientSize.Height - $h
            $script:LogPanel.SetBounds($script:LogPanel.Left, $top, $script:LogPanel.Width, $h)
            if ($script:pnlContent -and -not $script:pnlContent.IsDisposed) {
                $script:pnlContent.Height = [math]::Max(140, $top - $script:pnlContent.Top)
                # Die Sperrschicht ist ein Geschwisterelement des Inhalts und
                # haengt am Fenster, nicht am Inhalt. Ohne diese Zeile bliebe
                # nach dem Einklappen unten ein anklickbarer Streifen frei.
                if ($script:BusyOverlay -and -not $script:BusyOverlay.IsDisposed) {
                    $script:BusyOverlay.SetBounds($script:pnlContent.Left, $script:pnlContent.Top,
                        $script:pnlContent.Width, $script:pnlContent.Height)
                    Set-BusyCardCenter
                }
            }
        }
        finally { $script:MainForm.ResumeLayout($true) }

        $script:Config.LogCollapsed = $Collapsed
        if ($script:btnLogToggle -and -not $script:btnLogToggle.IsDisposed) {
            $glyph = if ($Collapsed) { 'chevronup' } else { 'chevrondown' }
            [void](Set-ControlIcon -Control $script:btnLogToggle -Glyph $glyph -Size 14 -IconOnly)
            $tipKey = if ($Collapsed) { 'TipLogExpand' } else { 'TipLogCollapse' }
            Set-Tip $script:btnLogToggle (Get-Text $tipKey)
        }
        try { Update-CardGrid } catch { }
    }
    catch { }
}

function Update-StaticTips {
    # Kurzhinweise der festen Bedienelemente. Sie entstehen einmal beim
    # Fensterbau - frueher mit deutschem Text, der auch in EN/TR/AR stehen
    # blieb. Jetzt zentral und bei jedem Sprachwechsel erneut gesetzt.
    try {
        if ($script:lblAdmin -and -not $script:lblAdmin.IsDisposed) {
            # Fester Text aus dem Fensterbau - ohne diese Zeile bliebe er beim
            # Sprachwechsel stehen.
            $script:lblAdmin.Text = "{icon:shield} $(Get-Text 'AdminMode')"
            # Genau wie Update-ControlIcons es beim Fensterbau macht: Marke
            # aus dem Text entfernen und das Symbol als Bild setzen.
            [void](Set-ControlIcon -Control $script:lblAdmin -Glyph '{icon:shield}' -Size 16 -StripText)
        }
        # Beschriftungen des festen Rahmens: sie entstehen nur beim
        # Fensterbau und blieben bisher in der alten Sprache stehen.
        Update-LogTitle
        if ($script:txtLogSearch -and -not $script:txtLogSearch.IsDisposed) {
            Set-Placeholder -TextBox $script:txtLogSearch -Text (Get-Text 'LogSearchHint')
            Set-Tip $script:txtLogSearch (Get-Text 'TipLogSearch')
        }
        if ($script:btnCmdRun -and -not $script:btnCmdRun.IsDisposed) {
            $script:btnCmdRun.Text = "{icon:play} $(Get-Text 'CmdRun')"
            [void](Set-ControlIcon -Control $script:btnCmdRun -Glyph '{icon:play}' -Size 16 -StripText)
        }
        if ($script:btnLogClear -and -not $script:btnLogClear.IsDisposed) {
            $script:btnLogClear.Text = "{icon:broom} $(Get-Text 'Clean')"
            [void](Set-ControlIcon -Control $script:btnLogClear -Glyph '{icon:broom}' -Size 16 -StripText)
        }
        # Die Filterreiter der Protokollleiste standen nach einem
        # Sprachwechsel weiter in der alten Sprache - sie entstehen nur einmal.
        try { Update-LogFilterTabs } catch { }
        if ($script:txtCmd -and -not $script:txtCmd.IsDisposed) {
            Set-Placeholder -TextBox $script:txtCmd -Text (Get-Text 'CmdPlaceholder')
            Set-Tip -Control $script:txtCmd -Text (Get-Text 'CmdTabHint')
        }
        if ($script:txtLog -and -not $script:txtLog.IsDisposed) {
            $script:txtLog.RightToLeft = [System.Windows.Forms.RightToLeft]::No
        }
        if ($script:lblFooter -and -not $script:lblFooter.IsDisposed) {
            $script:lblFooter.Text = "  v$($script:Config.Version)   ·   $(Get-Text 'MenuSettings'): $(Get-Text 'KeyCtrl')+9"
        }
        if ($script:btnMaximize) { Set-Tip $script:btnMaximize (Get-Text 'TipMaximize') }
        if ($script:btnMinimize) { Set-Tip $script:btnMinimize (Get-Text 'TipMinimize') }
        if ($script:lblCPU) { Set-Tip $script:lblCPU (Get-Text 'TipCpu') }
        if ($script:lblRAM) { Set-Tip $script:lblRAM (Get-Text 'TipRam') }
        if ($script:lblDisk) { Set-Tip $script:lblDisk "$(Get-Text 'TipDisk') $env:SystemDrive" }
        if ($script:lblNet) { Set-Tip $script:lblNet (Get-Text 'TipNet') }
        if ($script:lblTime) { Set-Tip $script:lblTime (Get-Text 'TipClock') }
        if ($script:txtLog) { Set-Tip $script:txtLog (Get-Text 'TipLogBox') }
        if ($script:btnLogClear) { Set-Tip $script:btnLogClear (Get-Text 'TipLogClear') }
        if ($script:btnLogToggle) {
            $k = if ($script:Config.LogCollapsed) { 'TipLogExpand' } else { 'TipLogCollapse' }
            Set-Tip $script:btnLogToggle (Get-Text $k)
        }
    }
    catch { }
}

function Start-WindowDrag {
    # Native caption drag -> enables Aero Snap (top = maximize, sides = half)
    param([System.Windows.Forms.Control]$Control)
    if (-not $script:MainForm -or $script:MainForm.IsDisposed) { return }
    try {
        [void][EBHost.Native]::ReleaseCapture()
        [void][EBHost.Native]::SendMessage($script:MainForm.Handle, 0xA1, [IntPtr]2, [IntPtr]::Zero)  # WM_NCLBUTTONDOWN / HTCAPTION
    }
    catch { }
}

function Start-WindowResize {
    param([int]$HitTest)
    if (-not $script:MainForm -or $script:MainForm.IsDisposed) { return }
    if ($script:MainForm.WindowState -eq 'Maximized') { return }
    try {
        [void][EBHost.Native]::ReleaseCapture()
        [void][EBHost.Native]::SendMessage($script:MainForm.Handle, 0xA1, [IntPtr]$HitTest, [IntPtr]::Zero)
    }
    catch { }
}

function New-ResizeEdge {
    param([string]$Side, [int]$HitTest, [string]$Cursor, [System.Windows.Forms.Form]$Form)

    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.BackColor = [System.Drawing.Color]::Transparent
    $pnl.Cursor = [System.Windows.Forms.Cursors]::$Cursor
    switch ($Side) {
        'Right' { $pnl.Dock = 'Right'; $pnl.Width = 5 }
        'Bottom' { $pnl.Dock = 'Bottom'; $pnl.Height = 5 }
        'Left' { $pnl.Dock = 'Left'; $pnl.Width = 5 }
        'Top' { $pnl.Dock = 'Top'; $pnl.Height = 5 }
    }
    $pnl.Tag = $HitTest
    $pnl.Add_MouseDown({
            param($s, $e)
            if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { Start-WindowResize -HitTest $s.Tag }
        })
    $Form.Controls.Add($pnl)
    $pnl.BringToFront()
    return $pnl
}

function Get-TintColor {
    # Mischt eine Akzentfarbe mit einer Flaeche. Halbtransparente BackColor
    # wirkt in WinForms je nach Untergrund unterschiedlich - eine vorberechnete
    # Vollfarbe sieht ueberall gleich aus.
    param(
        [System.Drawing.Color]$Color,
        [System.Drawing.Color]$Base,
        [double]$Amount = 0.18
    )
    if ($Amount -lt 0) { $Amount = 0 }
    if ($Amount -gt 1) { $Amount = 1 }
    $r = [int][math]::Round($Base.R + ($Color.R - $Base.R) * $Amount)
    $g = [int][math]::Round($Base.G + ($Color.G - $Base.G) * $Amount)
    $b = [int][math]::Round($Base.B + ($Color.B - $Base.B) * $Amount)
    return [System.Drawing.Color]::FromArgb($r, $g, $b)
}

function New-BrandGradientBrush {
    # Dreistufiger Markenverlauf: hell -> mittel -> tief (bzw. die dunkle
    # Marine-Variante). Faellt bei jedem Fehler auf einen einfachen
    # Zweifarbverlauf zurueck, damit ein Paint-Handler nie abbricht.
    param(
        [System.Drawing.Rectangle]$Rect,
        [switch]$Dark,
        [single]$Angle = 0.0
    )
    if ($Rect.Width -lt 1 -or $Rect.Height -lt 1) { return $null }
    if ($Dark) {
        $c1 = Get-PaletteColor -Name 'Navy'
        $c2 = Get-PaletteColor -Name 'Dark'
        $c3 = Get-PaletteColor -Name 'Base'
    }
    else {
        $c1 = Get-PaletteColor -Name 'Light'
        $c2 = Get-PaletteColor -Name 'Mid'
        $c3 = Get-PaletteColor -Name 'Deep'
    }
    $brush = $null
    try {
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($Rect, $c1, $c3, $Angle)
        $blend = New-Object System.Drawing.Drawing2D.ColorBlend 3
        $blend.Colors = @($c1, $c2, $c3)
        $blend.Positions = @([single]0.0, [single]0.5, [single]1.0)
        $brush.InterpolationColors = $blend
    }
    catch {
        if ($brush) { $brush.Dispose() }
        $brush = $null
        try { $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($Rect, $c1, $c3, $Angle) } catch { $brush = $null }
    }
    return $brush
}

function Set-RoundedRegion {
    # Soft corners for cards and buttons - WinForms has no CornerRadius, so the
    # control gets a rounded region instead of its default rectangle.
    # Cards repeat the same few sizes, so the master region per size/radius is
    # built once and every control gets a cheap Clone of it (a 20 card view
    # used to build 40 GraphicsPath + Region objects on every view switch).
    param([System.Windows.Forms.Control]$Control, [int]$Radius = 10)
    if (-not $Control -or $Control.Width -le 0 -or $Control.Height -le 0) { return }

    $key = "$($Control.Width)x$($Control.Height)x$Radius"
    try {
        if (-not $script:RegionCache.ContainsKey($key)) {
            $path = $null
            try {
                $d = [math]::Max(2, $Radius * 2)
                $w = $Control.Width
                $h = $Control.Height
                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                $path.AddArc(0, 0, $d, $d, 180, 90)
                $path.AddArc(($w - $d), 0, $d, $d, 270, 90)
                $path.AddArc(($w - $d), ($h - $d), $d, $d, 0, 90)
                $path.AddArc(0, ($h - $d), $d, $d, 90, 90)
                $path.CloseFigure()
                $script:RegionCache[$key] = New-Object System.Drawing.Region($path)
            }
            finally { if ($path) { $path.Dispose() } }
        }

        # Clone: every control owns (and disposes) its own Region instance,
        # the cached master stays alive until Stop-AppFonts runs.
        $old = $Control.Region
        $Control.Region = $script:RegionCache[$key].Clone()
        if ($old) { $old.Dispose() }
    }
    catch { }
}

function Enable-DarkTitleTheme {
    # Windows zeichnet Rollbalken im Systemthema - auf einer dunklen Ober-
    # flaeche leuchteten sie hellgrau. Der dunkle App-Modus muss vor dem
    # Erzeugen der Fenster gesetzt werden (uxtheme Ordinal 135, ab Win10 1809).
    try { [void][EBHost.Native]::SetPreferredAppMode(2) } catch { }
}

function Set-DarkScrollbarOne {
    # Setzt fuer rollbare Steuerelemente das dunkle Explorer-Thema. Nur fuer
    # Typen, die ueberhaupt Rollbalken haben - sonst wuerden unnoetig Fenster-
    # handles erzeugt.
    param([System.Windows.Forms.Control]$Control)
    if (-not $Control -or $Control.IsDisposed) { return }
    try {
        $scrollable = ($Control -is [System.Windows.Forms.ListView]) -or
        ($Control -is [System.Windows.Forms.TextBoxBase]) -or
        ($Control -is [System.Windows.Forms.TreeView]) -or
        ($Control -is [System.Windows.Forms.ComboBox]) -or
        (($Control -is [System.Windows.Forms.ScrollableControl]) -and $Control.AutoScroll)
        if ($scrollable) {
            [void][EBHost.Native]::SetWindowTheme($Control.Handle, 'DarkMode_Explorer', $null)
        }
    }
    catch { }
}

function Set-DarkScrollbars {
    param([System.Windows.Forms.Control]$Control, [switch]$Recurse)
    if (-not $Control -or $Control.IsDisposed) { return }
    Set-DarkScrollbarOne -Control $Control
    if ($Recurse -and $Control.HasChildren) {
        foreach ($c in @($Control.Controls)) {
            if ($c -and -not $c.IsDisposed) { Set-DarkScrollbars -Control $c -Recurse }
        }
    }
}

function Set-DarkInputOne {
    # Kontrollkaestchen und Eingabefelder zeichnet Windows im Systemthema -
    # auf dunklem Grund blieben sie weiss. FlatStyle 'Flat' plus dunkles
    # Explorer-Thema kommt einer nativen dunklen Darstellung am naechsten.
    param([System.Windows.Forms.Control]$Control)
    if (-not $Control -or $Control.IsDisposed) { return }
    try {
        if ($Control -is [System.Windows.Forms.CheckBox] -or
            $Control -is [System.Windows.Forms.RadioButton]) {
            $Control.FlatStyle = 'Flat'
            $Control.UseVisualStyleBackColor = $false
            $Control.BackColor = [System.Drawing.Color]::Transparent
            if ($Control.ForeColor -eq [System.Drawing.SystemColors]::ControlText) {
                $Control.ForeColor = $script:Theme.TextPrimary
            }
            if ($Control.IsHandleCreated) {
                [void][EBHost.Native]::SetWindowTheme($Control.Handle, 'DarkMode_Explorer', $null)
            }
            else {
                $Control.Add_HandleCreated({
                        try { [void][EBHost.Native]::SetWindowTheme($this.Handle, 'DarkMode_Explorer', $null) } catch { }
                    })
            }
        }
        elseif ($Control -is [System.Windows.Forms.TextBoxBase]) {
            # FixedSingle zeichnet einen Systemrahmen, der die Hintergrundfarbe
            # ignoriert - ohne Rahmen bleibt die Flaeche durchgehend dunkel.
            if ($Control.BorderStyle -eq 'FixedSingle') { $Control.BorderStyle = 'None' }
            if ($Control.BackColor.GetBrightness() -gt 0.5) {
                $Control.BackColor = $script:Theme.BgTertiary
                $Control.ForeColor = $script:Theme.TextPrimary
            }
        }
    }
    catch { }
}

function Set-DarkInputs {
    param([System.Windows.Forms.Control]$Control, [switch]$Recurse)
    if (-not $Control -or $Control.IsDisposed) { return }
    Set-DarkInputOne -Control $Control
    if ($Recurse -and $Control.HasChildren) {
        foreach ($c in @($Control.Controls)) {
            if ($c -and -not $c.IsDisposed) { Set-DarkInputs -Control $c -Recurse }
        }
    }
}

function ConvertTo-SortKey {
    # Wandelt einen Zellentext in einen Zahlenwert um, damit '9 MB' nicht
    # hinter '80 KB' einsortiert wird. Gibt $null zurueck, wenn es keine Zahl
    # ist - dann wird die Spalte alphabetisch sortiert.
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $t = $Text.Trim()

    $dt = [datetime]::MinValue
    if ($t.Length -ge 8 -and [datetime]::TryParse($t, [ref]$dt)) { return [double]$dt.Ticks }

    $mult = 1.0
    if ($t -match '(?i)TB(/s)?$') { $mult = 1TB }
    elseif ($t -match '(?i)GB(/s)?$') { $mult = 1GB }
    elseif ($t -match '(?i)MB(/s)?$') { $mult = 1MB }
    elseif ($t -match '(?i)KB(/s)?$') { $mult = 1KB }

    $num = ($t -replace '[^0-9,.\-]', '')
    if ([string]::IsNullOrWhiteSpace($num)) { return $null }
    # Deutsche und englische Schreibweise: 1.234,56 und 1,234.56
    if ($num.Contains(',') -and $num.Contains('.')) {
        if ($num.LastIndexOf(',') -gt $num.LastIndexOf('.')) { $num = ($num -replace '\.', '') -replace ',', '.' }
        else { $num = $num -replace ',', '' }
    }
    elseif ($num.Contains(',')) { $num = $num -replace ',', '.' }

    $v = 0.0
    if ([double]::TryParse($num, [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture, [ref]$v)) {
        return ($v * $mult)
    }
    return $null
}

function Get-ListPref {
    # Gemerkte Einstellungen einer Liste (Sortierspalte, Richtung, Breiten).
    param([string]$Name)
    if (-not $script:ListPrefs) { $script:ListPrefs = @{} }
    if ([string]::IsNullOrWhiteSpace($Name)) { return @{ Sort = -1; Asc = $true; Widths = @() } }
    if (-not $script:ListPrefs.ContainsKey($Name)) {
        $script:ListPrefs[$Name] = @{ Sort = -1; Asc = $true; Widths = @(); Titles = $null }
    }
    return $script:ListPrefs[$Name]
}

function Invoke-ListViewSort {
    # Sortiert die Liste nach der im Profil hinterlegten Spalte.
    param([System.Windows.Forms.ListView]$ListView, [string]$Name)
    if (-not $ListView -or $ListView.IsDisposed) { return }
    $pref = Get-ListPref $Name
    $col = [int]$pref.Sort
    if ($col -lt 0 -or $col -ge $ListView.Columns.Count) { return }
    if ($ListView.Items.Count -lt 2) { return }
    try {
        if ($null -eq $pref.Titles) {
            $tt = New-Object 'System.Collections.Generic.List[string]'
            foreach ($c in $ListView.Columns) { $tt.Add(([string]$c.Text -replace '\s*[▲▼]\s*$', '')) }
            $pref.Titles = $tt
        }

        $rows = New-Object 'System.Collections.Generic.List[object]'
        $numCount = 0
        $filled = 0
        foreach ($it in @($ListView.Items)) {
            $txt = ''
            if ($col -lt $it.SubItems.Count) { $txt = [string]$it.SubItems[$col].Text }
            $k = ConvertTo-SortKey $txt
            if (-not [string]::IsNullOrWhiteSpace($txt)) { $filled++ }
            if ($null -ne $k) { $numCount++ }
            $rows.Add([pscustomobject]@{ Item = $it; Text = $txt; Num = $k })
        }

        # Frueher musste JEDE Zelle eine Zahl sein. Eine einzige Zeile mit '-',
        # 'n/v' oder leerem Feld kippte die ganze Spalte auf alphabetisch -
        # dann stand '10 MB' vor '9 MB'. Jetzt entscheidet die Mehrheit, und
        # die Zellen ohne Zahl wandern geschlossen ans Ende.
        $numeric = ($filled -gt 0 -and $numCount -ge [math]::Ceiling($filled * 0.6))
        if ($numeric) {
            $sorted = @($rows | Sort-Object -Property @{ Expression = { $null -eq $_.Num } }, @{ Expression = { $_.Num } }, @{ Expression = { $_.Text } })
        }
        else { $sorted = @($rows | Sort-Object -Property Text) }
        if (-not $pref.Asc) { [array]::Reverse($sorted) }

        $ListView.BeginUpdate()
        try {
            $ListView.Items.Clear()
            foreach ($r in $sorted) { [void]$ListView.Items.Add($r.Item) }
            for ($i = 0; $i -lt $ListView.Columns.Count -and $i -lt $pref.Titles.Count; $i++) {
                $arrow = ''
                if ($i -eq $col) { $arrow = $(if ($pref.Asc) { '  ▲' } else { '  ▼' }) }
                $ListView.Columns[$i].Text = $pref.Titles[$i] + $arrow
            }
        }
        finally { $ListView.EndUpdate() }
    }
    catch { }
}

function Restore-ListViewSort {
    # Nach jedem Neubefuellen: die zuletzt gewaehlte Sortierung wieder
    # herstellen - sonst waere sie nach jeder Aktualisierung verloren.
    param([System.Windows.Forms.ListView]$ListView, [string]$Name)
    try { Invoke-ListViewSort -ListView $ListView -Name $Name } catch { }
}

function Set-ListViewSortable {
    # Klick auf den Spaltenkopf sortiert - beim zweiten Klick umgekehrt.
    # Die Wahl wird in den Einstellungen gemerkt.
    param([System.Windows.Forms.ListView]$ListView, [string]$Name)
    if (-not $ListView -or $ListView.IsDisposed) { return }
    $pref = Get-ListPref $Name
    $pref.Titles = $null

    $ListView.Add_ColumnClick(({
                param($s, $e)
                try {
                    if (-not $s -or $s.IsDisposed) { return }
                    if ([int]$pref.Sort -eq $e.Column) { $pref.Asc = -not $pref.Asc }
                    else { $pref.Sort = [int]$e.Column; $pref.Asc = $true }
                    Invoke-ListViewSort -ListView $s -Name $Name
                }
                catch { }
            }).GetNewClosure())
}

function Get-ListViewText {
    # Zeilen als Text - Tabulator fuer die Zwischenablage, Semikolon fuer CSV.
    param(
        [System.Windows.Forms.ListView]$ListView,
        [switch]$SelectedOnly,
        [string]$Separator = "`t",
        [switch]$WithHeader
    )
    if (-not $ListView -or $ListView.IsDisposed) { return '' }
    $sb = New-Object System.Text.StringBuilder
    $quote = ($Separator -eq ';')

    $fmt = {
        param($cells)
        $out = @()
        foreach ($c in $cells) {
            $v = [string]$c
            if ($quote) { $v = '"' + ($v -replace '"', '""') + '"' }
            $out += $v
        }
        return ($out -join $Separator)
    }

    if ($WithHeader) {
        $h = @()
        foreach ($c in $ListView.Columns) { $h += ([string]$c.Text -replace '\s*[▲▼]\s*$', '') }
        [void]$sb.AppendLine((& $fmt $h))
    }
    $src = if ($SelectedOnly) { @($ListView.SelectedItems) } else { @($ListView.Items) }
    foreach ($it in $src) {
        $cells = @()
        foreach ($si in $it.SubItems) { $cells += [string]$si.Text }
        [void]$sb.AppendLine((& $fmt $cells))
    }
    return $sb.ToString()
}

function Export-ListViewCsv {
    param([System.Windows.Forms.ListView]$ListView, [string]$Name = 'Liste')
    if (-not $ListView -or $ListView.IsDisposed -or $ListView.Items.Count -eq 0) {
        Write-Log (Get-Text 'ExportEmpty') 'WARNING'
        return
    }
    $dlg = $null
    try {
        $dlg = New-Object System.Windows.Forms.SaveFileDialog
        $dlg.Filter = 'CSV (*.csv)|*.csv'
        $dlg.FileName = ('EB_{0}_{1}.csv' -f $Name, (Get-Date -Format 'yyyyMMdd_HHmmss'))
        $dlg.InitialDirectory = [Environment]::GetFolderPath('Desktop')
        if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
        $csv = Get-ListViewText -ListView $ListView -Separator ';' -WithHeader
        # UTF-8 MIT Signatur: Excel zeigt Umlaute sonst als Buchstabensalat.
        $enc = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($dlg.FileName, $csv, $enc)
        Write-Log ((Get-Text 'ExportDone') + ': ' + [System.IO.Path]::GetFileName($dlg.FileName)) 'SUCCESS'
    }
    catch { Write-Log ("Export: " + $_.Exception.Message) 'ERROR' }
    finally { if ($dlg) { $dlg.Dispose() } }
}

function Add-ListContextMenu {
    # Rechtsklick: Zeile kopieren / alles kopieren / als CSV exportieren.
    # Zusaetzlich Strg+C auf der Liste.
    param([System.Windows.Forms.ListView]$ListView, [string]$Name = 'Liste')
    if (-not $ListView -or $ListView.IsDisposed) { return }
    try {
        $menu = New-Object System.Windows.Forms.ContextMenuStrip
        $menu.BackColor = $script:Theme.BgTertiary
        $menu.ForeColor = $script:Theme.TextPrimary
        $menu.ShowImageMargin = $false
        $menu.Font = (Get-AppFont -Size 9)

        $miCopy = $menu.Items.Add((Get-Text 'CtxCopy'))
        $miAll = $menu.Items.Add((Get-Text 'CtxCopyAll'))
        $miCsv = $menu.Items.Add((Get-Text 'CtxExport'))
        foreach ($mi in @($miCopy, $miAll, $miCsv)) {
            $mi.BackColor = $script:Theme.BgTertiary
            $mi.ForeColor = $script:Theme.TextPrimary
        }

        $miCopy.Add_Click(({
                    try {
                        $t = Get-ListViewText -ListView $ListView -SelectedOnly
                        if ($t) { [System.Windows.Forms.Clipboard]::SetText($t) }
                    }
                    catch { }
                }).GetNewClosure())
        $miAll.Add_Click(({
                    try {
                        $t = Get-ListViewText -ListView $ListView -WithHeader
                        if ($t) { [System.Windows.Forms.Clipboard]::SetText($t) }
                    }
                    catch { }
                }).GetNewClosure())
        $miCsv.Add_Click(({ Export-ListViewCsv -ListView $ListView -Name $Name }).GetNewClosure())

        $ListView.ContextMenuStrip = $menu
        $ListView.Add_KeyDown(({
                    param($s, $e)
                    try {
                        if ($e.Control -and $e.KeyCode -eq [System.Windows.Forms.Keys]::C) {
                            $t = Get-ListViewText -ListView $s -SelectedOnly
                            if ($t) { [System.Windows.Forms.Clipboard]::SetText($t) }
                            $e.SuppressKeyPress = $true
                        }
                    }
                    catch { }
                }))
        $ListView.Add_Disposed(({ try { $menu.Dispose() } catch { } }).GetNewClosure())
    }
    catch { }
}

function Set-ListViewColumnFit {
    # Verteilt die freie Breite auf die Spalten, damit rechts kein leerer
    # Streifen bleibt und die letzte Spalte nie abgeschnitten wird.
    param(
        [System.Windows.Forms.ListView]$ListView,
        [int[]]$Weights = $null,
        [string]$Name
    )
    if (-not $ListView -or $ListView.IsDisposed) { return }
    $n = $ListView.Columns.Count
    if ($n -eq 0) { return }

    # Hat der Benutzer eine Spalte selbst gezogen, gilt seine Breite - die
    # automatische Verteilung haelt sich dann heraus und die Breiten landen
    # in den Einstellungen.
    $pref = Get-ListPref $Name
    $state = @{ Manual = $false; Busy = $false }
    if ($pref.Widths -and @($pref.Widths).Count -eq $n) {
        try {
            $state.Busy = $true
            for ($i = 0; $i -lt $n; $i++) {
                $wv = [int]@($pref.Widths)[$i]
                if ($wv -ge 30) { $ListView.Columns[$i].Width = $wv }
            }
            $state.Manual = $true
        }
        catch { }
        finally { $state.Busy = $false }
    }

    # Die Ausgangsbreiten werden EINMAL gemerkt. Wuerde man bei jedem Lauf die
    # aktuelle Breite als Mindestmass nehmen, wandern die Spalten mit jeder
    # Groessenaenderung weiter - genau das passiert bei der naiven Variante.
    $mins = New-Object 'System.Collections.Generic.List[int]'
    for ($i = 0; $i -lt $n; $i++) {
        $mins.Add([int][math]::Max(60, $ListView.Columns[$i].Width))
    }
    $wts = New-Object 'System.Collections.Generic.List[int]'
    for ($i = 0; $i -lt $n; $i++) {
        if ($Weights -and $Weights.Count -eq $n) { $wts.Add([int][math]::Max(0, $Weights[$i])) }
        else { $wts.Add(1) }
    }
    $wsum = 0
    foreach ($x in $wts) { $wsum += $x }
    if ($wsum -le 0) { $wsum = $n }

    $fit = ({
            param($s, $e)
            try {
                if (-not $s -or $s.IsDisposed) { return }
                if ($state.Manual) { return }
                if ($s.Columns.Count -ne $mins.Count) { return }
                $state.Busy = $true
                $avail = [int][math]::Max(160, ($s.ClientSize.Width - 4))
                $total = 0
                foreach ($m in $mins) { $total += $m }
                $surplus = [int][math]::Max(0, ($avail - $total))
                $used = 0
                for ($i = 0; $i -lt ($mins.Count - 1); $i++) {
                    $grow = [int][math]::Floor($surplus * $wts[$i] / $wsum)
                    $s.Columns[$i].Width = $mins[$i] + $grow
                    $used += $s.Columns[$i].Width
                }
                $last = $mins.Count - 1
                $s.Columns[$last].Width = [int][math]::Max($mins[$last], ($avail - $used))
            }
            catch { }
            finally { $state.Busy = $false }
        }).GetNewClosure()

    if (-not $state.Manual) { & $fit $ListView $null }
    $ListView.Add_ClientSizeChanged($fit)

    $ListView.Add_ColumnWidthChanged(({
                param($s, $e)
                try {
                    if ($state.Busy -or -not $s -or $s.IsDisposed) { return }
                    $state.Manual = $true
                    $w = New-Object 'System.Collections.Generic.List[int]'
                    foreach ($c in $s.Columns) { $w.Add([int]$c.Width) }
                    $pref.Widths = $w.ToArray()
                }
                catch { }
            }).GetNewClosure())
}

function Resize-ContentChildren {
    # Jedes Kind, dessen rechter Rand ueber den Inhaltsbereich hinausragt,
    # erzeugt einen waagerechten Rollbalken. Rechts verankerte Elemente folgen
    # dem Panel ohnehin - nur die fest gesetzten werden begrenzt.
    if (-not $script:pnlContent -or $script:pnlContent.IsDisposed) { return }
    $w = $script:pnlContent.ClientSize.Width
    if ($w -le 0) { return }
    foreach ($c in @($script:pnlContent.Controls)) {
        if (-not $c -or $c.IsDisposed) { continue }
        try {
            if ($c.Anchor -band [System.Windows.Forms.AnchorStyles]::Right) { continue }
            $maxW = $w - $c.Location.X - 25
            if ($maxW -ge 120 -and $c.Width -gt $maxW) { $c.Width = [int]$maxW }
        }
        catch { }
    }
}

function Set-DoubleBuffered {
    # DoubleBuffered is a PROTECTED property - assigning it directly
    # ($form.DoubleBuffered = $true) raises "property cannot be found" in
    # PowerShell. Reflection is the supported way and also kills the flicker
    # in the scrolling content panel.
    param([System.Windows.Forms.Control]$Control)

    if (-not $Control) { return }
    try {
        $prop = [System.Windows.Forms.Control].GetProperty(
            'DoubleBuffered',
            [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($Control, $true, $null) }
    }
    catch { }
}

function New-MainForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$($script:Config.AppName) v$($script:Config.Version)"
    $form.ClientSize = New-Object System.Drawing.Size(1500, 880)
    $form.MinimumSize = New-Object System.Drawing.Size(1200, 700)
    # No MaximumSize: large/4K displays must not be clipped
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'None'

    # Restore the geometry of the last session, but only if it is still on a
    # screen that exists right now (monitor unplugged / resolution changed)
    if ($script:Config.RememberWin -and $script:Config.WinBounds) {
        try {
            $b = $script:Config.WinBounds
            $rect = New-Object System.Drawing.Rectangle($b.X, $b.Y, $b.Width, $b.Height)
            $visible = $false
            foreach ($scr in [System.Windows.Forms.Screen]::AllScreens) {
                if ($scr.WorkingArea.IntersectsWith($rect)) { $visible = $true; break }
            }
            if ($visible) {
                $form.StartPosition = 'Manual'
                $form.Location = New-Object System.Drawing.Point($b.X, $b.Y)
                $form.ClientSize = New-Object System.Drawing.Size($b.Width, $b.Height)
            }
        }
        catch { }
    }
    # 1500 x 880 ist auf einem 1440er Laptopbildschirm breiter als der Desktop -
    # das Fenster ragte rechts hinaus, Administrator-Hinweis und die rechte
    # Kartenspalte waren abgeschnitten. Darum auf die Arbeitsflaeche begrenzen.
    try {
        $wa = ([System.Windows.Forms.Screen]::FromPoint([System.Windows.Forms.Cursor]::Position)).WorkingArea
        $minW = [math]::Min(1200, [math]::Max(900, $wa.Width - 40))
        $minH = [math]::Min(700, [math]::Max(600, $wa.Height - 40))
        $form.MinimumSize = New-Object System.Drawing.Size($minW, $minH)

        $cw = [math]::Min($form.ClientSize.Width, ($wa.Width - 20))
        $ch = [math]::Min($form.ClientSize.Height, ($wa.Height - 20))
        if ($cw -lt $minW) { $cw = $minW }
        if ($ch -lt $minH) { $ch = $minH }
        if ($cw -ne $form.ClientSize.Width -or $ch -ne $form.ClientSize.Height) {
            $form.ClientSize = New-Object System.Drawing.Size($cw, $ch)
        }
        if ($form.StartPosition -eq 'Manual') {
            $px = [math]::Max($wa.X, [math]::Min($form.Location.X, ($wa.Right - $form.Width)))
            $py = [math]::Max($wa.Y, [math]::Min($form.Location.Y, ($wa.Bottom - $form.Height)))
            $form.Location = New-Object System.Drawing.Point($px, $py)
        }
    }
    catch { }

    $form.BackColor = $script:Theme.BgPrimary
    $form.KeyPreview = $true
    Set-DoubleBuffered -Control $form
    try { $form.Icon = [System.Drawing.SystemIcons]::Application } catch { }
    $script:MainForm = $form

    # ---- Title bar ------------------------------------------------------------
    $bar = New-Object System.Windows.Forms.Panel
    $bar.Location = New-Object System.Drawing.Point(0, 0)
    $bar.Size = New-Object System.Drawing.Size(1500, 40)
    $bar.BackColor = $script:Theme.BgHeader
    $bar.Anchor = 'Top,Left,Right'
    $form.Controls.Add($bar)
    Set-DoubleBuffered -Control $bar

    $barLine = New-Object System.Windows.Forms.Panel
    $barLine.Dock = 'Bottom'
    $barLine.Height = 2
    $barLine.BackColor = [System.Drawing.Color]::Transparent
    $barLine.Add_Paint({
            param($s, $e)
            $br = $null
            try {
                $rect = New-Object System.Drawing.Rectangle(0, 0, [math]::Max(1, $s.Width), $s.Height)
                $br = New-BrandGradientBrush -Rect $rect
                if ($br) { $e.Graphics.FillRectangle($br, $rect) }
            }
            catch { }
            finally { if ($br) { $br.Dispose() } }
        })
    $bar.Controls.Add($barLine)

    $lblBar = New-Object System.Windows.Forms.Label
    $lblBar.Text = "  {icon:bolt}  $($script:Config.AppName)  ·  v$($script:Config.Version)"
    $lblBar.Font = (Get-AppFont -Size 10 -Style 'Bold')
    $lblBar.ForeColor = $script:Theme.TextSecondary
    $lblBar.Location = New-Object System.Drawing.Point(12, 10)
    # Fixed width instead of AutoSize: the three window buttons own the last
    # 150 px, a long title used to run underneath them.
    $lblBar.AutoSize = $false
    $lblBar.Size = New-Object System.Drawing.Size(($bar.Width - 170), 20)
    $lblBar.TextAlign = 'MiddleLeft'
    $lblBar.AutoEllipsis = $true
    $lblBar.Anchor = 'Top,Left,Right'
    $lblBar.BackColor = [System.Drawing.Color]::Transparent
    $bar.Controls.Add($lblBar)

    # Native caption drag: gives us Aero Snap (drag to top = maximize,
    # drag to a side = half screen) instead of the old manual coordinate math.
    $dragDown = {
        param($s, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { Start-WindowDrag -Control $s }
    }
    $dblClick = {
        $script:MainForm.WindowState = if ($script:MainForm.WindowState -eq 'Maximized') { 'Normal' } else { 'Maximized' }
    }
    $bar.Add_MouseDown($dragDown);    $bar.Add_DoubleClick($dblClick)
    $lblBar.Add_MouseDown($dragDown); $lblBar.Add_DoubleClick($dblClick)

    # Window buttons - anchored right so they follow resizing
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = ''
    $btnClose.Tag = 'close'
    $btnClose.Size = New-Object System.Drawing.Size(46, 40)
    $btnClose.Location = New-Object System.Drawing.Point(($bar.Width - 46), 0)
    $btnClose.Anchor = 'Top,Right'
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 0
    $btnClose.BackColor = $script:Theme.BgHeader
    $btnClose.ForeColor = $script:Theme.TextSecondary
    $btnClose.Font = (Get-AppFont -Size 11)
    $btnClose.Cursor = 'Hand'
    $btnClose.TabStop = $false
    [void](Set-ControlIcon -Control $btnClose -Glyph 'close' -Size 14 -Color $script:Theme.TextSecondary -IconOnly)
    $btnClose.Add_MouseEnter({
            $this.BackColor = $script:Theme.Error
            $this.ForeColor = [System.Drawing.Color]::White
            $img = Get-IconBitmap -Name 'close' -Size 14 -Color ([System.Drawing.Color]::White)
            if ($img) { $this.Image = $img }
        })
    $btnClose.Add_MouseLeave({
            $this.BackColor = $script:Theme.BgHeader
            $this.ForeColor = $script:Theme.TextSecondary
            $img = Get-IconBitmap -Name 'close' -Size 14 -Color $script:Theme.TextSecondary
            if ($img) { $this.Image = $img }
        })
    $btnClose.Add_Click({ $script:MainForm.Close() })
    $bar.Controls.Add($btnClose)
    Set-Tip $btnClose "$(Get-Text 'Close')  ($(Get-Text 'KeyCtrl')+Q)"

    $btnMax = New-Object System.Windows.Forms.Button
    $btnMax.Text = ''
    $btnMax.Tag = 'square'
    $btnMax.Size = New-Object System.Drawing.Size(46, 40)
    $btnMax.Location = New-Object System.Drawing.Point(($bar.Width - 92), 0)
    $btnMax.Anchor = 'Top,Right'
    $btnMax.FlatStyle = 'Flat'
    $btnMax.FlatAppearance.BorderSize = 0
    $btnMax.BackColor = $script:Theme.BgHeader
    $btnMax.ForeColor = $script:Theme.TextSecondary
    $btnMax.Font = (Get-AppFont -Size 11)
    $btnMax.Cursor = 'Hand'
    $btnMax.TabStop = $false
    [void](Set-ControlIcon -Control $btnMax -Glyph 'square' -Size 14 -Color $script:Theme.TextSecondary -IconOnly)
    $btnMax.Add_MouseEnter({
            $this.BackColor = $script:Theme.BgTertiary
            $img = Get-IconBitmap -Name ([string]$this.Tag) -Size 14 -Color ([System.Drawing.Color]::White)
            if ($img) { $this.Image = $img }
        })
    $btnMax.Add_MouseLeave({
            $this.BackColor = $script:Theme.BgHeader
            $img = Get-IconBitmap -Name ([string]$this.Tag) -Size 14 -Color $script:Theme.TextSecondary
            if ($img) { $this.Image = $img }
        })
    $btnMax.Add_Click({
            $script:MainForm.WindowState = if ($script:MainForm.WindowState -eq 'Maximized') { 'Normal' } else { 'Maximized' }
        })
    $bar.Controls.Add($btnMax)
    $script:btnMaximize = $btnMax

    $btnMin = New-Object System.Windows.Forms.Button
    $btnMin.Text = ''
    $btnMin.Tag = 'minus'
    $btnMin.Size = New-Object System.Drawing.Size(46, 40)
    $btnMin.Location = New-Object System.Drawing.Point(($bar.Width - 138), 0)
    $btnMin.Anchor = 'Top,Right'
    $btnMin.FlatStyle = 'Flat'
    $btnMin.FlatAppearance.BorderSize = 0
    $btnMin.BackColor = $script:Theme.BgHeader
    $btnMin.ForeColor = $script:Theme.TextSecondary
    $btnMin.Font = (Get-AppFont -Size 11)
    $btnMin.Cursor = 'Hand'
    $btnMin.TabStop = $false
    [void](Set-ControlIcon -Control $btnMin -Glyph 'minus' -Size 14 -IconOnly)
    $btnMin.Add_MouseEnter({
            $this.BackColor = $script:Theme.BgTertiary
            $img = Get-IconBitmap -Name 'minus' -Size 14 -Color ([System.Drawing.Color]::White)
            if ($img) { $this.Image = $img }
        })
    $btnMin.Add_MouseLeave({
            $this.BackColor = $script:Theme.BgHeader
            $img = Get-IconBitmap -Name 'minus' -Size 14 -Color $script:Theme.TextSecondary
            if ($img) { $this.Image = $img }
        })
    $btnMin.Add_Click({
            if ($script:Config.MinimizeToTray -and $script:TrayIcon) {
                $script:MainForm.Hide()
                if (-not $script:TrayHintShown) {
                    $script:TrayHintShown = $true
                    Show-TrayBalloon -Text (Get-Text 'TrayHint')
                }
            }
            else { $script:MainForm.WindowState = 'Minimized' }
        })
    $bar.Controls.Add($btnMin)
    $script:btnMinimize = $btnMin

    # Keep the maximize glyph in sync with the real window state
    $form.Add_Resize({
            # Add_Resize feuert bei jedem Mausruckeln. Das Symbol haengt aber
            # nur am Fensterzustand - ohne diesen Vergleich lief die ganze
            # Symbolarbeit waehrend des Ziehens dauerhaft mit.
            $stateNow = [string]$script:MainForm.WindowState
            if ($script:LastWindowState -eq $stateNow) { return }
            $script:LastWindowState = $stateNow
            if ($script:btnMaximize -and -not $script:btnMaximize.IsDisposed) {
                $glyph = if ($script:MainForm.WindowState -eq 'Maximized') { 'restore' } else { 'square' }
                $col = if ($script:btnMaximize.BackColor -eq $script:Theme.BgHeader) {
                    $script:Theme.TextSecondary
                }
                else { [System.Drawing.Color]::White }
                $img = Get-IconBitmap -Name $glyph -Size 14 -Color $col
                if ($img) {
                    $script:btnMaximize.Image = $img
                    $script:btnMaximize.Text = ''
                    $script:btnMaximize.ImageAlign = [System.Drawing.ContentAlignment]::MiddleCenter
                }
                # Symbolname ins Tag, damit Hover dasselbe Symbol einfaerbt
                $script:btnMaximize.Tag = $glyph
            }
        })

    # ---- Sidebar --------------------------------------------------------------
    $sidebar = New-Object System.Windows.Forms.Panel
    $sidebar.Location = New-Object System.Drawing.Point(0, 40)
    $sidebar.Size = New-Object System.Drawing.Size(250, 840)
    $sidebar.BackColor = $script:Theme.BgSidebar
    $sidebar.Anchor = 'Top,Bottom,Left'
    $form.Controls.Add($sidebar)
    Set-DoubleBuffered -Control $sidebar

    $scroll = New-Object System.Windows.Forms.Panel
    $scroll.Location = New-Object System.Drawing.Point(0, 0)
    $scroll.Size = New-Object System.Drawing.Size(250, 802)
    $scroll.BackColor = $script:Theme.BgSidebar
    $scroll.AutoScroll = $true
    # Vertical only. WinForms would otherwise show a horizontal bar as soon as
    # the vertical one appears and steals 17 px of width.
    $scroll.HorizontalScroll.Maximum = 0
    $scroll.HorizontalScroll.Visible = $false
    $scroll.AutoScrollMargin = New-Object System.Drawing.Size(0, 10)
    $scroll.Anchor = 'Top,Bottom,Left,Right'
    $sidebar.Controls.Add($scroll)
    $script:pnlSidebarScroll = $scroll

    $lblFoot = New-Object System.Windows.Forms.Label
    $lblFoot.Text = "  v$($script:Config.Version)   ·   $(Get-Text 'MenuSettings'): $(Get-Text 'KeyCtrl')+9"
    $script:lblFooter = $lblFoot
    $lblFoot.Font = (Get-AppFont -Size 8)
    $lblFoot.ForeColor = $script:Theme.TextMuted
    $lblFoot.BackColor = $script:Theme.BgSidebar
    $lblFoot.TextAlign = 'MiddleLeft'
    $lblFoot.Location = New-Object System.Drawing.Point(0, 806)
    $lblFoot.Size = New-Object System.Drawing.Size(250, 34)
    $lblFoot.Anchor = 'Bottom,Left,Right'
    $sidebar.Controls.Add($lblFoot)

    $top = 6
    $top = New-SidebarButton -TextKey 'CatMain' -Top $top -IsCategory $true
    $top = New-SidebarButton -TextKey 'MenuDashboard' -Icon 'home' -ViewTag 'Dashboard' -Top $top
    $top = New-SidebarButton -TextKey 'MenuHardware' -Icon 'monitor' -ViewTag 'Hardware' -Top $top
    $top = New-SidebarButton -TextKey 'MenuBenchmark' -Icon 'chart' -ViewTag 'Benchmark' -Top $top

    $top = New-SidebarButton -TextKey 'CatOptimize' -Top ($top + 6) -IsCategory $true
    $top = New-SidebarButton -TextKey 'MenuDisk' -Icon 'save' -ViewTag 'Disk' -Top $top
    $top = New-SidebarButton -TextKey 'MenuGaming' -Icon 'gamepad' -ViewTag 'Gaming' -Top $top
    $top = New-SidebarButton -TextKey 'MenuTweaks' -Icon 'wrench' -ViewTag 'Tweaks' -Top $top
    $top = New-SidebarButton -TextKey 'MenuInput' -Icon 'mouse' -ViewTag 'InputTuning' -Top $top

    $top = New-SidebarButton -TextKey 'CatSecurity' -Top ($top + 6) -IsCategory $true
    $top = New-SidebarButton -TextKey 'MenuPrivacy' -Icon 'lock' -ViewTag 'Privacy' -Top $top
    $top = New-SidebarButton -TextKey 'MenuDefender' -Icon 'shield' -ViewTag 'Defender' -Top $top
    $top = New-SidebarButton -TextKey 'MenuUpdates' -Icon 'refresh' -ViewTag 'Updates' -Top $top

    $top = New-SidebarButton -TextKey 'CatSystem' -Top ($top + 6) -IsCategory $true
    $top = New-SidebarButton -TextKey 'MenuServices' -Icon 'gear' -ViewTag 'Services' -Top $top
    $top = New-SidebarButton -TextKey 'MenuStartup' -Icon 'rocket' -ViewTag 'Startup' -Top $top
    $top = New-SidebarButton -TextKey 'MenuTasks' -Icon 'calendar' -ViewTag 'ScheduledTasks' -Top $top
    $top = New-SidebarButton -TextKey 'MenuProcesses' -Icon 'bars' -ViewTag 'Processes' -Top $top
    $top = New-SidebarButton -TextKey 'MenuNetwork' -Icon 'globe' -ViewTag 'Network' -Top $top

    $top = New-SidebarButton -TextKey 'CatAdvanced' -Top ($top + 6) -IsCategory $true
    $top = New-SidebarButton -TextKey 'MenuRegistry' -Icon 'folders' -ViewTag 'Registry' -Top $top
    $top = New-SidebarButton -TextKey 'MenuRepair' -Icon 'wrench' -ViewTag 'Repair' -Top $top
    $top = New-SidebarButton -TextKey 'MenuContext' -Icon 'note' -ViewTag 'ContextMenu' -Top $top
    $top = New-SidebarButton -TextKey 'MenuChanges' -Icon 'undo' -ViewTag 'Changes' -Top $top
    $top = New-SidebarButton -TextKey 'MenuSettings' -Icon 'gear' -ViewTag 'Settings' -Top $top
    $top = New-SidebarButton -TextKey 'MenuHelp' -Icon 'help' -ViewTag 'Help' -Top $top

    # ---- Header with live mini stats -----------------------------------------
    $header = New-Object System.Windows.Forms.Panel
    $header.Location = New-Object System.Drawing.Point(250, 40)
    $header.Size = New-Object System.Drawing.Size(1250, 58)
    $header.BackColor = $script:Theme.BgSecondary
    $header.Anchor = 'Top,Left,Right'
    $form.Controls.Add($header)
    Set-DoubleBuffered -Control $header
    $script:pnlHeader = $header
    $header.Add_ClientSizeChanged({ Update-HeaderLayout })

    $mkStat = {
        param($text, $x, $color, $w = 100)
        $l = New-Object System.Windows.Forms.Label
        $l.Text = $text
        $l.Font = (Get-AppFont -Size 10 -Style 'Bold')
        $l.ForeColor = $color
        $l.Location = New-Object System.Drawing.Point($x, 18)
        $l.Size = New-Object System.Drawing.Size($w, 24)
        $l.BackColor = [System.Drawing.Color]::Transparent
        $l.AutoEllipsis = $true
        # Vector icon instead of the emoji prefix; the label grows by the icon
        # width so "Net: 12.34 MB/s" is no longer cut off.
        $g = Get-LeadingGlyph $text
        if ($g) { [void](Set-ControlIcon -Control $l -Glyph $g -Size 16 -Color $color -StripText) }
        return $l
    }

    # Die Kopfzeile ist 1250 px breit (Fenster 1500 minus Seitenleiste 250),
    # nicht 1500 - mit den alten Breiten fiel das letzte Element immer heraus.
    # Die beiden widerspruechlichen lblNet.Size-Zeilen sind entfallen.
    $script:lblCPU = & $mkStat '{icon:cpu} CPU: --%' 20 $script:Theme.Cyan 100
    $script:lblRAM = & $mkStat '{icon:cpu} RAM: --%' 200 $script:Theme.Purple 100
    $script:lblDisk = & $mkStat '{icon:save} Disk: --%' 380 $script:Theme.Warning 110
    $script:lblNet = & $mkStat '{icon:globe} Net: -- MB/s' 560 $script:Theme.Success 150
    $script:lblTime = & $mkStat '{icon:clock} --:--:--' 760 $script:Theme.TextSecondary 95
    $script:lblLogPath = & $mkStat '{icon:note} ---' 940 $script:Theme.TextMuted 150
    $script:lblLogPath.Cursor = 'Hand'
    $script:lblLogPath.Add_Click({ Open-SessionLog })
    foreach ($l in @($script:lblCPU, $script:lblRAM, $script:lblDisk, $script:lblNet, $script:lblTime, $script:lblLogPath)) {
        $header.Controls.Add($l)
    }
    Update-LogPathLabel

    # Tiny live graphs right next to the CPU and RAM readouts
    $mkSpark = {
        param($x, $key, $color)
        $sp = New-Object System.Windows.Forms.Panel
        $sp.Location = New-Object System.Drawing.Point($x, 21)
        $sp.Size = New-Object System.Drawing.Size(64, 18)
        $sp.BackColor = [System.Drawing.Color]::Transparent
        $sp.Tag = @{ Key = $key; Color = $color }
        Set-DoubleBuffered -Control $sp
        $sp.Add_Paint({
                param($s, $e)
                Invoke-SparklineDraw -e $e -History $script:SparklineHistory[$s.Tag.Key] -Color $s.Tag.Color `
                    -Rect (New-Object System.Drawing.Rectangle(0, 0, $s.Width, $s.Height))
            })
        $header.Controls.Add($sp)
        $sp.BringToFront()
        return $sp
    }
    $script:SparkCPU = & $mkSpark 124 'CPU' $script:Theme.Cyan
    $script:SparkRAM = & $mkSpark 304 'RAM' $script:Theme.Purple

    # Hairline under the header separates it from the content area
    $headLine = New-Object System.Windows.Forms.Panel
    $headLine.Dock = 'Bottom'
    $headLine.Height = 1
    $headLine.BackColor = $script:Theme.BgTertiary
    $header.Controls.Add($headLine)

    $script:lblStatus = New-Object System.Windows.Forms.Label
    $script:lblStatus.Text = ''
    $script:lblStatus.Font = (Get-AppFont -Size 9)
    $script:lblStatus.ForeColor = $script:Theme.TextMuted
    $script:lblStatus.Location = New-Object System.Drawing.Point(940, 20)
    $script:lblStatus.Size = New-Object System.Drawing.Size(130, 22)
    $script:lblStatus.TextAlign = 'MiddleRight'
    $script:lblStatus.AutoEllipsis = $true
    $script:lblStatus.Anchor = 'Top,Left'
    $script:lblStatus.BackColor = [System.Drawing.Color]::Transparent
    $script:lblStatus.AutoEllipsis = $true
    $header.Controls.Add($script:lblStatus)


    $lblAdmin = New-Object System.Windows.Forms.Label
    $lblAdmin.Text = "{icon:shield} $(Get-Text 'AdminMode')"
    $lblAdmin.Font = (Get-AppFont -Size 9 -Style 'Bold')
    $lblAdmin.ForeColor = $script:Theme.Success
    $lblAdmin.Location = New-Object System.Drawing.Point(1080, 20)
    $lblAdmin.Size = New-Object System.Drawing.Size(150, 22)
    $lblAdmin.TextAlign = 'MiddleRight'
    # Positioned by Update-HeaderLayout, not by anchoring
    $lblAdmin.Anchor = 'Top,Left'
    $lblAdmin.BackColor = [System.Drawing.Color]::Transparent
    $header.Controls.Add($lblAdmin)
    $script:lblAdmin = $lblAdmin

    Update-HeaderLayout

    # ---- Content area ---------------------------------------------------------
    $content = New-Object System.Windows.Forms.Panel
    $content.Location = New-Object System.Drawing.Point(250, 98)
    $content.Size = New-Object System.Drawing.Size(1250, 622)
    $content.BackColor = $script:Theme.BgPrimary
    $content.AutoScroll = $true
    # Nur senkrecht scrollen; unten 24 px Luft, damit die letzte Kartenreihe
    # nicht direkt an der Protokollleiste klebt.
    $content.HorizontalScroll.Maximum = 0
    $content.HorizontalScroll.Visible = $false
    $content.AutoScrollMargin = New-Object System.Drawing.Size(0, 24)
    $content.Anchor = 'Top,Bottom,Left,Right'
    $form.Controls.Add($content)
    Set-DoubleBuffered -Control $content
    $script:pnlContent = $content
    $content.Add_ClientSizeChanged({ Request-ContentReflow })

    # ---- Log panel ------------------------------------------------------------
    $logPanel = New-Object System.Windows.Forms.Panel
    $logPanel.Location = New-Object System.Drawing.Point(250, 722)
    $logPanel.Size = New-Object System.Drawing.Size(1250, 158)
    $logPanel.BackColor = $script:Theme.BgSecondary
    $logPanel.Anchor = 'Bottom,Left,Right'
    $form.Controls.Add($logPanel)
    $script:LogPanel = $logPanel
    Set-DoubleBuffered -Control $logPanel

    $lblLog = New-Object System.Windows.Forms.Label
    # UseMnemonic aus: sonst verschluckt WinForms ein '&' im Titel.
    $lblLog.UseMnemonic = $false
    $lblLog.Text = "{icon:note} $(Get-Text 'LogPanelTitle')"
    $script:lblLogTitle = $lblLog
    $lblLog.Font = (Get-AppFont -Size 9 -Style 'Bold')
    $lblLog.ForeColor = $script:Theme.TextMuted
    $lblLog.Location = New-Object System.Drawing.Point(14, 6)
    $lblLog.AutoSize = $true
    $lblLog.BackColor = [System.Drawing.Color]::Transparent
    $lblLog.Cursor = 'Hand'
    $lblLog.Add_DoubleClick({ Set-LogCollapsed -Collapsed (-not $script:Config.LogCollapsed) })
    $logPanel.Controls.Add($lblLog)

    # ---- Filterreiter oben rechts --------------------------------------------
    $script:LogFilterButtons = @{}
    foreach ($t in (Get-LogFilterTabDefs)) {
        $tb = New-Object System.Windows.Forms.Button
        $tb.Size = New-Object System.Drawing.Size(62, 22)
        $tb.Location = New-Object System.Drawing.Point(0, 4)
        $tb.Anchor = 'Top,Right'
        $tb.FlatStyle = 'Flat'
        $tb.FlatAppearance.BorderSize = 0
        $tb.BackColor = $script:Theme.BgTertiary
        $tb.ForeColor = $script:Theme.TextSecondary
        $tb.Font = (Get-AppFont -Size 8 -Style 'Bold')
        $tb.Cursor = 'Hand'
        $tb.TabStop = $false
        $tb.Tag = $t.Mode
        $tb.Add_Click({ Set-LogFilter -Mode ([string]$this.Tag) })
        $logPanel.Controls.Add($tb)
        $script:LogFilterButtons[$t.Mode] = $tb
    }

    # ---- Volltextsuche im Protokoll -----------------------------------------
    $txtLogSearch = New-Object System.Windows.Forms.TextBox
    # Lage und Breite setzt Update-LogPanelHeader - sie haengen von der
    # gemessenen Titelbreite der jeweiligen Sprache ab.
    $txtLogSearch.Location = New-Object System.Drawing.Point(260, 4)
    $txtLogSearch.Size = New-Object System.Drawing.Size(190, 22)
    $txtLogSearch.Anchor = 'Top,Left'
    $txtLogSearch.BackColor = $script:Theme.BgTertiary
    $txtLogSearch.ForeColor = $script:Theme.TextPrimary
    $txtLogSearch.BorderStyle = 'FixedSingle'
    $txtLogSearch.Font = (Get-AppFont -Size 8)
    $logPanel.Controls.Add($txtLogSearch)
    Set-Placeholder -TextBox $txtLogSearch -Text (Get-Text 'LogSearchHint')
    Set-Tip $txtLogSearch (Get-Text 'TipLogSearch')
    $script:txtLogSearch = $txtLogSearch

    # Jede Taste direkt neu zu rendern laesst das Tippen haengen, sobald der
    # Puffer voll ist - deshalb 180 ms Nachlauf wie beim Umbruch des Rasters.
    $script:LogSearchTimer = New-Object System.Windows.Forms.Timer
    $script:LogSearchTimer.Interval = 180
    $script:LogSearchTimer.Add_Tick({
            try { $script:LogSearchTimer.Stop() } catch { }
            $q = ''
            if ($script:txtLogSearch -and -not $script:txtLogSearch.IsDisposed) { $q = $script:txtLogSearch.Text }
            Set-LogSearch -Query $q
        })
    $txtLogSearch.Add_TextChanged({
            try { $script:LogSearchTimer.Stop(); $script:LogSearchTimer.Start() } catch { }
        })
    $txtLogSearch.Add_KeyDown({
            param($s, $e)
            if ($e.KeyCode -eq 'Escape') {
                $e.SuppressKeyPress = $true
                $e.Handled = $true
                $s.Text = ''
            }
        })

    $lblLogMatch = New-Object System.Windows.Forms.Label
    $lblLogMatch.Font = (Get-AppFont -Size 8)
    $lblLogMatch.ForeColor = $script:Theme.TextMuted
    $lblLogMatch.BackColor = [System.Drawing.Color]::Transparent
    $lblLogMatch.TextAlign = 'MiddleLeft'
    $lblLogMatch.AutoEllipsis = $true
    $lblLogMatch.Visible = $false
    $lblLogMatch.Location = New-Object System.Drawing.Point(470, 6)
    $lblLogMatch.Size = New-Object System.Drawing.Size(90, 20)
    $logPanel.Controls.Add($lblLogMatch)
    $script:lblLogMatch = $lblLogMatch

    $logPanel.Add_ClientSizeChanged({ Update-LogPanelHeader })
    Update-LogPanelHeader

    # Ein- und Ausklappen: Auf 900er-Bildschirmen nimmt die Protokollleiste
    # 158 von rund 820 nutzbaren Pixeln ein - eingeklappt bleiben 32.
    $btnLogToggle = New-Object System.Windows.Forms.Button
    $btnLogToggle.Size = New-Object System.Drawing.Size(34, 22)
    $btnLogToggle.Location = New-Object System.Drawing.Point(($logPanel.Width - 188), 4)
    $btnLogToggle.Anchor = 'Top,Right'
    $btnLogToggle.FlatStyle = 'Flat'
    $btnLogToggle.FlatAppearance.BorderSize = 0
    $btnLogToggle.BackColor = $script:Theme.BgTertiary
    $btnLogToggle.ForeColor = $script:Theme.TextSecondary
    $btnLogToggle.Cursor = 'Hand'
    $btnLogToggle.TabStop = $false
    [void](Set-ControlIcon -Control $btnLogToggle -Glyph 'chevrondown' -Size 14 -IconOnly)
    $btnLogToggle.Add_Click({ Set-LogCollapsed -Collapsed (-not $script:Config.LogCollapsed) })
    $logPanel.Controls.Add($btnLogToggle)
    Set-RoundedRegion -Control $btnLogToggle -Radius 5
    $script:btnLogToggle = $btnLogToggle

    $btnLogOpen = New-Object System.Windows.Forms.Button
    $btnLogOpen.Text = '{icon:folderopen}'
    $btnLogOpen.Size = New-Object System.Drawing.Size(34, 22)
    $btnLogOpen.Location = New-Object System.Drawing.Point(($logPanel.Width - 150), 4)
    $btnLogOpen.Anchor = 'Top,Right'
    $btnLogOpen.FlatStyle = 'Flat'
    $btnLogOpen.FlatAppearance.BorderSize = 0
    $btnLogOpen.BackColor = $script:Theme.BgTertiary
    $btnLogOpen.ForeColor = $script:Theme.TextSecondary
    $btnLogOpen.Font = Get-AppFont -Size 8 -Style 'Bold'
    $btnLogOpen.Cursor = 'Hand'
    $btnLogOpen.TabStop = $false
    $btnLogOpen.Add_Click({ Open-SessionLog })
    Set-Tip $btnLogOpen (Get-Text 'LogOpenTip')
    $logPanel.Controls.Add($btnLogOpen)
    Set-RoundedRegion -Control $btnLogOpen -Radius 5

    $btnLogClear = New-Object System.Windows.Forms.Button
    $script:btnLogClear = $btnLogClear
    $btnLogClear.Text = "{icon:broom} $(Get-Text 'Clean')"
    $btnLogClear.Size = New-Object System.Drawing.Size(96, 22)
    $btnLogClear.Location = New-Object System.Drawing.Point(($logPanel.Width - 112), 4)
    $btnLogClear.Anchor = 'Top,Right'
    $btnLogClear.FlatStyle = 'Flat'
    $btnLogClear.FlatAppearance.BorderSize = 0
    $btnLogClear.BackColor = $script:Theme.BgTertiary
    $btnLogClear.ForeColor = $script:Theme.TextSecondary
    $btnLogClear.Font = (Get-AppFont -Size 8 -Style 'Bold')
    $btnLogClear.Cursor = 'Hand'
    $btnLogClear.TabStop = $false
    $btnLogClear.Add_Click({ Clear-LogView })
    $logPanel.Controls.Add($btnLogClear)
    Set-RoundedRegion -Control $btnLogClear -Radius 5

    $txtLog = New-Object System.Windows.Forms.RichTextBox
    $txtLog.Location = New-Object System.Drawing.Point(14, 26)
    $txtLog.Size = New-Object System.Drawing.Size(1222, 94)
    $txtLog.BackColor = $script:Theme.BgPrimary
    $txtLog.ForeColor = $script:Theme.TextSecondary
    $txtLog.ReadOnly = $true
    $txtLog.BorderStyle = 'None'
    $txtLog.Font = (Get-AppFont -Family $script:MonoFont -Size 9)
    $txtLog.Anchor = 'Top,Bottom,Left,Right'
    $logPanel.Controls.Add($txtLog)
    # Zeitstempel, Pfade und Befehlsausgaben - diese Flaeche darf im
    # arabischen Modus nicht gespiegelt werden.
    $txtLog.RightToLeft = [System.Windows.Forms.RightToLeft]::No
    $script:txtLog = $txtLog

    # ---- Befehlszeile unter dem Protokoll ------------------------------------
    $lblPrompt = New-Object System.Windows.Forms.Label
    $lblPrompt.Text = 'cmd >'
    $lblPrompt.RightToLeft = [System.Windows.Forms.RightToLeft]::No
    $lblPrompt.Font = (Get-AppFont -Family $script:MonoFont -Size 9 -Style 'Bold')
    $lblPrompt.ForeColor = $script:Theme.Cyan
    $lblPrompt.BackColor = [System.Drawing.Color]::Transparent
    $lblPrompt.AutoSize = $true
    $lblPrompt.Location = New-Object System.Drawing.Point(14, 130)
    $lblPrompt.Anchor = 'Bottom,Left'
    $logPanel.Controls.Add($lblPrompt)
    $script:lblPrompt = $lblPrompt

    $txtCmd = New-Object System.Windows.Forms.TextBox
    $txtCmd.Location = New-Object System.Drawing.Point(62, 126)
    $txtCmd.Size = New-Object System.Drawing.Size(1084, 24)
    $txtCmd.Anchor = 'Bottom,Left,Right'
    $txtCmd.BackColor = $script:Theme.BgPrimary
    $txtCmd.ForeColor = $script:Theme.TextPrimary
    $txtCmd.BorderStyle = 'FixedSingle'
    $txtCmd.Font = (Get-AppFont -Family $script:MonoFont -Size 9)
    $logPanel.Controls.Add($txtCmd)
    # Eingegeben werden cmd-Befehle - immer linkslaeufig, sonst landet der
    # Mauszeiger rechts und der Pfad steht verkehrt herum.
    $txtCmd.RightToLeft = [System.Windows.Forms.RightToLeft]::No
    Set-Placeholder -TextBox $txtCmd -Text (Get-Text 'CmdPlaceholder')
    Set-Tip -Control $txtCmd -Text (Get-Text 'CmdTabHint')
    $script:txtCmd = $txtCmd
    $script:CmdHistory = New-Object System.Collections.Generic.List[string]
    $script:CmdHistoryPos = -1
    $script:CmdComplete = $null

    # Tab wandert in einem TextBox normalerweise zum naechsten Steuerelement.
    # Fuer eine Befehlszeile ist das die falsche Belegung - PreviewKeyDown
    # muss Tab erst als echte Taste anmelden, sonst sieht KeyDown sie nie.
    $txtCmd.Add_PreviewKeyDown({
            param($s, $e)
            if ($e.KeyCode -eq 'Tab') { $e.IsInputKey = $true }
        })
    # Jede normale Eingabe verwirft die laufende Vervollstaendigung.
    $txtCmd.Add_TextChanged({
            if ($script:CmdComplete -and [string]$script:CmdComplete.Text -ne [string]$script:txtCmd.Text) {
                $script:CmdComplete = $null
            }
        })
    $txtCmd.Add_KeyDown({
            param($s, $e)
            try {
                if ($e.KeyCode -eq 'Tab') {
                    $e.SuppressKeyPress = $true
                    $e.Handled = $true
                    Invoke-CommandCompletion
                    return
                }
                if ($e.KeyCode -eq 'Escape') {
                    $e.SuppressKeyPress = $true
                    $e.Handled = $true
                    $script:CmdComplete = $null
                    $script:CmdHistoryPos = -1
                    $script:txtCmd.Clear()
                    return
                }
                if ($e.KeyCode -eq 'Enter') {
                    $e.SuppressKeyPress = $true
                    $e.Handled = $true
                    Submit-ConsoleCommand
                }
                elseif ($e.KeyCode -eq 'Up') {
                    $script:CmdComplete = $null
                    $e.SuppressKeyPress = $true
                    if ($script:CmdHistory.Count -gt 0) {
                        if ($script:CmdHistoryPos -lt 0) { $script:CmdHistoryPos = $script:CmdHistory.Count }
                        if ($script:CmdHistoryPos -gt 0) { $script:CmdHistoryPos-- }
                        $script:txtCmd.Text = $script:CmdHistory[$script:CmdHistoryPos]
                        $script:txtCmd.SelectionStart = $script:txtCmd.TextLength
                    }
                }
                elseif ($e.KeyCode -eq 'Down') {
                    $script:CmdComplete = $null
                    $e.SuppressKeyPress = $true
                    if ($script:CmdHistory.Count -gt 0 -and $script:CmdHistoryPos -ge 0) {
                        $script:CmdHistoryPos++
                        if ($script:CmdHistoryPos -ge $script:CmdHistory.Count) {
                            $script:CmdHistoryPos = -1
                            $script:txtCmd.Clear()
                        }
                        else {
                            $script:txtCmd.Text = $script:CmdHistory[$script:CmdHistoryPos]
                            $script:txtCmd.SelectionStart = $script:txtCmd.TextLength
                        }
                    }
                }
            }
            catch { }
        })

    $btnRun = New-Object System.Windows.Forms.Button
    $script:btnRun = $btnRun
    $btnRun.Text = "{icon:play} $(Get-Text 'CmdRun')"
    $script:btnCmdRun = $btnRun
    $btnRun.Size = New-Object System.Drawing.Size(82, 24)
    $btnRun.Location = New-Object System.Drawing.Point(1154, 126)
    $btnRun.Anchor = 'Bottom,Right'
    $btnRun.FlatStyle = 'Flat'
    $btnRun.FlatAppearance.BorderSize = 0
    $btnRun.BackColor = $script:Theme.Accent
    $btnRun.ForeColor = $script:Theme.TextWhite
    $btnRun.Font = (Get-AppFont -Size 8 -Style 'Bold')
    $btnRun.Cursor = 'Hand'
    $btnRun.Add_Click({ Submit-ConsoleCommand })
    $logPanel.Controls.Add($btnRun)
    Set-RoundedRegion -Control $btnRun -Radius 5

    Set-LogFilter -Mode 'ALL'

    # ---- Resizable borderless window -----------------------------------------
    [void](New-ResizeEdge -Side 'Right'  -HitTest 11 -Cursor 'SizeWE' -Form $form)   # HTRIGHT
    [void](New-ResizeEdge -Side 'Bottom' -HitTest 15 -Cursor 'SizeNS' -Form $form)   # HTBOTTOM

    $grip = New-Object System.Windows.Forms.Panel
    $grip.Size = New-Object System.Drawing.Size(16, 16)
    $grip.Anchor = 'Bottom,Right'
    $grip.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - 16), ($form.ClientSize.Height - 16))
    $grip.BackColor = [System.Drawing.Color]::Transparent
    $grip.Cursor = [System.Windows.Forms.Cursors]::SizeNWSE
    $grip.Add_Paint({
            param($s, $e)
            $br = New-Object System.Drawing.SolidBrush($script:Theme.TextMuted)
            try {
                foreach ($d in @(@(11, 3), @(7, 7), @(11, 7), @(3, 11), @(7, 11), @(11, 11))) {
                    $e.Graphics.FillRectangle($br, $d[0], $d[1], 2, 2)
                }
            }
            finally { $br.Dispose() }
        })
    $grip.Add_MouseDown({
            param($s, $e)
            if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { Start-WindowResize -HitTest 17 }  # HTBOTTOMRIGHT
        })
    $form.Controls.Add($grip)
    $grip.BringToFront()

    # Maximizing a borderless form would cover the taskbar - clamp it
    $setBounds = {
        try {
            $wa = [System.Windows.Forms.Screen]::FromControl($script:MainForm).WorkingArea
            $script:MainForm.MaximizedBounds = $wa
        }
        catch { }
    }
    $form.Add_Load($setBounds)
    $form.Add_LocationChanged($setBounds)

    # Title bar, header stats, window buttons and log panel: swap the last
    # emoji placeholders for vector icons, then re-measure the header
    Update-ControlIcons -Root $form -Size 16
    try { Update-HeaderLayout } catch { }
    try { Set-DarkScrollbars -Control $form -Recurse } catch { }
    try { Set-DarkInputs -Control $form -Recurse } catch { }

    # Ganz zum Schluss: Jetzt existieren Titelleiste, Kopf UND Protokollfeld.
    Update-StaticTips

    return $form
}

#endregion 7. MAIN WINDOW


#region 8. TIMER, SHORTCUTS, STARTUP

function Add-SparklinePoint {
    param([string]$Key, [single]$Value)
    $list = $script:SparklineHistory[$Key]
    if ($null -eq $list) { return }
    $list.Add($Value)
    while ($list.Count -gt $script:SparklineHistory.BufferSize) { $list.RemoveAt(0) }
}

$script:TimerErrorCount = 0
$script:Tick = 0
$script:ProcCountCache = 0
$script:SvcRowKeys = @()
$script:ServiceInfoCache = @{}
$script:ServiceDependents = @{}
$script:ServiceStatus = @{}
$script:ProcCpuPrev = @{}
$script:ProcCpuMap = @{}
$script:ProcCpuTime = $null
$script:Shutdown = $false

function Update-LogPathLabel {
    # Zeigt den Dateinamen der laufenden Sitzungsprotokolldatei; der volle
    # Pfad steht im Hinweisfenster, ein Klick oeffnet die Datei.
    if (-not $script:lblLogPath -or $script:lblLogPath.IsDisposed) { return }
    try {
        if ($script:LogFilePath) {
            # 'session_20261006_143512.log' passt nicht in 150 px - Vorsilbe
            # und Endung weglassen, der volle Pfad steht im Hinweisfenster.
            $leaf = Split-Path -Leaf $script:LogFilePath
            $leaf = $leaf -replace '^session_', '' -replace '\.log$', ''
            $script:lblLogPath.Text = $leaf
            Set-Tip $script:lblLogPath "$(Get-Text 'HeadLogPath'): $script:LogFilePath"
        }
        else {
            $script:lblLogPath.Text = '---'
            Set-Tip $script:lblLogPath (Get-Text 'HeadLogPath')
        }
    }
    catch { }
}

function Get-TextPixelWidth {
    # Eine Beschriftung ist so breit wie ihr Text - feste Pixelwerte stimmen
    # nur fuer die Sprache und die Zahlen, fuer die sie gewaehlt wurden.
    param([string]$Text, $Font, [int]$Fallback = 100)
    if ([string]::IsNullOrEmpty($Text)) { return 0 }
    try {
        $m = [System.Windows.Forms.TextRenderer]::MeasureText($Text, $Font)
        if ($m.Width -gt 0) { return [int]$m.Width }
    }
    catch { }
    return $Fallback
}

function Get-HeaderItemWidth {
    # Gemessen wird ein Muster mit dem laengsten zu erwartenden Wert, nicht der
    # aktuelle Text: sonst wanderte die ganze Zeile jede Sekunde ein paar Pixel
    # hin und her, sobald aus 9 % eine 10 % wird.
    param($Label, [string]$Sample, [int]$Icon = 22, [int]$Pad = 12,
        [int]$Min = 60, [int]$Max = 280, [int]$Fallback = 110)
    if (-not $Label -or $Label.IsDisposed) { return 0 }
    $f = $Label.Font
    $w = (Get-TextPixelWidth -Text $Sample -Font $f -Fallback $Fallback) + $Icon + $Pad
    if ($w -lt $Min) { $w = $Min }
    if ($w -gt $Max) { $w = $Max }
    return [int]$w
}

function Get-HeaderLayoutPlan {
    # Reine Geometrie - ohne Oberflaechenbezug, damit sich jede Engstelle
    # einzeln pruefen laesst.
    param(
        [int]$Width,
        [int[]]$ItemWidths = @(),
        [bool[]]$HasSpark = @(),
        [int]$AdminWidth = 0,
        # Die Statusspiegelung ist das Unwichtigste der Zeile: dieselbe Meldung
        # steht einen Zentimeter tiefer im Protokoll. Frueher reservierte sie
        # 150 px fest - dafuer flogen am Ende zwei echte Messwerte raus bzw.
        # wurden ineinandergeschoben. Sie bekommt jetzt nur noch den Rest.
        [int]$StatusMin = 0,
        [int]$StatusShowMin = 90,
        [int]$Gap = 10,
        [int]$Left = 20,
        [int]$SparkWidth = 64,
        [int]$SparkGap = 4
    )
    $plan = @{
        AdminVisible = $false; AdminX = 0
        StatusVisible = $false; StatusX = 0; StatusWidth = 0
        Items = @()
    }
    $widths = @($ItemWidths)
    if ($Width -le 0) { return $plan }

    $right = $Width - 20
    # Das Abzeichen faellt als Erstes weg - es aendert sich ohnehin nie.
    if ($AdminWidth -gt 0 -and $Width -ge ($AdminWidth + 760)) {
        $plan.AdminVisible = $true
        $plan.AdminX = $Width - 20 - $AdminWidth
        $right = $plan.AdminX - $Gap
    }

    $x = $Left
    for ($i = 0; $i -lt $widths.Count; $i++) {
        $w = [int]$widths[$i]
        $spark = $false
        if ($i -lt @($HasSpark).Count) { $spark = [bool]$HasSpark[$i] }
        $need = $w + $Gap
        if ($spark) { $need += ($SparkGap + $SparkWidth) }
        $entry = @{ Visible = $false; X = 0; SparkX = 0; Width = $w }
        if (($x + $need) -le ($right - $StatusMin)) {
            $entry.Visible = $true
            $entry.X = $x
            if ($spark) { $entry.SparkX = $x + $w + $SparkGap }
            $x += $need
        }
        $plan.Items += $entry
    }

    $sw = $right - $x - $Gap
    if ($sw -ge $StatusShowMin) {
        $plan.StatusVisible = $true
        $plan.StatusX = $x + $Gap
        $plan.StatusWidth = $sw
    }
    return $plan
}

function Update-HeaderLayout {
    # Die Zeile floss schon von links nach rechts, rechnete dabei aber mit
    # festen Breiten (100/110/150/95/150). "RAM: 26%" passte nicht in 100 px
    # und wurde zu "RAM: 2...", der Protokollname und das Administrator-
    # Abzeichen waren ebenfalls abgeschnitten. Jetzt wird gemessen.
    if (-not $script:pnlHeader -or $script:pnlHeader.IsDisposed) { return }
    $w = $script:pnlHeader.ClientSize.Width
    if ($w -le 0) { return }

    $defs = @(
        @{ L = $script:lblCPU; S = $script:SparkCPU; Sample = 'CPU: 100%'; Fb = 100 }
        @{ L = $script:lblRAM; S = $script:SparkRAM; Sample = 'RAM: 100%'; Fb = 100 }
        @{ L = $script:lblDisk; S = $null; Sample = 'Disk: 100%'; Fb = 110 }
        @{ L = $script:lblNet; S = $null; Sample = 'Net: 999.9 MB/s'; Fb = 150 }
        @{ L = $script:lblTime; S = $null; Sample = '00:00:00'; Fb = 95 }
        @{ L = $script:lblLogPath; S = $null; Sample = $null; Fb = 150 }
    )
    $widths = @()
    $sparks = @()
    foreach ($d in $defs) {
        $sample = if ($d.Sample) { $d.Sample } elseif ($d.L) { [string]$d.L.Text } else { '' }
        $widths += (Get-HeaderItemWidth -Label $d.L -Sample $sample -Fallback $d.Fb)
        $sparks += [bool]$d.S
    }
    $adminW = 0
    if ($script:lblAdmin -and -not $script:lblAdmin.IsDisposed) {
        $adminW = Get-HeaderItemWidth -Label $script:lblAdmin -Sample ([string]$script:lblAdmin.Text) -Fallback 150 -Max 240
    }

    $plan = Get-HeaderLayoutPlan -Width $w -ItemWidths $widths -HasSpark $sparks -AdminWidth $adminW

    if ($script:lblAdmin -and -not $script:lblAdmin.IsDisposed) {
        $script:lblAdmin.Visible = $plan.AdminVisible
        if ($plan.AdminVisible) {
            $script:lblAdmin.SetBounds($plan.AdminX, 20, $adminW, 22)
        }
    }
    for ($i = 0; $i -lt $defs.Count; $i++) {
        $d = $defs[$i]
        if (-not $d.L -or $d.L.IsDisposed) { continue }
        $e = $plan.Items[$i]
        $d.L.Visible = $e.Visible
        if ($e.Visible) { $d.L.SetBounds($e.X, 18, $e.Width, 24) }
        if ($d.S -and -not $d.S.IsDisposed) {
            $d.S.Visible = $e.Visible
            if ($e.Visible) { $d.S.Location = New-Object System.Drawing.Point($e.SparkX, 21) }
        }
    }
    if ($script:lblStatus -and -not $script:lblStatus.IsDisposed) {
        $script:lblStatus.Visible = $plan.StatusVisible
        if ($plan.StatusVisible) {
            $script:lblStatus.SetBounds($plan.StatusX, 20, $plan.StatusWidth, 22)
        }
    }
}

function Update-LiveStats {
    try {
        $script:Tick++

        # Minimized or hidden: every measurement would feed labels and gauges
        # that nobody can see. Skip the tick and give the CPU back.
        if ($script:MainForm -and -not $script:MainForm.IsDisposed) {
            if (-not $script:MainForm.Visible -or $script:MainForm.WindowState -eq 'Minimized') {
                return
            }
        }

        $onDashboard = ($script:Config.CurrentView -eq 'Dashboard')

        # --- CPU + RAM: native calls, cheap enough for every tick -------------
        $cpu = Get-CpuUsageFast
        $ram = [int]$script:CurrentStats.RAM
        $mem = Get-MemoryFast
        if ($mem) { $ram = [int]$mem.Percent }

        # --- Network: managed statistics, every tick --------------------------
        $net = [double](Get-NetworkThroughputMBs)

        # --- Expensive items run on a slower schedule -------------------------
        $disk = [int]$script:CurrentStats.Disk
        if ($script:Tick % 30 -eq 1) {
            # DriveInfo ist ein verwalteter Aufruf im Mikrosekundenbereich.
            # Die alte CIM-Abfrage lief auf dem Oberflaechenstrang und hat alle
            # 30 Sekunden einen sichtbaren Haenger erzeugt.
            try {
                $di = New-Object -TypeName 'System.IO.DriveInfo' -ArgumentList $env:SystemDrive
                if ($di -and $di.IsReady -and $di.TotalSize -gt 0) {
                    $disk = [int]((($di.TotalSize - $di.TotalFreeSpace) / $di.TotalSize) * 100)
                }
            }
            catch {
                try {
                    $sys = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'" -ErrorAction Stop
                    if ($sys -and $sys.Size -gt 0) {
                        $disk = [int]((($sys.Size - $sys.FreeSpace) / $sys.Size) * 100)
                    }
                }
                catch { }
            }
        }

        # Prozessliste und Bewertung speisen ausschliesslich Anzeigen des
        # Dashboards. In jeder anderen Ansicht entfaellt der Durchlauf - das
        # war bisher alle fuenf Sekunden ein spuerbarer Ruckler.
        if ($onDashboard -and ($script:Tick % 5 -eq 1 -or $script:ProcCountCache -le 0)) {
            try {
                # Process objects hold OS handles - dispose them, otherwise the
                # app slowly leaks handles while it runs.
                $all = [System.Diagnostics.Process]::GetProcesses()
                $script:ProcCountCache = $all.Length
                foreach ($pr in $all) { try { $pr.Dispose() } catch { } }
            }
            catch { }
        }

        $script:CurrentStats.CPU = $cpu
        $script:CurrentStats.RAM = $ram
        $script:CurrentStats.Disk = $disk
        $script:CurrentStats.Net = $net
        $script:CurrentStats.Time = Get-Date
        if ($onDashboard -and $script:Tick % 5 -eq 1) { $script:CurrentStats.Health = Get-SystemHealthScore }

        Add-SparklinePoint -Key 'CPU' -Value $cpu
        Add-SparklinePoint -Key 'RAM' -Value $ram
        Add-SparklinePoint -Key 'NET' -Value $net

        # --- Header mini stats: only touch a label when the text changed ------
        # The icon is a picture on the label now, so the text stays plain
        Set-LabelText $script:lblCPU  "CPU: $cpu%"
        Set-LabelText $script:lblRAM  "RAM: $ram%"
        Set-LabelText $script:lblDisk "Disk: $disk%"
        Set-LabelText $script:lblNet  ("Net: " + (Format-NetRate $net))
        Set-LabelText $script:lblTime "$(Get-Date -Format 'HH:mm:ss')"

        foreach ($sp in @($script:SparkCPU, $script:SparkRAM)) {
            if ($sp -and -not $sp.IsDisposed) { $sp.Invalidate() }
        }

        # --- Dashboard widgets: repaint only while that view is visible -------
        if ($onDashboard) {
            foreach ($pnl in @($script:GaugeCPU, $script:GaugeRAM, $script:GaugeNet, $script:pnlHealth)) {
                if ($pnl -and -not $pnl.IsDisposed) { $pnl.Invalidate() }
            }
            if ($script:StatDisk -and -not $script:StatDisk.IsDisposed) {
                Set-LabelText $script:StatDisk.Tag.ValueLabel "$disk%"
            }
            if ($script:StatProc -and -not $script:StatProc.IsDisposed) {
                Set-LabelText $script:StatProc.Tag.ValueLabel ([string]$script:ProcCountCache)
            }
        }

        $script:TimerErrorCount = 0   # reset after a clean tick
    }
    catch {
        $script:TimerErrorCount++
        if ($script:TimerErrorCount -ge 5) {
            if ($script:Timer) { $script:Timer.Stop() }
            Write-Log "$(Get-Text 'LogMonitorStopped'): $($_.Exception.Message)" 'ERROR'
        }
    }
}

function Set-LabelText {
    # Assigning Text always triggers a repaint - skip it when nothing changed.
    param($Label, [string]$Text)
    if (-not $Label -or $Label.IsDisposed) { return }
    if ($Label.Text -ne $Text) { $Label.Text = $Text }
}

function Start-Monitoring {
    # Exactly ONE timer instance - the old build started it three times
    if ($script:Timer) { return }
    $script:Timer = New-Object System.Windows.Forms.Timer
    $script:Timer.Interval = $script:Config.TimerInterval
    $script:Timer.Add_Tick({ Update-LiveStats })
    $script:Timer.Start()
}

function Register-Shortcuts {
    param([System.Windows.Forms.Form]$Form)

    $Form.Add_KeyDown({
            param($s, $e)
            try {
                switch ($e.KeyCode) {
                    'F5' { Set-View -ViewName $script:Config.CurrentView; $e.Handled = $true }
                    'F1' { Set-View -ViewName 'Help'; $e.Handled = $true }
                    'F11' {
                        $script:MainForm.WindowState =
                        if ($script:MainForm.WindowState -eq 'Maximized') { 'Normal' } else { 'Maximized' }
                        $e.Handled = $true
                    }
                    # Escape used to close the whole app - far too easy to hit
                    # by accident. It now just leaves the current search box.
                    'Escape' {
                        if ($script:MainForm.ActiveControl -is [System.Windows.Forms.TextBoxBase]) {
                            $script:MainForm.ActiveControl.Clear()
                        }
                        $e.Handled = $true
                    }
                    default {
                        if ($e.Control) {
                            switch ($e.KeyCode) {
                                'D1' { Set-View -ViewName 'Dashboard'; $e.Handled = $true }
                                'D2' { Set-View -ViewName 'Hardware'; $e.Handled = $true }
                                'D3' { Set-View -ViewName 'Disk'; $e.Handled = $true }
                                'D4' { Set-View -ViewName 'Gaming'; $e.Handled = $true }
                                'D5' { Set-View -ViewName 'Privacy'; $e.Handled = $true }
                                'D6' { Set-View -ViewName 'Services'; $e.Handled = $true }
                                'D7' { Set-View -ViewName 'Processes'; $e.Handled = $true }
                                'D8' { Set-View -ViewName 'Repair'; $e.Handled = $true }
                                'D9' { Set-View -ViewName 'Settings'; $e.Handled = $true }
                                'L' { Clear-LogView; $e.Handled = $true }
                                'F' {
                                    if ($script:SearchBox -and -not $script:SearchBox.IsDisposed) {
                                        [void]$script:SearchBox.Focus()
                                    }
                                    $e.Handled = $true
                                }
                                'Q' { $script:MainForm.Close(); $e.Handled = $true }
                                'W' { $script:MainForm.Close(); $e.Handled = $true }
                                'R' { Set-View -ViewName $script:Config.CurrentView; $e.Handled = $true }
                                'H' { Set-View -ViewName 'Help'; $e.Handled = $true }
                            }
                        }
                    }
                }
            }
            catch { Write-Log "$(Get-Text 'Error'): $($_.Exception.Message)" 'ERROR' }
        })
}

function Show-MainWindow {
    # Holt das Fenster aus dem Infobereich zurueck.
    try {
        if (-not $script:MainForm -or $script:MainForm.IsDisposed) { return }
        if (-not $script:MainForm.Visible) { $script:MainForm.Show() }
        if ($script:MainForm.WindowState -eq 'Minimized') {
            $script:MainForm.WindowState = $(if ($script:Config.WinMaximized) { 'Maximized' } else { 'Normal' })
        }
        [void]$script:MainForm.Activate()
        $script:MainForm.BringToFront()
    }
    catch { }
}

function Show-TrayBalloon {
    # Sprechblase am Infobereich - nur sinnvoll, wenn das Fenster versteckt
    # ist; sonst uebernimmt die Kurzmeldung im Fenster.
    param([string]$Text, [string]$Title = '', [string]$Type = 'INFO')
    try {
        if (-not $script:TrayIcon -or -not $script:TrayIcon.Visible -or -not $Text) { return }

        # Windows blendet schnell aufeinander folgende Sprechblasen ohnehin
        # aus. Statt sie wegzuwerfen, wird nur die letzte gezeigt: gleiche
        # Meldung oder weniger als vier Sekunden Abstand werden verschluckt.
        $now = Get-Date
        if ($script:BalloonLastText -eq $Text -and $script:BalloonLastTime -and
            (($now - $script:BalloonLastTime).TotalSeconds -lt 20)) {
            return
        }
        if ($script:BalloonLastTime -and (($now - $script:BalloonLastTime).TotalSeconds -lt 4)) { return }
        $script:BalloonLastText = $Text
        $script:BalloonLastTime = $now

        $ico = switch ($Type) {
            'ERROR' { [System.Windows.Forms.ToolTipIcon]::Error }
            'WARNING' { [System.Windows.Forms.ToolTipIcon]::Warning }
            default { [System.Windows.Forms.ToolTipIcon]::Info }
        }
        if (-not $Title) {
            # Titel in der eingestellten Sprache statt fest 'EB_Optimizer'
            $key = switch ($Type) { 'ERROR' { 'Error' } 'WARNING' { 'Warning' } 'SUCCESS' { 'Success' } default { 'Info' } }
            $Title = "$($script:Config.AppName) - $(Get-Text $key)"
        }
        # ShowBalloonTip schneidet ab etwa 250 Zeichen hart ab
        if ($Text.Length -gt 220) { $Text = $Text.Substring(0, 217) + '...' }
        $script:TrayIcon.ShowBalloonTip(5000, $Title, $Text, $ico)
    }
    catch { }
}

function Initialize-TrayIcon {
    # Symbol im Infobereich mit Schnellaktionen. Das Programm laeuft damit
    # weiter, ohne ein Fenster in der Taskleiste zu belegen.
    if ($script:TrayIcon) { return }
    try {
        $ni = New-Object System.Windows.Forms.NotifyIcon
        $ni.Text = 'EB_Optimizer v' + [string]$script:Config.Version

        $icon = $null
        try {
            $bmp = Get-IconBitmap -Name 'bolt' -Size 32 -Color $script:Theme.Accent
            if ($bmp) {
                # Icon.FromHandle gibt das GDI-Handle beim Dispose NICHT frei.
                # Deshalb eine eigenstaendige Kopie ziehen und das Handle selbst
                # zerstoeren - sonst bleibt pro Programmlauf eines haengen.
                $h = $bmp.GetHicon()
                $tmp = [System.Drawing.Icon]::FromHandle($h)
                try { $icon = $tmp.Clone() } catch { $icon = $tmp }
                if (-not [object]::ReferenceEquals($icon, $tmp)) {
                    try { $tmp.Dispose() } catch { }
                    try { [void][EBHost.Native]::DestroyIcon($h) } catch { }
                }
            }
        }
        catch { }
        if (-not $icon) { try { $icon = [System.Drawing.SystemIcons]::Application } catch { } }
        $ni.Icon = $icon
        $script:TrayIconObject = $icon

        $menu = New-Object System.Windows.Forms.ContextMenuStrip
        $menu.BackColor = $script:Theme.BgTertiary
        $menu.ForeColor = $script:Theme.TextPrimary
        $menu.ShowImageMargin = $false

        $miShow = $menu.Items.Add((Get-Text 'TrayShow'))
        $miShow.Font = (Get-AppFont -Size 9 -Style 'Bold')
        [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
        $miClean = $menu.Items.Add((Get-Text 'QuickClean'))
        $miRam = $menu.Items.Add((Get-Text 'QuickRAM'))
        [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
        $miExit = $menu.Items.Add((Get-Text 'TrayExit'))

        foreach ($mi in @($miShow, $miClean, $miRam, $miExit)) {
            $mi.BackColor = $script:Theme.BgTertiary
            $mi.ForeColor = $script:Theme.TextPrimary
        }

        $miShow.Add_Click({ Show-MainWindow })
        # Aktionen zeigen zuerst das Fenster: der Fortschrittsdialog gehoert
        # sonst zu einem unsichtbaren Fenster und waere nicht bedienbar.
        $miClean.Add_Click({ Show-MainWindow; [void](Invoke-QuickClean) })
        $miRam.Add_Click({ Show-MainWindow; Optimize-Memory })
        $miExit.Add_Click({
                try {
                    if ($script:MainForm -and -not $script:MainForm.IsDisposed) {
                        if (-not $script:MainForm.Visible) { $script:MainForm.Show() }
                        $script:MainForm.Close()
                    }
                }
                catch { }
            })

        $ni.ContextMenuStrip = $menu
        $ni.Add_DoubleClick({ Show-MainWindow })
        $ni.Visible = $true
        $script:TrayIcon = $ni
        $script:TrayMenu = $menu
    }
    catch { $script:TrayIcon = $null }
}

function Stop-TrayIcon {
    try {
        if ($script:TrayIcon) {
            $script:TrayIcon.Visible = $false
            $script:TrayIcon.Dispose()
            $script:TrayIcon = $null
        }
    }
    catch { }
    try { if ($script:TrayMenu) { $script:TrayMenu.Dispose(); $script:TrayMenu = $null } } catch { }
    try {
        # Das aus einer Bitmap erzeugte Symbol haelt ein GDI-Handle
        if ($script:TrayIconObject) { $script:TrayIconObject.Dispose(); $script:TrayIconObject = $null }
    }
    catch { }
}

function Stop-AppResources {
    Stop-TrayIcon

    try {
        if ($script:Timer) {
            $script:Timer.Stop()
            $script:Timer.Dispose()
            $script:Timer = $null
        }
    }
    catch { }

    try {
        if ($script:ToolTip) { $script:ToolTip.Dispose(); $script:ToolTip = $null }
    }
    catch { }

    try {
        if ($script:BusyTimer) { $script:BusyTimer.Stop(); $script:BusyTimer.Dispose(); $script:BusyTimer = $null }
    }
    catch { }

    try {
        if ($script:AppMutex) {
            try { $script:AppMutex.ReleaseMutex() } catch { }
            $script:AppMutex.Dispose()
            $script:AppMutex = $null
        }
    }
    catch { }

    Close-LogFile
}

function Stop-AppFonts {
    Stop-AppIcons
    Stop-LoadJobs
    try { Clear-Toasts } catch { }
    try { Stop-ProcessAutoRefresh } catch { }
    try {
        if ($script:LogSearchTimer) {
            $script:LogSearchTimer.Stop()
            $script:LogSearchTimer.Dispose()
            $script:LogSearchTimer = $null
        }
    }
    catch { }

    # Runs on FormClosed, not FormClosing: controls may still repaint while the
    # window is closing, and painting with a disposed font throws.
    try {
        if ($script:RegionCache) {
            foreach ($r in @($script:RegionCache.Values)) {
                if ($r -is [System.IDisposable]) { $r.Dispose() }
            }
            $script:RegionCache.Clear()
        }
    }
    catch { }

    try {
        if ($script:Fonts) {
            foreach ($f in @($script:Fonts.Values)) {
                if ($f -is [System.IDisposable]) { $f.Dispose() }
            }
            $script:Fonts.Clear()
        }
    }
    catch { }
}

# ------------------------------------------------------------------- STARTUP --
function Get-MigrationAction {
    # Reine Entscheidung, damit sie pruefbar bleibt: uebernommen wird nur,
    # wenn es am alten Ort etwas gibt und am neuen noch nichts steht. Alles
    # andere waere ein Ueberschreiben von Daten, die der Nutzer schon hat.
    param([bool]$OldExists, [bool]$NewExists)
    if (-not $OldExists) { return 'none' }
    if ($NewExists) { return 'keep' }
    return 'take'
}

function Import-LegacyAppData {
    # Das Programm hiess frueher EB_EHAB OPTIMIZER und legte Einstellungen und
    # Sicherungen unter diesem Namen ab. Beim ersten Start unter dem neuen
    # Namen werden sie uebernommen, damit Sprache, Fensterlage und vor allem
    # die Registrierungs-Sicherungen nicht verloren gehen.
    $oldSet = Join-Path $env:APPDATA 'EB_EHAB_Optimizer'
    $oldBak = Join-Path $env:USERPROFILE 'Documents\EB_EHAB_Backups'
    $newSet = Split-Path -Path $script:Config.SettingsPath -Parent
    $newBak = $script:Config.BackupDir

    try {
        $act = Get-MigrationAction -OldExists (Test-Path -LiteralPath $oldSet) `
            -NewExists (Test-Path -LiteralPath $script:Config.SettingsPath)
        if ($act -eq 'take') {
            if (-not (Test-Path -LiteralPath $newSet)) { [void](New-Item -Path $newSet -ItemType Directory -Force) }
            foreach ($f in @(Get-ChildItem -LiteralPath $oldSet -File -ErrorAction SilentlyContinue)) {
                Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $newSet $f.Name) -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch { }

    try {
        $act = Get-MigrationAction -OldExists (Test-Path -LiteralPath $oldBak) -NewExists (Test-Path -LiteralPath $newBak)
        if ($act -eq 'take') {
            # Verschieben statt kopieren: Sicherungen koennen hunderte
            # Megabyte gross sein. Klappt es nicht (Datei in Benutzung,
            # anderes Laufwerk), bleibt einfach der alte Ordner in Gebrauch.
            try { Move-Item -LiteralPath $oldBak -Destination $newBak -ErrorAction Stop }
            catch { $script:Config.BackupDir = $oldBak }
        }
        elseif ($act -eq 'keep') {
            # Beide Ordner vorhanden - der neue gilt, der alte bleibt
            # unangetastet liegen.
        }
    }
    catch { }
}

function Start-EBOptimizer {
    Register-CrashHandlers
    # Hintergrundlaeufe haben eigene Variablen. Der Sicherungsordner geht
    # deshalb ueber die Umgebung mit, statt ueber $script:Config.
    try { $env:EB_BACKUP_DIR = $script:Config.BackupDir } catch { }
    Import-LegacyAppData
    Import-AppSettings
    Import-ChangeLog
    Set-Language -Code $script:Config.CurrentLang | Out-Null

    # ---- Single instance ---------------------------------------------------
    # Two elevated copies would fight over the registry backups, the log file
    # and settings.json. The second start just focuses the first window.
    $isFirst = $false
    try {
        $script:AppMutex = New-Object System.Threading.Mutex($true, 'Global\EB_OPTIMIZER_v13_5', [ref]$isFirst)
    }
    catch {
        # No mutex (policy / unusual session) -> never block the start
        $script:AppMutex = $null
        $isFirst = $true
    }

    if (-not $isFirst) {
        try {
            $hwnd = [EBHost.Native]::FindWindow($null, "$($script:Config.AppName) v$($script:Config.Version)")
            if ($hwnd -ne [IntPtr]::Zero) {
                if ([EBHost.Native]::IsIconic($hwnd)) { [void][EBHost.Native]::ShowWindow($hwnd, 9) }  # SW_RESTORE
                [void][EBHost.Native]::SetForegroundWindow($hwnd)
            }
            else {
                [void][System.Windows.Forms.MessageBox]::Show(
                    (Get-Text 'SingleMsg'), (Get-Text 'SingleTitle'),
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
        catch { }
        try { if ($script:AppMutex) { $script:AppMutex.Dispose(); $script:AppMutex = $null } } catch { }
        return
    }

    # Muss vor dem Erzeugen der Fenster laufen, damit Rollbalken dunkel sind
    Enable-DarkTitleTheme

    Show-Splash

    $form = New-MainForm
    Register-Shortcuts -Form $form

    $form.Add_Shown({
            # Acrylic needs an existing window handle - that is why this runs here
            try { Enable-EBAcrylic -Form $script:MainForm } catch { }

            # Windows 11: rounded window corners (ignored on Windows 10)
            try {
                $pref = 2   # DWMWCP_ROUND
                [void][EBHost.Native]::DwmSetWindowAttribute($script:MainForm.Handle, 33, [ref]$pref, 4)
            }
            catch { }

            # Mouse wheel scrolls whatever is under the cursor
            try { [System.Windows.Forms.Application]::AddMessageFilter((New-Object EBHost.WheelFilter)) } catch { }

            Write-Log "$(Get-Text 'Welcome')" 'TITLE'
            Write-Log "$($script:Config.AppName) v$($script:Config.Version) - $(Get-Text 'Ready')" 'SUCCESS'
            try { Write-Log (Get-WindowsRelease).Text 'SYSTEM' } catch { }
            Write-Log "$(Get-Text 'ShortcutInfo')  |  F1 = $(Get-Text 'MenuHelp')" 'INFO'
            if ($script:LogFilePath) { Write-Log "$(Get-Text 'LogFile'): $script:LogFilePath" 'INFO' }

            # Einmalig beim Start: steht noch ein Neustart aus? Mehrere Tweaks
            # und jede SFC-Reparatur wirken erst danach.
            try {
                $rr = @(Get-PendingRebootReasons -State (Read-PendingRebootState -ForceRefresh))
                if ($rr.Count -gt 0 -and -not $script:RebootWarned) {
                    $script:RebootWarned = $true
                    Write-Log "$(Get-Text 'RebootNeeded') ($(($rr | ForEach-Object { Get-Text $_ }) -join ', '))" 'WARNING'
                }
            }
            catch { }

            if ($script:Config.RememberWin -and $script:Config.WinMaximized) {
                $script:MainForm.WindowState = 'Maximized'
            }

            $startView = if ($script:Config.RestoreView -and $script:ViewMap.Contains($script:Config.LastView)) {
                $script:Config.LastView
            }
            else { 'Dashboard' }

            Set-View -ViewName $startView
            if ($script:Config.LogCollapsed) { Set-LogCollapsed -Collapsed $true }
            Initialize-TrayIcon
            Update-LiveStats
            Start-Monitoring
        })

    $form.Add_FormClosing({
            # Stops deferred/debounced timers from touching dying controls
            $script:Shutdown = $true
            [void](Export-AppSettings)
            Stop-AppResources
        })

    $form.Add_FormClosed({ Stop-AppFonts })

    [System.Windows.Forms.Application]::Run($form)

    try { $form.Dispose() } catch { }
}

Start-EBOptimizer

#endregion 8. TIMER, SHORTCUTS, STARTUP
