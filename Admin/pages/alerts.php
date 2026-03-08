<?php
ini_set('display_errors', 0);
error_reporting(0);

require_once __DIR__ . '/../config/config.php';
requireRole(ROLE_STAFF);
require_once __DIR__ . '/../config/firestore_rest.php';

$pageTitle = 'Alerts Center';
include __DIR__ . '/../includes/header.php';

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

$alerts = [];
$now = time();

try {
    $results = firestore_runQuery([
        "from"  => [["collectionId" => "services"]],
        "limit" => 100
    ]);
    $services = [];
    foreach ($results as $row) {
        if (empty($row['document'])) continue;
        $doc = $row['document'];
        $d = firestore_unpack_fields($doc['fields'] ?? []);
        $d['_id'] = basename($doc['name']);
        $services[] = $d;
    }

    foreach ($services as $s) {
        $name = $s['name'] ?? $s['_id'];
        $isOpen = $s['isOpen'] ?? false;
        $pending = (int)($s['pendingCount'] ?? 0);
        $active  = (int)($s['activeCount'] ?? 0);
        $calledId = $s['calledEntryId'] ?? null;
        $callExp  = $s['callExpiresAt'] ?? null;
        $headId   = $s['headPendingEntryId'] ?? null;
        $assigned = $s['assignedStaffIds'] ?? [];

        // Expired call
        if ($calledId && $callExp && strtotime($callExp) < $now) {
            $alerts[] = ['severity'=>'critical','icon'=>'🔴','title'=>"Expired call — $name",'desc'=>"Called entry $calledId has expired. Check in window passed.",'service'=>$name,'action'=>'expire_called','serviceId'=>$s['_id']];
        }

        // Service open with no staff
        if ($isOpen && empty($assigned) && $pending > 0) {
            $alerts[] = ['severity'=>'warning','icon'=>'⚠️','title'=>"No staff assigned — $name",'desc'=>"$pending people waiting, but no staff assigned to this service.",'service'=>$name];
        }

        // Closed with pending
        if (!$isOpen && $pending > 0) {
            $alerts[] = ['severity'=>'warning','icon'=>'🔒','title'=>"Closed with pending — $name",'desc'=>"Service is closed but $pending entries are still pending.",'service'=>$name];
        }

        // Head missing
        if ($isOpen && $pending > 0 && !$headId) {
            $alerts[] = ['severity'=>'warning','icon'=>'🧭','title'=>"Head missing — $name",'desc'=>"Service has $pending pending but headPendingEntryId is not set. Repair needed.",'service'=>$name,'action'=>'repair','serviceId'=>$s['_id']];
        }

        // Counter drift
        $realPending = $pending; // We'd need to recount to check drift
        if ($active > 5) {
            $alerts[] = ['severity'=>'warning','icon'=>'📊','title'=>"High active count — $name",'desc'=>"$active entries marked active simultaneously. Possible drift.",'service'=>$name,'action'=>'repair','serviceId'=>$s['_id']];
        }

        // Very large queue
        if ($pending > 30) {
            $alerts[] = ['severity'=>'info','icon'=>'📋','title'=>"Large queue — $name",'desc'=>"$pending entries waiting. Consider opening additional capacity.",'service'=>$name];
        }
    }

    // Camera alerts
    $camResults = firestore_runQuery([
        "from"  => [["collectionId" => "surveillance_cameras"]],
        "limit" => 50
    ]);
    foreach ($camResults as $row) {
        if (empty($row['document'])) continue;
        $doc = $row['document'];
        $d = firestore_unpack_fields($doc['fields'] ?? []);
        $d['_id'] = basename($doc['name']);
        $lastActive = $d['lastActive'] ?? null;
        $isOnline = ($d['isActive'] ?? false) && $lastActive && ($now - strtotime($lastActive)) < 120;
        if (($d['isActive'] ?? false) && !$isOnline) {
            $alerts[] = ['severity'=>'warning','icon'=>'📹','title'=>"Camera offline — " . ($d['name'] ?? $d['_id']),'desc'=>'Camera is marked active but has not reported in the last 2 minutes.','service'=>null];
        }
    }

} catch(Exception $e) { error_log("Alerts page: ".$e->getMessage()); }

