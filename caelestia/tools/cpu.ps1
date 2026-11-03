# Starts waku on a config home and prints the CPU seconds it used over a 5 s window after a warm-up.
param([Parameter(Mandatory)][string]$ConfigHome, [int]$Warmup = 8, [string]$Bin = $(if ($env:WAKU_BIN) { $env:WAKU_BIN } else { Join-Path $PSScriptRoot '..\bin' }))
$env:QT_FORCE_STDERR_LOGGING = '1'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$l = @('--config-home', $ConfigHome, '--no-tray', '--font-engine=directwrite', '--import-path', (Join-Path $port 'modules'))
$p = Start-Process (Join-Path $Bin 'waku.exe') -ArgumentList $l -PassThru -WindowStyle Hidden -RedirectStandardError (Join-Path $port 'logs\cpu.err.txt') -RedirectStandardOutput (Join-Path $port 'logs\cpu.out.txt')
Start-Sleep $Warmup; $p.Refresh(); $a = $p.TotalProcessorTime.TotalSeconds; Start-Sleep 5; $p.Refresh(); $b = $p.TotalProcessorTime.TotalSeconds
"{0}: cpu {1:N2}s over 5s, ws {2:N0} MB" -f (Split-Path $ConfigHome -Leaf), ($b - $a), ($p.WorkingSet64 / 1MB)
& (Join-Path $Bin 'wakuc.exe') --config-home $ConfigHome quit | Out-Null
if (-not $p.WaitForExit(6000)) { $p.Kill() }
