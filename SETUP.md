# QueueLens Admin v6 — Setup Guide

## Prerequisites

- PHP 8.1+
- Composer
- Apache or Nginx with PHP
- A Firebase project (Firestore + Authentication enabled)

---

## Step 1 — Place Files

Copy the `queuelens-admin-v6/` folder to your web root:

```
/var/www/html/queuelens/        ← Linux/Apache
C:\xampp\htdocs\queuelens\      ← Windows/XAMPP
```

---

## Step 2 — Install Dependencies

```bash
cd /var/www/html/queuelens
composer install --no-dev
```

---

## Step 3 — Configure Environment Variables (Required)

**Never place `serviceAccountKey.json` inside the web root.**

Set these in your Apache vhost, Nginx config, or `/etc/environment`:

```apache
# Apache vhost example
SetEnv FIREBASE_PROJECT_ID       your-project-id
SetEnv FIREBASE_SERVICE_ACCOUNT  /etc/queuelens/serviceAccountKey.json
SetEnv FIREBASE_API_KEY          AIzaSy...
SetEnv FIREBASE_AUTH_DOMAIN      your-project.firebaseapp.com
```

```nginx
# Nginx + PHP-FPM: add to fastcgi_params
fastcgi_param FIREBASE_PROJECT_ID      your-project-id;
fastcgi_param FIREBASE_SERVICE_ACCOUNT /etc/queuelens/serviceAccountKey.json;
fastcgi_param FIREBASE_API_KEY         AIzaSy...;
fastcgi_param FIREBASE_AUTH_DOMAIN     your-project.firebaseapp.com;
```

### Getting the values:

| Variable | Where to find it |
|---|---|
| `FIREBASE_PROJECT_ID` | Firebase Console → Project Settings → General |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase Console → Project Settings → Service Accounts → Generate Key. **Save outside web root.** |
| `FIREBASE_API_KEY` | Firebase Console → Project Settings → General → Web API Key |
| `FIREBASE_AUTH_DOMAIN` | Firebase Console → Project Settings → General → `yourproject.firebaseapp.com` |

---

## Step 4 — Firebase Client Config

Copy and fill in `config/firebase_client.json.example`:

```bash
cp config/firebase_client.json.example config/firebase_client.json
# Edit config/firebase_client.json with your public Firebase web values
```

This file contains **public** values only (no private key). It is safe to store in the project, but is already in `.gitignore` so you can customize freely.

---

## Step 5 — Create Admin User in Firestore

In Firebase Console → Firestore Database → `users` collection:

Add a document where **Document ID = your Firebase Auth UID**:

```json
{
  "role": "admin",
  "name": "Your Name",
  "email": "your@email.com",
  "isActive": true
}
```

Your Firebase Auth UID can be found in Authentication → Users tab.

---

## Step 6 — Test Login

Visit: `http://localhost/queuelens/`

Sign in with your Firebase email and password.

---

## Security Checklist Before Production

- [ ] `serviceAccountKey.json` is **outside** the web root
- [ ] Environment variables set in web server config (not in PHP files)
- [ ] `config/firebase_client.json` is populated (public values only)
- [ ] `.htaccess` is active (prevents direct access to `config/`, `services/`)
- [ ] `display_errors` is `Off` in `php.ini`
- [ ] HTTPS is enabled
- [ ] Only staff/admin Firebase accounts exist in `users` collection with correct role field
