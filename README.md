# QueeueLens

> **Smart campus queue management with real-time AI, surveillance, and geofencing — built for IUT**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.11-0175C2?logo=dart)](https://dart.dev)
[![PHP](https://img.shields.io/badge/PHP-8.1%2B-777BB4?logo=php)](https://php.net)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%2B%20Auth-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Private-red)](.)
[![Version](https://img.shields.io/badge/Version-1.0.0-green)](.)

---

## Live Deployments

| Platform | URL |
|---|---|
| 🌐 Flutter Web App (student-facing) | [sunjohabdurazck.github.io/QueeueLens](https://sunjohabdurazck.github.io/QueeueLens/) |
| 🖥️ Admin Dashboard | [queuelens.ct.ws](https://queuelens.ct.ws/) |
| 💻 Source Code | [github.com/sunjohabdurazck/QueeueLens](https://github.com/sunjohabdurazck/QueeueLens) |

---

## Overview

**QueeueLens** is a full-stack campus queue management platform built for IUT students and staff. It combines a cross-platform Flutter mobile and web app with a PHP admin dashboard, all backed by Firebase Firestore in real time.

Students join queues by scanning QR codes, track their position live, and receive intelligent wait-time predictions. Staff manage queues from a web dashboard with granular role-based permissions. Surveillance cameras feed into an on-device ML pipeline that counts people and detects crowd anomalies, while geofencing automatically monitors student presence and handles queue expiry.

---

## Documentation

| Document | Description |
|---|---|
| [SETUP.md](SETUP.md) | Full installation guide for the Flutter app and PHP admin dashboard |
| [FEATURES.md](FEATURES.md) | Complete inventory of every implemented feature |
| [CHANGELOG.md](CHANGELOG.md) | Full version history with per-sprint release notes |

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
│   │   ├── queue/              # Queue state machine, intelligence listener
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

The Flutter app follows **clean architecture** per feature (data → domain → presentation), using Riverpod for reactive state and GetIt for dependency injection. The admin panel is a PHP MVC application authenticating via the Firebase REST API with server-side session fingerprinting.

---

## Features

### Student App (Flutter — Android, iOS, Web)

**Queue Management**
- Browse campus service points with live queue counters
- Join queues by scanning a service QR code (anti-replay token validation)
- Real-time queue position with live wait-time range (min / max)
- Full entry lifecycle: `pending → called → active → served / left / expired`
- Push notifications and in-app inbox for all queue events
- Leave or re-join queues at any time

**AI-Powered Wait Intelligence**
- On-device wait-time prediction based on historical serve-time logs
- Time-of-day bucketing for peak vs off-peak accuracy
- Best service recommendation: shortest predicted wait + walking distance
- Proactive turn-coming-soon and wait-increase alerts
- Anomaly detection for unusual queue spikes and suspicious activity
- Virtual campus painter with live queue depth overlays

**Campus Navigation**
- Interactive map (OpenStreetMap via `flutter_map`)
- Turn-by-turn walking directions to any service point
- Geofence-triggered presence monitoring with inactivity auto-expire
- Compass-assisted 3D virtual campus view

**Surveillance Viewer**
- Live MJPEG / RTSP / HTTP camera stream viewer
- Real-time person detection overlaid on feed (bounding boxes + count badge)
- TFLite SSD MobileNet v2 on Android; TensorFlow.js on Web

**Authentication**
- Firebase Auth (email + password) with email verification gate
- QR-code-assisted registration — scan student ID to auto-fill profile
- Password reset and in-profile password change

---

### Admin Dashboard (PHP v6 — Web)

**Live Queue Management**
- Real-time multi-column queue board: Pending · Called · Active · Served · Expired
- Call next, recall, check-in, mark served / left / no-show, force-expire
- Queue Repair: `syncServiceState` reconciler fixes counter drift without data loss
- Live call-expiry countdown per called entry

**Services & Staff**
- Create, update, delete, open, close, and pause service points
- Configurable per-service settings: call window, max pending, accepting flag
- Assign staff to specific services

**User & Role Management**
- Roles: `student` · `staff` · `admin`
- Granular permissions: `canManageServices`, `canManageUsers`, `canManageCameras`, `canRepairQueue`, `canPurgeEntry`, `canExportAudit`, `canOperateAllServices`
- Active / inactive toggle and multi-service assignment

**Camera Management**
- Register and manage IP cameras (MJPEG · RTSP · HTTP)
- View live feeds from the dashboard
- Heartbeat-based online/offline health indicators
- 3D campus map overlay with camera positions

**Analytics & Alerts**
- Service throughput charts, serve time trends, queue depth history
- Alerts centre: expired calls, no staff, closed-with-pending, large queue, camera offline
- Quick-fix actions inline with each alert type
- Full audit log with CSV/JSON export

**Security (v6)**
- Session fingerprinting (IP + User-Agent hash validation on every request)
- Env-var-only secrets — no credentials inside the web root
- `httponly`, `SameSite: Strict`, HTTPS-aware session cookies
- Permission whitelist — arbitrary client-sent permission keys are rejected server-side

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

## Quick Start

See **[SETUP.md](SETUP.md)** for the full installation guide. In brief:

**Flutter app:**
```bash
git clone https://github.com/sunjohabdurazck/QueeueLens.git
cd QueeueLens
flutter pub get
# Add google-services.json and update lib/firebase_options.dart
flutter run
```

**Admin dashboard:**
```bash
cp -r Admin/ /var/www/html/queuelens/
cd /var/www/html/queuelens
composer install --no-dev
# Set FIREBASE_PROJECT_ID, FIREBASE_SERVICE_ACCOUNT, FIREBASE_API_KEY env vars
# Create first admin user in Firestore — see SETUP.md §4.5
```

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
              left (called_no_show | active_abandoned | admin_removed | ...)
```

- **callHead** — moves the front pending entry to `called`; starts the call expiry window
- **checkInCalled** — student checks in during the call window → `active`
- **markServed** — staff marks the active entry as `served`
- **expireCalled** — call window elapsed; entry becomes `left: called_no_show`
- **syncServiceState** — authoritative reconciler called after every mutation; re-derives all counters from actual entry documents

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: describe your change"`
4. Push and open a pull request

Follow the existing clean-architecture patterns per feature module. Keep business logic out of widgets and presentation layer out of repositories.

---

## License

This project is private and proprietary. All rights reserved.

---

*[SETUP.md](SETUP.md) · [FEATURES.md](FEATURES.md) · [CHANGELOG.md](CHANGELOG.md)*
