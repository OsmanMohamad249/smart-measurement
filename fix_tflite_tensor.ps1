# Fix tflite_flutter tensor.dart issue
# This script finds and patches the tensor.dart file automatically

Write-Host "`n🔧 TFLite Flutter Tensor.dart Patcher`n" -ForegroundColor Cyan

# Find the file
$searchPaths = @(
    "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev",
    "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dartlang.org",
    "$env:APPDATA\Pub\Cache\hosted\pub.dev",
    "$env:APPDATA\Pub\Cache\hosted\pub.dartlang.org"
)

$tensorFile = $null

foreach ($basePath in $searchPaths) {
    if (Test-Path $basePath) {
        $tfliteDirs = Get-ChildItem -Path $basePath -Directory -Filter "tflite_flutter-*" -ErrorAction SilentlyContinue
        foreach ($dir in $tfliteDirs) {
            $possibleFile = Join-Path $dir.FullName "lib\src\tensor.dart"
            if (Test-Path $possibleFile) {
                $tensorFile = $possibleFile
                Write-Host "✅ Found tensor.dart at:" -ForegroundColor Green
                Write-Host "   $tensorFile`n" -ForegroundColor White
                break
            }
        }
        if ($tensorFile) { break }
    }
}

if (-not $tensorFile) {
    Write-Host "❌ tensor.dart not found!" -ForegroundColor Red
    Write-Host "   Run 'flutter pub get' first.`n" -ForegroundColor Yellow
    exit 1
}

# Read the file
$content = Get-Content $tensorFile -Raw

# Check if already patched
if ($content -match "// PATCHED by smart-measurement") {
    Write-Host "✅ Already patched!`n" -ForegroundColor Green
    exit 0
}

# Apply fixes
Write-Host "🔄 Applying patches..." -ForegroundColor Cyan

# Fix 1: Line 58 - UnmodifiableUint8ListView
$content = $content -replace 'return UnmodifiableUint8ListView\(', 'return Uint8List.view('

# Fix 2: Line 60 - asTypedList issue
$content = $content -replace 'data\.asTypedList\(tfliteBinding\.TfLiteTensorByteSize\(_tensor\)\)\);', 'data.buffer.asUint8List(data.offsetInBytes, tfliteBinding.TfLiteTensorByteSize(_tensor)));'

# Add patch marker
$content = "// PATCHED by smart-measurement fix script`n" + $content

# Write back
Set-Content -Path $tensorFile -Value $content -NoNewline

Write-Host "✅ Patches applied successfully!`n" -ForegroundColor Green

Write-Host "📋 Changes made:" -ForegroundColor Yellow
Write-Host "   1. Fixed UnmodifiableUint8ListView → Uint8List.view" -ForegroundColor White
Write-Host "   2. Fixed asTypedList → buffer.asUint8List`n" -ForegroundColor White

Write-Host "🚀 Next steps:" -ForegroundColor Cyan
Write-Host "   flutter clean" -ForegroundColor White
Write-Host "   flutter run --release`n" -ForegroundColor White

