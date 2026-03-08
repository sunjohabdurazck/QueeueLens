<?php
// api/login.php
ini_set('display_errors', 1);
error_reporting(E_ALL);

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: /queuelens/login.php');
    exit;
}

$email = trim($_POST['email'] ?? '');
if ($email === '') {
    header('Location: /queuelens/login.php?error=missing_email');
    exit;
}

require __DIR__ . '/../config/firestore_rest.php';

try {
    $user = firestore_findUserByEmail($email);
} catch (Throwable $e) {
    // If REST fails, show server error
    // You can also log: error_log($e->getMessage());
    header('Location: /queuelens/login.php?error=server_error');
    exit;
}

if (!$user) {
    header('Location: /queuelens/login.php?error=no_user');
    exit;
}

// Normalize role
$roleRaw = $user['role'] ?? '';
$role = strtolower(trim((string)$roleRaw));

if (!in_array($role, ['admin', 'staff'], true)) {
    header('Location: /queuelens/login.php?error=forbidden');
    exit;
}

// ✅ SESSION KEYS REQUIRED BY config.php
$_SESSION['user_id'] = 'php_admin:' . ($user['email'] ?? $email); // stable server-side ID
$_SESSION['user_name'] = $user['name'] ?? 'Admin';
$_SESSION['user_email'] = $user['email'] ?? $email;
$_SESSION['user_role'] = $role;
$_SESSION['last_activity'] = time();

// Optional: regenerate session id to reduce fixation risk
session_regenerate_id(true);

// Redirect to dashboard
header('Location: /queuelens/index.php');
exit;
