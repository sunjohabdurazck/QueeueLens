<?php
ini_set('display_errors', 0);
error_reporting(0);

require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_ADMIN);
require_once __DIR__ . '/../config/firestore_rest.php';

$pageTitle = 'Analytics';
include __DIR__ . '/../includes/header.php';

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

// Real stats from Firestore
$services = [];
$totalServed = 0; $totalPending = 0; $totalActive = 0;
$openCount = 0; $closedCount = 0;
$serviceStats = [];

try {
    $results = firestore_runQuery([
        "from"  => [["collectionId" => "services"]],
        "limit" => 100
    ]);
    foreach ($results as $row) {
        if (empty($row['document'])) continue;
        $doc = $row['document'];
        $d = firestore_unpack_fields($doc['fields'] ?? []);
        $d['_id'] = basename($doc['name']);
        $services[] = $d;
        $totalServed  += (int)($d['totalServed'] ?? 0);
        $totalPending += (int)($d['pendingCount'] ?? 0);
        $totalActive  += (int)($d['activeCount'] ?? 0);
        if ($d['isOpen'] ?? false) $openCount++; else $closedCount++;
        $serviceStats[] = ['name' => $d['name'] ?? $d['_id'], 'served' => (int)($d['totalServed']??0), 'pending' => (int)($d['pendingCount']??0)];
    }
    usort($serviceStats, fn($a,$b) => $b['served'] <=> $a['served']);
} catch(Exception $e) {}

$cameras = []; $onlineCams = 0;
try {
    $camResults = firestore_runQuery([
        "from"  => [["collectionId" => "surveillance_cameras"]],
        "limit" => 50
    ]);
    foreach ($camResults as $row) {
        if (empty($row['document'])) continue;
        $doc = $row['document'];
        $d = firestore_unpack_fields($doc['fields'] ?? []);
        $d['_id'] = basename($doc['name']);
        $cameras[] = $d;
        $lastActive = $d['lastActive'] ?? null;
        if (($d['isActive']??false) && $lastActive && (time() - strtotime($lastActive)) < 120) $onlineCams++;
    }
} catch(Exception $e) {}

// Recent audit activity
$recentActions = [];
try {
    $logResults = firestore_runQuery([
        "from"    => [["collectionId" => "audit_logs"]],
        "orderBy" => [["field" => ["fieldPath" => "createdAt"], "direction" => "DESCENDING"]],
        "limit"   => 20
    ]);
    foreach ($logResults as $row) {
        if (empty($row['document'])) continue;
        $doc = $row['document'];
        $d = firestore_unpack_fields($doc['fields'] ?? []);
        $recentActions[] = $d;
    }
} catch(Exception $e) {}
?>

<div class="page-header">
  <div class="page-header-row">
    <div>
      <h1 class="page-title">Analytics</h1>
      <p class="page-subtitle">Real operational metrics from Firestore</p>
    </div>
    <button class="btn btn-ghost btn-sm" onclick="location.reload()">↻ Refresh</button>
  </div>
</div>

<!-- Real Stats -->
<div class="stats-grid">
  <div class="stat-card purple">
    <div class="stat-icon">🏅</div>
    <div class="stat-label">Total Served (All Time)</div>
    <div class="stat-value purple"><?= number_format($totalServed) ?></div>
    <div class="stat-sub">Across all services</div>
  </div>
  <div class="stat-card amber">
    <div class="stat-icon">⏳</div>
    <div class="stat-label">Currently Pending</div>
    <div class="stat-value amber"><?= $totalPending ?></div>
    <div class="stat-sub">Live queue depth</div>
  </div>
  <div class="stat-card green">
    <div class="stat-icon">✅</div>
    <div class="stat-label">Currently Active</div>
    <div class="stat-value green"><?= $totalActive ?></div>
    <div class="stat-sub">Being served now</div>
  </div>
  <div class="stat-card blue">
    <div class="stat-icon">🏢</div>
    <div class="stat-label">Open Services</div>
    <div class="stat-value blue"><?= $openCount ?> / <?= count($services) ?></div>
    <div class="stat-sub"><?= $closedCount ?> currently closed</div>
  </div>
  <div class="stat-card <?= $onlineCams < count($cameras) ? 'amber' : 'green' ?>">
    <div class="stat-icon">📹</div>
    <div class="stat-label">Cameras Online</div>
    <div class="stat-value <?= $onlineCams < count($cameras) ? 'amber' : 'green' ?>"><?= $onlineCams ?>/<?= count($cameras) ?></div>
    <div class="stat-sub">Last 2 min heartbeat</div>
  </div>
  <div class="stat-card blue">
    <div class="stat-icon">📝</div>
    <div class="stat-label">Recent Actions</div>
    <div class="stat-value blue"><?= count($recentActions) ?></div>
    <div class="stat-sub">Last 20 audit events</div>
  </div>
