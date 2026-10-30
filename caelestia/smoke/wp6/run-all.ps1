# Runs the WP6 harness once per state (one.ps1) and saves cropped shots under shots\ (gitignored).
$cases = @(
  @{ n = 'launcher'; o = 'launcher'; t = '' }, @{ n = 'search'; o = 'launcher'; t = 'fire' },
  @{ n = 'actions'; o = 'launcher'; t = '>' }, @{ n = 'calc'; o = 'launcher'; t = '>calc 2+3*4' },
  @{ n = 'scheme'; o = 'launcher'; t = '>scheme ' }, @{ n = 'variant'; o = 'launcher'; t = '>variant ' },
  @{ n = 'wallpaper'; o = 'launcher'; t = '>wallpaper ' }, @{ n = 'osd'; o = 'osd'; t = '' },
  @{ n = 'session'; o = 'session'; t = '' }
)
foreach ($c in $cases) {
  Write-Host "=== $($c.n)"
  & (Join-Path $PSScriptRoot 'one.ps1') -Name $c.n -Open $c.o -Search $c.t -Wait 16 | Where-Object { $_ -match 'qml:|rror|warn' -and $_ -notmatch 'WP6:' }
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\..\logs\run.err.txt') (Join-Path $PSScriptRoot "..\..\logs\wp6-$($c.n).err.txt") -Force
}
