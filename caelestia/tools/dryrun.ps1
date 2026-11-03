# Safe check of the launcher commands. Starts a private waku on THIS worktree with
# CAELESTIA_DRYRUN=1 (and the engine's own WAKU_WALLPAPER_DRYRUN=1), runs each launcher action
# through the debug IPC (`call launcher action <name>`), and prints the DRYRUN / REFUSED log lines.
# Nothing changes on the machine. A second run (-Restore) shows the saved colour choice.
param(
  [switch]$Restore,
  [string]$Bin = $(if ($env:WAKU_BIN) { $env:WAKU_BIN } else { Join-Path $PSScriptRoot '..\bin' })
)
$ErrorActionPreference = 'Stop'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logs = Join-Path $port 'logs'
New-Item -ItemType Directory -Force $logs | Out-Null
$err = Join-Path $logs 'dryrun.err.txt'; $out = Join-Path $logs 'dryrun.out.txt'
$env:QT_FORCE_STDERR_LOGGING = '1'
$env:CAELESTIA_DRYRUN = '1'
$env:WAKU_WALLPAPER_DRYRUN = '1'
$env:CAELESTIA_WALLPAPERS_DIR = Join-Path $port 'assets'
$waku = Join-Path $Bin 'waku.exe'; $wakuc = Join-Path $Bin 'wakuc.exe'
$p = Start-Process -FilePath $waku -PassThru -WindowStyle Hidden -RedirectStandardError $err -RedirectStandardOutput $out `
  -ArgumentList @('--config-home', $port, '--import-path', (Join-Path $port 'modules'), '--font-engine=directwrite', '--no-tray')
function Call([string[]]$a) { "{0} -> {1}" -f ($a -join ' '), (& $wakuc --config-home $port call @a 2>&1 | Out-String).Trim() }
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
  & $wakuc --config-home $port quit | Out-Null
  if (-not $p.WaitForExit(6000)) { Stop-Process -Id $p.Id -Force; Write-Host 'killed own pid' }
}
