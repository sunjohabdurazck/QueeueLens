<?php
/**
 * QueueService.php — v6
 *
 * Queue State Machine Contract:
 * ─────────────────────────────
 * Entry statuses:   pending → called → active → served
 *                   pending → left  (any time)
 *                   called  → expired | left
 *                   active  → left
 *
 * Forbidden transitions (enforced):
 *   served/left/expired → anything
 *   active → pending/called
 *   expired → active
 *
 * Service document counters:
 *   pendingCount       = count of docs with status=pending
 *   activeCount        = count of docs with status=active  (max 1 in normal flow)
 *   calledEntryId      = single called entry (max 1)
 *   headPendingEntryId = oldest pending entry ID (or null)
 *   activeEntryId      = current active entry ID (or null)
 *   callExpiresAt      = when calledEntryId expires (or null)
 *
 * syncServiceState() is the authoritative reconciler. Called after every mutation.
 */

require_once __DIR__ . '/../config/firestore_rest.php';
require_once __DIR__ . '/../services/AuditService.php';

class QueueService {

    // Terminal statuses — no further transitions allowed
    const TERMINAL = ['served', 'left', 'expired'];

    // =========================================================
    // READ HELPERS
    // =========================================================

    public static function getService(string $serviceId): ?array {
        return firestore_getDocument("services/$serviceId");
    }

    public static function getEntries(string $serviceId, ?string $status = null, int $limit = 200): array {
        $query = [
            'from'    => [['collectionId' => 'entries']],
            'orderBy' => [['field' => ['fieldPath' => 'joinedAt'], 'direction' => 'ASCENDING']],
            'limit'   => $limit,
        ];
        if ($status !== null) {
            $query['where'] = ['fieldFilter' => [
                'field' => ['fieldPath' => 'status'],
                'op'    => 'EQUAL',
                'value' => ['stringValue' => $status],
            ]];
        }
        $rows    = firestore_runQueryWithParent("services/$serviceId", $query);
        $entries = [];
        foreach ($rows as $row) {
            if (empty($row['document'])) continue;
            $doc  = $row['document'];
            $data = firestore_unpack_fields($doc['fields'] ?? []);
            $data['_id']   = basename($doc['name']);
            $data['_path'] = "services/$serviceId/entries/" . $data['_id'];
            $entries[]     = $data;
        }
        return $entries;
    }

    public static function getEntry(string $serviceId, string $entryId): ?array {
        $data = firestore_getDocument("services/$serviceId/entries/$entryId");
        if ($data) {
            $data['_id']   = $entryId;
            $data['_path'] = "services/$serviceId/entries/$entryId";
        }
        return $data;
    }

    // =========================================================
    // syncServiceState — authoritative post-action reconciler
    // Call this after EVERY queue mutation.
    // Derives truth from entry docs; patches service doc.
    // =========================================================
    public static function syncServiceState(string $serviceId): void {
        try {
            $service = self::getService($serviceId);
            if (!$service) return;

            // Read all active entries
            $allEntries  = self::getEntries($serviceId, null, 500);
            $pending = []; $active = []; $called = [];

            foreach ($allEntries as $e) {
                $s = $e['status'] ?? '';
                if ($s === 'pending') $pending[] = $e;
                if ($s === 'active')  $active[]  = $e;
                if ($s === 'called')  $called[]  = $e;
            }

            // Sort pending oldest-first
            usort($pending, fn($a, $b) => strcmp($a['joinedAt'] ?? '', $b['joinedAt'] ?? ''));

            $headPendingId = !empty($pending) ? $pending[0]['_id'] : null;
            $activeId      = !empty($active)  ? $active[0]['_id']  : null;

            // Determine valid called entry (must not be expired)
            $calledId      = null;
            $callExpiresAt = null;
            if (!empty($called)) {
                // Most recently called wins
                usort($called, fn($a, $b) => strcmp($b['calledAt'] ?? '', $a['calledAt'] ?? ''));
                $top = $called[0];
                $exp = $top['callExpiresAt'] ?? null;
                if (!$exp || strtotime($exp) > time()) {
                    $calledId      = $top['_id'];
                    $callExpiresAt = $exp ? ['timestampValue' => $exp] : null;
                }
                // If expired: mark as expired (async — best effort)
                foreach ($called as $c) {
                    $cExp = $c['callExpiresAt'] ?? null;
                    if ($cExp && strtotime($cExp) <= time()) {
                        try {
                            firestore_updateDocument($c['_path'], [
                                'status'    => 'expired',
                                'expiredAt' => fs_timestamp_now(),
                            ]);
                        } catch (Throwable $e) {}
                        if ($c['_id'] === $calledId) {
                            $calledId = null; $callExpiresAt = null;
                        }
                    }
                }
            }

            $patch = [
                'pendingCount'       => count($pending),
                'activeCount'        => count($active),
                'headPendingEntryId' => $headPendingId,
                'activeEntryId'      => $activeId,
                'calledEntryId'      => $calledId,
                'callExpiresAt'      => $callExpiresAt,
                'lastUpdatedAt'      => fs_timestamp_now(),
            ];

            firestore_updateDocument("services/$serviceId", $patch);
        } catch (Throwable $e) {
            error_log('QueueService::syncServiceState error: ' . $e->getMessage());
        }
    }

