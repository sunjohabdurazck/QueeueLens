<?php
// config/config.php — v6: auth, roles, permissions, service access
ini_set('display_errors', 0); error_reporting(0);

if (session_status() === PHP_SESSION_NONE) {
    session_set_cookie_params([
        'lifetime' => 0,
        'path'     => '/',
        'secure'   => isset($_SERVER['HTTPS']),
        'httponly' => true,
        'samesite' => 'Strict',
    ]);
    session_start();
}

define('APP_NAME',       'QueueLens Admin');
define('BASE_PATH',      '/queuelens');
define('BASE_URL',       'http://localhost' . BASE_PATH);
define('SESSION_TIMEOUT', 60 * 60 * 6); // 6 hours

define('ROLE_STUDENT', 'student');
define('ROLE_STAFF',   'staff');
define('ROLE_ADMIN',   'admin');

// =========================================================
// REDIRECT
// =========================================================
function redirectTo(string $path): void {
    $url = rtrim(BASE_PATH, '/') . '/' . ltrim($path, '/');
    header("Location: $url");
    exit;
}

// =========================================================
// AUTHENTICATION
// =========================================================
function isAuthenticated(): bool {
    if (!isset($_SESSION['user_id'], $_SESSION['user_role'], $_SESSION['last_activity'])) {
        return false;
    }
    if ((time() - (int)$_SESSION['last_activity']) > SESSION_TIMEOUT) {
        return false;
    }
    // Session fingerprint check (detect simple hijack attempts)
    $ipHash = hash('sha256', $_SERVER['REMOTE_ADDR'] ?? '');
    $uaHash = hash('sha256', $_SERVER['HTTP_USER_AGENT'] ?? '');
    if (isset($_SESSION['ip_hash']) && $_SESSION['ip_hash'] !== $ipHash) return false;
    if (isset($_SESSION['ua_hash']) && $_SESSION['ua_hash'] !== $uaHash) return false;
    return true;
}

function requireAuth(): void {
    if (!isAuthenticated()) {
        session_unset(); session_destroy();
        redirectTo('login.php');
    }
    $_SESSION['last_activity'] = time();
}

function requireRole(string $requiredRole): void {
    requireAuth();
    $role = userRole();
    if ($requiredRole === ROLE_STAFF) {
        if (!in_array($role, [ROLE_STAFF, ROLE_ADMIN], true)) {
            redirectTo('login.php?error=forbidden');
        }
        return;
    }
    if ($requiredRole === ROLE_ADMIN) {
        if ($role !== ROLE_ADMIN) redirectTo('login.php?error=forbidden');
        return;
    }
    if ($role !== strtolower($requiredRole)) redirectTo('login.php?error=forbidden');
}

function currentUser(): array {
    return [
        'id'    => $_SESSION['user_id']    ?? null,
        'name'  => $_SESSION['user_name']  ?? null,
        'email' => $_SESSION['user_email'] ?? null,
        'role'  => $_SESSION['user_role']  ?? null,
    ];
}

function userRole(): string {
    return strtolower(trim((string)($_SESSION['user_role'] ?? '')));
}

function hasRole(string $role): bool {
    $current = userRole();
    if (strtolower($role) === ROLE_STAFF) {
        return in_array($current, [ROLE_STAFF, ROLE_ADMIN], true);
    }
    return $current === strtolower($role);
}

function isAdmin(): bool { return userRole() === ROLE_ADMIN; }
function isStaff(): bool { return hasRole(ROLE_STAFF); }

// =========================================================
// SERVICE-LEVEL ACCESS
// =========================================================

/**
 * Current user's assigned service IDs (from session, set on login).
 * Empty array = all services allowed (for backward compat and new staff).
 */
function assignedServiceIds(): array {
    return (array)($_SESSION['assigned_service_ids'] ?? []);
}

/**
 * Returns true if user can operate the given serviceId.
 * Admin: always. Staff: must be in assignments, or assignments empty (= all).
 */
function canManageService(string $serviceId): bool {
    if (isAdmin()) return true;
    $assigned = assignedServiceIds();
    return empty($assigned) || in_array($serviceId, $assigned, true);
}

/**
 * JSON-abort if user cannot manage this service. Use in API endpoints.
 */
function requireServiceAccess(string $serviceId): void {
    if (!canManageService($serviceId)) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'Access denied: service not in your assignments']);
        exit;
    }
}

// =========================================================
// GRANULAR PERMISSIONS
// Known permission keys (whitelist — reject unknowns)
// =========================================================
const KNOWN_PERMISSIONS = [
    'canRepairQueue',
    'canPurgeEntry',
    'canManageUsers',
    'canManageCameras',
    'canManageServices',
    'canExportAudit',
    'canOperateAllServices',
];

/**
 * Check a granular permission. Admin always has all.
 */
function hasPermission(string $perm): bool {
    if (isAdmin()) return true;
    $perms = (array)($_SESSION['permissions'] ?? []);
    return !empty($perms[$perm]);
}

/**
 * JSON-abort if user lacks a permission. Use in API endpoints.
 */
function requirePermission(string $perm): void {
    if (!hasPermission($perm)) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => "Access denied: missing permission '$perm'"]);
        exit;
    }
}

// =========================================================
// CSRF PROTECTION
// =========================================================
if (!function_exists('generateCSRFToken')) {
    function generateCSRFToken(): string {
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }
}

if (!function_exists('verifyCSRFToken')) {
    function verifyCSRFToken(string $token): bool {
        return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
    }
}

// =========================================================
// CSRF for JSON API endpoints
// =========================================================
function requireCSRF(): void {
    $token = $_POST['csrf_token'] ?? ($_SERVER['HTTP_X_CSRF_TOKEN'] ?? '');
    if (!verifyCSRFToken($token)) {
        http_response_code(403);
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => 'Invalid CSRF token']);
        exit;
    }
}

// =========================================================
// ERROR MESSAGES
// =========================================================
function errorMessageFromQuery(): ?string {
    return match ($_GET['error'] ?? null) {
        'missing_token'  => 'Authentication failed: no token received from browser.',
        'invalid_token'  => 'Authentication failed: token invalid or expired. Please try again.',
        'no_user'        => 'No staff account found. Contact your system administrator.',
        'forbidden'      => 'Access denied. Your account may be deactivated or lacks staff/admin role.',
        'server_error'   => 'Server error during login. Check error logs.',
        null             => null,
        default          => 'Login failed.',
    };
}

// =========================================================
// JSON RESPONSE HELPER
// =========================================================
if (!function_exists('jsonResponse')) {
    function jsonResponse($success, string $message = '', array $extra = [], int $status = 200): void {
        http_response_code($status);
        header('Content-Type: application/json');
        if (is_array($success)) { echo json_encode($success); exit; }
        echo json_encode(array_merge(['success' => (bool)$success, 'message' => $message], $extra));
        exit;
    }
}
