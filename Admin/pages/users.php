<?php
ini_set('display_errors', 0);
error_reporting(0);

require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_STAFF);
require_once __DIR__ . '/../config/firestore_rest.php';
require_once __DIR__ . '/../services/UserService.php';

$pageTitle = 'Staff & Users';
include __DIR__ . '/../includes/header.php';

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

$users = []; $services = []; $flash = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST' && verifyCSRFToken($_POST['csrf_token'] ?? '')) {
    $uid = trim($_POST['uid'] ?? '');
    if ($uid && isAdmin()) {
        $pAction = $_POST['action'] ?? '';
        if ($pAction === 'update_user') {
            $sIds  = array_values(array_filter(explode(',', $_POST['service_ids'] ?? '')));
            $perms = [];
            foreach (KNOWN_PERMISSIONS as $p) {
                $perms[$p] = !empty($_POST["perm_$p"]);
            }
            $flash = UserService::updateUserAdmin($uid, [
                'role'               => $_POST['new_role']  ?? 'staff',
                'isActive'           => ($_POST['is_active'] ?? '1') === '1',
                'assignedServiceIds' => $sIds,
                'permissions'        => $perms,
            ]);
        } elseif ($pAction === 'set_active') {
            $flash = UserService::setActive($uid, ($_POST['is_active'] ?? '0') === '1');
        }
    }
}

try {
    $users = UserService::getAllUsers();
    $sRows = firestore_runQuery(['from' => [['collectionId' => 'services']], 'limit' => 50]);
    foreach ($sRows as $r) {
        if (empty($r['document'])) continue;
        $d = firestore_unpack_fields($r['document']['fields'] ?? []);
        $d['_id'] = basename($r['document']['name']);
        $services[] = $d;
    }
} catch (Exception $e) { error_log('Users page: '.$e->getMessage()); }

$staffUsers   = array_values(array_filter($users, fn($u) => in_array($u['role'] ?? '', ['staff','admin'])));
$studentUsers = array_values(array_filter($users, fn($u) => ($u['role'] ?? '') === 'student'));
$csrf = generateCSRFToken();
?>

<div class="page-header">
  <div class="page-header-row">
    <div>
      <h1 class="page-title">Staff &amp; Users</h1>
      <p class="page-subtitle">Role management, permissions, and service assignments</p>
    </div>
  </div>
</div>

<?php if ($flash): ?>
<div class="alert alert-<?= $flash['success']?'success':'danger' ?>">
  <?= $flash['success']?'✅':'❌' ?> <?= h($flash['message'] ?? '') ?>
</div>
<?php endif; ?>

<div class="tabs" data-tabs>
  <button class="tab-btn active" data-tab="staff">Staff &amp; Admins (<?= count($staffUsers) ?>)</button>
  <button class="tab-btn" data-tab="students">Students (<?= count($studentUsers) ?>)</button>
</div>

