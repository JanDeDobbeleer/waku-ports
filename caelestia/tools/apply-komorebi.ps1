# Applies this port's komorebi settings: backs up the current komorebi.json, copies the one from
# this port's komorebi folder and asks komorebi to reload it. Run it from anywhere; -WhatIf shows
# what it would do.
[CmdletBinding(SupportsShouldProcess)]
param([string]$KomorebiHome = (Join-Path $env:USERPROFILE '.config\komorebi'))
$ErrorActionPreference = 'Stop'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$name = Split-Path $port -Leaf
$source = Join-Path $port 'komorebi\komorebi.json'
$target = Join-Path $KomorebiHome 'komorebi.json'
New-Item -ItemType Directory -Force -Path $KomorebiHome | Out-Null
if ((Test-Path -LiteralPath $target) -and ((Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $source).Hash)) {   # no backup of an identical file
  $backup = "$target.bak-before-$name-$(Get-Date -Format yyyyMMdd-HHmmss)"
  if ($PSCmdlet.ShouldProcess($target, "back up to $backup")) { Copy-Item -LiteralPath $target -Destination $backup }
}
if ($PSCmdlet.ShouldProcess($target, "copy $source")) {
  Copy-Item -LiteralPath $source -Destination $target -Force
  & komorebic.exe reload-configuration
}