// Sort: critical first
usort($alerts, fn($a,$b) => ['critical'=>0,'warning'=>1,'info'=>2][$a['severity']] <=> ['critical'=>0,'warning'=>1,'info'=>2][$b['severity']]);

$csrf = generateCSRFToken();
?>

<div class="page-header">
  <div class="page-header-row">
    <div>
      <h1 class="page-title">Alerts Center</h1>
      <p class="page-subtitle">Operational issues requiring attention</p>
    </div>
    <div class="header-actions">
      <button class="btn btn-ghost btn-sm" onclick="location.reload()">↻ Refresh</button>
    </div>
  </div>
</div>

<?php if (empty($alerts)): ?>
<div style="text-align:center;padding:80px 20px">
  <div style="font-size:3rem;margin-bottom:16px">✅</div>
  <div style="font-family:var(--font-mono);font-size:1.1rem;color:var(--c-green);margin-bottom:8px">All Clear</div>
  <div style="font-size:.85rem;color:var(--c-text3)">No active alerts detected. System is operating normally.</div>
</div>
<?php else: ?>

<div class="stats-grid" style="grid-template-columns:repeat(3,1fr)">
  <?php
  $critical = count(array_filter($alerts, fn($a)=>$a['severity']==='critical'));
  $warning  = count(array_filter($alerts, fn($a)=>$a['severity']==='warning'));
  $info     = count(array_filter($alerts, fn($a)=>$a['severity']==='info'));
  ?>
  <div class="stat-card red"><div class="stat-icon">🔴</div><div class="stat-label">Critical</div><div class="stat-value red"><?= $critical ?></div></div>
  <div class="stat-card amber"><div class="stat-icon">⚠️</div><div class="stat-label">Warning</div><div class="stat-value amber"><?= $warning ?></div></div>
  <div class="stat-card blue"><div class="stat-icon">ℹ️</div><div class="stat-label">Info</div><div class="stat-value blue"><?= $info ?></div></div>
</div>

<div style="display:flex;flex-direction:column;gap:10px">
<?php foreach ($alerts as $a): ?>
<div class="card" style="border-left: 3px solid <?= $a['severity']==='critical'?'var(--c-red)':($a['severity']==='warning'?'var(--c-amber)':'var(--c-primary)') ?>">
  <div style="padding:16px 20px;display:flex;align-items:flex-start;gap:14px">
    <span style="font-size:1.3rem;margin-top:1px"><?= $a['icon'] ?></span>
    <div style="flex:1">
      <div style="font-weight:600;font-size:.88rem;color:var(--c-text)"><?= h($a['title']) ?></div>
      <div style="font-size:.78rem;color:var(--c-text2);margin-top:4px"><?= h($a['desc']) ?></div>
      <?php if (!empty($a['service'])): ?>
      <div style="font-size:.7rem;color:var(--c-text3);margin-top:4px;font-family:var(--font-mono)">SERVICE: <?= h($a['service']) ?></div>
      <?php endif; ?>
    </div>
    <div style="display:flex;gap:6px;flex-shrink:0">
      <span style="font-family:var(--font-mono);font-size:.62rem;padding:3px 8px;border-radius:4px;background:var(--c-surface2);color:<?= $a['severity']==='critical'?'var(--c-red)':($a['severity']==='warning'?'var(--c-amber)':'var(--c-primary)') ?>;text-transform:uppercase;font-weight:700"><?= $a['severity'] ?></span>
      <?php if (!empty($a['action']) && !empty($a['serviceId'])): ?>
      <button onclick="queueAction('<?= h($a['action']) ?>','<?= h($a['serviceId']) ?>')" class="btn btn-ghost btn-sm">Fix</button>
      <?php endif; ?>
    </div>
  </div>
</div>
<?php endforeach; ?>
</div>
<?php endif; ?>

<script>
window._csrfToken = '<?= h($csrf) ?>';
window._basePath = '<?= BASE_PATH ?>';
window.refreshPage = () => location.reload();
</script>
<?php include __DIR__ . '/../includes/footer.php'; ?>
