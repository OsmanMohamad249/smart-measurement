#!/usr/bin/env pwsh
# Ultimate fix for tflite_flutter tensor.dart

Write-Host "`n🔧 TFLite Flutter Ultimate Fix" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Step 1: Ensure we have the right version
Write-Host "[1/5] Checking pubspec.yaml..." -ForegroundColor Yellow
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match "tflite_flutter:\s*0\.10\.4") {
    Write-Host "✓ Version 0.10.4 confirmed" -ForegroundColor Green
} else {
    Write-Host "✗ Wrong version! Please ensure pubspec.yaml has:" -ForegroundColor Red
    Write-Host "  tflite_flutter: 0.10.4" -ForegroundColor Yellow
    exit 1
}

# Step 2: Run pub get
Write-Host "`n[2/5] Running flutter pub get..." -ForegroundColor Yellow
flutter pub get | Out-Null
Write-Host "✓ Dependencies updated" -ForegroundColor Green

# Step 3: Find tensor.dart in all possible locations
Write-Host "`n[3/5] Locating tensor.dart..." -ForegroundColor Yellow

$searchPaths = @(
    "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev",
    "$env:APPDATA\Pub\Cache\hosted\pub.dev",
    "$env:USERPROFILE\.pub-cache\hosted\pub.dev"
)

$tensorFile = $null
foreach ($base in $searchPaths) {
    if (Test-Path $base) {
        $dirs = Get-ChildItem $base -Directory -Filter "tflite_flutter-0.10.4" -ErrorAction SilentlyContinue
        foreach ($dir in $dirs) {
            $file = Join-Path $dir.FullName "lib\src\tensor.dart"
            if (Test-Path $file) {
                $tensorFile = $file
                Write-Host "✓ Found at: $tensorFile" -ForegroundColor Green
                break
            }
        }
        if ($tensorFile) { break }
    }
}

if (-not $tensorFile) {
    Write-Host "✗ tensor.dart not found!" -ForegroundColor Red
    Write-Host "  Pub cache may be in a different location." -ForegroundColor Yellow
    Write-Host "  Try running manually:" -ForegroundColor Yellow
    Write-Host "  1. flutter pub cache repair" -ForegroundColor White
    Write-Host "  2. flutter pub get" -ForegroundColor White
    Write-Host "  3. Run this script again" -ForegroundColor White
    exit 1
}

# Step 4: Apply the fix
Write-Host "`n[4/5] Applying fixes..." -ForegroundColor Yellow

$content = Get-Content $tensorFile -Raw

# Check if already fixed
if ($content -match "// PATCHED FOR DART 3|Uint8List\.view") {
    Write-Host "✓ Already patched!" -ForegroundColor Green
} else {
    # Backup
    $backup = "$tensorFile.original"
    if (-not (Test-Path $backup)) {
        Copy-Item $tensorFile $backup
    }

    # Fix line 58
    $content = $content -replace 'return UnmodifiableUint8ListView\(', 'return Uint8List.view('

    # Fix line 60
    $content = $content -replace 'data\.asTypedList\(tfliteBinding\.TfLiteTensorByteSize\(_tensor\)\)\);', 'data.buffer.asUint8List(data.offsetInBytes, tfliteBinding.TfLiteTensorByteSize(_tensor)));'

    # Add marker
    $content = "// PATCHED FOR DART 3 COMPATIBILITY`n" + $content

    # Save
    Set-Content $tensorFile $content -NoNewline

    Write-Host "✓ Fixes applied successfully!" -ForegroundColor Green
}

# Step 5: Clean and ready
Write-Host "`n[5/5] Cleaning project..." -ForegroundColor Yellow
flutter clean | Out-Null
Write-Host "✓ Project cleaned" -ForegroundColor Green

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "✓ All done!" -ForegroundColor Green
Write-Host "================================`n" -ForegroundColor Cyan

Write-Host "Next: Run this command:" -ForegroundColor Yellow
Write-Host "  flutter run --release`n" -ForegroundColor White

