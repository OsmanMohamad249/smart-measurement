# Fix tflite_flutter tensor.dart UnmodifiableUint8ListView issue
# This script patches the tflite_flutter library to work with newer Dart SDK

Write-Host "`n🔧 Fixing tflite_flutter tensor.dart issue...`n" -ForegroundColor Cyan

# Find the tflite_flutter package
$pubCache = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev"
$tfliteDirs = Get-ChildItem -Path $pubCache -Directory -Filter "tflite_flutter-*" -ErrorAction SilentlyContinue

if ($tfliteDirs.Count -eq 0) {
    Write-Host "❌ tflite_flutter not found in pub cache" -ForegroundColor Red
    Write-Host "   Run 'flutter pub get' first" -ForegroundColor Yellow
    exit 1
}

foreach ($dir in $tfliteDirs) {
    $tensorFile = Join-Path $dir.FullName "lib\src\tensor.dart"

    if (Test-Path $tensorFile) {
        Write-Host "✅ Found: $tensorFile" -ForegroundColor Green

        # Read the file
        $content = Get-Content $tensorFile -Raw

        # Check if already patched
        if ($content -match "\/\/ PATCHED") {
            Write-Host "✅ Already patched!" -ForegroundColor Green
            continue
        }

        # Apply the fix
        $content = $content -replace "return UnmodifiableUint8ListView\(", "return Uint8List.view("

        # Add patch marker
        $content = "// PATCHED by smart-measurement fix script`n" + $content

        # Write back
        Set-Content -Path $tensorFile -Value $content -NoNewline

        Write-Host "✅ Patched successfully!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  tensor.dart not found in $($dir.Name)" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ Fix applied! Now run: flutter clean && flutter pub get`n" -ForegroundColor Green

