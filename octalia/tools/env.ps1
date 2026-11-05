# The Octalia port's part of start.ps1 in the repo root. Runs in the launcher's scope: $PortDir and $Dev are set,
# and $PortFlags may be assigned (extra waku arguments).
# Octalia reads its config and cache folders from these; keep them inside the port. HOME is only read
# (default wallpaper and video folders).
$env:OCTALIA_CONFIG_DIR = Join-Path $PortDir 'state\config'
$env:OCTALIA_CACHE_DIR = Join-Path $PortDir 'state\cache'
$env:HOME = $env:USERPROFILE
New-Item -ItemType Directory -Force $env:OCTALIA_CONFIG_DIR, $env:OCTALIA_CACHE_DIR | Out-Null
$PortFlags = @('--import-path', (Join-Path $PortDir 'modules'))