<div data-tabs>
  <div class="tab-panel active" data-panel="staff">
    <div class="filter-bar">
      <div class="search-input-wrap">
        <span class="search-icon">🔍</span>
        <input class="search-input" type="search" placeholder="Search staff..." data-search="#staffTable">
      </div>
    </div>
    <div class="table-wrap">
      <table id="staffTable">
        <thead><tr>
          <th>Name</th><th>Email</th><th>Role</th><th>Status</th>
          <th>Assigned Services</th><th>Last Login</th>
          <?php if(isAdmin()): ?><th>Actions</th><?php endif; ?>
        </tr></thead>
        <tbody>
          <?php foreach ($staffUsers as $u):
            $uid = $u['_id'];
            $role = $u['role'] ?? 'staff';
            $isActive = $u['isActive'] ?? true;
            $assignedIds = is_array($u['assignedServiceIds'] ?? null) ? $u['assignedServiceIds'] : [];
            $perms = is_array($u['permissions'] ?? null) ? $u['permissions'] : [];
          ?>
          <tr data-searchable>
            <td>
              <div style="font-weight:600"><?= h($u['name'] ?? 'Unknown') ?></div>
              <div class="td-mono" style="font-size:.65rem"><?= h($uid) ?></div>
            </td>
            <td class="td-mono"><?= h($u['email'] ?? '—') ?></td>
            <td><span class="badge badge-<?= $role ?>"><?= ucfirst($role) ?></span></td>
            <td><?= $isActive ? '<span class="badge badge-open"><span class="pulse-dot green"></span> Active</span>' : '<span class="badge badge-closed">Inactive</span>' ?></td>
            <td>
              <?php if (empty($assignedIds)): ?>
                <span style="color:var(--c-text3);font-size:.75rem">All services</span>
              <?php else: ?>
                <span style="font-size:.75rem" title="<?= h(implode(', ', $assignedIds)) ?>"><?= count($assignedIds) ?> assigned</span>
              <?php endif; ?>
            </td>
            <td class="td-mono"><?= !empty($u['lastLoginAt']) ? date('M j, H:i', strtotime($u['lastLoginAt'])) : '—' ?></td>
            <?php if (isAdmin()): ?>
            <td>
              <button onclick="openUserModal(<?= json_encode([
                'uid'=>$uid,'name'=>$u['name']??'','role'=>$role,
                'isActive'=>(bool)$isActive,'assignedIds'=>$assignedIds,'permissions'=>$perms
              ]) ?>)" class="btn btn-ghost btn-sm">Edit</button>
            </td>
            <?php endif; ?>
          </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  </div>

  <div class="tab-panel" data-panel="students">
    <div class="table-wrap">
      <table id="studentsTable">
        <thead><tr><th>Name</th><th>Email</th><th>Status</th><th>Joined</th><?php if(isAdmin()): ?><th>Actions</th><?php endif; ?></tr></thead>
        <tbody>
          <?php foreach ($studentUsers as $u):
            $uid = $u['_id']; $isActive = $u['isActive'] ?? true; ?>
          <tr data-searchable>
            <td><div style="font-weight:600"><?= h($u['name'] ?? 'Unknown') ?></div><div class="td-mono" style="font-size:.65rem"><?= h($uid) ?></div></td>
            <td class="td-mono"><?= h($u['email'] ?? '—') ?></td>
            <td><?= $isActive ? '<span class="badge badge-open">Active</span>' : '<span class="badge badge-closed">Blocked</span>' ?></td>
            <td class="td-mono"><?= !empty($u['createdAt']) ? date('M j, Y', strtotime($u['createdAt'])) : '—' ?></td>
            <?php if (isAdmin()): ?>
            <td>
              <form method="POST" style="display:inline">
                <input type="hidden" name="csrf_token" value="<?= h($csrf) ?>">
                <input type="hidden" name="action" value="set_active">
                <input type="hidden" name="uid" value="<?= h($uid) ?>">
                <input type="hidden" name="is_active" value="<?= $isActive ? '0' : '1' ?>">
                <button type="submit" class="btn btn-<?= $isActive?'danger':'success' ?> btn-sm"><?= $isActive ? '🚫 Block' : '✅ Unblock' ?></button>
              </form>
            </td>
            <?php endif; ?>
          </tr>
          <?php endforeach; ?>
          <?php if (empty($studentUsers)): ?><tr><td colspan="5" style="text-align:center;padding:40px;color:var(--c-text3)">No students found</td></tr><?php endif; ?>
        </tbody>
      </table>
    </div>
  </div>
</div>

