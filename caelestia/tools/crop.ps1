# Crops a screenshot: crop.ps1 -In shots\a.png -Out shots\b.png -Rect x,y,w,h (physical pixels).
param([Parameter(Mandatory)][string]$In, [Parameter(Mandatory)][string]$Out, [Parameter(Mandatory)][string]$Rect)
Add-Type -AssemblyName System.Drawing
$src = [Drawing.Bitmap]::FromFile((Resolve-Path $In).Path)
$c = $Rect -split "," | ForEach-Object { [int]$_ }
$r = New-Object Drawing.Rectangle $c[0], $c[1], $c[2], $c[3]
$dst = $src.Clone($r, $src.PixelFormat); $src.Dispose()
$dst.Save((Join-Path (Get-Location) $Out), [Drawing.Imaging.ImageFormat]::Png); $dst.Dispose()
