$home_ = 'D:\wabar-ports\wt\fix-bt-net'
$cfg = Join-Path $home_ 'smoke\bt-probe'
$env:QT_FORCE_STDERR_LOGGING = '1'
$err = Join-Path $home_ 'logs\probe.err.txt'; New-Item -ItemType Directory -Force (Split-Path $err) | Out-Null
$p = Start-Process 'D:\wabar\dist\wabar\wabar.exe' -ArgumentList @('--config-home',$cfg,'--import-path',(Join-Path $home_ 'modules'),'--font-engine=directwrite','--no-tray') -RedirectStandardError $err -RedirectStandardOutput (Join-Path $home_ 'logs\probe.out.txt') -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 55
Stop-Process -Id $p.Id -Force
Get-Content $err | Where-Object { $_ -match 'PROBE|Error|rror:' } | Select-Object -First 40
