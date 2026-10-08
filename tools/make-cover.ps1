param([string]$OutFile, [int]$Scale = 2)
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$W = 630; $H = 500; $GY = 432
function C($hex, $a = 255) { $c = [System.Drawing.ColorTranslator]::FromHtml($hex); [System.Drawing.Color]::FromArgb($a, $c.R, $c.G, $c.B) }
function B($hex, $a = 255) { New-Object System.Drawing.SolidBrush (C $hex $a) }
function RoundRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = 2 * $r
  $p.AddArc($x, $y, $d, $d, 180, 90); $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90); $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure(); return $p
}
function Glow($g, [float]$x, [float]$y, [float]$r, $hex, $a) {
  $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
  $gp.AddEllipse($x - $r, $y - $r, 2 * $r, 2 * $r)
  $pb = New-Object System.Drawing.Drawing2D.PathGradientBrush $gp
  $pb.CenterColor = C $hex $a
  $pb.SurroundColors = @((C $hex 0))
  $g.FillPath($pb, $gp)
}
function Hash([double]$n) { $s = [Math]::Sin($n * 127.1 + 311.7) * 43758.5453; return $s - [Math]::Floor($s) }

$bmp = New-Object System.Drawing.Bitmap ($W * $Scale), ($H * $Scale)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAlias'; $g.PixelOffsetMode = 'HighQuality'
$g.ScaleTransform($Scale, $Scale)

# ---- sky, stars, moon ----
$sky = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Rectangle 0, 0, $W, $GY), (C '#0c1530'), (C '#4a6a8e'), 90
$blend = New-Object System.Drawing.Drawing2D.ColorBlend 3
$blend.Colors = @((C '#0c1530'), (C '#1d3560'), (C '#55748f'))
$blend.Positions = @(0.0, 0.55, 1.0)
$sky.InterpolationColors = $blend
$g.FillRectangle($sky, 0, 0, $W, $GY + 2)
$rnd = New-Object System.Random 11
for ($i = 0; $i -lt 90; $i++) {
  $s = 0.8 + $rnd.NextDouble() * 1.6
  $g.FillEllipse((B '#ffffff' (60 + $rnd.Next(170))), [float]($rnd.NextDouble() * $W), [float]($rnd.NextDouble() * 260), [float]$s, [float]$s)
}
Glow $g 545 78 110 '#fbf0cf' 70
$g.FillEllipse((B '#fbf0cf'), 517, 50, 56, 56)
$g.FillEllipse((B '#beaf8c' 90), 528, 62, 13, 13)
$g.FillEllipse((B '#beaf8c' 90), 549, 80, 9, 9)

# ---- hills and two pine layers ----
$pts = New-Object System.Collections.Generic.List[System.Drawing.PointF]
$pts.Add((New-Object System.Drawing.PointF 0, $GY))
for ($x = 0; $x -le $W; $x += 6) { $pts.Add((New-Object System.Drawing.PointF $x, ([float]($GY - 150 + [Math]::Sin($x * 0.009) * 26 + [Math]::Sin($x * 0.023 + 1) * 13)))) }
$pts.Add((New-Object System.Drawing.PointF $W, $GY))
$g.FillPolygon((B '#203c5c'), $pts.ToArray())

function Pines($g, $sp, $baseY, $hmax, $hex, $seed) {
  $br = B $hex
  for ($i = -1; $i -le [int]($W / $sp) + 1; $i++) {
    $x = $i * $sp + (Hash ($i * 3.1 + $seed)) * $sp * 0.5
    $ph = $hmax * (0.55 + 0.45 * (Hash ($i * 7.7 + $seed)))
    $pw = $ph * 0.46
    for ($k = 0; $k -lt 3; $k++) {
      $ty = $baseY - $ph + $k * $ph * 0.27; $tw = $pw * (0.55 + $k * 0.25)
      $g.FillPolygon($br, [System.Drawing.PointF[]]@(
        (New-Object System.Drawing.PointF ([float]$x), ([float]$ty)),
        (New-Object System.Drawing.PointF ([float]($x + $tw / 2)), ([float]($ty + $ph * 0.42))),
        (New-Object System.Drawing.PointF ([float]($x - $tw / 2)), ([float]($ty + $ph * 0.42)))))
    }
    $g.FillRectangle($br, [float]($x - 3), [float]($baseY - $ph * 0.2), 6, [float]($ph * 0.22))
  }
  $g.FillRectangle($br, 0, $baseY - 2, $W, $GY - $baseY + 4)
}
Pines $g 36 ($GY - 55) 80 '#18314d' 0
# fireflies between layers
for ($i = 0; $i -lt 16; $i++) {
  $fx = (Hash ($i + 1.3)) * $W; $fy = 150 + (Hash ($i + 5.1)) * 230
  Glow $g $fx $fy 9 '#ffd96a' 80
  $g.FillEllipse((B '#ffecaa' 230), [float]($fx - 1.8), [float]($fy - 1.8), 3.6, 3.6)
}
Pines $g 54 ($GY + 4) 130 '#10233a' 50

