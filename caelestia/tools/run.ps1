# Starts wabar on a config home, reports status and log problems, optionally fires a shortcut and a
# screenshot, then quits. Always passes --no-tray. Never use a real user config home.
param(
  [Alias('Home')][string]$ConfigHome = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [int]$Seconds = 8,
  [string[]]$Shortcut, # one or more, fired in order, 2 s apart
  [string]$Shot,
  [int]$Toast = 0, # raise this many test toasts (tools	oast.ps1) before the shortcut and shot
  [string]$Bin = 'D:\wabar\build\arm64-debug'
)
$ErrorActionPreference = 'Stop'
$env:QT_FORCE_STDERR_LOGGING = '1' # Qt writes qml: messages to stderr only with this
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logs = Join-Path $port 'logs'
New-Item -ItemType Directory -Force $logs | Out-Null
$err = Join-Path $logs 'run.err.txt'; $out = Join-Path $logs 'run.out.txt'
$wabar = Join-Path $Bin 'wabar.exe'; $wabarc = Join-Path $Bin 'wabarc.exe'
$launch = @('--config-home', $ConfigHome, '--no-tray', '--font-engine=directwrite')
# A smoke shell has its own config home; the port's modules still resolve through --import-path.
if ((Resolve-Path $ConfigHome).Path.TrimEnd([char]92) -ne $port.TrimEnd([char]92)) { $launch += @('--import-path', (Join-Path $port 'modules')) }
$p = Start-Process -FilePath $wabar -ArgumentList $launch -RedirectStandardError $err `
  -RedirectStandardOutput $out -PassThru -WindowStyle Hidden
try {
  Start-Sleep -Seconds $Seconds
  Write-Host "== status (pid $($p.Id), exited: $($p.HasExited))"
  & $wabarc --config-home $ConfigHome status
  if ($Toast -gt 0) { & (Join-Path $PSScriptRoot 'toast.ps1') -Count $Toast; Start-Sleep -Seconds 2 }
  foreach ($sc in ($Shortcut -split ",")) {
    Write-Host "== shortcut $sc"
    & $wabarc --config-home $ConfigHome shortcut $sc
    Start-Sleep -Seconds 2
  }
  if ($Shot) { & (Join-Path $PSScriptRoot 'shot.ps1') -Out $Shot }
  Write-Host '== log problems (max 60)'
  $hits = @(Get-Content $err, $out -ErrorAction SilentlyContinue |
    Where-Object { $_ -match 'qml:|error|Error|warning' })
  $hits | Select-Object -First 60 | ForEach-Object { Write-Host $_ }
  Write-Host "($($hits.Count) matching lines)"
} finally {
  & $wabarc --config-home $ConfigHome quit
  if (-not $p.WaitForExit(5000)) { Stop-Process -Id $p.Id -Force; Write-Host 'killed' }
}
