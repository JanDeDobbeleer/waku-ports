# The Noctalia port's part of D:\waku-ports\start.ps1. Runs in the launcher's scope: $PortDir and $Dev are set,
# and $PortFlags may be assigned (extra waku arguments).
$env:PATH += ';C:\Program Files\komorebi\bin'
# Noctalia reads its config and cache folders from these; keep them inside the port. HOME is only read
# (default wallpaper and video folders).
$env:NOCTALIA_CONFIG_DIR = Join-Path $PortDir 'state\config'
$env:NOCTALIA_CACHE_DIR = Join-Path $PortDir 'state\cache'
$env:HOME = $env:USERPROFILE
New-Item -ItemType Directory -Force $env:NOCTALIA_CONFIG_DIR, $env:NOCTALIA_CACHE_DIR | Out-Null
$PortFlags = @('--import-path', (Join-Path $PortDir 'modules'))
