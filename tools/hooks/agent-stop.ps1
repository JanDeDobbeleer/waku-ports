# Copilot agentStop hook (.github/hooks/qml-checks.json): when an agent finishes a turn with changes in
# a port, runs the same checks as CI for that port (lint on the changed files, then runtime and perf)
# and sends the agent back to work when they fail. A passing state is remembered, so turns that
# change nothing in a port cost nothing.
$ErrorActionPreference = 'Stop'
try { [void]([Console]::In.ReadToEnd() | ConvertFrom-Json) } catch { }
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$ports = @('celeste', 'octalia', 'nomarchy', 'start12')
Push-Location $root
try {
  $base = git merge-base HEAD origin/main 2>$null
  if (-not $base) { $base = 'HEAD' }
  $changed = @(git diff --name-only $base -- $ports) + @(git ls-files --others --exclude-standard -- $ports)
  $changed = @($changed | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Sort-Object -Unique)
  if (-not $changed) { exit 0 }

  $state = git rev-parse --git-path waku-ports-agent-check
  $sha = [Security.Cryptography.SHA256]::Create()
  $key = ($changed | ForEach-Object { $_ + '=' + (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash }) -join "`n"
  $key = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($key))) -replace '-', ''
  if ((Test-Path $state) -and (Get-Content $state -Raw).Trim() -eq $key) { exit 0 }

  $touched = @($changed | ForEach-Object { ($_ -split '/')[0] } | Sort-Object -Unique)
  $code = @($changed | Where-Object { $_ -match '\.(qml|m?js)$' })
  $check = Join-Path $PSScriptRoot '..\check.ps1'
  $out = @()
  $ok = $true
  $runs = @()
  if ($code) { $runs += , @{ File = $code; Quiet = $true } }
  $runs += , @{ Port = $touched; Step = @('runtime', 'perf'); Quiet = $true }
  foreach ($run in $runs) {
    try {
      $out += & $check @run *>&1 | ForEach-Object { "$_" }
      if ($LASTEXITCODE -ne 0) { $ok = $false }
    } catch { $out += "$_"; $ok = $false }
  }

  if ($ok) {
    [IO.File]::WriteAllText($state, $key)
    exit 0
  }
  $found = @($out | Where-Object { $_ -match ':\d+:\d+: \[' -or $_ -match '\sFAIL\s' })
  # Without findings the tooling itself failed (no Qt, no engine): say nothing rather than loop.
  if (-not $found) { exit 0 }
  $reason = "The QML checks (tools\check.ps1, the same as CI) fail for $($touched -join ', '). Fix every " +
    "finding in the code without qmllint disable comments, then finish again.`n" + (($found | Select-Object -First 80) -join "`n")
  if ($reason.Length -gt 9000) { $reason = $reason.Substring(0, 9000) + "`n..." }
  @{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress
  exit 0
} finally { Pop-Location }
