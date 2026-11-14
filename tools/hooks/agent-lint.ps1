# Copilot postToolUse hook (.github/hooks/qml-checks.json): after an agent edits or creates a .qml or
# .js file in a port, lints that file and hands any warning back to the agent in the same turn.
$ErrorActionPreference = 'Stop'
try {
  $hook = [Console]::In.ReadToEnd() | ConvertFrom-Json
  $toolArgs = $hook.toolArgs
  if ($toolArgs -is [string]) { $toolArgs = $toolArgs | ConvertFrom-Json }
} catch { exit 0 }

$paths = @()
if ($toolArgs.path) { $paths += [string]$toolArgs.path }
foreach ($text in @($toolArgs.input, $toolArgs.patch)) {
  if ($text -is [string]) {
    $paths += [regex]::Matches($text, '(?m)^\*\*\* (?:Add|Update) File: (.+?)\s*$') | ForEach-Object { $_.Groups[1].Value }
  }
}
$paths = @($paths | Where-Object { $_ -match '\.(qml|m?js)$' } | Sort-Object -Unique)
if (-not $paths) { exit 0 }

$check = Join-Path $PSScriptRoot '..\check.ps1'
try {
  $out = & $check -File $paths -Quiet *>&1 | ForEach-Object { "$_" }
  $code = $LASTEXITCODE
} catch { $out = @("$_"); $code = 1 }
if ($code -eq 0) { exit 0 }

$found = @($out | Where-Object { $_ -match '\[qmllint ' })
$text = if ($found) {
  "qmllint reports $($found.Count) problem(s) in the file(s) you just changed. Fix them in the code; " +
  "do not add qmllint disable comments.`n" + (($found | Select-Object -First 60) -join "`n")
} else {
  "The QML lint hook could not run tools\check.ps1: " + (($out | Select-Object -Last 5) -join ' ')
}
if ($text.Length -gt 9000) { $text = $text.Substring(0, 9000) + "`n..." }
@{ additionalContext = $text } | ConvertTo-Json -Compress
exit 0
