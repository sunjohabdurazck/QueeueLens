<?php
ini_set('display_errors', 0);
error_reporting(0);

require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_STAFF);
require_once __DIR__ . '/../config/firestore_rest.php';
require_once __DIR__ . '/../services/AuditService.php';

$pageTitle = 'Services';
include __DIR__ . '/../includes/header.php';

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

$flash = null;

// Handle POST
if ($_SERVER['REQUEST_METHOD'] === 'POST' && verifyCSRFToken($_POST['csrf_token'] ?? '')) {
    $action = $_POST['action'] ?? '';

    try {
        switch ($action) {
            case 'create_service':
                if (isAdmin()) {
                    $doc = [
                        'name'               => trim($_POST['name'] ?? ''),
                        'description'        => trim($_POST['description'] ?? ''),
                        'isOpen'             => false,
                        'paused'             => false,
                        'pendingCount'       => 0,
                        'activeCount'        => 0,
                        'totalServed'        => 0,
                        'headPendingEntryId' => null,
                        'calledEntryId'      => null,
                        'callExpiresAt'      => null,
                        'activeEntryId'      => null,
                        'callWindowSeconds'  => (int)($_POST['callWindowSeconds'] ?? 120),
                        'maxPending'         => (int)($_POST['maxPending'] ?? 50),
                        'locationName'       => trim($_POST['locationName'] ?? ''),
                        'acceptingNewEntries'=> true,
                        'createdAt'          => fs_timestamp_now(),
                        'lastUpdatedAt'      => fs_timestamp_now(),
                        'createdBy'          => $_SESSION['user_id'] ?? 'admin',
                    ];
                    $result = firestore_createDocument('services', $doc);
                    AuditService::log('SERVICE_CREATE', 'services', [], $doc);
                    $flash = ['success'=>true, 'message'=>'Service created'];
                }
                break;

            case 'toggle_open':
                $svcId = $_POST['serviceId'] ?? '';
                $newState = ($_POST['new_state'] ?? '1') === '1';
                if ($svcId) {
                    firestore_updateDocument("services/$svcId", [
                        'isOpen'        => $newState,
                        'paused'        => false,
                        'lastUpdatedAt' => fs_timestamp_now(),
                    ]);
                    AuditService::log($newState?'SERVICE_OPEN':'SERVICE_CLOSE', "services/$svcId", [], ['isOpen'=>$newState], '', $svcId);
                    $flash = ['success'=>true,'message'=>'Service '.($newState?'opened':'closed')];
                }
                break;

            case 'toggle_pause':
                $svcId = $_POST['serviceId'] ?? '';
                $paused = ($_POST['paused'] ?? '1') === '1';
                if ($svcId) {
                    firestore_updateDocument("services/$svcId", ['paused'=>$paused,'lastUpdatedAt'=>fs_timestamp_now()]);
                    AuditService::log($paused?'SERVICE_PAUSE':'SERVICE_UNPAUSE', "services/$svcId", [], ['paused'=>$paused], '', $svcId);
                    $flash = ['success'=>true,'message'=>'Service '.($paused?'paused':'unpaused')];
                }
                break;

            case 'delete_service':
                if (isAdmin()) {
                    $svcId = $_POST['serviceId'] ?? '';
                    if ($svcId) {
                        AuditService::log('SERVICE_DELETE', "services/$svcId", [], [], $_POST['reason']??'', $svcId);
                        firestore_deleteDocument("services/$svcId");
                        $flash = ['success'=>true,'message'=>'Service deleted'];
                    }
                }
                break;
        }
    } catch (Exception $e) {
        $flash = ['success'=>false,'message'=>'Error: '.$e->getMessage()];
    }
}

