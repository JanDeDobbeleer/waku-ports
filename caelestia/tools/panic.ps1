# Emergency stop: quits waku, brings the Windows taskbar back, and kills a stuck waku if it did not quit.
# Run it from any PowerShell: pwsh -NoProfile -File D:\waku-ports\caelestia\tools\panic.ps1
$home_ = 'D:\waku-ports\caelestia'
$wakuc = 'D:\waku\dist\waku\wakuc.exe'
& $wakuc --config-home $home_ quit 2>&1 | Out-Null
Start-Sleep -Seconds 4
$left = Get-Process waku -ErrorAction SilentlyContinue
if ($left) {
  # Only a waku that runs this config home; leave any other copy alone.
  foreach ($p in $left) {
    $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)").CommandLine
    if ($cmd -match [regex]::Escape($home_)) { Stop-Process -Id $p.Id -Force }
  }
}
# The engine restores the taskbar on a clean quit; after a forced stop, show it explicitly.
Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class Tb {
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindow(string c, string t);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
}
'@
$h = [Tb]::FindWindow('Shell_TrayWnd', $null)
if ($h -ne [IntPtr]::Zero) { [void][Tb]::ShowWindow($h, 8) }   # SW_SHOWNA
'waku stopped, taskbar shown.'
