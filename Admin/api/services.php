<?php
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/firestore_rest.php';

requireRole(ROLE_STAFF);

/**
 * Always return JSON — even if warnings/notices happen.
 */
header('Content-Type: application/json; charset=utf-8');
ini_set('display_errors', '0');
error_reporting(E_ALL);

ob_start();

// Convert PHP warnings/notices into exceptions so we can JSON them
set_error_handler(function ($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

set_exception_handler(function ($e) {
    while (ob_get_level()) ob_end_clean();
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage(),
    ]);
    exit;
});

function openStatusString(bool $isOpen): string {
    return $isOpen ? 'OPEN' : 'CLOSED';
}

/**
 * Strict boolean from POST for checkbox-like values.
 * Accepts: "on", "1", "true", "yes"
 */
function postBool(string $key): bool {
    if (!isset($_POST[$key])) return false;
    $v = strtolower(trim((string)$_POST[$key]));
    return in_array($v, ['on', '1', 'true', 'yes'], true);
}

$action = $_POST['api_action'] ?? $_POST['action'] ?? '';

try {

    // ----------------------------
    // CREATE SERVICE
    // ----------------------------
    if ($action === 'create') {

        $idRaw = trim($_POST['id'] ?? '');
        $id    = strtolower($idRaw);

        $name        = trim($_POST['name'] ?? '');
        $description = trim($_POST['description'] ?? '');

        // checkbox from HTML form: present => true
        $isOpen = isset($_POST['isOpen']);

        if ($id === '') jsonResponse(false, 'Service ID is required');

        // ✅ enforce svc_ prefix as requested
        if (!preg_match('/^svc_[a-z0-9_]{3,46}$/', $id)) {
            jsonResponse(false, 'Invalid Service ID. Must start with svc_. Use 3–46 chars after svc_: a-z, 0-9, underscore only.');
        }

        if ($name === '') jsonResponse(false, 'Name is required');

        $existing = firestore_getDocument("services/$id");
        if (!empty($existing) && !empty($existing['name'])) {
            jsonResponse(false, 'That Service ID already exists. Choose a different one.');
        }

        firestore_setDocument("services/$id", [
            // ✅ add serviceId field for Flutter
            'serviceId' => $id,

            'name' => $name,
            'description' => $description,

            'isOpen' => $isOpen,
            'status' => openStatusString($isOpen),

            'pendingCount' => 0,
            'activeCount'  => 0,
            'totalServed'  => 0,

            // Firestore timestamp value helper from firestore_rest.php
            'createdAt'     => fs_timestamp_now(),
            'lastUpdatedAt' => fs_timestamp_now(),
        ]);

        jsonResponse(true, "Service created ($id)", ['reload' => true]);
    }

    // ----------------------------
    // UPDATE SERVICE
    // ----------------------------
    if ($action === 'update') {

        $id          = strtolower(trim($_POST['id'] ?? ''));
        $name        = trim($_POST['name'] ?? '');
        $description = trim($_POST['description'] ?? '');

        $isOpen = isset($_POST['isOpen']);

        if ($id === '') jsonResponse(false, 'Missing service ID');

        if (!preg_match('/^svc_[a-z0-9_]{3,46}$/', $id)) {
            jsonResponse(false, 'Invalid Service ID.');
        }

        firestore_updateDocument("services/$id", [
            // ✅ keep it stable
            'serviceId' => $id,

            'name' => $name,
            'description' => $description,

            'isOpen' => $isOpen,
            'status' => openStatusString($isOpen),

            'lastUpdatedAt' => fs_timestamp_now(),
        ]);

        jsonResponse(true, 'Service updated', ['reload' => true]);
    }

    // ----------------------------
    // TOGGLE SERVICE
    // ----------------------------
    if ($action === 'toggle') {

        $id = strtolower(trim($_POST['id'] ?? ''));
        if ($id === '') jsonResponse(false, 'Missing service ID');

        if (!preg_match('/^svc_[a-z0-9_]{3,46}$/', $id)) {
            jsonResponse(false, 'Invalid Service ID.');
        }

        // ✅ robust: your JS sends isOpen='' when closing, but key still exists
        $isOpen = postBool('isOpen');

        firestore_updateDocument("services/$id", [
            'serviceId' => $id,
            'isOpen' => $isOpen,
            'status' => openStatusString($isOpen),
            'lastUpdatedAt' => fs_timestamp_now(),
        ]);

        jsonResponse(true, $isOpen ? 'Service opened' : 'Service closed', ['reload' => true]);
    }

    // ----------------------------
    // RESET COUNTS
    // ----------------------------
    if ($action === 'reset_counts') {

        $id = strtolower(trim($_POST['id'] ?? ''));
        if ($id === '') jsonResponse(false, 'Missing service ID');

        firestore_updateDocument("services/$id", [
            'serviceId' => $id,
            'pendingCount' => 0,
            'activeCount'  => 0,
            'totalServed'  => 0,
            'lastUpdatedAt' => fs_timestamp_now(),
        ]);

        jsonResponse(true, 'Counts reset', ['reload' => true]);
    }

    // ----------------------------
    // DELETE SERVICE
    // ----------------------------
    if ($action === 'delete') {

        $id = strtolower(trim($_POST['id'] ?? ''));
        if ($id === '') jsonResponse(false, 'Missing service ID');

        firestore_deleteDocument("services/$id");

        jsonResponse(true, 'Service deleted', ['reload' => true]);
    }

    // ----------------------------
    // LIST SERVICES
    // ----------------------------
    if ($action === 'list') {

        $results = firestore_runQuery([
            "from" => [["collectionId" => "services"]],
            "orderBy" => [[
                "field" => ["fieldPath" => "name"],
                "direction" => "ASCENDING"
            ]]
        ]);

        $services = [];

        foreach ($results as $row) {
            if (empty($row['document'])) continue;

            $doc = $row['document'];
            $fields = firestore_unpack_fields($doc['fields'] ?? []);

            $fullName = $doc['name'] ?? '';
            $parts = explode('/services/', $fullName);
            $id = $parts[1] ?? '';

            // ensure consistent fields
            if (!isset($fields['serviceId'])) $fields['serviceId'] = $id;
            if (!isset($fields['status'])) {
                $isOpen = (bool)($fields['isOpen'] ?? false);
                $fields['status'] = openStatusString($isOpen);
            }

            $services[] = array_merge($fields, ['id' => $id]);
        }

        jsonResponse(true, 'OK', ['services' => $services]);
    }

    jsonResponse(false, 'Invalid action');

} catch (Throwable $e) {
    while (ob_get_level()) ob_end_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
    exit;
}
