param([string]$OutDir)
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

function C($hex, $a = 255) { $c = [System.Drawing.ColorTranslator]::FromHtml($hex); [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }

function Draw-Sky($g, $w, $h) {
  $rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
  $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, (C '#0c1530'), (C '#3f5f85'), 90
  $g.FillRectangle($br, $rect)
  $rnd = New-Object System.Random 7
  for ($i = 0; $i -lt [int]($w * $h / 9000); $i++) {
    $s = 1 + $rnd.NextDouble() * ($w / 400)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush (C '#ffffff' ([int](80 + $rnd.Next(150))))), [float]($rnd.NextDouble() * $w), [float]($rnd.NextDouble() * $h * 0.6), [float]$s, [float]$s)
  }
}

# Mushroom centered at (cx, cy); s = cap half-width in pixels.
function Draw-Mushroom($g, [float]$cx, [float]$cy, [float]$s) {
  $k = $s / 26.0
  # glow
  $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
  $gp.AddEllipse($cx - 60 * $k, $cy - 60 * $k, 120 * $k, 120 * $k)
  $pgb = New-Object System.Drawing.Drawing2D.PathGradientBrush $gp
  $pgb.CenterColor = C '#ffd96a' 70
  $pgb.SurroundColors = @((C '#ffd96a' 0))
  $g.FillPath($pgb, $gp)
  # legs + stem
  $stem = New-Object System.Drawing.SolidBrush (C '#f6ead2')
  $g.FillEllipse((New-Object System.Drawing.SolidBrush (C '#d2bb90')), $cx - 9 * $k, $cy + 16 * $k, 7 * $k, 10 * $k)
  $g.FillEllipse((New-Object System.Drawing.SolidBrush (C '#d2bb90')), $cx + 2 * $k, $cy + 16 * $k, 7 * $k, 10 * $k)
  $sp = New-Object System.Drawing.Drawing2D.GraphicsPath
  $r = 9 * $k; $x = $cx - 11 * $k; $y = $cy - 2 * $k; $w = 22 * $k; $h = 23 * $k
  $sp.AddArc($x, $y, 2 * $r, 2 * $r, 180, 90); $sp.AddArc($x + $w - 2 * $r, $y, 2 * $r, 2 * $r, 270, 90)
  $sp.AddArc($x + $w - 2 * $r, $y + $h - 2 * $r, 2 * $r, 2 * $r, 0, 90); $sp.AddArc($x, $y + $h - 2 * $r, 2 * $r, 2 * $r, 90, 90)
  $sp.CloseFigure(); $g.FillPath($stem, $sp)
  # face
  $ink = New-Object System.Drawing.SolidBrush (C '#1a1410')
  foreach ($ex in @(-4.5, 4.5)) {
    $g.FillEllipse($ink, $cx + ($ex - 2.2) * $k, $cy + 6.5 * $k, 4.4 * $k, 6 * $k)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush (C '#ffffff')), $cx + ($ex - 0.1) * $k, $cy + 7.4 * $k, 1.8 * $k, 1.8 * $k)
  }
  $blush = New-Object System.Drawing.SolidBrush (C '#e86e6e' 115)
  $g.FillEllipse($blush, $cx - 10.6 * $k, $cy + 11.4 * $k, 5.2 * $k, 5.2 * $k)
  $g.FillEllipse($blush, $cx + 5.4 * $k, $cy + 11.4 * $k, 5.2 * $k, 5.2 * $k)
  $pen = New-Object System.Drawing.Pen (C '#1a1410'), (1.4 * $k)
  $g.DrawArc($pen, $cx - 2.4 * $k, $cy + 11.6 * $k, 4.8 * $k, 4.8 * $k, 27, 126)
  # gills
  $g.FillEllipse((New-Object System.Drawing.SolidBrush (C '#b98f62')), $cx - 22 * $k, $cy - 4 * $k, 44 * $k, 10 * $k)
  # cap
  $cp = New-Object System.Drawing.Drawing2D.GraphicsPath
  $cp.AddBezier($cx - 26 * $k, $cy + 1 * $k, $cx - 27 * $k, $cy - 29 * $k, $cx + 27 * $k, $cy - 29 * $k, $cx + 26 * $k, $cy + 1 * $k)
  $cp.AddBezier($cx + 26 * $k, $cy + 1 * $k, $cx + 9 * $k, $cy + 4.5 * $k, $cx - 9 * $k, $cy + 4.5 * $k, $cx - 26 * $k, $cy + 1 * $k)
  $cp.CloseFigure()
  $cb = New-Object System.Drawing.Drawing2D.PathGradientBrush $cp
  $cb.CenterPoint = New-Object System.Drawing.PointF ($cx - 7 * $k), ($cy - 16 * $k)
  $cb.CenterColor = C '#f2694f'
  $cb.SurroundColors = @((C '#a3261a'))
  $g.FillPath($cb, $cp)
  $spot = New-Object System.Drawing.SolidBrush (C '#fdf6e6')
  foreach ($s2 in @(@(-13, -8, 4.2), @(1, -16, 4.8), @(13, -7, 3.6), @(-3, -5, 2.6), @(20, -1.5, 2))) {
    $rr = $s2[2]
    $g.FillEllipse($spot, $cx + ($s2[0] - $rr) * $k, $cy + ($s2[1] - $rr * 0.85) * $k, 2 * $rr * $k, 1.7 * $rr * $k)
  }
}

