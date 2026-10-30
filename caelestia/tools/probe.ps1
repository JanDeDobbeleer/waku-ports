# Starts wabar on a config home, lists the top-level windows of the process (rect, styles, z
# order) and runs WindowFromPoint on sample points, optionally after a shortcut and a shot.
# Read-only: sends no input. Always passes --no-tray, never --register-app-bar.
param(
  [Alias('Home')][string]$ConfigHome = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [int]$Seconds = 10,
  [string]$Shortcut,
  [string]$Shot,
  [string]$Bin = 'D:\wabar\build\arm64-debug'
)
Add-Type @'
using System; using System.Text; using System.Collections.Generic; using System.Runtime.InteropServices;
public static class P {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int i);
  [DllImport("user32.dll")] public static extern IntPtr WindowFromPoint(POINT p);
  [DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr h, uint f);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L,T,R,B; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X,Y; public POINT(int x,int y){X=x;Y=y;} }
  public static List<IntPtr> All() { var l=new List<IntPtr>(); EnumWindows((h,x)=>{l.Add(h);return true;},IntPtr.Zero); return l; }
  public static string Info(IntPtr h) {
    uint pid; GetWindowThreadProcessId(h,out pid); RECT r; GetWindowRect(h,out r);
    var t=new StringBuilder(128); GetWindowText(h,t,128); var c=new StringBuilder(128); GetClassName(h,c,128);
    return string.Format("{0:X} pid={1} vis={2} ex={3:X} [{4},{5},{6},{7}] {8} '{9}'",h.ToInt64(),pid,IsWindowVisible(h),GetWindowLong(h,-20),r.L,r.T,r.R,r.B,c,t);
  }
}
'@
[P]::SetProcessDPIAware() | Out-Null
$env:QT_FORCE_STDERR_LOGGING = '1'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$wabar = Join-Path $Bin 'wabar.exe'; $wabarc = Join-Path $Bin 'wabarc.exe'
$launch = @('--config-home', $ConfigHome, '--no-tray', '--font-engine=directwrite')
if ((Resolve-Path $ConfigHome).Path.TrimEnd([char]92) -ne $port.TrimEnd([char]92)) { $launch += @('--import-path', (Join-Path $port 'modules')) }
$p = Start-Process -FilePath $wabar -ArgumentList $launch -PassThru -WindowStyle Hidden `
  -RedirectStandardError (Join-Path $port 'logs\probe.err.txt') -RedirectStandardOutput (Join-Path $port 'logs\probe.out.txt')
try {
  Start-Sleep -Seconds $Seconds
  & $wabarc --config-home $ConfigHome status
  if ($Shortcut) { & $wabarc --config-home $ConfigHome shortcut $Shortcut; Start-Sleep -Seconds 2 }
  $order = 0
  foreach ($h in [P]::All()) { $order++; $pidv = 0; [void][P]::GetWindowThreadProcessId($h, [ref]$pidv)
    if ($pidv -eq $p.Id) { "z=$order " + [P]::Info($h) } }
  foreach ($pt in @(@(20,500), @(40,300), @(1280,853), @(1280,400), @(2400,853), @(1280,10), @(1280,1700))) {
    $h = [P]::WindowFromPoint((New-Object P+POINT $pt[0], $pt[1]))
    $root = [P]::GetAncestor($h, 2)
    "point $($pt -join ',') -> " + [P]::Info($root)
  }
  if ($Shot) { & (Join-Path $PSScriptRoot 'shot.ps1') -Out $Shot }
} finally {
  & $wabarc --config-home $ConfigHome quit
  if (-not $p.WaitForExit(8000)) { Stop-Process -Id $p.Id -Force }
}