    // =========================================================
    // CALL HEAD
    // =========================================================
    public static function callHead(string $serviceId, int $windowSeconds = 120): array {
        $service = self::getService($serviceId);
        if (!$service) return ['success' => false, 'message' => 'Service not found'];

        // Block if active entry exists
        if (!empty($service['activeEntryId'])) {
            return ['success' => false, 'message' => 'Cannot call next: an entry is currently active. Mark it served or left first.'];
        }

        // Block if unexpired called entry exists
        $existingCalledId = $service['calledEntryId'] ?? null;
        if ($existingCalledId) {
            $exp = $service['callExpiresAt'] ?? null;
            if ($exp && strtotime($exp) > time()) {
                return ['success' => false, 'message' => 'An unexpired called entry already exists. Use recall or expire it first.'];
            }
            // Expired call: clean it up before proceeding
            $staleEntry = self::getEntry($serviceId, $existingCalledId);
            if ($staleEntry && ($staleEntry['status'] ?? '') === 'called') {
                firestore_updateDocument($staleEntry['_path'], ['status' => 'expired', 'expiredAt' => fs_timestamp_now()]);
            }
        }

        // Find head pending entry
        $headId = $service['headPendingEntryId'] ?? null;
        $entry  = null;
        if ($headId) {
            $entry = self::getEntry($serviceId, $headId);
            if (!$entry || ($entry['status'] ?? '') !== 'pending') {
                $headId = null; $entry = null;
            }
        }
        if (!$entry) {
            $pending = self::getEntries($serviceId, 'pending', 1);
            if (empty($pending)) return ['success' => false, 'message' => 'No pending entries in queue'];
            $entry  = $pending[0];
            $headId = $entry['_id'];
        }

        $expiresAt = gmdate('c', time() + $windowSeconds);
        $callerUid = $_SESSION['user_id'] ?? 'staff';

        firestore_updateDocument($entry['_path'], [
            'status'        => 'called',
            'calledAt'      => fs_timestamp_now(),
            'calledBy'      => $callerUid,
            'callExpiresAt' => ['timestampValue' => $expiresAt],
            'checkInBy'     => ['timestampValue' => $expiresAt],
        ]);

        AuditService::log('QUEUE_CALL_HEAD', $entry['_path'], ['status' => 'pending'], ['status' => 'called', 'expiresAt' => $expiresAt], '', $serviceId, $headId);

        // Sync derives new head, clears old called ref, updates counts
        self::syncServiceState($serviceId);

        return ['success' => true, 'message' => 'Entry called', 'entryId' => $headId];
    }

