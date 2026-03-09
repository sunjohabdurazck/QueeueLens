# QueeueLens — Setup Guide

> Step-by-step instructions for getting the Flutter app and PHP admin dashboard running locally and in production.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [1. Clone the Repository](#1-clone-the-repository)
- [2. Firebase Project Setup](#2-firebase-project-setup)
- [3. Flutter App Setup](#3-flutter-app-setup)
  - [3.1 Install Dependencies](#31-install-dependencies)
  - [3.2 Configure Firebase](#32-configure-firebase)
  - [3.3 Add ML Model Assets](#33-add-ml-model-assets)
  - [3.4 Firestore Security Rules](#34-firestore-security-rules)
  - [3.5 Run the App](#35-run-the-app)
- [4. Admin Dashboard Setup (PHP)](#4-admin-dashboard-setup-php)
  - [4.1 Copy Files to Web Root](#41-copy-files-to-web-root)
  - [4.2 Install PHP Dependencies](#42-install-php-dependencies)
  - [4.3 Set Environment Variables](#43-set-environment-variables)
  - [4.4 Configure Firebase Client](#44-configure-firebase-client)
  - [4.5 Create the First Admin User](#45-create-the-first-admin-user)
  - [4.6 Open the Dashboard](#46-open-the-dashboard)
- [5. Firestore Initial Data](#5-firestore-initial-data)
- [6. Production Checklist](#6-production-checklist)
- [7. Troubleshooting](#7-troubleshooting)

---

## Prerequisites

| Tool | Version | Required For |
|---|---|---|
| Flutter SDK | `>=3.x` | Mobile + web app |
| Dart SDK | `>=3.11` | Bundled with Flutter |
| Android Studio / Xcode | Latest stable | Android / iOS builds |
| PHP | `8.1+` | Admin dashboard |
| Composer | Latest | Admin PHP dependencies |
| Apache or Nginx | Any modern | Admin dashboard hosting |
| Firebase project | — | All backend services |
| Google Maps API key | — | Campus map feature |

> **iOS Note:** The Flutter app is iOS-compatible but requires an Apple Developer Programme enrolment to provision and deploy. All other targets work without a paid account.

---

## 1. Clone the Repository

```bash
git clone https://github.com/sunjohabdurazck/QueeueLens.git
cd QueeueLens
```

---

## 2. Firebase Project Setup

All backend services — Firestore, Auth, Storage, Messaging — run on a single Firebase project.

1. Go to [Firebase Console](https://console.firebase.google.com) → **Add project**
2. Enable the following services:
   - **Authentication** → Sign-in method → Email/Password ✓
   - **Cloud Firestore** → Create database (production mode recommended)
   - **Firebase Storage** → Default bucket
   - **Firebase Cloud Messaging** → No extra config required
3. Register your apps:
   - **Android app** — use your app's `applicationId` (e.g. `com.example.queueulens`)
   - **Web app** — for the Flutter web build and admin dashboard
4. Download credentials:
   - `google-services.json` → Android app
   - `GoogleService-Info.plist` → iOS app
   - **Service Account key** (JSON) → Admin dashboard only (keep outside web root)

> The service account key is for the **admin dashboard only**. The Flutter app uses the Firebase SDK directly and does not need it.

---

## 3. Flutter App Setup

### 3.1 Install Dependencies

```bash
flutter pub get
```

### 3.2 Configure Firebase

**Android:**

```bash
# Place the file at:
android/app/google-services.json
```

**iOS:**

```bash
# Place the file at:
ios/Runner/GoogleService-Info.plist
```

**Web / Firebase Options:**

Open `lib/firebase_options.dart` and update it with your project values from Firebase Console → Project Settings → Your apps → Web app → SDK snippet:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_PROJECT.firebaseapp.com',
  storageBucket: 'YOUR_PROJECT.appspot.com',
);
```

You can also use the FlutterFire CLI to regenerate this file automatically:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

**Google Maps (campus map feature):**

Add your Maps API key to:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_MAPS_API_KEY"/>
```

```dart
// web/index.html — inside <head>
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_MAPS_API_KEY"></script>
```

### 3.3 Add ML Model Assets

The person detection feature requires TFLite model files. Place them at the paths defined in `pubspec.yaml`:

```
assets/
  models/
    android/
      ssd_mobilenet_v2.tflite
    web/
      ssd_mobilenet_v2.tflite
  images/
    # any app image assets
```

> The SSD MobileNet v2 model can be downloaded from the [TensorFlow Model Garden](https://github.com/tensorflow/models/blob/master/research/object_detection/g3doc/tf2_detection_zoo.md) or [Kaggle Models](https://www.kaggle.com/models). Use the `.tflite` variant for Android and the `.json` + weights shards for web.

### 3.4 Firestore Security Rules

Deploy the security rules from the repository:

```bash
firebase deploy --only firestore:rules
```

Key rules enforced:
- Students can only read/write their own queue entries
- One active queue entry per user enforced server-side
- 60-second re-join cooldown after `served` status
- Admin role required for all service management operations

### 3.5 Run the App

```bash
# Android (connected device or emulator)
flutter run

# Web
flutter run -d chrome

# Release build (Android)
flutter build apk --release

# Release build (Web)
flutter build web --release
```

---

## 4. Admin Dashboard Setup (PHP)

The admin dashboard is a PHP 8.1+ application located in the `Admin/` directory.

### 4.1 Copy Files to Web Root

**Linux (Apache):**

```bash
cp -r Admin/ /var/www/html/queuelens/
```

**Windows (XAMPP):**

```
Copy Admin/ → C:\xampp\htdocs\queuelens\
```

**Using a subdomain (recommended for production):**

Point your virtual host document root directly to `Admin/`:

```apache
<VirtualHost *:443>
    ServerName admin.queuelens.yourdomain.com
    DocumentRoot /var/www/queuelens/Admin
</VirtualHost>
```

### 4.2 Install PHP Dependencies

```bash
cd /var/www/html/queuelens
composer install --no-dev --optimize-autoloader
```

### 4.3 Set Environment Variables

**Never place credentials inside the web root.** Set them as server environment variables:

**Apache virtual host:**

```apache
SetEnv FIREBASE_PROJECT_ID        your-project-id
SetEnv FIREBASE_SERVICE_ACCOUNT   /etc/queuelens/serviceAccountKey.json
SetEnv FIREBASE_API_KEY           AIzaSy...
SetEnv FIREBASE_AUTH_DOMAIN       your-project.firebaseapp.com
```

**Nginx (fastcgi_params or site config):**

```nginx
fastcgi_param FIREBASE_PROJECT_ID       your-project-id;
fastcgi_param FIREBASE_SERVICE_ACCOUNT  /etc/queuelens/serviceAccountKey.json;
fastcgi_param FIREBASE_API_KEY          AIzaSy...;
fastcgi_param FIREBASE_AUTH_DOMAIN      your-project.firebaseapp.com;
```

**Linux `.env` file (if your setup uses dotenv):**

```bash
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_SERVICE_ACCOUNT=/etc/queuelens/serviceAccountKey.json
FIREBASE_API_KEY=AIzaSy...
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
```

> Store `serviceAccountKey.json` **outside** the web root (e.g. `/etc/queuelens/`). The path you set in `FIREBASE_SERVICE_ACCOUNT` must be readable by the web server process.

### 4.4 Configure Firebase Client

The dashboard also needs your public Firebase web config (safe to expose — these are public values):

```bash
cp Admin/config/firebase_client.json.example Admin/config/firebase_client.json
```

Edit `firebase_client.json`:

```json
{
  "apiKey": "AIzaSy...",
  "authDomain": "your-project.firebaseapp.com",
  "projectId": "your-project-id",
  "storageBucket": "your-project.appspot.com",
  "messagingSenderId": "000000000000",
  "appId": "1:000000000000:web:abc123"
}
```

### 4.5 Create the First Admin User

Admin users must exist in both **Firebase Authentication** and **Firestore**.

1. In Firebase Console → Authentication → Users → **Add user** — create an account with an email and password for the first admin.

2. Copy the resulting **UID** (shown in the Users table).

3. In Firestore → `users` collection → **Add document** — set the **Document ID** to that UID:

```json
{
  "role": "admin",
  "name": "Admin Name",
  "email": "admin@example.com",
  "isActive": true,
  "assignedServiceIds": [],
  "permissions": {
    "canManageServices": true,
    "canManageUsers": true,
    "canManageCameras": true,
    "canRepairQueue": true,
    "canPurgeEntry": true,
    "canExportAudit": true,
    "canOperateAllServices": true
  }
}
```

### 4.6 Open the Dashboard

```
http://localhost/queuelens/
```

Or your configured domain/subdomain. Log in with the Firebase email and password created in step 4.5.

---

## 5. Firestore Initial Data

To seed the database with your campus service points, add documents to the `services` collection in Firestore Console:

```json
{
  "name": "Registrar's Office",
  "description": "Academic document collection and certification",
  "location": "Admin Building, Ground Floor",
  "isOpen": true,
  "pendingCount": 0,
  "activeCount": 0,
  "lat": 23.9565,
  "lng": 90.4062,
  "callWindowSeconds": 300,
  "maxPending": 50,
  "acceptingNewEntries": true,
  "headPendingEntryId": null,
  "activeEntryId": null,
  "calledEntryId": null,
  "callExpiresAt": null
}
```

Repeat for each service point (Library, Medical Centre, Cafeteria, etc.). The Flutter app will display them automatically.

---

## 6. Production Checklist

```
Security
[ ] serviceAccountKey.json is stored OUTSIDE the web root
[ ] All Firebase credentials are set via environment variables, not hardcoded
[ ] firebase_client.json contains public values only (no service account)
[ ] .htaccess is active — blocks direct access to config/ and services/ directories
[ ] display_errors = Off in php.ini
[ ] HTTPS is enforced (redirect HTTP → HTTPS)
[ ] Only staff/admin accounts exist in the Firestore users collection with correct roles

Firebase
[ ] Firestore security rules deployed (firebase deploy --only firestore:rules)
[ ] Firebase Storage rules restrict uploads to authenticated users only
[ ] FCM server key is not exposed in any client-side code

Flutter
[ ] google-services.json and GoogleService-Info.plist are in .gitignore
[ ] Firebase options do not contain service account credentials
[ ] Maps API key is restricted to your app's package name / bundle ID / referrer

Admin Dashboard
[ ] Composer autoloader is optimised (--optimize-autoloader)
[ ] PHP error logging is directed to a file, not stdout
[ ] Session cookie is httponly and SameSite: Strict
[ ] Apache/Nginx config blocks access to .env, composer.json, and *.json config files
```

---

## 7. Troubleshooting

**Flutter: `google-services.json` not found**  
Ensure it is placed at `android/app/google-services.json` (not at the project root).

**Flutter: Maps not loading on Android**  
Check that your Maps API key in `AndroidManifest.xml` has the *Maps SDK for Android* enabled in Google Cloud Console.

**Flutter: Geofence not triggering on Android 13+**  
Android 13 requires `ACCESS_BACKGROUND_LOCATION` permission separately. The app requests it during the queue join flow, but the user must explicitly grant "Allow all the time" in device settings if denied once.

**Admin: Blank page after login**  
Check PHP error logs (`/var/log/apache2/error.log` or `/var/log/nginx/error.log`). Common causes: missing environment variables, wrong path to `serviceAccountKey.json`, or Composer `vendor/` directory not present.

**Admin: `Cannot redeclare` PHP error**  
This was fixed in Admin v6. Ensure you are running the latest version from the `main` branch. Pull the latest and clear any opcode cache (`opcache_reset()` or restart PHP-FPM).

**Admin: Session keeps expiring**  
Session fingerprinting validates IP + User-Agent on every request. If your server sits behind a load balancer or proxy that rotates the client IP, configure the proxy to pass `X-Forwarded-For` and update the fingerprint logic in `Admin/config/session.php` accordingly.

**Firestore: Queue counters show wrong numbers**  
Use the **Repair Queue** button in the admin dashboard for the affected service. This runs `syncServiceState` which re-derives all counters from the actual entry documents without any data loss.

**Firestore: `PERMISSION_DENIED` errors in Flutter**  
Confirm that the Firestore security rules have been deployed. Run `firebase deploy --only firestore:rules` from the project root. Check that the logged-in user's `role` field exists in the `users` Firestore document matching their UID.

---

*See [FEATURES.md](FEATURES.md) for the complete feature inventory.*  
*See [CHANGELOG.md](CHANGELOG.md) for the full version history.*
