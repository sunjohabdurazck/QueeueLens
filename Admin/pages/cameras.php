<?php
ini_set('display_errors', 0);
error_reporting(0);

require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_STAFF);
require_once __DIR__ . '/../config/firestore_rest.php';
require_once __DIR__ . '/../services/AuditService.php';

$pageTitle = 'Cameras';
include __DIR__ . '/../includes/header.php';

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

$flash = null;
$csrf  = generateCSRFToken();

if ($_SERVER['REQUEST_METHOD'] === 'POST' && verifyCSRFToken($_POST['csrf_token'] ?? '')) {
    $action = $_POST['action'] ?? '';
    $camId  = trim($_POST['cameraId'] ?? '');

    try {
        switch($action) {
            case 'create_camera':
                if (isAdmin()) {
                    $doc = [
                        'name'        => trim($_POST['name'] ?? ''),
                        'location'    => trim($_POST['location'] ?? ''),
                        'streamUrl'   => trim($_POST['streamUrl'] ?? ''),
                        'serviceId'   => trim($_POST['serviceId'] ?? ''),
                        'isActive'    => true,
                        'lastActive'  => fs_timestamp_now(),
                        'createdAt'   => fs_timestamp_now(),
                        'createdBy'   => $_SESSION['user_id'] ?? 'admin',
                    ];
                    firestore_createDocument('surveillance_cameras', $doc);
                    AuditService::log('CAMERA_CREATE', 'surveillance_cameras', [], $doc);
                    $flash = ['success'=>true,'message'=>'Camera added'];
                }
                break;

            case 'toggle_camera':
                $newActive = ($_POST['new_state'] ?? '1') === '1';
                if ($camId) {
                    firestore_updateDocument("surveillance_cameras/$camId", ['isActive' => $newActive]);
                    AuditService::log($newActive?'CAMERA_ACTIVATE':'CAMERA_DEACTIVATE', "surveillance_cameras/$camId", [], ['isActive'=>$newActive]);
                    $flash = ['success'=>true,'message'=>'Camera '.($newActive?'activated':'deactivated')];
                }
                break;

            case 'delete_camera':
                if (isAdmin() && $camId) {
                    AuditService::log('CAMERA_DELETE', "surveillance_cameras/$camId", [], []);
                    firestore_deleteDocument("surveillance_cameras/$camId");
                    $flash = ['success'=>true,'message'=>'Camera deleted'];
                }
                break;
        }
    } catch(Exception $e) {
        $flash = ['success'=>false,'message'=>'Error: '.$e->getMessage()];
    }
}

$cameras = []; $services = [];

try {
    $results = firestore_runQuery([
        "from"  => [["collectionId" => "surveillance_cameras"]],
        "limit" => 100
    ]);
    foreach ($results as $row) {
        if (empty($row['document'])) continue;
        $doc = $row['document'];
        $d = firestore_unpack_fields($doc['fields'] ?? []);
        $d['_id'] = basename($doc['name']);
        $cameras[] = $d;
    }

    $sResults = firestore_runQuery([
        "from"  => [["collectionId" => "services"]],
        "limit" => 50
    ]);
    foreach ($sResults as $row) {
        if (empty($row['document'])) continue;
        $doc = $row['document'];
        $d = firestore_unpack_fields($doc['fields'] ?? []);
        $d['_id'] = basename($doc['name']);
        $services[] = $d;
    }
    $sMap = [];
    foreach ($services as $s) $sMap[$s['_id']] = $s['name'] ?? $s['_id'];

} catch(Exception $e) { error_log("Cameras: ".$e->getMessage()); $sMap = []; }

$online  = 0;
$offline = 0;
foreach ($cameras as $c) {
    $lastActive = $c['lastActive'] ?? null;
    $isOnline = ($c['isActive']??false) && $lastActive && (time()-strtotime($lastActive)) < 120;
    if ($isOnline) $online++; else $offline++;
}
?>

<div class="page-header">
  <div class="page-header-row">
    <div>
      <h1 class="page-title">Cameras</h1>
      <p class="page-subtitle">Surveillance system overview and management</p>
    </div>
    <?php if (isAdmin()): ?>
    <div class="header-actions">
      <button class="btn btn-primary" data-modal="createCameraModal">＋ Add Camera</button>
    </div>
    <?php endif; ?>
  </div>
</div>

<?php if ($flash): ?>
<div class="alert alert-<?= $flash['success']?'success':'danger' ?> mb-6">
  <?= $flash['success']?'✅':'❌' ?> <?= h($flash['message']) ?>
</div>
<?php endif; ?>

<div class="stats-grid" style="grid-template-columns:repeat(3,1fr);margin-bottom:24px">
  <div class="stat-card blue"><div class="stat-icon">📹</div><div class="stat-label">Total Cameras</div><div class="stat-value blue"><?= count($cameras) ?></div></div>
  <div class="stat-card green"><div class="stat-icon">🟢</div><div class="stat-label">Online</div><div class="stat-value green"><?= $online ?></div><div class="stat-sub">Heartbeat &lt; 2min</div></div>
  <div class="stat-card red"><div class="stat-icon">🔴</div><div class="stat-label">Offline</div><div class="stat-value red"><?= $offline ?></div></div>
</div>