<!-- Unified Edit Modal: saves ALL fields in one POST -->
<div class="modal-overlay" id="userModal">
  <div class="modal" style="max-width:580px">
    <div class="modal-header">
      <span class="modal-title" id="userModalTitle">Edit User</span>
      <button class="modal-close" data-close-modal>✕</button>
    </div>
    <form method="POST" id="userForm">
      <div class="modal-body">
        <input type="hidden" name="csrf_token" value="<?= h($csrf) ?>">
        <input type="hidden" name="action" value="update_user">
        <input type="hidden" name="uid" id="userUid">

        <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
          <div class="form-group">
            <label class="form-label">Role</label>
            <select class="form-control" name="new_role" id="userRole">
              <option value="staff">Staff</option>
              <option value="admin">Admin</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Account Status</label>
            <select class="form-control" name="is_active" id="userIsActive">
              <option value="1">Active</option>
              <option value="0">Inactive</option>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">Assigned Services <span class="form-hint" style="display:inline">(empty = all services)</span></label>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:6px">
            <?php foreach ($services as $svc): ?>
            <label style="display:flex;align-items:center;gap:8px;font-size:.8rem;cursor:pointer;padding:7px 10px;background:var(--c-surface2);border-radius:6px;border:1px solid var(--c-border)">
              <input type="checkbox" class="svc-checkbox" value="<?= h($svc['_id']) ?>" style="accent-color:var(--c-primary)">
              <?= h($svc['name'] ?? $svc['_id']) ?>
            </label>
            <?php endforeach; ?>
          </div>
          <input type="hidden" name="service_ids" id="serviceIdsInput">
        </div>

        <div class="form-group">
          <label class="form-label">Granular Permissions</label>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:6px">
            <?php
            $permLabels = [
              'canRepairQueue'      => '🔧 Repair Queue',
              'canPurgeEntry'       => '🗑 Purge Entries',
              'canManageUsers'      => '👥 Manage Users',
              'canManageCameras'    => '📷 Manage Cameras',
              'canManageServices'   => '⚙️ Manage Services',
              'canExportAudit'      => '📋 Export Audit',
              'canOperateAllServices'=> '🌐 All Services',
            ];
            foreach ($permLabels as $pKey => $pLabel): ?>
            <label style="display:flex;align-items:center;gap:8px;font-size:.8rem;cursor:pointer;padding:7px 10px;background:var(--c-surface2);border-radius:6px;border:1px solid var(--c-border)">
              <input type="checkbox" name="perm_<?= $pKey ?>" value="1" class="perm-checkbox" data-perm="<?= $pKey ?>" style="accent-color:var(--c-primary)">
              <?= $pLabel ?>
            </label>
            <?php endforeach; ?>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" data-close-modal>Cancel</button>
        <button type="submit" class="btn btn-primary" onclick="prepareUserForm()">Save All Changes</button>
      </div>
    </form>
  </div>
</div>

<script>
function openUserModal(u) {
  document.getElementById('userModalTitle').textContent = 'Edit: ' + u.name;
  document.getElementById('userUid').value     = u.uid;
  document.getElementById('userRole').value    = u.role;
  document.getElementById('userIsActive').value = u.isActive ? '1' : '0';

  document.querySelectorAll('.svc-checkbox').forEach(cb => {
    cb.checked = Array.isArray(u.assignedIds) && u.assignedIds.includes(cb.value);
  });
  document.querySelectorAll('.perm-checkbox').forEach(cb => {
    cb.checked = u.permissions && u.permissions[cb.dataset.perm] === true;
  });

  document.getElementById('userModal').classList.add('open');
}

function prepareUserForm() {
  const ids = Array.from(document.querySelectorAll('.svc-checkbox:checked')).map(cb => cb.value);
  document.getElementById('serviceIdsInput').value = ids.join(',');
  // All other named inputs submit normally
}

// Tab system
document.querySelectorAll('[data-tabs] .tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    btn.closest('[data-tabs]').querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    const sibling = btn.closest('[data-tabs]').nextElementSibling;
    if (sibling) sibling.querySelectorAll('.tab-panel').forEach(p => {
      p.classList.toggle('active', p.dataset.panel === btn.dataset.tab);
    });
  });
});
</script>
<?php include __DIR__ . '/../includes/footer.php'; ?>
