# Starts this port through the shared launcher, start.ps1 in the repo root. Kept so the Startup shortcut that
# points here keeps working.
param([string]$Waku, [switch]$Dev, [switch]$DryRun)
$extra = @{}; if ($Waku) { $extra.Waku = $Waku }
& (Join-Path $PSScriptRoot '..\..\start.ps1') -Port octalia @extra -Dev:$Dev -DryRun:$DryRun