$services = [];
try {
    $results = firestore_runQuery([
        "from"    => [["collectionId" => "services"]],
        "orderBy" => [["field" => ["fieldPath" => "name"], "direction" => "ASCENDING"]],
        "limit"   => 100
    ]);
    foreach ($results as $row) {
        if (empty($row['document'])) continue;
        $doc = $row['document'];
        $d = firestore_unpack_fields($doc['fields'] ?? []);
        $d['_id'] = basename($doc['name']);
        $services[] = $d;
    }
} catch(Exception $e) { error_log("Services page: ".$e->getMessage()); }

$csrf = generateCSRFToken();
?>

<div class="page-header">
  <div class="page-header-row">
    <div>
      <h1 class="page-title">Services</h1>
      <p class="page-subtitle">Queue service management and operational settings</p>
    </div>
    <?php if (isAdmin()): ?>
    <div class="header-actions">
      <button class="btn btn-primary" data-modal="createServiceModal">＋ New Service</button>
    </div>
    <?php endif; ?>
  </div>
</div>

<?php if ($flash): ?>
<div class="alert alert-<?= $flash['success']?'success':'danger' ?> mb-6">
  <?= $flash['success']?'✅':'❌' ?> <?= h($flash['message']) ?>
</div>
<?php endif; ?>

<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(360px,1fr));gap:18px">
<?php foreach ($services as $svc):
  $svcId = $svc['_id'];
  $isOpen = $svc['isOpen'] ?? false;
  $paused = $svc['paused'] ?? false;
  $pending = (int)($svc['pendingCount'] ?? 0);
  $active  = (int)($svc['activeCount'] ?? 0);
  $served  = (int)($svc['totalServed'] ?? 0);
  $callExp = $svc['callExpiresAt'] ?? null;
  $calledId= $svc['calledEntryId'] ?? null;
  $hasExpiredCall = $calledId && $callExp && strtotime($callExp) < time();
?>
<div class="card" style="<?= $hasExpiredCall?'border-color:rgba(248,113,113,.4)':'' ?>">
  <div class="card-header">
    <div>
      <div class="card-title"><?= h($svc['name'] ?? 'Service') ?></div>
      <div style="margin-top:5px;display:flex;gap:6px;flex-wrap:wrap">
        <?php if ($paused): ?>
          <span class="badge badge-pending">⏸ Paused</span>
        <?php elseif ($isOpen): ?>
          <span class="badge badge-open"><span class="pulse-dot green"></span> Open</span>
        <?php else: ?>
          <span class="badge badge-closed">● Closed</span>
        <?php endif; ?>
        <?php if ($hasExpiredCall): ?><span class="badge badge-expired">⏱ Call Expired</span><?php endif; ?>
      </div>
    </div>
    <?php if (isAdmin()): ?>
    <div class="flex gap-2">
      <button onclick="document.getElementById('editModal_<?= h($svcId) ?>').classList.add('open')" class="btn btn-ghost btn-sm btn-icon" title="Settings">⚙</button>
    </div>
    <?php endif; ?>
  </div>

  <?php if (!empty($svc['description'])): ?>
  <div style="padding:10px 20px;font-size:.8rem;color:var(--c-text2);border-bottom:1px solid var(--c-border)"><?= h($svc['description']) ?></div>
  <?php endif; ?>

  <div class="qsc-counters">
    <div class="qsc-counter"><div class="qsc-counter-val pending"><?= $pending ?></div><div class="qsc-counter-label">Pending</div></div>
    <div class="qsc-counter"><div class="qsc-counter-val called"><?= $calledId ? 1 : 0 ?></div><div class="qsc-counter-label">Called</div></div>
    <div class="qsc-counter"><div class="qsc-counter-val active"><?= $active ?></div><div class="qsc-counter-label">Active</div></div>
    <div class="qsc-counter"><div class="qsc-counter-val" style="color:var(--c-text3)"><?= number_format($served) ?></div><div class="qsc-counter-label">Total Served</div></div>
  </div>

  <?php if (!empty($svc['locationName'])): ?>
  <div style="padding:8px 16px;font-size:.72rem;color:var(--c-text3);border-bottom:1px solid var(--c-border)">📍 <?= h($svc['locationName']) ?></div>
  <?php endif; ?>

  <div style="padding:14px 16px;display:flex;gap:6px;flex-wrap:wrap">
    <a href="<?= BASE_PATH ?>/pages/queue.php?service=<?= h($svcId) ?>" class="btn btn-outline btn-sm">📋 Manage Queue</a>
    <form method="POST" style="display:inline">
      <input type="hidden" name="csrf_token" value="<?= h($csrf) ?>">
      <input type="hidden" name="action" value="toggle_open">
      <input type="hidden" name="serviceId" value="<?= h($svcId) ?>">
      <input type="hidden" name="new_state" value="<?= $isOpen?'0':'1' ?>">
      <button type="submit" class="btn btn-<?= $isOpen?'danger':'success' ?> btn-sm">
        <?= $isOpen ? '⏹ Close' : '▶ Open' ?>
      </button>
    </form>
    <form method="POST" style="display:inline">
      <input type="hidden" name="csrf_token" value="<?= h($csrf) ?>">
      <input type="hidden" name="action" value="toggle_pause">
      <input type="hidden" name="serviceId" value="<?= h($svcId) ?>">
      <input type="hidden" name="paused" value="<?= $paused?'0':'1' ?>">
      <button type="submit" class="btn btn-ghost btn-sm"><?= $paused?'▶ Unpause':'⏸ Pause' ?></button>
    </form>
  </div>