    // =========================================================
    // RECALL HEAD
    // =========================================================
    public static function recallHead(string $serviceId, int $windowSeconds = 120): array {
        $service  = self::getService($serviceId);
        if (!$service) return ['success' => false, 'message' => 'Service not found'];

        $calledId = $service['calledEntryId'] ?? null;
        if (!$calledId) return ['success' => false, 'message' => 'No entry currently called'];

        $entry = self::getEntry($serviceId, $calledId);
        if (!$entry || ($entry['status'] ?? '') !== 'called') {
            return ['success' => false, 'message' => 'Called entry not in called state'];
        }

        $expiresAt = gmdate('c', time() + $windowSeconds);

        firestore_updateDocument($entry['_path'], [
            'calledAt'      => fs_timestamp_now(),
            'calledBy'      => $_SESSION['user_id'] ?? 'staff',
            'callExpiresAt' => ['timestampValue' => $expiresAt],
            'checkInBy'     => ['timestampValue' => $expiresAt],
            'recallCount'   => (int)($entry['recallCount'] ?? 0) + 1,
        ]);

        AuditService::log('QUEUE_RECALL_HEAD', $entry['_path'], [], ['recalledAt' => gmdate('c')], '', $serviceId, $calledId);
        self::syncServiceState($serviceId);
        return ['success' => true, 'message' => 'Entry recalled'];
    }

    // =========================================================
    // CHECK IN CALLED (called → active)
    // =========================================================
    public static function checkInCalled(string $serviceId): array {
        $service  = self::getService($serviceId);
        if (!$service) return ['success' => false, 'message' => 'Service not found'];

        $calledId = $service['calledEntryId'] ?? null;
        if (!$calledId) return ['success' => false, 'message' => 'No entry currently called'];

        $entry = self::getEntry($serviceId, $calledId);
        if (!$entry || ($entry['status'] ?? '') !== 'called') {
            return ['success' => false, 'message' => 'Called entry is not in called state'];
        }

        // Enforce check-in window
        $exp = $service['callExpiresAt'] ?? null;
        if ($exp && strtotime($exp) < time()) {
            return ['success' => false, 'message' => 'Check-in window has expired. Please expire and call next.'];
        }

        // Hard block: another active entry exists (v6: never silently replace)
        $prevActiveId = $service['activeEntryId'] ?? null;
        if ($prevActiveId && $prevActiveId !== $calledId) {
            return ['success' => false, 'message' => 'Another entry is currently active. Mark it served or left before checking in a new one.'];
        }

        firestore_updateDocument($entry['_path'], [
            'status'      => 'active',
            'checkedInAt' => fs_timestamp_now(),
            'checkedInBy' => $_SESSION['user_id'] ?? 'staff',
        ]);

        AuditService::log('QUEUE_CHECK_IN', $entry['_path'], ['status' => 'called'], ['status' => 'active'], '', $serviceId, $calledId);
        self::syncServiceState($serviceId);
        return ['success' => true, 'message' => 'Entry checked in and now active'];
    }

    // =========================================================
    // MARK SERVED (active → served; admin can serve any non-terminal)
    // =========================================================
    public static function markServed(string $serviceId, string $entryId, bool $adminOverride = false, string $reason = ''): array {
        $entry = self::getEntry($serviceId, $entryId);
        if (!$entry) return ['success' => false, 'message' => 'Entry not found'];

        $status = $entry['status'] ?? '';

        // Block terminal statuses for everyone
        if (in_array($status, self::TERMINAL)) {
            return ['success' => false, 'message' => "Entry is already in terminal state: $status"];
        }

        // Staff: only active entries
        if (!$adminOverride && $status !== 'active') {
            return ['success' => false, 'message' => "Only active entries can be marked served (current: $status). Use admin override if needed."];
        }

        // Admin override requires a reason
        if ($adminOverride && $status !== 'active' && !$reason) {
            return ['success' => false, 'message' => 'Admin override requires a reason'];
        }

        firestore_updateDocument($entry['_path'], [
            'status'   => 'served',
            'servedAt' => fs_timestamp_now(),
            'servedBy' => $_SESSION['user_id'] ?? 'staff',
        ]);

        AuditService::log(
            'QUEUE_MARK_SERVED', $entry['_path'],
            ['status' => $status], ['status' => 'served'],
            $reason, $serviceId, $entryId,
            ['override' => $adminOverride, 'dangerous' => $adminOverride && $status !== 'active']
        );

        self::syncServiceState($serviceId);
        return ['success' => true, 'message' => 'Entry marked as served'];
    }

