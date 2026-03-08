<?php
// api/services.php — v6: split operational vs structural actions with permissions
ini_set('display_errors', 0);
error_reporting(0);
ob_start();

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/firestore_rest.php';
require_once __DIR__ . '/../services/AuditService.php';

requireRole(ROLE_STAFF);
header('Content-Type: application/json; charset=utf-8');

set_error_handler(fn($s, $m) => throw new ErrorException($m, 0, $s));
set_exception_handler(function($e) {
    while (ob_get_level()) ob_end_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
    exit;
});

/**
 * Operational actions: open/close (any assigned staff)
 * Structural actions: create/update/delete/reset (requires canManageServices)
 */
$action = $_POST['api_action'] ?? $_POST['action'] ?? '';

function svcIdValid(string $id): bool {
    return (bool)preg_match('/^svc_[a-z0-9_]{3,46}$/', $id);
}
function openStr(bool $v): string { return $v ? 'OPEN' : 'CLOSED'; }
function postBool(string $k): bool {
    return in_array(strtolower(trim((string)($_POST[$k] ?? ''))), ['on','1','true','yes'], true);
}

try {

    // ── LIST (read-only, any staff) ────────────────────────────────────
    if ($action === 'list') {
        $rows = firestore_runQuery([
            'from'    => [['collectionId' => 'services']],
            'orderBy' => [['field' => ['fieldPath' => 'name'], 'direction' => 'ASCENDING']],
        ]);
        $services = [];
        foreach ($rows as $row) {
            if (empty($row['document'])) continue;
            $doc  = $row['document'];
            $d    = firestore_unpack_fields($doc['fields'] ?? []);
            $id   = basename($doc['name']);
            $d['id'] = $d['serviceId'] = $id;
            if (!isset($d['status'])) $d['status'] = openStr((bool)($d['isOpen'] ?? false));
            $services[] = $d;
        }
        jsonResponse(true, 'OK', ['services' => $services]);
    }

    // ── TOGGLE open/close (operational — assigned staff OK) ───────────
    if ($action === 'toggle') {
        requireCSRF();
        $id = strtolower(trim($_POST['id'] ?? ''));
        if (!$id || !svcIdValid($id)) jsonResponse(false, 'Invalid service ID');
        requireServiceAccess($id);

        $isOpen = postBool('isOpen');
        firestore_updateDocument("services/$id", [
            'isOpen' => $isOpen, 'status' => openStr($isOpen),
            'lastUpdatedAt' => fs_timestamp_now(),
        ]);
        AuditService::log('SERVICE_TOGGLE', "services/$id", [], ['isOpen' => $isOpen], '', $id);
        jsonResponse(true, $isOpen ? 'Service opened' : 'Service closed', ['reload' => true]);
    }

    // ── STRUCTURAL ACTIONS (require canManageServices) ─────────────────
    if (in_array($action, ['create', 'update', 'delete', 'reset_counts'])) {
        requireCSRF();
        requirePermission('canManageServices');
    }

    if ($action === 'create') {
        $id = strtolower(trim($_POST['id'] ?? ''));
        if (!$id || !svcIdValid($id)) jsonResponse(false, 'Invalid Service ID. Must match svc_[a-z0-9_]{3,46}');
        $name = trim($_POST['name'] ?? '');
        if (!$name) jsonResponse(false, 'Name is required');
        if (firestore_getDocument("services/$id")) jsonResponse(false, 'Service ID already exists');

        firestore_setDocument("services/$id", [
            'serviceId' => $id, 'name' => $name,
            'description' => trim($_POST['description'] ?? ''),
            'isOpen' => isset($_POST['isOpen']), 'status' => 'CLOSED',
            'pendingCount' => 0, 'activeCount' => 0, 'totalServed' => 0,
            'headPendingEntryId' => null, 'activeEntryId' => null,
            'calledEntryId' => null, 'callExpiresAt' => null,
            'createdAt' => fs_timestamp_now(), 'lastUpdatedAt' => fs_timestamp_now(),
        ]);
        AuditService::log('SERVICE_CREATE', "services/$id", [], ['name' => $name], '', $id);
        jsonResponse(true, "Service created ($id)", ['reload' => true]);
    }

    if ($action === 'update') {
        $id = strtolower(trim($_POST['id'] ?? ''));
        if (!$id || !svcIdValid($id)) jsonResponse(false, 'Invalid service ID');
        $name = trim($_POST['name'] ?? '');
        if (!$name) jsonResponse(false, 'Name required');

        $isOpen = isset($_POST['isOpen']);
        firestore_updateDocument("services/$id", [
            'name' => $name, 'description' => trim($_POST['description'] ?? ''),
            'isOpen' => $isOpen, 'status' => openStr($isOpen),
            'lastUpdatedAt' => fs_timestamp_now(),
        ]);
        AuditService::log('SERVICE_UPDATE', "services/$id", [], ['name' => $name, 'isOpen' => $isOpen], '', $id);
        jsonResponse(true, 'Service updated', ['reload' => true]);
    }

    if ($action === 'reset_counts') {
        $id = strtolower(trim($_POST['id'] ?? ''));
        if (!$id) jsonResponse(false, 'Missing service ID');
        firestore_updateDocument("services/$id", [
            'pendingCount' => 0, 'activeCount' => 0, 'totalServed' => 0,
            'lastUpdatedAt' => fs_timestamp_now(),
        ]);
        AuditService::log('SERVICE_RESET_COUNTS', "services/$id", [], [], 'Admin reset', $id);
        jsonResponse(true, 'Counts reset', ['reload' => true]);
    }

    if ($action === 'delete') {
        $id = strtolower(trim($_POST['id'] ?? ''));
        if (!$id) jsonResponse(false, 'Missing service ID');
        AuditService::log('SERVICE_DELETE', "services/$id", [], [], 'Admin delete', $id);
        firestore_deleteDocument("services/$id");
        jsonResponse(true, 'Service deleted', ['reload' => true]);
    }

    jsonResponse(false, 'Invalid action');

} catch (Throwable $e) {
    while (ob_get_level()) ob_end_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
    exit;
}