</div>

<?php if (isAdmin()): ?>
<!-- Edit Modal for this service -->
<div class="modal-overlay" id="editModal_<?= h($svcId) ?>">
  <div class="modal">
    <div class="modal-header">
      <span class="modal-title">⚙ Edit: <?= h($svc['name'] ?? 'Service') ?></span>
      <button class="modal-close" data-close-modal>✕</button>
    </div>
    <div class="modal-body">
      <div class="tabs" data-tabs="edit_<?= h($svcId) ?>">
        <button class="tab-btn active" data-tab="overview_<?= h($svcId) ?>">Overview</button>
        <button class="tab-btn" data-tab="settings_<?= h($svcId) ?>">Settings</button>
        <button class="tab-btn" data-tab="danger_<?= h($svcId) ?>">Danger</button>
      </div>
      <div data-tabs="edit_<?= h($svcId) ?>">
        <div class="tab-panel active" data-panel="overview_<?= h($svcId) ?>">
          <div class="grid-2">
            <div><div class="stat-label">Pending</div><div class="stat-value amber"><?= $pending ?></div></div>
            <div><div class="stat-label">Active</div><div class="stat-value green"><?= $active ?></div></div>
            <div><div class="stat-label">Total Served</div><div class="stat-value purple"><?= $served ?></div></div>
            <div><div class="stat-label">Call Window</div><div class="stat-value blue"><?= (int)($svc['callWindowSeconds']??120) ?>s</div></div>
          </div>
          <div class="divider"></div>
          <div style="font-size:.75rem;color:var(--c-text3)">
            <div>Head Pending: <code style="color:var(--c-text2)"><?= h($svc['headPendingEntryId'] ?? '—') ?></code></div>
            <div style="margin-top:4px">Called: <code style="color:var(--c-text2)"><?= h($svc['calledEntryId'] ?? '—') ?></code></div>
            <div style="margin-top:4px">Active: <code style="color:var(--c-text2)"><?= h($svc['activeEntryId'] ?? '—') ?></code></div>
          </div>
        </div>
        <div class="tab-panel" data-panel="settings_<?= h($svcId) ?>">
          <p style="color:var(--c-text2);font-size:.8rem">Queue repair tools:</p>
          <div style="margin-top:12px;display:flex;flex-direction:column;gap:8px">
            <button onclick="queueAction('repair','<?= h($svcId) ?>');this.closest('.modal-overlay').classList.remove('open')" class="btn btn-warning w-full">🔧 Repair &amp; Recalculate Queue State</button>
            <button onclick="queueAction('expire_called','<?= h($svcId) ?>');this.closest('.modal-overlay').classList.remove('open')" class="btn btn-ghost w-full">⏱ Force Expire Called Entry</button>
          </div>
        </div>
        <div class="tab-panel" data-panel="danger_<?= h($svcId) ?>">
          <div class="alert alert-danger" style="font-size:.78rem">Deleting a service is irreversible. All entries will be orphaned.</div>
          <form method="POST">
            <input type="hidden" name="csrf_token" value="<?= h($csrf) ?>">
            <input type="hidden" name="action" value="delete_service">
            <input type="hidden" name="serviceId" value="<?= h($svcId) ?>">
            <div class="form-group">
              <label class="form-label">Reason for deletion</label>
              <input class="form-control" name="reason" required placeholder="Why are you deleting this service?">
            </div>
            <button type="submit" class="btn btn-danger w-full" onclick="return confirm('Permanently delete <?= addslashes(h($svc['name']??'this service')) ?>?')">🗑 Delete Service Permanently</button>
          </form>
        </div>
      </div>
    </div>
  </div>
