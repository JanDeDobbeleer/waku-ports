# Makes Windows start noctalia at sign-in: writes a waku.lnk in the Startup folder that runs
# tools\start.ps1. An old wabar.lnk or waku.lnk is moved to a .bak file first.
[CmdletBinding(SupportsShouldProcess)]
param()
$ErrorActionPreference = 'Stop'
$startup = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
$script = (Resolve-Path (Join-Path $PSScriptRoot 'start.ps1')).Path
foreach ($old in 'wabar.lnk', 'waku.lnk') {
  $path = Join-Path $startup $old
  if ((Test-Path -LiteralPath $path) -and $PSCmdlet.ShouldProcess($path, 'move to .bak')) {
    Move-Item -LiteralPath $path -Destination "$path.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  }
}
if ($PSCmdlet.ShouldProcess($startup, 'create waku.lnk')) {
  $link = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $startup 'waku.lnk'))
  $link.TargetPath = (Get-Command pwsh).Source
  $link.Arguments = "-NoProfile -WindowStyle Hidden -File `"$script`""
  $link.WindowStyle = 7
  $link.Description = 'waku with the noctalia port'
  $link.Save()
}
