# Packages the game for itch.io: dist\flappy-mushroom-itch.zip with index.html at the zip root.
# Entries are written with forward slashes; Compress-Archive on Windows PowerShell 5.1 uses
# backslashes, which itch.io's servers treat as part of the file name.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$root = $PSScriptRoot
$dist = Join-Path $root 'dist'
$zip = Join-Path $dist 'flappy-mushroom-itch.zip'
$files = @('index.html', 'manifest.webmanifest') + (Get-ChildItem (Join-Path $root 'icons') -File | ForEach-Object { "icons/$($_.Name)" })

New-Item -ItemType Directory -Force $dist | Out-Null
if (Test-Path $zip) { Remove-Item -Force $zip }
$archive = [System.IO.Compression.ZipFile]::Open($zip, 'Create')
try {
  foreach ($f in $files) {
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, (Join-Path $root $f), $f, 'Optimal') | Out-Null
  }
} finally {
  $archive.Dispose()
}
"Created $zip"
