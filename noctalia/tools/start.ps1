# Starts this port through the shared launcher, D:\waku-ports\start.ps1. Kept so the Startup shortcut that
# points here keeps working.
param([string]$Waku = 'D:\waku\dist\waku\waku.exe', [switch]$Dev, [switch]$DryRun)
& (Join-Path $PSScriptRoot '..\..\start.ps1') -Port noctalia -Waku $Waku -Dev:$Dev -DryRun:$DryRun
