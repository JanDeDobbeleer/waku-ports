# Starts the Omarchy shell as the bar, the way the other ports start: your deployed waku engine,
# Windows' tray hooked, the bar registered as an app bar (it reserves the top of the screen) and the
# Windows taskbar hidden while it runs.
#   .\tools\start.ps1            start (live)
#   .\tools\start.ps1 -Dev       the port's bundled engine, hidden, no tray, no app bar, taskbar left alone
#   .\tools\stop.ps1             stop
# The shell uses the port's own home (state\home), so your user profile is not touched.
param(
  [string]$Waku = 'D:\waku\dist\waku\waku.exe',
  [switch]$Dev
)
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

if ($Dev) {
  $Waku = Join-Path $root 'bin\waku.exe'
  $flags = @('--config-home', $root, '--no-tray', '--font-engine=directwrite')
  $p = Start-Process $Waku -PassThru -WindowStyle Hidden -ArgumentList $flags `
    -RedirectStandardError (Join-Path $logs 'shell.err.txt') -RedirectStandardOutput (Join-Path $logs 'shell.out.txt')
} else {
  $flags = @('--config-home', $root, '--font-engine=directwrite', '--register-app-bar', '--hide-taskbar')
  $p = Start-Process $Waku -PassThru -WorkingDirectory (Split-Path $Waku) -ArgumentList $flags
}
Write-Host "omarchy shell started, pid $($p.Id). Menu: Ctrl+Alt+Space   Apps: Ctrl+Alt+Shift+Space"
