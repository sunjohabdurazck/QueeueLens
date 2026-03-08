<?php
ini_set('display_errors', 0);
error_reporting(0);

require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_STAFF);
require_once __DIR__ . '/../config/firestore_rest.php';
require_once __DIR__ . '/../services/QueueService.php';

$pageTitle = 'Live Queue';
include __DIR__ . '/../includes/header.php';

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }
function formatTime($ts) {
    if (!$ts) return '--';
    $t = is_string($ts) ? strtotime($ts) : (int)$ts;
    if (!$t) return '--';
    return date('H:i', $t);
}
function shortId($id) { return strtoupper(substr($id, -6)); }

$services = [];
try {
    $results = firestore_runQuery([
        "from"  => [["collectionId" => "services"]],
        "orderBy" => [["field" => ["fieldPath" => "name"], "direction" => "ASCENDING"]],
        "limit" => 50
    ]);
    foreach ($results as $row) {
        if (empty($row['document'])) continue;
        $doc = $row['document'];
        $d = firestore_unpack_fields($doc['fields'] ?? []);
        $d['_id'] = basename($doc['name']);
        $services[] = $d;
    }
} catch (Exception $e) { error_log("Queue page services: ".$e->getMessage()); }

$selectedId = $_GET['service'] ?? ($services[0]['_id'] ?? null);
$selected   = null;
foreach ($services as $s) {
    if ($s['_id'] === $selectedId) { $selected = $s; break; }
}

$entries = [];
$pending = []; $called = []; $active = []; $served = []; $expired = [];

if ($selected) {
    try {
        $entries = QueueService::getEntries($selectedId, null, 200);
        foreach ($entries as $e) {
            switch ($e['status'] ?? 'pending') {
                case 'pending':  $pending[] = $e; break;
                case 'called':   $called[]  = $e; break;
                case 'active':   $active[]  = $e; break;
                case 'served':   $served[]  = $e; break;
                case 'expired':  $expired[] = $e; break;
            }
        }
        // Sort pending by joinedAt
        usort($pending, fn($a,$b) => strcmp($a['joinedAt']??'', $b['joinedAt']??''));
    } catch(Exception $e) { error_log("Queue entries: ".$e->getMessage()); }
}

$csrf = generateCSRFToken();
$callExp = $selected['callExpiresAt'] ?? null;
?>

<div class="page-header">
  <div class="page-header-row">
    <div>
      <h1 class="page-title">Live Queue</h1>
      <p class="page-subtitle">Full lifecycle queue management</p>
    </div>
    <div class="header-actions">
      <button class="btn btn-ghost btn-sm" onclick="location.reload()">↻ Refresh</button>
      <?php if (isAdmin() && $selected): ?>
      <button class="btn btn-warning btn-sm" onclick="if(confirm('Repair service queue state?')) queueAction('repair','<?= h($selectedId) ?>')">🔧 Repair Queue</button>
      <?php endif; ?>
    </div>
  </div>
</div>

<!-- Service Selector -->
<div class="filter-bar mb-6">
  <label class="form-label" style="margin:0;white-space:nowrap">Service:</label>
  <select class="form-control" style="max-width:300px" onchange="location.href='?service='+this.value">
    <?php foreach ($services as $s): ?>
    <option value="<?= h($s['_id']) ?>" <?= $s['_id']===$selectedId?'selected':'' ?>>
      <?= h($s['name'] ?? $s['_id']) ?> — <?= ($s['isOpen']??false)?'Open':'Closed' ?>
    </option>
    <?php endforeach; ?>
  </select>
  <?php if ($selected): ?>
  <span class="badge badge-<?= ($selected['isOpen']??false)?'open':'closed' ?>">
    <?= ($selected['isOpen']??false)?'🟢 Open':'🔴 Closed' ?>
  </span>
  <?php endif; ?>
</div>

