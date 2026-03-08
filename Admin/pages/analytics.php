<?php
require_once '../config/config.php';
requireRole(ROLE_STAFF);

require_once '../config/firebase.php';  // ✅ defines $firestore

$pageTitle = 'Analytics';
include '../includes/header.php';

$error = null;

// defaults...
$totalServices = 0;
$openServices = 0;
$totalCameras = 0;
$activeCameras = 0;
$totalQueueEntries = 0;
$servedToday = 0;

try {
    $services = $firestore->collection('services')->documents();
    $totalServices = count($services);

    foreach ($services as $s) {
        $d = $s->data();
        if (($d['status'] ?? '') === 'open') $openServices++;
    }

    $cameras = $firestore->collection('surveillance_cameras')->documents();
    $totalCameras = count($cameras);

    foreach ($cameras as $c) {
        $d = $c->data();
        if (!empty($d['isActive'])) $activeCameras++;
    }

    foreach ($services as $s) {
        $serviceId = $s->id();
        $entries = $firestore->collection("services/$serviceId/entries")->documents();
        foreach ($entries as $e) {
            $totalQueueEntries++;
            if (($e->data()['status'] ?? '') === 'served') $servedToday++;
        }
    }
} catch (Throwable $e) {
    $error = $e->getMessage();
    error_log("Analytics error: " . $e->getMessage());
}
?>

<div class="page-header">
  <div>
    <h1 class="page-title">📈 Analytics</h1>
    <p class="page-subtitle">System overview and usage statistics</p>
  </div>
</div>

<?php if ($error): ?>
  <div class="alert alert-danger">
    Error loading analytics: <?= htmlspecialchars($error) ?>
  </div>
<?php endif; ?>

<div class="stats-grid">

  <div class="stat-card">
    <div class="stat-icon">🏢</div>
    <div class="stat-value"><?= $totalServices ?></div>
    <div class="stat-label">Total Services</div>
    <div class="stat-sub"><?= $openServices ?> Open</div>
  </div>

  <div class="stat-card">
    <div class="stat-icon">📹</div>
    <div class="stat-value"><?= $activeCameras ?>/<?= $totalCameras ?></div>
    <div class="stat-label">Cameras Online</div>
  </div>

  <div class="stat-card">
    <div class="stat-icon">📋</div>
    <div class="stat-value"><?= $totalQueueEntries ?></div>
    <div class="stat-label">Total Queue Entries</div>
  </div>

  <div class="stat-card">
    <div class="stat-icon">✅</div>
    <div class="stat-value"><?= $servedToday ?></div>
    <div class="stat-label">Served (Total)</div>
  </div>

</div>

<?php include '../includes/footer.php'; ?>
