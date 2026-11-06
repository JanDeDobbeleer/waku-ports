# Crops a region out of a saved shot: crop.ps1 in.png out.png x y w h [scale]
param([string]$In, [string]$Out, [int]$X, [int]$Y, [int]$W, [int]$H, [double]$Scale = 1)
Add-Type -AssemblyName System.Drawing
$im = [Drawing.Bitmap]::FromFile($In)
$c = $im.Clone((New-Object Drawing.Rectangle $X, $Y, $W, $H), $im.PixelFormat)
if ($Scale -ne 1) { $c = New-Object Drawing.Bitmap $c, ([int]($W * $Scale)), ([int]($H * $Scale)) }
$c.Save($Out); $im.Dispose()
