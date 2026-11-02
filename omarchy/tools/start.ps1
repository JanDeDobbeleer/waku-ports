# Starts this port through the shared launcher, D:\waku-ports\start.ps1. Kept so the old path works.
#   .\tools\start.ps1          live: your deployed engine, tray, app bar, Windows taskbar hidden
#   .\tools\start.ps1 -Dev     the bundled engine, hidden, no tray, no app bar, taskbar left alone
param([string]$Waku = 'D:\waku\dist\waku\waku.exe', [switch]$Dev, [switch]$DryRun)
& (Join-Path $PSScriptRoot '..\..\start.ps1') -Port omarchy -Waku $Waku -Dev:$Dev -DryRun:$DryRun
