# Instantiates every singleton under modules\qs\{services,utils} and every daemon once, then
# reports load failures. Runs waku on a generated config home (smoke\loadcheck), read only.
param([int]$Seconds = 10, [string]$Bin = $(if ($env:WAKU_BIN) { $env:WAKU_BIN } else { Join-Path $PSScriptRoot '..\bin' }))
$ErrorActionPreference = 'Stop'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$home_ = Join-Path $port 'smoke\loadcheck'
New-Item -ItemType Directory -Force $home_ | Out-Null
$single = @(); $daemons = @()
foreach ($dir in 'services', 'utils') {
  Get-ChildItem (Join-Path $port "modules\qs\$dir") -Filter *.qml | ForEach-Object {
    if (Select-String -LiteralPath $_.FullName -Pattern '^\s*pragma\s+Singleton' -Quiet) { $single += $_.BaseName }
  }
}
Get-ChildItem (Join-Path $port 'modules\qs\daemons') -Filter *.qml | ForEach-Object { $daemons += $_.BaseName }
$q = @('import QtQuick', 'import Quickshell', 'import qs.services', 'import qs.utils', 'import qs.daemons', 'ShellRoot {')
foreach ($d in $daemons) { $q += "    $d {}" }
$q += '    Component.onCompleted: {'
foreach ($s in $single) { $q += "        try { void $s; console.log('LOADED $s', typeof $s, String($s) !== 'null') } catch (e) { console.log('LOADFAIL $s', e) }" }
$q += '    }', '}'
[IO.File]::WriteAllText((Join-Path $home_ 'shell.qml'), ($q -join "`n"), (New-Object Text.UTF8Encoding $false))
$env:QT_FORCE_STDERR_LOGGING = '1'
$err = Join-Path $port 'logs\load.err.txt'; New-Item -ItemType Directory -Force (Split-Path $err) | Out-Null
$args_ = @('--config-home', $home_, '--no-tray', '--no-app-bar', '--keep-taskbar', '--no-keys', '--no-tiling', '--font-engine=directwrite', '--import-path', (Join-Path $port 'modules'))
$p = Start-Process (Join-Path $Bin 'waku.exe') -ArgumentList $args_ -RedirectStandardError $err -RedirectStandardOutput (Join-Path $port 'logs\load.out.txt') -PassThru -WindowStyle Hidden
try { Start-Sleep -Seconds $Seconds; & (Join-Path $Bin 'wakuc.exe') --config-home $home_ status } finally {
  & (Join-Path $Bin 'wakuc.exe') --config-home $home_ quit
  if (-not $p.WaitForExit(5000)) { Stop-Process -Id $p.Id -Force }
}
$log = @(Get-Content $err, (Join-Path $port 'logs\load.out.txt') -ErrorAction SilentlyContinue)
$ok = 0; $bad = @()
foreach ($s in $single) { if ($log -match "LOADED $s ") { $ok++; Write-Host "ok    $s" } else { $bad += $s; Write-Host "FAIL  $s" } }
$errs = @($log | Where-Object { $_ -match 'qml:.*(Error|error)|TypeError|ReferenceError|unavailable|is not a type|Unable to assign' -and $_ -notmatch 'LOADED' })
$errs | Select-Object -First 40 | ForEach-Object { Write-Host $_ }
Write-Host "singletons ok: $ok, failed: $($bad.Count); daemons instantiated: $($daemons -join ', '); error lines: $($errs.Count)"
if ($bad.Count -or $errs.Count) { exit 1 }
