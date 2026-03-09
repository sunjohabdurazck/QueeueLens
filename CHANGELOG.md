# Changelog

All notable changes to QueeueLens are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] — 2026-03-10

> **First public release.** Full-stack campus queue management with AI intelligence, geofencing, surveillance, and a PHP admin dashboard.

### Flutter App

#### Added — Authentication & Onboarding
- Email + password registration with Firebase Auth
- QR-code-assisted onboarding: scan student ID to auto-fill profile fields
- Email verification gate blocking queue features until verified
- Resend verification email flow
- Forgot password via Firebase Auth email reset
- Change password from student profile
- Profile picture upload to Firebase Storage
- Role-based post-login routing (student vs admin experience)

#### Added — Queue Management
- Browse campus service points with real-time Firestore subscription
- Join queue by scanning service QR code (anti-replay token validation)
- One-user-one-queue enforcement at Firestore security rule level
- Full queue entry lifecycle: `pending → called → active → served / left / expired`
- My Queue screen with live position and estimated wait range (min/max)
- "You're next" alert when position reaches ≤ 3
- Check-in flow with visible countdown timer after being called
- Voluntary queue exit with immediate counter recalculation
- Auto-expire of called entries after configurable window
- 60-second re-join cooldown after being served

#### Added — AI Intelligence
- On-device wait-time prediction using rolling average of serve-time logs
- Time-of-day bucketing for more accurate predictions during peak/off-peak hours
- Min/max confidence interval applied to wait estimates
- Best service recommender: scores nearby services by predicted wait + walking distance
- Recommendation card UI with one-tap action to switch services
- Turn-coming-soon proactive detection (fires before position reaches ≤ 3)
- Wait-time increase detection: alerts when predicted wait grows by > 20%
- Better nearby service background check every 5 minutes within 200 m radius
- Anomaly detection for spam joins/leaves, long-active entries, queue depth spikes
- Anomaly dashboard with severity filtering
- Virtual campus painter with live queue depth overlays per service
- `QueueIntelligenceListener` singleton coordinating all background AI tasks

#### Added — Geofencing & Presence
- Per-queue geofence started and stopped with each active entry
- Android foreground service with persistent notification for reliable background operation
- Heartbeat Firestore write every 60 seconds for active participants
- Inactivity watchdog: auto-expires entry after 5-minute heartbeat gap
- Auto-expire via Cloud Function on unresolved geofence EXIT
- Six semantic leave reason codes: `called_no_show`, `active_abandoned`, `pending_left`, `admin_removed`, `repair_cleanup`, `inactivity_timeout`

#### Added — Notifications
- Firebase Cloud Messaging push notifications (background + terminated app)
- `flutter_local_notifications` for on-device scheduled alerts
- Android notification channels: queue alerts · AI alerts · geofence alerts
- Web Service Worker registration for partial browser push support
- In-app notification inbox with mark-one-read and mark-all-read
- Notification types: joined, turn-coming-soon, called, served, inactivity warning, expired, wait increased, better service nearby, geofence left/returned/confirm-active

#### Added — Campus Map
- Interactive OpenStreetMap via `flutter_map`
- Live GPS location with accuracy ring
- All service points as tappable map markers
- Service search on the map view
- Bottom sheet with queue info on marker tap
- Walking route with turn-by-turn steps, distance, and ETA
- Campus boundary check with graceful fallback for off-campus users
- Re-centre camera button
- Compass-assisted 3D virtual campus orientation

#### Added — Surveillance
- MJPEG / RTSP / HTTP stream viewer (full-screen)
- TFLite SSD MobileNet v2 person detection on Android
- TensorFlow.js SSD MobileNet v2 inference on Web
- Bounding box overlay on live camera feed
- People count badge updated from ML inference
- Stream loading indicator, 10-second timeout, and retry button
- Camera list with heartbeat-based online/offline status

---

### Admin Dashboard (PHP v6)

#### Added — Foundation
- Firebase Auth REST API login with JWT verification
- Session fingerprinting: IP + User-Agent hash validated on every request
- Env-var-only secrets workflow (`FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_API_KEY`)
- `httponly`, `SameSite: Strict`, HTTPS-aware session cookies
- Permission whitelist: arbitrary client permission keys rejected server-side
- Role-scoped endpoints: `staff` can toggle queues; only `admin` can create/update/delete services

#### Added — Queue Operations
- Real-time multi-column queue board: Pending · Called · Active · Served · Expired
- Call head, recall, check-in called, mark served, mark left, expire called, force expire, purge entry
- Per-entry action buttons rendered based on current entry status
- Live call-expiry countdown per called entry
- Queue Repair: runs `syncServiceState` reconciler to fix counter drift without data loss
- `syncServiceState` authoritative reconciler: re-derives all counters from actual entry documents