# ---- logs ----
function Trunk($g, [float]$x, [float]$top, [float]$bot, [float]$seed) {
  $OW = 78
  $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.RectangleF ($x - 6), 0, ($OW + 12), 10), (C '#2b1b0f'), (C '#24170c'), 0
  $cb = New-Object System.Drawing.Drawing2D.ColorBlend 4
  $cb.Colors = @((C '#2b1b0f'), (C '#6a4829'), (C '#56391f'), (C '#24170c'))
  $cb.Positions = @(0.0, 0.3, 0.55, 1.0)
  $br.InterpolationColors = $cb
  $g.FillRectangle($br, $x, -5, $OW, $top + 5)
  $g.FillRectangle($br, $x, $bot, $OW, $GY - $bot + 4)
  $pen = New-Object System.Drawing.Pen (C '#120a04' 130), 2.6
  for ($k = 1; $k -lt 4; $k++) {
    $gx = $x + $OW * $k / 4 + ((Hash ($seed + $k)) - 0.5) * 8
    $g.DrawLine($pen, $gx, -5, $gx, $top - 18); $g.DrawLine($pen, $gx, $bot + 18, $gx, $GY)
  }
  # shelf fungus
  $fy = $bot + 42
  if ($GY - $fy -gt 20) {
    $g.FillPie((B '#e0a347'), $x + $OW - 16, $fy - 6, 32, 12, -90, 180)
    $g.FillPie((B '#c98a34'), $x + $OW - 11, $fy + 6, 22, 10, -90, 180)
    $g.FillPie((B '#f4cf7c'), $x + $OW - 10, $fy - 4, 20, 4, -90, 180)
  }
  # stump lip with rings
  $g.FillRectangle($br, $x - 5, $bot, $OW + 10, 16)
  $cx = $x + $OW / 2; $rx = $OW / 2 + 5
  $g.FillEllipse((B '#c99a62'), $cx - $rx, $bot - 7, 2 * $rx, 14)
  $rp = New-Object System.Drawing.Pen (C '#9a6c3e'), 1.5
  foreach ($f in @(0.72, 0.46, 0.22)) { $g.DrawEllipse($rp, [float]($cx - $rx * $f), [float]($bot - 7 * $f), [float](2 * $rx * $f), [float](14 * $f)) }
  # hanging log lip, underside, moss
  $g.FillRectangle($br, $x - 5, $top - 16, $OW + 10, 16)
  $g.FillEllipse((B '#1e1309'), $cx - $rx, $top - 6, 2 * $rx, 12)
  $g.FillRectangle((B '#5f9c45'), $x - 5, $top - 18, $OW + 10, 6)
  for ($i = 0; $i -lt 6; $i++) {
    $mx = $x - 5 + ($i + 0.5) * ($OW + 10) / 6
    $g.FillPath((B '#5f9c45'), (RoundRect ($mx - 4.5) ($top - 16) 9 (14 + (Hash ($seed + 20 + $i)) * 16) 4.5))
  }
  # vine
  $vx = $x + 20
  $vp = New-Object System.Drawing.Pen (C '#4a8536'), 2
  $g.DrawBezier($vp, $vx, $top, $vx + 7, $top + 18, $vx - 4, $top + 34, $vx + 2, $top + 52)
  foreach ($k in 1..3) { $g.FillEllipse((B '#6fb150'), [float]($vx + $(if ($k % 2) { 1 } else { -7 })), [float]($top + $k * 15), 7, 4) }
}
Trunk $g 392 178 342 5
Trunk $g 598 108 278 9

