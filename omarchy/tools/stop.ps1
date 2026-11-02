# Stops every running waku through the shared launcher, D:\waku-ports\stop.ps1. Kept so the old path works.
param([switch]$DryRun)
& (Join-Path $PSScriptRoot '..\..\stop.ps1') -DryRun:$DryRun
