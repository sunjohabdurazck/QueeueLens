<?php
// services/UserService.php — v6

require_once __DIR__ . '/../config/firestore_rest.php';
require_once __DIR__ . '/../services/AuditService.php';

class UserService {

    public static function getAllUsers(int $limit = 200): array {
        $results = firestore_runQuery([
            'from'    => [['collectionId' => 'users']],
            'orderBy' => [['field' => ['fieldPath' => 'email'], 'direction' => 'ASCENDING']],
            'limit'   => $limit,
        ]);
        $users = [];
        foreach ($results as $row) {
            if (empty($row['document'])) continue;
            $d = firestore_unpack_fields($row['document']['fields'] ?? []);
            $d['_id'] = basename($row['document']['name']);
            $users[]  = $d;
        }
        return $users;
    }

    public static function getUser(string $uid): ?array {
        $data = firestore_getDocument("users/$uid");
        if ($data) $data['_id'] = $uid;
        return $data;
    }

    /**
     * Unified admin update — role, isActive, assignedServiceIds, permissions in one call.
     * Validates permission keys against whitelist. Prevents self-demotion/deactivation.
     */
    public static function updateUserAdmin(string $uid, array $fields): array {
        $before = self::getUser($uid);
        if (!$before) return ['success' => false, 'message' => 'User not found'];

        $actorUid = $_SESSION['user_id'] ?? '';

        if ($uid === $actorUid) {
            if (isset($fields['role']) && $fields['role'] !== 'admin') {
                return ['success' => false, 'message' => 'Cannot demote your own account'];
            }
            if (isset($fields['isActive']) && $fields['isActive'] === false) {
                return ['success' => false, 'message' => 'Cannot deactivate your own account'];
            }
        }

        // Whitelist permission keys
        if (isset($fields['permissions'])) {
            $filtered = [];
            foreach (KNOWN_PERMISSIONS as $key) {
                if (isset($fields['permissions'][$key])) {
                    $filtered[$key] = (bool)$fields['permissions'][$key];
                }
            }
            $fields['permissions'] = $filtered;
        }

        $allowed = ['role', 'isActive', 'assignedServiceIds', 'permissions'];
        $update  = array_intersect_key($fields, array_flip($allowed));
        $update['lastUpdatedAt'] = fs_timestamp_now();
        $update['updatedBy']     = $actorUid;

        firestore_updateDocument("users/$uid", $update);
        AuditService::log('USER_ADMIN_UPDATE', "users/$uid", $before, $update);
        return ['success' => true, 'message' => 'User updated'];
    }

    public static function updateRole(string $uid, string $newRole): array {
        return self::updateUserAdmin($uid, ['role' => $newRole]);
    }

    public static function setActive(string $uid, bool $isActive): array {
        return self::updateUserAdmin($uid, ['isActive' => $isActive]);
    }

    public static function assignServices(string $uid, array $serviceIds): array {
        return self::updateUserAdmin($uid, ['assignedServiceIds' => $serviceIds]);
    }

    public static function updatePermissions(string $uid, array $permissions): array {
        return self::updateUserAdmin($uid, ['permissions' => $permissions]);
    }
}
