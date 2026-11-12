# Downloads the waku release pinned in tools\waku.json into .cache\waku\<version>: the engine (from
# the MSIX, which is a zip) under engine\ and the QML type metadata under qml-types\. Verifies both
# against the release's checksums.txt. Does nothing when the folder is already complete.
param(
  [string]$Version,
  [ValidateSet('x64', 'arm64')][string]$Arch
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $Version) { $Version = (Get-Content (Join-Path $PSScriptRoot 'waku.json') -Raw | ConvertFrom-Json).version }
if (-not $Arch) { $Arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' } }

$dest = Join-Path $root ".cache\waku\$Version"
$engine = Join-Path $dest 'engine'
$types = Join-Path $dest 'qml-types'
if ((Test-Path (Join-Path $engine 'waku.exe')) -and (Test-Path (Join-Path $types 'Quickshell\qmldir'))) {
  Write-Output $dest
  return
}

$base = "https://github.com/JanDeDobbeleer/waku/releases/download/v$Version"
$dl = Join-Path $dest 'download'
New-Item -ItemType Directory -Force $dl | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-Asset([string]$name) {
  $file = Join-Path $dl $name
  for ($i = 1; $i -le 3; $i++) {
    try { Invoke-WebRequest -Uri "$base/$name" -OutFile $file -UseBasicParsing; return $file }
    catch {
      if ($i -eq 3) { throw "cannot download $base/$name ($($_.Exception.Message)). Does waku v$Version ship it?" }
      Start-Sleep -Seconds (2 * $i)
    }
  }
}

$sums = Get-Content (Get-Asset 'checksums.txt')
foreach ($name in @("waku-$Arch.msix", 'waku-qml-types.zip')) {
  $file = Get-Asset $name
  $line = $sums | Where-Object { $_ -match "\s\*?$([regex]::Escape($name))$" } | Select-Object -First 1
  if (-not $line) { throw "checksums.txt of v$Version has no entry for $name" }
  $want = ($line -split '\s+')[0]
  $got = (Get-FileHash $file -Algorithm SHA256).Hash
  if ($got -ne $want) { throw "checksum mismatch for $name" }
}

# Expand-Archive only takes .zip names.
$msixZip = Join-Path $dl "waku-$Arch.zip"
Copy-Item (Join-Path $dl "waku-$Arch.msix") $msixZip -Force
Remove-Item $engine, $types -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive $msixZip $engine -Force
Expand-Archive (Join-Path $dl 'waku-qml-types.zip') $types -Force
Remove-Item $dl -Recurse -Force
Write-Output $dest
