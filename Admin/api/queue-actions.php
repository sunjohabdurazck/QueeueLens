<?php
require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_STAFF);

require_once __DIR__ . '/../config/firestore_rest.php';

header('Content-Type: application/json');

function jsonResponse(array $data, int $status = 200): void {
    http_response_code($status);
    echo json_encode($data);
    exit;
}

// Parse JSON body for POST requests
$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) $input = $_POST;

$action    = $input['action'] ?? '';
$serviceId = $input['serviceId'] ?? '';

if ($action === '' || $serviceId === '') {
    jsonResponse(['success' => false, 'message' => 'action and serviceId required'], 400);
}

function nowIso(): string {
    return gmdate('c'); // ISO timestamp string
}

try {
    if ($action === 'call_next') {

        // Query first pending entry in subcollection services/{serviceId}/entries
        $results = firestore_runQueryWithParent("services/$serviceId", [
            "from" => [["collectionId" => "entries"]],
            "where" => [
                "fieldFilter" => [
                    "field" => ["fieldPath" => "status"],
                    "op" => "EQUAL",
                    "value" => ["stringValue" => "pending"]
                ]
            ],
            "orderBy" => [[
                "field" => ["fieldPath" => "joinedAt"],
                "direction" => "ASCENDING"
            ]],
            "limit" => 1
        ]);

        $doc = null;
        foreach ($results as $row) {
            if (!empty($row['document'])) { $doc = $row['document']; break; }
        }

        if (!$doc) {
            jsonResponse(['success' => false, 'message' => 'No pending entries'], 404);
        }

        // Extract entryId from full name
        // name: projects/.../documents/services/{serviceId}/entries/{entryId}
        $fullName = $doc['name'] ?? '';
        $parts = explode('/entries/', $fullName);
        $entryId = $parts[1] ?? '';
        if ($entryId === '') {
            jsonResponse(['success' => false, 'message' => 'Could not determine entryId'], 500);
        }

        // Update entry => active
        firestore_updateDocument("services/$serviceId/entries/$entryId", [
            'status'   => 'active',
            'calledAt' => nowIso(),
            'calledBy' => $_SESSION['user_id'] ?? 'staff',
        ]);

        // Update service counts
        $svc = firestore_getDocument("services/$serviceId");
        $pendingCount = (int)($svc['pendingCount'] ?? 0);
        $activeCount  = (int)($svc['activeCount'] ?? 0);

        firestore_updateDocument("services/$serviceId", [
            'pendingCount'  => max(0, $pendingCount - 1),
            'activeCount'   => $activeCount + 1,
            'lastUpdatedAt' => nowIso(),
        ]);

        jsonResponse(['success' => true, 'message' => 'Next person called', 'reload' => true]);
    }

    if ($action === 'mark_served') {
        $entryId = $input['entryId'] ?? '';
        if ($entryId === '') {
            jsonResponse(['success' => false, 'message' => 'entryId required'], 400);
        }

        // Read entry to know its status (pending/active)
        $entry = firestore_getDocument("services/$serviceId/entries/$entryId");
        if (!$entry) {
            jsonResponse(['success' => false, 'message' => 'Entry not found'], 404);
        }

        $status = $entry['status'] ?? 'pending';

        // Mark served (optional) then delete (keeps list clean)
        firestore_updateDocument("services/$serviceId/entries/$entryId", [
            'status'   => 'served',
            'servedAt' => nowIso(),
            'servedBy' => $_SESSION['user_id'] ?? 'staff',
        ]);

        firestore_deleteDocument("services/$serviceId/entries/$entryId");

        // Update counts
        $svc = firestore_getDocument("services/$serviceId");
        $pendingCount = (int)($svc['pendingCount'] ?? 0);
        $activeCount  = (int)($svc['activeCount'] ?? 0);
        $totalServed  = (int)($svc['totalServed'] ?? 0);

        $updates = [
            'totalServed'   => $totalServed + 1,
            'lastUpdatedAt' => nowIso(),
        ];

        if ($status === 'active') $updates['activeCount']  = max(0, $activeCount - 1);
        else                     $updates['pendingCount'] = max(0, $pendingCount - 1);

        firestore_updateDocument("services/$serviceId", $updates);

        jsonResponse(['success' => true, 'message' => 'Entry served', 'reload' => true]);
    }

    jsonResponse(['success' => false, 'message' => 'Unknown action'], 400);

} catch (Throwable $e) {
    jsonResponse(['success' => false, 'message' => 'Failed: ' . $e->getMessage()], 500);
}
