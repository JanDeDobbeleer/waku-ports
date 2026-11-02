# Starts Noctalia on its own config home, lists IPC targets, opens panels through `wabarc call`
# and takes a screenshot of each. Shots hold the full desktop (private): keep them in shots\.
param(
  [string]$Bin = 'D:\wabar-compat\build\arm64-release',
  [string]$Steps = 'launcher toggle', # ';'-separated "target function [args]"; closed again with the same call
  [int]$Boot = 12
)
$ErrorActionPreference = 'Stop'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$env:PATH += ';C:\Program Files\komorebi\bin'
$env:NOCTALIA_CONFIG_DIR = Join-Path $port 'state\config'
$env:NOCTALIA_CACHE_DIR = Join-Path $port 'state\cache'
$env:HOME = $env:USERPROFILE
$env:QT_FORCE_STDERR_LOGGING = '1'
$logs = Join-Path $port 'logs'; New-Item -ItemType Directory -Force $logs | Out-Null
$wabar = Join-Path $Bin 'wabar.exe'; $wabarc = Join-Path $Bin 'wabarc.exe'
if (Get-Process wabar -ErrorAction SilentlyContinue) { throw 'a wabar shell is running; stop it first' }
$p = Start-Process -FilePath $wabar -PassThru -WindowStyle Hidden `
  -RedirectStandardError (Join-Path $logs 'visual.err.txt') -RedirectStandardOutput (Join-Path $logs 'visual.out.txt') `
  -ArgumentList @('--config-home', $port, '--no-tray', '--font-engine=directwrite')
try {
  Start-Sleep -Seconds $Boot
  & $wabarc --config-home $port status
  & $wabarc --config-home $port call
  $i = 0
  foreach ($s in ($Steps -split ';')) {
    $i++
    $a = $s -split ' '
    Write-Host "== $s"
    & $wabarc --config-home $port call @a
    Start-Sleep -Seconds 3
    & (Join-Path $PSScriptRoot 'shot.ps1') -Out ("visual-{0:d2}.png" -f $i)
    & $wabarc --config-home $port call @a
    Start-Sleep -Seconds 1
  }
  Write-Host '== qml problems'
  Get-Content (Join-Path $logs 'visual.err.txt') | Where-Object { $_ -match 'qml:.*(rror|arning|ailed)|TypeError|ReferenceError|not (a )?(type|defined)' } |
    Select-Object -Unique -First 40
} finally {
  & $wabarc --config-home $port quit
  if (-not $p.WaitForExit(5000)) { Stop-Process -Id $p.Id -Force; Write-Host 'killed' }
}
