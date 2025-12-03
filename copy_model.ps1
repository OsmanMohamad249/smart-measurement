# Script to copy YOLO model from card-detection-yolo to smart-measurement

$sourcePath = "C:\Users\HP\PycharmProjects\card-detection-yolo\flutter_app\assets\models"
$destPath = "C:\Users\HP\PycharmProjects\smart-measurement\assets\models"

Write-Host "=== YOLO Model Copy Script ===" -ForegroundColor Cyan
Write-Host ""

# Check if source exists
if (-not (Test-Path $sourcePath)) {
    Write-Host "ERROR: Source path does not exist: $sourcePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Searching for .tflite files in card-detection-yolo..." -ForegroundColor Yellow

    $tfliteFiles = Get-ChildItem "C:\Users\HP\PycharmProjects\card-detection-yolo" -Recurse -Filter "*.tflite" -ErrorAction SilentlyContinue

    if ($tfliteFiles.Count -gt 0) {
        Write-Host "Found $($tfliteFiles.Count) .tflite file(s):" -ForegroundColor Green
        foreach ($file in $tfliteFiles) {
            Write-Host "  - $($file.FullName)" -ForegroundColor White
        }

        Write-Host ""
        Write-Host "Copying first .tflite file to destination..." -ForegroundColor Yellow

        $firstFile = $tfliteFiles[0]
        Copy-Item $firstFile.FullName -Destination "$destPath\yolov8_pose.tflite" -Force

        Write-Host "SUCCESS: Copied $($firstFile.Name) to $destPath\yolov8_pose.tflite" -ForegroundColor Green
    } else {
        Write-Host "No .tflite files found in card-detection-yolo directory" -ForegroundColor Red
        Write-Host "Please check if the repository was cloned correctly" -ForegroundColor Yellow
    }
} else {
    Write-Host "Source path found: $sourcePath" -ForegroundColor Green

    # Get all files from source
    $files = Get-ChildItem $sourcePath -File

    if ($files.Count -eq 0) {
        Write-Host "WARNING: Source directory is empty" -ForegroundColor Yellow
    } else {
        Write-Host "Found $($files.Count) file(s) to copy" -ForegroundColor Green

        # Create destination directory if it doesn't exist
        if (-not (Test-Path $destPath)) {
            New-Item -ItemType Directory -Path $destPath -Force | Out-Null
        }

        # Copy each file
        foreach ($file in $files) {
            Copy-Item $file.FullName -Destination $destPath -Force
            Write-Host "  Copied: $($file.Name)" -ForegroundColor White
        }

        Write-Host ""
        Write-Host "SUCCESS: All files copied to $destPath" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Verification ===" -ForegroundColor Cyan
$destFiles = Get-ChildItem $destPath -File -ErrorAction SilentlyContinue

if ($destFiles) {
    Write-Host "Files in destination:" -ForegroundColor Green
    foreach ($file in $destFiles) {
        $sizeKB = [math]::Round($file.Length / 1KB, 2)
        Write-Host "  - $($file.Name) ($sizeKB KB)" -ForegroundColor White
    }
} else {
    Write-Host "WARNING: No files found in destination directory" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Script completed!" -ForegroundColor Cyan

