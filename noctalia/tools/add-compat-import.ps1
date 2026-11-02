# Adds `import qs.compat` (after the last import) to every non-compat file that uses a type the
# port's compat module supplies. Idempotent.
param([string]$Pattern = '\b(PopupWindow|IdleInhibitor|IdleMonitor|ToplevelManager)\b')
$utf8 = New-Object Text.UTF8Encoding $false; $n = 0
Get-ChildItem (Join-Path $PSScriptRoot '..\modules\qs') -Recurse -Filter *.qml |
  Where-Object { $_.DirectoryName -notmatch '\compat$' } | ForEach-Object {
  $t = [IO.File]::ReadAllText($_.FullName)
  if ($t -notmatch $Pattern -or $t -match '(?m)^import qs\.compat') { return }
  $m = [regex]::Matches($t, '(?m)^import [^\r\n]+\r?\n')
  if ($m.Count -eq 0) { return }
  $last = $m[$m.Count - 1]
  [IO.File]::WriteAllText($_.FullName, $t.Insert($last.Index + $last.Length, "import qs.compat`n"), $utf8); $n++
}
"compat import added to $n files"
