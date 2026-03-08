<?php
// api/login.php — Firebase ID token verification (v6)
// P0 fix: getFirebaseProjectId() is defined in config/firestore_rest.php only.
// This file does NOT redeclare it.
ini_set('display_errors', 0);
error_reporting(0);

if (session_status() === PHP_SESSION_NONE) session_start();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: /queuelens/login.php');
    exit;
}

require_once __DIR__ . '/../config/config.php';

if (!verifyCSRFToken($_POST['csrf_token'] ?? '')) {
    redirectTo('login.php?error=server_error');
}

$idToken = trim($_POST['id_token'] ?? '');
if ($idToken === '') {
    redirectTo('login.php?error=missing_token');
}

// firestore_rest.php provides: firestore_getDocument, fs_timestamp_now, getFirebaseProjectId
require_once __DIR__ . '/../config/firestore_rest.php';

// =========================================================
// Verify Firebase ID token via Google public keys (RS256)
// =========================================================
function verifyFirebaseIdToken(string $idToken): ?array {
    $parts = explode('.', $idToken);
    if (count($parts) !== 3) return null;

    $header  = json_decode(base64url_decode_token($parts[0]), true);
    $payload = json_decode(base64url_decode_token($parts[1]), true);
    if (!$header || !$payload) return null;

    $kid = $header['kid'] ?? null;
    if (!$kid) return null;

    // Fetch and cache Google public keys
    $cacheFile = sys_get_temp_dir() . '/ql_firebase_pubkeys_' . md5('v6') . '.json';
    $keys      = null;

    if (file_exists($cacheFile) && (time() - filemtime($cacheFile)) < 3300) {
        $keys = json_decode(file_get_contents($cacheFile), true);
    }

    if (!$keys) {
        $context = stream_context_create(['http' => ['timeout' => 5]]);
        $raw = @file_get_contents(
            'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com',
            false, $context
        );
        if (!$raw) {
            error_log('QueueLens login: could not fetch Firebase public keys (network issue)');
            return null;
        }
        $keys = json_decode($raw, true);
        if ($keys) @file_put_contents($cacheFile, $raw);
    }

    if (!isset($keys[$kid])) return null;

    // Verify RS256 signature
    $pubKey = openssl_pkey_get_public($keys[$kid]);
    if (!$pubKey) return null;

    $verified = openssl_verify(
        $parts[0] . '.' . $parts[1],
        base64url_decode_token($parts[2]),
        $pubKey,
        OPENSSL_ALGO_SHA256
    );

    if ($verified !== 1) return null;

    // Validate standard JWT claims
    $now       = time();
    $projectId = getFirebaseProjectId(); // from firestore_rest.php — NOT redeclared here

    if (($payload['exp'] ?? 0) < $now)           return null;
    if (($payload['iat'] ?? 0) > $now + 300)      return null; // 5min clock skew tolerance
    if (($payload['aud'] ?? '') !== $projectId)   return null;
    if (($payload['iss'] ?? '') !== "https://securetoken.google.com/$projectId") return null;
    if (empty($payload['sub']))                    return null;
    if (empty($payload['email']))                  return null;

    return $payload;
}

function base64url_decode_token(string $input): string {
    $rem = strlen($input) % 4;
    if ($rem) $input .= str_repeat('=', 4 - $rem);
    return base64_decode(strtr($input, '-_', '+/'));
}

// =========================================================
// Verify token
// =========================================================
try {
    $tokenPayload = verifyFirebaseIdToken($idToken);
} catch (Throwable $e) {
    error_log('QueueLens login token error: ' . $e->getMessage());
    redirectTo('login.php?error=server_error');
}

if (!$tokenPayload) {
    redirectTo('login.php?error=invalid_token');
}

$firebaseUid   = $tokenPayload['sub'];
$firebaseEmail = strtolower(trim($tokenPayload['email'] ?? ''));

// =========================================================
// Load Firestore user record by verified UID (not email)
// =========================================================
try {
    $user = firestore_getDocument("users/$firebaseUid");
} catch (Throwable $e) {
    error_log('QueueLens login Firestore error: ' . $e->getMessage());
    redirectTo('login.php?error=server_error');
}

if (!$user) {
    redirectTo('login.php?error=no_user');
}

// Belt-and-suspenders: email must match token (blocks account takeover via UID reuse)
$storedEmail = strtolower(trim($user['email'] ?? ''));
if ($storedEmail && $firebaseEmail && $storedEmail !== $firebaseEmail) {
    error_log("QueueLens login email mismatch: token=$firebaseEmail stored=$storedEmail uid=$firebaseUid");
    redirectTo('login.php?error=forbidden');
}

$role = strtolower(trim((string)($user['role'] ?? '')));
if (!in_array($role, ['admin', 'staff'], true)) {
    redirectTo('login.php?error=forbidden');
}

if (($user['isActive'] ?? true) === false) {
    redirectTo('login.php?error=forbidden');
}

// =========================================================
// Create hardened session
// =========================================================
session_regenerate_id(true);

$_SESSION['user_id']              = $firebaseUid;
$_SESSION['user_name']            = $user['name'] ?? 'Staff';
$_SESSION['user_email']           = $user['email'] ?? $firebaseEmail;
$_SESSION['user_role']            = $role;
$_SESSION['last_activity']        = time();
$_SESSION['assigned_service_ids'] = is_array($user['assignedServiceIds'] ?? null)
                                        ? $user['assignedServiceIds'] : [];
$_SESSION['permissions']          = is_array($user['permissions'] ?? null)
                                        ? $user['permissions'] : [];
// Store fingerprint for session hijack detection
$_SESSION['ip_hash']              = hash('sha256', $_SERVER['REMOTE_ADDR'] ?? '');
$_SESSION['ua_hash']              = hash('sha256', $_SERVER['HTTP_USER_AGENT'] ?? '');

// Update lastLoginAt async (failure is non-fatal)
try {
    firestore_updateDocument("users/$firebaseUid", ['lastLoginAt' => fs_timestamp_now()]);
} catch (Throwable $e) {}

redirectTo('index.php');
