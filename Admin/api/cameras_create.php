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
if ($id === '') $id = 'cam_' . bin2hex(random_bytes(6));

$data = [
  'serviceId'   => trim($_POST['serviceId'] ?? ''),
  'name'        => trim($_POST['name'] ?? ''),
  'streamUrl'   => trim($_POST['streamUrl'] ?? ''),
  'type'        => (int)($_POST['type'] ?? 0),
  'isActive'    => isset($_POST['isActive']),
  'description' => trim($_POST['description'] ?? ''),
  'position'    => [
    'x' => (float)($_POST['positionX'] ?? 0),
    'y' => (float)($_POST['positionY'] ?? 0),
    'z' => (float)($_POST['positionZ'] ?? 0),
  ],
  'lastActive'  => null,
];

firestore_setDocument("surveillance_cameras/$id", $data);

if (isAjax()) jsonOut(true, 'Camera added', true);
redirectTo('pages/cameras.php?ok=created');