# ---- ground ----
$gb = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Rectangle 0, $GY, $W, ($H - $GY)), (C '#3b2a1b'), (C '#1c130b'), 90
$g.FillRectangle($gb, 0, $GY, $W, $H - $GY)
for ($i = 0; $i -lt 22; $i++) {
  $g.FillEllipse((B '#000000' 60), [float]((Hash ($i * 1.7)) * $W), [float]($GY + 22 + (Hash ($i * 2.9)) * 40), [float](5 + (Hash $i) * 8), [float](3 + (Hash ($i * 3)) * 3))
}
$g.FillRectangle((B '#4e8a3a'), 0, $GY, $W, 9)
$g.FillRectangle((B '#355f28'), 0, $GY + 9, $W, 4)
function Tiny($g, [float]$x, [float]$s, $hex) {
  $g.FillPath((B '#efe2c4'), (RoundRect ($x - 4 * $s) ($GY + 2 - 14 * $s) (8 * $s) (14 * $s) (3 * $s)))
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $p.AddBezier($x - 13 * $s, $GY + 2 - 12 * $s, $x - 13 * $s, $GY + 2 - 28 * $s, $x + 13 * $s, $GY + 2 - 28 * $s, $x + 13 * $s, $GY + 2 - 12 * $s)
  $p.CloseFigure(); $g.FillPath((B $hex), $p)
}
Tiny $g 60 0.9 '#b7412f'; Tiny $g 84 0.6 '#c8a24a'; Tiny $g 300 0.75 '#c8a24a'; Tiny $g 528 0.85 '#b7412f'
$grass = B '#62a34a'
for ($x = -4; $x -lt $W; $x += 13) {
  $bladeH = 5 + (Hash ($x * 0.37)) * 8
  $g.FillPolygon($grass, [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF $x, ($GY + 2)), (New-Object System.Drawing.PointF ($x + 3), ($GY - $bladeH)), (New-Object System.Drawing.PointF ($x + 6), ($GY + 2))))
}

# ---- power caps ----
function PowerCap($g, [float]$x, [float]$y, [float]$s, $cap, $spot, $glowHex) {
  Glow $g $x $y (40 * $s) $glowHex 110
  $g.FillPath((B '#f4e8cf'), (RoundRect ($x - 4.5 * $s) ($y - 2 * $s) (9 * $s) (13 * $s) (3.5 * $s)))
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $p.AddBezier($x - 14 * $s, $y, $x - 15 * $s, $y - 20 * $s, $x + 15 * $s, $y - 20 * $s, $x + 14 * $s, $y)
  $p.AddBezier($x + 14 * $s, $y, $x + 5 * $s, $y + 2 * $s, $x - 5 * $s, $y + 2 * $s, $x - 14 * $s, $y)
  $p.CloseFigure(); $g.FillPath((B $cap), $p)
  foreach ($sp in @(@(-7, -5, 2.4), @(2, -10, 2.8), @(8, -4, 2))) {
    $r = $sp[2] * $s; $g.FillEllipse((B $spot), [float]($x + $sp[0] * $s - $r), [float]($y + $sp[1] * $s - $r), [float](2 * $r), [float](2 * $r))
  }
}
function Sparkle($g, [float]$x, [float]$y, [float]$s, $hex) {
  $g.FillPolygon((B $hex), [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF $x, ($y - $s)), (New-Object System.Drawing.PointF ($x + $s * 0.28), ($y - $s * 0.28)),
    (New-Object System.Drawing.PointF ($x + $s), $y), (New-Object System.Drawing.PointF ($x + $s * 0.28), ($y + $s * 0.28)),
    (New-Object System.Drawing.PointF $x, ($y + $s)), (New-Object System.Drawing.PointF ($x - $s * 0.28), ($y + $s * 0.28)),
    (New-Object System.Drawing.PointF ($x - $s), $y), (New-Object System.Drawing.PointF ($x - $s * 0.28), ($y - $s * 0.28))))
}
PowerCap $g 330 236 1.5 '#a46ae8' '#f3e9ff' '#a46ae8'
PowerCap $g 540 196 1.35 '#2f9be8' '#e6f5ff' '#2f9be8'
$zp = New-Object System.Drawing.Pen (C '#8fd0ff' 200), 2.4
$zp.StartCap = 'Round'; $zp.EndCap = 'Round'
foreach ($l in @(@(-10, 18), @(0, 26), @(10, 15))) { $g.DrawLine($zp, 566, (190 + $l[0]), (566 + $l[1]), (190 + $l[0])) }
PowerCap $g 112 372 1.45 '#ffc93c' '#fff7d6' '#ffc93c'
foreach ($a in 0..3) { $ang = $a * [Math]::PI / 2 + 0.4; Sparkle $g ([float](112 + [Math]::Cos($ang) * 34)) ([float](366 + [Math]::Sin($ang) * 30)) 5 '#ffe08a' }