    // =========================================================
    // MARK LEFT (semantic reasons)
    // =========================================================
    const LEFT_REASONS = [
        'called_no_show'    => 'Called but did not check in',
        'active_abandoned'  => 'Active session abandoned by user',
        'pending_left'      => 'Left queue while waiting',
        'admin_removed'     => 'Removed by administrator',
        'repair_cleanup'    => 'Removed during queue repair',
    ];

    public static function markLeft(string $serviceId, string $entryId, string $reason = 'pending_left'): array {
        $entry = self::getEntry($serviceId, $entryId);
        if (!$entry) return ['success' => false, 'message' => 'Entry not found'];

        $status = $entry['status'] ?? '';

        // Block terminal statuses
        if (in_array($status, self::TERMINAL)) {
            return ['success' => false, 'message' => "Cannot mark left: entry is already in terminal state: $status"];
        }

        // Validate reason
        if (!array_key_exists($reason, self::LEFT_REASONS)) {
            $reason = 'pending_left';
        }

        // Restrict harsher reasons to admin
        if ($reason === 'admin_removed' && !isAdmin()) {
            return ['success' => false, 'message' => 'admin_removed reason requires admin privilege'];
        }

        firestore_updateDocument($entry['_path'], [
            'status'     => 'left',
            'leftAt'     => fs_timestamp_now(),
            'leftReason' => $reason,
        ]);

        AuditService::log('QUEUE_MARK_LEFT', $entry['_path'], ['status' => $status], ['status' => 'left', 'reason' => $reason], $reason, $serviceId, $entryId);
        self::syncServiceState($serviceId);
        return ['success' => true, 'message' => 'Entry marked as left (' . self::LEFT_REASONS[$reason] . ')'];
    }

    // =========================================================
    // EXPIRE CALLED
    // Normal: only if call window has actually passed
    // Early/forced: admin only with reason
    // =========================================================
    public static function expireCalled(string $serviceId, bool $forceExpire = false, string $reason = ''): array {
        $service  = self::getService($serviceId);
        if (!$service) return ['success' => false, 'message' => 'Service not found'];

        $calledId = $service['calledEntryId'] ?? null;
        if (!$calledId) return ['success' => false, 'message' => 'No called entry to expire'];

        $entry = self::getEntry($serviceId, $calledId);
        if (!$entry) return ['success' => false, 'message' => 'Called entry not found'];

        $exp = $service['callExpiresAt'] ?? null;
        $isActuallyExpired = $exp && strtotime($exp) <= time();

        // Normal staff: only expire if window has passed
        if (!$isActuallyExpired && !$forceExpire) {
            return ['success' => false, 'message' => 'Call window has not expired yet. Use "Force Expire" (admin) to expire early.'];
        }

        // Force expire (early): admin only + reason required
        if ($forceExpire && !$isActuallyExpired) {
            if (!isAdmin()) {
                return ['success' => false, 'message' => 'Force expire requires admin privilege'];
            }
            if (!$reason) {
                return ['success' => false, 'message' => 'Force expire requires a reason'];
            }
        }

        firestore_updateDocument($entry['_path'], [
            'status'    => 'expired',
            'expiredAt' => fs_timestamp_now(),
        ]);

        AuditService::log(
            'QUEUE_EXPIRE_CALLED', $entry['_path'],
            ['status' => 'called'], ['status' => 'expired'],
            $reason ?: 'call_window_passed', $serviceId, $calledId,
            ['override' => $forceExpire, 'dangerous' => $forceExpire && !$isActuallyExpired]
        );

        // syncServiceState recalculates head and clears call refs
        self::syncServiceState($serviceId);
        return ['success' => true, 'message' => 'Called entry expired. Queue head recalculated.'];
    }

