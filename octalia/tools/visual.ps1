# Starts Octalia on its own config home, lists IPC targets, opens panels through `wakuc call`
# and takes a screenshot of each. Shots hold the full desktop (private): keep them in shots\.
param(
  [string]$Bin = $(if ($env:WAKU_BIN) { $env:WAKU_BIN } else { Join-Path $PSScriptRoot '..\bin' }),
  [string]$Steps = 'launcher toggle', # ';'-separated "target function [args]"; closed again with the same call
  [int]$Boot = 12
)
$ErrorActionPreference = 'Stop'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$env:OCTALIA_CONFIG_DIR = Join-Path $port 'state\config'
$env:OCTALIA_CACHE_DIR = Join-Path $port 'state\cache'
$env:HOME = $env:USERPROFILE
$env:QT_FORCE_STDERR_LOGGING = '1'
$logs = Join-Path $port 'logs'; New-Item -ItemType Directory -Force $logs | Out-Null
$waku = Join-Path $Bin 'waku.exe'; $wakuc = Join-Path $Bin 'wakuc.exe'
if (Get-Process waku -ErrorAction SilentlyContinue) { throw 'a waku shell is running; stop it first' }
$p = Start-Process -FilePath $waku -PassThru -WindowStyle Hidden `
  -RedirectStandardError (Join-Path $logs 'visual.err.txt') -RedirectStandardOutput (Join-Path $logs 'visual.out.txt') `
  -ArgumentList @('--config-home', $port, '--no-tray', '--no-app-bar', '--font-engine=directwrite')
try {
  Start-Sleep -Seconds $Boot
  & $wakuc --config-home $port status
  & $wakuc --config-home $port call
  $i = 0
  foreach ($s in ($Steps -split ';')) {
    $i++
    $a = $s -split ' '
    Write-Host "== $s"
    & $wakuc --config-home $port call @a
    Start-Sleep -Seconds 3
    & (Join-Path $PSScriptRoot 'shot.ps1') -Out ("visual-{0:d2}.png" -f $i)
    & $wakuc --config-home $port call @a
    Start-Sleep -Seconds 1
  }
  Write-Host '== qml problems'
  Get-Content (Join-Path $logs 'visual.err.txt') | Where-Object { $_ -match 'qml:.*(rror|arning|ailed)|TypeError|ReferenceError|not (a )?(type|defined)' } |
    Select-Object -Unique -First 40
} finally {
  & $wakuc --config-home $port quit
  if (-not $p.WaitForExit(5000)) { Stop-Process -Id $p.Id -Force; Write-Host 'killed' }
}
