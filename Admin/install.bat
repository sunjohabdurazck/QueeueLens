@echo off
echo ============================================
echo  QueueLens Admin System - Quick Setup
echo ============================================
echo.

echo [1/5] Checking PHP installation...
php --version > nul 2>&1
if errorlevel 1 (
    echo ERROR: PHP is not installed or not in PATH
    echo Please install XAMPP from https://www.apachefriends.org/
    pause
    exit /b 1
)
echo ✓ PHP is installed

echo.
echo [2/5] Checking Composer installation...
composer --version > nul 2>&1
if errorlevel 1 (
    echo ERROR: Composer is not installed
    echo Please install Composer from https://getcomposer.org/
    pause
    exit /b 1
)
echo ✓ Composer is installed

echo.
echo [3/5] Installing PHP dependencies...
composer install
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)
echo ✓ Dependencies installed

echo.
echo [4/5] Checking Firebase configuration...
if not exist "config\serviceAccountKey.json" (
    echo WARNING: Firebase service account key not found!
    echo.
    echo Please follow these steps:
    echo 1. Go to Firebase Console: https://console.firebase.google.com/
    echo 2. Select your project
    echo 3. Go to Project Settings ^> Service Accounts
    echo 4. Click "Generate New Private Key"
    echo 5. Save the JSON file as: config\serviceAccountKey.json
    echo.
    echo Press any key when you've added the file...
    pause > nul
    
    if not exist "config\serviceAccountKey.json" (
        echo ERROR: Service account key still not found!
        pause
        exit /b 1
    )
)
echo ✓ Firebase configuration found

echo.
echo [5/5] Checking XAMPP Apache...
tasklist /FI "IMAGENAME eq httpd.exe" 2>NUL | find /I /N "httpd.exe">NUL
if errorlevel 1 (
    echo WARNING: Apache is not running
    echo Please start Apache from XAMPP Control Panel
    echo.
) else (
    echo ✓ Apache is running
)

echo.
echo ============================================
echo  Setup Complete! 🎉
echo ============================================
echo.
echo Next steps:
echo 1. Make sure Apache is running in XAMPP
echo 2. Create admin user in Firebase Console:
echo    - Collection: users
echo    - Document ID: [your Firebase Auth UID]
echo    - Fields: { role: "admin", name: "Your Name", email: "your@email.com" }
echo.
echo 3. Visit: http://localhost/queuelens/
echo 4. Login with your Firebase credentials
echo.
echo Documentation:
echo - Quick Start: GETTING_STARTED.md
echo - Full Guide: README.md
echo - Setup Help: SETUP.md
echo.
echo Press any key to open the system in your browser...
pause > nul

start http://localhost/queuelens/

echo.
echo Enjoy your magnificent admin system! 🚀
pause