</div>
<?php endif; ?>

<?php endforeach; ?>

<?php if (empty($services)): ?>
<div class="empty-state" style="grid-column:1/-1">
  <div class="empty-state-icon">🏢</div>
  <div class="empty-state-title">No services yet</div>
  <div class="empty-state-text">Create your first service to get started.</div>
</div>
<?php endif; ?>
</div>

<!-- Create Service Modal -->
<?php if (isAdmin()): ?>
<div class="modal-overlay" id="createServiceModal">
  <div class="modal">
    <div class="modal-header">
      <span class="modal-title">＋ Create New Service</span>
      <button class="modal-close" data-close-modal>✕</button>
    </div>
    <form method="POST">
      <div class="modal-body">
        <input type="hidden" name="csrf_token" value="<?= h($csrf) ?>">
        <input type="hidden" name="action" value="create_service">
        <div class="form-group">
          <label class="form-label">Service Name *</label>
          <input class="form-control" name="name" required placeholder="e.g. Library Print Service">
        </div>
        <div class="form-group">
          <label class="form-label">Description</label>
          <textarea class="form-control" name="description" rows="2" placeholder="Brief description..."></textarea>
        </div>
        <div class="grid-2">
          <div class="form-group">
            <label class="form-label">Location</label>
            <input class="form-control" name="locationName" placeholder="e.g. Building A, Floor 2">
          </div>
          <div class="form-group">
            <label class="form-label">Call Window (seconds)</label>
            <input class="form-control" type="number" name="callWindowSeconds" value="120" min="30" max="600">
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">Max Pending Entries</label>
          <input class="form-control" type="number" name="maxPending" value="50" min="1" max="500">
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" data-close-modal>Cancel</button>
        <button type="submit" class="btn btn-primary">Create Service</button>
      </div>
    </form>
  </div>
</div>

<script>
// Per-service tab system
document.querySelectorAll('[data-tabs]').forEach(container => {
  const tabsId = container.getAttribute('data-tabs');
  if (!tabsId) return;
  // find buttons with matching data-tab
  const buttons = document.querySelectorAll(`[data-tab]`);
  buttons.forEach(btn => {
    btn.addEventListener('click', () => {
      const panel = btn.getAttribute('data-tab');
      const parentTabs = btn.closest('[data-tabs]');
      if (!parentTabs) return;
      parentTabs.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const sibling = parentTabs.nextElementSibling;
      if (sibling) {
        sibling.querySelectorAll('.tab-panel').forEach(p => {
          p.classList.toggle('active', p.getAttribute('data-panel') === panel);
        });
      }
    });
  });
});
</script>
<?php endif; ?>

<script>
window._csrfToken = '<?= h($csrf) ?>';
window._basePath = '<?= BASE_PATH ?>';
window.refreshPage = () => location.reload();
</script>
<?php include __DIR__ . '/../includes/footer.php'; ?>
