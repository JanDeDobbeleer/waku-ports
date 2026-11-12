<#
Validates the ports. Three steps, each fails on any finding:

  lint     qmllint on every tracked .qml and .js file, every warning category on, compiler
           (qmlsc) category included. Any warning fails.
  runtime  1. loads every component of the port with Qt.createComponent in a throwaway shell;
           2. starts the port's real shell.qml from a copy of the port with empty state, drives it
              through <port>\tools\smoke.txt (wakuc commands that open its panels and menus), and
              fails on any QML warning, error or binding loop it logs, or on a failed smoke command.
  perf     starts the shell again on the state the runtime run left (no first-run wizards) and
           measures start-up time, idle CPU, memory and handles against tools\perf-budget.json.

  .\tools\check.ps1                                   everything, every port
  .\tools\check.ps1 -Port celeste -Step lint          one port, one step
  .\tools\check.ps1 -File celeste\shell.qml,a\b.qml   lint just these files (used by the hooks)

The engine and the QML type metadata come from the waku release pinned in tools\waku.json
(downloaded by tools\fetch-waku.ps1 into .cache\). Override them with WAKU_CHECK_EXE (waku.exe)
and WAKU_QML_TYPES (a folder with Quickshell\ and waku\). Qt's qmllint comes from QT_BIN, else
C:\Qt\<qt>\msvc2022_*\bin.
#>
[CmdletBinding()]
param(
  [ValidateSet('celeste', 'octalia', 'nomarchy', 'start12')][string[]]$Port = @('celeste', 'octalia', 'nomarchy', 'start12'),
  [ValidateSet('lint', 'runtime', 'perf')][string[]]$Step = @('lint', 'runtime', 'perf'),
  [string[]]$File,
  [int]$StartSeconds = 60,   # longest wait for the shell to finish loading
  [int]$SettleSeconds = 10,  # idle time after loading before sampling (services still start)
  [int]$SampleSeconds = 10,  # idle CPU sample length
  [int]$SmokeGapMs = 1500,   # wait after each smoke command
  [switch]$Quiet
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$pin = Get-Content (Join-Path $PSScriptRoot 'waku.json') -Raw | ConvertFrom-Json
$ci = $env:GITHUB_ACTIONS -eq 'true'
$work = Join-Path ([IO.Path]::GetTempPath()) 'waku-ports-check'
New-Item -ItemType Directory -Force $work | Out-Null
$results = New-Object System.Collections.ArrayList
$failed = $false

function Say([string]$text) { if (-not $Quiet) { Write-Host $text } }

function Report([string]$file, [int]$line, [int]$col, [string]$title, [string]$message) {
  $rel = $file
  if ($rel.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { $rel = $rel.Substring($root.Length + 1) }
  $rel = $rel.Replace('\', '/')
  if ($ci) {
    $m = $message -replace '%', '%25' -replace "`r", '%0D' -replace "`n", '%0A'
    Write-Host "::error file=$rel,line=$line,col=$col,title=$title::$m"
  } else {
    Write-Host ("{0}:{1}:{2}: [{3}] {4}" -f $rel, $line, $col, $title, $message)
  }
}

function Add-Result([string]$port, [string]$step, [bool]$ok, [string]$detail) {
  [void]$results.Add([pscustomobject]@{ Port = $port; Step = $step; Status = $(if ($ok) { 'PASS' } else { 'FAIL' }); Detail = $detail })
  if (-not $ok) { $script:failed = $true }
}

function Get-QtBin {
  if ($env:QT_BIN -and (Test-Path (Join-Path $env:QT_BIN 'qmllint.exe'))) { return $env:QT_BIN }
  $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'msvc2022_arm64' } else { 'msvc2022_64' }
  foreach ($a in @($arch, 'msvc2022_64', 'msvc2022_arm64')) {
    $bin = "C:\Qt\$($pin.qt)\$a\bin"
    if (Test-Path (Join-Path $bin 'qmllint.exe')) { return $bin }
  }
  throw "qmllint $($pin.qt) not found: set QT_BIN or install Qt $($pin.qt) under C:\Qt"
}

function Get-Waku {
  $exe = $env:WAKU_CHECK_EXE
  $types = $env:WAKU_QML_TYPES
  if (-not $exe -or -not $types) {
    $dest = & (Join-Path $PSScriptRoot 'fetch-waku.ps1') | Select-Object -Last 1
    if (-not $exe) { $exe = Join-Path $dest 'engine\waku.exe' }
    if (-not $types) { $types = Join-Path $dest 'qml-types' }
  }
  if (-not (Test-Path $exe)) { throw "engine not found: $exe" }
  if (-not (Test-Path (Join-Path $types 'Quickshell'))) { throw "QML type metadata not found: $types" }
  [pscustomobject]@{ Exe = (Resolve-Path $exe).Path; Wakuc = Join-Path (Split-Path (Resolve-Path $exe).Path) 'wakuc.exe'; Types = (Resolve-Path $types).Path }
}

function Get-PortFiles([string]$port) {
  Push-Location $root
  try { @(git ls-files --cached --others --exclude-standard -- "$port/*.qml" "$port/*.js" "$port/*.mjs" | Sort-Object -Unique | ForEach-Object { Join-Path $root $_ } | Where-Object { Test-Path -LiteralPath $_ }) }
  finally { Pop-Location }
}

function Get-ImportPaths([string]$port, [string]$qtBin, [string]$types) {
  $paths = @((Resolve-Path (Join-Path $qtBin '..\qml')).Path, $types)
  $modules = Join-Path $root "$port\modules"
  if (Test-Path $modules) { $paths += $modules }
  $paths
}

# ---------------------------------------------------------------- lint
function Invoke-Lint([hashtable]$byPort, $waku, [string]$qtBin) {
  $procs = @()
  foreach ($p in $byPort.Keys) {
    $files = @($byPort[$p])
    if (-not $files.Count) { continue }
    $json = Join-Path $work "lint-$p.json"
    $rsp = Join-Path $work "lint-$p.rsp"
    Remove-Item $json -ErrorAction SilentlyContinue
    $args_ = @('--bare')
    foreach ($i in (Get-ImportPaths $p $qtBin $waku.Types)) { $args_ += @('-I', $i) }
    $args_ += @('--compiler', 'warning', '--json', $json) + $files
    [IO.File]::WriteAllLines($rsp, [string[]]$args_)
    $proc = Start-Process -FilePath (Join-Path $qtBin 'qmllint.exe') -ArgumentList "`"@$rsp`"" -PassThru -NoNewWindow `
      -RedirectStandardOutput (Join-Path $work "lint-$p.out.txt") -RedirectStandardError (Join-Path $work "lint-$p.err.txt")
    $procs += [pscustomobject]@{ Port = $p; Proc = $proc; Json = $json; Count = $files.Count }
  }
  foreach ($x in $procs) {
    $x.Proc.WaitForExit()
    if (-not (Test-Path $x.Json)) {
      Get-Content (Join-Path $work "lint-$($x.Port).err.txt") -ErrorAction SilentlyContinue | Select-Object -First 20 | ForEach-Object { Write-Host $_ }
      Add-Result $x.Port 'lint' $false "qmllint exited $($x.Proc.ExitCode) without a report"
      continue
    }
    $report = Get-Content $x.Json -Raw | ConvertFrom-Json
    $n = 0
    foreach ($f in $report.files) {
      foreach ($w in $f.warnings) {
        $n++
        Report $f.filename ([int]$w.line) ([int]$w.column) "qmllint $($w.id)" $w.message
      }
      if (-not $f.success -and -not $f.warnings) {
        $n++
        Report $f.filename 1 1 'qmllint' 'qmllint could not process this file'
      }
    }
    Add-Result $x.Port 'lint' ($n -eq 0) "$($x.Count) files, $n warnings"
  }
}

# ---------------------------------------------------------------- runtime
function Read-Log([string]$path) {
  if (-not (Test-Path $path)) { return @() }
  # The file is still open for writing by waku; read it shared.
  $fs = [IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
  try {
    $sr = New-Object IO.StreamReader($fs)
    $lines = $sr.ReadToEnd() -split "`n"
  } finally { $fs.Dispose() }
  foreach ($l in $lines) { if ($l.Trim()) { try { $l | ConvertFrom-Json } catch { } } }
}

function Start-Waku($waku, [string]$configHome, [string[]]$imports, [string]$log, [string[]]$Extra = @()) {
  $flags = @('--config-home', $configHome, '--log-file', $log, '--no-tray', '--no-app-bar', '--keep-taskbar',
    '--no-keys', '--no-hotkeys', '--no-tiling', '--no-shell-desktops')
  foreach ($i in $imports) { $flags += @('--import-path', $i) }
  $flags += $Extra
  $quoted = $flags | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }
  Start-Process -FilePath $waku.Exe -ArgumentList $quoted -PassThru -WindowStyle Hidden -WorkingDirectory (Split-Path $waku.Exe) `
    -RedirectStandardOutput "$log.out.txt" -RedirectStandardError "$log.err.txt"
}

function Stop-Waku($waku, $proc, [string]$configHome) {
  if ($proc.HasExited) { return }
  & $waku.Wakuc --config-home $configHome quit 2>&1 | Out-Null
  if (-not $proc.WaitForExit(10000)) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
}

# Problems the shell logged: every warning, critical and fatal message but the load check's own.
function Get-Problems($records, [string]$portDir) {
  $records | Where-Object {
    $_.k -eq 'log' -and $_.lvl -in @('warning', 'critical', 'fatal') -and $_.msg -notmatch '^LOADCHK\|'
  }
}

# A problem in the engine's own QML (the waku and Quickshell modules compiled into waku.exe) is not
# the port's to fix. It is reported as a notice for the engine and does not fail the run.
function Test-EngineProblem($rec, [string]$port) {
  if ($rec.msg -match 'image://windowicon/') { return $true }
  if ($rec.msg -match 'file:///') { return $false }
  if ($rec.msg -match 'qrc:/qt/qml/(waku|Quickshell)/') { return $true }
  if ($rec.msg -match 'of the object (\w+?)_QMLTYPE_\d+') {
    $name = $Matches[1]
    return -not (Get-PortFiles $port | Where-Object { (Split-Path $_ -Leaf) -eq "$name.qml" })
  }
  $false
}

function Write-Problem($rec, [string]$portDir, [string]$port) {
  $file = Join-Path $root "$port\shell.qml"; $line = 1; $col = 1
  if ($rec.msg -match 'file:///([^\s:?]+(?::[\\/][^\s:?]+)?\.(?:qml|js|mjs))(?:\?[^\s:]*)?:(\d+)(?::(\d+))?') {
    $file = $Matches[1].Replace('/', '\'); $line = [int]$Matches[2]; if ($Matches[3]) { $col = [int]$Matches[3] }
    # Map the copy of the port back to the port.
    if ($file.StartsWith($portDir, [StringComparison]::OrdinalIgnoreCase)) {
      $file = Join-Path $root ($port + $file.Substring($portDir.Length))
    }
  }
  Report $file $line $col "runtime $($rec.lvl)" $rec.msg
}

function Invoke-LoadCheck([string]$port, $waku) {
  $portDir = Join-Path $root $port
  $files = Get-PortFiles $port | Where-Object { $_ -like '*.qml' -and (Split-Path $_ -Leaf) -cmatch '^[A-Z]' }
  $urls = ($files | ForEach-Object { '    "file:///' + $_.Replace('\', '/') + '"' }) -join ",`n"
  $home_ = Join-Path $work "load-$port"
  Remove-Item $home_ -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force $home_ | Out-Null
  $qml = @"
import QtQuick
import Quickshell
ShellRoot {
  readonly property list<string> files: [
$urls
  ]
  Timer {
    interval: 200; running: true
    onTriggered: {
      let bad = 0;
      for (let i = 0; i < files.length; ++i) {
        const c = Qt.createComponent(files[i]);
        if (c.status === Component.Error) { bad++; console.warn("LOADCHK|ERR|" + files[i] + "|" + c.errorString().replace(/\s*\n\s*/g, " ;; ")); }
        else if (c.status !== Component.Ready) { bad++; console.warn("LOADCHK|PEND|" + files[i]); }
      }
      console.info("LOADCHK|DONE|" + files.length + "|" + bad);
    }
  }
}
"@
  [IO.File]::WriteAllText((Join-Path $home_ 'shell.qml'), $qml, (New-Object Text.UTF8Encoding $false))
  $log = Join-Path $home_ 'waku.log'
  $imports = @(); if (Test-Path (Join-Path $portDir 'modules')) { $imports += (Join-Path $portDir 'modules') }
  # Singletons the components reference start up and may write state under HOME (undefined on
  # Windows unless a port's env hook sets it): keep that in the scratch folder.
  $savedHome = $env:HOME; $env:HOME = $home_
  try { $proc = Start-Waku $waku $home_ $imports $log } finally { $env:HOME = $savedHome }
  $done = $null
  $t0 = Get-Date
  try {
    while (((Get-Date) - $t0).TotalSeconds -lt $StartSeconds -and -not $proc.HasExited) {
      Start-Sleep -Milliseconds 500
      $done = Read-Log $log | Where-Object { $_.k -eq 'log' -and $_.msg -like 'LOADCHK|DONE|*' } | Select-Object -First 1
      if ($done) { break }
    }
  } finally { Stop-Waku $waku $proc $home_ }
  $recs = @(Read-Log $log)
  $bad = 0
  foreach ($r in $recs | Where-Object { $_.k -eq 'log' -and $_.msg -match '^LOADCHK\|(ERR|PEND)\|' }) {
    $bad++
    $parts = $r.msg -split '\|', 4
    $f = $parts[2] -replace '^file:///', ''
    $why = if ($parts.Count -gt 3) { $parts[3] } else { 'not ready' }
    Report $f.Replace('/', '\') 1 1 "runtime load" ("{0}: {1}" -f $parts[1], $why)
  }
  if (-not $done) {
    Add-Result $port 'runtime load' $false "no result within $StartSeconds s (exit: $(if ($proc.HasExited) { $proc.ExitCode } else { 'killed' }))"
    return
  }
  Add-Result $port 'runtime load' ($bad -eq 0) "$(@($files).Count) components, $bad failed"
}

# Drives the running shell through <port>\tools\smoke.txt, so panels and menus that start-up never
# shows run too. One wakuc command per line (`call <target> <fn> [args]`, `surface toggle <name>`,
# ...), `sleep <seconds>` to wait longer, `#` comments. A command fails when wakuc exits non-zero,
# or when the line ends in `=> <regex>` and the output does not match it.
function Invoke-Smoke([string]$port, $waku, [string]$copy, $proc) {
  $file = Join-Path $copy 'tools\smoke.txt'
  if (-not (Test-Path $file)) { return $null }
  $steps = @()
  $n = 0
  foreach ($raw in Get-Content $file) {
    $n++
    $line = $raw.Trim()
    if (-not $line -or $line.StartsWith('#')) { continue }
    if ($proc.HasExited) {
      $steps += [pscustomobject]@{ LineNo = $n; Line = $line; At = [DateTimeOffset]::Now; Ok = $false; Output = 'the shell exited' }
      break
    }
    if ($line -match '^sleep\s+([\d.]+)$') { Start-Sleep -Milliseconds ([double]$Matches[1] * 1000); continue }
    $cmd = $line; $expect = $null
    if ($line -match '^(.*?)\s+=>\s+(.+)$') { $cmd = $Matches[1]; $expect = $Matches[2] }
    $at = [DateTimeOffset]::Now
    # wakuc splits arguments on spaces; a JSON argument must not contain any.
    $out = (& $waku.Wakuc --config-home $copy @($cmd -split '\s+') 2>&1) -join ' '
    $ok = $LASTEXITCODE -eq 0 -and (-not $expect -or $out -match $expect)
    $steps += [pscustomobject]@{ LineNo = $n; Line = $line; At = $at; Ok = $ok; Output = $out }
    Start-Sleep -Milliseconds $SmokeGapMs
  }
  [pscustomobject]@{ Steps = $steps }
}

function Invoke-ShellRun([string]$port, $waku, [bool]$checkProblems, [bool]$checkPerf, [bool]$fresh = $true) {
  $src = Join-Path $root $port
  $copy = Join-Path $work "shell-$port"
  if ($fresh) {
    Remove-Item $copy -Recurse -Force -ErrorAction SilentlyContinue
    # A copy of the port's files (tracked and new, not ignored), as CI sees them: the run writes state, and the live shell of the
    # same port must not see it.
    Push-Location $root
    try { $tracked = @(git ls-files --cached --others --exclude-standard -- "$port/" | Sort-Object -Unique | Where-Object { Test-Path -LiteralPath $_ }) } finally { Pop-Location }
    foreach ($t in $tracked) {
      $dest = Join-Path $copy $t.Substring($port.Length + 1)
      $dir = Split-Path $dest
      if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
      Copy-Item -LiteralPath (Join-Path $root $t) -Destination $dest
    }
  }
  $log = Join-Path $work "shell-$port.log"
  Remove-Item "$log*" -ErrorAction SilentlyContinue
  # The port's start-up hook, as start.ps1 -Dev runs it: environment and pre-start steps.
  $saved = @{}; Get-ChildItem env: | ForEach-Object { $saved[$_.Name] = $_.Value }
  $PortDir = $copy; $Dev = $true; $PortFlags = @()
  $hook = Join-Path $copy 'tools\env.ps1'
  try {
    if (Test-Path $hook) { . $hook | Out-Null }
    $proc = Start-Waku $waku $copy @() $log -Extra $PortFlags
  } finally {
    Get-ChildItem env: | Where-Object { -not $saved.ContainsKey($_.Name) } | ForEach-Object { Remove-Item "env:$($_.Name)" }
    foreach ($k in $saved.Keys) { Set-Item "env:$k" $saved[$k] }
  }
  $t0 = Get-Date
  $loaded = $null
  $metrics = $null
  $smoke = $null
  try {
    while (((Get-Date) - $t0).TotalSeconds -lt $StartSeconds -and -not $proc.HasExited) {
      Start-Sleep -Milliseconds 500
      $loaded = Read-Log $log | Where-Object { $_.k -eq 'ev' -and $_.ev -eq 'shell.reload' } | Select-Object -First 1
      if ($loaded) { break }
    }
    if ($loaded -and -not $proc.HasExited) {
      Start-Sleep -Seconds $SettleSeconds
      if ($checkProblems) { $smoke = Invoke-Smoke $port $waku $copy $proc }
      $proc.Refresh()
      $cpu0 = $proc.TotalProcessorTime; $w0 = Get-Date
      Start-Sleep -Seconds $SampleSeconds
      $proc.Refresh()
      if (-not $proc.HasExited) {
        $cpuPct = 100 * ($proc.TotalProcessorTime - $cpu0).TotalMilliseconds / ((Get-Date) - $w0).TotalMilliseconds
        $metrics = [ordered]@{
          startupMs  = 0
          idleCpuPct = [math]::Round($cpuPct, 2)
          privateMB  = [math]::Round($proc.PrivateMemorySize64 / 1MB, 1)
          handles    = $proc.HandleCount
        }
      }
    }
  } finally { Stop-Waku $waku $proc $copy }
  $recs = @(Read-Log $log)
  $steps = @($recs | Where-Object { $_.k -eq 'ev' -and $_.ev -eq 'reload.step' })
  $reloads = @($recs | Where-Object { $_.k -eq 'ev' -and $_.ev -eq 'shell.reload' })

  if ($checkProblems) {
    $all = @(Get-Problems $recs $copy)
    $engine = @($all | Where-Object { Test-EngineProblem $_ $port })
    $problems = @($all | Where-Object { -not (Test-EngineProblem $_ $port) })
    foreach ($r in $engine) {
      if ($ci) { Write-Host "::notice title=engine ($port)::$($r.msg)" } else { Write-Host "engine ($port): $($r.msg)" }
    }
    foreach ($r in $problems) {
      # Name the smoke command a warning followed, so it can be reproduced.
      $after = $null
      if ($smoke -and $r.t) {
        $at = [DateTimeOffset]::Parse($r.t)
        $after = $smoke.Steps | Where-Object { $_.At -le $at } | Select-Object -Last 1
      }
      if ($after) { $r.msg = "$($r.msg) (after smoke: $($after.Line))" }
      Write-Problem $r $copy $port
    }
    foreach ($r in $reloads | Where-Object { -not $_.ok }) { Report (Join-Path $src 'shell.qml') 1 1 'runtime reload' $r.error }
    $smokeFailed = 0
    if ($smoke) {
      foreach ($s in $smoke.Steps | Where-Object { -not $_.Ok }) {
        $smokeFailed++
        Report (Join-Path $src 'tools\smoke.txt') $s.LineNo 1 'runtime smoke' "$($s.Line): $($s.Output)"
      }
    }
    $ok = $loaded -and -not ($reloads | Where-Object { -not $_.ok }) -and $problems.Count -eq 0 -and $smokeFailed -eq 0
    $detail = if (-not $loaded) { "shell did not load within $StartSeconds s" } else { "$($problems.Count) warnings, $($engine.Count) engine notices" }
    if ($smoke) { $detail += ", smoke $(@($smoke.Steps).Count - $smokeFailed)/$(@($smoke.Steps).Count)" }
    Add-Result $port 'runtime shell' ([bool]$ok) $detail
  }

  if ($checkPerf) {
    if (-not $metrics) { Add-Result $port 'perf' $false 'no measurement: the shell did not load or exited'; return }
    $first = $steps | Where-Object { $_.step -eq 'first reload done' } | Select-Object -First 1
    if ($first) { $metrics.startupMs = [int]$first.ms }
    $metrics.bindingLoops = @($recs | Where-Object { $_.k -eq 'log' -and $_.msg -match 'Binding loop' }).Count
    $budgets = Get-Content (Join-Path $PSScriptRoot 'perf-budget.json') -Raw | ConvertFrom-Json
    $budget = $budgets.$port
    $over = @()
    foreach ($k in @('startupMs', 'idleCpuPct', 'privateMB', 'handles', 'bindingLoops')) {
      $limit = $budget.$k
      if ($null -ne $limit -and $metrics[$k] -gt $limit) { $over += "$k $($metrics[$k]) > $limit" }
    }
    $detail = ($metrics.Keys | ForEach-Object { "$_=$($metrics[$_])" }) -join ' '
    [IO.File]::WriteAllText((Join-Path $work "perf-$port.json"), ($metrics | ConvertTo-Json))
    foreach ($o in $over) { Report (Join-Path $PSScriptRoot 'perf-budget.json') 1 1 "perf $port" "over budget: $o" }
    Add-Result $port 'perf' ($over.Count -eq 0) $detail
  }
}

# ---------------------------------------------------------------- main
$qtBin = Get-QtBin
$waku = Get-Waku
Say "qmllint: $qtBin`nengine:  $($waku.Exe)`ntypes:   $($waku.Types)"

if ($File) {
  $byPort = @{}
  foreach ($f in $File) {
    $full = if ([IO.Path]::IsPathRooted($f)) { $f } else { Join-Path $root $f }
    if (-not (Test-Path $full) -or $full -notmatch '\.(qml|m?js)$') { continue }
    $full = (Resolve-Path $full).Path
    $p = ($full.Substring($root.Length + 1) -split '[\\/]')[0]
    if ($p -notin @('celeste', 'octalia', 'nomarchy', 'start12')) { continue }
    if (-not $byPort[$p]) { $byPort[$p] = @() }
    $byPort[$p] += $full
  }
  if ($byPort.Count) { Invoke-Lint $byPort $waku $qtBin }
} else {
  if ('lint' -in $Step) {
    $byPort = @{}
    foreach ($p in $Port) { $byPort[$p] = Get-PortFiles $p }
    Invoke-Lint $byPort $waku $qtBin
  }
  foreach ($p in $Port) {
    if ('runtime' -in $Step) { Invoke-LoadCheck $p $waku }
    # The runtime run starts from empty state, so first-run paths (setup wizards, default files) are
  # checked. Perf measures a second start on the state that run left: the shell as users run it.
  if ('runtime' -in $Step -or 'perf' -in $Step) { Invoke-ShellRun $p $waku ('runtime' -in $Step) $false }
  if ('perf' -in $Step) { Invoke-ShellRun $p $waku $false $true $false }
  }
}

if ($results.Count) {
  $table = $results | Format-Table -AutoSize | Out-String -Width 200
  Write-Host $table
  if ($env:GITHUB_STEP_SUMMARY) {
    $md = @('| Port | Step | Status | Detail |', '| --- | --- | --- | --- |')
    $md += $results | ForEach-Object { "| $($_.Port) | $($_.Step) | $($_.Status) | $($_.Detail) |" }
    Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value ($md -join "`n")
  }
}
if ($failed) { Write-Host 'Checks failed.'; exit 1 }
Say 'All checks passed.'
exit 0