<div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:16px">
<?php foreach ($cameras as $cam):
  $camId = $cam['_id'];
  $lastActive = $cam['lastActive'] ?? null;
  $isOnline = ($cam['isActive']??false) && $lastActive && (time()-strtotime($lastActive)) < 120;
  $lastActiveStr = $lastActive ? date('M j H:i', strtotime($lastActive)) : 'Never';
  $linkedService = $sMap[$cam['serviceId'] ?? ''] ?? null;
?>
<div class="card" style="<?= !$isOnline && ($cam['isActive']??false) ? 'border-color:rgba(248,113,113,.3)' : '' ?>">
  <div class="card-header">
    <div>
      <div class="card-title"><?= h($cam['name'] ?? 'Camera') ?></div>
      <div style="margin-top:4px">
        <?php if ($isOnline): ?>
          <span class="badge badge-online"><span class="pulse-dot green"></span> Online</span>
        <?php elseif ($cam['isActive'] ?? false): ?>
          <span class="badge badge-offline"><span class="pulse-dot red"></span> No Heartbeat</span>
        <?php else: ?>
          <span class="badge badge-offline">● Disabled</span>
        <?php endif; ?>
      </div>
    </div>
    <?php if (isAdmin()): ?>
    <form method="POST" style="display:inline">
      <input type="hidden" name="csrf_token" value="<?= h($csrf) ?>">
      <input type="hidden" name="action" value="toggle_camera">
      <input type="hidden" name="cameraId" value="<?= h($camId) ?>">
      <input type="hidden" name="new_state" value="<?= ($cam['isActive']??false)?'0':'1' ?>">
      <button type="submit" class="btn btn-ghost btn-sm btn-icon" title="Toggle">
        <?= ($cam['isActive']??false) ? '⏸' : '▶' ?>
      </button>
    </form>
    <?php endif; ?>
  </div>
  <div style="padding:14px 20px;display:flex;flex-direction:column;gap:8px">
    <?php if (!empty($cam['location'])): ?>
    <div class="state-row"><span class="state-label">Location</span><span class="state-val"><?= h($cam['location']) ?></span></div>
    <?php endif; ?>
    <?php if ($linkedService): ?>
    <div class="state-row"><span class="state-label">Service</span><span class="state-val"><?= h($linkedService) ?></span></div>
    <?php endif; ?>
    <div class="state-row"><span class="state-label">Last Heartbeat</span><span class="state-val"><?= h($lastActiveStr) ?></span></div>
    <?php if (!empty($cam['streamUrl'])): ?>
    <div class="state-row"><span class="state-label">Stream</span><span class="state-val" style="font-size:.65rem"><?= h(substr($cam['streamUrl'],0,30)).'...' ?></span></div>
    <?php endif; ?>
  </div>
  <?php if (isAdmin()): ?>
  <div style="padding:10px 16px;border-top:1px solid var(--c-border);display:flex;justify-content:flex-end">
    <form method="POST" style="display:inline">
      <input type="hidden" name="csrf_token" value="<?= h($csrf) ?>">
      <input type="hidden" name="action" value="delete_camera">
      <input type="hidden" name="cameraId" value="<?= h($camId) ?>">
      <button type="submit" class="btn btn-danger btn-sm" onclick="return confirm('Delete this camera?')">🗑 Delete</button>
    </form>
  </div>
  <?php endif; ?>
</div>
<?php endforeach; ?>
<?php if (empty($cameras)): ?>
<div class="empty-state" style="grid-column:1/-1">
  <div class="empty-state-icon">📹</div>
  <div class="empty-state-title">No cameras configured</div>
  <?php if (isAdmin()): ?><div class="empty-state-text">Add your first camera to start monitoring.</div><?php endif; ?>
</div>
<?php endif; ?>
</div>

<?php if (isAdmin()): ?>
<div class="modal-overlay" id="createCameraModal">
  <div class="modal">
    <div class="modal-header">
      <span class="modal-title">＋ Add Camera</span>
      <button class="modal-close" data-close-modal>✕</button>
    </div>
    <form method="POST">
      <div class="modal-body">
        <input type="hidden" name="csrf_token" value="<?= h($csrf) ?>">
        <input type="hidden" name="action" value="create_camera">
        <div class="form-group">
          <label class="form-label">Camera Name *</label>
          <input class="form-control" name="name" required placeholder="e.g. Lobby Cam 01">
        </div>
        <div class="form-group">
          <label class="form-label">Physical Location</label>
          <input class="form-control" name="location" placeholder="e.g. Building A Entrance">
        </div>
        <div class="form-group">
          <label class="form-label">Linked Service</label>
          <select class="form-control" name="serviceId">
            <option value="">— None —</option>
            <?php foreach ($services as $s): ?>
            <option value="<?= h($s['_id']) ?>"><?= h($s['name'] ?? $s['_id']) ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Stream URL</label>
          <input class="form-control" name="streamUrl" type="url" placeholder="rtsp://... or https://...">
          <div class="form-hint">RTSP or HLS stream URL for live preview</div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" data-close-modal>Cancel</button>
        <button type="submit" class="btn btn-primary">Add Camera</button>
      </div>
    </form>
  </div>
</div>
<?php endif; ?>

<?php include __DIR__ . '/../includes/footer.php'; ?>
