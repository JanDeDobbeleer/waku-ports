# Shared by gen-themes.ps1 (the shipped theme files) and wallpaper-theme.ps1 (the one computed theme).
# Dot-source it: . (Join-Path $PSScriptRoot 'theme-lib.ps1')

function Read-ThemeColors([string]$path) {
  $colors = @{}
  foreach ($line in Get-Content $path) {
    if ($line -match '^\s*([A-Za-z0-9_]+)\s*=\s*"([^"]*)"') { $colors[$Matches[1]] = $Matches[2] }
  }
  $colors
}

# Renders default\themed\shell.toml.tpl for one palette, with LF line endings.
function Render-ShellToml([string]$template, [hashtable]$colors) {
  function Resolve-Color([string]$name) { if ($colors.ContainsKey($name)) { $colors[$name] } else { $name } }
  function Mix([string]$a, [string]$b, [string]$pct) {
    $p = [double]($pct.TrimEnd('%')) / 100.0
    $ca = (Resolve-Color $a).TrimStart('#'); $cb = (Resolve-Color $b).TrimStart('#')
    $out = '#'
    foreach ($i in 0, 2, 4) {
      $x = [Convert]::ToInt32($ca.Substring($i, 2), 16); $y = [Convert]::ToInt32($cb.Substring($i, 2), 16)
      $out += ('{0:x2}' -f [int][Math]::Round($x * $p + $y * (1 - $p)))
    }
    $out
  }
  $text = [regex]::Replace($template, '\{\{\s*([^}]*?)\s*\}\}', {
    param($m)
    $parts = $m.Groups[1].Value -split '\s+'
    switch ($parts[0]) {
      'mix' { Mix $parts[1] $parts[2] $parts[3] }
      # the theme's Hyprland gradient has no Windows meaning: the first colour stands in for it
      'shell_gradient' { Resolve-Color $parts[2] }
      default { Resolve-Color $parts[0] }
    }
  })
  $text -replace "`r`n", "`n"
}
