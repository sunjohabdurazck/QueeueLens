#!/bin/bash

echo "============================================"
echo " Queue Master Admin System - Quick Setup"
echo "============================================"
echo ""

# Check PHP
echo "[1/5] Checking PHP installation..."
if ! command -v php &> /dev/null; then
    echo "❌ ERROR: PHP is not installed"
    echo "Please install PHP 7.4+ from https://www.php.net/"
    exit 1
fi
echo "✓ PHP is installed ($(php -v | head -n 1))"

# Check Composer
echo ""
echo "[2/5] Checking Composer installation..."
if ! command -v composer &> /dev/null; then
    echo "❌ ERROR: Composer is not installed"
    echo "Please install Composer from https://getcomposer.org/"
    exit 1
fi
echo "✓ Composer is installed"

# Install dependencies
echo ""
echo "[3/5] Installing PHP dependencies..."
composer install
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to install dependencies"
    exit 1
fi
echo "✓ Dependencies installed"

# Check Firebase config
echo ""
echo "[4/5] Checking Firebase configuration..."
if [ ! -f "config/serviceAccountKey.json" ]; then
    echo "⚠️  WARNING: Firebase service account key not found!"
    echo ""
    echo "Please follow these steps:"
    echo "1. Go to Firebase Console: https://console.firebase.google.com/"
    echo "2. Select your project"
    echo "3. Go to Project Settings > Service Accounts"
    echo "4. Click 'Generate New Private Key'"
    echo "5. Save the JSON file as: config/serviceAccountKey.json"
    echo ""
    read -p "Press ENTER when you've added the file..."
    
    if [ ! -f "config/serviceAccountKey.json" ]; then
        echo "❌ ERROR: Service account key still not found!"
        exit 1
    fi
fi
echo "✓ Firebase configuration found"

# Check Apache/Web Server
echo ""
echo "[5/5] Checking web server..."
if command -v apachectl &> /dev/null; then
    if pgrep httpd > /dev/null || pgrep apache2 > /dev/null; then
        echo "✓ Apache is running"
    else
        echo "⚠️  WARNING: Apache is not running"
        echo "Please start Apache/XAMPP"
    fi
else
    echo "⚠️  WARNING: Apache not detected"
    echo "Make sure your web server is running"
fi

echo ""
echo "============================================"
echo " Setup Complete! 🎉"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Make sure Apache/web server is running"
echo "2. Create admin user in Firebase Console:"
echo "   - Collection: users"
echo "   - Document ID: [your Firebase Auth UID]"
echo "   - Fields: { role: \"admin\", name: \"Your Name\", email: \"your@email.com\" }"
echo ""
echo "3. Visit: http://localhost/queuelens/"
echo "4. Login with your Firebase credentials"
echo ""
echo "Documentation:"
echo "- Quick Start: GETTING_STARTED.md"
echo "- Full Guide: README.md"
echo "- Setup Help: SETUP.md"
echo ""
echo "Opening browser..."

# Try to open browser
if command -v xdg-open &> /dev/null; then
    xdg-open "http://localhost/admin_system/"
elif command -v open &> /dev/null; then
    open "http://localhost/admin_system/"
fi

echo ""
echo "Enjoy your magnificent admin system! 🚀"
