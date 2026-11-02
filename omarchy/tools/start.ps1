# Starts the Omarchy shell and leaves it running (hidden window, no tray).
#   .\tools\start.ps1          start
#   .\tools\stop.ps1           stop
# Uses the port's own home (state\home), so the real user profile is not touched.
param([string]$Bin = (Join-Path $PSScriptRoot '..\bin'))
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$env:HOME = Join-Path $root 'state\home'
$env:OMARCHY_PATH = $root
$env:QT_FORCE_STDERR_LOGGING = '1'
# Git for Windows' bash and find first (the shell runs bash scripts), then komorebi for workspaces.
$env:PATH = 'C:\Program Files\Git\usr\bin;' + $env:PATH + ';C:\Program Files\komorebi\bin'
$logs = Join-Path $root 'logs'; New-Item -ItemType Directory -Force $logs | Out-Null
# the saved theme (Catppuccin the first time), and the previews the theme switcher lists
& (Join-Path $PSScriptRoot 'theme-apply.ps1') -Prepare
& (Join-Path $PSScriptRoot 'theme-apply.ps1') | Out-Null
$p = Start-Process (Join-Path $Bin 'waku.exe') -PassThru -WindowStyle Hidden `
  -ArgumentList @('--config-home', $root, '--no-tray', '--font-engine=directwrite') `
  -RedirectStandardError (Join-Path $logs 'shell.err.txt') -RedirectStandardOutput (Join-Path $logs 'shell.out.txt')
Write-Host "omarchy shell started, pid $($p.Id). Menu: Ctrl+Alt+Space   Apps: Ctrl+Alt+Shift+Space"
