# Stops the Omarchy shell started by start.ps1.
param([string]$Bin = (Join-Path $PSScriptRoot '..\bin'))
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
& (Join-Path $Bin 'wakuc.exe') --config-home $root quit
