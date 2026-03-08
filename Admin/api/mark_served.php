<?php
require_once '../config/config.php';
requireRole(ROLE_STAFF);

require_once '../config/firebase.php';
require_once '../config/firestore_rest.php';

header('Content-Type: application/json');

$entryPath = $_POST['entryPath'] ?? null;

if (!$entryPath) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing entryPath']);
    exit;
}

try {
    firestore_patch($entryPath, [
        'status' => 'served',
        'servedAt' => fs_timestamp_now()
    ]);

    echo json_encode(['success' => true]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
