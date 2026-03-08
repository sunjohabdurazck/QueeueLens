<?php
// services/AuditService.php — v6: structured native maps, dangerous/override flags

require_once __DIR__ . '/../config/firestore_rest.php';

class AuditService {

    /**
     * @param string      $action       e.g. 'QUEUE_CALL_HEAD'
     * @param string      $targetPath   e.g. 'services/svc_x/entries/abc'
     * @param array       $before       state before mutation (PHP array, stored as Firestore map)
     * @param array       $after        state after mutation
     * @param string      $reason       human reason or empty
     * @param string|null $serviceId
     * @param string|null $entryId
     * @param array       $meta         optional: ['override'=>bool, 'dangerous'=>bool, 'outcome'=>'success']
     */
    public static function log(
        string $action,
        string $targetPath = '',
        array  $before     = [],
        array  $after      = [],
        string $reason     = '',
        ?string $serviceId = null,
        ?string $entryId   = null,
        array  $meta       = []
    ): void {
        try {
            $doc = [
                'actorUid'   => $_SESSION['user_id']    ?? 'unknown',
                'actorName'  => $_SESSION['user_name']  ?? 'Unknown',
                'actorRole'  => $_SESSION['user_role']  ?? 'unknown',
                'actorEmail' => $_SESSION['user_email'] ?? '',
                'action'     => $action,
                'targetPath' => $targetPath,
                'targetType' => self::inferTargetType($targetPath),
                'serviceId'  => $serviceId ?? '',
                'entryId'    => $entryId   ?? '',
                'reason'     => $reason,
                'source'     => 'php_admin_v6',
                'ipAddress'  => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
                'sessionId'  => session_id(),
                'createdAt'  => fs_timestamp_now(),
                // Structured maps (not JSON strings)
                'before'     => empty($before) ? null : $before,
                'after'      => empty($after)  ? null : $after,
                // Meta flags
                'override'   => (bool)($meta['override']  ?? false),
                'dangerous'  => (bool)($meta['dangerous']  ?? false),
                'outcome'    => $meta['outcome'] ?? 'success',
            ];

            // Remove null values to keep Firestore docs clean
            $doc = array_filter($doc, fn($v) => $v !== null);

            firestore_createDocument('audit_logs', $doc);
        } catch (Throwable $e) {
            error_log('AuditService::log failed: ' . $e->getMessage());
        }
    }

    private static function inferTargetType(string $path): string {
        if (str_contains($path, '/entries/')) return 'entry';
        if (str_starts_with($path, 'services/')) return 'service';
        if (str_starts_with($path, 'users/'))    return 'user';
        if (str_starts_with($path, 'surveillance_cameras/')) return 'camera';
        return 'unknown';
    }
}
