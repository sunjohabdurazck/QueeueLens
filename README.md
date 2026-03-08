# QueeueLens

> **Smart campus queue management with real-time AI, surveillance, and geofencing — built for IUT**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.11-0175C2?logo=dart)](https://dart.dev)
[![PHP](https://img.shields.io/badge/PHP-8.1%2B-777BB4?logo=php)](https://php.net)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%2B%20Auth-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Private-red)](.)
[![Version](https://img.shields.io/badge/Version-1.0.0-green)](.)

---

## Overview

**QueeueLens** is a full-stack campus queue management platform designed for IUT students and staff. It combines a cross-platform Flutter mobile/web app with a PHP admin dashboard — all backed by Firebase Firestore in real time.

Students join queues by scanning QR codes, track their position live, and receive intelligent wait time predictions. Staff manage the queue from a web dashboard with granular role-based permissions. Surveillance cameras feed into an on-device ML pipeline that counts people and detects crowd anomalies, while geofencing automatically notifies students as they approach a service point.

---

## Architecture

```
QueeueLens/
├── lib/                        # Flutter app (mobile + web)
│   ├── app/                    # App entry, routing, theming
│   ├── core/                   # Shared utilities, notifications, geofencing
│   ├── di/                     # Dependency injection (GetIt)
│   ├── features/
│   │   ├── ai/                 # Wait prediction, anomaly detection, recommendations
│   │   ├── queue/              # Queue state machine, intelligence listeners
│   │   ├── services/           # QR scanning, queue joining, live position tracking
│   │   └── surveillance/       # Camera feeds, TFLite person detection (Android + Web)
│   ├── map/                    # Campus map, directions, location services
│   └── src/                    # Auth, student profile, shared widgets
└── Admin/                      # PHP web dashboard (v6)
    ├── api/                    # REST endpoints (queue, cameras, services, auth)
    ├── config/                 # Firebase connection, session security, permissions
    ├── pages/                  # Dashboard UI (queue, analytics, cameras, logs, users)
    └── services/               # QueueService, UserService, AuditService
```

The Flutter app follows **clean architecture** per feature (data → domain → presentation), using Riverpod for state management and GetIt for dependency injection. The admin panel is a PHP MVC application authenticating via Firebase REST API with server-side session fingerprinting.

---

## Features

### Student App (Flutter — Android, iOS, Web)

**Queue Management**
- Browse available campus service points
- Join queues by scanning a QR code
- Real-time queue position with live countdown
- Push notifications and in-app inbox for call alerts
- Leave or re-join queues at any time

**AI-Powered Wait Intelligence**
- On-device wait time prediction based on historical serve-time logs
- Best service recommendation (shortest predicted wait nearby)
- Anomaly detection for unusual queue spikes
- Time-bucketed scoring that accounts for time-of-day patterns

**Campus Navigation**
- Interactive campus map (OpenStreetMap via `flutter_map`)
- Turn-by-turn walking directions to service points
- Geofence-triggered notifications as you approach a service location
- Compass-assisted 3D virtual campus view

**Surveillance Viewer**
- Live MJPEG camera stream viewer
- Real-time person detection overlaid on feed (bounding boxes + count badge)
- TFLite SSD MobileNet v2 model — runs natively on Android and via TensorFlow.js on web

**Authentication**
- Firebase Auth (email + password)
- QR-code-assisted registration flow
- Email verification gate
- Password reset

---

### Admin Dashboard (PHP — Web)

**Live Queue Management**
- Real-time queue view per service
- Call next, recall, check-in, mark served / left / no-show
- Force-expire called entries (admin only, with reason)
- Service open/close toggle

**Services & Staff**
- Create, update, delete service points
- Assign staff to specific services
- Per-service queue reset

**User & Role Management**
- Roles: `student`, `staff`, `admin`
- Granular permission flags: `canManageServices`, `canManageUsers`, `canManageCameras`, `canRepairQueue`, `canPurgeEntry`, `canExportAudit`, `canOperateAllServices`
- Active/inactive toggle, multi-service assignment

**Camera Management**
- Register and manage IP cameras
- View live feeds from dashboard
- 3D campus map overlay with camera positions

**Analytics & Audit**
- Service throughput charts
- Serve time trends and queue depth history
- Full audit log (staff actions, overrides, outcomes)

**Security (v6)**
- Session fingerprinting (IP + User-Agent hash validation)
- Env-var-only secrets — no keys inside the web root
- `httponly`, `SameSite: Strict`, HTTPS-aware session cookies
- Permission whitelist — arbitrary client-sent permission keys are rejected

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile / Web app | Flutter 3.x, Dart ≥ 3.11 |
| State management | Riverpod 2, flutter_bloc |
| Dependency injection | GetIt |
| Routing | go_router |
| Backend / realtime DB | Firebase Firestore |
| Authentication | Firebase Auth |
| Push notifications | Firebase Messaging + flutter_local_notifications |
| Maps | flutter_map (OpenStreetMap) + geolocator |
| Geofencing | flutter_background_service, custom GeofenceService |
| ML / Person detection | TFLite (Android) + TensorFlow.js (Web) — SSD MobileNet v2 |
| Camera streaming | mobile_scanner, camera, mjpeg_view |
| Local persistence | Hive, shared_preferences |
| Admin dashboard | PHP 8.1+, Composer |
| Admin auth | Firebase REST API + JWT (firebase/php-jwt) |
| Admin HTTP client | Guzzle 7 |

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.x` with Dart `>=3.11`
- A Firebase project with **Firestore** and **Authentication** enabled
- PHP `8.1+` and Composer (for the admin panel)
- Apache or Nginx

---

### 1. Clone the repository

```bash
git clone https://github.com/your-org/QueeueLens.git
cd QueeueLens
```

---

### 2. Flutter App Setup

**Install dependencies:**

```bash
flutter pub get
```

**Configure Firebase:**

1. Go to Firebase Console → Project Settings → Add App (Android / iOS / Web)
2. Download `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS)
3. Place them in the correct platform directories
4. The web config lives in `lib/firebase_options.dart` — update it with your project values

**Add assets:**

Place the TFLite model files at:
```
assets/models/android/ssd_mobilenet_v2.tflite
assets/models/web/ssd_mobilenet_v2.tflite
assets/images/          ← any app images
```

**Run:**

```bash
# Android / iOS
flutter run

# Web
flutter run -d chrome
```

---

### 3. Admin Dashboard Setup

**Copy files to your web root:**

```bash
# Linux / Apache
cp -r Admin/ /var/www/html/queuelens/

# Windows / XAMPP
# Copy Admin/ to C:\xampp\htdocs\queuelens\
```

**Install PHP dependencies:**

```bash
cd /var/www/html/queuelens
composer install --no-dev
```

**Set environment variables** (never put keys inside the web root):

```apache
# Apache vhost
SetEnv FIREBASE_PROJECT_ID       your-project-id
SetEnv FIREBASE_SERVICE_ACCOUNT  /etc/queuelens/serviceAccountKey.json
SetEnv FIREBASE_API_KEY          AIzaSy...
SetEnv FIREBASE_AUTH_DOMAIN      your-project.firebaseapp.com
```

```nginx
# Nginx + PHP-FPM (in fastcgi_params or site config)
fastcgi_param FIREBASE_PROJECT_ID      your-project-id;
fastcgi_param FIREBASE_SERVICE_ACCOUNT /etc/queuelens/serviceAccountKey.json;
fastcgi_param FIREBASE_API_KEY         AIzaSy...;
fastcgi_param FIREBASE_AUTH_DOMAIN     your-project.firebaseapp.com;
```

**Configure Firebase client (public values only):**

```bash
cp Admin/config/firebase_client.json.example Admin/config/firebase_client.json
# Edit firebase_client.json with your web app config values
```

**Create the first admin user in Firestore:**

In Firebase Console → Firestore → `users` collection, create a document where the **Document ID is your Firebase Auth UID**:

```json
{
  "role": "admin",
  "name": "Your Name",
  "email": "your@email.com",
  "isActive": true
}
```

**Visit the dashboard:**

```
http://localhost/queuelens/
```

---

### Production Security Checklist

- [ ] `serviceAccountKey.json` is stored **outside** the web root
- [ ] All secrets are set via environment variables, not hardcoded
- [ ] `config/firebase_client.json` contains public values only
- [ ] `.htaccess` is active (blocks direct access to `config/` and `services/`)
- [ ] `display_errors = Off` in `php.ini`
- [ ] HTTPS is enabled and enforced
- [ ] Only staff/admin Firebase accounts exist in the `users` collection with correct role fields

---

## Firestore Data Model

```
services/{serviceId}
  ├── name, description, location, isOpen
  ├── pendingCount, activeCount
  ├── headPendingEntryId, activeEntryId, calledEntryId
  └── callExpiresAt

services/{serviceId}/entries/{entryId}
  ├── userId, studentName, joinedAt
  ├── status: pending | called | active | served | left
  ├── calledAt, servedAt, leftReason
  └── position

users/{userId}
  ├── role: student | staff | admin
  ├── name, email, isActive
  ├── assignedServiceIds[]
  └── permissions: { canManageServices, canManageUsers, ... }

cameras/{cameraId}
  ├── name, streamUrl, location
  └── lat, lng

serve_time_logs/{logId}
  ├── serviceId, servedAt
  └── durationSeconds
```

---

## Queue State Machine

```
pending → called → active → served
                 ↓
              left (called_no_show, active_abandoned, admin_removed, ...)
```

- **callHead** — moves the front of the pending queue to `called`, starts the expiry window
- **checkInCalled** — student checks in during the call window → `active`
- **markServed** — staff marks active entry as `served`
- **expireCalled** — call window expired, entry becomes `left: called_no_show`
- **syncServiceState** — authoritative reconciler called after every mutation; re-derives all counters from actual entry documents

---

## Project Structure (Flutter)

```
lib/
├── app/
│   ├── app.dart                # MaterialApp + ProviderScope root
│   ├── routes.dart             # go_router route definitions
│   └── theme.dart              # Light/dark theme
├── core/
│   ├── constants/              # App strings, Firestore paths
│   ├── errors/                 # App exceptions, failure types
│   ├── geofencing/             # Background geofence service
│   ├── notifications/          # FCM, local notifications, inbox
│   └── widgets/                # Scaffold, error/loading/empty views
├── features/
│   ├── ai/
│   │   ├── core/               # Scoring algorithms, geo helpers, time buckets
│   │   ├── data/               # Local datasource, serve-time log models
│   │   ├── domain/             # WaitPrediction, Recommendation, Anomaly entities
│   │   └── presentation/       # AnomaliesPage, VirtualCampusViewPage, AI providers
│   ├── queue/
│   │   ├── application/        # QueueIntelligenceProvider, listener
│   │   └── domain/             # ExpireInactiveEntries use case
│   ├── services/
│   │   ├── data/               # Queue + service repositories, QR payload model
│   │   ├── domain/             # QueueEntry, ServicePoint entities + use cases
│   │   └── presentation/       # ServicesListPage, ServiceDetailsPage, MyQueuePage,
│   │                           # QrScannerPage, JoinQueueResultPage
│   └── surveillance/
│       ├── data/               # Camera model, repository
│       ├── domain/             # SurveillanceCamera, PersonDetection entities
│       ├── infrastructure/
│       │   ├── android/        # TFLite image preprocessing + postprocessing
│       │   └── web/            # TensorFlow.js bridge, web camera impl
│       └── presentation/       # SurveillanceScreen, CameraViewPage, detection overlay
├── map/
│   ├── map_screen.dart
│   ├── map_controller.dart
│   └── services/               # LocationService, DirectionsService, MapDataService
└── src/
    ├── screens/                # Login, Signup, Home, StudentProfile, EmailVerification
    ├── data/                   # Firebase auth + Firestore datasources
    └── domain/                 # Auth use cases (SignIn, SignUp, SignOut, ...)
```

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full version history. The current release is **Admin v6**, which introduced:

- Fatal login redeclaration bug fix (PHP `Cannot redeclare`)
- Env-var-only secrets workflow
- Full queue state machine with `syncServiceState` authoritative reconciler
- Role-scoped service actions (`toggle` vs `create/update/delete`)
- Permission whitelist with server-side input filtering
- Session fingerprinting for hijack detection

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: describe your change"`
4. Push and open a pull request

Please follow the existing clean-architecture patterns per feature module and keep business logic out of widgets.

---

## License

This project is private and proprietary. All rights reserved.
