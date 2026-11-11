[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('MaterialSymbolsRounded', 'GoogleSansFlex', 'CaskaydiaMonoNerdFont')]
  [string[]]$Font,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$catalog = @{
  MaterialSymbolsRounded = @{
    Family = 'Material Symbols Rounded'
    File = 'MaterialSymbolsRounded.ttf'
    Url = 'https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf'
  }
  GoogleSansFlex = @{
    Family = 'Google Sans Flex'
    File = 'GoogleSansFlex.ttf'
    Url = 'https://github.com/google/fonts/raw/main/ofl/googlesansflex/GoogleSansFlex%5BROND%2Copsz%2Cslnt%2Cwdth%2Cwght%5D.ttf'
  }
  CaskaydiaMonoNerdFont = @{
    Family = 'CaskaydiaMono Nerd Font'
    ArchiveUrl = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip'
    Prefix = 'CaskaydiaMonoNerdFont'
    Styles = @(
      'Regular', 'Bold', 'Italic', 'BoldItalic',
      'ExtraLight', 'ExtraLightItalic', 'Light', 'LightItalic',
      'SemiLight', 'SemiLightItalic', 'SemiBold', 'SemiBoldItalic'
    )
  }
}

$dir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
New-Item -ItemType Directory -Force $dir | Out-Null
if (-not (Test-Path $key)) { New-Item -Path $key | Out-Null }

foreach ($fontName in $Font) {
  $spec = $catalog[$fontName]
  $entries = @()
  if ($spec.Styles) {
    foreach ($style in $spec.Styles) {
      $entries += [pscustomobject]@{
        File = "$($spec.Prefix)-$style.ttf"
        ValueName = "$($spec.Family) $style (TrueType)"
      }
    }
  } else {
    $entries = @([pscustomobject]@{
      File = $spec.File
      ValueName = "$($spec.Family) (TrueType)"
    })
  }

  $pending = @()
  foreach ($entry in $entries) {
    $target = Join-Path $dir $entry.File
    $registered = Get-ItemProperty -Path $key -Name $entry.ValueName -ErrorAction SilentlyContinue
    if ($Force -or -not ((Test-Path $target) -and $registered)) {
      $pending += $entry
    }
  }
  if ($pending.Count -eq 0) {
    Write-Host "$($spec.Family): already installed"
    continue
  }

  $workDir = Join-Path ([IO.Path]::GetTempPath()) ('waku-fonts-' + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $workDir | Out-Null
  try {
    if ($spec.ArchiveUrl) {
      $archive = Join-Path $workDir 'font.zip'
      $extractDir = Join-Path $workDir 'extracted'
      Invoke-WebRequest -Uri $spec.ArchiveUrl -OutFile $archive -UseBasicParsing
      Expand-Archive -LiteralPath $archive -DestinationPath $extractDir
    }

    foreach ($entry in $pending) {
      $source = if ($spec.ArchiveUrl) {
        Join-Path $extractDir $entry.File
      } else {
        $download = Join-Path $workDir $entry.File
        Invoke-WebRequest -Uri $spec.Url -OutFile $download -UseBasicParsing
        $download
      }
      if (-not (Test-Path $source)) { throw "$($spec.Family): expected font file not found ($($entry.File))" }
      if ((Get-Item $source).Length -lt 100KB) { throw "$($spec.Family): download looks wrong ($source)" }

      $target = Join-Path $dir $entry.File
      Copy-Item -LiteralPath $source -Destination $target -Force
      New-ItemProperty -Path $key -Name $entry.ValueName -Value $target -PropertyType String -Force | Out-Null
      Write-Host "$($entry.ValueName): installed to $target"
    }
  } finally {
    Remove-Item -LiteralPath $workDir -Recurse -Force
  }
}

Write-Host 'Done. Restart waku so it sees the new fonts.'