function New-Canvas($w, $h) {
  $bmp = New-Object System.Drawing.Bitmap $w, $h
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'
  return @($bmp, $g)
}

New-Item -ItemType Directory -Force (Join-Path $OutDir 'icons') | Out-Null

# App icons: full-bleed background so they also work as maskable icons.
foreach ($spec in @(@('icon-512.png', 512), @('icon-192.png', 192), @('apple-touch-icon.png', 180))) {
  $n = $spec[1]
  $bmp, $g = New-Canvas $n $n
  Draw-Sky $g $n $n
  $g.FillRectangle((New-Object System.Drawing.SolidBrush (C '#10233a')), 0, [int]($n * 0.84), $n, $n)
  $g.FillRectangle((New-Object System.Drawing.SolidBrush (C '#4e8a3a')), 0, [int]($n * 0.84), $n, [int]([Math]::Max(2, $n * 0.025)))
  Draw-Mushroom $g ($n * 0.5) ($n * 0.5) ($n * 0.27)
  $bmp.Save((Join-Path $OutDir "icons\$($spec[0])"), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}

# Share preview image 1200x630
$bmp, $g = New-Canvas 1200 630
Draw-Sky $g 1200 630
$g.FillRectangle((New-Object System.Drawing.SolidBrush (C '#10233a')), 0, 540, 1200, 90)
$g.FillRectangle((New-Object System.Drawing.SolidBrush (C '#4e8a3a')), 0, 540, 1200, 12)
Draw-Mushroom $g 900 330 150
$fam = 'Arial Rounded MT Bold'
if (-not ((New-Object System.Drawing.Text.InstalledFontCollection).Families.Name -contains $fam)) { $fam = 'Segoe UI Black' }
$f1 = New-Object System.Drawing.Font $fam, 92, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$f2 = New-Object System.Drawing.Font $fam, 34, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
foreach ($line in @(@('Flappy', 150, '#f6ead2'), @('Mushroom', 250, '#d8432f'))) {
  $tp = New-Object System.Drawing.Drawing2D.GraphicsPath
  $tp.AddString($line[0], $f1.FontFamily, [int]$f1.Style, $f1.Size, (New-Object System.Drawing.PointF 70, $line[1]), [System.Drawing.StringFormat]::GenericDefault)
  $op = New-Object System.Drawing.Pen (C "#0b1220"), 14; $op.LineJoin = "Round"; $g.DrawPath($op, $tp)
  $g.FillPath((New-Object System.Drawing.SolidBrush (C $line[2])), $tp)
}
$g.DrawString('Hop the forest. Climb the daily rankings.', $f2, (New-Object System.Drawing.SolidBrush (C '#ffd96a')), 76, 380)
$bmp.Save((Join-Path $OutDir 'og-image.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
'done'
