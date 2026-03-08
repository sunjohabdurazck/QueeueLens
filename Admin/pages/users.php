<?php
// pages/users.php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_STAFF);

require_once __DIR__ . '/../config/firestore_rest.php';

$msg = null;
$err = null;

// -----------------------------
// CSRF (add if not present in config.php)
// -----------------------------
if (!function_exists('generateCSRFToken')) {
    function generateCSRFToken(): string {
        if (session_status() === PHP_SESSION_NONE) session_start();
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }
}
if (!function_exists('verifyCSRFToken')) {
    function verifyCSRFToken(string $token): bool {
        if (session_status() === PHP_SESSION_NONE) session_start();
        return !empty($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
    }
}

// -----------------------------
// Firestore pack value (if missing)
// -----------------------------
if (!function_exists('firestore_pack_value')) {
    function firestore_pack_value($v): array {
        if (is_string($v)) return ['stringValue' => $v];
        if (is_bool($v))   return ['booleanValue' => $v];
        if (is_int($v))    return ['integerValue' => (string)$v];
        if (is_float($v))  return ['doubleValue' => $v];
        if ($v === null)   return ['nullValue' => null];

        if (is_array($v)) {
            $isList = array_keys($v) === range(0, count($v) - 1);
            if ($isList) {
                return ['arrayValue' => ['values' => array_map('firestore_pack_value', $v)]];
            }
            $fields = [];
            foreach ($v as $k => $vv) $fields[$k] = firestore_pack_value($vv);
            return ['mapValue' => ['fields' => $fields]];
        }

        return ['stringValue' => (string)$v];
    }
}

// -----------------------------
// SAFE PATCH (fixes updateMask.fieldPaths[0] issue)
// -----------------------------
function firestore_patch_safe(string $docPath, array $fields): array {
    [$http, $accessToken] = firestore_client();

    $fsFields = [];
    foreach ($fields as $k => $v) $fsFields[$k] = firestore_pack_value($v);

    // repeated: updateMask.fieldPaths=a&updateMask.fieldPaths=b (NO indexes)
    $qs = [];
    foreach (array_keys($fsFields) as $p) {
        $qs[] = 'updateMask.fieldPaths=' . rawurlencode($p);
    }
    $queryString = implode('&', $qs);

    $res = $http->patch($docPath . '?' . $queryString, [
        'headers' => [
            'Authorization' => "Bearer $accessToken",
            'Content-Type'  => 'application/json',
        ],
        'json' => ['fields' => $fsFields],
    ]);

    return json_decode((string)$res->getBody(), true);
}

function firestore_delete_safe(string $docPath): void {
    [$http, $accessToken] = firestore_client();
    $http->delete($docPath, [
        'headers' => ['Authorization' => "Bearer $accessToken"]
    ]);
}

function nowIso(): string {
    return gmdate('c');
}

function extractIdFromDocName(string $name): string {
    $pos = strrpos($name, '/');
    return $pos === false ? $name : substr($name, $pos + 1);
}

function fmtLastLogin($v): string {
    if ($v instanceof DateTimeInterface) return $v->format('Y-m-d H:i');
    if (is_string($v)) {
        $t = strtotime($v);
        if ($t) return date('Y-m-d H:i', $t);
        return $v;
    }
    return '—';
}

// -----------------------------
// POST actions (admin only)
// -----------------------------
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {

    if (!hasRole(ROLE_ADMIN)) {
        $err = "Only admin can perform this action.";
    } elseif (!verifyCSRFToken($_POST['csrf_token'] ?? '')) {
        $err = "Invalid CSRF token.";
    } else {
        $action = $_POST['action'];
        $collection = strtolower(trim($_POST['collection'] ?? ''));
        $uid = trim($_POST['uid'] ?? '');

        if (!in_array($collection, ['users', 'students'], true)) {
            $err = "Invalid collection.";
        } elseif ($uid === '') {
            $err = "Missing uid.";
        } else {
            try {

                if ($action === 'update_role') {
                    if ($collection !== 'users') throw new Exception("Roles apply only to users.");

                    $newRole = strtolower(trim($_POST['role'] ?? ''));
                    if (!in_array($newRole, ['admin', 'staff'], true)) {
                        throw new Exception("Invalid role (use admin or staff).");
                    }

                    firestore_patch_safe("users/$uid", [
                        'role'      => $newRole,
                        'updatedAt' => nowIso(),
                    ]);

                    $msg = "✅ Role updated.";
                }

                elseif ($action === 'toggle_block') {
                    $block = ($_POST['block'] ?? '') === '1';

                    firestore_patch_safe("$collection/$uid", [
                        'isBlocked' => $block,
                        'blockedAt' => $block ? nowIso() : null,
                        'updatedAt' => nowIso(),
                    ]);

                    $msg = $block ? "🚫 Account blocked." : "✅ Account unblocked.";
                }

                elseif ($action === 'delete_account') {
                    // Delete completely from firestore
                    firestore_delete_safe("$collection/$uid");
                    $msg = "🗑️ Account deleted from $collection.";
                }

                else {
                    throw new Exception("Unknown action.");
                }

            } catch (Throwable $e) {
                $err = "Action failed: " . $e->getMessage();
            }
        }
    }
}

// -----------------------------
// GET filters
// -----------------------------
$q = trim($_GET['q'] ?? '');

// -----------------------------
// READ: users collection (admins/staff)
// -----------------------------
$users = [];
try {
    $rows = firestore_runQuery([
        "from" => [["collectionId" => "users"]],
        "limit" => 300
    ]);

    foreach ($rows as $row) {
        if (empty($row['document'])) continue;
        $doc = $row['document'];
        $id = extractIdFromDocName($doc['name'] ?? '');

        $data = firestore_unpack_fields($doc['fields'] ?? []);
        $data['_uid'] = $id;

        if ($q !== '') {
            $hay = strtolower(($data['name'] ?? '') . ' ' . ($data['email'] ?? '') . ' ' . $id);
            if (strpos($hay, strtolower($q)) === false) continue;
        }

        $users[] = $data;
    }
} catch (Throwable $e) {
    $err = $err ?: ("Failed to load users: " . $e->getMessage());
}

// -----------------------------
// READ: students collection
// -----------------------------
$students = [];
try {
    $rows = firestore_runQuery([
        "from" => [["collectionId" => "students"]],
        "limit" => 800
    ]);

    foreach ($rows as $row) {
        if (empty($row['document'])) continue;
        $doc = $row['document'];
        $docId = extractIdFromDocName($doc['name'] ?? '');

        $data = firestore_unpack_fields($doc['fields'] ?? []);
        // your students have 'uid' field, but docId is also uid
        $data['_uid'] = (string)($data['uid'] ?? $docId);

        if ($q !== '') {
            $hay = strtolower(
                ($data['name'] ?? '') . ' ' .
                ($data['email'] ?? '') . ' ' .
                ($data['studentID'] ?? '') . ' ' .
                ($data['_uid'] ?? '')
            );
            if (strpos($hay, strtolower($q)) === false) continue;
        }

        $students[] = $data;
    }
} catch (Throwable $e) {
    $err = $err ?: ("Failed to load students: " . $e->getMessage());
}

// Sort by name
$sortByName = function($a, $b) {
    return strcmp(strtolower((string)($a['name'] ?? '')), strtolower((string)($b['name'] ?? '')));
};
usort($users, $sortByName);
usort($students, $sortByName);

include __DIR__ . '/../includes/header.php';
?>

<div class="page-container">
  <div class="page-header">
    <div>
      <h1 class="page-title">👥 Users & Students</h1>
      <p class="page-subtitle">
        <code>users</code> = staff/admin. <code>students</code> = student accounts.
      </p>
    </div>
  </div>

  <?php if ($msg): ?><div class="alert alert-success"><?= htmlspecialchars($msg) ?></div><?php endif; ?>
  <?php if ($err): ?><div class="alert alert-danger"><?= htmlspecialchars($err) ?></div><?php endif; ?>

  <div class="card" style="margin-bottom:16px;">
    <div class="card-header" style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;">
      <h2 class="card-title">Search</h2>
      <form method="GET" action="<?= htmlspecialchars(BASE_URL) ?>/pages/users.php" style="display:flex; gap:10px; align-items:center; flex-wrap:wrap;">
        <input class="input" style="min-width:260px;" type="text" name="q" value="<?= htmlspecialchars($q) ?>" placeholder="Search name/email/uid/studentID…" />
        <button class="btn btn-primary" type="submit">🔎 Search</button>
        <a class="btn btn-secondary" href="<?= htmlspecialchars(BASE_URL) ?>/pages/users.php">↻ Reset</a>
      </form>
    </div>
  </div>

  <!-- USERS BLOCK -->
  <div class="card" style="margin-bottom:18px;">
    <div class="card-header">
      <h2 class="card-title">Users (Admin / Staff)</h2>
      <div style="opacity:.75; margin-top:6px;">Total: <b><?= count($users) ?></b></div>
    </div>

    <div class="card-content">
      <div class="table-responsive">
        <table class="table">
          <thead>
            <tr>
              <th>Name</th><th>Email</th><th>UID</th><th>Role</th><th>Status</th><th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <?php if (count($users) === 0): ?>
              <tr><td colspan="6" style="opacity:.8;">No users found.</td></tr>
            <?php endif; ?>

            <?php foreach ($users as $u): ?>
              <?php
                $uid = (string)($u['_uid'] ?? '');
                $name = (string)($u['name'] ?? '');
                $email= (string)($u['email'] ?? '');
                $role = strtolower((string)($u['role'] ?? 'staff'));
                $isBlocked = (bool)($u['isBlocked'] ?? false);
              ?>
              <tr>
                <td><?= htmlspecialchars($name ?: '—') ?></td>
                <td><?= htmlspecialchars($email ?: '—') ?></td>
                <td style="font-family: ui-monospace, Menlo, monospace; font-size:12px;"><?= htmlspecialchars($uid) ?></td>
                <td><span class="badge badge-warning"><?= htmlspecialchars($role) ?></span></td>
                <td><?= $isBlocked ? '<span class="badge badge-danger">blocked</span>' : '<span class="badge badge-success">active</span>' ?></td>
                <td>
                  <?php if (hasRole(ROLE_ADMIN)): ?>
                    <div style="display:flex; gap:6px; flex-wrap:wrap;">
                      <!-- Role -->
                      <form method="POST" action="<?= htmlspecialchars(BASE_URL) ?>/pages/users.php" style="display:flex; gap:6px; align-items:center;">
                        <input type="hidden" name="csrf_token" value="<?= htmlspecialchars(generateCSRFToken()) ?>">
                        <input type="hidden" name="collection" value="users">
                        <input type="hidden" name="action" value="update_role">
                        <input type="hidden" name="uid" value="<?= htmlspecialchars($uid) ?>">
                        <select name="role" class="input" style="min-width:110px;">
                          <option value="staff" <?= $role === 'staff' ? 'selected' : '' ?>>staff</option>
                          <option value="admin" <?= $role === 'admin' ? 'selected' : '' ?>>admin</option>
                        </select>
                        <button class="btn btn-small btn-primary" type="submit">Save</button>
                      </form>

                      <!-- Block -->
                      <form method="POST" action="<?= htmlspecialchars(BASE_URL) ?>/pages/users.php" onsubmit="return confirm('Change block status?');">
                        <input type="hidden" name="csrf_token" value="<?= htmlspecialchars(generateCSRFToken()) ?>">
                        <input type="hidden" name="collection" value="users">
                        <input type="hidden" name="action" value="toggle_block">
                        <input type="hidden" name="uid" value="<?= htmlspecialchars($uid) ?>">
                        <input type="hidden" name="block" value="<?= $isBlocked ? '0' : '1' ?>">
                        <button class="btn btn-small <?= $isBlocked ? 'btn-success' : 'btn-danger' ?>" type="submit">
                          <?= $isBlocked ? 'Unblock' : 'Block' ?>
                        </button>
                      </form>

                      <!-- Delete -->
                      <form method="POST" action="<?= htmlspecialchars(BASE_URL) ?>/pages/users.php" onsubmit="return confirm('Delete this user from Firestore?');">
                        <input type="hidden" name="csrf_token" value="<?= htmlspecialchars(generateCSRFToken()) ?>">
                        <input type="hidden" name="collection" value="users">
                        <input type="hidden" name="action" value="delete_account">
                        <input type="hidden" name="uid" value="<?= htmlspecialchars($uid) ?>">
                        <button class="btn btn-small btn-danger" type="submit">Delete</button>
                      </form>
                    </div>
                  <?php else: ?>
                    <span style="opacity:.65;">Admin only</span>
                  <?php endif; ?>
                </td>
              </tr>
            <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- STUDENTS BLOCK -->
  <div class="card">
    <div class="card-header">
      <h2 class="card-title">Students</h2>
      <div style="opacity:.75; margin-top:6px;">Total: <b><?= count($students) ?></b></div>
    </div>

    <div class="card-content">
      <div class="table-responsive">
        <table class="table">
          <thead>
            <tr>
              <th>Name</th><th>Email</th><th>Student ID</th><th>Department</th><th>Country</th><th>UID</th><th>Status</th><th>Last Login</th><th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <?php if (count($students) === 0): ?>
              <tr><td colspan="9" style="opacity:.8;">No students found.</td></tr>
            <?php endif; ?>

            <?php foreach ($students as $s): ?>
              <?php
                $uid = (string)($s['_uid'] ?? '');
                $name = (string)($s['name'] ?? '');
                $email= (string)($s['email'] ?? '');
                $studentID = (string)($s['studentID'] ?? '—');
                $dept = (string)($s['department'] ?? '—');
                $country = (string)($s['country'] ?? '—');
                $isBlocked = (bool)($s['isBlocked'] ?? false);
                $lastLoginText = fmtLastLogin($s['lastLoginAt'] ?? null);
              ?>
              <tr>
                <td><?= htmlspecialchars($name ?: '—') ?></td>
                <td><?= htmlspecialchars($email ?: '—') ?></td>
                <td><?= htmlspecialchars($studentID) ?></td>
                <td><?= htmlspecialchars($dept) ?></td>
                <td><?= htmlspecialchars($country) ?></td>
                <td style="font-family: ui-monospace, Menlo, monospace; font-size:12px;"><?= htmlspecialchars($uid) ?></td>
                <td><?= $isBlocked ? '<span class="badge badge-danger">blocked</span>' : '<span class="badge badge-success">active</span>' ?></td>
                <td><?= htmlspecialchars($lastLoginText) ?></td>
                <td>
                  <?php if (hasRole(ROLE_ADMIN)): ?>
                    <div style="display:flex; gap:6px; flex-wrap:wrap;">
                      <!-- Block -->
                      <form method="POST" action="<?= htmlspecialchars(BASE_URL) ?>/pages/users.php" onsubmit="return confirm('Change block status?');">
                        <input type="hidden" name="csrf_token" value="<?= htmlspecialchars(generateCSRFToken()) ?>">
                        <input type="hidden" name="collection" value="students">
                        <input type="hidden" name="action" value="toggle_block">
                        <input type="hidden" name="uid" value="<?= htmlspecialchars($uid) ?>">
                        <input type="hidden" name="block" value="<?= $isBlocked ? '0' : '1' ?>">
                        <button class="btn btn-small <?= $isBlocked ? 'btn-success' : 'btn-danger' ?>" type="submit">
                          <?= $isBlocked ? 'Unblock' : 'Block' ?>
                        </button>
                      </form>

                      <!-- Delete -->
                      <form method="POST" action="<?= htmlspecialchars(BASE_URL) ?>/pages/users.php" onsubmit="return confirm('Delete this student from Firestore?');">
                        <input type="hidden" name="csrf_token" value="<?= htmlspecialchars(generateCSRFToken()) ?>">
                        <input type="hidden" name="collection" value="students">
                        <input type="hidden" name="action" value="delete_account">
                        <input type="hidden" name="uid" value="<?= htmlspecialchars($uid) ?>">
                        <button class="btn btn-small btn-danger" type="submit">Delete</button>
                      </form>
                    </div>
                  <?php else: ?>
                    <span style="opacity:.65;">Admin only</span>
                  <?php endif; ?>
                </td>
              </tr>
            <?php endforeach; ?>
          </tbody>
        </table>
      </div>

      <div style="margin-top:12px; opacity:.75; font-size:12px;">
        Students are loaded from <code>students</code> collection (your Firebase structure).
      </div>
    </div>
  </div>

</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
