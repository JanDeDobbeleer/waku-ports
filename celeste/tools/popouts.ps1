# Opens each bar flyout through the test IPC (bar popout <name>) on its own copy of the shell and
# saves a capture of the flyout rectangle only. Never moves the cursor or sends input.
# One launch: starts waku on -ConfigHome, waits for the IPC, captures, quits only its own pid.
param(
  [Alias('Home')][string]$ConfigHome = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string[]]$Names = @('network', 'bluetooth', 'battery', 'audio', 'activewindow'),
  [string]$Out = (Join-Path $PSScriptRoot '..\shots'),
  [string]$Bin = $(if ($env:WAKU_BIN) { $env:WAKU_BIN } else { Join-Path $PSScriptRoot '..\bin' })
)
$ErrorActionPreference = 'Stop'
$env:QT_FORCE_STDERR_LOGGING = '1'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logs = Join-Path $port 'logs'; New-Item -ItemType Directory -Force $logs, $Out | Out-Null
$waku = Join-Path $Bin 'waku.exe'; $wakuc = Join-Path $Bin 'wakuc.exe'
$p = Start-Process -FilePath $waku -PassThru -WindowStyle Hidden `
  -RedirectStandardError (Join-Path $logs 'popouts.err.txt') -RedirectStandardOutput (Join-Path $logs 'popouts.out.txt') `
  -ArgumentList @('--config-home', $ConfigHome, '--no-tray', '--no-app-bar', '--font-engine=directwrite', '--import-path', (Join-Path $port 'modules'))
try {
  $ready = $false
  for ($i = 0; $i -lt 60 -and -not $ready; $i++) {
    Start-Sleep -Seconds 2
    $r = & $wakuc --config-home $ConfigHome call bar popoutState 2>&1 | Out-String
    $ready = $r -match '(true|false) \d+'
  }
  Write-Host "ready: $ready (pid $($p.Id))"
  Write-Host "entries: $(& $wakuc --config-home $ConfigHome call bar entries 2>&1 | Out-String)"
  Write-Host "bt: $(& $wakuc --config-home $ConfigHome call bar btDevices 2>&1 | Out-String)"
  foreach ($n in $Names) {
    Write-Host "== $n : $(& $wakuc --config-home $ConfigHome call bar popout $n 2>&1 | Out-String)"
    Start-Sleep -Seconds 5
    $st = (& $wakuc --config-home $ConfigHome call bar popoutState 2>&1 | Out-String).Trim()
    Write-Host "state: $st"
    $f = $st -split '\s+'
    if ($f.Count -ge 6 -and [int]$f[4] -gt 0) {
      $pad = 24
      $x = [Math]::Max(0, [int]$f[2] - $pad); $y = [Math]::Max(0, [int]$f[3] - $pad)
      & (Join-Path $PSScriptRoot 'shot.ps1') -Out (Join-Path $Out "popout-$n.png") -Crop "$x,$y,$([int]$f[4] + 2 * $pad),$([int]$f[5] + 2 * $pad)"
    }
    & $wakuc --config-home $ConfigHome call bar popoutClose | Out-Null
    Start-Sleep -Milliseconds 800
  }
  # The bar strip with the status icons.
  & (Join-Path $PSScriptRoot 'shot.ps1') -Out (Join-Path $Out 'barstrip.png') -Crop '0,0,160,2560'
  Get-Content (Join-Path $logs 'popouts.err.txt'), (Join-Path $logs 'popouts.out.txt') -ErrorAction SilentlyContinue |
    Where-Object { $_ -match 'qml:|rror|arning' } | Select-Object -First 40
} finally {
  & $wakuc --config-home $ConfigHome quit
  if (-not $p.WaitForExit(8000)) { Stop-Process -Id $p.Id -Force; Write-Host 'killed own pid' }
}
