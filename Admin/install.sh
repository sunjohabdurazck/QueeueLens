#!/bin/bash
# QueueLens Admin v6 — Setup Script (env-based secrets only)

echo "============================================"
echo " QueueLens Admin v6 — Setup"
echo "============================================"
echo ""

# Check PHP
echo "[1/4] Checking PHP..."
if ! command -v php &>/dev/null; then
    echo "❌ PHP not found. Install PHP 8.1+"
    exit 1
fi
echo "✓ PHP: $(php -v | head -n1)"

# Check Composer
echo ""
echo "[2/4] Checking Composer..."
if ! command -v composer &>/dev/null; then
    echo "❌ Composer not found. Install from https://getcomposer.org/"
    exit 1
fi
echo "✓ Composer: $(composer --version)"

# Install dependencies
echo ""
echo "[3/4] Installing PHP dependencies..."
composer install --no-dev --optimize-autoloader
if [ $? -ne 0 ]; then echo "❌ composer install failed"; exit 1; fi
echo "✓ Dependencies installed"

# Environment check
echo ""
echo "[4/4] Checking required environment variables..."

MISSING=0

check_env() {
    local VAR=$1
    local DESC=$2
    if [ -z "${!VAR}" ]; then
        echo "  ⚠️  Missing: $VAR — $DESC"
        MISSING=$((MISSING+1))
    else
        echo "  ✓ $VAR is set"
    fi
}

check_env "FIREBASE_PROJECT_ID"      "Your Firebase project ID (e.g. queuelens)"
check_env "FIREBASE_SERVICE_ACCOUNT" "Absolute path to service account JSON key (OUTSIDE web root)"
check_env "FIREBASE_API_KEY"         "Firebase Web API key (for client-side auth)"
check_env "FIREBASE_AUTH_DOMAIN"     "Firebase auth domain (e.g. queuelens.firebaseapp.com)"

if [ $MISSING -gt 0 ]; then
    echo ""
    echo "⚠️  Set the missing environment variables before running."
    echo ""
    echo "Recommended: add to /etc/environment or your web server vhost config:"
    echo ""
    echo "  SetEnv FIREBASE_PROJECT_ID       your-project-id"
    echo "  SetEnv FIREBASE_SERVICE_ACCOUNT  /etc/queuelens/serviceAccountKey.json"
    echo "  SetEnv FIREBASE_API_KEY          AIza..."
    echo "  SetEnv FIREBASE_AUTH_DOMAIN      your-project.firebaseapp.com"
    echo ""
    echo "⚠️  NEVER place serviceAccountKey.json inside the web root or app folder."
    echo ""
else
    echo ""
    echo "✓ All environment variables set"
fi

echo ""
echo "============================================"
echo " Setup complete!"
echo "============================================"
echo ""
echo "Next: verify a staff/admin user exists in Firestore:"
echo "  Collection: users"
echo "  Document ID: [Firebase Auth UID]"
echo "  Fields: { role: 'admin', name: 'Name', email: 'email', isActive: true }"
echo ""
echo "Visit: http://localhost/queuelens/"
