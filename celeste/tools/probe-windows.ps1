# One launch: lists waku's top-level windows (rect, ex style, DPI, monitor rect), then opens the
# sidebar, session and OSD in turn and saves right-strip crops (x 3040..3840) to shots\edge\.
# Full captures are deleted at once. Read-only: no input, no work area reserved (--no-app-bar), --no-tray.
param(
  [string]$Home_ = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$Tag = 'before',
  [string]$Bin = $(if ($env:WAKU_BIN) { $env:WAKU_BIN } else { Join-Path $PSScriptRoot '..\bin' }),
  [int]$SettleSeconds = 25
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System; using System.Text; using System.Collections.Generic; using System.Runtime.InteropServices;
public static class PW {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int i);
  [DllImport("user32.dll")] static extern uint GetDpiForWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L,T,R,B; }
  public static List<string> Of(uint want) {
    var l = new List<string>();
    EnumWindows((h, x) => {
      uint pid; GetWindowThreadProcessId(h, out pid); if (pid != want) return true;
      RECT r; GetWindowRect(h, out r); var t = new StringBuilder(128); GetWindowText(h, t, 128);
      var c = new StringBuilder(128); GetClassName(h, c, 128);
      l.Add(string.Format("vis={0} ex={1:X} dpi={2} rect=[{3},{4},{5},{6}] size={7}x{8} {9} '{10}'", IsWindowVisible(h) ? 1 : 0,
        GetWindowLong(h, -20), GetDpiForWindow(h), r.L, r.T, r.R, r.B, r.R - r.L, r.B - r.T, c, t));
      return true; }, IntPtr.Zero);
    return l; }
}
'@
[void][PW]::SetProcessDPIAware()
Add-Type -AssemblyName System.Windows.Forms
$mon = [Windows.Forms.Screen]::PrimaryScreen
"monitor bounds=$($mon.Bounds) working=$($mon.WorkingArea)"
$exe = Join-Path $Bin 'waku.exe'; $wc = Join-Path $Bin 'wakuc.exe'
$out = Join-Path $Home_ 'shots\edge'; New-Item -ItemType Directory -Force $out | Out-Null
$logs = Join-Path $Home_ 'logs'; New-Item -ItemType Directory -Force $logs | Out-Null
$env:QT_FORCE_STDERR_LOGGING = '1'
$p = Start-Process $exe -ArgumentList @('--config-home', $Home_, '--no-tray', '--no-app-bar', '--font-engine=directwrite', '--import-path', (Join-Path $Home_ 'modules')) -PassThru -WindowStyle Hidden -RedirectStandardError (Join-Path $logs 'edge.err.txt') -RedirectStandardOutput (Join-Path $logs 'edge.out.txt')
function Crop($name, $x, $y, $w, $h) {
  $full = Join-Path $env:TEMP "waku_edge_full.png"
  & (Join-Path $PSScriptRoot 'shot.ps1') -Out $full | Out-Null
  $im = [Drawing.Bitmap]::FromFile($full)
  $c = $im.Clone((New-Object Drawing.Rectangle $x, $y, $w, $h), $im.PixelFormat)
  $c.Save((Join-Path $out "$Tag-$name.png")); $c.Dispose(); $im.Dispose()
  Remove-Item -LiteralPath $full -Force
}
try {
  $ready = $false
  for ($i = 0; $i -lt 40 -and -not $ready; $i++) {
    Start-Sleep -Seconds 4
    if ($p.HasExited) { 'exited early'; break }
    if ((& $wc --config-home $Home_ status 2>&1 | Out-String) -match 'windows=([1-9])') { $ready = $true }
  }
  Start-Sleep -Seconds $SettleSeconds
  "== windows (idle)"; [PW]::Of($p.Id)
  $states = @(
    @{ n = 'sidebar'; cmd = @('shortcut', 'sidebar') },
    @{ n = 'session'; cmd = @('shortcut', 'session') },
    @{ n = 'osd'; cmd = @('call', 'drawers', 'toggle', 'osd') })
  foreach ($s in $states) {
    & $wc --config-home $Home_ @($s.cmd) 2>&1 | Out-Null; Start-Sleep -Seconds 4
    Crop $s.n 3040 0 800 2560
    if ($s.n -eq 'sidebar') { "== windows (sidebar open)"; [PW]::Of($p.Id) }
    & $wc --config-home $Home_ @($s.cmd) 2>&1 | Out-Null; Start-Sleep -Seconds 2
  }
} finally {
  & $wc --config-home $Home_ quit 2>&1 | Out-Null
  if (-not $p.WaitForExit(8000)) { Stop-Process -Id $p.Id -Force; 'killed' }
}
