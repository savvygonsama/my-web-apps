# 아이콘 PNG 생성 (Windows PowerShell). 실행: powershell -ExecutionPolicy Bypass -File tools/make-icons.ps1
Add-Type -AssemblyName System.Drawing
$out = Join-Path $PSScriptRoot "..\icons"
function C($hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
function Draw($size, $file, $maskable, $round) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'; $g.PixelOffsetMode = 'HighQuality'
  $g.Clear([System.Drawing.Color]::Transparent)
  $bg = New-Object System.Drawing.SolidBrush (C '#1d566f')
  if ($round) {
    $r = $size * 0.22; $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc(0,0,2*$r,2*$r,180,90); $p.AddArc($size-2*$r,0,2*$r,2*$r,270,90)
    $p.AddArc($size-2*$r,$size-2*$r,2*$r,2*$r,0,90); $p.AddArc(0,$size-2*$r,2*$r,2*$r,90,90); $p.CloseFigure()
    $g.FillPath($bg, $p)
  } else { $g.FillRectangle($bg, 0, 0, $size, $size) }
  # 코일 좌표계: x 10..66, y 10..57 → 가운데 정렬
  $s = if ($maskable) { $size * 0.50 / 56 } else { $size * 0.66 / 56 }
  $ox = $size/2 - 38*$s; $oy = $size/2 - 33*$s
  function X($v) { $ox + $v*$s }; function Y($v) { $oy + $v*$s }
  $ink = New-Object System.Drawing.Pen (C '#0d2f3e'), (2.8*$s)
  $soft = New-Object System.Drawing.SolidBrush (C '#dfeaf1')
  $white = New-Object System.Drawing.SolidBrush (C '#ffffff')
  $g.FillEllipse($soft, (X 46), (Y 10), 20*$s, 38*$s); $g.DrawEllipse($ink, (X 46), (Y 10), 20*$s, 38*$s)
  $g.FillRectangle($soft, (X 20), (Y 10), 36*$s, 38*$s)
  $g.DrawLine($ink, (X 20), (Y 10), (X 56), (Y 10)); $g.DrawLine($ink, (X 20), (Y 48), (X 56), (Y 48))
  $g.FillEllipse($white, (X 10), (Y 10), 20*$s, 38*$s); $g.DrawEllipse($ink, (X 10), (Y 10), 20*$s, 38*$s)
  $g.DrawEllipse($ink, (X 15), (Y 20), 10*$s, 18*$s)
  $eye = New-Object System.Drawing.SolidBrush (C '#1d566f')
  $g.FillEllipse($eye, (X 33.3), (Y 21.3), 5.4*$s, 5.4*$s); $g.FillEllipse($eye, (X 44.3), (Y 21.3), 5.4*$s, 5.4*$s)
  $sm = New-Object System.Drawing.Pen (C '#1d566f'), (2.4*$s); $sm.StartCap='Round'; $sm.EndCap='Round'
  $g.DrawArc($sm, (X 37.5), (Y 27.5), 8*$s, 6*$s, 20, 140)
  $tie = New-Object System.Drawing.SolidBrush (C '#c8662a')
  $pts = @((New-Object System.Drawing.PointF (X 40), (Y 41)), (New-Object System.Drawing.PointF (X 43), (Y 41)), (New-Object System.Drawing.PointF (X 45), (Y 52)), (New-Object System.Drawing.PointF (X 41.5), (Y 57)), (New-Object System.Drawing.PointF (X 38), (Y 52)))
  $g.FillPolygon($tie, $pts)
  $g.FillRectangle($tie, (X 39.3), (Y 38), 4.4*$s, 3.2*$s)
  $bmp.Save((Join-Path $out $file), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}
Draw 192 'icon-192.png' $false $true
Draw 512 'icon-512.png' $false $true
Draw 512 'icon-maskable-512.png' $true $false
Draw 180 'apple-touch-icon.png' $false $false
Write-Output "done"