<?php if ($selected): ?>
<!-- Control Panel -->
<div class="card mb-6">
  <div class="card-header">
    <div>
      <div class="card-title">⚡ Queue Control Panel — <?= h($selected['name'] ?? $selectedId) ?></div>
      <div class="card-subtitle">headPending: <span class="text-mono text-xs"><?= h($selected['headPendingEntryId'] ?? '—') ?></span> | called: <span class="text-mono text-xs"><?= h($selected['calledEntryId'] ?? '—') ?></span> | active: <span class="text-mono text-xs"><?= h($selected['activeEntryId'] ?? '—') ?></span></div>
    </div>
    <div class="flex gap-2 items-center">
      <?php if ($callExp): ?>
      <div style="font-size:.72rem;color:var(--c-text3)">Call expires:</div>
      <span class="countdown ok" data-expires="<?= h($callExp) ?>">--:--</span>
      <?php endif; ?>
    </div>
  </div>
  <div style="padding:16px 20px;display:flex;gap:8px;flex-wrap:wrap;border-bottom:1px solid var(--c-border)">
    <button onclick="doAction('call_head')" class="btn btn-primary">📣 Call Head</button>
    <?php if (!empty($selected['calledEntryId'])): ?>
    <button onclick="doAction('check_in')" class="btn btn-success">✅ Check In Called</button>
    <button onclick="doAction('recall_head')" class="btn btn-ghost">🔁 Recall</button>
    <button onclick="doAction('expire_called')" class="btn btn-warning">⏱ Expire Call</button>
    <?php endif; ?>
    <?php if (!empty($selected['activeEntryId'])): ?>
    <button onclick="doAction('mark_served','<?= h($selected['activeEntryId']) ?>')" class="btn btn-success">🏅 Mark Served</button>
    <button onclick="doAction('mark_left','<?= h($selected['activeEntryId']) ?>')" class="btn btn-danger">🚪 Mark Left</button>
    <?php endif; ?>
  </div>
  <div class="qsc-counters">
    <div class="qsc-counter">
      <div class="qsc-counter-val pending"><?= count($pending) ?></div>
      <div class="qsc-counter-label">Pending</div>
    </div>
    <div class="qsc-counter">
      <div class="qsc-counter-val called"><?= count($called) ?></div>
      <div class="qsc-counter-label">Called</div>
    </div>
    <div class="qsc-counter">
      <div class="qsc-counter-val active"><?= count($active) ?></div>
      <div class="qsc-counter-label">Active</div>
    </div>
    <div class="qsc-counter">
      <div class="qsc-counter-val" style="color:var(--c-text3)"><?= count($served) ?></div>
      <div class="qsc-counter-label">Served Today</div>
    </div>
    <div class="qsc-counter">
      <div class="qsc-counter-val" style="color:var(--c-red)"><?= count($expired) ?></div>
      <div class="qsc-counter-label">Expired</div>
    </div>
  </div>
</div>

<!-- Queue Timeline Columns -->
<div style="display:grid;grid-template-columns:repeat(5,1fr);gap:14px;margin-bottom:32px">

  <!-- PENDING -->
  <div class="card" style="overflow:hidden">
    <div class="queue-col-header">
      <span class="queue-col-title pending">Pending</span>
      <span class="queue-col-count" style="background:rgba(251,191,36,0.12);color:var(--c-amber)"><?= count($pending) ?></span>
    </div>
    <div class="queue-col-body">
      <?php if (empty($pending)): ?>
        <div class="empty-col">No pending entries</div>
      <?php else: foreach ($pending as $i => $e): $isHead = ($i === 0); ?>
      <div class="entry-card" style="<?= $isHead?'border-left:2px solid var(--c-amber)':'' ?>">
        <div class="entry-card-name"><?= h($e['studentName'] ?? $e['userId'] ?? 'Unknown') ?></div>
        <div class="entry-card-meta"><?= shortId($e['_id']) ?> · <?= formatTime($e['joinedAt'] ?? null) ?><?= $isHead?' · HEAD':'' ?></div>
        <div class="entry-card-actions">
          <button onclick="doAction('mark_left','<?= h($e['_id']) ?>')" class="btn btn-danger btn-sm" title="Mark left">🚪</button>
          <?php if (isAdmin()): ?>
          <button onclick="purgeEntry('<?= h($e['_id']) ?>')" class="btn btn-ghost btn-sm" title="Purge">🗑</button>
          <?php endif; ?>
        </div>
      </div>
      <?php endforeach; endif; ?>
    </div>
  </div>

  <!-- CALLED -->
  <div class="card" style="overflow:hidden">
    <div class="queue-col-header">
      <span class="queue-col-title called">Called</span>
      <span class="queue-col-count" style="background:rgba(56,189,248,0.12);color:var(--c-primary)"><?= count($called) ?></span>
    </div>
    <div class="queue-col-body">
      <?php if (empty($called)): ?>
        <div class="empty-col">No called entries</div>
      <?php else: foreach ($called as $e): $exp = $e['callExpiresAt'] ?? null; ?>
      <div class="entry-card" style="border-left:2px solid var(--c-primary)">
        <div class="entry-card-name"><?= h($e['studentName'] ?? $e['userId'] ?? 'Unknown') ?></div>
        <div class="entry-card-meta"><?= shortId($e['_id']) ?> · Called <?= formatTime($e['calledAt'] ?? null) ?></div>
        <?php if ($exp): ?><div style="margin-top:4px"><span class="countdown ok" data-expires="<?= h($exp) ?>">--:--</span></div><?php endif; ?>
        <div class="entry-card-actions">
          <button onclick="doAction('check_in')" class="btn btn-success btn-sm">✅</button>
          <button onclick="doAction('recall_head')" class="btn btn-ghost btn-sm">🔁</button>
          <button onclick="doAction('expire_called')" class="btn btn-warning btn-sm">⏱</button>
        </div>
      </div>
      <?php endforeach; endif; ?>
    </div>
  </div>

  <!-- ACTIVE -->
  <div class="card" style="overflow:hidden">
    <div class="queue-col-header">
      <span class="queue-col-title active">Active</span>
      <span class="queue-col-count" style="background:rgba(52,211,153,0.12);color:var(--c-green)"><?= count($active) ?></span>
    </div>
    <div class="queue-col-body">
      <?php if (empty($active)): ?>
        <div class="empty-col">No active entries</div>
      <?php else: foreach ($active as $e): ?>
      <div class="entry-card" style="border-left:2px solid var(--c-green)">
        <div class="entry-card-name"><?= h($e['studentName'] ?? $e['userId'] ?? 'Unknown') ?></div>
        <div class="entry-card-meta"><?= shortId($e['_id']) ?> · Since <?= formatTime($e['checkedInAt'] ?? null) ?></div>
        <div class="entry-card-actions">
          <button onclick="doAction('mark_served','<?= h($e['_id']) ?>')" class="btn btn-success btn-sm">🏅 Served</button>
          <button onclick="doAction('mark_left','<?= h($e['_id']) ?>')" class="btn btn-danger btn-sm">🚪</button>
        </div>
      </div>
      <?php endforeach; endif; ?>
    </div>
  </div>

  <!-- SERVED -->
  <div class="card" style="overflow:hidden">
    <div class="queue-col-header">
      <span class="queue-col-title served">Served</span>
      <span class="queue-col-count" style="background:rgba(100,116,139,0.12);color:var(--c-text3)"><?= count($served) ?></span>
    </div>
    <div class="queue-col-body">
      <?php if (empty($served)): ?>
        <div class="empty-col">None served yet</div>
      <?php else: foreach (array_slice(array_reverse($served), 0, 15) as $e): ?>
      <div class="entry-card">
        <div class="entry-card-name"><?= h($e['studentName'] ?? $e['userId'] ?? 'Unknown') ?></div>
        <div class="entry-card-meta"><?= shortId($e['_id']) ?> · <?= formatTime($e['servedAt'] ?? null) ?></div>
      </div>
      <?php endforeach; endif; ?>
    </div>
  </div>

  <!-- EXPIRED / NO-SHOW -->
  <div class="card" style="overflow:hidden">
    <div class="queue-col-header">
      <span class="queue-col-title expired">Expired</span>
      <span class="queue-col-count" style="background:rgba(248,113,113,0.10);color:var(--c-red)"><?= count($expired) ?></span>
    </div>
    <div class="queue-col-body">
      <?php if (empty($expired)): ?>
        <div class="empty-col">No expired entries</div>
      <?php else: foreach (array_slice(array_reverse($expired), 0, 10) as $e): ?>
      <div class="entry-card">
        <div class="entry-card-name"><?= h($e['studentName'] ?? $e['userId'] ?? 'Unknown') ?></div>
        <div class="entry-card-meta"><?= shortId($e['_id']) ?> · <?= formatTime($e['expiredAt'] ?? null) ?></div>
        <?php if (isAdmin()): ?>
        <div class="entry-card-actions">
          <button onclick="purgeEntry('<?= h($e['_id']) ?>')" class="btn btn-ghost btn-sm">🗑 Purge</button>
        </div>
        <?php endif; ?>
      </div>
      <?php endforeach; endif; ?>
    </div>
  </div>

