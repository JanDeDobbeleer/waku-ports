# One state of the harness: one.ps1 -Name x -Open launcher -Search 'fire' -Wait 8
param([string]$Name = 'x', [string]$Open = 'launcher', [string]$Search = '', [int]$Wait = 8)
$port = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$env:CAELESTIA_WALLPAPERS_DIR = Join-Path $port 'assets'
Remove-Item Env:CAELESTIA_ALLOW_ACTIONS -ErrorAction SilentlyContinue
$env:WP6_OPEN = $Open; $env:WP6_SEARCH = $Search
& (Join-Path $port 'tools\run.ps1') -Home (Join-Path $port 'smoke\wp6') -Seconds $Wait -Shot "wp6-$Name.png" | Where-Object { $_ -notmatch '^(ok|shot)' }
& (Join-Path $port 'tools\crop.ps1') -In "shots\wp6-$Name.png" -Out "shots\wp6-$Name-c.png" -Rect '590,310,1380,1080'
