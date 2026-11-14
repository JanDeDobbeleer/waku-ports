# Downloads the latest waku release (or -Version) into .cache\waku\<version>: the engine (from the
# MSIX, which is a zip) under engine\ and the QML type metadata under qml-types\. Verifies both
# against the release's checksums.txt, keeps only that version in the cache and prints its folder.
# Does nothing when the folder is already complete. -Resolve prints the version without downloading.
# Without network it falls back to the newest complete version in the cache.
param(
  [string]$Version,
  [ValidateSet('x64', 'arm64')][string]$Arch,
  [switch]$Resolve
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$cache = Join-Path $root '.cache\waku'
$repo = 'https://github.com/JanDeDobbeleer/waku'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Test-Complete([string]$dir) {
  (Test-Path (Join-Path $dir 'engine\waku.exe')) -and (Test-Path (Join-Path $dir 'qml-types\Quickshell\qmldir'))
}

# releases/latest redirects to releases/tag/v<version>. Reading the redirect needs no API token
# and is not rate limited.
function Get-LatestVersion {
  $request = [Net.HttpWebRequest]::Create("$repo/releases/latest")
  $request.AllowAutoRedirect = $false
  $request.UserAgent = 'waku-ports'
  $response = $request.GetResponse()
  try { $location = $response.Headers['Location'] } finally { $response.Close() }
  if ($location -notmatch '/tag/v([^/]+)$') { throw "unexpected redirect for the latest waku release: $location" }
  $matches[1]
}

if (-not $Version) {
  try { $Version = Get-LatestVersion }
  catch {
    $cached = Get-ChildItem $cache -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Complete $_.FullName } |
      Sort-Object { try { [version]$_.Name } catch { [version]'0.0' } } | Select-Object -Last 1
    if (-not $cached) { throw "cannot find the latest waku release ($($_.Exception.Message)) and nothing is cached" }
    Write-Warning "cannot reach GitHub, using cached waku $($cached.Name)"
    $Version = $cached.Name
  }
}
if ($Resolve) {
  Write-Output $Version
  return
}
if (-not $Arch) { $Arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' } }

$dest = Join-Path $cache $Version
$engine = Join-Path $dest 'engine'
$types = Join-Path $dest 'qml-types'
if (Test-Complete $dest) {
  Write-Output $dest
  return
}

$base = "$repo/releases/download/v$Version"
$dl = Join-Path $dest 'download'
New-Item -ItemType Directory -Force $dl | Out-Null

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
Get-ChildItem $cache -Directory | Where-Object Name -ne $Version | Remove-Item -Recurse -Force
Write-Output $dest