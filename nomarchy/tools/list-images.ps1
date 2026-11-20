# Lists the images in a folder and its subfolders one level down, one full path per line. The
# wallpaper picker runs it. Works in Windows PowerShell 5.1 and PowerShell 7.
param([Parameter(Mandatory)][string]$Dir)
Get-ChildItem -LiteralPath $Dir -File -Recurse -Depth 1 -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -match '^\.(jpe?g|png|webp|bmp)$' } |
  ForEach-Object { $_.FullName }
