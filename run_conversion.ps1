# =============================================================================
# YOLO ONNX to TFLite Conversion Script
# Fallback: Instructions for using Google Colab
# =============================================================================

Write-Host "="*70 -ForegroundColor Cyan
Write-Host " YOLO ONNX to TFLite Converter" -ForegroundColor Yellow
Write-Host "="*70 -ForegroundColor Cyan

# Check if Python is available
Write-Host "`nChecking for Python installation..." -ForegroundColor Cyan
$pythonPath = Get-Command python -ErrorAction SilentlyContinue

if (-not $pythonPath) {
    Write-Host "❌ Python not found in PATH" -ForegroundColor Red
    Write-Host "`nYou have 3 options:" -ForegroundColor Yellow
    Write-Host "`n1️⃣  Install Python 3.10:" -ForegroundColor Green
    Write-Host "   Download from: https://www.python.org/downloads/"
    Write-Host "   Make sure to check 'Add Python to PATH' during installation"

    Write-Host "`n2️⃣  Use Google Colab (Recommended if no Python):" -ForegroundColor Green
    Write-Host "   a) Open: https://colab.research.google.com/"
    Write-Host "   b) Create new notebook"
    Write-Host "   c) Copy and paste the code from TFLITE_CONVERSION_GUIDE.md"
    Write-Host "   d) Upload your ONNX model"
    Write-Host "   e) Download the converted TFLite model"

    Write-Host "`n3️⃣  Use pre-converted model:" -ForegroundColor Green
    Write-Host "   If your YOLO trainer provides TFLite export, use that"

    Write-Host "`n"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Python found: $($pythonPath.Source)" -ForegroundColor Green

# Check Python version
$pythonVersion = & python --version 2>&1
Write-Host "✅ $pythonVersion" -ForegroundColor Green

# Check if running in virtual environment
$inVenv = $env:VIRTUAL_ENV
if ($inVenv) {
    Write-Host "✅ Virtual environment active: $inVenv" -ForegroundColor Green
} else {
    Write-Host "⚠️  No virtual environment detected" -ForegroundColor Yellow
    Write-Host "   Creating virtual environment for clean installation..." -ForegroundColor Yellow

    # Create venv
    python -m venv venv_tflite
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Virtual environment created" -ForegroundColor Green
        Write-Host "   Activating..." -ForegroundColor Cyan
        .\venv_tflite\Scripts\Activate.ps1
    } else {
        Write-Host "❌ Failed to create virtual environment" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n" + "="*70 -ForegroundColor Cyan
Write-Host " Installing Dependencies" -ForegroundColor Yellow
Write-Host "="*70 -ForegroundColor Cyan

Write-Host "`nThis may take a few minutes..." -ForegroundColor Yellow

# Upgrade pip
Write-Host "`n📦 Upgrading pip..." -ForegroundColor Cyan
python -m pip install --upgrade pip --quiet

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to upgrade pip" -ForegroundColor Red
    exit 1
}

# Install packages
$packages = @(
    "tensorflow==2.13.0",
    "onnx==1.14.0",
    "numpy<2.0",
    "ultralytics"
)

foreach ($package in $packages) {
    Write-Host "📦 Installing $package..." -ForegroundColor Cyan
    python -m pip install $package --quiet

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install $package" -ForegroundColor Red
        Write-Host "   Try manually: pip install $package" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ All dependencies installed" -ForegroundColor Green

# Run the conversion script
Write-Host "`n" + "="*70 -ForegroundColor Cyan
Write-Host " Running Conversion" -ForegroundColor Yellow
Write-Host "="*70 -ForegroundColor Cyan

if (Test-Path ".\convert_yolo_to_tflite.py") {
    python convert_yolo_to_tflite.py
} else {
    Write-Host "❌ convert_yolo_to_tflite.py not found" -ForegroundColor Red
    Write-Host "   Please ensure the script is in the current directory" -ForegroundColor Yellow
}

Write-Host "`n" + "="*70 -ForegroundColor Cyan
Write-Host " Done" -ForegroundColor Yellow
Write-Host "="*70 -ForegroundColor Cyan

Read-Host "`nPress Enter to exit"

