# Replaces Linux commands in the Octalia QML with calls to qs.compat Os. Idempotent.
$root = Join-Path $PSScriptRoot '..\modules\qs'
$utf8 = New-Object Text.UTF8Encoding $false; $n = 0; $edits = 0
Get-ChildItem $root -Recurse -Filter *.qml | Where-Object { $_.DirectoryName -notmatch '\compat$' } | ForEach-Object {
  $t = [IO.File]::ReadAllText($_.FullName); $o = $t
  $t = [regex]::Replace($t, 'Quickshell\.execDetached\(\["mkdir", "-p", ([^\]]+)\]\)', 'Os.mkdirp($1)')
  $t = [regex]::Replace($t, 'Quickshell\.execDetached\(\["rm", "-rf", ([^\]]+)\]\)', 'Os.rm($1, true)')
  $t = [regex]::Replace($t, 'Quickshell\.execDetached\(\["rm", "-f", ([^\]]+)\]\)', 'Os.rm($1)')
  $t = [regex]::Replace($t, 'Quickshell\.execDetached\(\["wl-copy", ([^\]]+)\]\)', 'Os.copy($1)')
  $t = [regex]::Replace($t, 'Quickshell\.execDetached\(\["xdg-open", ([^\]]+)\]\)', 'Os.open($1)')
  if ($t -cne $o) { [IO.File]::WriteAllText($_.FullName, $t, $utf8); $n++ }
}
"files changed: $n"
