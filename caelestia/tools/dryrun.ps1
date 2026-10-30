# Safe check of the launcher commands. Starts a private wabar on THIS worktree with
# CAELESTIA_DRYRUN=1 (and the engine's own WABAR_WALLPAPER_DRYRUN=1), runs each launcher action
# through the debug IPC (`call launcher action <name>`), and prints the DRYRUN / REFUSED log lines.
# Nothing changes on the machine. A second run (-Restore) shows the saved colour choice.
param(
  [switch]$Restore,
  [string]$Bin = 'D:\wabar\dist\wabar'
)
$ErrorActionPreference = 'Stop'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logs = Join-Path $port 'logs'
New-Item -ItemType Directory -Force $logs | Out-Null
$err = Join-Path $logs 'dryrun.err.txt'; $out = Join-Path $logs 'dryrun.out.txt'
$env:QT_FORCE_STDERR_LOGGING = '1'
$env:CAELESTIA_DRYRUN = '1'
$env:WABAR_WALLPAPER_DRYRUN = '1'
$env:CAELESTIA_WALLPAPERS_DIR = Join-Path $port 'assets'
$wabar = Join-Path $Bin 'wabar.exe'; $wabarc = Join-Path $Bin 'wabarc.exe'
$p = Start-Process -FilePath $wabar -PassThru -WindowStyle Hidden -RedirectStandardError $err -RedirectStandardOutput $out `
  -ArgumentList @('--config-home', $port, '--import-path', (Join-Path $port 'modules'), '--font-engine=directwrite', '--no-tray')
function Call([string[]]$a) { "{0} -> {1}" -f ($a -join ' '), (& $wabarc --config-home $port call @a 2>&1 | Out-String).Trim() }
try {
  Start-Sleep -Seconds 12
  Call @('launcher', 'actions')
  Call @('launcher', 'state')
  if (-not $Restore) {
    foreach ($n in 'Dark', 'Random', 'Lock', 'Sleep', 'Shutdown', 'Reboot', 'Logout', 'Light') { Call @('launcher', 'action', $n); Start-Sleep -Milliseconds 700 }
    $wp = Get-ChildItem (Join-Path $port 'assets') -Include *.webp, *.png, *.jpg -Recurse | Select-Object -First 1
    if ($wp) { Call @('wallpaper', 'set', $wp.FullName.Replace('\', '/')) }
    Start-Sleep -Seconds 2
    Call @('launcher', 'state')
  }
  Write-Host '== log lines'
  Get-Content $err, $out -ErrorAction SilentlyContinue | Where-Object { $_ -match 'DRYRUN|REFUSED|Toaster|ReferenceError|TypeError|Unable to assign|is not a|not installed|qml:.*(Error|error)' } | Select-Object -First 60
} finally {
  & $wabarc --config-home $port quit | Out-Null
  if (-not $p.WaitForExit(6000)) { Stop-Process -Id $p.Id -Force; Write-Host 'killed own pid' }
}
