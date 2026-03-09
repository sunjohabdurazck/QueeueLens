# QueeueLens — Feature Reference

> Complete inventory of every implemented feature across the student app, admin dashboard, AI layer, and infrastructure.

---

## Table of Contents

- [Student App](#student-app)
  - [Authentication & Onboarding](#authentication--onboarding)
  - [App Navigation & Structure](#app-navigation--structure)
  - [Service Discovery](#service-discovery)
  - [Queue Management](#queue-management)
  - [AI-Powered Intelligence](#ai-powered-intelligence)
  - [Notifications](#notifications)
  - [Geofencing & Presence](#geofencing--presence)
  - [Campus Map & Navigation](#campus-map--navigation)
  - [Surveillance & Camera Viewer](#surveillance--camera-viewer)
- [Admin Dashboard (PHP v6)](#admin-dashboard-php-v6)
  - [Authentication & Access Control](#authentication--access-control)
  - [Live Queue Management](#live-queue-management)
  - [Service Management](#service-management)
  - [User & Role Management](#user--role-management)
  - [Camera Management](#camera-management)
  - [Analytics & Reporting](#analytics--reporting)
  - [Alerts Centre](#alerts-centre)
  - [Audit & Security](#audit--security)
- [Platform & Infrastructure](#platform--infrastructure)

---

## Student App

### Authentication & Onboarding

| Feature | Description |
|---|---|
| Email / password registration | Standard Firebase Auth signup with client-side and server-side validation |
| QR-assisted onboarding | Scan student ID card QR to auto-fill name, student ID, department, and nationality |
| Email verification gate | New accounts are blocked from queue features until email is verified |
| Resend verification email | Users can trigger a new verification email from the app |
| Login | Email + password login with Firebase Auth |
| Forgot password | Password reset email sent via Firebase Auth |
| Change password | In-profile password update with current-password confirmation |
| Profile picture upload | Pick from gallery or camera; stored in Firebase Storage |
| Logout | Full session teardown including local cache invalidation |
| Role-based routing | Students and admins are routed to separate experiences on login |

---

### App Navigation & Structure

| Feature | Description |
|---|---|
| Bottom tab navigation | Five tabs: Map · Services · Home · My Queue · More |
| Notification badge | Unread notification count overlaid on the notification icon |
| QR scan shortcut | Global floating shortcut to open the QR scanner from any tab |
| Profile shortcut | Quick access to student profile from the home header |
| Light / dark / system themes | User-selectable theme with persistence via `shared_preferences` |

---

### Service Discovery

| Feature | Description |
|---|---|
| Real-time service list | All campus service points with live Firestore subscription |
| Search services | Text search filtering the service list in real time |
| Filter open services only | Toggle to hide closed service points |
| Service detail page | Full detail view for each service point |
| Live counters per service | `pendingCount`, `activeCount`, estimated wait, avg minutes/person, last updated timestamp |
| Open / closed status badge | Colour-coded badge showing current service availability |

---

### Queue Management

| Feature | Description |
|---|---|
| Join queue via QR scan | Scan service QR code to enrol; anti-replay token validation prevents duplicate scans |
| One-user-one-queue enforcement | Enforced at Firestore security rule level — students cannot be in two queues simultaneously |
| Queue entry lifecycle | Full state machine: `pending → called → active → served / left / expired` |
| My Queue page | Dedicated screen showing current position, status, and wait estimate |
| Live queue position | Real-time position recalculation on every queue change |
| Estimated wait range | Min/max wait prediction displayed with confidence bounds |
| "You're next" awareness | Visual and notification alert when position reaches ≤ 3 |
| Check-in flow | Student confirms presence after being called; initiates countdown window |
| Countdown timer display | Visible timer showing remaining check-in window after being called |
| Leave queue | Voluntary queue exit with immediate counter recalculation |
| Auto-expire called entries | Entries not checked-in within the call window are automatically expired |
| Queue repair on counters | `syncServiceState` reconciler re-derives all counts from actual entry documents |
| 60-second re-join cooldown | Prevents immediate re-join after being served; enforced via Firestore security rule |
| Test-mode QR generation | Dev/test mode allows generating valid queue QR codes without physical posters |

---

### AI-Powered Intelligence

| Feature | Description |
|---|---|
| Wait-time prediction | Rolling-average model using last N serve-time logs per service; produces min/max range |
| Time-of-day bucketing | Prediction scoring accounts for time-of-day patterns (morning rush vs quiet periods) |
| Confidence interval | Statistical confidence bounds applied to the wait range display |
| Best service recommendation | Scores nearby services by predicted wait + walking distance; surfaces the best alternative |
| Recommendation card UI | Inline card with one-tap action to switch to recommended service |
| Turn-coming-soon detection | Fires proactively when predicted turn arrival is imminent |
| Wait-time increase detection | Alerts user when predicted wait increases by more than 20% |
| Better nearby service detection | Periodic background check (every 5 min) for lower-wait alternatives within 200 m |
| Anomaly detection | Detects spam joins/leaves, unusually long active entries, and queue depth spikes |
| Anomaly dashboard | Filterable list of detected anomalies with severity indicators |
| Virtual campus view | 3D-style campus painter overlaid with live queue depth indicators per service |
| Queue intelligence listener | Singleton coordinator managing heartbeat, predictions, turn alerts, geofence, and recommendations |

---

### Notifications

| Feature | Description |
|---|---|
| In-app notification inbox | Persistent inbox with all received notifications |
| Mark one read | Tap to mark a single notification as read |
| Mark all read | Bulk read action; badge count resets to zero |
| Push notifications (FCM) | Firebase Cloud Messaging delivers notifications even when app is backgrounded |
| Local notifications | Scheduled on-device notifications for time-sensitive events |
| Android notification channels | Separate channels for queue alerts, AI alerts, and geofence alerts (user-controllable) |
| Web notification fallback | Service Worker registration for partial push support on web browsers |
| Joined queue | Confirmation notification on successful queue enrolment |
| Turn coming soon | Alert when position reaches ≤ 3 |
| Called / check-in prompt | Immediate alert when admin calls the student's entry |
| Served confirmation | Notification when entry is marked served |
| Inactivity warning | Alert when heartbeat gap approaches the auto-expire threshold |
| Queue expired | Notification when entry is auto-expired |
| Wait time increased | AI alert when predicted wait increases significantly |
| Better service nearby | AI alert when a lower-wait alternative is detected |
| Left service area | Geofence EXIT event notification |
| Returned to service area | Geofence ENTER event notification |
| Confirm still active | Presence confirmation prompt when geofence warns of absence |

---

### Geofencing & Presence

| Feature | Description |
|---|---|
| Per-queue geofence | Individual geofence started and stopped for each active queue entry |
| Radius-based monitoring | Configurable radius around each service point's GPS coordinates |
| Android foreground service | Persistent foreground service with notification to survive Android battery optimisation |
| Background geofence | Continues monitoring when app is backgrounded or screen is off |
| Heartbeat writes | Firestore heartbeat write every 60 seconds for active queue participants |
| Inactivity watchdog | Triggers auto-expiry if heartbeat stops for more than 5 minutes |
| Auto-expire on absence | Entry transitioned to `expired` via Cloud Function if geofence exit is unresolved |
| Semantic leave reasons | Six reason codes: `called_no_show`, `active_abandoned`, `pending_left`, `admin_removed`, `repair_cleanup`, `inactivity_timeout` |

---

### Campus Map & Navigation

| Feature | Description |
|---|---|
| Interactive campus map | OpenStreetMap tiles via `flutter_map` |
| Live user location | Real-time GPS location with accuracy indicator |
| Location permission handling | Graceful permission request flow with fallback for denied permissions |
| Campus place markers | All service points rendered as tappable markers |
| Search campus locations | Text search for campus buildings and service points |
| Place detail sheets | Bottom sheet with service info, queue depth, and wait estimate on marker tap |
| Route to selected place | Tap a service to get walking route from current location |
| Turn-by-turn steps | Step-by-step walking directions with distance per step |
| Distance + duration display | Total walking distance and estimated time displayed on route |
| Clear route | One-tap route dismissal |
| Camera-to-user-location | Button to re-centre map on current location |
| Campus boundary check | Detects if user is outside campus; shows graceful fallback |
| Compass-assisted 3D view | Virtual campus orientation using device compass heading |

---

### Surveillance & Camera Viewer

| Feature | Description |
|---|---|
| Camera list | Browse all registered campus cameras |
| Camera live view | Full-screen MJPEG / RTSP / HTTP stream viewer |
| Stream loading indicator | Spinner with 10-second timeout and retry button on slow connections |
| Camera info panel | Name, location, last heartbeat, and stream URL metadata |
| Refresh stream | Manual stream refresh button |
| People counting badge | Real-time count badge derived from ML detection results |
| Detection bounding boxes | On-feed overlay of detected person bounding boxes |
| TFLite inference (Android) | SSD MobileNet v2 running natively via `tflite_flutter` |
| TensorFlow.js inference (Web) | Same model running via TF.js bridge for web platform |
| Camera type support | IP Webcam · RTSP · MJPEG · HTTP image stream |

---

## Admin Dashboard (PHP v6)

### Authentication & Access Control

| Feature | Description |
|---|---|
| Firebase REST auth | Admin login via Firebase Auth REST API with JWT verification |
| Session fingerprinting | IP + User-Agent hash validated on every request to detect session hijacking |
| Role-based routing | `student` / `staff` / `admin` roles enforced server-side |
| Permission whitelist | Arbitrary client-sent permission keys are rejected; server validates against known keys |
| Secure session cookies | `httponly`, `SameSite: Strict`, HTTPS-aware cookie configuration |
| Env-var-only secrets | Firebase credentials loaded from environment variables; no keys inside web root |

---

### Live Queue Management

| Feature | Description |
|---|---|
| Live queue view | Real-time queue board per service with all entry statuses |
| Service selector | Switch between service points in the queue view |
| Multi-column board | Columns: Pending · Called · Active · Served · Expired |
| Call head | Transitions front pending entry to `called`; starts expiry countdown |
| Recall head | Re-calls an entry that was missed |
| Check in called | Moves `called` entry to `active` |
| Mark served | Closes active entry as `served` |
| Mark left | Admin marks entry as left with reason |
| Expire called | Expires a `called` entry after window closes |
| Force expire | Immediate admin override expiry with reason code |
| Purge entry | Hard-delete an entry (requires `canPurgeEntry` permission) |
| Repair queue | Runs `syncServiceState` reconciler to fix counter drift |
| Call expiry countdown | Live countdown showing remaining check-in window |
| Per-entry action buttons | Contextual actions shown per entry based on its current status |

---

### Service Management

| Feature | Description |
|---|---|
| Services page | List of all registered service points with status |
| Create service | Add new service point with location, capacity, and queue settings |
| Update service | Edit name, location, call window, max pending, accepting flag |
| Delete service | Remove a service and its configuration |
| Open service | Set service to accepting new queue entries |
| Close service | Stop new entries; existing entries are preserved |
| Pause / unpause service | Temporarily suspend calling without closing |
| Queue settings | Configurable: call window seconds, max pending, location name, accepting new entries |
| Per-service overview modal | Quick-view stats modal without leaving the services list |
| Reset counts | Force-reset service counters via API |

---

### User & Role Management

| Feature | Description |
|---|---|
| Staff & users page | List of all platform users with role and status |
| Role assignment | Set user role: `student`, `staff`, or `admin` |
| Activate / deactivate | Toggle `isActive` flag; inactive users cannot log in |
| Assign services to staff | Map staff members to specific service points |
| Permission editing | Set granular permission flags per user |
| Permission keys | `canRepairQueue` · `canPurgeEntry` · `canManageUsers` · `canManageCameras` · `canManageServices` · `canExportAudit` · `canOperateAllServices` |

---

### Camera Management

| Feature | Description |
|---|---|
| Cameras page | List of all registered cameras with health status |
| Add camera | Register new IP camera with stream URL and GPS coordinates |
| Delete camera | Remove camera registration |
| Activate / deactivate | Toggle camera active state |
| Assign camera to service | Link camera to a specific service point |
| Stream URL storage | Supports IP Webcam · RTSP · MJPEG · HTTP stream types |
| Location metadata | GPS lat/lng stored per camera |
| Online / offline health | Heartbeat-based online status (last ping < threshold = online) |
| Camera stats summary | Total · Online · Offline counts at a glance |
| 3D campus map overlay | Visual campus map showing camera positions and coverage |

---

### Analytics & Reporting

| Feature | Description |
|---|---|
| Analytics page | Dedicated analytics dashboard |
| Total served metrics | Cumulative and period-filtered serve counts per service |
| Live queue depth | Current pending + active counts across all services |
| Open vs closed services | At-a-glance service availability summary |
| Camera online ratio | Percentage of cameras currently reporting a heartbeat |
| Service performance ranking | Services ranked by throughput, average wait, and serve time |
| Serve time trends | Historical chart of average serve duration over time |
| Queue depth history | Time-series chart of queue depth for capacity planning |
| Audit log summaries | Aggregate views of admin actions by type and actor |
| Export audit log | CSV/JSON export of the full audit log (requires `canExportAudit`) |

---

### Alerts Centre

| Feature | Description |
|---|---|
| Expired call alerts | Service has a called entry whose window has elapsed |
| No-staff-assigned alerts | Service is open with no staff member assigned |
| Closed-with-pending alerts | Service is closed but still has pending entries |
| Missing queue head alerts | Service counters indicate a head entry but none is found |
| High active-count alerts | Unusually high number of simultaneously active entries |
| Large queue alerts | Pending count exceeds configured threshold |
| Camera offline alerts | Camera has not sent a heartbeat within the expected window |
| Quick-fix actions | Each alert type exposes one-click resolution actions inline |

---

### Audit & Security

| Feature | Description |
|---|---|
| Audit logging | Every admin action recorded with actor UID, action type, target, timestamp, and metadata |
| Immutable log | Audit entries are append-only; no update or delete endpoints |
| CSRF protection | Token-based CSRF validation on all state-changing requests |
| IP / User-Agent fingerprinting | Session validated against initial IP + UA hash on every request |
| Permission-based access | Server-side permission check before every sensitive action |
| Env-var secrets | `FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_API_KEY` loaded from environment only |

---

## Platform & Infrastructure

| Area | Detail |
|---|---|
| Flutter platforms | Android · Web (iOS-ready, pending provisioning) |
| Admin platform | PHP 8.1+, Apache / Nginx, Composer |
| Realtime database | Cloud Firestore (NoSQL, real-time listeners) |
| Authentication | Firebase Auth (email + password) |
| Push notifications | Firebase Cloud Messaging + `flutter_local_notifications` |
| File storage | Firebase Storage (profile pictures, assets) |
| Background processing | Android foreground service for geofence + heartbeat |
| State management | Riverpod 2 (Flutter) + PHP session (admin) |
| Dependency injection | GetIt (Flutter) |
| Routing | `go_router` (Flutter) |
| Maps | `flutter_map` with OpenStreetMap tiles |
| ML inference | TFLite (Android) + TensorFlow.js (Web) — SSD MobileNet v2 |
| Local persistence | Hive + `shared_preferences` |
| Version control | Git + GitHub (feature-branch workflow, PR reviews) |

---

*Last updated: March 2026 — QueeueLens v1.0.0*
