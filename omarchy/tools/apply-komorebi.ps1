# Applies this port's komorebi settings: backs up the current komorebi.json, writes the one from this
# port's komorebi folder with the border colours of the current Omarchy theme, and asks komorebi to
# reload it. Run it from anywhere, and again after a theme change; -WhatIf shows what it would do,
# -KeepColours copies the file as shipped (Catppuccin).
[CmdletBinding(SupportsShouldProcess)]
param([string]$KomorebiHome = (Join-Path $env:USERPROFILE '.config\komorebi'), [switch]$KeepColours)
$ErrorActionPreference = 'Stop'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$name = Split-Path $port -Leaf
$source = Join-Path $port 'komorebi\komorebi.json'
$target = Join-Path $KomorebiHome 'komorebi.json'
$utf8 = New-Object Text.UTF8Encoding $false
$text = [IO.File]::ReadAllText($source)

if (-not $KeepColours) {
  # The theme the shell is on: theme-apply.ps1 copies its colors.toml here.
  $colorsPath = Join-Path $port 'state\home\.local\state\omarchy\current\theme\colors.toml'
  if (Test-Path -LiteralPath $colorsPath) {
    $c = @{}
    foreach ($line in Get-Content -LiteralPath $colorsPath) {
      if ($line -match '^\s*([A-Za-z0-9_]+)\s*=\s*"(#[0-9a-fA-F]{6})"') { $c[$Matches[1]] = $Matches[2] }
    }
    $map = [ordered]@{ single = 'accent'; stack = 'accent'; monocle = 'accent'; floating = 'yellow'; unfocused = 'muted'; unfocused_locked = 'orange' }
    foreach ($key in $map.Keys) {
      $hex = $c[$map[$key]]
      if ($hex) { $text = [regex]::Replace($text, '("' + $key + '"\s*:\s*")#[0-9a-fA-F]{6}(")', { param($m) $m.Groups[1].Value + $hex + $m.Groups[2].Value }) }
    }
  } else {
    Write-Warning "no theme colours at $colorsPath; using the shipped ones"
  }
}

New-Item -ItemType Directory -Force -Path $KomorebiHome | Out-Null
if (Test-Path -LiteralPath $target) {
  $backup = "$target.bak-before-$name-$(Get-Date -Format yyyyMMdd-HHmmss)"
  if ($PSCmdlet.ShouldProcess($target, "back up to $backup")) { Copy-Item -LiteralPath $target -Destination $backup }
}
if ($PSCmdlet.ShouldProcess($target, "write the $name settings")) {
  [IO.File]::WriteAllText($target, $text, $utf8)
  & komorebic.exe reload-configuration
}
