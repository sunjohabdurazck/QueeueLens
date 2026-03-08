<?php
require_once '../config/config.php';
requireRole(ROLE_STAFF);

require_once '../config/firebase.php';
require_once '../config/firestore_rest.php';

header('Content-Type: application/json');

$serviceId = $_POST['serviceId'] ?? null;

if (!$serviceId) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing serviceId']);
    exit;
}

try {
    // Find oldest pending entry
    $query = new FirestoreRestQuery();

    $results = $query->runQuery([
        'from' => [
            ['collectionId' => 'entries', 'allDescendants' => false]
        ],
        'where' => [
            'compositeFilter' => [
                'op' => 'AND',
                'filters' => [
                    [
                        'fieldFilter' => [
                            'field' => ['fieldPath' => 'serviceId'],
                            'op' => 'EQUAL',
                            'value' => ['stringValue' => $serviceId]
                        ]
                    ],
                    [
                        'fieldFilter' => [
                            'field' => ['fieldPath' => 'status'],
                            'op' => 'EQUAL',
                            'value' => ['stringValue' => 'pending']
                        ]
                    ]
                ]
            ]
        ],
        'orderBy' => [[
            'field' => ['fieldPath' => 'joinedAt'],
            'direction' => 'ASCENDING'
        ]],
        'limit' => 1
    ]);

    if (empty($results)) {
        echo json_encode(['message' => 'No pending entries']);
        exit;
    }

    $doc = $results[0]['document'];
    $docName = $doc['name']; // full path

    // Mark as active
    firestore_patch($docName, [
        'status' => 'active',
        'checkInBy' => $_SESSION['user_name'] ?? 'staff',
        'checkedInAt' => fs_timestamp_now()
    ]);

    echo json_encode(['success' => true]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
