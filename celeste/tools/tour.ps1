# Starts the full shell once, opens each panel in turn through wakuc, saves cropped captures to
# shots\tour\<name>.png and closes the panel again. Full-screen captures hold whatever is behind the
# transparent shell, so only the crops are kept and the full captures are deleted at once.
param(
  [string]$Home_ = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$Bin = $(if ($env:WAKU_BIN) { $env:WAKU_BIN } else { Join-Path $PSScriptRoot '..\bin' }),
  [string]$Exe = (Join-Path $Bin 'waku.exe'),
  [string]$Wakuc = (Join-Path $Bin 'wakuc.exe'),
  [int]$SettleSeconds = 30
)
$ErrorActionPreference = 'Stop'
$out = Join-Path $Home_ 'shots\tour'
New-Item -ItemType Directory -Force $out | Out-Null
$err = Join-Path $Home_ 'logs\tour.err.txt'
New-Item -ItemType Directory -Force (Split-Path $err) | Out-Null
$env:QT_FORCE_STDERR_LOGGING = '1'
$p = Start-Process $Exe -ArgumentList @('--config-home', $Home_, '--no-tray', '--no-app-bar', '--font-engine=directwrite', '--import-path', (Join-Path $Home_ 'modules')) -PassThru -RedirectStandardError $err
function Status { & $Wakuc --config-home $Home_ status 2>&1 | Out-String }
$ready = $false
for ($i = 0; $i -lt 60 -and -not $ready; $i++) {
  Start-Sleep -Seconds 4
  if ($p.HasExited) { 'waku exited early'; break }
  $s = Status
  if ($s -match 'windows=([1-9])') { $ready = $true }
}
"ready=$ready after ~$($i*4) s; $(Status)".Trim()
Start-Sleep -Seconds $SettleSeconds
# name, open command, region x y w h (physical pixels), scale
$states = @(
  @{ n = 'bar';       cmd = @();                       r = 0, 0, 160, 2560;       s = 0.5 },
  @{ n = 'launcher';  cmd = @('shortcut', 'launcher');  r = 1020, 1480, 1800, 1080; s = 0.6 },
  @{ n = 'session';   cmd = @('shortcut', 'session');   r = 3340, 700, 500, 1160;   s = 0.6 },
  @{ n = 'osd';       cmd = @('call', 'drawers', 'toggle', 'osd'); r = 3340, 700, 500, 1160; s = 0.6 },
  @{ n = 'sidebar';   cmd = @('shortcut', 'sidebar');   r = 3040, 0, 800, 2560;    s = 0.5 },
  @{ n = 'dashboard'; cmd = @('shortcut', 'dashboard'); r = 1020, 0, 1800, 1100;   s = 0.6 },
  @{ n = 'utilities'; cmd = @('shortcut', 'utilities'); r = 3040, 1300, 800, 1260; s = 0.6 }
)
Add-Type -AssemblyName System.Drawing
foreach ($st in $states) {
  if ($st.cmd.Count) { & $Wakuc --config-home $Home_ @($st.cmd) 2>&1 | Out-Null; Start-Sleep -Seconds 5 }
  $full = Join-Path $out ("_full_" + $st.n + '.png')
  & (Join-Path $Home_ 'tools\shot.ps1') -Out $full 2>&1 | Out-Null
  $img = $null
  # shot.ps1 may save under shots\; find the file
  $cand = @($full, (Join-Path $Home_ ('shots\' + (Split-Path $full -Leaf)))) | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($cand) {
    $im = [Drawing.Bitmap]::FromFile($cand)
    $x, $y, $w, $h = $st.r
    $w = [Math]::Min($w, $im.Width - $x); $h = [Math]::Min($h, $im.Height - $y)
    $c = $im.Clone((New-Object Drawing.Rectangle $x, $y, $w, $h), $im.PixelFormat)
    $c2 = New-Object Drawing.Bitmap $c, ([int]($w * $st.s)), ([int]($h * $st.s))
    $c2.Save((Join-Path $out ($st.n + '.png')))
    $c2.Dispose(); $c.Dispose(); $im.Dispose()
    Remove-Item -LiteralPath $cand -Force
    "captured $($st.n): ${w}x${h} (full size $($im.Width))"
  } else { "no capture for $($st.n)" }
  if ($st.cmd.Count) { & $Wakuc --config-home $Home_ @($st.cmd) 2>&1 | Out-Null; Start-Sleep -Seconds 2 }
}
"status: $(Status)".Trim()
& $Wakuc --config-home $Home_ quit 2>&1 | Out-Null
Start-Sleep -Seconds 5
if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force; 'killed' }
"log problem lines:"
(Get-Content $err -ErrorAction SilentlyContinue | Where-Object { $_ -match 'qml:|Error|error|warning|Warning' } | Select-Object -First 40) -join "`n"