# ---- hero mushroom ----
$mx = 228; $my = 300
# hop trail: fading spore dots along the arc behind it
for ($i = 1; $i -le 9; $i++) {
  $t = $i / 9.0
  $tx = $mx - 30 - $t * 150; $ty = $my + 40 + [Math]::Pow($t, 1.6) * 60 - $t * 10
  $g.FillEllipse((B '#ffecbe' ([int](200 * (1 - $t) + 30))), [float]($tx - 3), [float]($ty - 3), 6, 6)
}
foreach ($d in @(@(-18, 52, 3), @(-6, 60, 2.2), @(8, 55, 2.6), @(-26, 66, 1.8))) {
  $g.FillEllipse((B '#ffecbe' 170), [float]($mx + $d[0] - $d[2]), [float]($my + $d[1] - $d[2]), [float](2 * $d[2]), [float](2 * $d[2]))
}
Glow $g $mx $my 120 '#ffd96a' 55
$state = $g.Save()
$g.TranslateTransform($mx, $my)
$g.RotateTransform(-18)
$g.ScaleTransform(2.55 * 1.08, 2.55 * 0.94)   # mid-hop stretch
$g.FillPath((B '#d2bb90'), (RoundRect -9 16 7 10 3.5))
$g.FillPath((B '#d2bb90'), (RoundRect 2 15 7 10 3.5))
$sb = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.RectangleF -11, 0, 22, 10), (C '#dcc8a2'), (C '#cdb48a'), 0
$scb = New-Object System.Drawing.Drawing2D.ColorBlend 3
$scb.Colors = @((C '#dcc8a2'), (C '#fbf2de'), (C '#cdb48a')); $scb.Positions = @(0.0, 0.45, 1.0)
$sb.InterpolationColors = $scb
$g.FillPath($sb, (RoundRect -11 -2 22 23 9))
foreach ($ex in @(-4.5, 4.5)) {
  $g.FillEllipse((B '#1a1410'), [float]($ex - 2.3), 6.3, 4.6, 6.2)
  $g.FillEllipse((B '#ffffff'), [float]($ex - 0.1), 7.2, 1.9, 1.9)
}
$g.FillEllipse((B '#e86e6e' 120), -10.8, 11.2, 5.4, 5.4)
$g.FillEllipse((B '#e86e6e' 120), 5.4, 11.2, 5.4, 5.4)
$g.FillEllipse((B '#1a1410'), -2, 13.2, 4, 4.6)   # excited "o" mouth
$g.FillEllipse((B '#b98f62'), -22, -4, 44, 10)
$cp = New-Object System.Drawing.Drawing2D.GraphicsPath
$cp.AddBezier(-26, 1, -27, -29, 27, -29, 26, 1)
$cp.AddBezier(26, 1, 9, 4.5, -9, 4.5, -26, 1)
$cp.CloseFigure()
$capb = New-Object System.Drawing.Drawing2D.PathGradientBrush $cp
$capb.CenterPoint = New-Object System.Drawing.PointF -7, -16
$capb.CenterColor = C '#f4735a'
$capb.SurroundColors = @((C '#a3261a'))
$g.FillPath($capb, $cp)
foreach ($s2 in @(@(-13, -8, 4.2), @(1, -16, 4.8), @(13, -7, 3.6), @(-3, -5, 2.6), @(20, -1.5, 2))) {
  $r = $s2[2]; $g.FillEllipse((B '#fdf6e6'), [float]($s2[0] - $r), [float]($s2[1] - $r * 0.85), [float](2 * $r), [float](1.7 * $r))
}
$g.FillEllipse((B '#ffffff' 60), -17, -19, 12, 5)
$g.Restore($state)

# ---- title ----
$fam = 'Arial Rounded MT Bold'
if (-not ((New-Object System.Drawing.Text.InstalledFontCollection).Families.Name -contains $fam)) { $fam = 'Segoe UI Black' }
$ff = New-Object System.Drawing.FontFamily $fam
function Title($g, $txt, [float]$x, [float]$y, [float]$size, $fill, [float]$angle) {
  $tp = New-Object System.Drawing.Drawing2D.GraphicsPath
  $tp.AddString($txt, $ff, 0, $size, (New-Object System.Drawing.PointF 0, 0), [System.Drawing.StringFormat]::GenericTypographic)
  $st = $g.Save()
  $g.TranslateTransform($x, $y); $g.RotateTransform($angle)
  $g.TranslateTransform(0, 6)
  $sp = New-Object System.Drawing.Pen (C '#000000' 90), ($size * 0.22); $sp.LineJoin = 'Round'
  $g.DrawPath($sp, $tp)
  $g.TranslateTransform(0, -6)
  $op = New-Object System.Drawing.Pen (C '#0b1220'), ($size * 0.2); $op.LineJoin = 'Round'
  $g.DrawPath($op, $tp)
  $g.FillPath((B $fill), $tp)
  $g.Restore($st)
}
Title $g 'Flappy' 34 26 70 '#f6ead2' -4
Title $g 'Mushroom' 28 96 82 '#e2482f' -4

$g.Dispose()
$bmp.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
"Saved $OutFile ($($W * $Scale)x$($H * $Scale))"