    // =========================================================
    // REPAIR SERVICE — structured diagnostics, no fake outcomes
    // =========================================================
    public static function repairService(string $serviceId): array {
        $service = self::getService($serviceId);
        if (!$service) return ['success' => false, 'message' => 'Service not found'];

        $allEntries = self::getEntries($serviceId, null, 500);

        $pending = []; $active = []; $called = [];
        foreach ($allEntries as $e) {
            $s = $e['status'] ?? '';
            if ($s === 'pending') $pending[] = $e;
            if ($s === 'active')  $active[]  = $e;
            if ($s === 'called')  $called[]  = $e;
        }

        $issues = [];
        $fixes  = [];

        // Multiple active entries: mark extras as left (with repair reason), not served
        if (count($active) > 1) {
            $issues[] = 'Multiple active entries detected (' . count($active) . ')';
            usort($active, fn($a,$b) => strcmp($b['checkedInAt'] ?? '', $a['checkedInAt'] ?? ''));
            for ($i = 1; $i < count($active); $i++) {
                firestore_updateDocument($active[$i]['_path'], [
                    'status'     => 'left',
                    'leftAt'     => fs_timestamp_now(),
                    'leftReason' => 'repair_cleanup',
                ]);
                $fixes[] = 'Marked duplicate active ' . $active[$i]['_id'] . ' as left (repair_cleanup)';
            }
            $active = [$active[0]];
        }

        // Multiple called entries: expire extras
        if (count($called) > 1) {
            $issues[] = 'Multiple called entries (' . count($called) . ')';
            usort($called, fn($a,$b) => strcmp($b['calledAt'] ?? '', $a['calledAt'] ?? ''));
            for ($i = 1; $i < count($called); $i++) {
                firestore_updateDocument($called[$i]['_path'], ['status' => 'expired', 'expiredAt' => fs_timestamp_now()]);
                $fixes[] = 'Expired duplicate called ' . $called[$i]['_id'];
            }
            $called = [$called[0]];
        }

        // Stale called entry
        if (!empty($called)) {
            $c   = $called[0];
            $exp = $c['callExpiresAt'] ?? null;
            if ($exp && strtotime($exp) <= time()) {
                firestore_updateDocument($c['_path'], ['status' => 'expired', 'expiredAt' => fs_timestamp_now()]);
                $fixes[]  = 'Auto-expired stale called ' . $c['_id'];
                $issues[] = 'Stale called entry expired';
                $called   = [];
            }
        }

        // Ref mismatches
        $computedActiveId = !empty($active) ? $active[0]['_id'] : null;
        $computedCalledId = !empty($called) ? $called[0]['_id'] : null;
        if (($service['activeEntryId'] ?? null) !== $computedActiveId) {
            $issues[] = 'activeEntryId mismatch';
        }
        if (($service['calledEntryId'] ?? null) !== $computedCalledId) {
            $issues[] = 'calledEntryId mismatch';
        }

        // Rebuild pending order
        usort($pending, fn($a,$b) => strcmp($a['joinedAt'] ?? '', $b['joinedAt'] ?? ''));
        $computedHead = !empty($pending) ? $pending[0]['_id'] : null;
        if (($service['headPendingEntryId'] ?? null) !== $computedHead) {
            $issues[] = 'headPendingEntryId mismatch';
        }

        // Apply authoritative sync
        self::syncServiceState($serviceId);
        $fixes[] = 'syncServiceState applied';

        AuditService::log('QUEUE_REPAIR_SERVICE', "services/$serviceId", $service, [], 'Admin repair', $serviceId, null,
            ['issuesFound' => $issues, 'fixesApplied' => $fixes]);

        return [
            'success'      => true,
            'message'      => 'Repair complete',
            'pendingCount' => count($pending),
            'activeCount'  => count($active),
            'calledCount'  => count($called),
            'issuesFound'  => $issues,
            'fixesApplied' => $fixes,
        ];
    }

    // =========================================================
    // PURGE ENTRY (hard delete, admin only)
    // =========================================================
    public static function purgeEntry(string $serviceId, string $entryId, string $reason = ''): array {
        if (!$reason) return ['success' => false, 'message' => 'Purge requires a reason'];

        $entry = self::getEntry($serviceId, $entryId);
        if (!$entry) return ['success' => false, 'message' => 'Entry not found'];

        AuditService::log('QUEUE_PURGE_ENTRY', $entry['_path'], $entry, [], $reason, $serviceId, $entryId,
            ['dangerous' => true, 'override' => true]);

        firestore_deleteDocument($entry['_path']);

        // Sync clears any refs to this entry
        self::syncServiceState($serviceId);
        return ['success' => true, 'message' => 'Entry purged and service state synced'];
    }
}
