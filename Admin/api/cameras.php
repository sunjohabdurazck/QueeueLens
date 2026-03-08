<?php
require_once '../config/config.php';
requireRole(ROLE_STAFF);

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['success' => false, 'message' => 'Invalid method'], 405);
}

if (!verifyCSRFToken($_POST['csrf_token'] ?? '')) {
    jsonResponse(['success' => false, 'message' => 'Invalid CSRF token'], 403);
}

$action = $_POST['action'] ?? '';

try {
    require_once '../config/firebase.php';
    $firebase = FirebaseAdmin::getInstance();
    $db = $firebase->getFirestore();
    
    switch ($action) {
        case 'create':
            $cameraData = [
                'name' => $_POST['name'] ?? '',
                'serviceId' => $_POST['serviceId'] ?? '',
                'streamUrl' => $_POST['streamUrl'] ?? '',
                'type' => (int)($_POST['type'] ?? 0),
                'isActive' => isset($_POST['isActive']),
                'position' => [
                    'x' => (float)($_POST['positionX'] ?? 0),
                    'y' => (float)($_POST['positionY'] ?? 0),
                    'z' => (float)($_POST['positionZ'] ?? 0)
                ],
                'description' => $_POST['description'] ?? '',
                'lastActive' => new \Google\Cloud\Core\Timestamp(new \DateTime())
            ];
            
            $newCamera = $db->collection('surveillance_cameras')->add($cameraData);
            
            logActivity('CREATE_CAMERA', '/surveillance_cameras/' . $newCamera->id(), $cameraData);
            
            jsonResponse(['success' => true, 'message' => 'Camera added successfully', 'reload' => true]);
            break;
            
        default:
            jsonResponse(['success' => false, 'message' => 'Unknown action'], 400);
    }
    
} catch (Exception $e) {
    error_log("Camera API error: " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Server error occurred'], 500);
}
