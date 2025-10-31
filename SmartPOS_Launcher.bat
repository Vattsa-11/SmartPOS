@echo off
title SmartPOS Launcher
color 0A

echo.
echo  =====================================================
echo  ^|                                                   ^|
echo  ^|               SmartPOS Launcher                   ^|
echo  ^|            One-Click Startup Script               ^|
echo  ^|                                                   ^|
echo  =====================================================
echo.

:: Define paths - Update these if your paths are different
set "PROJECT_ROOT=%~dp0"
set "BACKEND_PATH=%PROJECT_ROOT%smartpos\backend"
set "FRONTEND_PATH=%PROJECT_ROOT%smartpos\frontend"

echo [INFO] Project root: %PROJECT_ROOT%
echo [INFO] Backend path: %BACKEND_PATH%
echo [INFO] Frontend path: %FRONTEND_PATH%
echo.

:: Check prerequisites
echo [1/6] Checking prerequisites...

:: Check Python
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python is not installed or not in PATH!
    echo [INFO] Please install Python 3.8+ from https://python.org
    pause
    exit /b 1
)
echo [OK] Python is installed

:: Check Flutter
flutter --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter is not installed or not in PATH!
    echo [INFO] Please install Flutter from https://flutter.dev
    pause
    exit /b 1
)
echo [OK] Flutter is installed

:: Check directories
if not exist "%BACKEND_PATH%" (
    echo [ERROR] Backend directory not found!
    echo [INFO] Expected: %BACKEND_PATH%
    pause
    exit /b 1
)
echo [OK] Backend directory found

if not exist "%FRONTEND_PATH%" (
    echo [ERROR] Frontend directory not found!
    echo [INFO] Expected: %FRONTEND_PATH%
    pause
    exit /b 1
)
echo [OK] Frontend directory found

echo.
echo [2/6] Installing backend dependencies...
cd /d "%BACKEND_PATH%"
if not exist "requirements.txt" (
    echo [WARNING] requirements.txt not found in backend directory
) else (
    pip install -r requirements.txt >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo [OK] Backend dependencies installed
    ) else (
        echo [WARNING] Some backend dependencies may have failed to install
    )
)

echo.
echo [3/6] Installing frontend dependencies...
cd /d "%FRONTEND_PATH%"
flutter pub get >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Frontend dependencies installed
) else (
    echo [WARNING] Frontend dependencies installation had issues
)

echo.
echo [4/6] Starting backend server...
cd /d "%BACKEND_PATH%"
start "SmartPOS Backend API" cmd.exe /k "title SmartPOS Backend ^& echo Starting backend server on http://127.0.0.1:8001 ^& python -m uvicorn simple_fastapi:app --host 0.0.0.0 --port 8001 --reload"

echo [INFO] Waiting for backend to initialize...
timeout /t 8 /nobreak >nul

echo.
echo [5/6] Building and starting frontend application...
cd /d "%FRONTEND_PATH%"
echo [INFO] Building Flutter web app (this may take a minute)...
flutter build web >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Flutter build complete
) else (
    echo [WARNING] Flutter build may have had issues
)

echo [INFO] Starting web server...
cd /d "%FRONTEND_PATH%\build\web"
start "SmartPOS Frontend" cmd.exe /k "title SmartPOS Frontend ^& echo Starting web server on http://127.0.0.1:8080 ^& python -m http.server 8080"

echo [INFO] Waiting for frontend to start...
timeout /t 10 /nobreak >nul

echo.
echo [6/6] SmartPOS is starting up...
echo.
echo  =====================================================
echo  ^|                                                   ^|
echo  ^|                SmartPOS RUNNING                   ^|
echo  ^|                                                   ^|
echo  ^|  Backend API: http://127.0.0.1:8001              ^|
echo  ^|  API Docs:    http://127.0.0.1:8001/docs         ^|
echo  ^|  Frontend:    http://127.0.0.1:8080              ^|
echo  ^|                                                   ^|
echo  ^|  Check the opened terminal windows for logs       ^|
echo  ^|                                                   ^|
echo  =====================================================
echo.
echo [INFO] Your browser should open automatically in a few seconds...
echo [INFO] Close this window when you're done using SmartPOS
echo.

:: Wait for 5 seconds then try to open browser
timeout /t 5 /nobreak >nul
start http://127.0.0.1:8080

echo Press any key to exit and stop SmartPOS...
pause >nul

:: Cleanup - Kill the processes
echo.
echo [INFO] Stopping SmartPOS services...
taskkill /f /fi "WINDOWTITLE eq SmartPOS Backend*" >nul 2>&1
taskkill /f /fi "WINDOWTITLE eq SmartPOS Frontend*" >nul 2>&1
echo [INFO] SmartPOS stopped.
timeout /t 2 /nobreak >nul