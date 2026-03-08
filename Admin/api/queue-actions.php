<?php
// api/queue-actions.php — v6: CSRF, service access, permission checks, split expire modes
ini_set('display_errors', 0);
error_reporting(0);

require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_STAFF);

require_once __DIR__ . '/../config/firestore_rest.php';
require_once __DIR__ . '/../services/QueueService.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonResponse(false, 'Method not allowed', [], 405);
requireCSRF();

$action    = trim($_POST['action']    ?? '');
$serviceId = trim($_POST['serviceId'] ?? '');
$entryId   = trim($_POST['entryId']   ?? '');
$reason    = trim($_POST['reason']    ?? '');
$override  = !empty($_POST['override']) && isAdmin();

if (!$serviceId) jsonResponse(false, 'Missing serviceId');

// Service-level access gate
requireServiceAccess($serviceId);

try {
    switch ($action) {

        case 'call_head':
            $result = QueueService::callHead($serviceId);
            break;

        case 'recall_head':
            $result = QueueService::recallHead($serviceId);
            break;

        case 'check_in':
            $result = QueueService::checkInCalled($serviceId);
            break;

        case 'mark_served':
            if (!$entryId) { $result = ['success' => false, 'message' => 'Missing entryId']; break; }
            if ($override && !isAdmin()) { $result = ['success' => false, 'message' => 'Override requires admin']; break; }
            $result = QueueService::markServed($serviceId, $entryId, $override, $reason);
            break;

        case 'mark_left':
            if (!$entryId) { $result = ['success' => false, 'message' => 'Missing entryId']; break; }
            // Map reason from POST to semantic key
            $leftReason = $reason ?: 'pending_left';
            if (!array_key_exists($leftReason, QueueService::LEFT_REASONS)) {
                $leftReason = 'pending_left';
            }
            $result = QueueService::markLeft($serviceId, $entryId, $leftReason);
            break;

        case 'expire_called':
            // Normal expire: no override (only works if window passed)
            $result = QueueService::expireCalled($serviceId, false, '');
            break;

        case 'force_expire_called':
            // Early/force expire: admin only + reason
            if (!isAdmin()) { $result = ['success' => false, 'message' => 'Force expire requires admin']; break; }
            if (!$reason)   { $result = ['success' => false, 'message' => 'Force expire requires a reason']; break; }
            $result = QueueService::expireCalled($serviceId, true, $reason);
            break;

        case 'repair':
            requirePermission('canRepairQueue');
            $result = QueueService::repairService($serviceId);
            break;

        case 'purge_entry':
            requirePermission('canPurgeEntry');
            if (!$entryId) { $result = ['success' => false, 'message' => 'Missing entryId']; break; }
            if (!$reason)  { $result = ['success' => false, 'message' => 'Purge requires a reason']; break; }
            $result = QueueService::purgeEntry($serviceId, $entryId, $reason);
            break;

        case 'sync_state':
            requirePermission('canRepairQueue');
            QueueService::syncServiceState($serviceId);
            $result = ['success' => true, 'message' => 'Service state synced'];
            break;

        default:
            $result = ['success' => false, 'message' => "Unknown action: $action"];
    }

    echo json_encode($result);
} catch (Throwable $e) {
    error_log('queue-actions.php: ' . $e->getMessage());
    jsonResponse(false, 'Server error', [], 500);
}
