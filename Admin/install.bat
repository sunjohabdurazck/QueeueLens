@echo off
REM QueueLens Admin v6 - Windows Setup

echo ============================================
echo  QueueLens Admin v6 - Setup
echo ============================================
echo.

where php >nul 2>&1 || (echo PHP not found. Install PHP 8.1+ && exit /b 1)
where composer >nul 2>&1 || (echo Composer not found. Install from https://getcomposer.org && exit /b 1)

echo Installing PHP dependencies...
composer install --no-dev --optimize-autoloader
if errorlevel 1 (echo composer install failed && exit /b 1)

echo.
echo ============================================
echo  Setup complete!
echo ============================================
echo.
echo IMPORTANT: Set these environment variables in IIS or Apache vhost:
echo   FIREBASE_PROJECT_ID       your-project-id
echo   FIREBASE_SERVICE_ACCOUNT  C:\keys\serviceAccountKey.json (outside web root)
echo   FIREBASE_API_KEY          AIza...
echo   FIREBASE_AUTH_DOMAIN      your-project.firebaseapp.com
echo.
echo NEVER place serviceAccountKey.json inside htdocs or the app folder.
