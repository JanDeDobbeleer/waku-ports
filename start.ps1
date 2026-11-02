# Starts one port as the bar: stops any waku that is running, loads that port's environment, and starts
# the deployed engine on it. One launcher for every port; what is port-specific lives in the port, in
# <port>\tools\env.ps1.
#
#   .\start.ps1 -Port omarchy          the live setup: your engine, tray, app bar, Windows taskbar hidden
#   .\start.ps1 -Port omarchy -Dev     the port's own bundled engine (<port>\bin), hidden, no tray, no app bar
#   .\start.ps1 -Port noctalia -DryRun print what would run, change nothing
#
# A port's tools\env.ps1 is run in this script's scope. It may set environment variables and run any
# pre-start step, and may set $PortFlags (extra waku arguments). It can read $Dev and $PortDir.
param(
  [Parameter(Mandatory)][ValidateSet('caelestia', 'noctalia', 'omarchy')][string]$Port,
  [string]$Waku = 'D:\waku\dist\waku\waku.exe',
  [switch]$Dev,
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$PortDir = Join-Path $PSScriptRoot $Port
if (-not (Test-Path (Join-Path $PortDir 'shell.qml'))) { throw "$Port has no shell.qml in $PortDir" }

# 1. one shell at a time: ask each running waku to quit (the engine puts the taskbar back when it does)
& (Join-Path $PSScriptRoot 'stop.ps1') -DryRun:$DryRun

# 2. the port's own environment and pre-start step
$PortFlags = @()
$hook = Join-Path $PortDir 'tools\env.ps1'
if ($DryRun) {
  Write-Host "would run $hook"
} elseif (Test-Path $hook) {
  . $hook
}

# 3. the engine and its flags
if ($Dev) {
  $Waku = Join-Path $PortDir 'bin\waku.exe'
  $flags = @('--config-home', $PortDir, '--no-tray', '--font-engine=directwrite') + $PortFlags
} else {
  $flags = @('--config-home', $PortDir, '--font-engine=directwrite', '--register-app-bar', '--hide-taskbar') + $PortFlags
}
if (-not (Test-Path $Waku)) { throw "engine not found: $Waku" }
if ($DryRun) {
  Write-Host "would start: `"$Waku`" $($flags -join ' ')"
  return
}
$logs = Join-Path $PortDir 'logs'; New-Item -ItemType Directory -Force $logs | Out-Null
if ($Dev) {
  $p = Start-Process $Waku -PassThru -WindowStyle Hidden -ArgumentList $flags `
    -RedirectStandardError (Join-Path $logs 'shell.err.txt') -RedirectStandardOutput (Join-Path $logs 'shell.out.txt')
} else {
  $p = Start-Process $Waku -PassThru -WorkingDirectory (Split-Path $Waku) -ArgumentList $flags
}
Write-Host "$Port started, pid $($p.Id)"
