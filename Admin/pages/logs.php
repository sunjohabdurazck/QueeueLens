<?php
ini_set('display_errors', 0);
error_reporting(0);

require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_ADMIN);
require_once __DIR__ . '/../config/firestore_rest.php';

$pageTitle = 'Audit Logs';
include __DIR__ . '/../includes/header.php';

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

$logs = [];
$filterAction = $_GET['action'] ?? '';
$filterRole   = $_GET['role'] ?? '';
$limit        = min(200, max(10, (int)($_GET['limit'] ?? 100)));

try {
    $query = [
        "from"    => [["collectionId" => "audit_logs"]],
        "orderBy" => [["field" => ["fieldPath" => "createdAt"], "direction" => "DESCENDING"]],
        "limit"   => $limit,
    ];

    $results = firestore_runQuery($query);
    foreach ($results as $row) {
        if (empty($row['document'])) continue;
        $doc = $row['document'];
        $d = firestore_unpack_fields($doc['fields'] ?? []);
        $d['_id'] = basename($doc['name']);
        if ($filterAction && stripos($d['action'] ?? '', $filterAction) === false) continue;
        if ($filterRole && ($d['actorRole'] ?? '') !== $filterRole) continue;
        $logs[] = $d;
    }
} catch(Exception $e) { error_log("Logs page: ".$e->getMessage()); }

$actionColors = [
    'QUEUE_CALL_HEAD' => 'var(--c-primary)',
    'QUEUE_RECALL_HEAD' => 'var(--c-primary)',
    'QUEUE_CHECK_IN' => 'var(--c-green)',
    'QUEUE_MARK_SERVED' => 'var(--c-green)',
    'QUEUE_MARK_LEFT' => 'var(--c-amber)',
    'QUEUE_EXPIRE_CALLED' => 'var(--c-amber)',
    'QUEUE_REPAIR_SERVICE' => 'var(--c-accent)',
    'QUEUE_PURGE_ENTRY' => 'var(--c-red)',
    'USER_ROLE_CHANGE' => 'var(--c-accent)',
    'USER_ACTIVATE' => 'var(--c-green)',
    'USER_DEACTIVATE' => 'var(--c-red)',
];
?>

<div class="page-header">
  <div class="page-header-row">
    <div>
      <h1 class="page-title">Audit Logs</h1>
      <p class="page-subtitle">Complete audit trail of all admin actions</p>
    </div>
  </div>
</div>

<div class="filter-bar mb-6">
  <form method="GET" style="display:flex;gap:8px;flex-wrap:wrap;align-items:center">
    <div class="search-input-wrap" style="min-width:240px">
      <span class="search-icon">🔍</span>
      <input class="search-input" name="action" value="<?= h($filterAction) ?>" placeholder="Filter by action (e.g. QUEUE_CALL_HEAD)...">
    </div>
    <select class="form-control" name="role" style="width:140px">
      <option value="">All roles</option>
      <option value="admin" <?= $filterRole==='admin'?'selected':'' ?>>Admin</option>
      <option value="staff" <?= $filterRole==='staff'?'selected':'' ?>>Staff</option>
    </select>
    <select class="form-control" name="limit" style="width:100px">
      <?php foreach ([50,100,200] as $l): ?>
      <option value="<?= $l ?>" <?= $limit==$l?'selected':'' ?>><?= $l ?> rows</option>
      <?php endforeach; ?>
    </select>
    <button type="submit" class="btn btn-primary btn-sm">Filter</button>
    <a href="?" class="btn btn-ghost btn-sm">Clear</a>
  </form>
</div>

<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Time</th>
        <th>Actor</th>
        <th>Role</th>
        <th>Action</th>
        <th>Target</th>
        <th>IP</th>
        <th>Diff</th>
      </tr>
    </thead>
    <tbody>
      <?php if (empty($logs)): ?>
      <tr><td colspan="7" style="text-align:center;padding:40px;color:var(--c-text3)">No audit logs found</td></tr>
      <?php else: foreach ($logs as $log):
        $ts = $log['createdAt'] ?? null;
        $time = $ts ? date('M j H:i:s', strtotime($ts)) : '—';
        $action = $log['action'] ?? 'UNKNOWN';
        $color = $actionColors[$action] ?? 'var(--c-text2)';
        $before = $log['before'] ?? null;
        $after  = $log['after'] ?? null;
        $hasDiff = ($before || $after);
      ?>
      <tr>
        <td class="td-mono" style="white-space:nowrap"><?= h($time) ?></td>
        <td>
          <div style="font-weight:600;font-size:.82rem"><?= h($log['actorName'] ?? 'Unknown') ?></div>
          <div class="td-mono" style="font-size:.62rem"><?= h($log['actorEmail'] ?? '') ?></div>
        </td>
        <td><span class="badge badge-<?= h($log['actorRole'] ?? 'staff') ?>"><?= ucfirst(h($log['actorRole'] ?? '')) ?></span></td>
        <td>
          <code style="font-family:var(--font-mono);font-size:.68rem;padding:2px 8px;border-radius:4px;background:var(--c-surface2);color:<?= $color ?>"><?= h($action) ?></code>
        </td>
        <td class="td-mono" style="font-size:.68rem;max-width:200px;overflow:hidden;text-overflow:ellipsis"><?= h($log['targetPath'] ?? '—') ?></td>
        <td class="td-mono"><?= h($log['ipAddress'] ?? '—') ?></td>
        <td>
          <?php if ($hasDiff): ?>
          <button onclick="this.nextElementSibling.style.display=this.nextElementSibling.style.display==='none'?'block':'none'"
                  class="btn btn-ghost btn-sm">View</button>
          <div style="display:none;margin-top:6px">
            <?php if ($before): ?>
            <div style="font-size:.65rem;color:var(--c-text3);margin-bottom:2px">BEFORE</div>
            <pre style="font-family:var(--font-mono);font-size:.65rem;background:var(--c-surface2);padding:8px;border-radius:4px;color:var(--c-red);white-space:pre-wrap;max-height:80px;overflow:auto"><?= h($before) ?></pre>
            <?php endif; ?>
            <?php if ($after): ?>
            <div style="font-size:.65rem;color:var(--c-text3);margin-top:6px;margin-bottom:2px">AFTER</div>
            <pre style="font-family:var(--font-mono);font-size:.65rem;background:var(--c-surface2);padding:8px;border-radius:4px;color:var(--c-green);white-space:pre-wrap;max-height:80px;overflow:auto"><?= h($after) ?></pre>
            <?php endif; ?>
          </div>
          <?php else: ?>
          <span style="color:var(--c-text3);font-size:.72rem">—</span>
          <?php endif; ?>
        </td>
      </tr>
      <?php endforeach; endif; ?>
    </tbody>
  </table>
</div>
<div style="margin-top:12px;font-size:.75rem;color:var(--c-text3)">Showing <?= count($logs) ?> of latest <?= $limit ?> records. Source: audit_logs collection.</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
