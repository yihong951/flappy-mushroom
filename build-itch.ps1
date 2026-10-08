# Packages the game for itch.io: dist\flappy-mushroom-itch.zip with index.html at the zip root.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$stage = Join-Path $root 'dist\itch'
$zip = Join-Path $root 'dist\flappy-mushroom-itch.zip'

if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Force $stage | Out-Null
Copy-Item (Join-Path $root 'index.html'), (Join-Path $root 'manifest.webmanifest') $stage
Copy-Item -Recurse (Join-Path $root 'icons') $stage

if (Test-Path $zip) { Remove-Item -Force $zip }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip
Remove-Item -Recurse -Force $stage
"Created $zip"