</div>
<?php endif; // $selected ?>

<!-- Purge Modal -->
<div class="modal-overlay" id="purgeModal">
  <div class="modal">
    <div class="modal-header">
      <span class="modal-title">🗑 Purge Entry</span>
      <button class="modal-close" data-close-modal>✕</button>
    </div>
    <div class="modal-body">
      <p style="color:var(--c-text2);font-size:.85rem;margin-bottom:16px">This permanently deletes the entry from Firestore. Only use for duplicates or corrupted records.</p>
      <input type="hidden" id="purgeEntryId">
      <div class="form-group">
        <label class="form-label">Reason for deletion</label>
        <input class="form-control" id="purgeReason" placeholder="e.g. duplicate entry, test record..." required>
      </div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-ghost" data-close-modal>Cancel</button>
      <button class="btn btn-danger" onclick="confirmPurge()">🗑 Permanently Delete</button>
    </div>
  </div>
</div>

<meta name="csrf-token" content="<?= h($csrf) ?>">
<script>
window._basePath = '<?= BASE_PATH ?>';
window._csrfToken = '<?= $csrf ?>';
window._serviceId = '<?= h($selectedId ?? '') ?>';
window.refreshPage = () => location.reload();

function doAction(action, entryId) {
  queueAction(action, window._serviceId, entryId);
}

function purgeEntry(entryId) {
  document.getElementById('purgeEntryId').value = entryId;
  document.getElementById('purgeModal').classList.add('open');
}

function confirmPurge() {
  const id = document.getElementById('purgeEntryId').value;
  const reason = document.getElementById('purgeReason').value;
  if (!reason) { showToast('Please enter a reason', 'error'); return; }
  document.getElementById('purgeModal').classList.remove('open');
  queueAction('purge_entry', window._serviceId, id, reason);
}
</script>
<?php include __DIR__ . '/../includes/footer.php'; ?>
