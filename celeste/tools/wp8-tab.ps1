# Opens the dashboard on one tab, captures, crops the top centre and deletes the full capture.
param([int]$Tab = 0, [int]$Seconds = 70, [string]$Crop = '800,0,2240,1000', [double]$Scale = 0.5)
$ErrorActionPreference = 'Stop'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$env:CELESTE_DASH_TAB = "$Tab"
$full = Join-Path $port "shots\full$Tab.png"
& (Join-Path $PSScriptRoot 'run.ps1') -Home $port -Seconds $Seconds -Shortcut dashboard -Shot $full
$c = $Crop -split ',' | ForEach-Object { [int]$_ }
& (Join-Path $PSScriptRoot 'crop.ps1') $full (Join-Path $port "shots\tab$Tab.png") $c[0] $c[1] $c[2] $c[3] $Scale
Remove-Item -LiteralPath $full
