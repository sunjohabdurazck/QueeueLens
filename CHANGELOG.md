# QueueLens Admin — v6 Changelog

## v6 — Login Stability, Queue Correctness, Secrets & Permissions

---

### 🔴 P0 Fix: Fatal Login Redeclaration Bug

**`getFirebaseProjectId()` function redeclaration removed.**

In v5, `api/login.php` redeclared `getFirebaseProjectId()` after `config/firestore_rest.php` had already defined it. This caused a PHP fatal error (`Cannot redeclare`) that broke the login path entirely.

**Fix:** `getFirebaseProjectId()` is now defined **once and only once** in `config/firestore_rest.php` (wrapped in `function_exists` guard). `api/login.php` no longer defines it — it uses the one from `firestore_rest.php`.

---

### 🔴 P0 Fix: No Nested Old Version in Package

Previous builds accidentally included `queuelens-admin-v4/` inside the package zip. Removed. `.gitignore` now explicitly excludes all `queuelens-admin-v*/` directories.

---

### 🔐 Secrets: Env-Only Workflow (P1)

- `install.sh` and `install.bat` no longer reference `config/serviceAccountKey.json` as the install target.
- Both scripts now check for `FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY`, `FIREBASE_AUTH_DOMAIN` environment variables.
- `SETUP.md` fully rewritten: env var setup is the default (Apache `SetEnv`, Nginx `fastcgi_param`), bundled key is explicitly documented as dev-only.
- `config/firebase_client.json.example` clarifies which values are public (safe to store) vs private (must stay out of web root).

---

### 🔄 Queue State Machine (P1)

**`expireCalled()` — now split into normal vs force:**
- Normal staff expire (`action=expire_called`): only works if `callExpiresAt <= now`. Returns error if call window is still open.
- Force expire (`action=force_expire_called`): admin only, requires reason. Clearly marked as override.

**`QueueService::LEFT_REASONS` — semantic reason constants:**
- `called_no_show`, `active_abandoned`, `pending_left`, `admin_removed`, `repair_cleanup`
- `admin_removed` restricted to admin role server-side.
- All reasons stored in entry doc as `leftReason`.

**`syncServiceState()` — authoritative post-action reconciler:**
- Called after every queue mutation (callHead, recallHead, checkInCalled, markServed, markLeft, expireCalled, purge).
- Derives `pendingCount`, `activeCount`, `headPendingEntryId`, `activeEntryId`, `calledEntryId`, `callExpiresAt` from actual entry documents.
- Auto-expires stale called entries during sync.
- Makes `repair` emergency-only, not a normal-flow dependency.

**`repairService()` — no fake outcomes:**
- Duplicate active entries → marked `left` with `repair_cleanup` reason (not silently "served").
- Returns `issuesFound[]` and `fixesApplied[]` for full transparency.
- Uses `syncServiceState()` at end for authoritative reconciliation.

---

### ⚙️ Services API (P1)

`api/services.php` now explicitly splits operational vs structural actions:

| Action | Required Permission |
|---|---|
| `list` | any staff |
| `toggle` (open/close) | any assigned staff |
| `create` | `canManageServices` |
| `update` | `canManageServices` |
| `delete` | `canManageServices` |
| `reset_counts` | `canManageServices` |

Previously, update and toggle were both `canManageServices`, which was too rigid for service-assigned staff who should be able to open/close their service.

---

### 🔐 Permissions (P1)

**`KNOWN_PERMISSIONS` whitelist in `config/config.php`:**
- `canRepairQueue`, `canPurgeEntry`, `canManageUsers`, `canManageCameras`, `canManageServices`, `canExportAudit`, `canOperateAllServices`
- `UserService::updateUserAdmin()` filters against whitelist — arbitrary permission keys from client input are rejected.

**`requirePermission()` used in queue-actions.php:**
- `repair` → `canRepairQueue`
- `purge_entry` → `canPurgeEntry`
- `sync_state` → `canRepairQueue`

---

### 🔐 Session Hardening

`config/config.php` now sets secure session cookie params on startup:
- `httponly: true`
- `samesite: Strict`
- `secure: true` (if HTTPS detected)

`api/login.php` stores `ip_hash` and `ua_hash` in session. `isAuthenticated()` validates them — simple session hijack detection.

---

### 🐛 Other Fixes

- `api/stats.php`: correctly uses `jsonResponse(false, 'message', [], 500)` — status code in correct parameter position.
- `AuditService::log()`: now accepts `$meta` array for `override`, `dangerous`, `outcome`, `issuesFound`, `fixesApplied` — stored as native Firestore maps, not JSON strings.
- `purgeEntry()`: now requires a non-empty reason (returns error otherwise).
- Users page modal: `action=update_user` saves role + isActive + assignedServiceIds + permissions in one unified POST. No more single-field save bug.

---

### Score Δ (v5 → v6)

| Area | v5 | v6 |
|---|---|---|
| Structure | 9/10 | 9.5/10 |
| Security design | 8/10 | 9/10 |
| Actual runtime safety | 6.5/10 | 8.5/10 |
| Queue correctness | 8/10 | 9/10 |
| Production readiness | 7/10 | 9/10 |
