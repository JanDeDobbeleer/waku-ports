# Rewrites upstream QML that uses Caelestia's attached Config/Tokens types for the port's
# singletons: `root.Config.bar.x` becomes `Config.bar.x`, and the per-screen lines
# `contentItem.Config.screen: screen.name` are removed. Run it on a copied tree, in place.
param(
  [Parameter(Mandatory)][string]$Path,
  [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$files = Get-ChildItem -LiteralPath $Path -Recurse -Filter *.qml -File
$changed = 0
foreach ($f in $files) {
  $text = [IO.File]::ReadAllText($f.FullName)
  $new = [regex]::Replace($text, '(?m)^[ \t]*[A-Za-z_][\w.]*\.(Config|Tokens)\.screen[ \t]*:.*\r?\n', '')
  $new = [regex]::Replace($new, '\b[A-Za-z_]\w*\.(Config|Tokens)\.(?=[a-z])', '$1.')
  if ($new -cne $text) {
    $changed++
    if (-not $WhatIf) { [IO.File]::WriteAllText($f.FullName, $new, (New-Object Text.UTF8Encoding $false)) }
    Write-Host ("{0}: {1}" -f ($(if ($WhatIf) { 'would change' } else { 'changed' })), $f.FullName)
  }
}
Write-Host "$changed of $($files.Count) files"
