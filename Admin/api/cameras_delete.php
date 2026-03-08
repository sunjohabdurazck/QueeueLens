<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_STAFF);
require_once __DIR__ . '/../config/firestore_rest.php';

function isAjax(): bool {
  return isset($_SERVER['HTTP_X_REQUESTED_WITH']) &&
         strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) === 'xmlhttprequest';
}
function jsonOut(bool $success, string $message, bool $reload = false): void {
  header('Content-Type: application/json');
  echo json_encode(['success'=>$success, 'message'=>$message, 'reload'=>$reload]);
  exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  if (isAjax()) jsonOut(false, 'Invalid method');
  redirectTo('pages/cameras.php');
}

if (!verifyCSRFToken($_POST['csrf_token'] ?? '')) {
  if (isAjax()) jsonOut(false, 'Invalid CSRF token');
  die('Invalid CSRF token');
}

$id = trim($_POST['id'] ?? '');
if ($id === '') {
  if (isAjax()) jsonOut(false, 'Missing camera id');
  die('Missing camera id');
}

firestore_deleteDocument("surveillance_cameras/$id");

if (isAjax()) jsonOut(true, 'Camera deleted', true);
redirectTo('pages/cameras.php?ok=deleted');