#### Added — Service Management
- Create, update, delete service points
- Open, close, pause, unpause service
- Configurable settings per service: call window seconds, max pending, location name, accepting flag
- Per-service overview modal
- Reset counts API endpoint

#### Added — User & Permission Management
- User list with role and active status
- Role assignment: `student` / `staff` / `admin`
- Activate / deactivate accounts
- Assign staff to specific services
- Granular permission editing: `canRepairQueue`, `canPurgeEntry`, `canManageUsers`, `canManageCameras`, `canManageServices`, `canExportAudit`, `canOperateAllServices`

#### Added — Camera Management
- Register, delete, activate/deactivate cameras
- Assign cameras to service points
- Stream URL storage (IP Webcam · RTSP · MJPEG · HTTP)
- GPS coordinates per camera
- Heartbeat-based online/offline health
- 3D campus map overlay of camera positions

#### Added — Analytics & Alerts
- Service throughput charts and serve time trends
- Queue depth history for capacity planning
- Camera online ratio
- Service performance ranking
- Alerts centre: expired calls, no staff, closed-with-pending, missing head, high active, large queue, camera offline
- Quick-fix actions inline with each alert type
- Audit log with export (`canExportAudit`)

---

### Infrastructure

#### Added
- Firestore data model: `services/{serviceId}/entries/{entryId}`, `users`, `cameras`, `serve_time_logs`, `audit_log`
- Cloud Function `syncServiceState` reconciler triggered after every queue mutation
- Firestore security rules enforcing one-active-queue-per-student and re-join cooldown
- GitHub Actions CI: `flutter analyze` + unit tests on every pull request
- Feature-branch workflow with mandatory PR reviews

#### Fixed
- Fatal PHP login redeclaration bug (`Cannot redeclare` error on repeated includes)

---

## [0.5.0-beta] — 2026-02-15

> Sprint 5 integration build — release hardening and virtual campus.

### Changed
- Dynamic service rendering with live queue depth indicators on virtual campus
- Staff QR scan-to-active validation hardened against replay and double-scan edge cases
- Final UI polish: empty states, error handling, and edge case screens across all features

### Fixed
- `pendingCount` not correctly decremented after voluntary queue leave
- Android geofence not triggering on Android 13 due to missing background location permission
- Admin Repair Queue incorrectly resetting position to 0 for `active` entries
- Map routing error when user is outside campus boundary

---

## [0.4.0-beta] — 2026-02-03

> Sprint 4 build — AI intelligence layer and geofencing.

### Added
- Serve time logging to Firestore for use in prediction models
- Wait-time prediction with rolling average and confidence interval
- Anomaly detection and anomaly dashboard
- Best service recommender with distance scoring
- Recommender card UI and action flow
- Android foreground geofence service for Android 13 compatibility
- Heartbeat writer and inactivity auto-expire via Cloud Function
- Semantic leave reasons introduced

### Fixed
- Queue counter desync under concurrent joins resolved with Firestore transactions
- 60-second re-join cooldown added after being marked served

---

## [0.3.0-beta] — 2026-01-11

> Sprint 3 build — queue core and campus map.

### Added
- Complete queue lifecycle: Mark Served, Leave Queue, auto-expire
- QR code generated per entry; staff scan-to-active flow
- Real-time My Queue sync
- Campus map with service markers, routing, and walking directions
- `syncServiceState` reconciler introduced for counter integrity
- Queue Repair admin tool

### Fixed
- `pendingCount` and `activeCount` logic corrected
- QR scanner freezing on second scan (controller lifecycle fix)
- Campus boundary check with fallback to nearest entry point

---

## [0.2.0-alpha] — 2025-12-16

> Sprint 2 build — Firebase integration and real-time queue.

### Added
- Firebase Authentication replacing mock auth
- Firestore student profile schema and persistence
- Queue creation and join flow with real-time Firestore subscription
- Admin dashboard base screens
- Service list UI with queue card components
- Join confirmation and success UX

---

## [0.1.0-alpha] — 2025-12-02

> Sprint 1 build — authentication and foundational scaffolding.

### Added
- Email/password authentication with validation rules
- Role-based access control for student and admin
- Live QR scanner with camera integration
- Student data parsing and validation
- Login, signup, email verification, and forgot-password screens
- Shared widget library, theme system, and local storage setup

---

*For the complete feature inventory see [FEATURES.md](FEATURES.md).*  
*For installation instructions see [SETUP.md](SETUP.md).*
