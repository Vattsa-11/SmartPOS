# SmartPOS Launcher - PowerShell Version
# Advanced startup script with better error handling and UI

# Set console properties
$Host.UI.RawUI.WindowTitle = "SmartPOS Launcher"
Clear-Host

# Display banner
Write-Host ""
Write-Host "  ====================================================="  -ForegroundColor Cyan
Write-Host "  |                                                   |"  -ForegroundColor Cyan
Write-Host "  |               SmartPOS Launcher                   |"  -ForegroundColor Cyan
Write-Host "  |            One-Click Startup Script               |"  -ForegroundColor Cyan
Write-Host "  |                                                   |"  -ForegroundColor Cyan
Write-Host "  ====================================================="  -ForegroundColor Cyan
Write-Host ""

# Define paths
$projectRoot = $PSScriptRoot
$backendPath = Join-Path $projectRoot "smartpos\backend"
$frontendPath = Join-Path $projectRoot "smartpos\frontend"

Write-Host "[INFO] Project root: $projectRoot" -ForegroundColor Gray
Write-Host "[INFO] Backend path: $backendPath" -ForegroundColor Gray
Write-Host "[INFO] Frontend path: $frontendPath" -ForegroundColor Gray
Write-Host ""

# Function to check if a command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Function to start a process in a new window
function Start-ServiceWindow {
    param(
        [string]$Title,
        [string]$WorkingDirectory,
        [string]$Command
    )
    
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "powershell.exe"
    $processInfo.Arguments = "-NoExit -Command `"& {Set-Location '$WorkingDirectory'; `$Host.UI.RawUI.WindowTitle='$Title'; $Command}`""
    $processInfo.WorkingDirectory = $WorkingDirectory
    $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
    
    [System.Diagnostics.Process]::Start($processInfo) | Out-Null
}

# Step 1: Check prerequisites
Write-Host "[1/6] Checking prerequisites..." -ForegroundColor Yellow

# Check Python
if (Test-Command "python") {
    Write-Host "[OK] Python is installed" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Python is not installed or not in PATH!" -ForegroundColor Red
    Write-Host "[INFO] Please install Python 3.8+ from https://python.org" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}

# Check Flutter
if (Test-Command "flutter") {
    Write-Host "[OK] Flutter is installed" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Flutter is not installed or not in PATH!" -ForegroundColor Red
    Write-Host "[INFO] Please install Flutter from https://flutter.dev" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}

# Check directories
if (Test-Path $backendPath) {
    Write-Host "[OK] Backend directory found" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Backend directory not found!" -ForegroundColor Red
    Write-Host "[INFO] Expected: $backendPath" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}

if (Test-Path $frontendPath) {
    Write-Host "[OK] Frontend directory found" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Frontend directory not found!" -ForegroundColor Red
    Write-Host "[INFO] Expected: $frontendPath" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}

# Step 2: Install backend dependencies
Write-Host ""
Write-Host "[2/6] Installing backend dependencies..." -ForegroundColor Yellow
Set-Location $backendPath

$requirementsFile = Join-Path $backendPath "requirements.txt"
if (Test-Path $requirementsFile) {
    try {
        pip install -r requirements.txt | Out-Null
        Write-Host "[OK] Backend dependencies installed" -ForegroundColor Green
    }
    catch {
        Write-Host "[WARNING] Some backend dependencies may have failed to install" -ForegroundColor Yellow
    }
} else {
    Write-Host "[WARNING] requirements.txt not found in backend directory" -ForegroundColor Yellow
}

# Step 3: Install frontend dependencies
Write-Host ""
Write-Host "[3/6] Installing frontend dependencies..." -ForegroundColor Yellow
Set-Location $frontendPath

try {
    flutter pub get | Out-Null
    Write-Host "[OK] Frontend dependencies installed" -ForegroundColor Green
}
catch {
    Write-Host "[WARNING] Frontend dependencies installation had issues" -ForegroundColor Yellow
}

# Step 4: Start backend server
Write-Host ""
Write-Host "[4/6] Starting backend server..." -ForegroundColor Yellow
Start-ServiceWindow -Title "SmartPOS Backend API" -WorkingDirectory $backendPath -Command "Write-Host 'Starting backend server on http://127.0.0.1:8001' -ForegroundColor Cyan; python -m uvicorn simple_fastapi:app --host 0.0.0.0 --port 8001 --reload"

Write-Host "[INFO] Waiting for backend to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 8

# Step 5: Build and start frontend application
Write-Host ""
Write-Host "[5/6] Building and starting frontend application..." -ForegroundColor Yellow
Set-Location $frontendPath

Write-Host "[INFO] Building Flutter web app (this may take a minute)..." -ForegroundColor Cyan
try {
    flutter build web | Out-Null
    Write-Host "[OK] Flutter build complete" -ForegroundColor Green
}
catch {
    Write-Host "[WARNING] Flutter build may have had issues" -ForegroundColor Yellow
}

Write-Host "[INFO] Starting web server..." -ForegroundColor Cyan
$webPath = Join-Path $frontendPath "build\web"
Start-ServiceWindow -Title "SmartPOS Frontend" -WorkingDirectory $webPath -Command "Write-Host 'Starting web server on http://127.0.0.1:8080' -ForegroundColor Cyan; python -m http.server 8080"

Write-Host "[INFO] Waiting for frontend to start..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Step 6: Display success message
Write-Host ""
Write-Host "[6/6] SmartPOS is starting up..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  =====================================================" -ForegroundColor Green
Write-Host "  |                                                   |" -ForegroundColor Green
Write-Host "  |                SmartPOS RUNNING                   |" -ForegroundColor Green
Write-Host "  |                                                   |" -ForegroundColor Green
Write-Host "  |  Backend API: http://127.0.0.1:8001              |" -ForegroundColor Green
Write-Host "  |  API Docs:    http://127.0.0.1:8001/docs         |" -ForegroundColor Green
Write-Host "  |  Frontend:    http://127.0.0.1:8080              |" -ForegroundColor Green
Write-Host "  |                                                   |" -ForegroundColor Green
Write-Host "  |  Check the opened terminal windows for logs       |" -ForegroundColor Green
Write-Host "  |                                                   |" -ForegroundColor Green
Write-Host "  =====================================================" -ForegroundColor Green
Write-Host ""

Write-Host "[INFO] Your browser should open automatically in a few seconds..." -ForegroundColor Cyan
Write-Host "[INFO] Close this window when you're done using SmartPOS" -ForegroundColor Cyan
Write-Host ""

# Wait and open browser
Start-Sleep -Seconds 5
Start-Process "http://127.0.0.1:8080"

Write-Host "Press any key to exit and stop SmartPOS..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Cleanup - Kill processes
Write-Host ""
Write-Host "[INFO] Stopping SmartPOS services..." -ForegroundColor Yellow
try {
    Get-Process -Name "flutter" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "[INFO] SmartPOS stopped." -ForegroundColor Green
}
catch {
    Write-Host "[INFO] Some processes may still be running. Please close the terminal windows manually." -ForegroundColor Yellow
}

Start-Sleep -Seconds 2