# Removes `<Type> { id: <Id> ... }` blocks (brace matched) from a file. Used for octalia-qs blur regions
# (Type Region) and for Linux-only Process blocks (Type Process).
param([Parameter(Mandatory)][string]$File, [Parameter(Mandatory)][string[]]$Ids, [string]$Type = 'Region')
$t = [IO.File]::ReadAllText($File)
foreach ($id in $Ids) {
  $m = [regex]::Match($t, "(?m)^[ \t]*$Type \{\r?\n[ \t]*id: $id\b")
  if (-not $m.Success) { Write-Host "not found: $id in $File"; continue }
  $i = $t.IndexOf('{', $m.Index); $depth = 0; $j = $i
  for (; $j -lt $t.Length; $j++) { if ($t[$j] -eq '{') { $depth++ } elseif ($t[$j] -eq '}') { $depth--; if ($depth -eq 0) { break } } }
  $end = $j + 1; while ($end -lt $t.Length -and $t[$end] -ne "`n") { $end++ }
  $t = $t.Remove($m.Index, $end + 1 - $m.Index)
  Write-Host "removed $id from $File"
}
[IO.File]::WriteAllText($File, $t, (New-Object Text.UTF8Encoding $false))
