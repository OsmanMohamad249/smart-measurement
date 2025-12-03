#!/usr/bin/env pwsh
# Complete fix for tflite_flutter tensor.dart issue
# Run this after flutter pub get

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TFLite Flutter Complete Fix Script" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Run pub get first
Write-Host "Step 1: Running flutter pub get..." -ForegroundColor Yellow
flutter pub get

# Step 2: Find tensor.dart
Write-Host "`nStep 2: Locating tensor.dart..." -ForegroundColor Yellow

$found = $false
$tensorFile = $null

# Search in multiple possible locations
$basePaths = @(
    "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev",
    "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dartlang.org",
    "$env:APPDATA\Pub\Cache\hosted\pub.dev",
    "$env:APPDATA\Pub\Cache\hosted\pub.dartlang.org",
    "$env:USERPROFILE\.pub-cache\hosted\pub.dev",
    "$env:USERPROFILE\.pub-cache\hosted\pub.dartlang.org"
)

foreach ($basePath in $basePaths) {
    if (Test-Path $basePath) {
        $tfliteDirs = Get-ChildItem -Path $basePath -Directory -Filter "tflite_flutter-*" -ErrorAction SilentlyContinue
        foreach ($dir in $tfliteDirs) {
            $possibleFile = Join-Path $dir.FullName "lib\src\tensor.dart"
            if (Test-Path $possibleFile) {
                $tensorFile = $possibleFile
                $found = $true
                Write-Host "✓ Found: $tensorFile" -ForegroundColor Green
                break
            }
        }
        if ($found) { break }
    }
}

if (-not $found) {
    Write-Host "✗ tensor.dart not found in pub cache!" -ForegroundColor Red
    Write-Host "  Make sure flutter pub get completed successfully." -ForegroundColor Yellow
    exit 1
}

# Step 3: Backup original file
Write-Host "`nStep 3: Creating backup..." -ForegroundColor Yellow
$backupFile = "$tensorFile.backup"
if (-not (Test-Path $backupFile)) {
    Copy-Item $tensorFile $backupFile
    Write-Host "✓ Backup created" -ForegroundColor Green
} else {
    Write-Host "✓ Backup already exists" -ForegroundColor Green
}

# Step 4: Read and fix the file
Write-Host "`nStep 4: Applying fixes..." -ForegroundColor Yellow

$content = Get-Content $tensorFile -Raw

# Check if already patched
if ($content -match "// PATCHED FOR DART 3") {
    Write-Host "✓ File already patched!" -ForegroundColor Green
    Write-Host "`n✓ All done! Run 'flutter run --release' now.`n" -ForegroundColor Green
    exit 0
}

# Apply Fix 1: Line ~58 - UnmodifiableUint8ListView
$fix1Applied = $false
if ($content -match 'return UnmodifiableUint8ListView\(') {
    $content = $content -replace 'return UnmodifiableUint8ListView\(', 'return Uint8List.view('
    $fix1Applied = $true
    Write-Host "✓ Fix 1: UnmodifiableUint8ListView → Uint8List.view" -ForegroundColor Green
}

# Apply Fix 2: Line ~60 - asTypedList
$fix2Applied = $false
if ($content -match '    data\.asTypedList\(tfliteBinding\.TfLiteTensorByteSize\(_tensor\)\)\);') {
    $content = $content -replace '    data\.asTypedList\(tfliteBinding\.TfLiteTensorByteSize\(_tensor\)\)\);', '    data.buffer.asUint8List(data.offsetInBytes, tfliteBinding.TfLiteTensorByteSize(_tensor)));'
    $fix2Applied = $true
    Write-Host "✓ Fix 2: asTypedList → buffer.asUint8List" -ForegroundColor Green
}

if (-not $fix1Applied -and -not $fix2Applied) {
    Write-Host "⚠ No fixes needed or patterns not found" -ForegroundColor Yellow
    Write-Host "  The file may already be correct or have different content." -ForegroundColor Yellow
}

# Add patch marker
$patchMarker = "// PATCHED FOR DART 3 COMPATIBILITY - DO NOT EDIT`n"
$content = $patchMarker + $content

# Step 5: Write the fixed content
Set-Content -Path $tensorFile -Value $content -NoNewline
Write-Host "✓ File saved" -ForegroundColor Green

# Step 6: Clean and verify
Write-Host "`nStep 5: Cleaning Flutter project..." -ForegroundColor Yellow
flutter clean | Out-Null
Write-Host "✓ Project cleaned" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✓ Fix completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. flutter pub get" -ForegroundColor White
Write-Host "  2. flutter run --release`n" -ForegroundColor White

Write-Host "Note: If you run 'flutter pub get' again, you may need to re-run this script.`n" -ForegroundColor Cyan

