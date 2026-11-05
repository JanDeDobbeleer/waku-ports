# Installs the two fonts Celeste needs, for the current user only (no admin rights):
#   Material Symbols Rounded  every icon     Apache-2.0, google/material-design-icons
#   Google Sans Flex          the UI text    SIL OFL 1.1, google/fonts
# They are downloaded from upstream, not shipped in this repo. Restart waku afterwards.
#   .\tools\install-fonts.ps1
#   .\tools\install-fonts.ps1 -Force      download and install again
[CmdletBinding()]
param([switch]$Force)
$ErrorActionPreference = 'Stop'
$fonts = @(
  @{ Name = 'Material Symbols Rounded'; File = 'MaterialSymbolsRounded.ttf'
     Url = 'https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf' },
  @{ Name = 'Google Sans Flex'; File = 'GoogleSansFlex.ttf'
     Url = 'https://github.com/google/fonts/raw/main/ofl/googlesansflex/GoogleSansFlex%5BROND%2Copsz%2Cslnt%2Cwdth%2Cwght%5D.ttf' }
)
$dir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
New-Item -ItemType Directory -Force $dir | Out-Null
New-Item -Force $key | Out-Null
foreach ($f in $fonts) {
  $target = Join-Path $dir $f.File
  $value = "$($f.Name) (TrueType)"
  if ((Test-Path $target) -and (Get-ItemProperty $key -Name $value -ErrorAction SilentlyContinue) -and -not $Force) {
    Write-Host "$($f.Name): already installed"; continue
  }
  Write-Host "$($f.Name): downloading"
  $tmp = Join-Path ([IO.Path]::GetTempPath()) $f.File
  Invoke-WebRequest -Uri $f.Url -OutFile $tmp -UseBasicParsing
  if ((Get-Item $tmp).Length -lt 100KB) { throw "$($f.Name): download looks wrong ($tmp)" }
  Copy-Item $tmp $target -Force
  Remove-Item $tmp
  New-ItemProperty -Path $key -Name $value -Value $target -PropertyType String -Force | Out-Null
  Write-Host "$($f.Name): installed to $target"
}
Write-Host 'Done. Restart waku so it sees the new fonts.'
