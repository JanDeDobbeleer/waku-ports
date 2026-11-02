# Starts the noctalia port as the bar: the settings and cache folders it needs, komorebic on PATH,
# then waku with this port as the config home. Used by the Startup shortcut (tools\install-startup.ps1).
param([string]$Waku = 'D:\waku\dist\waku\waku.exe')
$ErrorActionPreference = 'Stop'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$env:PATH += ';C:\Program Files\komorebi\bin'
$env:NOCTALIA_CONFIG_DIR = Join-Path $port 'state\config'
$env:NOCTALIA_CACHE_DIR = Join-Path $port 'state\cache'
$env:HOME = $env:USERPROFILE
New-Item -ItemType Directory -Force $env:NOCTALIA_CONFIG_DIR, $env:NOCTALIA_CACHE_DIR | Out-Null
Start-Process -FilePath $Waku -WorkingDirectory (Split-Path $Waku) -ArgumentList @(
  '--config-home', $port, '--import-path', (Join-Path $port 'modules'),
  '--font-engine=directwrite', '--register-app-bar', '--hide-taskbar')
