# Loads every component file of modules\qs\components in a throwaway shell and reports which fail.
#
# For each .qml file the shell calls Qt.createComponent (compile + import check). Files without
# required properties and whose root is not a window are also instantiated once. Types that need
# parameters or that are windows are compile-checked only and listed as such. Singletons are
# skipped (they cannot be created) and listed.
#
# One waku process loads the files one after another and logs "LOADALL|BEGIN|file" before each.
# If waku hangs or exits mid-run, the file named by the last BEGIN is recorded as CRASH and the
# run restarts with the rest. Needs an engine build: set WAKU_BIN, or copy one to bin\.
param(
  [string]$Components = (Join-Path $PSScriptRoot '..\modules\qs\components'),
  [string]$Stubs = (Join-Path $PSScriptRoot '..\smoke\wp3\modules'),
  [string]$Bin = $(if ($env:WAKU_BIN) { $env:WAKU_BIN } else { Join-Path $PSScriptRoot '..\bin' }),
  [int]$IdleSeconds = 20,
  [int]$MaxSeconds = 180,
  [string[]]$Only
)
$ErrorActionPreference = 'Stop'
$env:QT_FORCE_STDERR_LOGGING = '1'
$port = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$root = (Resolve-Path -LiteralPath $Components).Path.TrimEnd('\')
$work = Join-Path $port 'logs\loadall'
$home_ = Join-Path $work 'home'
Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force (Join-Path $home_ 'modules') | Out-Null
# Stub modules (qs.services, qs.utils, M3Shapes ...) only for URIs the port does not provide yet.
if (Test-Path -LiteralPath $Stubs) {
  $stubRoot = (Resolve-Path -LiteralPath $Stubs).Path.TrimEnd('\')
  Get-ChildItem -LiteralPath $stubRoot -Recurse -Filter qmldir | ForEach-Object {
    $rel = $_.DirectoryName.Substring($stubRoot.Length + 1)
    if (-not (Test-Path -LiteralPath (Join-Path $port "modules\$rel\qmldir"))) {
      $dst = Join-Path $home_ "modules\$rel"
      New-Item -ItemType Directory -Force $dst | Out-Null
      Copy-Item -Path (Join-Path $_.DirectoryName '*') -Destination $dst -Force
    }
  }
}

$entries = @()
$skipped = @()
foreach ($f in (Get-ChildItem -LiteralPath $root -Recurse -Filter *.qml -File | Sort-Object FullName)) {
  $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
  if ($Only -and -not ($Only | Where-Object { $rel -like $_ })) { continue }
  $text = [IO.File]::ReadAllText($f.FullName)
  if ($text -match '(?m)^\s*pragma\s+Singleton\b') { $skipped += [pscustomobject]@{ File = $rel; Why = 'singleton' }; continue }
  $needsParams = $text -match '(?m)^\s*required\s+'
  $isWindow = $text -match '(?m)^(PanelWindow|FloatingWindow|PopupWindow|Window)\s*\{'
  $entries += [pscustomobject]@{ File = $rel; Url = ('file:///' + $f.FullName.Replace('\', '/')); Create = (-not $needsParams -and -not $isWindow); Note = $(if ($needsParams) { 'required properties' } elseif ($isWindow) { 'window root' } else { '' }) }
}

$results = @{}
$remaining = [System.Collections.Generic.List[object]]($entries)
$iteration = 0
while ($remaining.Count -gt 0) {
  $iteration++
  $js = ($remaining | ForEach-Object { '{rel:"' + $_.File + '",url:"' + $_.Url + '",create:' + ($_.Create.ToString().ToLower()) + '}' }) -join ",`n    "
  $shell = @"
import QtQuick
import Quickshell

ShellRoot {
  id: root
  property var entries: [
    $js
  ]
  property int idx: 0
  Item { id: holder; visible: false }
  Timer {
    interval: 20; running: true; repeat: true
    onTriggered: {
      if (root.idx >= root.entries.length) { console.log("LOADALL|DONE"); running = false; return; }
      const e = root.entries[root.idx++];
      console.log("LOADALL|BEGIN|" + e.rel);
      const c = Qt.createComponent(e.url);
      if (c.status === Component.Error) {
        console.log("LOADALL|FAIL|" + e.rel + "|" + c.errorString().replace(/\r?\n/g, " ; "));
        return;
      }
      if (c.status !== Component.Ready) { console.log("LOADALL|FAIL|" + e.rel + "|status " + c.status); return; }
      if (!e.create) { console.log("LOADALL|COMPILED|" + e.rel); return; }
      const o = c.createObject(holder);
      if (o) { console.log("LOADALL|OK|" + e.rel); } else { console.log("LOADALL|FAIL|" + e.rel + "|" + c.errorString().replace(/\r?\n/g, " ; ")); }
    }
  }
}
"@
  [IO.File]::WriteAllText((Join-Path $home_ 'shell.qml'), $shell, (New-Object Text.UTF8Encoding $false))
  $err = Join-Path $work "run$iteration.err.txt"; $out = Join-Path $work "run$iteration.out.txt"
  $launch = @('--config-home', $home_, '--no-tray', '--no-app-bar', '--keep-taskbar', '--no-keys', '--no-tiling', '--font-engine=directwrite', '--import-path', (Join-Path $port 'modules'))
  $p = Start-Process -FilePath (Join-Path $Bin 'waku.exe') -ArgumentList $launch -RedirectStandardError $err -RedirectStandardOutput $out -PassThru -WindowStyle Hidden
  $sw = [Diagnostics.Stopwatch]::StartNew(); $lastSize = -1; $idle = [Diagnostics.Stopwatch]::StartNew(); $done = $false
  while ($sw.Elapsed.TotalSeconds -lt $MaxSeconds) {
    Start-Sleep -Milliseconds 500
    $size = (Get-Item -LiteralPath $err).Length
    if ($size -ne $lastSize) { $lastSize = $size; $idle.Restart() }
    $tail = Get-Content -LiteralPath $err -Tail 5 -ErrorAction SilentlyContinue
    if ($tail -match 'LOADALL\|DONE') { $done = $true; break }
    if ($p.HasExited -or $idle.Elapsed.TotalSeconds -gt $IdleSeconds) { break }
  }
  & (Join-Path $Bin 'wakuc.exe') --config-home $home_ quit 2>$null | Out-Null
  if (-not $p.WaitForExit(5000)) { Stop-Process -Id $p.Id -Force }
  $lines = @(Get-Content -LiteralPath $err, $out -ErrorAction SilentlyContinue | Where-Object { $_ -match 'LOADALL\|' })
  $last = $null
  foreach ($l in $lines) {
    if ($l -match 'LOADALL\|BEGIN\|(.+)$') { $last = $Matches[1]; continue }
    if ($l -match 'LOADALL\|(OK|COMPILED)\|(.+)$') { $results[$Matches[2]] = [pscustomobject]@{ Status = $Matches[1]; Detail = '' }; $last = $null; continue }
    if ($l -match 'LOADALL\|FAIL\|([^|]+)\|(.*)$') { $results[$Matches[1]] = [pscustomobject]@{ Status = 'FAIL'; Detail = $Matches[2] }; $last = $null; continue }
  }
  if ($done) { break }
  if ($last) { $results[$last] = [pscustomobject]@{ Status = 'CRASH'; Detail = 'waku hung or exited while loading this file; see ' + $err } }
  elseif (-not $lines) { Write-Host "no LOADALL output; see $err"; break }
  $remaining = [System.Collections.Generic.List[object]]@($remaining | Where-Object { -not $results.ContainsKey($_.File) })
}

$ok = @($results.GetEnumerator() | Where-Object { $_.Value.Status -eq 'OK' })
$compiled = @($results.GetEnumerator() | Where-Object { $_.Value.Status -eq 'COMPILED' })
$fail = @($results.GetEnumerator() | Where-Object { $_.Value.Status -in 'FAIL', 'CRASH' } | Sort-Object Name)
Write-Host ''
Write-Host ("files: {0}  instantiated ok: {1}  compiled only: {2}  failed/crashed: {3}  singletons skipped: {4}" -f ($entries.Count + $skipped.Count), $ok.Count, $compiled.Count, $fail.Count, $skipped.Count)
if ($compiled.Count) {
  Write-Host '-- compiled only (not instantiated):'
  foreach ($c in ($compiled | Sort-Object Name)) {
    $e = $entries | Where-Object { $_.File -eq $c.Name }
    Write-Host ("   {0}  [{1}]" -f $c.Name, $e.Note)
  }
}
if ($skipped.Count) { Write-Host '-- skipped:'; $skipped | ForEach-Object { Write-Host ("   {0}  [{1}]" -f $_.File, $_.Why) } }
if ($fail.Count) {
  Write-Host '-- FAILED:'
  foreach ($f in $fail) { Write-Host ("   {0}  {1}: {2}" -f $f.Name, $f.Value.Status, $f.Value.Detail) }
}
# Other QML error lines the run printed (not tied to a LOADALL line).
$noise = @(Get-ChildItem -LiteralPath $work -Filter *.err.txt | ForEach-Object { Get-Content -LiteralPath $_.FullName } | Where-Object { $_ -match 'qml:|\.qml:|error' -and $_ -notmatch 'LOADALL\|' } | Select-Object -Unique -First 30)
if ($noise.Count) { Write-Host '-- other log lines:'; $noise | ForEach-Object { Write-Host "   $_" } }
exit $(if ($fail.Count) { 1 } else { 0 })
