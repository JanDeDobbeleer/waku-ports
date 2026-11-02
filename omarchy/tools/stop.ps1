# Stops the Omarchy shell started by start.ps1. The engine puts the Windows taskbar back on exit.
#   .\tools\stop.ps1         the live engine
#   .\tools\stop.ps1 -Dev    the bundled engine
param([switch]$Dev, [string]$Waku = 'D:\waku\dist\waku')
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$bin = if ($Dev) { Join-Path $root 'bin' } else { $Waku }
& (Join-Path $bin 'wakuc.exe') --config-home $root quit