</div>

<!-- Service Leaderboard -->
<div class="grid-2">
  <div class="card mb-6">
    <div class="card-header"><div class="card-title">🏆 Services by Volume Served</div></div>
    <div class="card-body" style="padding:0">
      <?php if (empty($serviceStats)): ?>
      <div class="empty-state"><div class="empty-state-text">No data</div></div>
      <?php else: ?>
      <?php $maxServed = max(array_column($serviceStats, 'served') ?: [1]); ?>
      <?php foreach ($serviceStats as $i => $stat): ?>
      <div style="padding:14px 20px;border-bottom:1px solid var(--c-border);display:flex;align-items:center;gap:14px">
        <div style="font-family:var(--font-mono);font-size:.75rem;color:var(--c-text3);width:20px"><?= $i+1 ?></div>
        <div style="flex:1">
          <div style="font-weight:600;font-size:.85rem;margin-bottom:5px"><?= h($stat['name']) ?></div>
          <div style="background:var(--c-surface2);border-radius:4px;height:6px;overflow:hidden">
            <div style="height:100%;background:var(--c-accent);border-radius:4px;width:<?= $maxServed>0?round($stat['served']/$maxServed*100):0 ?>%"></div>
          </div>
        </div>
        <div style="font-family:var(--font-mono);font-size:.85rem;color:var(--c-accent);font-weight:700"><?= number_format($stat['served']) ?></div>
        <div style="font-family:var(--font-mono);font-size:.75rem;color:var(--c-amber)"><?= $stat['pending'] ?> pending</div>
      </div>
      <?php endforeach; ?>
      <?php endif; ?>
    </div>
  </div>

  <!-- Recent Audit Actions -->
  <div class="card mb-6">
    <div class="card-header">
      <div class="card-title">📝 Recent Actions</div>
      <a href="<?= BASE_PATH ?>/pages/logs.php" class="btn btn-ghost btn-sm">All Logs →</a>
    </div>
    <div class="card-body" style="padding:0">
      <?php foreach (array_slice($recentActions, 0, 10) as $log):
        $ts = $log['createdAt'] ?? null;
        $timeStr = $ts ? date('H:i', strtotime($ts)) : '—';
        $action = $log['action'] ?? '';
        $actor  = $log['actorName'] ?? 'Unknown';
      ?>
      <div style="padding:11px 20px;border-bottom:1px solid var(--c-border);display:flex;align-items:center;gap:12px">
        <div style="font-family:var(--font-mono);font-size:.65rem;color:var(--c-text3);flex-shrink:0"><?= h($timeStr) ?></div>
        <div style="flex:1">
          <code style="font-size:.65rem;color:var(--c-primary);background:var(--c-surface2);padding:1px 6px;border-radius:3px"><?= h($action) ?></code>
          <span style="font-size:.73rem;color:var(--c-text2);margin-left:8px"><?= h($actor) ?></span>
        </div>
        <span class="badge badge-<?= $log['actorRole']??'staff' ?>" style="font-size:.58rem"><?= ucfirst(h($log['actorRole']??'')) ?></span>
      </div>
      <?php endforeach; ?>
      <?php if (empty($recentActions)): ?>
      <div class="empty-state"><div class="empty-state-text">No audit events recorded yet</div></div>
      <?php endif; ?>
    </div>
  </div>
</div>

<?php include __DIR__ . '/../includes/footer.php'; ?>
