# Runs smoke\livecheck.qml on the live desktop: a shell with no windows that registers SystemStat, scans
# Wi-Fi and prints what the ported services report. Uses its own config home, so a running shell is
# never touched; --no-tray keeps Explorer alone. Prints the LIVE| lines.
param([string]$Bin = (Join-Path $PSScriptRoot '..\bin'), [int]$MaxSeconds = 60)
$ErrorActionPreference = 'Stop'
$env:QT_FORCE_STDERR_LOGGING = '1'
$env:PATH += ';C:\Program Files\komorebi\bin'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$env:NOCTALIA_CONFIG_DIR = Join-Path $port 'state\config'; $env:NOCTALIA_CACHE_DIR = Join-Path $port 'state\cache'
$env:HOME = $env:USERPROFILE
New-Item -ItemType Directory -Force $env:NOCTALIA_CONFIG_DIR, $env:NOCTALIA_CACHE_DIR | Out-Null
$home_ = Join-Path $port 'smoke\livecheck2'
$wc = Join-Path $Bin 'wakuc.exe'
$existing = (& $wc --config-home $home_ status 2>&1 | Out-String)
if ($existing -match 'running; pid=') { throw 'a shell already runs for the livecheck home' }
Copy-Item -LiteralPath (Join-Path $port 'smoke\livecheck.qml') -Destination (Join-Path $home_ 'shell.qml') -Force
$err = Join-Path $port 'logs\livecheck.err.txt'
$p = Start-Process (Join-Path $Bin 'waku.exe') -PassThru -WindowStyle Hidden -RedirectStandardError $err -RedirectStandardOutput "$err.out" `
  -ArgumentList @('--config-home', $home_, '--no-tray', '--import-path', (Join-Path $port 'modules'))
$t0 = Get-Date
try {
  while (((Get-Date) - $t0).TotalSeconds -lt $MaxSeconds) {
    Start-Sleep -Seconds 2
    if ($p.HasExited) { break }
    if (Select-String -LiteralPath $err -Pattern 'LIVE\|DONE' -Quiet -ErrorAction SilentlyContinue) { break }
  }
} finally {
  & $wc --config-home $home_ quit 2>&1 | Out-Null
  if (-not $p.WaitForExit(6000)) { Stop-Process -Id $p.Id -Force }
}
Get-Content $err, "$err.out" -ErrorAction SilentlyContinue | Where-Object { $_ -match 'LIVE\||TypeError|ReferenceError|unavailable|is not a type' } | ForEach-Object { $_ -replace '^qml: ', '' }
