# The wallpaper theme is the only theme computed at run time: it takes a palette from the wallpaper and
# renders colors.toml and shell.toml into the state folder the shell watches. Every other theme ships
# ready in themes\<name>\ (see gen-themes.ps1).
#   wallpaper-theme.ps1 -PaletteB64 <base64 json> [-ExpectedTheme @wallpaper]
# -ExpectedTheme makes the script do nothing when the saved theme changed while the palette was computed.
# Works in Windows PowerShell 5.1 (the shell runs it) and PowerShell 7.
param([Parameter(Mandatory)][string]$PaletteB64, [string]$ExpectedTheme = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'theme-lib.ps1')
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$current = Join-Path $root 'state\home\.local\state\nomarchy\current'
$themeOut = Join-Path $current 'theme'
$utf8 = New-Object Text.UTF8Encoding $false
New-Item -ItemType Directory -Force $themeOut | Out-Null

if ($ExpectedTheme) {
  $idFile = Join-Path $current 'theme.name'
  $saved = if (Test-Path $idFile) { (Get-Content $idFile -Raw).Trim() } else { '' }
  if ("@$saved" -ne $ExpectedTheme) { return }
}

$palette = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($PaletteB64)) | ConvertFrom-Json
$keys = 'mode','accent','selection','muted','background','dark_background','darker_background','lighter_background',
  'foreground','dark_foreground','light_foreground','bright_foreground','red','yellow','orange','green','cyan','blue',
  'magenta','brown','bright_red','bright_yellow','bright_green','bright_cyan','bright_blue','bright_magenta'
$lines = foreach ($key in $keys) {
  $value = [string]$palette.$key
  if (($key -eq 'mode' -and $value -notin @('dark', 'light')) -or
      ($key -ne 'mode' -and $value -notmatch '^#[0-9a-fA-F]{6}$')) { throw "invalid wallpaper color: $key" }
  "$key = `"$value`""
}
$colorsToml = ($lines -join "`n") + "`n"
$colorsPath = Join-Path $themeOut 'colors.toml'
[IO.File]::WriteAllText($colorsPath, $colorsToml, $utf8)

$template = [IO.File]::ReadAllText((Join-Path $root 'default\themed\shell.toml.tpl'))
[IO.File]::WriteAllText((Join-Path $themeOut 'shell.toml'), (Render-ShellToml $template (Read-ThemeColors $colorsPath)), $utf8)
Write-Host 'theme wallpaper'
