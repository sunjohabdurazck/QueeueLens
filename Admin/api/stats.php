<?php
// api/stats.php — v6: uses firestore_rest directly, correct jsonResponse signature
ini_set('display_errors', 0);
error_reporting(0);

require_once __DIR__ . '/../config/config.php';
requireAuth();

header('Content-Type: application/json');

require_once __DIR__ . '/../config/firestore_rest.php';

try {
    $rows = firestore_runQuery(['from' => [['collectionId' => 'services']], 'limit' => 100]);

    $stats = ['totalServices'=>0,'openServices'=>0,'totalPending'=>0,'totalActive'=>0,'totalServed'=>0,'totalCalled'=>0,'expiredCalls'=>0];

    foreach ($rows as $row) {
        if (empty($row['document'])) continue;
        $d = firestore_unpack_fields($row['document']['fields'] ?? []);
        $stats['totalServices']++;
        if (!empty($d['isOpen']))          $stats['openServices']++;
        $stats['totalPending'] += (int)($d['pendingCount'] ?? 0);
        $stats['totalActive']  += (int)($d['activeCount']  ?? 0);
        $stats['totalServed']  += (int)($d['totalServed']  ?? 0);
        if (!empty($d['calledEntryId'])) {
            $stats['totalCalled']++;
            $exp = $d['callExpiresAt'] ?? null;
            if ($exp && strtotime($exp) < time()) $stats['expiredCalls']++;
        }
    }

    jsonResponse(true, '', ['stats' => $stats]);
} catch (Throwable $e) {
    error_log('stats.php: ' . $e->getMessage());
    jsonResponse(false, 'Failed to fetch stats', [], 500);
}
