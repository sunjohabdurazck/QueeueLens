<?php
require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_STAFF);

require_once __DIR__ . '/../config/firestore_rest.php';

header('Content-Type: application/json');

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['success'=>false,'message'=>'Invalid method']); exit;
    }

    if (!verifyCSRFToken($_POST['csrf_token'] ?? '')) {
        echo json_encode(['success'=>false,'message'=>'Invalid CSRF token']); exit;
    }

    $serviceId = $_POST['serviceId'] ?? '';
    $entryId   = $_POST['entryId'] ?? '';

    if (!$serviceId || !$entryId) {
        echo json_encode(['success'=>false,'message'=>'Missing data']); exit;
    }

    $entryPath = "services/$serviceId/entries/$entryId";
    $entryData = firestore_getDocument($entryPath);

    if (!$entryData) {
        echo json_encode(['success'=>false,'message'=>'Entry not found']); exit;
    }

    firestore_deleteDocument($entryPath);

    $serviceData = firestore_getDocument("services/$serviceId");

    $updates = [
        'lastUpdatedAt'=> fs_timestamp_now()
    ];

    if (($entryData['status'] ?? '') === 'active') {
        $updates['activeCount'] = max(0, ($serviceData['activeCount'] ?? 0) - 1);
    } else {
        $updates['pendingCount'] = max(0, ($serviceData['pendingCount'] ?? 0) - 1);
    }

    firestore_updateDocument("services/$serviceId", $updates);

    echo json_encode(['success'=>true,'message'=>'Entry deleted']);

} catch (Throwable $e) {
    echo json_encode(['success'=>false,'message'=>'Failed: '.$e->getMessage()]);
}
