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
    if (!$serviceId) {
        echo json_encode(['success'=>false,'message'=>'Missing serviceId']); exit;
    }

    // Query first pending entry
    $results = firestore_runQueryWithParent(
        "services/$serviceId",
        [
            "from" => [["collectionId" => "entries"]],
            "where" => [
                "fieldFilter" => [
                    "field" => ["fieldPath" => "status"],
                    "op" => "EQUAL",
                    "value" => ["stringValue" => "pending"]
                ]
            ],
            "limit" => 1
        ]
    );

    $entryDoc = null;
    foreach ($results as $row) {
        if (!empty($row['document'])) {
            $entryDoc = $row['document'];
            break;
        }
    }

    if (!$entryDoc) {
        echo json_encode(['success'=>false,'message'=>'No pending entries']); exit;
    }

    $fullPath = $entryDoc['name']; // full Firestore path
    $relativePath = str_replace(
        "projects/queeuelens/databases/(default)/documents/",
        '',
        $fullPath
    );

    // Update entry to active
    firestore_updateDocument($relativePath, [
        'status' => 'active',
        'calledAt' => fs_timestamp_now(),
        'calledBy' => $_SESSION['user_id'] ?? 'staff'
    ]);

    // Update service counters
    $serviceData = firestore_getDocument("services/$serviceId");

    firestore_updateDocument("services/$serviceId", [
        'pendingCount' => max(0, ($serviceData['pendingCount'] ?? 0) - 1),
        'activeCount'  => ($serviceData['activeCount'] ?? 0) + 1,
        'lastUpdatedAt'=> fs_timestamp_now()
    ]);

    echo json_encode(['success'=>true,'message'=>'Next person called']);

} catch (Throwable $e) {
    echo json_encode(['success'=>false,'message'=>'Failed: '.$e->getMessage()]);
}
