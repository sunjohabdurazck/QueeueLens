<?php
// config/config.php
// QueueLens Admin Panel - Session + Role Guard + CSRF (Windows/XAMPP safe)

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

/* =========================================================
   APP CONSTANTS
========================================================= */

define('APP_NAME', 'QueueLens Admin');
define('BASE_PATH', '/queuelens');
define('BASE_URL', 'http://localhost' . BASE_PATH);
define('SESSION_TIMEOUT', 60 * 60 * 6); // 6 hours

/* =========================================================
   ROLES
========================================================= */

define('ROLE_STUDENT', 'student');
define('ROLE_STAFF',   'staff');
define('ROLE_ADMIN',   'admin');

/* =========================================================
   REDIRECT HELPER
========================================================= */

function redirectTo(string $path): void {
    $url = rtrim(BASE_PATH, '/') . '/' . ltrim($path, '/');
    header("Location: $url");
    exit;
}

/* =========================================================
   AUTHENTICATION
========================================================= */

function isAuthenticated(): bool {
    if (!isset($_SESSION['user_id'], $_SESSION['user_role'], $_SESSION['last_activity'])) {
        return false;
    }

    // Session timeout check
    if ((time() - (int)$_SESSION['last_activity']) > SESSION_TIMEOUT) {
        return false;
    }

    return true;
}

function requireAuth(): void {
    if (!isAuthenticated()) {
        session_unset();
        session_destroy();
        redirectTo('login.php');
    }

    // Refresh activity timestamp
    $_SESSION['last_activity'] = time();
}

function requireRole(string $requiredRole): void {
    requireAuth();

    $role = strtolower(trim((string)($_SESSION['user_role'] ?? '')));

    // STAFF pages allow STAFF + ADMIN
    if ($requiredRole === ROLE_STAFF) {
        if (!in_array($role, [ROLE_STAFF, ROLE_ADMIN], true)) {
            redirectTo('login.php?error=forbidden');
        }
        return;
    }

    // ADMIN pages allow ADMIN only
    if ($requiredRole === ROLE_ADMIN) {
        if ($role !== ROLE_ADMIN) {
            redirectTo('login.php?error=forbidden');
        }
        return;
    }

    // Default strict match
    if ($role !== strtolower($requiredRole)) {
        redirectTo('login.php?error=forbidden');
    }
}

/* =========================================================
   CURRENT USER HELPERS
========================================================= */

function currentUser(): array {
    return [
        'id'    => $_SESSION['user_id'] ?? null,
        'name'  => $_SESSION['user_name'] ?? null,
        'email' => $_SESSION['user_email'] ?? null,
        'role'  => $_SESSION['user_role'] ?? null,
    ];
}

function userRole(): string {
    return strtolower(trim((string)($_SESSION['user_role'] ?? '')));
}

function hasRole(string $role): bool {
    $current = userRole();
    $role = strtolower(trim($role));

    if ($role === ROLE_STAFF) {
        return in_array($current, [ROLE_STAFF, ROLE_ADMIN], true);
    }

    return $current === $role;
}

function isAdmin(): bool {
    return hasRole(ROLE_ADMIN);
}

function isStaff(): bool {
    return hasRole(ROLE_STAFF);
}

/* =========================================================
   CSRF PROTECTION
========================================================= */

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
        return isset($_SESSION['csrf_token']) &&
               hash_equals($_SESSION['csrf_token'], $token);
    }
}

/* =========================================================
   ERROR MESSAGE HELPER
========================================================= */

function errorMessageFromQuery(): ?string {
    $err = $_GET['error'] ?? null;
    if (!$err) return null;

    return match ($err) {
        'missing_email' => 'Please enter your email.',
        'no_user'       => 'User not found. Make sure your email exists in Firestore users collection.',
        'forbidden'     => 'Access denied (role not allowed).',
        'server_error'  => 'Server error. Check Apache error.log for details.',
        default         => 'Login failed.',
    };
}
if (!function_exists('jsonResponse')) {
  function jsonResponse($success, string $message = '', array $extra = [], int $status = 200): void {

    http_response_code($status);
    header('Content-Type: application/json');

    // If first argument is already an array, just output it
    if (is_array($success)) {
        echo json_encode($success);
        exit;
    }

    echo json_encode(array_merge([
      'success' => (bool)$success,
      'message' => $message,
    ], $extra));

    exit;
  }
}
