<?php
require_once '../config/config.php';
requireAuth();

try {
    require_once '../config/firebase.php';
    $firebase = FirebaseAdmin::getInstance();
    $db = $firebase->getFirestore();
    
    $servicesRef = $db->collection('services');
    $services = $servicesRef->documents();
    
    $stats = [
        'totalServices' => 0,
        'totalPending' => 0,
        'totalActive' => 0,
        'totalServed' => 0
    ];
    
    foreach ($services as $service) {
        $data = $service->data();
        $stats['totalServices']++;
        $stats['totalPending'] += $data['pendingCount'] ?? 0;
        $stats['totalActive'] += $data['activeCount'] ?? 0;
        $stats['totalServed'] += $data['totalServed'] ?? 0;
    }
    
    jsonResponse(['success' => true, 'stats' => $stats]);
    
} catch (Exception $e) {
    jsonResponse(['success' => false, 'message' => 'Failed to fetch stats'], 500);
}
