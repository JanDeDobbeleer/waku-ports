# Makes Windows start a port at sign-in: writes waku.lnk in the Startup folder that runs
# D:\waku-ports\start.ps1 -Port <port>. An existing waku.lnk or wabar.lnk is moved to a .bak file first.
#   .\install-startup.ps1 -Port omarchy
#   .\install-startup.ps1 -Port omarchy -WhatIf     show what it would do
[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][ValidateSet('caelestia', 'noctalia', 'omarchy')][string]$Port)
$ErrorActionPreference = 'Stop'
$startup = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
$script = (Resolve-Path (Join-Path $PSScriptRoot 'start.ps1')).Path
foreach ($old in 'wabar.lnk', 'waku.lnk') {
  $path = Join-Path $startup $old
  if ((Test-Path -LiteralPath $path) -and $PSCmdlet.ShouldProcess($path, 'move to .bak')) {
    Move-Item -LiteralPath $path -Destination "$path.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  }
}
if ($PSCmdlet.ShouldProcess($startup, "create waku.lnk for $Port")) {
  $link = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $startup 'waku.lnk'))
  $link.TargetPath = (Get-Command pwsh).Source
  $link.Arguments = "-NoProfile -WindowStyle Hidden -File `"$script`" -Port $Port"
  $link.WindowStyle = 7
  $link.Description = "waku with the $Port port"
  $link.Save()
  Write-Host "Startup now runs: $script -Port $Port"
}
